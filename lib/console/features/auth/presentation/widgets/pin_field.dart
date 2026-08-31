import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';

/// A six-box verification code field.
///
/// Per artboard 11A: 56dp boxes, filled ones white with the digit, the box
/// awaiting input ringed 2px in `#1D7EC0`, and the boxes after it filled
/// `#F4F6F9` so the remaining length is visible at a glance.
///
/// One real `TextField` sits invisibly behind the boxes and owns the text.
/// Six separate fields would fight each other over focus and break paste,
/// which is how most people enter a code from another app.
class PinField extends StatefulWidget {
  const PinField({
    super.key,
    required this.controller,
    this.length = 6,
    this.hasError = false,
    this.onCompleted,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final int length;
  final bool hasError;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return Stack(
      children: [
        // The invisible field: real keyboard, real paste, real selection —
        // just not drawn.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
        GestureDetector(
          onTap: _focus.requestFocus,
          child: Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _PinBox(
                    digit: i < text.length ? text[i] : null,
                    active: _focus.hasFocus && i == text.length,
                    hasError: widget.hasError,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.digit,
    required this.active,
    required this.hasError,
  });

  final String? digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final filled = digit != null;

    final border = hasError
        ? BorderSide(color: context.scheme.error, width: 2)
        : active
        ? BorderSide(color: context.colors.link, width: 2)
        : BorderSide(color: context.colors.outline);

    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Boxes still to be filled sit on the page background, so the
        // remaining length of the code is legible without counting.
        color: filled || active
            ? context.scheme.surface
            : context.scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.fromBorderSide(border),
      ),
      child: Text(
        digit ?? '',
        style: context.text.label.copyWith(
          fontSize: 22,
          color: context.scheme.primary,
        ),
      ),
    );
  }
}
