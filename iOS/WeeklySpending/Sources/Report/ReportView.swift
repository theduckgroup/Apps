import Foundation
import SwiftUI

struct ReportView: View {
    var template: Template
    
    var body: some View {
        Text(template.name)
    }
}
