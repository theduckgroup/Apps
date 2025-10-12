import Foundation
import SwiftUI

struct HomeView: View {
    @AppStorage("App:persistedQuizName") var persistedQuizName: String = ""
    @State var quizResult: Result<Quiz, Error>?
    @State var error: Error?
    @State var isFetching = false
    @State var fetchTask: Task<Void, Never>?
    @State var presentedQuiz: Quiz?
    @State var presentingSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        bodyContent()
            .fullScreenCover(item: $presentedQuiz) { quiz in
                QuizView(quiz: quiz)
            }
            .onAppear {
                fetchQuiz()
            }
            .onReceive(EventHub.shared.quizzesChanged) {
                fetchQuiz()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    fetchQuiz()
                }
            }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        ZStack {
            VStack(spacing: 15) {
                if !persistedQuizName.isEmpty {
                    Text(persistedQuizName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                let quiz: Quiz? = if let quizResult, case .success(let quiz) = quizResult {
                    quiz
                } else {
                    nil
                }
                
                Button {
                    if let quiz {
                        self.presentedQuiz = quiz
                    }
                } label: {
                    Text("Start")
                        .font(.title2)
                        .padding(.horizontal)
                }
                .disabled(quiz == nil)
                .buttonStyle_glassProminent_shim()
                .glassEffectShim()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            HStack {
                Button {
                    presentingSettings = true
                    
                } label: {
                    Image(systemName: "person.fill")
                        .contentShape(Rectangle())
                }
                .buttonStyle(.paper())
                .padding(.bottom, 3)
                .popover(isPresented: $presentingSettings) {
                    SettingsView()
                }
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if isFetching {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 30)
                
            } else if let quizResult, case .failure(let error) = quizResult {
                VStack(alignment: .leading) {
                    Text(formatError(error))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                    
                    Button("Retry") {
                        fetchQuiz(delay: true)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .fixedSize(horizontal: false, vertical: false)
                .padding()
                .frame(width: horizontalSizeClass == .regular ? 570 : nil)
                .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : nil)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemFill))
                }
                .padding()
                
            }
        }
    }
    
    private func fetchQuiz(delay: Bool = false) {
        fetchTask?.cancel()
        
        fetchTask = Task {
            isFetching = true
            
            do {
                if delay {
                    try await Task.sleep(for: .seconds(1))
                }
                
                // throw GenericError("Culpa dolore sit pariatur commodo nulla commodo amet ad velit magna commodo fugiat. Laboris reprehenderit do culpa. Enim quis cupidatat ex mollit elit aute proident dolor dolor laboris et ex esse aliqua fugiat. Commodo officia consequat minim elit aliquip qui veniam labore dolore eu culpa aliquip ex.")
                // throw GenericError("Not connected to internet")
                
                let quiz = try await {
                    if isRunningForPreviews {
                        return try await API.shared.mockQuiz()
                    }
                    
                    return try await API.shared.quiz(code: "FOH_STAFF_KNOWLEDGE")
                }()

                self.quizResult = .success(quiz)
                self.persistedQuizName = quiz.name
                
                isFetching = false
                
            } catch {
                guard !error.isCancellationError else {
                    return
                }
                
                isFetching = false
                
                logger.error("Unable to parse quiz: \(error)")
                self.quizResult = .failure(error)
            }
        }
    }
}

extension View {
    @ViewBuilder
    func onReceive<T>(_ stream: AsyncStream<T>, assignTo: Binding<T>) -> some View {
        task {
            for await value in stream {
                assignTo.wrappedValue = value
            }
        }
    }
    
    @ViewBuilder
    func onReceive<T>(_ createStream: @escaping () -> AsyncStream<T>, perform: @escaping (T) -> Void) -> some View {
        task {
            print("Creating task")
            
            for await value in createStream() {
                perform(value)
            }
        }
    }
    
    @ViewBuilder
    func buttonStyle_glassProminent_shim() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    HomeView()
        .tint(.red)
        .environment(AppDefaults())
}
