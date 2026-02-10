import SwiftUI

struct AddRDPPayload {
    var alias: String
    var clientId: String
    var name: String
    var host: String
    var port: Int
    var domain: String
    var user: String
    var tags: String
}

struct AddRDPView: View {
    @Environment(\.dismiss) private var dismiss

    let clients: [Client]
    let preselected: Client?
    let onSave: (AddRDPPayload) -> Void

    @State private var alias = ""
    @State private var clientId = ""
    @State private var name = ""
    @State private var host = ""
    @State private var portText = "3389"   // ✅ digitável
    @State private var domain = ""
    @State private var user = ""
    @State private var tags = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cadastrar RDP").font(.title2).bold()

            Form {
                Picker("Cliente", selection: $clientId) {
                    Text("Selecione...").tag("")
                    ForEach(clients, id: \.id) { c in
                        Text("\(c.name) (\(c.id))").tag(c.id)
                    }
                }

                TextField("Alias (ex: scma-rdp01)", text: $alias)
                TextField("Nome do servidor", text: $name)
                TextField("Host/IP", text: $host)

                TextField("Porta (padrão 3389)", text: $portText)

                TextField("Domínio (opcional)", text: $domain)
                TextField("Usuário", text: $user)
                TextField("Tags (opcional)", text: $tags)

                Text("Obs: porta fora do padrão é gravada no .rdp via server port:i:PORT.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Cancelar") { dismiss() }
                Spacer()
                Button("Salvar") {
                    let p = Int(portText.trimmed) ?? 3389
                    onSave(.init(
                        alias: alias.trimmed,
                        clientId: clientId.trimmed,
                        name: name.trimmed,
                        host: host.trimmed,
                        port: p,
                        domain: domain.trimmed,
                        user: user.trimmed,
                        tags: tags.trimmed
                    ))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(clientId.trimmed.isEmpty || alias.trimmed.isEmpty || name.trimmed.isEmpty || host.trimmed.isEmpty || user.trimmed.isEmpty)
            }
        }
        .padding()
        .preferredColorScheme(.dark)
        .onAppear {
            if clientId.isEmpty {
                clientId = preselected?.id ?? clients.first?.id ?? ""
            }
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
