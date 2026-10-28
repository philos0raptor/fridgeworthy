import SwiftData
import SwiftUI
import UIKit
import reactnativeartworkbrownfield

struct DailyMemoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Artwork.createdAt) private var allArtworks: [Artwork]
    @Query(sort: \Child.createdAt) private var children: [Child]

    @Binding var pendingImages: [PendingArtworkPhoto]
    let initialChild: Child?
    let onRequestPhoto: (Date) -> Void
    let onDisplayedDateChanged: (Date) -> Void
    let onNoteFocusChanged: (Bool) -> Void

    @State private var displayedDate: Date
    @State private var railDatePosition: Date?
    @State private var pendingCarouselFiles: [URL] = []
    @State private var carouselListenerID: String?
    @State private var selectedEntryChildID: UUID?
    @State private var note = ""
    @State private var isEditingNote = false
    @State private var isPersisting = false
    @State private var viewModel = CaptureViewModel()
    @AppStorage("memoryFont") private var memoryFont = "rounded"

    private let calendar = Calendar.current

    init(
        initialDate: Date,
        initialChild: Child?,
        pendingImages: Binding<[PendingArtworkPhoto]>,
        onRequestPhoto: @escaping (Date) -> Void,
        onDisplayedDateChanged: @escaping (Date) -> Void,
        onNoteFocusChanged: @escaping (Bool) -> Void
    ) {
        _displayedDate = State(initialValue: initialDate)
        _railDatePosition = State(initialValue: Calendar.current.startOfDay(for: initialDate))
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

    private var selectedPendingImages: [PendingArtworkPhoto] {
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
                        filledState(availableHeight: geometry.size.height)
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
        .onAppear {
            reconcileSelectedEntryChild()
            refreshNote()
            syncPendingCarouselFiles()
            registerCarouselListener()
            persistPendingImagesIfNeeded()
        }
        .onChange(of: displayedDate) { _, newDate in
            railDatePosition = calendar.startOfDay(for: newDate)
            isEditingNote = false
            reconcileSelectedEntryChild()
            refreshNote()
            registerCarouselListener()
            onDisplayedDateChanged(newDate)
        }
        .onChange(of: artworksForDisplayedDate.map(\.id)) { _, _ in
            reconcileSelectedEntryChild()
            if !isEditingNote {
                refreshNote()
            }
        }
        .onChange(of: pendingImages.count) { _, _ in
            reconcileSelectedEntryChild()
            syncPendingCarouselFiles()
            persistPendingImagesIfNeeded()
        }
        .onChange(of: isComposingNote) { _, isComposing in
            onNoteFocusChanged(isComposing)
        }
        .onDisappear {
            onNoteFocusChanged(false)
            removeCarouselListener()
            removePendingCarouselFiles()
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
        .scrollPosition(id: $railDatePosition, anchor: .center)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .frame(width: 184, height: 28)
        .onChange(of: railDatePosition) { _, newDate in
            guard newDate != nil else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
        }
        .onScrollPhaseChange { _, newPhase in
            guard newPhase == .idle,
                  let settledDate = railDatePosition,
                  !calendar.isDate(settledDate, inSameDayAs: displayedDate) else {
                return
            }
            selectDate(settledDate)
        }
    }

    private func dateRailButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: railDatePosition ?? displayedDate)
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

    private func filledState(availableHeight: CGFloat) -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("memoryTop")

                    if showsChildSelector {
                        childSelector
                            .padding(.top, 10)
                    }

                    artworkCarousel
                        .padding(.top, 14)

                    ArtworkNoteHostView(
                        initialNote: artworksForDisplayedDate.first?.title ?? "",
                        sessionID: noteSessionID,
                        fontStyle: memoryFont
                    )
                        .id("\(noteSessionID)-\(memoryFont)")
                        .frame(maxWidth: .infinity)
                        .frame(height: isComposingNote ? 148 : 110)
                        .padding(.top, 18)
                        .id("memoryNote")
                        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: isComposingNote)
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.never)
            .onChange(of: isComposingNote) { _, isComposing in
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    scrollProxy.scrollTo(
                        isComposing ? "memoryNote" : "memoryTop",
                        anchor: isComposing ? .bottom : .top
                    )
                }
            }
            .onChange(of: availableHeight) { _, _ in
                guard isComposingNote else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    scrollProxy.scrollTo("memoryNote", anchor: .bottom)
                }
            }
        }
    }

    private var isComposingNote: Bool { isEditingNote }
    private var cardHeight: CGFloat { isComposingNote ? 210 : 314 }

    private var noteSessionID: String {
        String(calendar.startOfDay(for: displayedDate).timeIntervalSince1970)
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

                    FWAnimatedSelectionChip(
                        name: child.name,
                        colorTint: color,
                        isActive: isSelected,
                        onTap: { selectedEntryChildID = child.id },
                        font: FW.Font.caption(12),
                        verticalPadding: 7,
                        activeBorderColor: FW.Color.onboardingInk.opacity(0.58)
                    )
                }
            }
            .modifier(FWSelectionLayoutAnimation(selection: selectedEntryChild?.id))
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
        .frame(height: 34)
        .accessibilityLabel("Children with artwork on this day")
    }

    private var artworkCarousel: some View {
        ArtworkCarouselHostView(
            images: carouselImages,
            allowsAddingPhoto: isToday
        )
        .id(carouselIdentity)
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: isComposingNote)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            selectedEntryChild.map { "Photos for \($0.name) on \(headerTitle)" }
                ?? "Photos for \(headerTitle)"
        )
    }

    private var carouselImages: [[String: String]] {
        let saved = dayArtworks.map { artwork in
            ["id": artwork.id.uuidString, "uri": imageURL(for: artwork)]
        }
        let pending = selectedPendingImages.indices.compactMap { index -> [String: String]? in
            guard pendingCarouselFiles.indices.contains(index) else { return nil }
            return [
                "id": "pending-\(index)",
                "uri": pendingCarouselFiles[index].absoluteString,
            ]
        }
        return saved + pending
    }

    private var carouselIdentity: String {
        let imageIDs = carouselImages.map { "\($0["id"] ?? ""): \($0["uri"] ?? "")" }
        return "\(calendar.startOfDay(for: displayedDate).timeIntervalSince1970)-\(selectedEntryChildID?.uuidString ?? "none")-\(imageIDs.joined(separator: "|"))"
    }

    private var headerTitle: String {
        let headerDate = railDatePosition ?? displayedDate
        guard !DailyMemoryNavigation.isToday(headerDate, calendar: calendar) else { return "Today" }
        let components = calendar.dateComponents([.month, .day], from: headerDate)
        return String(format: "%02d.%02d", components.month ?? 0, components.day ?? 0)
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

    private func imageURL(for artwork: Artwork) -> String {
        guard !artwork.localImagePath.isEmpty else {
            return artwork.remoteImageURL ?? ""
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(artwork.localImagePath)
        return FileManager.default.fileExists(atPath: fileURL.path)
            ? fileURL.absoluteString
            : (artwork.remoteImageURL ?? "")
    }

    private func syncPendingCarouselFiles() {
        removePendingCarouselFiles()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("artwork-carousel", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        pendingCarouselFiles = pendingImages.compactMap { photo in
            let fileURL = directory.appendingPathComponent("\(UUID().uuidString).jpg")
            guard let data = photo.preparedImage.jpegData(compressionQuality: 0.85),
                  (try? data.write(to: fileURL, options: .atomic)) != nil else {
                return nil
            }
            return fileURL
        }
    }

    private func removePendingCarouselFiles() {
        pendingCarouselFiles.forEach { try? FileManager.default.removeItem(at: $0) }
        pendingCarouselFiles = []
    }

    private func registerCarouselListener() {
        removeCarouselListener()
        let date = displayedDate
        let sessionID = noteSessionID
        carouselListenerID = BrownfieldMessaging.addListener { message in
            guard let type = message["type"] as? String else { return }
            Task { @MainActor in
                switch type {
                case "artworkCarousel:addPhoto":
                    onRequestPhoto(date)
                case "artworkNote:focus":
                    guard message["sessionID"] as? String == sessionID else { return }
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        isEditingNote = true
                    }
                case "artworkNote:change":
                    guard message["sessionID"] as? String == sessionID,
                          let text = message["text"] as? String else { return }
                    note = text
                case "artworkNote:blur":
                    guard message["sessionID"] as? String == sessionID,
                          let text = message["text"] as? String else { return }
                    note = text
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        isEditingNote = false
                    }
                    commitCurrentNote()
                default:
                    break
                }
            }
        }
    }

    private func removeCarouselListener() {
        guard let carouselListenerID else { return }
        BrownfieldMessaging.removeListener(id: carouselListenerID)
        self.carouselListenerID = nil
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
                let photo = pendingImages[0]
                let saved = await viewModel.saveMemoryImage(
                    photo,
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
