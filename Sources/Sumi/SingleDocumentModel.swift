import AppKit
import Foundation
import SumiCore
import UniformTypeIdentifiers

private extension UTType {
    static let markdownDocument = UTType(filenameExtension: "md") ?? .plainText
}

@MainActor
final class SingleDocumentModel: ObservableObject {
    let id = UUID()
    let untitledName: String

    @Published var text: String
    @Published private(set) var fileURL: URL? {
        didSet { refreshWindowMetadata() }
    }
    @Published private(set) var isDirty: Bool {
        didSet { refreshWindowMetadata() }
    }

    weak var window: NSWindow?
    weak var registry: DocumentRegistry?

    init(text: String, fileURL: URL?, isDirty: Bool, untitledName: String, registry: DocumentRegistry?) {
        self.text = text
        self.fileURL = fileURL
        self.isDirty = isDirty
        self.untitledName = untitledName
        self.registry = registry
    }

    convenience init(loadingContentsOf url: URL, registry: DocumentRegistry) throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        self.init(text: text, fileURL: url, isDirty: false, untitledName: "Untitled.md", registry: registry)
    }

    static func blank(untitledName: String, registry: DocumentRegistry?) -> SingleDocumentModel {
        SingleDocumentModel(text: "", fileURL: nil, isDirty: false, untitledName: untitledName, registry: registry)
    }

    func load(text: String, fileURL: URL) {
        self.text = text
        self.fileURL = fileURL
        isDirty = false
    }

    var displayName: String {
        guard let url = fileURL else {
            return untitledName
        }

        return registry?.displayName(for: url) ?? url.lastPathComponent
    }

    var tabTitle: String {
        isDirty ? "\(displayName) - Edited" : displayName
    }

    var tabPillTitle: String {
        isDirty ? "* \(displayName)" : displayName
    }

    var outlineItems: [MarkdownOutlineItem] {
        MarkdownOutline.parse(text)
    }

    func refreshWindowMetadata() {
        window?.title = tabTitle
        window?.tab.title = tabPillTitle
        window?.representedURL = fileURL
        window?.isDocumentEdited = isDirty
    }

    func updateText(_ newText: String) {
        guard text != newText else {
            return
        }

        text = newText
        isDirty = true
    }

    func save() -> Bool {
        if let url = fileURL {
            return write(to: url)
        }

        return saveAs()
    }

    func saveAs() -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.markdownDocument]
        panel.nameFieldStringValue = displayName

        if panel.runModal() == .OK, let url = panel.url {
            return write(to: url)
        }

        return false
    }

    func confirmClose() -> Bool {
        guard isDirty else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Save changes to \(displayName)?"
        alert.informativeText = "Your changes will be lost if you do not save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Discard")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return save()
        case .alertThirdButtonReturn:
            return true
        default:
            return false
        }
    }

    private func write(to url: URL) -> Bool {
        if let existing = registry?.window(for: url), existing !== window {
            showError("Could not save document.", detail: "That file is already open in another window.")
            return false
        }

        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            isDirty = false
            return true
        } catch {
            showError("Could not save document.", detail: error.localizedDescription)
            return false
        }
    }

    private func showError(_ message: String, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }
}
