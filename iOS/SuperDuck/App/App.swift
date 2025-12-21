import SwiftUI
import Backend
import AppShared

@main
struct App: SwiftUI.App {
    let auth: Auth
    let api: API
    let appDefaults = AppDefaults(storageKey: "appDefaults:v2")
    
    init() {
        let auth = Auth()
        
        self.auth = auth
        
        self.api = {
            switch AppInfo.buildTarget {
            case .prod: API(env: .prod, auth: auth)
            case .local: API(env: .local, auth: auth)
            }
        }()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .onOpenURL { url in
                    auth.handle(url)
                }
        }
        .environment(auth)
        .environment(api)
        .environment(appDefaults)
    }
}

//

//private let auth = Auth()
//
//extension API {
//    static let shared: API = {
//        switch AppInfo.buildTarget {
//        case .prod: .prod
//        case .local: .local
//        }
//    }()
//}
//
//extension API {
//    static let prod = API(env: .prod, auth: .shared)
//    static let local = API(env: .local, auth: .shared)
//}
//
