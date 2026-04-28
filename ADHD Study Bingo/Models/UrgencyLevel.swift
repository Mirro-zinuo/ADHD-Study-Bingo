import SwiftUI

enum UrgencyLevel {
    case green
    case orange
    case red

    var color: Color {
        switch self {
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        }
    }
}
