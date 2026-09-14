import Foundation

actor DiskPublicCache: PublicCache {
    private let directory: URL

    init(directory: URL? = nil) {
        self.directory =
            directory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appending(path: "PublicAPI", directoryHint: .isDirectory)
    }

    func read(_ key: String) -> Data? {
        try? Data(contentsOf: file(key))
    }

    func write(_ data: Data, key: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(key), options: .atomic)
    }

    private func file(_ key: String) -> URL {
        directory.appending(path: key.replacingOccurrences(of: "/", with: "_") + ".json")
    }
}
