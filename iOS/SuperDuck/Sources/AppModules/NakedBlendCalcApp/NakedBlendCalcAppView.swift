import SwiftUI
import UIKit
import CommonUI

struct NakedBlendCalcAppView: View {
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
    @State var scrollPosition = ScrollPosition(idType: String.self)
    @State var confirmResetAlert: Bool = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init() {}
    
    var body: some View {
        NavigationStack {
            ScrollView {
                content()
                    .padding(.horizontal)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    }
                    .padding()
                    .id("contentView")
                    .scrollTargetLayout()
            }
            .scrollPosition($scrollPosition)
            .animation(.default, value: scrollPosition)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Naked Blend Calculator")
            .toolbar { toolbarContent() }
            .nonProdEnvWarningOverlay()
            .floatingTabBarSafeAreaInset()
            .onFloatingTabFirstSelected {
                Task {
                    // Scroll to ID animates by default but scroll to x/y does not!
                    // Wrapping this in withAnimation will actually break the animation!
                    try await Task.sleep(for: .seconds(0.10))
                    scrollPosition.scrollTo(id: "contentView", anchor: .bottom)
                }
            }
        }
        .alert("Reset Calculator?", isPresented: $confirmResetAlert, actions: {
            Button("Reset", role: .destructive) {
                UIApplication.shared.dismissKeyboard()
                reset()
            }
        }, message: {
            
        })
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Reset") {
                confirmResetAlert = true
                UIApplication.shared.dismissKeyboard()
            }
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Count and place coffee order on Monday afternoon")
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.vertical)
                .id("top")
            
            Divider()
            
            coffeePerDaySection()
                .id("coffeePerDaySection")
            
            Divider()

            otherSection()
                .id("otherSection")
            
            Divider()

            resultView()
        }
    }
    
    @ViewBuilder
    private func coffeePerDaySection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline) {
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
            .bold()
            
            let mon = NBNumberField("Mon", $mon, unit: "kg", restriction: .double).infiniteMaxWidth()
            let tue = NBNumberField("Tue", $tue, unit: "kg", restriction: .double).infiniteMaxWidth()
            let wed = NBNumberField("Wed", $wed, unit: "kg", restriction: .double).infiniteMaxWidth()
            let thu = NBNumberField("Thu", $thu, unit: "kg", restriction: .double).infiniteMaxWidth()
            let fri = NBNumberField("Fri", $fri, unit: "kg", restriction: .double).infiniteMaxWidth()
            let sat = NBNumberField("Sat", $sat, unit: "kg", restriction: .double).infiniteMaxWidth()
            let sun = NBNumberField("Sun", $sun, unit: "kg", restriction: .double).infiniteMaxWidth()
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
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func otherSection() -> some View {
        VStack(alignment: .leading) {
            let aging = NBNumberField("Aging Days", .constant(agingDays), restriction: .integer)
                .disabled(true)
                .foregroundStyle(.secondary)
            
            let pub = NBNumberField("Public Holidays (if any)", $publicHolidays, restriction: .integer)
            
            let onFocus = {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    scrollPosition.scrollTo(id: "contentView", anchor: .bottom)
                }
            }

            let coh = NBNumberField("Current Coffee on Hand", $coffeeOnHand, unit: "kg", restriction: .double, onFocus: onFocus)
            let cd = NBNumberField("Coffee Delivery Coming This Week", $coffeeDelivery, unit: "kg", restriction: .double, onFocus: onFocus)
            
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

//private struct SizePrefKey: PreferenceKey {
//    static var defaultValue: CGSize?
//    
//    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
//        if let next = nextValue() {
//            value = next
//        }
//    }
//}
//
//private struct SafeAreaInsetsPrefKey: PreferenceKey {
//    static var defaultValue: EdgeInsets?
//    
//    static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
//        if let next = nextValue() {
//            value = next
//        }
//    }
//}

private extension Double {
    var isNonZero: Bool {
        abs(self) > 0.01
    }
}

private extension View {
    @ViewBuilder
    func infiniteMaxWidth(alignment: Alignment = .leading) -> some View {
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
}

#Preview {
    NakedBlendCalcAppView()
}
