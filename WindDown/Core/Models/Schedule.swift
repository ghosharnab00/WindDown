import Foundation

struct Schedule: Codable, Equatable {
    var isEnabled: Bool
    var startTime: TimeComponents
    var endTime: TimeComponents
    var activeDays: Set<Weekday>

    static let `default` = Schedule(
        isEnabled: true,
        startTime: TimeComponents(hour: 18, minute: 0),
        endTime: TimeComponents(hour: 9, minute: 0),
        activeDays: Set(Weekday.weekdays)
    )

    func isActiveNow() -> Bool {
        guard isEnabled else { return false }
        guard !activeDays.isEmpty else { return false }

        let now = Date()
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: now)

        guard let weekday = Weekday(calendarWeekday: weekdayNumber),
              activeDays.contains(weekday) else {
            return false
        }

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute

        let startMinutes = startTime.hour * 60 + startTime.minute
        let endMinutes = endTime.hour * 60 + endTime.minute

        // Handle case where start equals end (no blocking period)
        if startMinutes == endMinutes {
            return false
        }

        if startMinutes < endMinutes {
            // Same day blocking (e.g., 9am to 5pm)
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Overnight blocking (e.g., 6pm to 9am)
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }

    func nextTransitionDate() -> Date? {
        guard isEnabled else { return nil }
        guard !activeDays.isEmpty else { return nil }

        let startMinutes = startTime.hour * 60 + startTime.minute
        let endMinutes = endTime.hour * 60 + endTime.minute
        guard startMinutes != endMinutes else { return nil }

        let now = Date()
        let calendar = Calendar.current

        if isActiveNow() {
            return nextOccurrence(of: endTime, after: now, calendar: calendar)
        } else {
            return nextOccurrence(of: startTime, after: now, calendar: calendar)
        }
    }

    private func nextOccurrence(of time: TimeComponents, after date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0

        guard var candidate = calendar.date(from: components) else { return nil }

        if candidate <= date {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        for _ in 0..<7 {
            let weekdayNumber = calendar.component(.weekday, from: candidate)
            if let weekday = Weekday(calendarWeekday: weekdayNumber),
               activeDays.contains(weekday) {
                return candidate
            }
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        return nil
    }
}

struct TimeComponents: Codable, Equatable {
    var hour: Int
    var minute: Int

    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }
}

enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    init?(calendarWeekday: Int) {
        self.init(rawValue: calendarWeekday)
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    static let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekend: [Weekday] = [.saturday, .sunday]
}
