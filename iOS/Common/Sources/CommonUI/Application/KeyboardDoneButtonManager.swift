import Combine
import UIKit
import Common

public class KeyboardDoneButtonManager {
    public static let shared = KeyboardDoneButtonManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)
            .sink { notification in
                guard UIDevice.current.userInterfaceIdiom == .phone else {
                    return
                }
                
                let textField = notification.object as! UITextField
                textField.inputAccessoryView = KeyboardToolbar(for: textField)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification)
            .sink { notification in
                guard UIDevice.current.userInterfaceIdiom == .phone else {
                    return
                }
                
                let textView = notification.object as! UITextView
                textView.inputAccessoryView = KeyboardToolbar(for: textView)
                textView.reloadInputViews() // Need this for the first time inputAccessoryView is set
            }
            .store(in: &cancellables)
    }
}

private class KeyboardToolbar: UIVisualEffectView {
    convenience init(for inputView: UIView) {
        let effect: UIVisualEffect = {
            if #available(iOS 26, *) {
                UIGlassEffect(style: .regular)
            } else {
                UIBlurEffect(style: .regular)
            }
        }()
        
        self.init(effect: effect)
        
        frame = .init(x: 0, y: 0, width: 600, height: 48)
        
        configureDoneButton(inputView)
    }
    
    private func configureDoneButton(_ inputView: UIView) {
        var config: UIButton.Configuration = {
            if #available(iOS 26, *) {
                .bordered()
            } else {
                .bordered()
            }
        }()
        
        config.image = UIImage(
            systemName: "chevron.down",
//            systemName: "keyboard.chevron.compact.down",
            withConfiguration:
                UIImage.SymbolConfiguration(hierarchicalColor: .label)
//                .applying(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 18, weight: .regular), scale: .medium))
        )
        config.buttonSize = .medium
        // config.baseForegroundColor = UIApplication.shared.anyKeyWindow?.tintColor ?? .secondaryLabel
        // config.baseBackgroundColor = UIApplication.shared.anyKeyWindow?.tintColor
        // config.baseForegroundColor = inputView.window?.tintColor // UIApplication.shared.anyKeyWindow?.tintColor
        // config.cornerStyle = .capsule
//        config.attributedTitle = AttributedString("Done", attributes: AttributeContainer([
//            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
//            .foregroundColor: inputView.tintColor
//        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)

        let button = UIButton(configuration: config, primaryAction: UIAction { _ in
            inputView.resignFirstResponder()
        })
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}


// Implementation with passthrough hit-test and clear background
// Can't make the background completely clear though (even pre-iOS 26); which makes it look not great
/*
private class KeyboardToolbar: UIView {
    convenience init(for inputView: UIView) {
        self.init(frame: .init(x: 0, y: 0, width: 600, height: 54))
        
        backgroundColor = .clear
        isOpaque = false
        
        let doneButton = Self.createDoneButton(for: inputView)
        
        addSubview(doneButton)

        NSLayoutConstraint.activate([
            doneButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private static func createDoneButton(for inputView: UIView) -> UIButton {
        var config: UIButton.Configuration = {
            if #available(iOS 26, *) {
                .glass()
            } else {
                .bordered()
            }
        }()
        
        // config.title = "Done"
        config.image = UIImage(systemName: "chevron.down")
        config.baseForegroundColor = UIApplication.shared.anyKeyWindow?.tintColor // inputView.window?.tintColor
        config.buttonSize = .medium
        // config.baseBackgroundColor = UIApplication.shared.anyKeyWindow?.tintColor
        // config.baseForegroundColor = inputView.window?.tintColor // UIApplication.shared.anyKeyWindow?.tintColor
        // config.cornerStyle = .capsule
        // config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)

        let button = UIButton(configuration: config, primaryAction: UIAction { _ in
            inputView.resignFirstResponder()
        })
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        // Passthrough touches on self

        if hitView == self {
            return nil
        }
        
        // Allow subview touches

        return hitView
    }
}
*/
