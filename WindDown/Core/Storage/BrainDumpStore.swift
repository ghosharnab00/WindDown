import Foundation
import Combine

struct BrainDumpEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var text: String
}

final class BrainDumpStore: ObservableObject {
    static let shared = BrainDumpStore()

    @Published private(set) var entries: [BrainDumpEntry] = []

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let winddownDir = appSupport.appendingPathComponent("WindDown", isDirectory: true)

        if !FileManager.default.fileExists(atPath: winddownDir.path) {
            try? FileManager.default.createDirectory(at: winddownDir, withIntermediateDirectories: true)
        }

        fileURL = winddownDir.appendingPathComponent("brain_dumps.json")
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([BrainDumpEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded.sorted { $0.date > $1.date }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL)
    }

    func addEntry(_ text: String) {
        let entry = BrainDumpEntry(date: Date(), text: text)
        entries.insert(entry, at: 0)
        save()
    }

    func deleteEntry(_ entry: BrainDumpEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func entriesGroupedByDate() -> [(String, [BrainDumpEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: entries) { entry in
            formatter.string(from: entry.date)
        }

        return grouped.sorted { first, second in
            guard let d1 = first.value.first?.date, let d2 = second.value.first?.date else { return false }
            return d1 > d2
        }
    }
}
