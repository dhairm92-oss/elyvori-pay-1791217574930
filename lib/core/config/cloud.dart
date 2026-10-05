/// The app's own cloud (accounts + synced data), hosted by Elyvori.
/// Elyvori fills [cloudAppId] when it generates the app; when it is empty the
/// app runs fully on the device (no sign-in screens, no sync).
const String cloudAppId = 'cmuvgp27s0002yrcwktkqo634';

bool get cloudEnabled => cloudAppId.isNotEmpty && !cloudAppId.startsWith('__');

/// `/cloud/<appId><path>` on the Elyvori API.
String cloudPath(String path) => '/cloud/$cloudAppId$path';
