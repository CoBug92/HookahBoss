import AuthenticationServices
import SwiftUI

struct AuthGateSheet: ViewModifier {

    // MARK: - Properties

    @ObservedObject var gate: AuthGate
    let authenticateIdentityToken: (String, String?) async throws -> Void

    // MARK: - Layout

    func body(content: Content) -> some View {
        content.sheet(isPresented: presentationBinding) {
            VStack(alignment: .leading, spacing: Margin.x9) {
                dragIndicator
                actionIcon
                actionDescription
                authenticationContent
            }
            .padding(.horizontal, Margin.x10)
            .padding(.bottom, Margin.x(12))
            .presentationDetents([.height(.sheetHeight)])
            .presentationCornerRadius(.sheetCornerRadius)
            .presentationBackground(AppTheme.card)
            .interactiveDismissDisabled(gate.state.isLoading)
            .accessibilityIdentifier("auth.sheet")
        }
    }

    private var presentationBinding: Binding<Bool> {
        Binding(
            get: { gate.state != .hidden },
            set: { isPresented in
                if !isPresented {
                    gate.cancel()
                }
            }
        )
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(.secondary.opacity(.dragIndicatorOpacity))
            .frame(width: .dragIndicatorWidth, height: Margin.x2)
            .frame(maxWidth: .infinity)
    }

    private var actionIcon: some View {
        Image(systemName: AppSymbol.favoriteFilled)
            .font(.title2)
            .foregroundStyle(AppTheme.gold)
            .frame(width: .actionIconSize, height: .actionIconSize)
            .background(AppTheme.gold.opacity(.actionIconBackgroundOpacity), in: Circle())
    }

    @ViewBuilder
    private var actionDescription: some View {
        if let action {
            Text(action.title.uppercased())
                .font(.caption.bold())
                .tracking(.actionTitleTracking)
                .foregroundStyle(AppTheme.gold)
            Text(action.body)
                .font(.system(size: .actionBodyFontSize, weight: .bold, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var authenticationContent: some View {
        if gate.state.isLoading {
            ProgressView()
                .accessibilityLabel(Text(L10n.Auth.loading))
        } else {
            signInButton
            if gate.state.isFailed {
                Text(L10n.Auth.error)
                    .foregroundStyle(.red)
                Text(L10n.Auth.retryHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(L10n.Auth.cancel) {
                gate.cancel()
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
        }
    }

    private var signInButton: some View {
        SignInWithAppleButton(.continue) { _ in
            gate.begin()
        } onCompletion: { result in
            Task {
                await complete(result)
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: .signInButtonHeight)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Margin.x7,
                style: .continuous
            )
        )
        .accessibilityLabel(Text(L10n.Auth.apple))
    }

    // MARK: - Private methods

    private var action: ProtectedAction? {
        switch gate.state {
        case .prompt(let action), .loading(let action), .failed(let action):
            action
        case .hidden:
            nil
        }
    }

    private func complete(_ result: Result<ASAuthorization, Error>) async {
        do {
            let authorization = try result.get()
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let data = credential.identityToken,
                let token = String(data: data, encoding: .utf8)
            else {
                throw AuthFlowError.missingIdentityToken
            }
            let code = credential.authorizationCode.flatMap {
                String(data: $0, encoding: .utf8)
            }
            try await authenticateIdentityToken(token, code)
            gate.succeed()
        } catch let error as ASAuthorizationError where error.code == .canceled {
            gate.cancel()
        } catch {
            gate.fail()
        }
    }
}

private extension AuthGate.State {
    var isLoading: Bool {
        if case .loading = self {
            true
        } else {
            false
        }
    }

    var isFailed: Bool {
        if case .failed = self {
            true
        } else {
            false
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let sheetHeight: CGFloat = 390
    static let sheetCornerRadius: CGFloat = 28
    static let dragIndicatorWidth: CGFloat = 38
    static let actionIconSize: CGFloat = 50
    static let actionTitleTracking: CGFloat = 1.1
    static let actionBodyFontSize: CGFloat = 27
    static let signInButtonHeight: CGFloat = 52
}

private extension Double {
    static let dragIndicatorOpacity = 0.3
    static let actionIconBackgroundOpacity = 0.12
}

private struct AuthGateSheetPreviewHarness: View {
    @StateObject private var gate = AuthGate()

    var body: some View {
        Color.clear
            .modifier(
                AuthGateSheet(
                    gate: gate,
                    authenticateIdentityToken: { _, _ in }
                )
            )
            .task {
                gate.request(.favorite, resume: {})
            }
    }
}

// MARK: - Preview

#Preview {
    AuthGateSheetPreviewHarness()
}
