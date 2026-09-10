/// Whether an integer is even or odd — a row's position in a striped table,
/// for one.
///
/// Pure Dart, so the app and the console can both use it.
enum Parity {
  even,
  odd;

  /// The parity of [n].
  factory Parity.of(int n) => n.isEven ? even : odd;
}
