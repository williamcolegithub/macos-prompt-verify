// Shows an alert on the built-in display.
//
// AppleScript's `display alert` opens wherever the active application is, so on
// a multi-monitor desk a security warning can appear on a screen you are not
// looking at. NSAlert alone is not enough either: it re-centres itself when
// shown, discarding any position set beforehand. So the alert is attached as a
// sheet to an invisible window placed on the built-in screen, which is a
// position the alert cannot override.

import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: alert <title> <message> [seconds]\n".data(using: .utf8)!)
    exit(2)
}
let title = args[1]
let message = args[2]
let timeout = args.count > 3 ? Double(args[3]) ?? 30 : 30

func builtInScreen() -> NSScreen? {
    for screen in NSScreen.screens {
        guard let num = screen.deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { continue }
        if CGDisplayIsBuiltin(num) != 0 { return screen }
    }
    return NSScreen.screens.first
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

guard let screen = builtInScreen() else { exit(1) }
let v = screen.visibleFrame

// Invisible carrier, centred on the built-in display. The sheet lands on it.
let carrier = NSWindow(
    contentRect: NSRect(x: v.midX - 240, y: v.midY - 60, width: 480, height: 120),
    styleMask: [.titled],
    backing: .buffered,
    defer: false)
carrier.level = .screenSaver
carrier.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
carrier.alphaValue = 0.0          // present, but not visible
carrier.titlebarAppearsTransparent = true
carrier.isOpaque = false
carrier.backgroundColor = .clear
carrier.orderFrontRegardless()
carrier.setFrameOrigin(NSPoint(x: v.midX - 240, y: v.midY - 60))

let alert = NSAlert()
alert.messageText = title
alert.informativeText = message
alert.alertStyle = .critical
alert.addButton(withTitle: "OK")

app.activate(ignoringOtherApps: true)
alert.beginSheetModal(for: carrier) { _ in
    NSApp.stop(nil)
    exit(0)
}
alert.window.level = .screenSaver

DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { exit(0) }
app.run()
