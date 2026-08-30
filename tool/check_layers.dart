// Verifies the architectural boundaries the MVP plan commits to.
//
// Run: `dart run tool/check_layers.dart` (wired into CI).
//
// The rule that matters most here is the first one: the API layer must be
// independent of the UI, in both directions. Conventions decay — this turns
// them into a non-zero exit code.
import 'dart:io';

/// A forbidden-import rule.
class Rule {
  const Rule({
    required this.name,
    required this.appliesTo,
    required this.forbidden,
    required this.because,
    this.exempt = const [],
  });

  final String name;

  /// Path fragments selecting the files this rule governs.
  final List<String> appliesTo;

  /// Import substrings that must not appear in those files.
  final List<String> forbidden;

  /// Printed on violation, so the failure teaches rather than just blocks.
  final String because;

  /// Paths exempted, with the reason recorded at the definition site.
  final List<String> exempt;
}

const rules = <Rule>[
  Rule(
    name: 'API layer is UI-free',
    appliesTo: ['lib/core/api/', 'lib/core/network/', 'lib/core/error/'],
    forbidden: [
      'package:material_ui/',
      'package:cupertino_ui/',
      'package:flutter/material.dart',
      'package:flutter/cupertino.dart',
      'package:flutter/widgets.dart',
      '/presentation/',
    ],
    // `api_providers.dart` composes the layer for the app and legitimately
    // touches Riverpod; `fixture_puntland_api.dart` needs `rootBundle`.
    // Neither imports a widget library, which is what the rule protects.
    exempt: [
      'lib/core/api/api_providers.dart',
      'lib/core/api/fixture_puntland_api.dart',
    ],
    because:
        'The API layer must be testable without a widget binding, and a '
        'widget import is how that quietly stops being true.',
  ),
  Rule(
    name: 'Domain is pure Dart',
    appliesTo: ['/domain/'],
    forbidden: [
      'package:material_ui/',
      'package:cupertino_ui/',
      'package:flutter/',
      'package:dio/',
      'package:json_annotation/',
      '/data/',
      '/presentation/',
    ],
    because:
        'Entities and repository interfaces describe the product, not the '
        'transport or the rendering. Keeping Flutter out is what lets the '
        'domain outlive both.',
  ),
  Rule(
    name: 'Data layer renders nothing',
    appliesTo: ['/data/'],
    forbidden: [
      'package:material_ui/',
      'package:cupertino_ui/',
      'package:flutter/material.dart',
      'package:flutter/cupertino.dart',
      '/presentation/',
    ],
    because: 'Repositories and mappers must not reach into widgets.',
  ),
  Rule(
    name: 'Presentation never touches DTOs or HTTP',
    appliesTo: ['/presentation/'],
    forbidden: [
      'package:dio/',
      '/api/dto/',
      'core/api/http_puntland_api.dart',
      'core/api/fixture_puntland_api.dart',
      '/data/',
    ],
    because:
        'Screens consume domain entities through repository interfaces. '
        'A DTO or a status code in a widget is a backend rename away from '
        'breaking the UI.',
  ),
];

/// `presentation/` may not name a DTO type even without importing one.
final _dtoIdentifier = RegExp(r'\b\w+Dto\b');

void main() {
  final violations = <String>[];
  var checked = 0;

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    if (entity.path.contains('/l10n/generated/')) continue;

    final path = entity.path;
    final source = entity.readAsStringSync();
    checked++;

    final imports = RegExp(
      r'''^\s*import\s+['"]([^'"]+)['"]''',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();

    for (final rule in rules) {
      if (!rule.appliesTo.any(path.contains)) continue;
      if (rule.exempt.any(path.endsWith)) continue;

      for (final import in imports) {
        for (final bad in rule.forbidden) {
          if (import.contains(bad)) {
            violations.add(
              '${rule.name}\n'
              '  $path\n'
              "  imports '$import'\n"
              '  ${rule.because}',
            );
          }
        }
      }

      if (rule.name.startsWith('Presentation')) {
        final hit = _dtoIdentifier.firstMatch(source);
        if (hit != null) {
          violations.add(
            '${rule.name}\n'
            '  $path\n'
            '  references the DTO type `${hit.group(0)}`\n'
            '  ${rule.because}',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ layer boundaries hold across $checked files');
    stdout.writeln('  ${rules.map((r) => r.name).join('\n  ')}');
    return;
  }

  stderr.writeln('✗ ${violations.length} layer violation(s):\n');
  for (final v in violations) {
    stderr.writeln('$v\n');
  }
  exitCode = 1;
}
