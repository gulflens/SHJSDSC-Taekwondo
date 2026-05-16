import SwiftUI

/// Modifiers that turn any view into a tap-target which presents an alert
/// containing a number-pad TextField. Used to let users type values directly
/// instead of clicking +/− buttons many times.
///
/// Usage:
///     Text("\(value)").tappableInt($value, in: 0...500)
///     Text("AED \(price)").tappableDouble($price, in: 0...10_000, decimals: 0)

public extension View {
    /// Make this view tappable; opens an alert with a number-pad TextField
    /// pre-filled with the current Int value.
    func tappableInt(
        _ value: Binding<Int>,
        in range: ClosedRange<Int>? = nil,
        title: LocalizedStringKey = "input.enter_value"
    ) -> some View {
        modifier(IntInputAlertModifier(value: value, range: range, title: title))
    }

    /// Make this view tappable; opens an alert with a decimal-pad TextField
    /// pre-filled with the current Double value, formatted to `decimals`.
    func tappableDouble(
        _ value: Binding<Double>,
        in range: ClosedRange<Double>? = nil,
        decimals: Int = 0,
        title: LocalizedStringKey = "input.enter_value"
    ) -> some View {
        modifier(DoubleInputAlertModifier(value: value, range: range, decimals: decimals, title: title))
    }
}

// MARK: - Int

private struct IntInputAlertModifier: ViewModifier {
    @Binding var value: Int
    let range: ClosedRange<Int>?
    let title: LocalizedStringKey

    @State private var presented = false
    @State private var draft = ""

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                draft = String(value)
                presented = true
            }
            .alert(title, isPresented: $presented) {
                TextField("", text: $draft)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                Button("action.cancel", role: .cancel) {}
                Button("action.save") { apply() }
            } message: {
                if let range {
                    Text("input.range_hint \(range.lowerBound) \(range.upperBound)")
                }
            }
    }

    private func apply() {
        guard var n = Int(draft.trimmingCharacters(in: .whitespaces)) else { return }
        if let r = range {
            n = max(r.lowerBound, min(r.upperBound, n))
        }
        value = n
    }
}

// MARK: - Double

private struct DoubleInputAlertModifier: ViewModifier {
    @Binding var value: Double
    let range: ClosedRange<Double>?
    let decimals: Int
    let title: LocalizedStringKey

    @State private var presented = false
    @State private var draft = ""

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                draft = formatted(value)
                presented = true
            }
            .alert(title, isPresented: $presented) {
                TextField("", text: $draft)
                    #if os(iOS)
                    .keyboardType(decimals > 0 ? .decimalPad : .numberPad)
                    #endif
                Button("action.cancel", role: .cancel) {}
                Button("action.save") { apply() }
            } message: {
                if let range {
                    Text("input.range_hint \(Int(range.lowerBound)) \(Int(range.upperBound))")
                }
            }
    }

    private func formatted(_ v: Double) -> String {
        if decimals == 0 {
            return String(Int(v.rounded()))
        }
        return String(format: "%.\(decimals)f", v)
    }

    private func apply() {
        let cleaned = draft.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard var n = Double(cleaned) else { return }
        if let r = range {
            n = max(r.lowerBound, min(r.upperBound, n))
        }
        value = n
    }
}
