import SwiftUI
import LemmyApi

struct SortSelectorComponent: View {
    var function: (LemmyApi.Sort, LemmyApi.TopTime) -> Void
    @Binding var currentSort: LemmyApi.Sort
    @Binding var currentTime: LemmyApi.TopTime
    
    let sortType: SortType

    init(sortType: SortType, currentSort: Binding<LemmyApi.Sort>, currentTime: Binding<LemmyApi.TopTime>, function: @escaping (LemmyApi.Sort, LemmyApi.TopTime) -> Void) {
        self.function =
            { sort, time in
                function(sort, time)
            }
        self._currentSort = currentSort
        self._currentTime = currentTime
        self.sortType = sortType
    }

    init(currentSort: Binding<LemmyApi.Sort>, function: @escaping (LemmyApi.Sort) -> Void) {
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
            ForEach(LemmyApi.Sort.allCases.filter { sortOption in
                switch sortType {
                case .Comments:
                    return sortOption.comments
                case .Posts:
                    return true
                case .Search:
                    return sortOption.search
                }
            }, id: \.rawValue) { sort in
                Button {
                    function(sort, currentTime)
                } label: {
                    if sort.hasTime && sortType != .Comments {
                        Menu {
                            ForEach(LemmyApi.TopTime.allCases, id: \.rawValue) { time in
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
            Label("Sort", systemImage: currentSort.image)
                .labelStyle(.iconOnly)
        }
    }
}

enum SortType {
    case Comments, Posts, Search
}
