import SwiftUI
import MarkdownStudioCore

struct ContentView: View {
    @EnvironmentObject private var store: DocumentStore
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            EditorPane()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    store.newDocument()
                } label: {
                    Label("New", systemImage: "square.and.pencil")
                }

                Button {
                    store.openDocument()
                } label: {
                    Label("Open", systemImage: "folder")
                }

                Button {
                    store.save()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(!store.activeIsDirty && store.activeFileURL != nil)
            }

            ToolbarItemGroup {
                MarkdownToolbarButton(title: "Bold", systemImage: "bold", style: .bold)
                MarkdownToolbarButton(title: "Italic", systemImage: "italic", style: .italic)
                MarkdownToolbarButton(title: "Code", systemImage: "curlybraces", style: .inlineCode)
                MarkdownToolbarButton(title: "Heading", systemImage: "textformat.size", style: .heading(2))
                MarkdownToolbarButton(title: "List", systemImage: "list.bullet", style: .bulletList)
                MarkdownToolbarButton(title: "Link", systemImage: "link", style: .link)
            }
        }
    }
}

private struct MarkdownToolbarButton: View {
    var title: String
    var systemImage: String
    var style: MarkdownFormatStyle

    var body: some View {
        Button {
            EditorRegistry.shared.apply(style)
        } label: {
            Label(title, systemImage: systemImage)
        }
        .help(title)
    }
}
