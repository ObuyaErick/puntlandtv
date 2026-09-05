import 'package:flutter_quill/flutter_quill.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import 'article_embeds.dart';
import 'article_html.dart';
import 'quill_material_bridge.dart';

/// The body field: the artboard's 44dp toolbar over a Quill editing surface.
class ArticleBodyEditor extends StatefulWidget {
  const ArticleBodyEditor({
    super.key,
    required this.controller,
    required this.locale,
    this.readOnly = false,
    this.autofocus = false,
  });

  final QuillController controller;

  /// Shown in the field's label, per the canvas: `BODY · SO`.
  final String locale;

  final bool readOnly;
  final bool autofocus;

  @override
  State<ArticleBodyEditor> createState() => _ArticleBodyEditorState();
}

class _ArticleBodyEditorState extends State<ArticleBodyEditor> {
  final _focus = FocusNode();
  final _scroll = ScrollController();

  @override
  void dispose() {
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
class ArticleBodyToolbar extends StatelessWidget {
  const ArticleBodyToolbar({super.key, required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _image(context),
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

  Future<void> _image(BuildContext context) async {
    final url = await _promptForUrl(
      context,
      title: context.l10n.formatImage,
      initial: '',
    );
    if (url == null || url.isEmpty) return;

    final index = controller.selection.baseOffset;
    controller.replaceText(
      index,
      controller.selection.extentOffset - index,
      BlockEmbed.image(url),
      TextSelection.collapsed(offset: index + 1),
    );
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
