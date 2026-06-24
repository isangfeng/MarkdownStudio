import SwiftUI
import SumiCore

struct ContentView: View {
    @EnvironmentObject private var model: SingleDocumentModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .environmentObject(model)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            EditorPane()
                .environmentObject(model)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    toggleSidebar()
                } label: {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
                .help("Toggle Sidebar")

                Button {
                    DocumentActions.newDocument()
                } label: {
                    Label("New", systemImage: "square.and.pencil")
                }

                Button {
                    DocumentActions.openDocument()
                } label: {
                    Label("Open", systemImage: "folder")
                }

                Button {
                    _ = model.save()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
            }

            ToolbarItemGroup {
                MarkdownToolbarButton(title: "Bold", systemImage: "bold", style: .bold)
                MarkdownToolbarButton(title: "Italic", systemImage: "italic", style: .italic)
                MarkdownToolbarButton(title: "Code", systemImage: "curlybraces", style: .inlineCode)
                Menu {
                    Button("Heading 1") { EditorRegistry.shared.apply(.heading(1)) }
                    Button("Heading 2") { EditorRegistry.shared.apply(.heading(2)) }
                    Button("Heading 3") { EditorRegistry.shared.apply(.heading(3)) }
                    Button("Heading 4") { EditorRegistry.shared.apply(.heading(4)) }
                    Button("Heading 5") { EditorRegistry.shared.apply(.heading(5)) }
                    Button("Heading 6") { EditorRegistry.shared.apply(.heading(6)) }
                    Divider()
                    Button("Paragraph") { EditorRegistry.shared.apply(.paragraph) }
                } label: {
                    Label("Heading", systemImage: "textformat.size")
                }
                .help("Heading")
                MarkdownToolbarButton(title: "List", systemImage: "list.bullet", style: .bulletList)
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Link") { EditorRegistry.shared.apply(.link) }
                    Button("Image") { EditorRegistry.shared.apply(.image) }
                    Button("Table") { EditorRegistry.shared.apply(.table) }
                    Divider()
                    Button("Horizontal Rule") { EditorRegistry.shared.apply(.horizontalRule) }
                    Button("Code Block") { EditorRegistry.shared.apply(.codeBlock) }
                    Button("Blockquote") { EditorRegistry.shared.apply(.blockquote) }
                } label: {
                    Label("Insert", systemImage: "plus.circle")
                }
                .help("Insert")
            }
        }
    }

    private func toggleSidebar() {
        columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
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
