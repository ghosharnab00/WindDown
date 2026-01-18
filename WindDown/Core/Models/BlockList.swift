import Foundation

struct BlockList: Codable, Equatable {
    var blockedApps: [BlockedApp]
    var blockedWebsites: [BlockedWebsite]

    static let `default` = BlockList(
        blockedApps: BlockedApp.defaults,
        blockedWebsites: BlockedWebsite.defaults
    )

    var enabledApps: [BlockedApp] {
        blockedApps.filter { $0.isEnabled }
    }

    var enabledWebsites: [BlockedWebsite] {
        blockedWebsites.filter { $0.isEnabled }
    }

    var enabledAppBundleIDs: Set<String> {
        Set(enabledApps.map { $0.bundleID })
    }

    var enabledWebsiteDomains: [String] {
        enabledWebsites.flatMap { $0.allDomains }
    }
}

struct BlockedApp: Codable, Equatable, Identifiable {
    var id: String { bundleID }
    let bundleID: String
    let name: String
    let category: WorkCategory
    var isEnabled: Bool

    static let defaults: [BlockedApp] = [
        BlockedApp(bundleID: "com.tinyspeck.slackmacgap", name: "Slack", category: .communication, isEnabled: true),
        BlockedApp(bundleID: "com.microsoft.teams", name: "Microsoft Teams", category: .communication, isEnabled: true),
        BlockedApp(bundleID: "com.microsoft.teams2", name: "Microsoft Teams (New)", category: .communication, isEnabled: true),
        BlockedApp(bundleID: "notion.id", name: "Notion", category: .documentation, isEnabled: true),
        BlockedApp(bundleID: "com.microsoft.VSCode", name: "VS Code", category: .code, isEnabled: true),
        BlockedApp(bundleID: "com.microsoft.Outlook", name: "Outlook", category: .communication, isEnabled: true),
        BlockedApp(bundleID: "com.apple.mail", name: "Apple Mail", category: .communication, isEnabled: false),
        BlockedApp(bundleID: "com.linear", name: "Linear", category: .projectManagement, isEnabled: true),
    ]
}

struct BlockedWebsite: Codable, Equatable, Identifiable {
    var id: String { domain }
    let domain: String
    let name: String
    let category: WorkCategory
    var isEnabled: Bool
    let additionalSubdomains: [String]

    init(domain: String, name: String, category: WorkCategory, isEnabled: Bool, additionalSubdomains: [String] = []) {
        self.domain = domain
        self.name = name
        self.category = category
        self.isEnabled = isEnabled
        self.additionalSubdomains = additionalSubdomains
    }

