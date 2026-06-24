import AppKit

@MainActor
final class DocumentWindowDelegate: NSObject, NSWindowDelegate {
    let model: SingleDocumentModel
    let registry: DocumentRegistry
    private let onClose: () -> Void

    init(model: SingleDocumentModel, registry: DocumentRegistry, onClose: @escaping () -> Void = {}) {
        self.model = model
        self.registry = registry
        self.onClose = onClose
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        model.confirmClose()
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            registry.unregister(window: window)
        }
        registry.unregister(model: model)
        onClose()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if let textView = Self.findTextView(in: window.contentView) {
            EditorRegistry.shared.activate(textView)
        }
    }

    private static func findTextView(in view: NSView?) -> NSTextView? {
        guard let view else { return nil }
        if let textView = view as? NSTextView {
            return textView
        }
        for subview in view.subviews {
            if let found = findTextView(in: subview) {
                return found
            }
        }
        return nil
    }
}
