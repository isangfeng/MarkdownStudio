import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var store: DocumentStore?

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        store?.shouldTerminateApplication() == false ? .terminateCancel : .terminateNow
    }
}

@main
struct MarkdownStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = DocumentStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    appDelegate.store = store
                }
                .frame(minWidth: 880, minHeight: 620)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document") {
                    store.newDocument()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open...") {
                    store.openDocument()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Close Document") {
                    store.closeDocument(store.activeDocumentID)
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            CommandGroup(after: .saveItem) {
                Button("Save") {
                    store.save()
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    store.saveAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandMenu("Markdown") {
                Button("Bold") {
                    EditorRegistry.shared.apply(.bold)
                }
                .keyboardShortcut("b", modifiers: .command)

                Button("Italic") {
                    EditorRegistry.shared.apply(.italic)
                }
                .keyboardShortcut("i", modifiers: .command)

                Button("Inline Code") {
                    EditorRegistry.shared.apply(.inlineCode)
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()

                Button("Heading 1") {
                    EditorRegistry.shared.apply(.heading(1))
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button("Heading 2") {
                    EditorRegistry.shared.apply(.heading(2))
                }
                .keyboardShortcut("2", modifiers: [.command, .option])

                Button("Heading 3") {
                    EditorRegistry.shared.apply(.heading(3))
                }
                .keyboardShortcut("3", modifiers: [.command, .option])

                Divider()

                Button("Bullet List") {
                    EditorRegistry.shared.apply(.bulletList)
                }
                .keyboardShortcut("8", modifiers: [.command, .shift])

                Button("Numbered List") {
                    EditorRegistry.shared.apply(.numberedList)
                }
                .keyboardShortcut("7", modifiers: [.command, .shift])

                Button("Quote") {
                    EditorRegistry.shared.apply(.blockquote)
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])

                Button("Code Block") {
                    EditorRegistry.shared.apply(.codeBlock)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Link") {
                    EditorRegistry.shared.apply(.link)
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}
