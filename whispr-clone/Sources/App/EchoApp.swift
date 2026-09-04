import SwiftUI

/// Echo is a menu-bar-only app (see `LSUIElement` in project.yml) — there's
/// no main window, so this `Scene` exists only because SwiftUI's `App`
/// protocol requires one. Everything real happens in `AppDelegate`, wired
/// up through `@NSApplicationDelegateAdaptor`.
@main
struct EchoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
