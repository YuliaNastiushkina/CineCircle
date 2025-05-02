import SwiftUI
import SwiftData

struct FilteredFriendList: View {
    @State var searchText: String = ""
    
    var body: some View {
        NavigationSplitView {
            FriendsList(nameFilter: searchText)
                .searchable(text: $searchText)
        } detail: {
            Text("Select a friend")
                .navigationTitle("Friend")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FilteredFriendList()
        .modelContainer(SampleData.shared.modelContainer)
}
