import Foundation

actor DeduplicatePool<Success> {
    private var runningTasks: [String: Task<Success, Error>] = [:]
    
    func run(key: String, _ taskFactory: @escaping () -> () async throws -> Success) async throws -> Success {
        if let existingTask = runningTasks[key] {
            return try await existingTask.value
        }
        
        let taskClosure = taskFactory()
        
        let newTask = Task {
            try await taskClosure()
        }
        
        runningTasks[key] = newTask
        
        defer {
            runningTasks[key] = nil
        }
        
        return try await newTask.value
    }
    
    func waitForAllTasks() async {
        for task in runningTasks.values {
            _ = await task.result
        }
        
        // Cleanup is done in the `run` method. Not needed here.
    }
}
