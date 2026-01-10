import AppKit
import SwiftUI

struct WindowSizingView: NSViewRepresentable {
    let minSize: CGSize
    let maxSize: CGSize

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.contentMinSize = minSize
            window.contentMaxSize = maxSize
        }
    }
}
