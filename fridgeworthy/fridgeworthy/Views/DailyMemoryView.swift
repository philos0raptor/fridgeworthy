import SwiftData
import SwiftUI
import UIKit

struct DailyMemoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Artwork.createdAt) private var allArtworks: [Artwork]
    @Query(sort: \Child.createdAt) private var children: [Child]

    @Binding var pendingImages: [UIImage]
    let initialChild: Child?
    let onRequestPhoto: (Date) -> Void
    let onDisplayedDateChanged: (Date) -> Void
    let onNoteFocusChanged: (Bool) -> Void

    @State private var displayedDate: Date
    @State private var currentCardIndex = 0
    @State private var selectedEntryChildID: UUID?
    @State private var note = ""
    @State private var isEditingNote = false
    @State private var isPersisting = false
    @State private var viewModel = CaptureViewModel()
    @FocusState private var noteFocused: Bool

    private let calendar = Calendar.current

    init(
        initialDate: Date,
        initialChild: Child?,
        pendingImages: Binding<[UIImage]>,
        onRequestPhoto: @escaping (Date) -> Void,
        onDisplayedDateChanged: @escaping (Date) -> Void,
        onNoteFocusChanged: @escaping (Bool) -> Void
    ) {
        _displayedDate = State(initialValue: initialDate)
        _pendingImages = pendingImages
        self.initialChild = initialChild
        self.onRequestPhoto = onRequestPhoto
        self.onDisplayedDateChanged = onDisplayedDateChanged
        self.onNoteFocusChanged = onNoteFocusChanged
    }

    private var activeChild: Child? {
        initialChild ?? children.first
    }

    private var artworksForDisplayedDate: [Artwork] {
        allArtworks
            .filter { calendar.isDate($0.createdAt, inSameDayAs: displayedDate) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var orderedChildIDs: [UUID] { children.map(\.id) }

    private var childrenWithArtworkOnDisplayedDate: [Child] {
        var childIDs = Set(artworksForDisplayedDate.compactMap { $0.child?.id })
        if !pendingImages.isEmpty, let pendingChild = activeChild {
            childIDs.insert(pendingChild.id)
        }
        return children.filter { childIDs.contains($0.id) }
    }

    private var selectedEntryChild: Child? {
        childrenWithArtworkOnDisplayedDate.first { $0.id == selectedEntryChildID }
            ?? childrenWithArtworkOnDisplayedDate.first
    }

    private var selectedChildArtworks: [Artwork] {
        guard let selectedEntryChild else {
            return artworksForDisplayedDate.filter { $0.child == nil }
        }
        return artworksForDisplayedDate.filter { $0.child?.id == selectedEntryChild.id }
    }

    private var selectedPendingImages: [UIImage] {
        guard let selectedEntryChild,
              selectedEntryChild.id == activeChild?.id else {
            return []
        }
        return pendingImages
    }

    private var dayArtworks: [Artwork] { selectedChildArtworks }

    private var showsChildSelector: Bool {
        childrenWithArtworkOnDisplayedDate.count > 0
    }

    private var datesWithEntries: Set<Date> {
        Set(allArtworks.compactMap { artwork in
            guard initialChild == nil || artwork.child?.id == initialChild?.id else {
                return nil
            }
            return calendar.startOfDay(for: artwork.createdAt)
        })
    }

    private var isToday: Bool {
        DailyMemoryNavigation.isToday(displayedDate, calendar: calendar)
    }

    private var dateRailDates: [Date] {
        DailyMemoryNavigation.dateRailDates(calendar: calendar)
    }

    private var showsTodayShortcut: Bool {
        DailyMemoryNavigation.showsTodayShortcut(
            for: displayedDate,
            calendar: calendar
        )
    }

    private var photoCount: Int {
        selectedChildArtworks.count + selectedPendingImages.count
    }

    private var cardCount: Int {
        photoCount + (isToday && photoCount > 0 ? 1 : 0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                FWPaperBackground()
                    .contentShape(Rectangle())
                    .gesture(daySwipeGesture)

                VStack(spacing: 0) {
                    header

                    if photoCount == 0 {
                        emptyState
                    } else {
                        filledState
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, geometry.safeAreaInsets.top + 4)

                FWHandwrittenStatusBar(inkColor: FW.Color.onboardingInk, verticalOffset: 0)
                    .padding(.horizontal, 24)
                    .frame(height: geometry.safeAreaInsets.top)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .statusBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    let currentArtworks = artworksForDisplayedDate
                    let currentNote = note
                    noteFocused = false
                    isEditingNote = false
                    Task {
                        await viewModel.updateMemoryNote(
                            currentNote,
                            for: currentArtworks,
                            context: modelContext
                        )
                    }
                }
            }
        }
        .onAppear {
            reconcileSelectedEntryChild()
            refreshNote()
            persistPendingImagesIfNeeded()
        }
        .onChange(of: displayedDate) { _, newDate in
            currentCardIndex = 0
            isEditingNote = false
            reconcileSelectedEntryChild()
            refreshNote()
            onDisplayedDateChanged(newDate)
        }
        .onChange(of: artworksForDisplayedDate.map(\.id)) { _, _ in
            reconcileSelectedEntryChild()
            currentCardIndex = min(currentCardIndex, max(cardCount - 1, 0))
            if !noteFocused {
                refreshNote()
            }
        }
        .onChange(of: pendingImages.count) { _, _ in
            reconcileSelectedEntryChild()
            currentCardIndex = min(currentCardIndex, max(cardCount - 1, 0))
            persistPendingImagesIfNeeded()
        }
        .onChange(of: selectedEntryChildID) { _, _ in
            currentCardIndex = 0
        }
        .onChange(of: noteFocused) { _, isFocused in
            onNoteFocusChanged(isFocused)
        }
        .onDisappear {
            onNoteFocusChanged(false)
            let currentArtworks = artworksForDisplayedDate
            let currentNote = note
            Task {
                await viewModel.updateMemoryNote(
                    currentNote,
                    for: currentArtworks,
                    context: modelContext
                )
            }
        }
        .alert("Upload issue", isPresented: uploadIssueBinding) {
            Button("OK", role: .cancel) { viewModel.uploadError = nil }
        } message: {
            Text(viewModel.uploadError ?? "The memory is saved on this phone and can upload later.")
        }
    }

    private var header: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 3) {
                Text(headerTitle)
                    .font(FW.Font.caption(12))
                    .foregroundStyle(FW.Color.onboardingInk)

                dateRail
            }

            if showsTodayShortcut {
                HStack {
                    Spacer()
                    Button("Today") {
                        selectDate(Date())
                    }
                    .font(FW.Font.caption(12))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .frame(height: 66)
    }

    private var dateRail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(dateRailDates, id: \.self) { date in
                        dateRailButton(for: date)
                            .id(calendar.startOfDay(for: date))
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 62)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .frame(width: 184, height: 28)
            .onAppear {
                proxy.scrollTo(
                    calendar.startOfDay(for: displayedDate),
                    anchor: .center
                )
            }
            .onChange(of: displayedDate) { _, newDate in
                withAnimation(.snappy(duration: 0.24)) {
                    proxy.scrollTo(
                        calendar.startOfDay(for: newDate),
                        anchor: .center
                    )
                }
            }
        }
    }

    private func dateRailButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: displayedDate)
        let hasEntry = DailyMemoryNavigation.hasEntry(
            on: date,
            in: datesWithEntries,
            calendar: calendar
        )

        return Button {
            selectDate(date)
        } label: {
            VStack(spacing: 3) {
                Text(String(calendar.component(.day, from: date)))
                    .font(FW.Font.caption(10))
                    .foregroundStyle(
                        FW.Color.onboardingInk.opacity(isSelected ? 1 : 0.34)
                    )

                if isSelected {
                    Capsule()
                        .fill(FW.Color.onboardingInk)
                        .frame(width: 12, height: 1)
                        .rotationEffect(.degrees(-3))
                }

                if hasEntry {
                    Circle()
                        .fill(FW.Color.onboardingInk.opacity(0.38))
                        .frame(width: 3, height: 3)
                } else {
                    Color.clear
                        .frame(width: 3, height: 3)
                }
            }
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            date.formatted(.dateTime.month(.wide).day().year())
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Button {
                onRequestPhoto(displayedDate)
            } label: {
                VStack(spacing: 12) {
                    Image("FWNavCapture")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)

                    Text("There’s still room for this day")
                        .font(FW.Font.caption(14))
                        .foregroundStyle(FW.Color.onboardingInk.opacity(0.62))
                }
                .padding(28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a memory for \(headerTitle)")

            Spacer()
        }
    }

    private var filledState: some View {
        VStack(spacing: 0) {
            if showsChildSelector {
                childSelector
                    .padding(.top, 10)
            }

            photoDeck
                .padding(.top, 14)

            noteArea
                .padding(.top, 18)

            Spacer(minLength: 8)
        }
    }

    private var childSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(childrenWithArtworkOnDisplayedDate) { child in
                    let isSelected = selectedEntryChild?.id == child.id
                    let color = FW.Color.childColor(
                        id: child.id,
                        orderedChildIDs: orderedChildIDs,
                        customIndex: child.colorIndex
                    )

                    Button {
                        withAnimation(.snappy(duration: 0.24)) {
                            selectedEntryChildID = child.id
                            currentCardIndex = 0
                        }
                    } label: {
                        Text(child.name)
                            .font(FW.Font.caption(12))
                            .foregroundStyle(FW.Color.onboardingInk)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(color.opacity(isSelected ? 0.78 : 0.48))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        isSelected
                                            ? FW.Color.onboardingInk.opacity(0.58)
                                            : Color.white.opacity(0.72),
                                        lineWidth: isSelected ? 1.25 : 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(child.name)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
        .frame(height: 34)
        .accessibilityLabel("Children with artwork on this day")
    }

    private var photoDeck: some View {
        ZStack {
            ForEach(0..<cardCount, id: \.self) { index in
                card(at: index)
                    .offset(x: cardOffset(for: index))
                    .scaleEffect(cardScale(for: index), anchor: .trailing)
                    .opacity(cardOpacity(for: index))
                    .zIndex(cardZIndex(for: index))
                    .allowsHitTesting(index == currentCardIndex)
            }
        }
        .frame(width: 292, height: 314)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .gesture(photoSwipeGesture)
        .animation(.snappy(duration: 0.24), value: currentCardIndex)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            selectedEntryChild.map { "Photos for \($0.name) on \(headerTitle)" }
                ?? "Photos for \(headerTitle)"
        )
    }

    @ViewBuilder
    private func card(at index: Int) -> some View {
        if index < dayArtworks.count {
            artworkCard(dayArtworks[index])
        } else if index < photoCount {
            imageCard(Image(uiImage: selectedPendingImages[index - dayArtworks.count]))
                .accessibilityLabel("New photo \(index - dayArtworks.count + 1)")
        } else {
            Button {
                onRequestPhoto(displayedDate)
            } label: {
                ZStack {
                    FW.Color.lavender
                    Image("FWNavCapture")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                }
                .frame(width: 292, height: 314)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .modifier(FW.Shadow.cardMedium())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add another photo")
        }
    }

    @ViewBuilder
    private func artworkCard(_ artwork: Artwork) -> some View {
        if let localImage = localImage(for: artwork) {
            imageCard(Image(uiImage: localImage))
                .accessibilityLabel("Saved artwork photo")
        } else if let remoteImageURL = artwork.remoteImageURL,
                  let url = URL(string: remoteImageURL) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    imageCard(image)
                } else if phase.error != nil {
                    unavailablePhoto
                } else {
                    ProgressView()
                        .tint(FW.Color.onboardingInk)
                        .frame(width: 292, height: 314)
                        .background(FW.Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .accessibilityLabel("Saved artwork photo")
        } else {
            unavailablePhoto
        }
    }

    private func imageCard(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: 292, height: 314)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .modifier(FW.Shadow.cardMedium())
    }

    private var unavailablePhoto: some View {
        Image(systemName: "photo")
            .font(.system(size: 36, weight: .light))
            .foregroundStyle(FW.Color.onboardingInk.opacity(0.34))
            .frame(width: 292, height: 314)
            .background(FW.Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var noteArea: some View {
        if shouldShowEditor {
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("What do you want to remember?")
                        .font(FW.Font.body(17))
                        .foregroundStyle(FW.Color.onboardingInk.opacity(0.48))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $note)
                    .font(FW.Font.body(17))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .scrollContentBackground(.hidden)
                    .focused($noteFocused)
                    .frame(minHeight: 82, maxHeight: 132)
            }
        } else if photoCount > 0 {
            Button {
                isEditingNote = true
                noteFocused = true
            } label: {
                Text(note.isEmpty ? "What do you want to remember?" : note)
                    .font(FW.Font.body(18))
                    .foregroundStyle(FW.Color.onboardingInk.opacity(note.isEmpty ? 0.48 : 1))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(note.isEmpty ? "Add memory message" : "Edit memory message")
        }
    }

    private var shouldShowEditor: Bool {
        isEditingNote || (isToday && photoCount > 0)
    }

    private var headerTitle: String {
        guard !isToday else { return "Today" }
        let components = calendar.dateComponents([.month, .day], from: displayedDate)
        return String(format: "%02d.%02d", components.month ?? 0, components.day ?? 0)
    }

    private func forwardDistance(to index: Int) -> Int {
        guard cardCount > 0 else { return 0 }
        return (index - currentCardIndex + cardCount) % cardCount
    }

    private func cardOffset(for index: Int) -> CGFloat {
        CGFloat(min(forwardDistance(to: index), 2)) * 16
    }

    private func cardScale(for index: Int) -> CGFloat {
        1 - CGFloat(min(forwardDistance(to: index), 2)) * 0.035
    }

    private func cardOpacity(for index: Int) -> Double {
        forwardDistance(to: index) > 2 ? 0 : 1
    }

    private func cardZIndex(for index: Int) -> Double {
        Double(cardCount - forwardDistance(to: index))
    }

    private var photoSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 22)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 36 else {
                    return
                }
                let delta = value.translation.width < 0 ? 1 : -1
                currentCardIndex = DailyMemoryNavigation.wrappedIndex(
                    currentCardIndex,
                    delta: delta,
                    count: cardCount
                )
            }
    }

    private var daySwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 48 else {
                    return
                }

                let offset = DailyMemoryNavigation.dayOffsetForSwipe(
                    translationWidth: value.translation.width
                )
                let nextDate = DailyMemoryNavigation.clampedTowardToday(
                    displayedDate,
                    by: offset,
                    calendar: calendar
                )
                guard !calendar.isDate(nextDate, inSameDayAs: displayedDate) else { return }

                commitCurrentNote()
                withAnimation(.snappy(duration: 0.28)) {
                    displayedDate = nextDate
                }
            }
    }

    private func localImage(for artwork: Artwork) -> UIImage? {
        guard !artwork.localImagePath.isEmpty else { return nil }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(artwork.localImagePath)
        return UIImage(contentsOfFile: fileURL.path)
    }

    private func refreshNote() {
        note = artworksForDisplayedDate.first?.title ?? ""
    }

    private func commitCurrentNote() {
        let currentArtworks = artworksForDisplayedDate
        let currentNote = note
        Task {
            await viewModel.updateMemoryNote(
                currentNote,
                for: currentArtworks,
                context: modelContext
            )
        }
    }

    private func selectDate(_ date: Date) {
        guard !calendar.isDate(date, inSameDayAs: displayedDate) else { return }
        commitCurrentNote()
        withAnimation(.snappy(duration: 0.28)) {
            displayedDate = date
        }
    }

    private func persistPendingImagesIfNeeded() {
        guard !isPersisting, !pendingImages.isEmpty, let activeChild else { return }
        isPersisting = true
        let targetDate = displayedDate

        Task {
            while !pendingImages.isEmpty {
                let image = pendingImages[0]
                let saved = await viewModel.saveMemoryImage(
                    image,
                    note: note,
                    date: targetDate,
                    child: activeChild,
                    context: modelContext
                )
                guard saved else { break }
                pendingImages.removeFirst()
            }
            isPersisting = false
        }
    }

    private func reconcileSelectedEntryChild() {
        let availableChildren = childrenWithArtworkOnDisplayedDate
        guard !availableChildren.isEmpty else {
            selectedEntryChildID = nil
            return
        }

        if let selectedEntryChildID,
           availableChildren.contains(where: { $0.id == selectedEntryChildID }) {
            return
        }

        if let initialChild,
           availableChildren.contains(where: { $0.id == initialChild.id }) {
            selectedEntryChildID = initialChild.id
        } else {
            selectedEntryChildID = availableChildren.first?.id
        }
    }

    private var uploadIssueBinding: Binding<Bool> {
        Binding(
            get: { viewModel.uploadError != nil },
            set: { if !$0 { viewModel.uploadError = nil } }
        )
    }
}
