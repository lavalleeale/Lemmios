import SwiftUI

struct FiltersView: View {
    @State var showingAdd = false
    @State var newFilter = ""
    @AppStorage("filters") var filters = [String]()
    var body: some View {
        ColoredListComponent {
            Section {
                ForEach(filters, id: \.self) { filter in
                    Text(filter)
                }
                .onDelete { indexSet in
                    filters.remove(atOffsets: indexSet)
                }
                Button("Add Keyword") {
                    showingAdd = true
                }
            } header: {
                Text("Filtered Keywords")
            } footer: {
                Text("Exclude posts containing these keywords in title")
            }
        }
        .alert("Add Filter", isPresented: $showingAdd) {
            TextField("Keyword", text: $newFilter)
            Button("Add Filter") {
                self.filters.append(newFilter)
                newFilter = ""
                showingAdd = false
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
