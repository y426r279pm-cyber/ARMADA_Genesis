import Foundation

/// Bridge's own history, kept apart from SwiftUI's.
///
/// The prototype keeps `state.stack` and renders a breadcrumb trail from it, and
/// a breadcrumb tap truncates the stack rather than popping once. That is a
/// different shape from a plain navigation stack, so it is modelled here
/// directly and the SwiftUI path follows it.
@Observable
public final class Navigator {
    public private(set) var route: Route
    public private(set) var stack: [Route] = []

    public init(route: Route = Route(.login)) { self.route = route }

    /// Push the current route and open a new one.
    ///
    /// `replace` swaps the current route without deepening the trail — used when
    /// a screen redirects, so Back does not land on a screen nobody chose.
    public func go(_ next: Route, replace: Bool = false) {
        if !replace, route.screen != .login { stack.append(route) }
        route = next
    }

    public func go(_ screen: Screen, _ recordID: String? = nil, replace: Bool = false) {
        go(Route(screen, recordID), replace: replace)
    }

    /// Back through Bridge's history, not the platform's.
    public func back() {
        guard let previous = stack.popLast() else { return }
        route = previous
    }

    /// A breadcrumb tap truncates: everything after the tapped crumb is dropped.
    public func jump(toCrumb index: Int) {
        guard stack.indices.contains(index) else { return back() }
        route = stack[index]
        stack = Array(stack.prefix(index))
    }

    /// The trail as shown: each ancestor, then the current route.
    public var crumbs: [Route] { stack + [route] }

    /// Sign-out returns to the front door and forgets where the person had been.
    public func reset(to screen: Screen = .login) {
        stack.removeAll()
        route = Route(screen)
    }
}
