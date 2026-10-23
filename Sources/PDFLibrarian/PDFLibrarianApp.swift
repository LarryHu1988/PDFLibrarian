import SwiftUI

@main
struct PDFLibrarianApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1060, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 1000)
    }
}
