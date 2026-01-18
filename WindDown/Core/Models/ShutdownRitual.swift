import Foundation

struct ShutdownRitual: Codable, Identifiable {
    var id: UUID
    var date: Date
    var brainDump: BrainDump
    var triagedItems: [TriagedItem]
    var tomorrowActions: [TomorrowAction]
    var isCompleted: Bool

    init(id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.date = date
        self.brainDump = BrainDump()
        self.triagedItems = []
        self.tomorrowActions = []
        self.isCompleted = false
    }

    mutating func complete() {
        isCompleted = true
    }
}

struct BrainDump: Codable {
    var items: [BrainDumpItem]

    init(items: [BrainDumpItem] = []) {
        self.items = items
    }

    mutating func addItem(_ text: String) {
        let item = BrainDumpItem(text: text)
        items.append(item)
    }

    mutating func removeItem(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
    }
}

struct BrainDumpItem: Codable, Identifiable, Equatable {
    var id: UUID
    var text: String
    var createdAt: Date
    var isCompleted: Bool

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }

    // Custom decoder for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, createdAt, isCompleted
    }
}

struct TriagedItem: Codable, Identifiable {
    var id: UUID
    var originalItem: BrainDumpItem
    var priority: TriagePriority
    var notes: String

    init(id: UUID = UUID(), originalItem: BrainDumpItem, priority: TriagePriority, notes: String = "") {
        self.id = id
        self.originalItem = originalItem
        self.priority = priority
        self.notes = notes
    }
}

enum TriagePriority: String, Codable, CaseIterable {
    case mustDo = "must_do"
    case shouldDo = "should_do"
    case couldDo = "could_do"
    case delegate = "delegate"
    case delete = "delete"

    var displayName: String {
        switch self {
        case .mustDo: return "Must Do"
        case .shouldDo: return "Should Do"
        case .couldDo: return "Could Do"
        case .delegate: return "Delegate"
        case .delete: return "Delete"
        }
    }

    var emoji: String {
        switch self {
        case .mustDo: return "🔴"
        case .shouldDo: return "🟡"
        case .couldDo: return "🟢"
        case .delegate: return "👥"
        case .delete: return "🗑️"
        }
    }

    var description: String {
        switch self {
        case .mustDo: return "Critical - do first thing tomorrow"
        case .shouldDo: return "Important - schedule time for this"
        case .couldDo: return "Nice to have - if time permits"
        case .delegate: return "Someone else can handle this"
        case .delete: return "Not actually needed"
        }
    }
}

struct TomorrowAction: Codable, Identifiable {
    var id: UUID
    var text: String
    var timeBlock: TimeBlock?
    var linkedTriagedItem: UUID?

    init(id: UUID = UUID(), text: String, timeBlock: TimeBlock? = nil, linkedTriagedItem: UUID? = nil) {
        self.id = id
        self.text = text
        self.timeBlock = timeBlock
        self.linkedTriagedItem = linkedTriagedItem
    }
}

enum TimeBlock: String, Codable, CaseIterable {
    case morning = "morning"
    case midday = "midday"
    case afternoon = "afternoon"

    var displayName: String {
        switch self {
        case .morning: return "Morning (9-12)"
        case .midday: return "Midday (12-2)"
        case .afternoon: return "Afternoon (2-5)"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .midday: return "sun.max"
        case .afternoon: return "sunset"
        }
    }
}
