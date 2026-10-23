// Prints the CGWindowID of the first on-screen normal window of the
// process whose PID is argv[1] (used by mac.sh to capture just that
// window). By PID, not by name: an installed Avalon has the same name as
// the development build.
import CoreGraphics

guard CommandLine.arguments.count > 1, let pid = Int(CommandLine.arguments[1]) else {
  fatalError("usage: winid PID")
}
let windows =
  CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
  as? [[String: Any]] ?? []
for w in windows
where (w[kCGWindowOwnerPID as String] as? Int) == pid
  && (w[kCGWindowLayer as String] as? Int) == 0
{
  print(w[kCGWindowNumber as String]!)
  break
}
