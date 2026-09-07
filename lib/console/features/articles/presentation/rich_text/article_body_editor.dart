import 'package:file_selector/file_selector.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../media/presentation/pages/media_detail_panel.dart';
import '../../../media/presentation/media_format.dart';
import '../../../media/presentation/widgets/media_picker_dialog.dart';
import 'article_embeds.dart';
import 'article_html.dart';
import 'article_paste_handler.dart';
import 'article_paste_listener.dart';
import 'quill_material_bridge.dart';

/// The body field: the artboard's 44dp toolbar over a Quill editing surface.
class ArticleBodyEditor extends ConsumerStatefulWidget {
  const ArticleBodyEditor({
    super.key,
    required this.controller,
    required this.locale,
    this.paste,
    this.readOnly = false,
    this.autofocus = false,
  });

  final QuillController controller;

  /// Shown in the field's label, per the canvas: `BODY · SO`.
  final String locale;

  /// What pasting into this field does.
  ///
  /// Optional so the field can be pumped on its own in a test. Without one it
  /// pastes plain text, which is what it did before any of this existed.
  final ArticlePasteHandler? paste;

  final bool readOnly;
  final bool autofocus;

  @override
  ConsumerState<ArticleBodyEditor> createState() => _ArticleBodyEditorState();
}

class _ArticleBodyEditorState extends ConsumerState<ArticleBodyEditor> {
  final _focus = FocusNode();
  final _scroll = ScrollController();

  ArticlePasteListener? _pasteListener;

  @override
  void initState() {
    super.initState();
    // `readOnly` used to hide the toolbar and nothing else, which left a
    // "read-only" body an editor could still type into.
    widget.controller.readOnly = widget.readOnly;
    _attachPasteListener();
  }

