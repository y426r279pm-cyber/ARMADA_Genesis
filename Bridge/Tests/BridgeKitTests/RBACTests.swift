import XCTest
@testable import BridgeKit

/// Roles decide what is visible, so they are worth asserting rather than assuming.
final class RBACTests: XCTestCase {

    /// Screens absent from a role are hidden, not disabled — so a role that
    /// cannot open a screen must not be able to reach it by any route.
    func testRolesCannotOpenScreensTheyDoNotHave() {
        XCTAssertFalse(Role.reception.canOpen(.facturas))
        XCTAssertFalse(Role.reception.canOpen(.cadena))
        XCTAssertFalse(Role.auditor.canOpen(.configuracion))
        XCTAssertFalse(Role.`operator`.canOpen(.conciliacion), "the Enterprise group is not the operator's")
    }

    /// Enterprise Admin is Admin plus the Enterprise group, never less.
    func testEnterpriseIsASupersetOfAdmin() {
        let missing = Role.admin.screens.filter { !Role.enterprise.screens.contains($0) }
        XCTAssertTrue(missing.isEmpty,
                      "Enterprise Admin cannot see: \(missing.map(\.rawValue).joined(separator: ", "))")
        let enterpriseOnly = Set(Role.enterprise.screens).subtracting(Role.admin.screens)
        XCTAssertEqual(enterpriseOnly, [.conciliacion, .medidas, .tiendas, .topologia])
    }

    /// Read-only means read-only.
    func testReadOnlyRolesCannotWrite() {
        XCTAssertFalse(Role.auditor.canWrite)
        XCTAssertFalse(Role.reception.canWrite)
        XCTAssertTrue(Role.admin.canWrite)
        XCTAssertTrue(Role.enterprise.canWrite)
    }

    /// The wizard and the policy editor are administrative.
    func testOnlyAdministrativeRolesAreAdmin() {
        XCTAssertEqual(Role.allCases.filter(\.isAdmin), [.admin, .enterprise])
    }

    /// Every role lands somewhere on sign-in.
    func testEveryRoleCanOpenHome() {
        for role in Role.allCases {
            XCTAssertTrue(role.canOpen(.home), "\(role.rawValue) has no home")
        }
    }

    /// A read-only role's action is refused, and refused before it seals.
    @MainActor
    func testReadOnlyActionsAreRefusedAndSealNothing() async {
        let store = AppStore()
        await store.dispatch(.signIn(role: .auditor, user: "a.luna"))
        let before = store.chain.count
        let outcome = await store.dispatch(.pauseAccount(id: "acc-1", paused: true))
        XCTAssertEqual(outcome, .refused(reason: .readOnly))
        XCTAssertEqual(store.chain.count, before, "a refused action must not seal")
    }

    /// A permitted action seals exactly once, and the chain stays intact.
    @MainActor
    func testPermittedActionSealsOnce() async {
        let store = AppStore()
        await store.dispatch(.signIn(role: .admin, user: "m.rios"))
        let outcome = await store.dispatch(.pauseAccount(id: "acc-1", paused: true))
        XCTAssertEqual(outcome, .sealed(seq: 1))
        XCTAssertEqual(store.chain.count, 1)
        XCTAssertTrue(store.chainState.isIntact)
    }
}
