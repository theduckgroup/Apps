import Foundation
import Backend
import Common

extension API {
    static let shared: API = {
        if isRunningForPreviews {
            return .local
        }
        
        switch AppInfo.buildTarget {
        case .prod:
            return .prod
            
        case .local:
            return API(
                // url: URL(string: "http://192.168.0.207:8021/api/quiz-app")!
                url: URL(string: "http://172.20.10.11:8021/api")!,
                auth: .shared
            )
        }
    }()
//    static let shared = API(
//        auth: .shared,
//        baseURL: {
//            switch AppInfo.buildTarget {
//            case .prod: URL(string: "https://apps.theduckgroup.com.au/api/quiz-app")!
//            // case .local: URL(string: "http://192.168.0.207:8021/api/quiz-app")!
//            case .local: URL(string: "http://172.20.10.11:8021/api/quiz-app")!
//            }
//        }()
//    )
}

extension Auth {
    // static let auth = Auth()
}

//
//extension EventHub {
//    static let shared = EventHub(baseURL: API.shared.baseURL)
//    
//    var quizzesChanged: AsyncStream<Void> {
//        events("quiz-app:quizzes:changed")
//    }
//}
