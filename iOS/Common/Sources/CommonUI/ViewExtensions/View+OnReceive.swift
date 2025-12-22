import SwiftUI

public extension View {
//    @ViewBuilder
//    func onReceive<T>(_ stream: AsyncStream<T>, assignTo: Binding<T>) -> some View {
//        task {
//            for await value in stream {
//                assignTo.wrappedValue = value
//            }
//        }
//    }
    
    @ViewBuilder
    func onReceive<T>(_ createStream: @autoclosure @escaping () -> AsyncStream<T>, perform: @escaping (T) -> Void) -> some View {
        task {
            for await value in createStream() {
                perform(value)
            }
        }
    }
}
