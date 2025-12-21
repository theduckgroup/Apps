import Foundation
public import SwiftUI

public struct RootView: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Text("Blahhhh")
                .navigationTitle("Weekly Spending")
        }
    }
}
