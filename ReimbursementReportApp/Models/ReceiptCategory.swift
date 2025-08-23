import Foundation

enum ReceiptCategory: String, CaseIterable, Identifiable {
    case transport, hotel, upgrade, localTravel, other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .transport:
            return "Major Transport"
        case .hotel:
            return "Hotel"
        case .upgrade:
            return "Flight Upgrade"
        case .localTravel:
            return "Local Transit"
        case .other:
            return "Other"
        }
    }
} 