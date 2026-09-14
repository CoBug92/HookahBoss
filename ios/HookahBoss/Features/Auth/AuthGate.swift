import Combine

@MainActor
final class AuthGate: ObservableObject {
    enum State: Equatable {
        case hidden
        case prompt(ProtectedAction)
        case loading(ProtectedAction)
        case failed(ProtectedAction)
    }

    @Published private(set) var state: State = .hidden
    private var pending: (() -> Void)?

    func request(_ action: ProtectedAction, resume: @escaping () -> Void) {
        guard case .hidden = state else { return }
        pending = resume
        state = .prompt(action)
    }

    func begin() {
        switch state {
        case .prompt(let action), .failed(let action):
            state = .loading(action)
        case .hidden, .loading:
            break
        }
    }

    func succeed() {
        let action = pending
        pending = nil
        state = .hidden
        action?()
    }

    func fail() {
        if case .loading(let action) = state {
            state = .failed(action)
        }
    }

    func cancel() {
        pending = nil
        state = .hidden
    }
}
