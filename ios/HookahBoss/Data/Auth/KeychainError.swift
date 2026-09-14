import Security

struct KeychainError: Error {
    let status: OSStatus

    init(_ status: OSStatus) {
        self.status = status
    }
}
