import Foundation

public enum TabViewItem: String, Codable, Hashable, CaseIterable {
    case quiz
    case weeklySpending
    case inventory
    case nakedBlendCalc
    case settings
    
    public var name: String {
        switch self {
        case .quiz: "FOH Test"
        case .weeklySpending: "Weekly Spending"
        case .inventory: "Inventory"
        case .nakedBlendCalc: "Naked Blend"
        case .settings: "Setting"
        }
    }
}
