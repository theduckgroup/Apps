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
 
        let doneBarItem = UIBarButtonItem(
            title: nil,
            // image: UIImage(systemName: "keyboard.chevron.compact.down"),
            image: UIImage(systemName: "chevron.down"),
            target: view,
            action: #selector(view.resignFirstResponder)
        )
        
        doneBarItem.tintColor = .secondaryLabel
        
        // Custom button: has a white border around the button!
        // let doneBarItem = UIBarButtonItem(customView: createDoneButton(for: view))

        // let doneBarItem = UIBarButtonItem(title: "Done", style: .done, target: view, action: #selector(view.resignFirstResponder))
        // doneBarItem.tintColor = .systemGray
                
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 600, height: 54))
        toolbar.backgroundColor = .systemGray6
        
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            doneBarItem
        ]
        
        return toolbar
    }
    
    private func createDoneButton(for view: UIView) -> UIButton {
        // Not used
        
        var config = UIButton.Configuration.filled()
        config.title = "Done"
        config.baseBackgroundColor = UIApplication.shared.anyKeyWindow?.tintColor
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.buttonSize = .small
        // config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)

        let button = UIButton(configuration: config, primaryAction: UIAction { _ in
            view.resignFirstResponder()
        })
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }
}