  @override
  void didUpdateWidget(covariant ArticleBodyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readOnly != oldWidget.readOnly) {
      widget.controller.readOnly = widget.readOnly;
    }
    if (widget.paste != oldWidget.paste) {
      _pasteListener?.detach();
      _pasteListener = null;
      _attachPasteListener();
    }
  }

  /// Hooks the browser's paste event, on the web only.
  ///
  /// Off the web this builds nothing: flutter_quill's own clipboard hook fires
  /// there and the handler is already wired into the controller's config. See
  /// `article_paste_listener.dart` for why the web cannot use that route.
  void _attachPasteListener() {
    final paste = widget.paste;
    if (paste == null) return;
    _pasteListener = ArticlePasteListener(
      isFocused: () => _focus.hasFocus,
      onPaste: ({html, plainText, imageBytes}) async {
        await paste.handleExclusively(
          html: html,
          plainText: plainText,
          imageBytes: imageBytes,
        );
        return true;
      },
    )..attach();
  }

  @override
  void dispose() {
    _pasteListener?.detach();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.editorBody(widget.locale.toUpperCase()),
          style: context.text.overline.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: context.colors.outline),
            ),
            child: ClipRRect(
              borderRadius: Radii.cardBorder,
              clipBehavior: Clip.antiAlias,
              child: QuillMaterialBridge(
                child: Column(
                  children: [
                    if (!widget.readOnly)
                      ArticleBodyToolbar(controller: widget.controller),
                    Expanded(
                      child: QuillEditor(
                        controller: widget.controller,
                        focusNode: _focus,
                        scrollController: _scroll,
                        config: QuillEditorConfig(
                          padding: const EdgeInsets.all(Spacing.listRhythm),
                          autoFocus: widget.autofocus,
                          expands: true,
                          placeholder: l10n.bodyPlaceholder,
                          customStyles: _styles(context),
                          embedBuilders: articleEmbedBuilders(),
                          unknownEmbedBuilder: unsupportedArticleEmbed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DefaultStyles _styles(BuildContext context) {
    final serif = TextStyle(
      fontFamily: FontFamily.serif,
      fontSize: 16,
      height: 26 / 16,
      color: context.scheme.onSurface,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        serif,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 13),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: FontFamily.serif,
          fontSize: 21,
          height: 28 / 21,
          fontWeight: FontWeight.w600,
          color: context.scheme.primary,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(16, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: FontFamily.serif,
          fontSize: 18,
          height: 25 / 18,
          fontWeight: FontWeight.w600,
          color: context.scheme.primary,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(14, 7),
        const VerticalSpacing(0, 0),
        null,
      ),
      quote: DefaultTextBlockStyle(
        serif.copyWith(
          fontWeight: FontWeight.w600,
          height: 25 / 16,
          color: context.scheme.primary,
        ),
        const HorizontalSpacing(14, 0),
        const VerticalSpacing(8, 13),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: context.colors.accent, width: 3),
          ),
        ),
      ),
      placeHolder: DefaultTextBlockStyle(
        serif.copyWith(color: context.scheme.onSurfaceVariant),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }
}

/// The 44dp control row above the body.
class ArticleBodyToolbar extends ConsumerWidget {
  const ArticleBodyToolbar({super.key, required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.chip),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: context.colors.outlineSubtle)),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final style = controller.getSelectionStyle().attributes;

          final controls = <Widget>[
            _Toggle(
              label: 'B',
              tooltip: l10n.formatBold,
              textStyle: const TextStyle(
                fontFamily: FontFamily.sans,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              active: style.containsKey(Attribute.bold.key),
              onPressed: () => _toggle(Attribute.bold),
            ),
            _Toggle(
              label: 'I',
              tooltip: l10n.formatItalic,
              textStyle: const TextStyle(
                fontFamily: FontFamily.serif,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
              active: style.containsKey(Attribute.italic.key),
              onPressed: () => _toggle(Attribute.italic),
            ),
            const _ToolbarRule(),
            _Toggle(
              label: 'H2',
              tooltip: l10n.formatHeading2,
              active: _isHeader(style, 2),
              onPressed: () => _header(2),
            ),
            _Toggle(
              label: 'H3',
              tooltip: l10n.formatHeading3,
              active: _isHeader(style, 3),
              onPressed: () => _header(3),
            ),
            const _ToolbarRule(),
            _Toggle(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: l10n.formatBulletList,
              active: style[Attribute.list.key]?.value == Attribute.ul.value,
              onPressed: () => _block(Attribute.ul),
            ),
            _Toggle(
              icon: Icons.format_quote_rounded,
              tooltip: l10n.formatQuote,
              active: style.containsKey(Attribute.blockQuote.key),
              onPressed: () => _block(Attribute.blockQuote),
            ),
            _Toggle(
              icon: Icons.link_rounded,
              tooltip: l10n.formatLink,
              active: style.containsKey(Attribute.link.key),
              onPressed: () => _link(context),
            ),
            _Toggle(
              icon: Icons.image_outlined,
              tooltip: l10n.formatImage,
              active: false,
              onPressed: () => _image(context, ref),
            ),
          ];

          final words = articleDocumentWordCount(controller.document);

          return Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: controls),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, right: Spacing.chip),
                  child: Text(
                    l10n.wordCountAndRead(words, articleReadingMinutes(words)),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.meta.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _isHeader(Map<String, Attribute> style, int level) =>
      style[Attribute.header.key]?.value == level;

  void _toggle(Attribute<dynamic> attribute) {
    final active = controller.getSelectionStyle().attributes.containsKey(
      attribute.key,
    );
    controller.formatSelection(
      active ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _header(int level) {
    final active = _isHeader(controller.getSelectionStyle().attributes, level);
    controller.formatSelection(
      active ? Attribute.header : Attribute.clone(Attribute.header, level),
    );
  }

  void _block(Attribute<dynamic> attribute) {
    final current = controller
        .getSelectionStyle()
        .attributes[attribute.key]
        ?.value;
    controller.formatSelection(
      current == attribute.value ? Attribute.clone(attribute, null) : attribute,
    );
  }

  Future<void> _link(BuildContext context) async {
    final existing = controller
        .getSelectionStyle()
        .attributes[Attribute.link.key]
        ?.value;
    final href = await _promptForUrl(
      context,
      title: context.l10n.formatLink,
      initial: existing as String? ?? '',
    );
    if (href == null) return;
    controller.formatSelection(
      href.isEmpty
          ? Attribute.clone(Attribute.link, null)
          : LinkAttribute(href),
    );
  }

  /// Puts an image in the body, from wherever the operator has one.
  ///
  /// Three routes, because there are three ways an image exists at the moment
  /// someone wants it: as a file on their machine, as something already in the
  /// library, or as a URL. The first two both end as a library asset — the
  /// same place a pasted screenshot lands — so the alt-text rule reaches every
  /// picture that goes into a story by any of them. A bare URL does not, and
  /// that is the cost of keeping it.
  Future<void> _image(BuildContext context, WidgetRef ref) async {
    final picked = await showDialog<_PickedImage>(
      context: context,
      builder: (context) => const _ImageSourceDialog(),
    );
    if (picked == null || !context.mounted) return;

    final index = controller.selection.baseOffset;
    controller.replaceText(
      index,
      controller.selection.extentOffset - index,
      BlockEmbed.image(picked.url),
      TextSelection.collapsed(offset: index + 1),
    );

    final assetId = picked.assetId;
    if (assetId == null || !picked.needsAlt) return;
    // An image lands undescribed, and this is the cheapest moment to fix that
    // — the same reason the media library opens the panel after an upload.
    showConsoleToast(
      context,
      message: context.l10n.pastedImageAdded,
      action: SnackBarAction(
        label: context.l10n.describeImage,
        onPressed: () => showMediaAsset(context, id: assetId),
      ),
    );
  }
}

/// What [_ImageSourceDialog] hands back.
class _PickedImage {
  const _PickedImage(this.url, {this.assetId, this.needsAlt = false});

  final String url;

  /// Null for a bare URL, which belongs to no asset this console knows about.
  final String? assetId;

  final bool needsAlt;
}

/// Asks where the image is coming from.
class _ImageSourceDialog extends ConsumerStatefulWidget {
  const _ImageSourceDialog();

  @override
  ConsumerState<_ImageSourceDialog> createState() => _ImageSourceDialogState();
}

class _ImageSourceDialogState extends ConsumerState<_ImageSourceDialog> {
  final _url = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.formatImage, style: context.text.title),
      content: SizedBox(
        width: Layout.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _fromComputer,
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: Text(l10n.imageFromComputer),
            ),
            const SizedBox(height: Spacing.chip),
            OutlinedButton.icon(
              onPressed: _busy ? null : _fromLibrary,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l10n.imageFromLibrary),
            ),
            const SizedBox(height: Spacing.listRhythm),
            Text(
              l10n.imageOrPasteUrl,
              style: context.text.overline.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _url,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(hintText: l10n.urlHint),
              onSubmitted: (_) => _fromUrl(),
            ),
            if (_busy) ...[
              const SizedBox(height: Spacing.listRhythm),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Spacing.chip),
                  Text(
                    l10n.uploadingImage,
                    style: context.text.meta.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Spacing.listRhythm),
              Text(
                _error!,
                style: context.text.meta.copyWith(color: context.scheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _fromUrl,
          child: Text(l10n.apply),
        ),
      ],
    );
  }

  void _fromUrl() {
    final url = _url.text.trim();
    if (url.isEmpty) return;
    Navigator.of(context).pop(_PickedImage(url));
  }

  Future<void> _fromLibrary() async {
    final asset = await pickMediaImage(context, ref);
    if (asset == null || !mounted) return;
    Navigator.of(context).pop(
      _PickedImage(
        asset.url,
        assetId: asset.id,
        needsAlt: !asset.hasCompleteAlt,
      ),
    );
  }

  Future<void> _fromComputer() async {
    const images = XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
      mimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
      uniformTypeIdentifiers: ['public.image'],
    );

    final file = await openFile(acceptedTypeGroups: const [images]);
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final l10n = context.l10n;
    if (ImageFormat.of(bytes) == null) {
      setState(() => _error = l10n.imageNotSupported);
      return;
    }
    if (bytes.length > kMaxPastedImageBytes) {
      setState(
        () => _error = l10n.imageTooLarge(
          MediaFormat.bytes(l10n, kMaxPastedImageBytes, context.languageCode),
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final asset = await ref
          .read(adminApiProvider)
          .uploadMedia(
            filename: file.name,
            kind: MediaKind.image,
            byteSize: bytes.length,
            bytes: bytes,
          );
      if (!mounted) return;
      Navigator.of(context).pop(
        _PickedImage(
          asset.url,
          assetId: asset.id,
          needsAlt: !asset.hasCompleteAlt,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l10n.imageUploadFailed;
      });
    }
  }
}

/// Asks for a URL. Returns null if dismissed, `''` to remove an existing one.
Future<String?> _promptForUrl(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  final field = TextEditingController(text: initial);
  final l10n = context.l10n;

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: context.text.title),
      content: SizedBox(
        width: Layout.dialogWidth,
        child: TextField(
          controller: field,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: l10n.urlHint),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        if (initial.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(l10n.removeLink),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(field.text.trim()),
          child: Text(l10n.apply),
        ),
      ],
    ),
  ).whenComplete(field.dispose);
}

/// One 36×36 toolbar control, labelled by glyph or icon.
class _Toggle extends StatelessWidget {
  const _Toggle({
    this.label,
    this.icon,
    this.textStyle,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final TextStyle? textStyle;
  final String tooltip;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colour = active ? context.scheme.onPrimary : context.scheme.primary;

    return Semantics(
      toggled: active,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? context.scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: icon != null
                ? Icon(icon, size: 17, color: colour)
                : Text(
                    label!,
                    style:
                        (textStyle ??
                                const TextStyle(
                                  fontFamily: FontFamily.sans,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ))
                            .copyWith(color: colour),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarRule extends StatelessWidget {
  const _ToolbarRule();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: context.colors.outline,
  );
}
