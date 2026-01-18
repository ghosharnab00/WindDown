import Foundation
import SwiftUI

enum WorkCategory: String, Codable, CaseIterable {
    case communication
    case documentation
    case code
    case projectManagement

    var displayName: String {
        switch self {
        case .communication: return "Communication"
        case .documentation: return "Documentation"
        case .code: return "Code & Development"
        case .projectManagement: return "Project Management"
        }
    }

    var icon: String {
        switch self {
        case .communication: return "bubble.left.and.bubble.right"
        case .documentation: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .projectManagement: return "list.bullet.rectangle"
        }
    }

    var color: Color {
        switch self {
        case .communication: return .blue
        case .documentation: return .orange
        case .code: return .purple
        case .projectManagement: return .green
        }
    }
}
