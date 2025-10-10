import Foundation

func wait<R>(atLeast: Duration, _ closure: () async throws -> R) async throws -> R {
    let clock = ContinuousClock()
    let startTime = clock.now

    let result: Result<R, Error> = await {
        do {
            return .success(try await closure())
            
        } catch {
            return .failure(error)
        }
    }()
    
    let elapsedTime = clock.now - startTime
    let remainingTime = atLeast - elapsedTime
    
    if remainingTime > .zero {
        try? await Task.sleep(for: remainingTime)
    }
    
    switch result {
    case .success(let value):
        return value
        
    case .failure(let error):
        throw error
    }
}
