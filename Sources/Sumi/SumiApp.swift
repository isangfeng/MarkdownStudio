import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var registry: DocumentRegistry { AppController.shared.registry }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            AppController.shared.openUntitledDocumentIfNeeded()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            AppController.shared.openUntitledDocumentIfNeeded()
        }
        return true
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let dirtyModels = registry.dirtyModels
        guard !dirtyModels.isEmpty else {
            return .terminateNow
        }

        let alert = NSAlert()
        alert.messageText = "Save changes to open documents?"
        alert.informativeText = "Your changes will be lost if you do not save them."
        alert.addButton(withTitle: "Save All")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Discard All")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            for model in dirtyModels where !model.save() {
                return .terminateCancel
            }
            return .terminateNow
        case .alertThirdButtonReturn:
            return .terminateNow
        default:
            return .terminateCancel
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct SumiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            DocumentCommands()

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

@MainActor
private struct DocumentCommands: Commands {
    private var focusedModel: SingleDocumentModel? {
        AppController.shared.selectedModel
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Document") {
                AppController.shared.newDocument()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open...") {
                AppController.shared.openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Close Document") {
                NSApp.keyWindow?.performClose(nil)
            }
            .keyboardShortcut("w", modifiers: .command)
        }

        CommandGroup(after: .saveItem) {
            Button("Save") {
                _ = focusedModel?.save()
            }
            .keyboardShortcut("s", modifiers: .command)

            Button("Save As...") {
                _ = focusedModel?.saveAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }
}
