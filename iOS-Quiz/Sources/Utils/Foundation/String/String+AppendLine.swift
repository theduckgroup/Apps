import Foundation

public extension String {
    /// Appends a line with `\n` at the end.
    ///
    /// If the string is not empty and does not end with `\n`, a `\n` is appended before the line.
    mutating func appendLine(_ line: String = "") {
        if let last, last != "\n" {
            // String is not empty and does not end with \n
            append("\n")
        }
        
        append(line + "\n")
    }
}
