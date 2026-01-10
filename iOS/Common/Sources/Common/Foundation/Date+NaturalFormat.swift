import Foundation

public extension Date {
    func naturalFormat() -> String {
        if Calendar.current.isDateInToday(self) {
            let timeString = self.formatted(.dateTime.hour().minute())
            return "Today \(timeString)"
            
        } else if Calendar.current.isDateInYesterday(self) {
            let timeString = self.formatted(.dateTime.hour().minute())
            return "Yesterday \(timeString)"
            
        } else {
            return self.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())
        }
    }
}
