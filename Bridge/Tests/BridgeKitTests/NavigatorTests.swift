import XCTest
@testable import BridgeKit

/// Bridge keeps its own history, and a breadcrumb tap truncates it rather than
/// popping once. That is not how a plain navigation stack behaves, so it is
/// tested directly.
final class NavigatorTests: XCTestCase {

    func testGoPushesAndBackPops() {
        let nav = Navigator(route: Route(.home))
        nav.go(.facturas)
        nav.go(.factura, "inv-1")
        XCTAssertEqual(nav.route, Route(.factura, "inv-1"))
        XCTAssertEqual(nav.crumbs.map(\.screen), [.home, .facturas, .factura])
        nav.back()
        XCTAssertEqual(nav.route, Route(.facturas))
    }

    /// Tapping the first crumb drops everything after it, not just one level.
    func testBreadcrumbJumpTruncates() {
        let nav = Navigator(route: Route(.home))
        nav.go(.facturas)
        nav.go(.factura, "inv-1")
        nav.go(.evento, "ev-9")
        nav.jump(toCrumb: 0)
        XCTAssertEqual(nav.route, Route(.home))
        XCTAssertTrue(nav.stack.isEmpty)
    }

    /// Replacing does not deepen the trail, so Back never lands on a screen
    /// nobody chose.
    func testReplaceDoesNotDeepenTheTrail() {
        let nav = Navigator(route: Route(.home))
        nav.go(.facturas)
        nav.go(.cobranza, replace: true)
        XCTAssertEqual(nav.crumbs.map(\.screen), [.home, .cobranza])
    }

    func testBackAtTheRootIsHarmless() {
        let nav = Navigator(route: Route(.home))
        nav.back()
        XCTAssertEqual(nav.route, Route(.home))
    }

    /// Signing out forgets where the person had been.
    func testResetClearsHistory() {
        let nav = Navigator(route: Route(.home))
        nav.go(.facturas)
        nav.reset()
        XCTAssertEqual(nav.route, Route(.login))
        XCTAssertTrue(nav.stack.isEmpty)
    }

    /// The `route:id` token the prototype uses round-trips.
    func testRouteTokenRoundTrip() {
        XCTAssertEqual(Route(token: "factura:inv-1"), Route(.factura, "inv-1"))
        XCTAssertEqual(Route(token: "home"), Route(.home))
        XCTAssertNil(Route(token: "nonsense"))
        XCTAssertEqual(Route(.factura, "inv-1").token, "factura:inv-1")
    }

    /// Every route a role can reach resolves to a screen the host can show.
    func testEveryRoleScreenIsAKnownRoute() {
        for role in Role.allCases {
            for screen in role.screens {
                XCTAssertNotNil(Screen(rawValue: screen.rawValue))
            }
        }
    }
}
