import Foundation


//
//ScrollViewReader { scrollView in
//    ScrollView(.horizontal, showsIndicators: false) {
//        HStack(spacing: 0) {
//            ForEach(Array(viewModel.pages.indices), id: \.self) { index in
//                let page = viewModel.pages[index]
//                viewForPage(page)
//                    .frame(width: geometry.size.width)
//                    .id(index)
//            }
//        }
//    }
//    .scrollTargetBehavior(.paging)
//    .onChange(of: pageIndex) {
//        withAnimation {
//            scrollView.scrollTo(pageIndex)
//        }
//    }
//}
