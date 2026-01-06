import Foundation
import SwiftUI
import Common
import CommonUI
import Backend
import Auth

struct RecentStockAdjustmentListView: View {
    var adjustments: [StockAdjustmentMeta]?
    var since: Date?
    var onView: (StockAdjustmentMeta) -> Void
    @Environment(API.self) var api
    @Environment(Auth.self) var auth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent")
                .font(.system(size: 27, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let adjustments {
                if adjustments.count > 0 {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(adjustments) { adjustment in
                            Row(adjustment: adjustment, isFirst: adjustment.id == adjustments.first?.id) {
                                onView(adjustment)
                            }
                        }

                        if let since {
                            let components = Calendar.current.dateComponents([.month], from: since, to: Date())
                            Text("Data for the past \(components.month!) months is shown.")
                                .foregroundStyle(.secondary)
                                .padding(.top)
                        }
                    }
                    .padding(.top, 24)

                } else {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .padding(.top, 15)
                }
            }
        }
    }
}

private struct Row: View {
    var adjustment: StockAdjustmentMeta
    var isFirst: Bool
    var onView: () -> Void
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(.secondary)
            
            let formattedDate = adjustment.timestamp.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())
            Text(formattedDate)
            
            Spacer()
            
            Button {
                onView()
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("View")
                    Image(systemName: "chevron.right").imageScale(.small)
                }
                .contentShape(Rectangle())
            }
        }
        .padding(.top, isFirst ? 0 : nil)
        .padding(.bottom)
        .overlay(alignment: .bottom) { Divider() }
        .onTapGesture {
            onView()
        }
    }
}

#Preview {
    @Previewable @State var adjustments: [StockAdjustmentMeta]?
    @Previewable @State var since: Date?

    ScrollView {
        if let adjustments {
            RecentStockAdjustmentListView(
                adjustments: adjustments,
                since: since,
                onView: { _ in }
            )
            .padding()

        } else {
            ProgressView()
                .progressViewStyle(.circular)
        }
    }
    .onAppear {
        Task {
            do {
                let response = try await API.localWithMockAuth.stockAdjustmentsMeta(storeId: Store.defaultStoreID, userId: User.mock.idString)
                adjustments = response.data
                since = response.since

            } catch {
                logger.error("Unable to get mock data: \(error)")
            }
        }
    }
    .previewEnvironment()
}
