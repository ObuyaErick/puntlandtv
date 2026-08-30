/// One page of a cursor-paginated list, in domain terms.
///
/// Pure Dart. The UI never sees `PagedDto`, and the cursor is opaque — the
/// only thing the app may do with it is hand it back to the next request.
class Page<T> {
  const Page({required this.items, this.nextCursor});

  const Page.empty() : items = const [], nextCursor = null;

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  Page<T> append(Page<T> next) =>
      Page<T>(items: [...items, ...next.items], nextCursor: next.nextCursor);
}
