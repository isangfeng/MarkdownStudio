import AppKit
import Combine
import Foundation
import MarkdownStudioCore
import UniformTypeIdentifiers

private extension UTType {
    static let markdownDocument = UTType(filenameExtension: "md") ?? .plainText
}

struct OpenDocument: Identifiable, Equatable {
    let id: UUID
    var text: String
    var fileURL: URL?
    var isDirty: Bool
    var untitledName: String
}

@MainActor
final class DocumentStore: ObservableObject {
    @Published private(set) var openDocuments: [OpenDocument]
    @Published private(set) var activeDocumentID: OpenDocument.ID
    @Published private(set) var recentDocuments: [URL]

    private let recentKey = "MarkdownStudio.recentDocuments"
    private var nextUntitledNumber = 2

    init() {
        let document = Self.makeUntitledDocument(name: "Untitled.md")
        self.openDocuments = [document]
        self.activeDocumentID = document.id
        self.recentDocuments = UserDefaults.standard
            .stringArray(forKey: recentKey)?
            .compactMap(URL.init(fileURLWithPath:)) ?? []
    }

    var activeDocument: OpenDocument {
        openDocuments.first { $0.id == activeDocumentID } ?? openDocuments[0]
    }

    var activeText: String {
        activeDocument.text
    }

    var activeDisplayName: String {
        displayName(for: activeDocument)
    }

    var activeIsDirty: Bool {
        activeDocument.isDirty
    }

    var activeFileURL: URL? {
        activeDocument.fileURL
    }

    var visibleRecentDocuments: [URL] {
        let openURLs = Set(openDocuments.compactMap(\.fileURL))
        return recentDocuments.filter { !openURLs.contains($0) }
    }

    var outlineItems: [MarkdownOutlineItem] {
        MarkdownOutline.parse(activeDocument.text)
    }

    func updateActiveText(_ text: String) {
        guard let index = activeDocumentIndex, openDocuments[index].text != text else {
            return
        }

        openDocuments[index].text = text
        openDocuments[index].isDirty = true
    }

    func selectDocument(_ id: OpenDocument.ID) {
        guard openDocuments.contains(where: { $0.id == id }) else {
            return
        }
        activeDocumentID = id
    }

    func newDocument() {
        let document = Self.makeUntitledDocument(name: nextUntitledName())
        openDocuments.append(document)
        activeDocumentID = document.id
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.markdownDocument, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            open(url)
        }
    }

    func loadRecentDocument(_ url: URL) {
        open(url)
    }

    func save() {
        _ = saveDocument(activeDocumentID)
    }

    func saveAs() {
        _ = saveDocumentAs(activeDocumentID)
    }

    func closeDocument(_ id: OpenDocument.ID) {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }),
              shouldCloseDocument(openDocuments[index]) else {
            return
        }

        let wasActive = openDocuments[index].id == activeDocumentID
        openDocuments.remove(at: index)

        if openDocuments.isEmpty {
            let document = Self.makeUntitledDocument(name: nextUntitledName())
            openDocuments = [document]
            activeDocumentID = document.id
        } else if wasActive {
            let nextIndex = min(index, openDocuments.count - 1)
            activeDocumentID = openDocuments[nextIndex].id
        }
    }

    func shouldTerminateApplication() -> Bool {
        let dirtyDocuments = openDocuments.filter(\.isDirty)
        guard !dirtyDocuments.isEmpty else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Save changes to open documents?"
        alert.informativeText = "Your changes will be lost if you do not save them."
        alert.addButton(withTitle: "Save All")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Discard All")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            for document in dirtyDocuments where !saveDocument(document.id) {
                return false
            }
            return true
        case .alertThirdButtonReturn:
            return true
        default:
            return false
        }
    }

    func displayName(for document: OpenDocument) -> String {
        guard let url = document.fileURL else {
            return document.untitledName
        }

        return displayName(for: url, visibleURLs: visibleDocumentURLs)
    }

    func recentDocumentDisplayName(for url: URL) -> String {
        displayName(for: url, visibleURLs: visibleDocumentURLs)
    }

    private var activeDocumentIndex: Int? {
        openDocuments.firstIndex { $0.id == activeDocumentID }
    }

    private var visibleDocumentURLs: [URL] {
        openDocuments.compactMap(\.fileURL) + visibleRecentDocuments
    }

    private func open(_ url: URL) {
        if let document = openDocuments.first(where: { $0.fileURL == url }) {
            activeDocumentID = document.id
            remember(url)
            return
        }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let document = OpenDocument(
                id: UUID(),
                text: text,
                fileURL: url,
                isDirty: false,
                untitledName: "Untitled.md"
            )
            openDocuments.append(document)
            activeDocumentID = document.id
            remember(url)
        } catch {
            showError("Could not open document.", detail: error.localizedDescription)
        }
    }

    private func saveDocument(_ id: OpenDocument.ID) -> Bool {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }) else {
            return false
        }

        if let url = openDocuments[index].fileURL {
            return writeDocument(id, to: url)
        }

        return saveDocumentAs(id)
    }

    private func saveDocumentAs(_ id: OpenDocument.ID) -> Bool {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.markdownDocument]
        panel.nameFieldStringValue = displayName(for: openDocuments[index])

        if panel.runModal() == .OK, let url = panel.url {
            return writeDocument(id, to: url)
        }

        return false
    }

    private func writeDocument(_ id: OpenDocument.ID, to url: URL) -> Bool {
        guard let index = openDocuments.firstIndex(where: { $0.id == id }) else {
            return false
        }

        if openDocuments.contains(where: { $0.id != id && $0.fileURL == url }) {
            showError("Could not save document.", detail: "That file is already open in another tab.")
            return false
        }

        do {
            try openDocuments[index].text.write(to: url, atomically: true, encoding: .utf8)
            openDocuments[index].fileURL = url
            openDocuments[index].isDirty = false
            remember(url)
            return true
        } catch {
            showError("Could not save document.", detail: error.localizedDescription)
            return false
        }
    }

    private func remember(_ url: URL) {
        recentDocuments.removeAll { $0 == url }
        recentDocuments.insert(url, at: 0)
        recentDocuments = Array(recentDocuments.prefix(10))
        UserDefaults.standard.set(recentDocuments.map(\.path), forKey: recentKey)
    }

    private func displayName(for url: URL, visibleURLs: [URL]) -> String {
        let matchingNameCount = visibleURLs.filter { $0.lastPathComponent == url.lastPathComponent }.count
        if matchingNameCount > 1 {
            return url.path
        }

        return url.lastPathComponent
    }

    private func shouldCloseDocument(_ document: OpenDocument) -> Bool {
        guard document.isDirty else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Save changes to \(displayName(for: document))?"
        alert.informativeText = "Your changes will be lost if you do not save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Discard")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return saveDocument(document.id)
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

    private func nextUntitledName() -> String {
        defer { nextUntitledNumber += 1 }
        return "Untitled \(nextUntitledNumber).md"
    }

    private static func makeUntitledDocument(name: String) -> OpenDocument {
        OpenDocument(
            id: UUID(),
            text: defaultDocument,
            fileURL: nil,
            isDirty: false,
            untitledName: name
        )
    }

    private static let defaultDocument = """
    # Untitled

    Start writing Markdown here.

    - Use the toolbar or keyboard shortcuts for common Markdown syntax.
    - Save as a `.md` file when you are ready.

    """
}
