import Combine
import Foundation
import ServiceManagement

protocol LoginItemServicing {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

struct LoginItemService: LoginItemServicing {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}

@MainActor
final class LoginItemViewModel: ObservableObject {
    @Published var isEnabled: Bool
    @Published private(set) var errorMessage: String?

    private let service: LoginItemServicing

    init(service: LoginItemServicing) {
        self.service = service
        self.isEnabled = service.isEnabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            try service.setEnabled(enabled)
            isEnabled = service.isEnabled
            errorMessage = nil
        } catch {
            isEnabled = service.isEnabled
            errorMessage = "ログイン項目を更新できません"
        }
    }

    func refresh() {
        isEnabled = service.isEnabled
    }
}
