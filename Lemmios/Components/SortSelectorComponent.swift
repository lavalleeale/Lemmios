import SwiftUI

struct SortSelectorComponent: View {
    var function: (LemmyHttp.Sort, LemmyHttp.TopTime) -> Void
    @Binding var currentSort: LemmyHttp.Sort
    @Binding var currentTime: LemmyHttp.TopTime
    
    let sortType: SortType

    init(sortType: SortType, currentSort: Binding<LemmyHttp.Sort>, currentTime: Binding<LemmyHttp.TopTime>, function: @escaping (LemmyHttp.Sort, LemmyHttp.TopTime) -> Void) {
        self.function =
            { sort, time in
                function(sort, time)
            }
        self._currentSort = currentSort
        self._currentTime = currentTime
        self.sortType = sortType
    }

    init(currentSort: Binding<LemmyHttp.Sort>, function: @escaping (LemmyHttp.Sort) -> Void) {
        self.function =
            { sort, _ in
                function(sort)
            }
        self._currentSort = currentSort
        self._currentTime = .constant(.All)
        self.sortType = .Comments
    }

    var body: some View {
        Menu {
            ForEach(LemmyHttp.Sort.allCases.filter { sortOption in
                switch sortType {
                case .Comments:
                    sortOption.comments
                case .Posts:
                    true
                case .Search:
                    sortOption.search
                }
            }, id: \.rawValue) { sort in
                Button {
                    function(sort, currentTime)
                } label: {
                    if sort.hasTime && sortType != .Comments {
                        Menu {
                            ForEach(LemmyHttp.TopTime.allCases, id: \.rawValue) { time in
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

enum SortType {
    case Comments, Posts, Search
}
