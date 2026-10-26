import SwiftData
import SwiftUI

struct HomeView: View {
    var addChildRequestToken: UUID?
    var onSelectDate: ((Date, Child?) -> Void)? = nil
    var onOpenHandUpArt: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query private var profiles: [UserProfile]

    @State private var visibleMonth = Date()
    @State private var selectedChild: Child?
    @State private var showMonthPicker = false
    @State private var showAddChild = false
    @State private var newChildName = ""

    private let calendar = Calendar.current

    private var userProfile: UserProfile? { profiles.first }
    private var orderedChildIDs: [UUID] { children.map(\.id) }

    private var displayedArtworks: [Artwork] {
        if let selectedChild {
            return selectedChild.artworks
        }
        return children.flatMap(\.artworks)
    }

    private var artworksByDay: [Date: [Artwork]] {
        Dictionary(grouping: displayedArtworks) { artwork in
            MonthCalendar.dayKey(for: artwork.createdAt, calendar: calendar)
        }
    }

    private var monthDays: [MonthDay?] {
        MonthCalendar.days(for: visibleMonth, calendar: calendar)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                FWPaperBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        monthHeader
                            .padding(.horizontal, 28)

                        childFilterRail
                            .padding(.top, 10)

                        calendarGrid
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        if children.isEmpty {
                            firstChildPrompt
                                .padding(.top, 18)
                        }

                        Color.clear.frame(height: 16)
                    }
                    .padding(.top, HomeTopLayout.monthTop(safeAreaTop: geometry.safeAreaInsets.top))
                }
                .scrollBounceBehavior(.basedOnSize)

                FWHandwrittenStatusBar(inkColor: FW.Color.onboardingInk, verticalOffset: 0)
                    .padding(.horizontal, 24)
                    .frame(height: geometry.safeAreaInsets.top)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .statusBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Add a Child", isPresented: $showAddChild) {
            TextField("Child's name", text: $newChildName)
            Button("Add") { addChild() }
            Button("Cancel", role: .cancel) { newChildName = "" }
        } message: {
            Text("Who is making the next fridge-worthy masterpiece?")
        }
        .sheet(isPresented: $showMonthPicker) {
            FWMonthPicker(selection: $visibleMonth, calendar: calendar)
        }
        .onChange(of: addChildRequestToken) { _, newValue in
            if newValue != nil {
                showAddChild = true
            }
        }
        .onAppear {
            if userProfile == nil {
                ensureProfile()
            }
        }
    }

    private var monthHeader: some View {
        ZStack {
            Button {
                showMonthPicker = true
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(visibleMonth.formatted(.dateTime.month(.wide)))
                        .font(FW.Font.heroDisplay(34, weight: .regular))
                        .tracking(-1.1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FW.Color.onboardingInk)
                }
                .foregroundStyle(FW.Color.onboardingInk)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Choose a different month and year")

            HStack(spacing: 8) {
                Spacer()
                if !MonthCalendar.isCurrentMonth(visibleMonth, calendar: calendar) {
                    Button("Today") {
                        withAnimation(.snappy(duration: 0.3)) {
                            visibleMonth = Date()
                        }
                    }
                    .font(FW.Font.caption(12, weight: .bold))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(.white.opacity(0.74))
                    .clipShape(Capsule())
                }

                Button {
                    onOpenHandUpArt?()
                } label: {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(FW.Color.onboardingInk)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.74))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Hand up art")
            }
        }
        .frame(minHeight: 44)
    }

    private var childFilterRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FWAllChip(isActive: selectedChild == nil) {
                    selectedChild = nil
                }

                ForEach(children) { child in
                    FWChildChip(
                        emoji: child.avatarEmoji,
                        name: child.name,
                        colorTint: FW.Color.childColor(
                            id: child.id,
                            orderedChildIDs: orderedChildIDs,
                            customIndex: child.colorIndex
                        ),
                        isActive: selectedChild?.id == child.id
                    ) {
                        selectedChild = child
                    }
                }

                Button {
                    showAddChild = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(FW.Color.onboardingInk)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.78))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a child")
            }
            .padding(.horizontal, 28)
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(FW.Font.caption(11, weight: .bold))
                        .foregroundStyle(FW.Color.onboardingInk.opacity(0.72))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: calendarRowSpacing) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(monthSwipeGesture)
        .animation(.easeInOut(duration: 0.24), value: visibleMonth)
    }

    private func dayCell(_ day: MonthDay) -> some View {
        let colors = markerColors(for: day.date)
        let key = MonthCalendar.dayKey(for: day.date, calendar: calendar)
        let artworkCount = (artworksByDay[key] ?? []).count
        return Button {
            onSelectDate?(day.date, selectedChild)
        } label: {
            VStack(spacing: 1) {
                FWHandwrittenGlyphSequence(
                    text: String(day.number),
                    height: 29,
                    inkColor: day.isToday ? FW.Color.today : FW.Color.onboardingInk
                )
                    .frame(width: 38, height: 34)

                FWEntryDots(colors: colors)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .disabled(day.date > Date())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(dayAccessibilityLabel(day, artworkCount: artworkCount))
    }

    private var firstChildPrompt: some View {
        Button {
            showAddChild = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                Text("Add your first little artist")
                    .font(FW.Font.body(14, weight: .bold))
            }
            .foregroundStyle(FW.Color.onboardingInk)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(.white.opacity(0.74))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    }

    private var calendarRowSpacing: CGFloat {
        MonthGridLayout.rowSpacing(
            rowCount: monthDays.count / 7,
            targetHeight: 430,
            cellHeight: 44
        )
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[offset...] + symbols[..<offset])
    }

    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 48 else {
                    return
                }
                let monthOffset = value.translation.width < 0 ? 1 : -1
                withAnimation(.snappy(duration: 0.3)) {
                    visibleMonth = MonthCalendar.clampedOffset(visibleMonth, by: monthOffset, calendar: calendar)
                }
            }
    }

    private func markerColors(for date: Date) -> [Color] {
        let key = MonthCalendar.dayKey(for: date, calendar: calendar)
        let childIDsWithEntries = Set((artworksByDay[key] ?? []).compactMap { $0.child?.id })
        let orderedChildIDs = children.map(\.id)
        return children.compactMap { child in
            guard childIDsWithEntries.contains(child.id) else { return nil }
            return FW.Color.childColor(
                id: child.id,
                orderedChildIDs: orderedChildIDs,
                customIndex: child.colorIndex
            )
        }
    }

    private func dayAccessibilityLabel(_ day: MonthDay, artworkCount: Int) -> String {
        let date = day.date.formatted(.dateTime.month(.wide).day())
        guard artworkCount > 0 else { return date }
        return "\(date), \(artworkCount) saved \(artworkCount == 1 ? "memory" : "memories")"
    }

    private func ensureProfile() {
        guard profiles.isEmpty else { return }
        let profile = UserProfile(supabaseID: authService.currentUserID?.uuidString ?? UUID().uuidString)
        modelContext.insert(profile)
    }

    private func addChild() {
        let trimmed = newChildName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let child = Child(name: trimmed)
        modelContext.insert(child)
        newChildName = ""

        guard let profileID = authService.currentUserID else { return }
        Task {
            _ = try? await SupabaseService.shared.insertChild(
                id: child.id,
                name: trimmed,
                profileID: profileID
            )
        }
    }
}
