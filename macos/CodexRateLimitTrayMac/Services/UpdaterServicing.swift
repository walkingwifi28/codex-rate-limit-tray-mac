import Combine
import Foundation

@MainActor
protocol UpdaterServicing: ObservableObject {
    var canCheckForUpdates: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    func checkForUpdates()
}
