import ServiceManagement

/// Launch at login through SMAppService (shows up in System Settings › General › Login Items).
@MainActor
enum LoginItem {
    enum Status {
        case enabled, disabled, requiresApproval
    }

    static var status: Status {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        default: .disabled
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
