import Foundation
import Combine

final class RitualStore: ObservableObject {
    static let shared = RitualStore()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var rituals: [ShutdownRitual] = []
    @Published var currentRitual: ShutdownRitual?

    private var ritualsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let winddownDir = appSupport.appendingPathComponent("WindDown", isDirectory: true)
        let ritualsDir = winddownDir.appendingPathComponent("Rituals", isDirectory: true)

        if !fileManager.fileExists(atPath: ritualsDir.path) {
            try? fileManager.createDirectory(at: ritualsDir, withIntermediateDirectories: true)
        }

        return ritualsDir
    }

    private init() {
        loadRituals()
    }

    // MARK: - Loading
    private func loadRituals() {
        do {
            let files = try fileManager.contentsOfDirectory(at: ritualsDirectory, includingPropertiesForKeys: [.creationDateKey])
            var loadedRituals: [ShutdownRitual] = []

            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let ritual = try? decoder.decode(ShutdownRitual.self, from: data) {
                    loadedRituals.append(ritual)
                }
            }

            rituals = loadedRituals.sorted { $0.date > $1.date }
        } catch {
            print("Failed to load rituals: \(error)")
            rituals = []
        }
    }

    // MARK: - Current Ritual
    func startNewRitual() -> ShutdownRitual {
        var ritual = ShutdownRitual()

        // Carry over incomplete items from previous rituals
        let incompleteItems = getIncompleteItemsFromPreviousRituals()
        if !incompleteItems.isEmpty {
            ritual.brainDump = BrainDump(items: incompleteItems)
        }

        currentRitual = ritual
        return ritual
    }

    func updateCurrentRitual(_ ritual: ShutdownRitual) {
        currentRitual = ritual
        // Auto-save when updating to persist brain dump items
        saveRitual(ritual)
    }

    func completeCurrentRitual() {
        guard var ritual = currentRitual else { return }
        ritual.complete()
        saveRitual(ritual)
        currentRitual = nil
    }

    func cancelCurrentRitual() {
        // Save the current state even if cancelled so brain dump items persist
        if let ritual = currentRitual {
            saveRitual(ritual)
        }
        currentRitual = nil
    }

    // MARK: - Incomplete Items
    private func getIncompleteItemsFromPreviousRituals() -> [BrainDumpItem] {
        // Get items from rituals in the last 7 days that aren't completed
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -7, to: Date()) else { return [] }

        var incompleteItems: [BrainDumpItem] = []
        let recentRituals = rituals.filter { $0.date >= cutoffDate }

        for ritual in recentRituals {
            let incomplete = ritual.brainDump.items.filter { !$0.isCompleted }
            incompleteItems.append(contentsOf: incomplete)
        }

        // Remove duplicates by ID
        var seen = Set<UUID>()
        return incompleteItems.filter { item in
            if seen.contains(item.id) {
                return false
            }
            seen.insert(item.id)
            return true
        }
    }

    func getActiveItems() -> [BrainDumpItem] {
        // Get all incomplete items from recent rituals plus current ritual
        var items = getIncompleteItemsFromPreviousRituals()

        if let current = currentRitual {
            for item in current.brainDump.items {
                if !items.contains(where: { $0.id == item.id }) {
                    items.append(item)
                }
            }
        }

        return items.filter { !$0.isCompleted }
    }

    // MARK: - Saving
    func saveRitual(_ ritual: ShutdownRitual) {
        do {
            let data = try encoder.encode(ritual)
            let filename = ritualFilename(for: ritual)
            let fileURL = ritualsDirectory.appendingPathComponent(filename)
            try data.write(to: fileURL)

            if let index = rituals.firstIndex(where: { $0.id == ritual.id }) {
                rituals[index] = ritual
            } else {
                rituals.insert(ritual, at: 0)
            }
        } catch {
            print("Failed to save ritual: \(error)")
        }
    }

    private func ritualFilename(for ritual: ShutdownRitual) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "ritual_\(formatter.string(from: ritual.date))_\(ritual.id.uuidString.prefix(8)).json"
    }

    // MARK: - Querying
    func ritualsForToday() -> [ShutdownRitual] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return rituals.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }

    func hasCompletedRitualToday() -> Bool {
        ritualsForToday().contains { $0.isCompleted }
    }

    func recentRituals(limit: Int = 7) -> [ShutdownRitual] {
        Array(rituals.prefix(limit))
    }

    // MARK: - Simple Brain Dump
    func saveBrainDump(_ text: String) {
        var ritual = currentRitual ?? ShutdownRitual()
        let item = BrainDumpItem(text: text)
        ritual.brainDump.items.append(item)
        ritual.complete()
        saveRitual(ritual)
        currentRitual = nil
    }

    // MARK: - Cleanup
    func deleteOldRituals(olderThan days: Int = 30) {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return }

        let oldRituals = rituals.filter { $0.date < cutoffDate }

        for ritual in oldRituals {
            let filename = ritualFilename(for: ritual)
            let fileURL = ritualsDirectory.appendingPathComponent(filename)
            try? fileManager.removeItem(at: fileURL)
        }

        rituals.removeAll { $0.date < cutoffDate }
    }
}
