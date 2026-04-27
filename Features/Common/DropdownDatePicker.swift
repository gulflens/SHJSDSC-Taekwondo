import SwiftUI

public struct DropdownDatePicker: View {
    @Binding var date: Date
    @Environment(\.locale) private var locale

    var minYear: Int
    var maxYear: Int

    public init(date: Binding<Date>,
                minYear: Int = 1950,
                maxYear: Int = Calendar.current.component(.year, from: Date()) + 10) {
        self._date = date
        self.minYear = minYear
        self.maxYear = maxYear
    }

    private var calendar: Calendar { Calendar.current }
    private var day: Int { calendar.component(.day, from: date) }
    private var month: Int { calendar.component(.month, from: date) }
    private var year: Int { calendar.component(.year, from: date) }

    private var daysInCurrentMonth: Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 31
    }

    private var monthSymbols: [String] {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = locale
        return cal.shortMonthSymbols
    }

    public var body: some View {
        HStack(spacing: 4) {
            Menu {
                ForEach(1...daysInCurrentMonth, id: \.self) { d in
                    Button(String(d)) { update(day: d) }
                }
            } label: {
                dropdownLabel(String(format: "%02d", day))
            }

            Menu {
                ForEach(1...12, id: \.self) { m in
                    Button(monthSymbols[m - 1]) { update(month: m) }
                }
            } label: {
                dropdownLabel(monthSymbols[month - 1])
            }

            Menu {
                ForEach(Array(stride(from: maxYear, through: minYear, by: -1)), id: \.self) { y in
                    Button(String(y)) { update(year: y) }
                }
            } label: {
                dropdownLabel(String(year))
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func dropdownLabel(_ text: String) -> some View {
        HStack(spacing: 3) {
            Text(verbatim: text)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.primary)
            Image(systemName: "chevron.down")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(.quaternarySystemFill), in: RoundedRectangle(cornerRadius: 5))
    }

    private func update(day: Int? = nil, month: Int? = nil, year: Int? = nil) {
        var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        if let year { comps.year = year }
        if let month { comps.month = month }
        let tempComps = DateComponents(year: comps.year, month: comps.month, day: 1)
        if let tempDate = calendar.date(from: tempComps),
           let maxDay = calendar.range(of: .day, in: .month, for: tempDate)?.count,
           let d = day ?? comps.day, d > maxDay {
            comps.day = maxDay
        } else if let day {
            comps.day = day
        }
        if let newDate = calendar.date(from: comps) {
            date = newDate
        }
    }
}
