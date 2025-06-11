import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        StartView()
    }
}

#Preview {
    ContentView()
}