    // Custom decoder to handle missing additionalSubdomains field for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        domain = try container.decode(String.self, forKey: .domain)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(WorkCategory.self, forKey: .category)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        additionalSubdomains = try container.decodeIfPresent([String].self, forKey: .additionalSubdomains) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case domain, name, category, isEnabled, additionalSubdomains
    }

    var allDomains: [String] {
        var domains = [domain, "www.\(domain)"]
        domains.append(contentsOf: additionalSubdomains)
        return domains
    }

    static let defaults: [BlockedWebsite] = [
        // Communication - Slack (comprehensive)
        BlockedWebsite(domain: "slack.com", name: "Slack", category: .communication, isEnabled: true,
                      additionalSubdomains: ["app.slack.com", "api.slack.com", "files.slack.com",
                                            "edgeapi.slack.com", "wss-primary.slack.com", "wss-backup.slack.com",
                                            "wss-mobile.slack.com", "slack-edge.com", "slackb.com"]),

        // Communication - Microsoft Teams (comprehensive)
        BlockedWebsite(domain: "teams.microsoft.com", name: "Microsoft Teams", category: .communication, isEnabled: true,
                      additionalSubdomains: ["teams.live.com", "statics.teams.cdn.office.net",
                                            "teams.office.com", "teams.cdn.office.net"]),

        // Communication - Gmail (comprehensive)
        BlockedWebsite(domain: "gmail.com", name: "Gmail", category: .communication, isEnabled: true,
                      additionalSubdomains: ["mail.google.com", "inbox.google.com", "googlemail.com",
                                            "mail-attachment.googleusercontent.com"]),

        // Communication - Outlook (comprehensive)
        BlockedWebsite(domain: "outlook.com", name: "Outlook", category: .communication, isEnabled: true,
                      additionalSubdomains: ["outlook.live.com", "outlook.office.com", "outlook.office365.com",
                                            "mail.live.com", "hotmail.com", "live.com"]),

        // Documentation - Notion (comprehensive)
        BlockedWebsite(domain: "notion.so", name: "Notion", category: .documentation, isEnabled: true,
                      additionalSubdomains: ["notion.site", "api.notion.com", "notion-static.com"]),

        // Documentation - Google Docs (comprehensive)
        BlockedWebsite(domain: "docs.google.com", name: "Google Docs", category: .documentation, isEnabled: true,
                      additionalSubdomains: ["sheets.google.com", "slides.google.com", "drive.google.com",
                                            "forms.google.com", "sites.google.com"]),

        // Documentation - Confluence
        BlockedWebsite(domain: "confluence.atlassian.com", name: "Confluence", category: .documentation, isEnabled: true,
                      additionalSubdomains: ["atlassian.net"]),

        // Code - GitHub (comprehensive)
        BlockedWebsite(domain: "github.com", name: "GitHub", category: .code, isEnabled: true,
                      additionalSubdomains: ["api.github.com", "gist.github.com", "raw.githubusercontent.com",
                                            "githubusercontent.com", "github.io", "github.dev",
                                            "copilot.github.com", "objects.githubusercontent.com"]),

        // Code - GitLab (comprehensive)
        BlockedWebsite(domain: "gitlab.com", name: "GitLab", category: .code, isEnabled: true,
                      additionalSubdomains: ["registry.gitlab.com", "assets.gitlab-static.net"]),

        // Code - AWS Console (comprehensive)
        BlockedWebsite(domain: "console.aws.amazon.com", name: "AWS Console", category: .code, isEnabled: true,
                      additionalSubdomains: ["aws.amazon.com", "signin.aws.amazon.com",
                                            "us-east-1.console.aws.amazon.com", "us-west-2.console.aws.amazon.com",
                                            "eu-west-1.console.aws.amazon.com"]),

        // Code - Google Cloud (comprehensive)
        BlockedWebsite(domain: "cloud.google.com", name: "Google Cloud", category: .code, isEnabled: true,
                      additionalSubdomains: ["console.cloud.google.com", "shell.cloud.google.com",
                                            "firebase.google.com", "console.firebase.google.com"]),

        // Code - Azure (comprehensive)
        BlockedWebsite(domain: "portal.azure.com", name: "Azure Portal", category: .code, isEnabled: true,
                      additionalSubdomains: ["azure.microsoft.com", "azure.com", "dev.azure.com",
                                            "login.microsoftonline.com"]),

        // Project Management - Linear
        BlockedWebsite(domain: "linear.app", name: "Linear", category: .projectManagement, isEnabled: true,
                      additionalSubdomains: ["api.linear.app"]),

        // Project Management - Asana
        BlockedWebsite(domain: "asana.com", name: "Asana", category: .projectManagement, isEnabled: true,
                      additionalSubdomains: ["app.asana.com", "api.asana.com"]),

        // Project Management - Jira
        BlockedWebsite(domain: "jira.atlassian.com", name: "Jira", category: .projectManagement, isEnabled: true,
                      additionalSubdomains: ["atlassian.com", "atlassian.net", "jira.com"]),

        // Project Management - Trello
        BlockedWebsite(domain: "trello.com", name: "Trello", category: .projectManagement, isEnabled: true,
                      additionalSubdomains: ["api.trello.com"]),

        // Project Management - Monday.com
        BlockedWebsite(domain: "monday.com", name: "Monday.com", category: .projectManagement, isEnabled: true,
                      additionalSubdomains: ["api.monday.com"]),

        // Project Management - Basecamp
        BlockedWebsite(domain: "basecamp.com", name: "Basecamp", category: .projectManagement, isEnabled: true,
                      additionalSubdomains: ["3.basecamp.com", "launchpad.37signals.com"]),
    ]
}
