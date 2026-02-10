import SwiftUI

struct AddClientView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var id = ""
    @State private var name = ""
    @State private var tags = ""

    let onSave: (_ id: String, _ name: String, _ tags: String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cadastrar Cliente").font(.title2).bold()

            Form {
                TextField("ID (ex: c123 / cliente01)", text: $id)
                TextField("Nome (ex: Santa Casa)", text: $name)
                TextField("Tags (opcional)", text: $tags)
            }

            HStack {
                Button("Cancelar") { dismiss() }
                Spacer()
                Button("Salvar") {
                    onSave(id.trimmed, name.trimmed, tags.trimmed)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(id.trimmed.isEmpty || name.trimmed.isEmpty)
            }
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
