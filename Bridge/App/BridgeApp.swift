import SwiftUI
import BridgeKit

/// The application.
///
/// Everything else lives in `BridgeKit`, which is a library on purpose: it can
/// be compiled and tested from the command line without an Xcode project, and
/// `swift build --package-path Bridge` is the fastest way to find what the
/// compiler disagrees with.
///
/// This file is the only part that needs an app target around it. Add it to a
/// macOS app target in Xcode, add BridgeKit as a local package dependency, and
/// the console runs. See `docs/OPENING_IN_XCODE.md`.
@main
struct BridgeApp: App {
    var body: some Scene {
        WindowGroup {
            BridgeRootView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .defaultSize(width: 1280, height: 820)
        .commands {
            // The console is a reading tool as much as a working one, so the
            // standard text-size commands are worth having.
            SidebarCommands()
        }
    }
}
