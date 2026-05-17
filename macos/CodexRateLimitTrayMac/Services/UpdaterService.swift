import Combine
import Foundation
import Sparkle

@MainActor
final class UpdaterService: UpdaterServicing {
    @Published private(set) var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates: Bool {
        didSet {
            guard automaticallyChecksForUpdates != oldValue else {
                return
            }
            updaterController?.updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
        }
    }

    private let updaterController: SPUStandardUpdaterController?
    private var cancellables = Set<AnyCancellable>()

    init() {
        guard Self.hasConfiguredPublicKey else {
            updaterController = nil
            automaticallyChecksForUpdates = false
            canCheckForUpdates = false
            return
        }

        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = updaterController
        automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates

        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    private static var hasConfiguredPublicKey: Bool {
        guard
            let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
            !publicKey.isEmpty
        else {
            return false
        }
        return publicKey != "REPLACE_WITH_SPARKLE_PUBLIC_ED_KEY"
    }
}
