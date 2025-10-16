import UIKit
import SwiftUI
import Common

// NOT USED
struct PagesView<T: Hashable, Content: View>: UIViewControllerRepresentable {
    @Binding var selection: T
    let values: [T]
    let content: (T) -> Content

    init(
        selection: Binding<T>,
        values: [T],
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self._selection = selection
        self.values = values
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [
                .interPageSpacing: 20
            ]
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator

        let initialVC = context.coordinator.controller(for: selection)
        controller.setViewControllers([initialVC], direction: .forward, animated: false)

        return controller
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        logger.info("updateUIViewController, selection = \(selection)")
        
        context.coordinator.parent = self
        context.coordinator.updateController(for: selection)
                
        if selection != context.coordinator.selection {
            logger.info("Updating selection from \(context.coordinator.selection) to \(selection)")
            
            let vc = context.coordinator.controller(for: selection)
            
            let direction: UIPageViewController.NavigationDirection = {
                if let currentIndex = values.firstIndex(of: context.coordinator.selection),
                   let newIndex = values.firstIndex(of: selection),
                   newIndex > currentIndex {
                    return .forward
                } else {
                    return .reverse
                }
            }()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                uiViewController.setViewControllers([vc], direction: direction, animated: true)
                context.coordinator.selection = selection
            }
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PagesView
        var viewControllers: [T: UIHostingController<AnyView>] = [:]
        var selection: T

        init(_ parent: PagesView) {
            self.parent = parent
            self.selection = parent.selection
        }
        
        deinit {} // Needed due to compiler error

        func updateController(for value: T) {
            if let vc = viewControllers[value] {
                vc.rootView = AnyView(parent.content(value))
            }
        }

        func controller(for value: T) -> UIViewController {
            logger.info("controller for \(value)")
            
            if let vc = viewControllers[value] {
                logger.info("using cached")
                return vc
            }
            
            logger.info("returning new")
            
            let hosting = UIHostingController(rootView: AnyView(parent.content(value)))
            viewControllers[value] = hosting
            return hosting
        }

        // PageViewController Data Source

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let currentIndex = index(of: viewController), currentIndex > 0 else {
                return nil
            }
            
            logger.info("viewControllerBefore \(currentIndex)")

            let prevValue = parent.values[currentIndex - 1]
            return controller(for: prevValue)
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let currentIndex = index(of: viewController), currentIndex < parent.values.count - 1 else {
                return nil
            }
            
            logger.info("viewControllerAfter \(currentIndex)")
            
            let nextValue = parent.values[currentIndex + 1]
            return controller(for: nextValue)
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            logger.info("didFinishAnimating")
            
            guard completed,
                  let visibleVC = pageViewController.viewControllers?.first,
                  let newIndex = index(of: visibleVC)
            else {
                return
            }

            let newValue = parent.values[newIndex]
            selection = newValue
            
            if parent.selection != newValue {
                DispatchQueue.main.async {
                    self.parent.selection = newValue
                }
            }
        }

        private func index(of viewController: UIViewController) -> Int? {
            viewControllers.first { $0.value == viewController }
                .flatMap { parent.values.firstIndex(of: $0.key) }
        }
    }
}


#Preview {
    @Previewable @State var value = 0
    
    VStack {
        PagesView(selection: $value, values: [0, 1, 2]) { value in
            switch value {
            case 0:
                Text("Red")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red)
                
            case 1:
                Text("Teal")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.teal)
            case 2:
                Text("Yellow")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
                
            default:
                fatalError()
            }
        }
        
        Text("Value: \(value)")
    }
}
