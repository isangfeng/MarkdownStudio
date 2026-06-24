import SwiftUI
import MarkdownStudioCore

struct SidebarView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        List(selection: Binding(
            get: { store.fileURL },
            set: { url in
                if let url {
                    store.loadRecentDocument(url)
                }
            }
        )) {
            Section("Current") {
                Label(store.currentDocumentDisplayName, systemImage: store.isDirty ? "doc.badge.ellipsis" : "doc.text")
                    .lineLimit(2)
                    .tag(store.fileURL)
                    .help(store.fileURL?.path ?? store.displayName)
            }

            Section("Recent") {
                if store.visibleRecentDocuments.isEmpty {
                    Text("No recent files")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.visibleRecentDocuments, id: \.self) { url in
                        recentDocumentRow(url)
                    }
                }
            }

            Section("Outline") {
                if store.outlineItems.isEmpty {
                    Text("No headings")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.outlineItems) { item in
                        outlineRow(item)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                Button {
                    store.newDocument()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("New Document")

                Button {
                    store.openDocument()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Open Document")

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    private func recentDocumentRow(_ url: URL) -> some View {
        Label(store.recentDocumentDisplayName(for: url), systemImage: "doc.text")
            .lineLimit(2)
            .tag(Optional(url))
            .help(url.path)
    }

    private func outlineRow(_ item: MarkdownOutlineItem) -> some View {
        HStack(spacing: 6) {
            Text("H\(item.level)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)

            Text(item.title)
                .lineLimit(1)
        }
        .padding(.leading, CGFloat(max(0, item.level - 1)) * 10)
        .help("Line \(item.lineNumber)")
    }
}
