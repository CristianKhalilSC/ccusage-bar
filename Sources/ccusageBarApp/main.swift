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
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model))

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

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            model.refresh()
        }
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
        let path = NSBezierPath()
        path.lineWidth = 1.8
        path.appendArc(withCenter: NSPoint(x: 9, y: 7), radius: 6, startAngle: 200, endAngle: -20, clockwise: false)
        path.stroke()
        let needle = NSBezierPath()
        needle.move(to: NSPoint(x: 9, y: 7))
        needle.line(to: NSPoint(x: 13, y: 11))
        needle.lineWidth = 1.8
        needle.stroke()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
