import AppKit
import SwiftUI
import ccusageCore
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let logger = Logger(subsystem: "com.cristiancruz.ccusagebar", category: "app")
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var model: UsageAppModel!
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model = UsageAppModel()
        model.onMenuTitleChange = { [weak self] title in
            self?.statusItem.button?.title = " \(title)"
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = MenuBarIcon.image()
            button.image?.isTemplate = true
            button.title = " -- / --"
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 390, height: 640)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model) { [weak self] height in
            self?.resizePopover(to: height)
        })

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains(.command) else { return event }
            if event.charactersIgnoringModifiers == "q" {
                NSApp.terminate(nil)
                return nil
            }
            if event.charactersIgnoringModifiers == "r" {
                self?.model.refresh()
                return nil
            }
            return event
        }

        logger.info("ccusage Bar launched")
        model.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model?.refreshLaunchAtLoginStatus()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            model.refresh()
        }
    }

    private func resizePopover(to height: CGFloat) {
        let fittedHeight = ceil(height)
        guard abs(popover.contentSize.height - fittedHeight) > 1 else { return }
        popover.contentSize = NSSize(width: 390, height: fittedHeight)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

enum MenuBarIcon {
    static func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        NSColor.labelColor.setStroke()

        let leftC = NSBezierPath()
        leftC.lineWidth = 2.15
        leftC.lineCapStyle = .round
        leftC.lineJoinStyle = .round
        leftC.move(to: NSPoint(x: 7.25, y: 12.35))
        leftC.curve(
            to: NSPoint(x: 4.78, y: 13.40),
            controlPoint1: NSPoint(x: 6.57, y: 13.03),
            controlPoint2: NSPoint(x: 5.70, y: 13.40)
        )
        leftC.curve(
            to: NSPoint(x: 1.35, y: 9.00),
            controlPoint1: NSPoint(x: 2.72, y: 13.40),
            controlPoint2: NSPoint(x: 1.35, y: 11.64)
        )
        leftC.curve(
            to: NSPoint(x: 4.78, y: 4.60),
            controlPoint1: NSPoint(x: 1.35, y: 6.36),
            controlPoint2: NSPoint(x: 2.72, y: 4.60)
        )
        leftC.curve(
            to: NSPoint(x: 7.25, y: 5.65),
            controlPoint1: NSPoint(x: 5.70, y: 4.60),
            controlPoint2: NSPoint(x: 6.57, y: 4.97)
        )
        leftC.stroke()

        let rightC = NSBezierPath()
        rightC.lineWidth = 2.15
        rightC.lineCapStyle = .round
        rightC.lineJoinStyle = .round
        rightC.move(to: NSPoint(x: 15.35, y: 12.35))
        rightC.curve(
            to: NSPoint(x: 12.72, y: 13.40),
            controlPoint1: NSPoint(x: 14.64, y: 13.03),
            controlPoint2: NSPoint(x: 13.70, y: 13.40)
        )
        rightC.curve(
            to: NSPoint(x: 9.10, y: 9.00),
            controlPoint1: NSPoint(x: 10.54, y: 13.40),
            controlPoint2: NSPoint(x: 9.10, y: 11.64)
        )
        rightC.curve(
            to: NSPoint(x: 12.72, y: 4.60),
            controlPoint1: NSPoint(x: 9.10, y: 6.36),
            controlPoint2: NSPoint(x: 10.54, y: 4.60)
        )
        rightC.curve(
            to: NSPoint(x: 15.35, y: 5.65),
            controlPoint1: NSPoint(x: 13.70, y: 4.60),
            controlPoint2: NSPoint(x: 14.64, y: 4.97)
        )
        rightC.stroke()

        let bars = NSBezierPath()
        bars.lineWidth = 1.25
        bars.lineCapStyle = .round
        bars.move(to: NSPoint(x: 12.35, y: 7.15))
        bars.line(to: NSPoint(x: 12.35, y: 9.55))
        bars.move(to: NSPoint(x: 14.15, y: 7.15))
        bars.line(to: NSPoint(x: 14.15, y: 10.85))
        bars.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
