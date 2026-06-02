import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] applicationWillFinishLaunching")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching — setting activation policy")
        NSApp.setActivationPolicy(.accessory)
        print("[AppDelegate] activation policy set, creating StatusBarController")
        statusBarController = StatusBarController()
        print("[AppDelegate] StatusBarController created: \(String(describing: statusBarController))")
    }
}
