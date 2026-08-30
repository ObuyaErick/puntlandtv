import 'bootstrap.dart';

/// Production entrypoint.
///
/// Flavour-specific entrypoints (`main_dev.dart`, `main_staging.dart`) call
/// the same [bootstrap] with different `--dart-define`s; see
/// `core/api/api_providers.dart` for the ones that matter.
void main() => bootstrap();
