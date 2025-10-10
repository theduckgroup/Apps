import Foundation

public extension String {
    func contains(_ substring: String, options: String.CompareOptions) -> Bool {
        range(of: substring, options: options, range: nil, locale: nil) != nil
    }
    
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        // See: https://stackoverflow.com/a/47220964/1572953
        
        var ranges: [Range<Index>] = []
        
        while ranges.last.map({ $0.upperBound < self.endIndex }) ?? true,
            let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex) ..< self.endIndex, locale: locale)
        {
            ranges.append(range)
        }
        
        return ranges
    }
}
