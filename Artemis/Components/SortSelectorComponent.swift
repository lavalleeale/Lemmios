import SwiftUI

struct SortSelectorComponent: View {
    var function: (_: LemmyHttp.Sort, _: LemmyHttp.TopTime) -> Void
    @Binding var currentSort: LemmyHttp.Sort
    @Binding var currentTime: LemmyHttp.TopTime
    let comment: Bool
    
    init(function: @escaping (_: LemmyHttp.Sort, _: LemmyHttp.TopTime) -> Void, currentSort: Binding<LemmyHttp.Sort>, currentTime: Binding<LemmyHttp.TopTime>) {
        self.function = function
        self._currentSort = currentSort
        self._currentTime = currentTime
        self.comment = false
    }
    
    init(function: @escaping (_: LemmyHttp.Sort) -> Void, currentSort: Binding<LemmyHttp.Sort>) {
        self.function = { sort, time in
            function(sort)
        }
        self._currentSort = currentSort
        self._currentTime = .constant(.All)
        self.comment = true
    }
    
    var body: some View {
        Menu {
            ForEach(LemmyHttp.Sort.allCases.filter({sortType in !comment || sortType.comments}), id: \.rawValue) {sort in
                Button {
                    function(sort, currentTime)
                } label: {
                    if (sort.hasTime && !comment) {
                        Menu {
                            ForEach(LemmyHttp.TopTime.allCases, id: \.rawValue) {time in
                                Button {
                                    function(sort, time)
                                } label: {
                                    Text(time.rawValue.capitalized)
                                }
                            }
                        } label: {
                            Image(systemName: sort.image)
                            Text(sort.rawValue.capitalized)
                        }
                    } else {
                        Image(systemName: sort.image)
                        Text(sort.rawValue.capitalized)
                    }
                }
            }
        } label: {
            Image(systemName: currentSort.image)
        }
    }
}

enum ThingType: String {
    case comments, posts, user
}
