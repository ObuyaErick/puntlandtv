import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../core/admin_api/dto/admin_program_dto.dart';

/// Which locales' shelves a programme actually appears on.
///
/// The same treatment the categories table uses for tab-bar visibility, and
/// for the same reason: an untitled locale is *hidden*, not filled in from the
/// other language, so the honest display is a pair of pills where one is off.
class ShelfPills extends StatelessWidget {
  const ShelfPills({super.key, required this.program});

  final AdminProgramDto program;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        for (final locale in AdminProgramDto.requiredLocales)
          _Pill(
            code: locale,
            // Live on a shelf means titled *and* published. A titled
            // programme nobody has published yet is not on a shelf, and
            // showing it as one would be a lie the newsroom acts on.
            on: program.isPublished && program.isVisibleIn(locale),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.code, required this.on});

  final String code;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: on ? context.colors.accentContainer : context.colors.skeleton,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        code.toUpperCase(),
        style: context.text.overline.copyWith(
          fontSize: 9.5,
          color: on
              ? context.colors.onAccentContainer
              : context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
