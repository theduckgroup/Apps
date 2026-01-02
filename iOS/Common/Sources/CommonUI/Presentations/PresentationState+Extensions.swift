import Foundation
import SwiftUI

public extension PresentationState {
    /// Presents a sheet.
    func presentSheet<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        present { hostView, $isPresented in
            hostView.sheet(isPresented: $isPresented, content: content)
        }
    }
    
    /// Presents a full-screen cover.
    func presentFullScreenCover<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        present { hostView, $isPresented in
            hostView.fullScreenCover(isPresented: $isPresented, content: content)
        }
    }
    
    /// Presents an alert.
    func presentAlert<A: View>(title: String = "", message: String = "", @ViewBuilder actions: @escaping () -> A) {
        present { hostView, $isPresented in
            hostView.alert(
                title,
                isPresented: $isPresented,
                actions: actions,
                message: { Text(message) }
            )
        }
    }
    
    /// Presents an error alert.
    func presentAlert(error: Error) {
        present(item: error) { hostView, $error in
            hostView.alert("Error", presenting: $error)
        }
    }
    
    /// Presents an error alert with given message.
    func presentAlert(errorMessage: String) {
        present(item: errorMessage) { hostView, $errorMessage in
            hostView.alert(
                "Error",
                presenting: $errorMessage,
                actions: { message in Button("OK") {} },
                message: { message in Text(message) }
            )
        }
    }
}
