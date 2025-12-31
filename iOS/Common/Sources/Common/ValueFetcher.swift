public import Foundation

@MainActor @Observable
public class ValueFetcher<Value> {
    private(set) public var value: Value?
    private(set) public var error: Error?
    private(set) public var isFetching = false
    private var task: Task<Void, Never>?
    
    public init() {}
    
    public func fetch(delay: Bool = false, operation: @MainActor @Sendable @escaping () async throws -> Value) {
        task?.cancel()
        
        task = Task {
            do {
                self.error = nil
                self.isFetching = true
                
                // Can't set isFetching in defer due to cancellation
                
                if delay {
                    try await Task.sleep(for: .seconds(0.5))
                }
                
                try Task.checkCancellation()
                
                if debugging {
                    // try await Task.sleep(for: .seconds(2))
                    // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                    // throw GenericError("Not connected to internet")
                }
                
                let fetchedValue = try await operation()
                
                try Task.checkCancellation()
                
                self.value = fetchedValue
                self.isFetching = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                self.error = error
                self.isFetching = false
            }
        }
    }
}
