import Foundation
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Keys
    private enum Keys {
        static let schedule = "winddown.schedule"
        static let blockList = "winddown.blockList"
        static let hasCompletedOnboarding = "winddown.hasCompletedOnboarding"
        static let launchAtLogin = "winddown.launchAtLogin"
        static let showWarningMinutes = "winddown.showWarningMinutes"
        static let emergencyUnlockPhrase = "winddown.emergencyUnlockPhrase"
        static let requireRitualBeforeLock = "winddown.requireRitualBeforeLock"
    }

    // MARK: - Published Properties
    @Published var schedule: Schedule {
        didSet { saveSchedule() }
    }

    @Published var blockList: BlockList {
        didSet { saveBlockList() }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showWarningMinutes: Int {
        didSet { defaults.set(showWarningMinutes, forKey: Keys.showWarningMinutes) }
    }

    @Published var emergencyUnlockPhrase: String {
        didSet { defaults.set(emergencyUnlockPhrase, forKey: Keys.emergencyUnlockPhrase) }
    }

    @Published var requireRitualBeforeLock: Bool {
        didSet { defaults.set(requireRitualBeforeLock, forKey: Keys.requireRitualBeforeLock) }
    }

    // MARK: - Initialization
    private init() {
        self.schedule = Self.loadSchedule(from: defaults, decoder: decoder)
        self.blockList = Self.loadBlockList(from: defaults, decoder: decoder)
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showWarningMinutes = defaults.object(forKey: Keys.showWarningMinutes) as? Int ?? 15
        self.emergencyUnlockPhrase = defaults.string(forKey: Keys.emergencyUnlockPhrase) ?? "I acknowledge that I am choosing to work outside my designated hours."
        self.requireRitualBeforeLock = defaults.object(forKey: Keys.requireRitualBeforeLock) as? Bool ?? true
    }

    // MARK: - Schedule
    private static func loadSchedule(from defaults: UserDefaults, decoder: JSONDecoder) -> Schedule {
        guard let data = defaults.data(forKey: Keys.schedule),
              let schedule = try? decoder.decode(Schedule.self, from: data) else {
            return Schedule.default
        }
        return schedule
    }

    private func saveSchedule() {
        guard let data = try? encoder.encode(schedule) else { return }
        defaults.set(data, forKey: Keys.schedule)
    }

    // MARK: - Block List
    private static func loadBlockList(from defaults: UserDefaults, decoder: JSONDecoder) -> BlockList {
        guard let data = defaults.data(forKey: Keys.blockList),
              let blockList = try? decoder.decode(BlockList.self, from: data) else {
            return BlockList.default
        }
        return blockList
    }

    private func saveBlockList() {
        guard let data = try? encoder.encode(blockList) else { return }
        defaults.set(data, forKey: Keys.blockList)
    }

    // MARK: - Block List Helpers
    func addBlockedApp(_ app: BlockedApp) {
        var list = blockList
        if !list.blockedApps.contains(where: { $0.bundleID == app.bundleID }) {
            list.blockedApps.append(app)
            blockList = list
        }
    }

    func removeBlockedApp(bundleID: String) {
        var list = blockList
        list.blockedApps.removeAll { $0.bundleID == bundleID }
        blockList = list
    }

    func toggleApp(bundleID: String, enabled: Bool) {
        var list = blockList
        if let index = list.blockedApps.firstIndex(where: { $0.bundleID == bundleID }) {
            list.blockedApps[index].isEnabled = enabled
            blockList = list
        }
    }

    func addBlockedWebsite(_ website: BlockedWebsite) {
        var list = blockList
        if !list.blockedWebsites.contains(where: { $0.domain == website.domain }) {
            list.blockedWebsites.append(website)
            blockList = list
        }
    }

    func removeBlockedWebsite(domain: String) {
        var list = blockList
        list.blockedWebsites.removeAll { $0.domain == domain }
        blockList = list
    }

    func toggleWebsite(domain: String, enabled: Bool) {
        var list = blockList
        if let index = list.blockedWebsites.firstIndex(where: { $0.domain == domain }) {
            list.blockedWebsites[index].isEnabled = enabled
            blockList = list
        }
    }

    // MARK: - Reset
    func resetToDefaults() {
        schedule = Schedule.default
        blockList = BlockList.default
        showWarningMinutes = 15
        emergencyUnlockPhrase = "I acknowledge that I am choosing to work outside my designated hours."
        requireRitualBeforeLock = true
    }
}
