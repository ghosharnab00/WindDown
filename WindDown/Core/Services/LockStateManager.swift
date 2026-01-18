import Foundation
import Combine

final class LockStateManager: ObservableObject {
    static let shared = LockStateManager()

    private let appBlockingService = AppBlockingService.shared
    private let hostsBlockingService = HostsBlockingService.shared
    private let notificationService = NotificationService.shared
    private let settings = SettingsStore.shared
    private let appState = AppState.shared

    private var scheduleCheckTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var isLocked: Bool = false

    // Manual override - when true, schedule timer won't auto-unlock
    private var isManuallyLocked: Bool = false

    private init() {
        setupBindings()
    }

    // MARK: - Lifecycle
    func start() {
        print("[LockStateManager] Starting...")
        cleanupStaleBlocking()
        checkScheduleAndUpdateState()
        startScheduleTimer()
        notificationService.requestAuthorization()
    }

    private func cleanupStaleBlocking() {
        if hostsBlockingService.checkHostsFileStatus() {
            let shouldBeLocked = settings.schedule.isEnabled && settings.schedule.isActiveNow()
            if !shouldBeLocked {
                print("[LockStateManager] Cleaning up stale blocking...")
                hostsBlockingService.deactivate { _ in }
            }
        }
    }

    func cleanup() {
        print("[LockStateManager] Cleaning up...")
        scheduleCheckTimer?.invalidate()
        appBlockingService.deactivate()
        hostsBlockingService.deactivate { _ in }
    }

    // MARK: - Setup
    private func setupBindings() {
        settings.$schedule
            .dropFirst()
            .sink { [weak self] _ in
                self?.checkScheduleAndUpdateState()
            }
            .store(in: &cancellables)

        settings.$blockList
            .dropFirst()
            .sink { [weak self] blockList in
                self?.updateBlockedContent(blockList)
            }
            .store(in: &cancellables)
    }

    private func startScheduleTimer() {
        scheduleCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkScheduleAndUpdateState()
        }
    }

    // MARK: - State Management
    private func checkScheduleAndUpdateState() {
        let schedule = settings.schedule

        guard schedule.isEnabled else {
            if isLocked && !isManuallyLocked {
                unlock()
            }
            if !isLocked {
                appState.lockStatus = .unlocked
            }
            return
        }

        // Don't override manual lock
        if isManuallyLocked {
            return
        }

        let shouldBeLocked = schedule.isActiveNow()

        if shouldBeLocked && !isLocked {
            lock()
        } else if !shouldBeLocked && isLocked {
            unlock()
        } else if !shouldBeLocked {
            checkForWarning()
        }
    }

    private func checkForWarning() {
        guard let nextLock = settings.schedule.nextTransitionDate() else {
            appState.lockStatus = .unlocked
            return
        }

        let minutesUntilLock = Int(nextLock.timeIntervalSinceNow / 60)
        let warningThreshold = settings.showWarningMinutes

        if minutesUntilLock > 0 && minutesUntilLock <= warningThreshold {
            appState.lockStatus = .warning(minutesUntilLock: minutesUntilLock)

            if minutesUntilLock == warningThreshold {
                notificationService.sendWarningNotification(minutesRemaining: minutesUntilLock)
            }
        } else {
            appState.lockStatus = .unlocked
        }
    }

    // MARK: - Lock/Unlock
    func lock() {
        guard !isLocked else { return }

        print("[LockStateManager] Locking...")

        let blockList = settings.blockList
        appBlockingService.activate(blocking: blockList.enabledAppBundleIDs)

        hostsBlockingService.activate(blocking: blockList.enabledWebsiteDomains) { result in
            if case .failure(let error) = result {
                print("[LockStateManager] Hosts blocking failed: \(error)")
            }
        }

        isLocked = true
        appState.lockStatus = .locked
        notificationService.sendLockActivatedNotification()
    }

    func unlock() {
        guard isLocked else { return }

        print("[LockStateManager] Unlocking...")

        appBlockingService.deactivate()
        hostsBlockingService.deactivate { _ in }

        isLocked = false
        isManuallyLocked = false
        appState.lockStatus = .unlocked
        notificationService.sendUnlockedNotification()
    }

    // MARK: - Manual Lock/Unlock
    func manualLock() {
        print("[LockStateManager] Manual lock")
        isManuallyLocked = true
        lock()
    }

    func manualUnlock() {
        print("[LockStateManager] Manual unlock")
        isManuallyLocked = false

        appBlockingService.deactivate()
        hostsBlockingService.deactivate { [weak self] _ in
            DispatchQueue.main.async {
                self?.isLocked = false
                self?.appState.lockStatus = .unlocked
            }
        }
    }

    // MARK: - Content Updates
    private func updateBlockedContent(_ blockList: BlockList) {
        guard isLocked else { return }

        appBlockingService.updateBlockedApps(blockList.enabledAppBundleIDs)
        hostsBlockingService.updateBlockedDomains(blockList.enabledWebsiteDomains) { _ in }
    }
}
