import Foundation

/// Decides when text binding is updated.
public enum TextFieldBindingUpdateMode {
    /// Text binding is updated as user types
    case immediate
    
    /// Text binding is updated when editing ends.
    /// - Important: You most likely have to resign focus when the view disappears or before data submission.
    case onEndEditing
}
