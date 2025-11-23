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

class Settings: ObservableObject {
    @Published var countdownDuration: CountdownDuration = .thirtySeconds
}
