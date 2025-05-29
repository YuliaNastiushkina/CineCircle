import SwiftUI

struct ContentView: View {
    var body: some View {
        StartView()
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}
