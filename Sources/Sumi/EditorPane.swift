import SwiftUI

struct EditorPane: View {
    @EnvironmentObject private var model: SingleDocumentModel

    var body: some View {
        ZStack {
            Color(nsColor: .textBackgroundColor)
                .ignoresSafeArea()

            MarkdownEditor(text: Binding(
                get: { model.text },
                set: { model.updateText($0) }
            ))
        }
        .navigationTitle(model.tabTitle)
    }
}
