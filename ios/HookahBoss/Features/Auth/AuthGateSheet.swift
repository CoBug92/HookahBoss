import AuthenticationServices
import SwiftUI

struct AuthGateSheet: ViewModifier {
    @ObservedObject var gate: AuthGate
    let authenticateIdentityToken: (String,String?) async throws -> Void
    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(get: { gate.state != .hidden }, set: { if !$0 { gate.cancel() } })) {
            VStack(spacing: 18) {
                if let action { Text(action.title).font(.title2.bold()); Text(action.body).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                if case .loading = gate.state { ProgressView().accessibilityLabel(Text(L10n.Auth.loading)) }
                else {
                    SignInWithAppleButton(.continue) { _ in gate.begin() } onCompletion: { result in Task { await complete(result) } }
                        .signInWithAppleButtonStyle(.black).frame(height: 50).accessibilityLabel(Text(L10n.Auth.apple))
                    if case .failed = gate.state { Text(L10n.Auth.error).foregroundStyle(.red); Text(L10n.Auth.retryHint).font(.caption).foregroundStyle(.secondary) }
                    Button(L10n.Auth.cancel) { gate.cancel() }
                }
            }.padding(24).presentationDetents([.medium]).interactiveDismissDisabled(gate.state.isLoading).accessibilityIdentifier("auth.sheet")
        }
    }
    private var action: ProtectedAction? { switch gate.state { case .prompt(let a), .loading(let a), .failed(let a): a; case .hidden: nil } }
    private func complete(_ result: Result<ASAuthorization, Error>) async {
        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else { throw AuthFlowError.missingIdentityToken }
            let code=credential.authorizationCode.flatMap{String(data:$0,encoding:.utf8)}
            try await authenticateIdentityToken(token,code); gate.succeed()
        } catch let error as ASAuthorizationError where error.code == .canceled { gate.cancel() }
        catch { gate.fail() }
    }
}

private extension AuthGate.State { var isLoading: Bool { if case .loading = self { true } else { false } } }
