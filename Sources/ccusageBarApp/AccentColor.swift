import AppKit
import SwiftUI

enum AccentColorOption: String, CaseIterable, Identifiable {
    case yellow
    case orange
    case coral
    case pink
    case purple
    case blue
    case cyan
    case green

    var id: String { rawValue }

    var name: String {
        rawValue.capitalized
    }

    var color: Color {
        Color(red: components.red, green: components.green, blue: components.blue)
    }

    var swatchImage: NSImage {
        components.swatchImage
    }

    var components: AccentColorComponents {
        switch self {
        case .yellow:
            AccentColorComponents(red: 238 / 255, green: 186 / 255, blue: 44 / 255)
        case .orange:
            AccentColorComponents(red: 255 / 255, green: 143 / 255, blue: 61 / 255)
        case .coral:
            AccentColorComponents(red: 255 / 255, green: 101 / 255, blue: 119 / 255)
        case .pink:
            AccentColorComponents(red: 255 / 255, green: 92 / 255, blue: 184 / 255)
        case .purple:
            AccentColorComponents(red: 167 / 255, green: 123 / 255, blue: 255 / 255)
        case .blue:
            AccentColorComponents(red: 91 / 255, green: 157 / 255, blue: 255 / 255)
        case .cyan:
            AccentColorComponents(red: 40 / 255, green: 199 / 255, blue: 217 / 255)
        case .green:
            AccentColorComponents(red: 72 / 255, green: 199 / 255, blue: 116 / 255)
        }
    }
}

struct AccentColorComponents: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    var swatchImage: NSImage {
        let size = NSSize(width: 12, height: 12)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor(
            red: red,
            green: green,
            blue: blue,
            alpha: 1
        ).setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    init(red: Double, green: Double, blue: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
    }

    init?(color: Color) {
        guard let color = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        self.init(
            red: color.redComponent,
            green: color.greenComponent,
            blue: color.blueComponent
        )
    }

    init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let rgb = Int(value, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var hex: String {
        String(
            format: "#%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }
}

@MainActor
final class AccentColorPanelController: NSObject {
    static let shared = AccentColorPanelController()

    private var onColorChange: ((Color) -> Void)?

    func show(color: Color, onColorChange: @escaping (Color) -> Void) {
        self.onColorChange = onColorChange

        NSApp.activate(ignoringOtherApps: true)
        let panel = NSColorPanel.shared
        panel.isContinuous = true
        panel.showsAlpha = false
        panel.color = NSColor(color)
        panel.setTarget(self)
        panel.setAction(#selector(colorDidChange(_:)))
        NSApp.orderFrontColorPanel(nil)
    }

    @objc private func colorDidChange(_ sender: NSColorPanel) {
        onColorChange?(Color(sender.color))
    }
}

private struct AppAccentColorKey: EnvironmentKey {
    static let defaultValue = AccentColorOption.yellow.color
}

extension EnvironmentValues {
    var appAccentColor: Color {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }
}
