import Foundation
import Combine

final class CSVStore: ObservableObject {
    @Published var clients: [Client] = []
    @Published var ssh: [SSHServer] = []
    @Published var rdp: [RDPServer] = []
    @Published var urls: [URLAccess] = []

    private let fm = FileManager.default
    private let baseURL: URL
    private let clientsURL: URL
    private let sshURL: URL
    private let rdpURL: URL
    private let urlsURL: URL

    init() {
        let home = fm.homeDirectoryForCurrentUser
        baseURL = home.appendingPathComponent(".menu-acessos", isDirectory: true)
        clientsURL = baseURL.appendingPathComponent("clients.csv")
        sshURL = baseURL.appendingPathComponent("ssh.csv")
        rdpURL = baseURL.appendingPathComponent("rdp.csv")
        urlsURL = baseURL.appendingPathComponent("urls.csv")
        ensureFiles()
        reload()
    }

    func ensureFiles() {
        try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)

        ensureFile(clientsURL, header: "client_id,client_name,tags\n")
        ensureFile(sshURL, header: "alias,client_id,server_name,host,port,user,tags\n")
        ensureFile(rdpURL, header: "alias,client_id,server_name,host,port,domain,user,tags\n")
        // ✅ novo
        ensureFile(urlsURL, header: "alias,client_id,name,host,port,path,tags\n")
    }

    private func ensureFile(_ url: URL, header: String) {
        if !fm.fileExists(atPath: url.path) {
            try? header.data(using: .utf8)?.write(to: url)
        }
    }

    func reload() {
        clients = loadClients()
        ssh = loadSSH()
        rdp = loadRDP()
        urls = loadURLs()
    }

    // MARK: - Helpers
    private func readLines(_ url: URL) -> [String] {
        guard let s = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return s.split(whereSeparator: \.isNewline).map(String.init)
    }

    private func splitCSV(_ line: String) -> [String] {
        line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
    }

    private func sanitizeCSV(_ value: String) -> String {
        value
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func rewriteFile(_ url: URL, header: String, rows: [String]) throws {
        let content = ([header] + rows).joined(separator: "\n") + "\n"
        try content.data(using: .utf8)!.write(to: url, options: .atomic)
    }

    private func appendLine(_ url: URL, _ line: String) throws {
        let data = (line + "\n").data(using: .utf8)!
        if fm.fileExists(atPath: url.path),
           let handle = try? FileHandle(forWritingTo: url) {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.close()
        } else {
            try data.write(to: url)
        }
    }

    // MARK: - Load
    private func loadClients() -> [Client] {
        readLines(clientsURL).dropFirst().compactMap { l in
            let c = splitCSV(l); guard c.count >= 3 else { return nil }
            return Client(id: c[0], name: c[1], tags: c[2])
        }.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private func loadSSH() -> [SSHServer] {
        readLines(sshURL).dropFirst().compactMap { l in
            let c = splitCSV(l); guard c.count >= 7 else { return nil }
            return SSHServer(alias: c[0], clientId: c[1], name: c[2], host: c[3],
                             port: Int(c[4]) ?? 22, user: c[5], tags: c[6])
        }
    }

    private func loadRDP() -> [RDPServer] {
        readLines(rdpURL).dropFirst().compactMap { l in
            let c = splitCSV(l); guard c.count >= 8 else { return nil }
            return RDPServer(alias: c[0], clientId: c[1], name: c[2], host: c[3],
                             port: Int(c[4]) ?? 3389, domain: c[5], user: c[6], tags: c[7])
        }
    }

    private func loadURLs() -> [URLAccess] {
        readLines(urlsURL).dropFirst().compactMap { l in
            let c = splitCSV(l); guard c.count >= 7 else { return nil }
            return URLAccess(
                alias: c[0], clientId: c[1], name: c[2], host: c[3],
                port: Int(c[4]) ?? 443, path: c[5], tags: c[6]
            )
        }
    }

    // MARK: - Clients CRUD
    func addClient(id: String, name: String, tags: String) throws {
        let line = "\(sanitizeCSV(id)),\(sanitizeCSV(name)),\(sanitizeCSV(tags))"
        try appendLine(clientsURL, line)
        reload()
    }

    func updateClient(_ updated: Client) throws {
        let header = "client_id,client_name,tags"
        let lines = readLines(clientsURL).dropFirst()
        var out: [String] = []

        for l in lines {
            let c = splitCSV(l); guard c.count >= 3 else { continue }
            if c[0].lowercased() == updated.id.lowercased() {
                out.append("\(sanitizeCSV(updated.id)),\(sanitizeCSV(updated.name)),\(sanitizeCSV(updated.tags))")
            } else {
                out.append(l)
            }
        }
        try rewriteFile(clientsURL, header: header, rows: out)
        reload()
    }

    /// ✅ Apaga cliente e remove SSH/RDP/URLs (cascata)
    func deleteClientCascade(clientId: String) throws {
        // clients
        do {
            let header = "client_id,client_name,tags"
            let lines = readLines(clientsURL).dropFirst()
            let kept = lines.filter { splitCSV($0).first?.lowercased() != clientId.lowercased() }
            try rewriteFile(clientsURL, header: header, rows: Array(kept))
        }

        // ssh
        do {
            let header = "alias,client_id,server_name,host,port,user,tags"
            let lines = readLines(sshURL).dropFirst()
            let kept = lines.filter {
                let c = splitCSV($0); return (c.count >= 2) ? (c[1].lowercased() != clientId.lowercased()) : true
            }
            try rewriteFile(sshURL, header: header, rows: Array(kept))
        }

        // rdp
        do {
            let header = "alias,client_id,server_name,host,port,domain,user,tags"
            let lines = readLines(rdpURL).dropFirst()
            let kept = lines.filter {
                let c = splitCSV($0); return (c.count >= 2) ? (c[1].lowercased() != clientId.lowercased()) : true
            }
            try rewriteFile(rdpURL, header: header, rows: Array(kept))
        }

        // urls
        do {
            let header = "alias,client_id,name,host,port,path,tags"
            let lines = readLines(urlsURL).dropFirst()
            let kept = lines.filter {
                let c = splitCSV($0); return (c.count >= 2) ? (c[1].lowercased() != clientId.lowercased()) : true
            }
            try rewriteFile(urlsURL, header: header, rows: Array(kept))
        }

        reload()
    }

    // MARK: - SSH CRUD
    func addSSH(alias: String, clientId: String, name: String, host: String, port: Int, user: String, tags: String) throws {
        let p = (1...65535).contains(port) ? port : 22
        let line = "\(sanitizeCSV(alias)),\(sanitizeCSV(clientId)),\(sanitizeCSV(name)),\(sanitizeCSV(host)),\(p),\(sanitizeCSV(user)),\(sanitizeCSV(tags))"
        try appendLine(sshURL, line)
        reload()
    }

    func updateSSH(_ updated: SSHServer) throws {
        let header = "alias,client_id,server_name,host,port,user,tags"
        let lines = readLines(sshURL).dropFirst()
        var out: [String] = []

        for l in lines {
            let c = splitCSV(l); guard c.count >= 7 else { continue }
            if c[0].lowercased() == updated.alias.lowercased() {
                let p = (1...65535).contains(updated.port) ? updated.port : 22
                out.append("\(sanitizeCSV(updated.alias)),\(sanitizeCSV(updated.clientId)),\(sanitizeCSV(updated.name)),\(sanitizeCSV(updated.host)),\(p),\(sanitizeCSV(updated.user)),\(sanitizeCSV(updated.tags))")
            } else {
                out.append(l)
            }
        }
        try rewriteFile(sshURL, header: header, rows: out)
        reload()
    }

    func deleteSSH(alias: String) throws {
        let header = "alias,client_id,server_name,host,port,user,tags"
        let lines = readLines(sshURL).dropFirst()
        let kept = lines.filter { splitCSV($0).first?.lowercased() != alias.lowercased() }
        try rewriteFile(sshURL, header: header, rows: Array(kept))
        reload()
    }

    // MARK: - RDP CRUD
    func addRDP(alias: String, clientId: String, name: String, host: String, port: Int, domain: String, user: String, tags: String) throws {
        let p = (1...65535).contains(port) ? port : 3389
        let line = "\(sanitizeCSV(alias)),\(sanitizeCSV(clientId)),\(sanitizeCSV(name)),\(sanitizeCSV(host)),\(p),\(sanitizeCSV(domain)),\(sanitizeCSV(user)),\(sanitizeCSV(tags))"
        try appendLine(rdpURL, line)
        reload()
    }

    func updateRDP(_ updated: RDPServer) throws {
        let header = "alias,client_id,server_name,host,port,domain,user,tags"
        let lines = readLines(rdpURL).dropFirst()
        var out: [String] = []

        for l in lines {
            let c = splitCSV(l); guard c.count >= 8 else { continue }
            if c[0].lowercased() == updated.alias.lowercased() {
                let p = (1...65535).contains(updated.port) ? updated.port : 3389
                out.append("\(sanitizeCSV(updated.alias)),\(sanitizeCSV(updated.clientId)),\(sanitizeCSV(updated.name)),\(sanitizeCSV(updated.host)),\(p),\(sanitizeCSV(updated.domain)),\(sanitizeCSV(updated.user)),\(sanitizeCSV(updated.tags))")
            } else {
                out.append(l)
            }
        }
        try rewriteFile(rdpURL, header: header, rows: out)
        reload()
    }

    func deleteRDP(alias: String) throws {
        let header = "alias,client_id,server_name,host,port,domain,user,tags"
        let lines = readLines(rdpURL).dropFirst()
        let kept = lines.filter { splitCSV($0).first?.lowercased() != alias.lowercased() }
        try rewriteFile(rdpURL, header: header, rows: Array(kept))
        reload()
    }

    // MARK: - URL (HTTPS) CRUD
    func addURL(_ u: URLAccess) throws {
        let p = (1...65535).contains(u.port) ? u.port : 443
        let path = u.path.isEmpty ? "/" : u.path
        let line = "\(sanitizeCSV(u.alias)),\(sanitizeCSV(u.clientId)),\(sanitizeCSV(u.name)),\(sanitizeCSV(u.host)),\(p),\(sanitizeCSV(path)),\(sanitizeCSV(u.tags))"
        try appendLine(urlsURL, line)
        reload()
    }

    func updateURL(_ u: URLAccess) throws {
        let header = "alias,client_id,name,host,port,path,tags"
        let lines = readLines(urlsURL).dropFirst()
        var out: [String] = []

        for l in lines {
            let c = splitCSV(l); guard c.count >= 7 else { continue }
            if c[0].lowercased() == u.alias.lowercased() {
                let p = (1...65535).contains(u.port) ? u.port : 443
                let path = u.path.isEmpty ? "/" : u.path
                out.append("\(sanitizeCSV(u.alias)),\(sanitizeCSV(u.clientId)),\(sanitizeCSV(u.name)),\(sanitizeCSV(u.host)),\(p),\(sanitizeCSV(path)),\(sanitizeCSV(u.tags))")
            } else {
                out.append(l)
            }
        }
        try rewriteFile(urlsURL, header: header, rows: out)
        reload()
    }

    func deleteURL(alias: String) throws {
        let header = "alias,client_id,name,host,port,path,tags"
        let lines = readLines(urlsURL).dropFirst()
        let kept = lines.filter { splitCSV($0).first?.lowercased() != alias.lowercased() }
        try rewriteFile(urlsURL, header: header, rows: Array(kept))
        reload()
    }
}
