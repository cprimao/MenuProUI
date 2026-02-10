import SwiftUI

struct EditRDPView: View {
    @Environment(\.dismiss) private var dismiss
    @State var item: RDPServer
    let onSave: (RDPServer) -> Void

    @State private var portText: String

    init(item: RDPServer, onSave: @escaping (RDPServer) -> Void) {
        self._item = State(initialValue: item)
        self.onSave = onSave
        self._portText = State(initialValue: "\(item.port)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Editar RDP").font(.title2).bold()

            Form {
                Text("Alias: \(item.alias)").foregroundStyle(.secondary)
                Text("Cliente: \(item.clientId)").foregroundStyle(.secondary)

                TextField("Nome", text: $item.name)
                TextField("Host/IP", text: $item.host)
                TextField("Porta", text: $portText)
                TextField("Domínio", text: $item.domain)
                TextField("Usuário", text: $item.user)
                TextField("Tags", text: $item.tags)
            }

            HStack {
                Button("Cancelar") { dismiss() }
                Spacer()
                Button("Salvar") {
                    item.port = Int(portText.trimmed) ?? item.port
                    onSave(item)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
