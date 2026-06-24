import SwiftUI

struct EditorPane: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            ZStack {
                Color(nsColor: .textBackgroundColor)
                    .ignoresSafeArea()

                MarkdownEditor(text: Binding(
                    get: { store.activeText },
                    set: { store.updateActiveText($0) }
                ))
            }
            .overlay(alignment: .topTrailing) {
                if store.activeIsDirty {
                    Text("Edited")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(store.activeDisplayName)
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.openDocuments) { document in
                    documentTab(document)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
        }
        .frame(height: 40)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func documentTab(_ document: OpenDocument) -> some View {
        let isActive = document.id == store.activeDocumentID

        return HStack(spacing: 6) {
            Button {
                store.selectDocument(document.id)
            } label: {
                HStack(spacing: 5) {
                    Text(store.displayName(for: document))
                        .lineLimit(1)

                    if document.isDirty {
                        Text("●")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: 180, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                store.closeDocument(document.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color(nsColor: .textBackgroundColor) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .padding(.trailing, 4)
        .help(document.fileURL?.path ?? store.displayName(for: document))
    }
}
