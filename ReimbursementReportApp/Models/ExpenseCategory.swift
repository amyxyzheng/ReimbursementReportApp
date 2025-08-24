import Foundation

enum ExpenseCategory: String, CaseIterable {
    case meal = "meal"
    case equipment = "equipment"
    
    var displayName: String {
        switch self {
        case .meal:
            return "Meal"
        case .equipment:
            return "Equipment"
        }
    }
    
    var icon: String {
        switch self {
        case .meal:
            return "🍽️"
        case .equipment:
            return "🛠️"
        }
    }
}
