import AuthenticationServices
import SwiftUI

struct AuthGateSheet: ViewModifier {
    @ObservedObject var gate: AuthGate
    let authenticateIdentityToken: (String,String?) async throws -> Void
    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(get: { gate.state != .hidden }, set: { if !$0 { gate.cancel() } })) {
            VStack(alignment:.leading,spacing: 18) {
                Capsule().fill(.secondary.opacity(0.3)).frame(width:38,height:4).frame(maxWidth:.infinity)
                Image(systemName:"heart.fill").font(.title2).foregroundStyle(AppTheme.gold).frame(width:50,height:50).background(AppTheme.gold.opacity(0.12),in:Circle())
                if let action { Text(action.title.uppercased()).font(.caption.bold()).tracking(1.1).foregroundStyle(AppTheme.gold);Text(action.body).font(.system(size:27,weight:.bold,design:.serif)).fixedSize(horizontal:false,vertical:true) }
                if case .loading = gate.state { ProgressView().accessibilityLabel(Text(L10n.Auth.loading)) }
                else {
                    SignInWithAppleButton(.continue) { _ in gate.begin() } onCompletion: { result in Task { await complete(result) } }
                        .signInWithAppleButtonStyle(.black).frame(height: 52).clipShape(RoundedRectangle(cornerRadius:14)).accessibilityLabel(Text(L10n.Auth.apple))
                    if case .failed = gate.state { Text(L10n.Auth.error).foregroundStyle(.red); Text(L10n.Auth.retryHint).font(.caption).foregroundStyle(.secondary) }
                    Button(L10n.Auth.cancel) { gate.cancel() }.frame(maxWidth:.infinity).foregroundStyle(.secondary)
                }
            }.padding(.horizontal,20).padding(.bottom,24).presentationDetents([.height(390)]).presentationCornerRadius(28).presentationBackground(AppTheme.card).interactiveDismissDisabled(gate.state.isLoading).accessibilityIdentifier("auth.sheet")
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
