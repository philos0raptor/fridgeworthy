import SwiftUI

struct FWMonthPicker: View {
    @Binding var selection: Date
    let calendar: Calendar

    @State private var selectedYear: Int

    private static let monthSymbols = DateFormatter().monthSymbols ?? []

    init(selection: Binding<Date>, calendar: Calendar) {
        _selection = selection
        self.calendar = calendar
        _selectedYear = State(initialValue: calendar.component(.year, from: selection.wrappedValue))
    }

    var body: some View {
        NavigationStack {
            FWPaperBackground(topTint: FW.Color.lavender.opacity(0.72))
                .overlay {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            Text("Choose a month")
                                .font(FW.Font.body(17, weight: .semibold))
                                .foregroundStyle(FW.Color.onboardingInk)

                            yearPicker
                            monthGrid
                        }
                        .padding(24)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
        }
        .tint(FW.Color.onboardingInk)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var yearPicker: some View {
        Menu {
            ForEach(yearRange, id: \.self) { year in
                Button {
                    selectedYear = year
                } label: {
                    if year == selectedYear {
                        Label(String(year), systemImage: "checkmark")
                    } else {
                        Text(String(year))
                    }
                }
            }
        } label: {
            HStack(spacing: 7) {
                Text(String(selectedYear))
                    .font(FW.Font.sectionTitle(20))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(FW.Color.onboardingInk)
            .padding(.horizontal, 18)
            .frame(height: 50)
            .background(.white.opacity(0.76))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Year")
        .accessibilityValue(String(selectedYear))
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
            ForEach(selectableMonthNumbers, id: \.self) { monthNumber in
                Button {
                    choose(month: monthNumber)
                } label: {
                    let month = Self.monthSymbols[monthNumber - 1]
                    Text(month)
                        .font(FW.Font.body(15, weight: isSelected(month: monthNumber) ? .bold : .semibold))
                        .foregroundStyle(isSelected(month: monthNumber) ? .white : FW.Color.onboardingInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isSelected(month: monthNumber) ? FW.Color.onboardingInk : .white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var yearRange: ClosedRange<Int> {
        let current = calendar.component(.year, from: Date())
        return MonthCalendar.selectableYears(currentYear: current)
    }

    private var selectableMonthNumbers: [Int] {
        MonthCalendar.selectableMonths(year: selectedYear, calendar: calendar)
    }

    private func isSelected(month: Int) -> Bool {
        calendar.component(.year, from: selection) == selectedYear
            && calendar.component(.month, from: selection) == month
    }

    private func choose(month: Int) {
        guard let date = calendar.date(from: DateComponents(year: selectedYear, month: month, day: 1)) else {
            return
        }
        selection = date
    }
}
