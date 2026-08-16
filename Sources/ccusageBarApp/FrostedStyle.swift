import SwiftUI

struct FrostedBackdrop: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let accentColor: Color

    var body: some View {
        ZStack {
            if reduceTransparency {
                Color(red: 9 / 255, green: 12 / 255, blue: 16 / 255)
            } else {
                Rectangle().fill(.ultraThinMaterial)
                Color.black.opacity(0.48)
            }

            RadialGradient(
                colors: [accentColor.opacity(reduceTransparency ? 0.08 : 0.17), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 330
            )

            RadialGradient(
                colors: [Color.cyan.opacity(reduceTransparency ? 0.03 : 0.08), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 290
            )
        }
        .ignoresSafeArea()
    }
}

private struct FrostedGlassSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool

    func body(content: Content) -> some View {
        if reduceTransparency {
            fallback(content: content, opaque: true)
        } else if #available(macOS 26.0, *) {
            if let tint {
                content.glassEffect(
                    .regular.tint(tint).interactive(interactive),
                    in: .rect(cornerRadius: cornerRadius)
                )
            } else {
                content.glassEffect(
                    .regular.interactive(interactive),
                    in: .rect(cornerRadius: cornerRadius)
                )
            }
        } else {
            fallback(content: content, opaque: false)
        }
    }

    private func fallback(content: Content, opaque: Bool) -> some View {
        content
            .background(
                opaque ? AnyShapeStyle(Color(red: 30 / 255, green: 34 / 255, blue: 40 / 255)) : AnyShapeStyle(.thinMaterial),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .background(
                tint?.opacity(opaque ? 0.18 : 0.12) ?? .clear,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(opaque ? 0.18 : 0.13), lineWidth: 1)
            }
    }
}

private struct FrostedCardSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    reduceTransparency
                        ? AnyShapeStyle(Color(red: 25 / 255, green: 28 / 255, blue: 33 / 255))
                        : AnyShapeStyle(.thinMaterial)
                )
                .overlay {
                    if !reduceTransparency {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.black.opacity(0.13))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(reduceTransparency ? 0.11 : 0.16), lineWidth: 1)
                }
                .shadow(color: .black.opacity(reduceTransparency ? 0 : 0.18), radius: 12, y: 5)
        }
    }
}

extension View {
    func frostedGlassSurface(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        interactive: Bool = true
    ) -> some View {
        modifier(FrostedGlassSurface(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }

    func frostedCardSurface(cornerRadius: CGFloat = 13) -> some View {
        modifier(FrostedCardSurface(cornerRadius: cornerRadius))
    }
}
