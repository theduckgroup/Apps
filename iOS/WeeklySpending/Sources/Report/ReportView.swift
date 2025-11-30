import Foundation
import SwiftUI
import Backend

struct ReportView: View {
    var template: Template
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
            }
            .navigationTitle(template.name)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        VStack(alignment: .leading) {
            
        }
    }
}

#Preview {
    @Previewable @State var template: Template?
    
    Text("Loading...")
        .fullScreenCover(item: $template) { template in
            ReportView(template: template)
        }
        .task {
            template = try! await API.shared.mockTemplate()
        }
}
