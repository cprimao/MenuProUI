import Foundation
import AppKit

enum RDPFileWriter {
    static func rdpDir() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".menu-acessos/rdpfiles", isDirectory: true)
    }

    static func ensureDir() {
        try? FileManager.default.createDirectory(at: rdpDir(), withIntermediateDirectories: true)
    }

    static func fileURL(alias: String) -> URL {
        rdpDir().appendingPathComponent("\(alias).rdp")
    }

    static func writeAndOpen(server: RDPServer) {
        ensureDir()
        let url = fileURL(alias: server.alias)
        let port = (1...65535).contains(server.port) ? server.port : 3389

        let content =
"""
full address:s:\(server.host)
server port:i:\(port)

username:s:\(server.user)
domain:s:\(server.domain)

prompt for credentials on client:i:1
authentication level:i:2
redirectclipboard:i:1
compression:i:1
screen mode id:i:2
use multimon:i:0
"""

        try? content.data(using: .utf8)?.write(to: url, options: .atomic)
        NSWorkspace.shared.open(url)
    }
}
