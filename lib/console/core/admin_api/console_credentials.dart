/// The console's live credentials.
///
/// One instance, shared by the client that *sends* the tokens and the
/// repository that *persists* them. It exists because those are genuinely two
/// jobs and the split matters: the backend rotates the refresh token on every
/// use and revokes the one presented, so a renewal that only the HTTP client
/// knew about would leave a spent token in storage and a console that cannot
/// restore its session after a reload.
///
/// [onChanged] is how the repository hears about a renewal the client performed
/// on its own — a request that met a lapsed access token and refreshed rather
/// than bouncing the operator to the login form mid-edit.
class ConsoleCredentials {
  String? accessToken;
  String? refreshToken;

  /// Called after any change to the pair, including being cleared.
  void Function()? onChanged;

  bool get hasSession => accessToken != null || refreshToken != null;

  /// Takes a pair, and reports the change only if there was one.
  ///
  /// Both the repository and the HTTP client hold what a sign-in returned — the
  /// repository because it persists it, the client because it sends it — and
  /// neither should have to know whether the other went first.
  void hold({String? accessToken, String? refreshToken}) {
    if (accessToken == this.accessToken &&
        refreshToken == this.refreshToken) {
      return;
    }
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    onChanged?.call();
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
    onChanged?.call();
  }
}
