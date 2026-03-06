import SwiftUI

@main
struct PantryApp: App {
    @State private var service = PantryService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(service)
        }
    }
}
