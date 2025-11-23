import Foundation

@MainActor
class Countdown: ObservableObject {
    @Published var countdownNumber: Int = 3
    
    private var countdownTask: Task<Void, Error>?
    
    func start(
        from: Int,
        onUpdate: @escaping (Int) -> Void,
        onFinish: @escaping () -> Void
    ) {
        countdownNumber = from
        
        countdownTask = Task {
            for i in (1...from).reversed() {
                try await Task.sleep(for: .seconds(1))
                let number = i - 1
                onUpdate(number)
            }
            onFinish()
        }
    }
    
    func cancel() {
        countdownTask?.cancel()
    }
}
