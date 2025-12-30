import Foundation
import SwiftUI

#Preview {
    PresentationStatePreviewView()
}

public struct PresentationStatePreviewView: View {
    @State var state = PresentationState()
    @State var state2 = PresentationState() // For testing not-added-to-view presentation state
    @State var uikitContext = UIKitContext()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            TaskButton("Present") {
                try await present()
            }
            
            TaskButton("Quick present/dismiss") {
                try await quickPresentDismiss()
            }
            
            TaskButton("Randomized present/dismiss") {
                try await randomizedPresentDismiss()
            }
            
            TaskButton("[Illegal] Dismiss without present") {
                try await dismissWithoutPresent()
            }
            
            TaskButton("[Illegal] Over-dismiss") {
                try await overDismiss()
            }
            
            TaskButton("[Illegal] Present multiple times (without delay)") {
                try await presentMultipleTimesWithoutDelay()
            }
            
            TaskButton("[Illegal] Present multiple times (with delay)") {
                try await presentMultipleTimesWithDelay()
            }
            
            TaskButton("[Illegal] Present without `presentations` modifier") {
                state2.presentSheet {
                    Text("You should not see this")
                }
            }
            
            Label("Use Preview output to see errors", systemImage: "info.circle.fill")
                .font(.subheadline)
                .padding(.top, 30)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
        }
        .presentations(state)
        .attach(uikitContext)
    }
    
    private func present() async throws {
        do {
            // Sheet with isPresented binding
            // (Internally `presentSheet` uses present with isPresented binding)
            
            state.presentSheet {
                Text("Presented with isPresented binding")
                    .interactiveDismissDisabled()
            }
            
            try await Task.sleep(for: .seconds(2))
            
            state.dismiss()
        }
        
        do {
            // Full-screen cover with item binding
            
            struct Item: Identifiable {
                var id: String
            }
            
            state.present(item: Item(id: "49")) { hostView, item in
                hostView.fullScreenCover(item: item) { item in
                    Text("Presented with item binding | Item ID: \(item.id)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                }
            }
            
            try await Task.sleep(for: .seconds(2))
            
            state.dismiss()
        }
        
        do {
            // Alert
            // Also using async/continuation to wait for user interaction
            
            try await withCheckedThrowingContinuation { cont in
                state.presentAlert(title: "Alert", message: "Hello!", actions: {
                    Button("Continue") {
                        cont.resume()
                    }
                    
                    Button("Cancel", role: .cancel) {
                        cont.resume(throwing: CancellationError())
                    }
                })
            }
        }
         
        do {
            // Progress HUD
                
            let progressHUDState = ProgressHUDState(title: "Loading", progress: .determinate(fraction: 0))
            
            state.presentProgressHUD(progressHUDState)
            
            for i in 0..<100 {
                progressHUDState.progress = .determinate(fraction: Double(i) / 100)
                try await Task.sleep(for: .seconds(0.025))
            }
            
            try await Task.sleep(for: .seconds(1))
            
            state.dismiss()
        }
        
        do {
            // Message HUD
            
            state.presentMessageHUD("Done")
            try await Task.sleep(for: .seconds(2))
            state.dismiss()
        }
    }

    private func quickPresentDismiss() async throws {
        state.presentProgressHUD(title: "Loading 1", message: "")
        // No wait before dismiss
        state.dismiss()
        
        // No wait before next present
        
        state.presentProgressHUD(title: "Loading 2", message: "")
        try await Task.sleep(for: .seconds(0.1)) // Short wait before dismiss
        state.dismiss()
        
        try await Task.sleep(for: .seconds(0.1)) // Short wait before next present
        
        state.presentProgressHUD(title: "Loading 3", message: "")
        try await Task.sleep(for: .seconds(1)) // Long wait before dismiss
        state.dismiss()
        
        try await Task.sleep(for: .seconds(1)) // Long wait before next present
        
        state.presentMessageHUD("Done")
        try await Task.sleep(for: .seconds(1))
        state.dismiss()
    }
    
    private func randomizedPresentDismiss() async throws {
        enum Kind: CaseIterable {
            case alert
            case sheet
            case fullScreenCover
            case customAlert
            case progressHUD
            case messageHUD
        }
        
        for i in 1..<100 {
            print("Iteration \(i)")
            
            // Present
            
            let kind = Kind.allCases.randomElement()!
            
            switch kind {
            case .alert: state.presentAlert(title: "Alert", actions: {})
            case .sheet: state.presentSheet { Text("Sheet") }
            case .fullScreenCover: state.presentFullScreenCover { Text("Full-screen Cover") }
            case .customAlert: state.presentCustomAlert(title: "Custom Alert", actions: []) { Text("Content") }
            case .progressHUD: state.presentProgressHUD(title: "Progress", message: "")
            case .messageHUD: state.presentMessageHUD("Done")
            }
            
            // Wait 0-1 sec before dismiss, 90% of the time
            
            if Double.random(in: 0..<1) < 0.90 {
                try await Task.sleep(for: .seconds(Double.random(in: 0..<1)))
            }
            
            // Dismiss
            
            state.dismiss()
            
            // Wait 0-1 sec before next present, 90% of the time
            
            if Double.random(in: 0..<1) < 0.90 {
                try await Task.sleep(for: .seconds(Double.random(in: 0..<1)))
            }
        }
    }
    
    private func dismissWithoutPresent() async throws {
        state.dismiss()
        
        state.presentFullScreenCover {
            Text("(After dismiss)")
            Button("Dismiss") { state.dismiss() }
        }
    }
    
    private func overDismiss() async throws {
        state.presentFullScreenCover {
            Text("View 1")
        }
        
        try await Task.sleep(for: .seconds(1))
        
        state.dismiss()
        state.dismiss()
        
        try await Task.sleep(for: .seconds(1))
        
        state.dismiss()
        state.dismiss()
        
        try await Task.sleep(for: .seconds(1))
        
        state.presentSheet {
            Text("(After over-dismiss)")
            Button("Dismiss") { state.dismiss() }
        }
    }
    
    private func presentMultipleTimesWithoutDelay() async throws {
        state.presentSheet {
            Text("View 1")
        }
        
        state.presentSheet {
            Text("View 2")
        }
        
        state.presentSheet {
            Text("View 3")
            Button("Dismiss") { state.dismiss() }
        }
    }
    
    private func presentMultipleTimesWithDelay() async throws {
        state.presentSheet {
            Text("View 1")
        }
        
        try await Task.sleep(for: .seconds(2))
        
        state.presentSheet {
            Text("View 2")
        }
        
        try await Task.sleep(for: .seconds(2))
        
        state.presentSheet {
            Text("View 3")
        }
    }
}

/// Button that runs an async action in an unstructured task.
private struct TaskButton: View {
    let title: String
    let action: () async throws -> Void
    
    init(_ title: String, action: @escaping () async throws -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(title) {
            Task {
                try await self.action()
            }
        }
    }
}
