/// One-shot signal that a fresh social-auth registration just completed
/// and the home page should ask the user whether they have a referral code.
///
/// Lives in memory only — the prompt is meant for the splash → home hop in
/// the same session immediately after social auth, so persistence across
/// app restarts isn't required (and would risk re-prompting an existing
/// user if the app was killed before the prompt was dismissed).
///
/// Producer (`LoginPage` social-auth listener): sets [pending] = true before
/// navigating to splash.
///
/// Consumer (`HomePage` first post-frame callback): calls [consume] to
/// atomically read & clear the flag before showing the prompt sheet.
class ReferralPromptCoordinator {
  ReferralPromptCoordinator._();

  static bool pending = false;

  /// Returns true and clears the flag if a prompt is pending.
  /// Returns false otherwise. Use this instead of reading [pending]
  /// directly so the consumer can never show the prompt twice.
  static bool consume() {
    if (!pending) return false;
    pending = false;
    return true;
  }
}
