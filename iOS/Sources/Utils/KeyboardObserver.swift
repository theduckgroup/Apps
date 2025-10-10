import Foundation
import Combine
import UIKit

@Observable
public class KeyboardObserver {
    static public let shared = KeyboardObserver()
    
    private(set) var isKeyboardVisible = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .sink { [unowned self] _ in
                self.isKeyboardVisible = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .sink { [unowned self] _ in
                self.isKeyboardVisible = false
            }
            .store(in: &cancellables)
    }
}
