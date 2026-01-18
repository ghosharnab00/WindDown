import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupBindings()

        // Request notification permission
        NotificationService.shared.requestAuthorization()

        // Only start services if onboarding is already complete
        if SettingsStore.shared.hasCompletedOnboarding {
            LockStateManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        LockStateManager.shared.cleanup()
    }

    // MARK: - Menu Bar Setup
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "moon", accessibilityDescription: "WindDown")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        self.popover = popover

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    private func setupBindings() {
        // Update menu bar icon based on lock status
        AppState.shared.$lockStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateMenuBarIcon(for: status)
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarIcon(for status: LockStatus) {
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: "WindDown")
    }

    // MARK: - Popover
    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
