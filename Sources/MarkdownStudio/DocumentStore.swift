import AppKit
import Combine
import Foundation
import MarkdownStudioCore
import UniformTypeIdentifiers

private extension UTType {
    static let markdownDocument = UTType(filenameExtension: "md") ?? .plainText
}

@MainActor
final class DocumentStore: ObservableObject {
    @Published var text: String {
        didSet {
            if text != oldValue {
                isDirty = true
            }
        }
    }

    @Published private(set) var fileURL: URL?
    @Published private(set) var isDirty: Bool
    @Published private(set) var recentDocuments: [URL]

    private let recentKey = "MarkdownStudio.recentDocuments"

    init() {
        self.text = Self.defaultDocument
        self.fileURL = nil
        self.isDirty = false
        self.recentDocuments = UserDefaults.standard
            .stringArray(forKey: recentKey)?
            .compactMap(URL.init(fileURLWithPath:)) ?? []
    }

    var displayName: String {
        if let fileURL {
            return fileURL.lastPathComponent
        }
        return "Untitled.md"
    }

    var currentDocumentDisplayName: String {
        displayName(for: fileURL, visibleURLs: visibleDocumentURLs)
    }

    var visibleRecentDocuments: [URL] {
        recentDocuments.filter { $0 != fileURL }
    }

    var outlineItems: [MarkdownOutlineItem] {
        MarkdownOutline.parse(text)
    }

    func recentDocumentDisplayName(for url: URL) -> String {
        displayName(for: url, visibleURLs: visibleDocumentURLs)
    }

    func newDocument() {
        if shouldContinueAfterUnsavedChanges() {
            text = Self.defaultDocument
            fileURL = nil
            isDirty = false
        }
    }

    func openDocument() {
        guard shouldContinueAfterUnsavedChanges() else {
            return
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.markdownDocument, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            load(url)
        }
    }

    func loadRecentDocument(_ url: URL) {
        guard url != fileURL, shouldContinueAfterUnsavedChanges() else {
            return
        }
        load(url)
    }

    func save() {
        if let fileURL {
            write(to: fileURL)
        } else {
            saveAs()
        }
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.markdownDocument]
        panel.nameFieldStringValue = displayName

        if panel.runModal() == .OK, let url = panel.url {
            write(to: url)
        }
    }

    private func load(_ url: URL) {
        do {
            text = try String(contentsOf: url, encoding: .utf8)
            fileURL = url
            isDirty = false
            remember(url)
        } catch {
            showError("Could not open document.", detail: error.localizedDescription)
        }
    }

    private func write(to url: URL) {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            isDirty = false
            remember(url)
        } catch {
            showError("Could not save document.", detail: error.localizedDescription)
        }
    }

    private func remember(_ url: URL) {
        recentDocuments.removeAll { $0 == url }
        recentDocuments.insert(url, at: 0)
        recentDocuments = Array(recentDocuments.prefix(10))
        UserDefaults.standard.set(recentDocuments.map(\.path), forKey: recentKey)
    }

    private var visibleDocumentURLs: [URL] {
        ([fileURL].compactMap { $0 } + visibleRecentDocuments)
    }

    private func displayName(for url: URL?, visibleURLs: [URL]) -> String {
        guard let url else {
            return "Untitled.md"
        }

        let matchingNameCount = visibleURLs.filter { $0.lastPathComponent == url.lastPathComponent }.count
        if matchingNameCount > 1 {
            return url.path
        }

        return url.lastPathComponent
    }

    private func shouldContinueAfterUnsavedChanges() -> Bool {
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
            save()
            return !isDirty
        case .alertThirdButtonReturn:
            return true
        default:
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

    private static let defaultDocument = """
    # Untitled

    Start writing Markdown here.

    - Use the toolbar or keyboard shortcuts for common Markdown syntax.
    - Save as a `.md` file when you are ready.

    """
}
