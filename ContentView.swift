import SwiftUI
import Combine
import Charts

struct ContentView: View {
    @StateObject private var store = CSVStore()
    @StateObject private var logs = LogParser()

    @State private var selectedClientId: String?

    // Add sheets
    @State private var showAddClient = false
    @State private var showAddSSH = false
    @State private var showAddRDP = false
    @State private var showAddURL = false

    // Edit sheets
    @State private var editingClient: Client?
    @State private var editingSSH: SSHServer?
    @State private var editingRDP: RDPServer?
    @State private var editingURL: URLAccess?

    // Deletes
    @State private var confirmDeleteClient: Client?
    @State private var confirmDeleteSSH: SSHServer?
    @State private var confirmDeleteRDP: RDPServer?
    @State private var confirmDeleteURL: URLAccess?

    // Errors
    @State private var errorMessage: String?
    @State private var showError = false

    private var selectedClient: Client? {
        guard let id = selectedClientId else { return nil }
        return store.clients.first(where: { $0.id.lowercased() == id.lowercased() })
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .tint(.blue)
        .alert("Erro", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Erro desconhecido")
        }
        .onAppear {
            if selectedClientId == nil {
                selectedClientId = store.clients.first?.id
            }
        }

        // MARK: - Add
        .sheet(isPresented: $showAddClient) {
            AddClientView { id, name, tags in
                do {
                    try store.addClient(id: id, name: name, tags: tags)
                    selectedClientId = store.clients.first(where: { $0.id.lowercased() == id.lowercased() })?.id
                        ?? store.clients.first?.id
                } catch { showErr(error) }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddSSH) {
            AddSSHView(clients: store.clients, preselected: selectedClient) { payload in
                do {
                    try store.addSSH(alias: payload.alias, clientId: payload.clientId, name: payload.name,
                                     host: payload.host, port: payload.port, user: payload.user, tags: payload.tags)
                } catch { showErr(error) }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showAddRDP) {
            AddRDPView(clients: store.clients, preselected: selectedClient) { payload in
                do {
                    try store.addRDP(alias: payload.alias, clientId: payload.clientId, name: payload.name,
                                     host: payload.host, port: payload.port, domain: payload.domain,
                                     user: payload.user, tags: payload.tags)
                } catch { showErr(error) }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showAddURL) {
            AddURLView(clients: store.clients, preselected: selectedClient) { u in
                do { try store.addURL(u) } catch { showErr(error) }
            }
            .presentationDetents([.large])
        }

        // MARK: - Edit
        .sheet(item: $editingClient) { c in
            EditClientView(item: c) { updated in
                do {
                    try store.updateClient(updated)
                    selectedClientId = updated.id
                } catch { showErr(error) }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $editingSSH) { s in
            EditSSHView(item: s) { updated in
                do { try store.updateSSH(updated) } catch { showErr(error) }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $editingRDP) { r in
            EditRDPView(item: r) { updated in
                do { try store.updateRDP(updated) } catch { showErr(error) }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $editingURL) { u in
            EditURLView(item: u) { updated in
                do { try store.updateURL(updated) } catch { showErr(error) }
            }
            .presentationDetents([.large])
        }

        // MARK: - Delete dialogs
        .confirmationDialog("Apagar cliente?", isPresented: Binding(
            get: { confirmDeleteClient != nil },
            set: { if !$0 { confirmDeleteClient = nil } }
        )) {
            Button("Apagar (cascata: SSH/RDP/URLs)", role: .destructive) {
                guard let c = confirmDeleteClient else { return }
                do {
                    try store.deleteClientCascade(clientId: c.id)
                    selectedClientId = store.clients.first?.id
                } catch { showErr(error) }
                confirmDeleteClient = nil
            }
            Button("Cancelar", role: .cancel) { confirmDeleteClient = nil }
        } message: {
            Text(confirmDeleteClient.map { "\($0.name) (\($0.id))" } ?? "")
        }

        .confirmationDialog("Apagar SSH?", isPresented: Binding(
            get: { confirmDeleteSSH != nil },
            set: { if !$0 { confirmDeleteSSH = nil } }
        )) {
            Button("Apagar", role: .destructive) {
                guard let s = confirmDeleteSSH else { return }
                do { try store.deleteSSH(alias: s.alias) } catch { showErr(error) }
                confirmDeleteSSH = nil
            }
            Button("Cancelar", role: .cancel) { confirmDeleteSSH = nil }
        } message: { Text(confirmDeleteSSH?.name ?? "") }

        .confirmationDialog("Apagar RDP?", isPresented: Binding(
            get: { confirmDeleteRDP != nil },
            set: { if !$0 { confirmDeleteRDP = nil } }
        )) {
            Button("Apagar", role: .destructive) {
                guard let r = confirmDeleteRDP else { return }
                do { try store.deleteRDP(alias: r.alias) } catch { showErr(error) }
                confirmDeleteRDP = nil
            }
            Button("Cancelar", role: .cancel) { confirmDeleteRDP = nil }
        } message: { Text(confirmDeleteRDP?.name ?? "") }

        .confirmationDialog("Apagar URL?", isPresented: Binding(
            get: { confirmDeleteURL != nil },
            set: { if !$0 { confirmDeleteURL = nil } }
        )) {
            Button("Apagar", role: .destructive) {
                guard let u = confirmDeleteURL else { return }
                do { try store.deleteURL(alias: u.alias) } catch { showErr(error) }
                confirmDeleteURL = nil
            }
            Button("Cancelar", role: .cancel) { confirmDeleteURL = nil }
        } message: { Text(confirmDeleteURL?.name ?? "") }
    }

    // MARK: - Sidebar
    private var sidebar: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Menu Acessos Pro").font(.title2).bold()
                Spacer()
                Button {
                    store.reload()
                    logs.reload()
                    if selectedClientId == nil { selectedClientId = store.clients.first?.id }
                    if store.clients.first(where: { $0.id.lowercased() == selectedClientId?.lowercased() }) == nil {
                        selectedClientId = store.clients.first?.id
                    }
                } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 8) {
                Button { showAddClient = true } label: { Label("Cliente", systemImage: "plus") }
                    .buttonStyle(.borderedProminent)

                Menu {
                    Button("Cadastrar SSH") { showAddSSH = true }
                    Button("Cadastrar RDP") { showAddRDP = true }
                    Button("Cadastrar URL (HTTPS)") { showAddURL = true }
                } label: {
                    Label("Acesso", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }

            List(selection: $selectedClientId) {
                ForEach(store.clients) { c in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.name).font(.headline)
                        Text(c.id).font(.caption).foregroundStyle(.secondary)
                        if !c.tags.isEmpty {
                            Text(c.tags).font(.caption).foregroundStyle(.blue.opacity(0.9))
                        }
                    }
                    .padding(.vertical, 6)
                    .tag(c.id)
                    .contextMenu {
                        Button("Editar") { editingClient = c }
                        Button("Apagar", role: .destructive) { confirmDeleteClient = c }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.92))
    }

    // MARK: - Detail
    private var detail: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedClient?.name ?? "Visão Geral")
                        .font(.title).bold()
                    Text("SSH/RDP/HTTPS • Portas digitáveis • Azul/Preto")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }

            chartCard

            if let c = selectedClient {
                accessesCard(client: c)
            } else {
                Text("Cadastre ou selecione um cliente.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 30)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.black)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Conexões por dia (SSH x RDP)").font(.headline)

            Chart(logs.points) { p in
                BarMark(
                    x: .value("Dia", p.day, unit: .day),
                    y: .value("Qtd", p.count)
                )
                .foregroundStyle(p.type == .ssh ? .blue : .cyan)
                .position(by: .value("Tipo", p.type.rawValue))
            }
            .chartLegend(.visible)
            .frame(height: 170)
        }
        .padding()
        .background(Color(red: 0.05, green: 0.07, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.25), lineWidth: 1))
    }

    private func accessesCard(client: Client) -> some View {
        let sshList = store.ssh.filter { $0.clientId.lowercased() == client.id.lowercased() }
        let rdpList = store.rdp.filter { $0.clientId.lowercased() == client.id.lowercased() }
        let urlList = store.urls.filter { $0.clientId.lowercased() == client.id.lowercased() }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Acessos").font(.headline)
                Spacer()
                Menu {
                    Button("Cadastrar SSH") { showAddSSH = true }
                    Button("Cadastrar RDP") { showAddRDP = true }
                    Button("Cadastrar URL (HTTPS)") { showAddURL = true }
                } label: {
                    Label("Adicionar", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            HStack(alignment: .top, spacing: 12) {
                // SSH
                VStack(alignment: .leading, spacing: 8) {
                    Text("SSH").font(.subheadline).foregroundStyle(.blue)
                    List(sshList) { s in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.name).font(.headline)
                                Text("\(s.user)@\(s.host):\(s.port)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Abrir") { SSHLauncher.openSSH(host: s.host, port: s.port, user: s.user) }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 6)
                        .contextMenu {
                            Button("Editar") { editingSSH = s }
                            Button("Apagar", role: .destructive) { confirmDeleteSSH = s }
                        }
                    }.frame(minHeight: 170)
                }.frame(maxWidth: .infinity)

                // RDP
                VStack(alignment: .leading, spacing: 8) {
                    Text("RDP").font(.subheadline).foregroundStyle(.cyan)
                    List(rdpList) { r in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.name).font(.headline)
                                Text("\(r.host):\(r.port)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Abrir") { RDPFileWriter.writeAndOpen(server: r) }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 6)
                        .contextMenu {
                            Button("Editar") { editingRDP = r }
                            Button("Apagar", role: .destructive) { confirmDeleteRDP = r }
                        }
                    }.frame(minHeight: 170)
                }.frame(maxWidth: .infinity)

                // URLs
                VStack(alignment: .leading, spacing: 8) {
                    Text("HTTPS").font(.subheadline).foregroundStyle(.mint)
                    List(urlList) { u in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(u.name).font(.headline)
                                Text("https://\(u.host):\(u.port)\(u.path)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Abrir") {
                                URLLauncher.openHTTPS(host: u.host, port: u.port, path: u.path)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 6)
                        .contextMenu {
                            Button("Editar") { editingURL = u }
                            Button("Apagar", role: .destructive) { confirmDeleteURL = u }
                        }
                    }.frame(minHeight: 170)
                }.frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(red: 0.03, green: 0.05, blue: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.18), lineWidth: 1))
    }

    private func showErr(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
