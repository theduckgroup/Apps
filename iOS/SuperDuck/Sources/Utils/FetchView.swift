import Foundation
import Common
import CommonUI
import SwiftUI

struct FetchView: View {
    var isFetching: Bool
    var fetchError: Error?
    var retry: () -> Void
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    init(isFetching: Bool, fetchError: Error? = nil, retry: @escaping () -> Void) {
        self.isFetching = isFetching
        self.fetchError = fetchError
        self.retry = retry
    }
    
    var body: some View {
        if isFetching {
            HStack {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
                
                Text("Loading...")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 21)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(.regularMaterial)
            }
            .padding()
            
        } else if let fetchError {
            VStack(alignment: .leading) {
                Text(formatError(fetchError))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                
                Button("Retry") {
                    retry()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .fixedSize(horizontal: false, vertical: false)
            .padding()
            .frame(width: horizontalSizeClass == .regular ? 570 : nil)
            .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : nil)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.regularMaterial)
                    .modified {
                        if colorScheme == .light {
                            $0.shadow(color: .black.opacity(0.05), radius: 12)
                        } else {
                            $0
                        }
                    }
            }
            .padding()
            .padding(.horizontal, 12) // Avoid coinciding edges with list views and so on
        }
    }
}

extension View {
    @ViewBuilder
    func fetchOverlay(isFetching: Bool, fetchError: Error?, retry: @escaping () -> Void) -> some View {
        safeAreaInset(edge: .bottom) {
            // Note: adding `padding()` here causes extra space to scroll view, even if FetchView is empty
            FetchView(isFetching: isFetching, fetchError: fetchError, retry: retry)
        }
    }
}
