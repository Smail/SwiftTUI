import SwiftTUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello")
                // Without .frame, the .position modifier takes up the whole screen space
                // This is standard behavior in SwiftUI.
                .frame(width: 20, height: 10)
                .position(x: 50, y: 30)
                .background(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
