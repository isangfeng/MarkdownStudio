import SwiftUI
import MarkdownStudioCore

struct SidebarView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        List {
            Section("Current") {
                ForEach(store.openDocuments) { document in
                    currentDocumentRow(document)
                }
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

    private func currentDocumentRow(_ document: OpenDocument) -> some View {
        Button {
            store.selectDocument(document.id)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: document.isDirty ? "doc.badge.ellipsis" : "doc.text")
                    .foregroundStyle(document.id == store.activeDocumentID ? .primary : .secondary)

                Text(store.displayName(for: document))
                    .lineLimit(2)

                if document.isDirty {
                    Text("●")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .help(document.fileURL?.path ?? store.displayName(for: document))
    }

    private func recentDocumentRow(_ url: URL) -> some View {
        Button {
            store.loadRecentDocument(url)
        } label: {
            Label(store.recentDocumentDisplayName(for: url), systemImage: "doc.text")
                .lineLimit(2)
        }
        .buttonStyle(.plain)
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
