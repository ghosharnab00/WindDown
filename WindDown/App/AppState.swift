import Foundation
import Combine

enum LockStatus: Equatable {
    case unlocked
    case locked
    case warning(minutesUntilLock: Int)

    var isBlocking: Bool {
        if case .locked = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .unlocked:
            return "Not blocking"
        case .locked:
            return "Blocking"
        case .warning(let minutes):
            return "Blocking in \(minutes)m"
        }
    }

    var iconName: String {
        switch self {
        case .unlocked:
            return "moon"
        case .locked:
            return "moon.fill"
        case .warning:
            return "moon.haze"
        }
    }
}

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var lockStatus: LockStatus = .unlocked

    private init() {}
}
