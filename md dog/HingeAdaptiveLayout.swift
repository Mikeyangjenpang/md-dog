//
//  HingeAdaptiveLayout.swift
//  md dog
//
//  iPhone Duo (iOS 27.1) adaptation: when the device is half-folded, the
//  reader stays on the primary panel and the controls move to the secondary
//  panel so nothing sits across the hinge.
//

import SwiftUI

/// Wraps `content` and, while a hinge division is active, shows `controls`
/// in a second panel. `isSplit` reports the current state so the content can
/// drop controls that would otherwise be duplicated.
struct HingeAdaptiveLayout<Content: View, Controls: View>: View {
    @Binding var isSplit: Bool
    @Binding var isDuo: Bool
    @ViewBuilder var content: () -> Content
    @ViewBuilder var controls: () -> Controls

    var body: some View {
        if #available(iOS 27.1, *) {
            HingeAwareContainer(isSplit: $isSplit, isDuo: $isDuo, content: content, controls: controls)
        } else {
            content()
        }
    }
}

@available(iOS 27.1, *)
private struct HingeAwareContainer<Content: View, Controls: View>: View {
    @Binding var isSplit: Bool
    @Binding var isDuo: Bool
    @ViewBuilder var content: () -> Content
    @ViewBuilder var controls: () -> Controls

    var body: some View {
        GeometryReader { proxy in
            // Only a horizontal hinge (panels stacked top/bottom) uses the
            // controls panel; a vertical hinge keeps the side-by-side layout
            // that the content provides itself.
            let folded = proxy.reservedRegions(kind: .division)
                .contains { $0.isActive && $0.frame.width > $0.frame.height }
            // A hinge division exists (even when inactive) only on foldable hardware.
            let hasHinge = !proxy.reservedRegions(kind: .division, options: .includeInactive).isEmpty
            Group {
                if folded {
                    ArrangementView {
                        content()
                    } secondary: {
                        controls()
                    }
                    .arrangementViewStyle(.split.axes(.vertical))
                } else {
                    content()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onChange(of: folded, initial: true) { _, newValue in
                isSplit = newValue
            }
            .onChange(of: hasHinge, initial: true) { _, newValue in
                isDuo = newValue
            }
        }
    }
}
