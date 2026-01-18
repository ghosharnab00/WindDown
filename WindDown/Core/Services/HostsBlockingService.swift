import Foundation
import AppKit

final class HostsBlockingService: ObservableObject {
    static let shared = HostsBlockingService()

    @Published private(set) var isActive: Bool = false
    @Published private(set) var blockedDomains: [String] = []

    private let hostsPath = "/etc/hosts"
    private let blockStartMarker = "# >>> WindDown Blocked Domains >>>"
    private let blockEndMarker = "# <<< WindDown Blocked Domains <<<"

    private init() {}

    // MARK: - Activation
    func activate(blocking domains: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isActive else {
            completion(.success(()))
            return
        }
        blockedDomains = domains
        // Check if already blocked
        do {
            let currentContents = try String(contentsOfFile: hostsPath, encoding: .utf8)
            let blockEntries = generateBlockEntries(for: domains)
            if currentContents.contains(blockEntries) {
                print("[HostsBlockingService] Block already present, skipping write.")
                isActive = true
                completion(.success(()))
                return
            }
        } catch { /* ignore and proceed */ }
        addBlockedDomains(domains) { [weak self] result in
            switch result {
            case .success:
                self?.isActive = true
                self?.flushDNSCache()
                print("[HostsBlockingService] Activated with \(domains.count) domains.")
                completion(.success(()))
            case .failure(let error):
                print("[HostsBlockingService] Activation failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    func deactivate(completion: @escaping (Result<Void, Error>) -> Void) {
        print("[HostsBlockingService] Starting deactivation.")
        // Always try to remove blocked domains, even if we think we're not active
        // This handles cases where the app crashed or was force-quit while blocking
        removeBlockedDomains { [weak self] result in
            switch result {
            case .success:
                self?.isActive = false
                self?.blockedDomains = []
                self?.flushDNSCache()
                print("[HostsBlockingService] Deactivated")
                completion(.success(()))
            case .failure(let error):
                print("[HostsBlockingService] Deactivation failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    func updateBlockedDomains(_ domains: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard isActive else {
            blockedDomains = domains
            completion(.success(()))
            return
        }
        // Check if block is already accurate
        do {
            let currentContents = try String(contentsOfFile: hostsPath, encoding: .utf8)
            let blockEntries = generateBlockEntries(for: domains)
            if currentContents.contains(blockEntries) {
                print("[HostsBlockingService] Update: Block already present, skipping write.")
                blockedDomains = domains
                completion(.success(()))
                return
            }
        } catch { /* ignore and proceed */ }
        removeBlockedDomains { [weak self] result in
            switch result {
            case .success:
                self?.addBlockedDomains(domains) { addResult in
                    switch addResult {
                    case .success:
                        self?.blockedDomains = domains
                        self?.flushDNSCache()
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Hosts File Manipulation
    private func addBlockedDomains(_ domains: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        let blockEntries = generateBlockEntries(for: domains)

        do {
            var currentContents = try String(contentsOfFile: hostsPath, encoding: .utf8)

            if currentContents.contains(blockStartMarker) {
                currentContents = removeExistingBlock(from: currentContents)
            }

            let newContents = currentContents.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" + blockEntries

            writeToHostsFile(newContents, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    private func removeBlockedDomains(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let currentContents = try String(contentsOfFile: hostsPath, encoding: .utf8)
            let newContents = removeExistingBlock(from: currentContents)

            writeToHostsFile(newContents, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    private func generateBlockEntries(for domains: [String]) -> String {
        var domainSet = Set(domains)
        // Always add www. variant if not already present
        for domain in domains {
            if !domain.hasPrefix("www.") {
                domainSet.insert("www." + domain)
            }
        }
        var lines = [blockStartMarker]
        for domain in domainSet.sorted() {
            lines.append("0.0.0.0 \(domain)")
            lines.append("127.0.0.1 \(domain)")
            lines.append("::0 \(domain)")
        }
        lines.append(blockEndMarker)
        return lines.joined(separator: "\n")
    }

    private func removeExistingBlock(from contents: String) -> String {
        guard let startRange = contents.range(of: blockStartMarker),
              let endRange = contents.range(of: blockEndMarker),
              startRange.lowerBound <= endRange.upperBound else {
            return contents
        }

        // The range to remove is from start of marker to *end* of blockEndMarker (inclusive)
        let removeEnd = endRange.upperBound
        let rangeToRemove = startRange.lowerBound..<removeEnd
        var newContents = contents
        newContents.removeSubrange(rangeToRemove)

        return newContents.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Privileged Write
    private func writeToHostsFile(_ contents: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("hosts_temp_\(UUID().uuidString)")

        do {
            try contents.write(to: tempFile, atomically: true, encoding: .utf8)
        } catch {
            completion(.failure(error))
            return
        }

        // Use osascript via Process - this handles the admin dialog better
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "do shell script \"cp '\(tempFile.path)' '\(self.hostsPath)'\" with administrator privileges"

            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]

            let pipe = Pipe()
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                try? FileManager.default.removeItem(at: tempFile)

                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        completion(.success(()))
                    } else {
                        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        completion(.failure(HostsBlockingError.privilegedWriteFailed(errorMessage)))
                    }
                }
            } catch {
                try? FileManager.default.removeItem(at: tempFile)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - DNS Cache
    private func flushDNSCache() {
        // Run on background thread to prevent UI freeze
        DispatchQueue.global(qos: .userInitiated).async {
            // Flush DNS cache without admin privileges
            // dscacheutil doesn't need admin, killall mDNSResponder does but we skip it
            // to avoid extra password prompts - the hosts change will take effect anyway
            let process = Process()
            process.launchPath = "/usr/bin/dscacheutil"
            process.arguments = ["-flushcache"]

            do {
                try process.run()
                process.waitUntilExit()
                print("[HostsBlockingService] DNS cache flushed (dscacheutil)")
            } catch {
                print("[HostsBlockingService] DNS flush error: \(error)")
            }

            // Send notification to apps about network change
            DispatchQueue.main.async {
                DistributedNotificationCenter.default().postNotificationName(
                    NSNotification.Name("com.apple.system.config.network_change"),
                    object: nil,
                    userInfo: nil,
                    deliverImmediately: true
                )
            }
        }
    }

    // MARK: - Querying
    func isDomainBlocked(_ domain: String) -> Bool {
        isActive && blockedDomains.contains(where: { $0 == domain || $0 == "www.\(domain)" })
    }

    func checkHostsFileStatus() -> Bool {
        do {
            let contents = try String(contentsOfFile: hostsPath, encoding: .utf8)
            return contents.contains(blockStartMarker)
        } catch {
            return false
        }
    }

    /// Verify hosts file was modified and print current blocked entries for debugging
    func verifyAndLogBlockedDomains() {
        do {
            let contents = try String(contentsOfFile: hostsPath, encoding: .utf8)
            if contents.contains(blockStartMarker) {
                // Extract and log the blocked domains
                if let startRange = contents.range(of: blockStartMarker),
                   let endRange = contents.range(of: blockEndMarker),
                   startRange.upperBound <= endRange.lowerBound {
                    let blockSection = String(contents[startRange.upperBound..<endRange.lowerBound])
                    let lines = blockSection.components(separatedBy: .newlines)
                        .filter { !$0.isEmpty }
                    print("[HostsBlockingService] Currently blocking \(lines.count) domain entries:")
                    for line in lines.prefix(10) {
                        print("  \(line)")
                    }
                    if lines.count > 10 {
                        print("  ... and \(lines.count - 10) more")
                    }
                } else {
                    print("[HostsBlockingService] WARNING: No WindDown block section found in hosts file or invalid block range!")
                }
            } else {
                print("[HostsBlockingService] WARNING: No WindDown block section found in hosts file!")
            }
        } catch {
            print("[HostsBlockingService] Failed to read hosts file: \(error)")
        }
    }
}

enum HostsBlockingError: LocalizedError {
    case privilegedWriteFailed(String)
    case scriptCreationFailed

    var errorDescription: String? {
        switch self {
        case .privilegedWriteFailed(let message):
            return "Failed to modify hosts file: \(message)"
        case .scriptCreationFailed:
            return "Failed to create AppleScript for privileged write"
        }
    }
}
