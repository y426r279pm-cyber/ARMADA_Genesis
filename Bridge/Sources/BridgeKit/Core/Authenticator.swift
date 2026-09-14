import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

/// The authenticator behind the approval gate.
///
/// On Apple hardware this is Touch ID, Face ID or a paired Watch, evaluated by
/// `LocalAuthentication`. The prototype could only draw this control; here it is
/// one, which is a large part of why the port is worth doing.
///
/// Every path that is not an explicit confirmation or an explicit refusal
/// returns `.ambiguous`, and the gate treats that as a refusal. The failure this
/// prevents is a second payment to a supplier who was already paid.
public struct Authenticator: Sendable {

    /// Injected so the gate can be tested. Production builds use `.system`.
    public var evaluate: @Sendable (String) async -> ApprovalGate.AuthenticationResult

    public init(evaluate: @escaping @Sendable (String) async -> ApprovalGate.AuthenticationResult) {
        self.evaluate = evaluate
    }

    public static let system = Authenticator { reason in
        #if canImport(LocalAuthentication)
        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No enrolled biometric and no passcode is not a refusal by the
            // person; it is a device that cannot answer. Ambiguous, so refused.
            return .ambiguous
        }
        do {
            let confirmed = try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                             localizedReason: reason)
            return confirmed ? .confirmed : .refused
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .userFallback, .systemCancel, .appCancel:
                return .refused
            case .authenticationFailed:
                return .refused
            default:
                // Timeouts, an unavailable sensor, a device lock, anything new
                // in a later OS: no answer, so no approval.
                return .ambiguous
            }
        } catch {
            return .ambiguous
        }
        #else
        return .ambiguous
        #endif
    }

    /// For previews and tests.
    public static func always(_ result: ApprovalGate.AuthenticationResult) -> Authenticator {
        Authenticator { _ in result }
    }
}
