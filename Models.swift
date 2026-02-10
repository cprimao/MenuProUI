import Foundation

struct Client: Identifiable, Hashable {
    let id: String
    var name: String
    var tags: String
}

struct SSHServer: Identifiable, Hashable {
    var id: String { alias }
    let alias: String
    let clientId: String
    var name: String
    var host: String
    var port: Int
    var user: String
    var tags: String
}

struct RDPServer: Identifiable, Hashable {
    var id: String { alias }
    let alias: String
    let clientId: String
    var name: String
    var host: String
    var port: Int
    var domain: String
    var user: String
    var tags: String
}

/// ✅ Novo: acessos HTTPS (Firewall/VMware/etc.)
struct URLAccess: Identifiable, Hashable {
    var id: String { alias }
    let alias: String
    let clientId: String
    var name: String
    var host: String
    var port: Int
    var path: String
    var tags: String
}

enum ConnType: String { case ssh = "SSH", rdp = "RDP" }

struct ConnLogPoint: Identifiable {
    let id = UUID()
    let day: Date
    let type: ConnType
    let count: Int
}
