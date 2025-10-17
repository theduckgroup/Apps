import Combine
import UIKit
import Common

public class KeyboardDoneButtonManager {
    public static let shared = KeyboardDoneButtonManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)
            .sink { [self] notification in
                let textField = notification.object as! UITextField
                textField.inputAccessoryView = inputAccessoryViewWithDoneButton(for: textField)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification)
            .sink { [self] notification in
                let textView = notification.object as! UITextView
                textView.inputAccessoryView = inputAccessoryViewWithDoneButton(for: textView)
                textView.reloadInputViews() // Need this for the first time inputAccessoryView is set
            }
            .store(in: &cancellables)
    }
    
    private func inputAccessoryViewWithDoneButton(for view: UIView) -> UIView? {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            return nil
        }
 
//        let doneBarItem = UIBarButtonItem(
//            title: nil,
//            image: UIImage(systemName: "keyboard.chevron.compact.down"),
//            target: view,
//            action: #selector(view.resignFirstResponder)
//        )
//        
//        doneBarItem.tintColor = .secondaryLabel
        
        let doneBarItem = UIBarButtonItem(title: "Done", style: .done, target: view, action: #selector(view.resignFirstResponder))
        // doneBarItem.tintColor = UIApplication.shared.anyKeyWindow?.tintColor
        doneBarItem.tintColor = .tintColor
        // doneBarItem.tintColor = .secondaryLabel
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        // toolbar.barTintColor = .tintColor
        
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            doneBarItem
        ]
        
        return toolbar
    }
}
