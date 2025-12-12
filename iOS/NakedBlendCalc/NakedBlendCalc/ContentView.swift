import SwiftUI
import UIKit

struct ContentView: View {
    let title = "Naked Blend Calculator"
    let resultViewID = "resultTextID"
    @State var mon: Double = 0
    @State var tue: Double = 0
    @State var wed: Double = 0
    @State var thu: Double = 0
    @State var fri: Double = 0
    @State var sat: Double = 0
    @State var sun: Double = 0
    let agingDays: Double = 14
    @State var publicHolidays: Double = 0
    @State var coffeeOnHand: Double = 0
    @State var coffeeDelivery: Double = 0
    @State var keyboardHeight: CGFloat = 0
    @State var confirmResetAlert: Bool = false
    @State var windowSize: CGSize = .zero
    @State var windowSafeAreaInsets: EdgeInsets = .init()
    @ScaledMetric var regularBodyTitleHeight: CGFloat = 48
    @ScaledMetric var regularContentWidth: CGFloat = 640
    @ScaledMetric var scaled12pt: CGFloat = 12
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularBody()
                
            } else {
                compactBody()
            }
        }
        .keyboardHeight($keyboardHeight)
        .alert("Reset Calculator?", isPresented: $confirmResetAlert, actions: {
            Button("Reset", role: .destructive) {
                UIApplication.dismissKeyboard()
                reset()
            }
            
        }, message: {
            
        })
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func regularBody() -> some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(.vertical) {
                VStack {
                    // Note: keyboard affects view size; to avoid problems, make sure the calculated
                    // size does not include keyboard safe area inset
                    
                    let portrait = windowSize.height > 1.25 * windowSize.width
                    
                    let height = portrait ? windowSize.height - windowSafeAreaInsets.top - windowSafeAreaInsets.bottom : nil
                    let offsetY: CGFloat = portrait ? (keyboardHeight > 10 ? -60 : 0) : 0
                    let paddingTop: CGFloat? = !portrait ? windowSafeAreaInsets.top + 20 : nil
                    let paddingBottom: CGFloat? = !portrait ? 20 : nil
                    
                    // Using if/else here will mess up portrait/landscape transition
                    
                    regularBodyContent(scrollViewProxy)
                        // Portrait
                        .frame(height: height)
                        .animation(.spring(), value: keyboardHeight)
                        .offset(y: offsetY)
                        // Lansdcape
                        .padding(.top, paddingTop)
                        .padding(.bottom, paddingBottom)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .background {
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePrefKey.self, value: geometryProxy.size)
                    .preference(key: SafeAreaInsetsPrefKey.self, value: geometryProxy.safeAreaInsets)
            }
            .ignoresSafeArea(.keyboard)
        }
        .onPreferenceChange(SizePrefKey.self) { value in
            if let value {
                self.windowSize = value
            }
        }
        .onPreferenceChange(SafeAreaInsetsPrefKey.self) { value in
            if let value {
                self.windowSafeAreaInsets = value
            }
        }
    }
    
    @ViewBuilder
    private func regularBodyContent(_ scrollViewProxy: ScrollViewProxy) -> some View {
        let contentWidth = min(windowSize.width - 2 * 20, regularContentWidth)
        
        VStack(spacing: 0) {
            regularBodyTitleView()
            content(scrollViewProxy)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: max(contentWidth, 0)) // Avoid warning wrt initial negative width
        .background(Color(uiColor: .quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
    
    @ViewBuilder
    private func regularBodyTitleView() -> some View {
        HStack {
            resetButton().opacity(0)
            
            Text(title)
                .frame(maxWidth: .infinity)
                .font(.body.bold())
            
            resetButton()
        }
        .padding(.horizontal, 12)
        .frame(height: regularBodyTitleHeight)
        .background(Color.themeMain)
        .foregroundStyle(Color.white)
        .tint(Color.themeMain)
    }
    
    @ViewBuilder
    private func compactBody() -> some View {
        NavigationView {
            ScrollViewReader { scrollViewProxy  in
                ScrollView {
                    content(scrollViewProxy)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                resetButton()
                            }
                        }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .addKeyboardDoneButton()
        }
    }
    
    @ViewBuilder
    private func resetButton() -> some View {
        Button("Reset") {
            confirmResetAlert = true
            UIApplication.dismissKeyboard()
        }
    }
    
    @ViewBuilder
    private func content(_ scrollViewProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Count and place coffee order on Monday afternoon")
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, scaled12pt)
            
            Divider()
            
            coffeePerDaySection()
            
            Divider()
            
            otherSection(scrollViewProxy)
            
            Divider()
            
            resultView()
        }
    }
    
    @ViewBuilder
    private func coffeePerDaySection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Average of Coffee Using per Day")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                let average = averageCoffeePerDay()
                
                if average > 0.01 {
                    HStack(spacing: 3) {
                        let formattedAverage = average.formatted(.number.precision(.fractionLength(0...1)))
                        Text("\(formattedAverage) kg")
                    }
                }
            }
            .font(.body.weight(.bold))
            
            let mon = NumberField("Mon", $mon, unit: "kg", restriction: .double).infiniteMaxWidth()
            let tue = NumberField("Tue", $tue, unit: "kg", restriction: .double).infiniteMaxWidth()
            let wed = NumberField("Wed", $wed, unit: "kg", restriction: .double).infiniteMaxWidth()
            let thu = NumberField("Thu", $thu, unit: "kg", restriction: .double).infiniteMaxWidth()
            let fri = NumberField("Fri", $fri, unit: "kg", restriction: .double).infiniteMaxWidth()
            let sat = NumberField("Sat", $sat, unit: "kg", restriction: .double).infiniteMaxWidth()
            let sun = NumberField("Sun", $sun, unit: "kg", restriction: .double).infiniteMaxWidth()
            let space = Color.clear.infiniteMaxWidth() // Not the same as Spacer()
            
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    mon; tue; wed; thu; fri; sat; sun
                }
                
            } else {
                HStack(spacing: 0) {
                    mon; tue; wed; thu
                }
                
                HStack(spacing: 0) {
                    fri; sat; sun; space
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func otherSection(_ scrollViewProxy: ScrollViewProxy?) -> some View {
        VStack(alignment: .leading) {
            let aging = NumberField("Aging Days", .constant(agingDays), restriction: .integer).disabled(true)
            let pub = NumberField("Public Holidays (if any)", $publicHolidays, restriction: .integer)
            
            let onFocus = {
                guard let scrollViewProxy else {
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation {
                        // ScrollViewProxy is buggy on iOS 15
                        
                        if #available(iOS 16, *) {
                            scrollViewProxy.scrollTo(resultViewID, anchor: .bottom)
                        }
                    }
                }
            }

            let coh = NumberField("Current Coffee on Hand", $coffeeOnHand, unit: "kg", restriction: .double, onFocus: onFocus)
            let cd = NumberField("Coffee Delivery Coming This Week", $coffeeDelivery, unit: "kg", restriction: .double, onFocus: onFocus)
            
            HStack(alignment: .top, spacing: 0) {
                aging.infiniteMaxWidth()
                pub.infiniteMaxWidth()
            }

            if horizontalSizeClass == .regular {
                HStack(alignment: .top) {
                    coh.infiniteMaxWidth()
                    cd.infiniteMaxWidth()
                }
                
            } else {
                VStack(alignment: .leading) {
                    coh.infiniteMaxWidth()
                    cd.infiniteMaxWidth()
                }
            }
            
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func resultView() -> some View {
        HStack {
            let value = coffeeToOrder().formatted(.number.precision(.fractionLength(0..<1)))
            
            VStack(spacing: 6) {
                Text("Naked Blend to order")
                    .font(.title3.smallCaps())
                
                Text("\(value) kg")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.themeOrange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 18)
        .id(resultViewID)
    }
    
    private func reset() {
        mon = 0
        tue = 0
        wed = 0
        thu = 0
        fri = 0
        sat = 0
        sun = 0
        publicHolidays = 0
        coffeeOnHand = 0
        coffeeDelivery = 0
    }
    
    private func averageCoffeePerDay() -> Double {
        let values = [mon, tue, wed, thu, fri, sat, sun]
        let n = values.filter { $0.isNonZero }.count

        guard n > 0 else {
            return 0
        }
        
        let result = values.reduce(0, +) / Double(n)
        return result
    }
    
    private func coffeeToOrder() -> Double {
        var value = averageCoffeePerDay() * (agingDays - publicHolidays) - (coffeeOnHand + coffeeDelivery)

        guard value.isNonZero && value > 0 else {
            return 0
        }

        value = (value / 6).rounded(.up) * 6
        
        return value
    }
}

private struct NumberField: View {
    let name: String
    @Binding var value: Double
    var unit: String?
    var restriction: Restriction
    var onFocus: () -> Void
    @State private var text: String
    @FocusState private var focused
    @ScaledMetric private var fontSize: CGFloat = 20
    
    init(
        _ name: String,
        _ value: Binding<Double>,
        unit: String? = nil,
        restriction: Restriction,
        onFocus: @escaping () -> Void = { }
    ) {
        self.name = name
        _value = value
        self.restriction = restriction
        self.unit = unit
        self.text = Self.formatValue(value.wrappedValue, unit, restriction)
        self.onFocus = onFocus
    }
    
    private var integer: Bool {
        restriction == .integer
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .font(.body.smallCaps().leading(.tight))
                .frame(maxHeight: .infinity, alignment: .bottom)
            
            TextField("", text: $text)
                .focused($focused)
                .font(.system(size: fontSize))
                .multilineTextAlignment(.leading)
                .frame(height: fontSize * 1.75)
                .keyboardType(integer ? .numberPad : .decimalPad)
        }
        .frame(minWidth: 60, alignment: .leading)
        // .fixedSize()
        .onTapGesture {
            focused = true
        }
        .onChange(of: text) { newValue in
            let x = text.components(separatedBy: " ").first ?? "" // Strip unit
            value = Double(x) ?? 0
        }
        .onChange(of: value) { newValue in
            if !focused {
                text = Self.formatValue(value, unit, restriction)
                // print("4 Set text to \(text)")
            }
        }
        .onChange(of: focused) { newValue in
            if focused {
                if value == 0 {
                    text = ""
                    
                } else {
                    text = Self.formatValue(value, restriction)
                    // print("1 Set text to \(text)")
                }
                
                onFocus()
                
            } else {
                text = Self.formatValue(value, unit, restriction)
                // print("2 Set text to \(text), unit = \(unit ?? "nil")")
            }
        }
    }
    
    /// Formats value with unit.
    private static func formatValue(_ value: Double, _ unit: String?, _ restriction: Restriction) -> String {
        var result = formatValue(value, restriction)
        
        if let unit {
            result += " \(unit)"
        }
        
        return result
    }
    
    /// Formats value (without unit).
    private static func formatValue(_ value: Double, _ restriction: Restriction) -> String {
        value.formatted(
            .number
                .precision(
                    .fractionLength(restriction == .integer ? 0...0 : 0...1)
                )
                .grouping(.never)
        )
    }
    
    enum Restriction {
        case integer
        case double
    }
}

extension View {
    @ViewBuilder
    func themedNavigationBar() -> some View {
        if #available(iOS 16, *) {
            self.toolbarBackground(Color.themeMain, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            
        } else {
            let _ = {
                UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
                UINavigationBar.appearance().backgroundColor = UIColor.themeMain
                UINavigationBar.appearance().barTintColor = UIColor.white
            }()
            
            self
        }
    }
}

struct SizePrefKey: PreferenceKey {
    static var defaultValue: CGSize?
    
    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        if let next = nextValue() {
            value = next
        }
    }
}

struct SafeAreaInsetsPrefKey: PreferenceKey {
    static var defaultValue: EdgeInsets?
    
    static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
        if let next = nextValue() {
            value = next
        }
    }
}

extension Double {
    var isNonZero: Bool {
        abs(self) > 0.01
        
        
    }
}

#Preview {
    ContentView()
}
