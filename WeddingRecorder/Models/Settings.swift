import Foundation

enum CountdownDuration: Int, CaseIterable, Identifiable {
    case thirtySeconds = 30
    case oneMinute = 60
    case twoMinutes = 120
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .thirtySeconds:
            return "30 segundos"
        case .oneMinute:
            return "1 minuto"
        case .twoMinutes:
            return "2 minutos"
        }
    }
}

enum PhotoBurstCountdownDuration: Int, CaseIterable, Identifiable {
    case fiveSeconds = 5
    case eightSeconds = 8
    case tenSeconds = 10
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        "\(self.rawValue) segundos"
    }
}

class Settings: ObservableObject {
    static let shared = Settings() // Singleton instance
    
    @Published var countdownDuration: CountdownDuration = .thirtySeconds
    @Published var photoBurstCountdownDuration: PhotoBurstCountdownDuration = .fiveSeconds
    
    private init() {} // Private initializer to ensure singleton usage
}
