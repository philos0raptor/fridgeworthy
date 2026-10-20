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

    @State private var displayedDate: Date
    @State private var currentCardIndex = 0
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
        onRequestPhoto: @escaping (Date) -> Void
    ) {
        _displayedDate = State(initialValue: initialDate)
        _pendingImages = pendingImages
        self.initialChild = initialChild
        self.onRequestPhoto = onRequestPhoto
    }

    private var activeChild: Child? {
        initialChild ?? children.first
    }

    private var dayArtworks: [Artwork] {
        allArtworks
            .filter { artwork in
                calendar.isDate(artwork.createdAt, inSameDayAs: displayedDate)
                    && (initialChild == nil || artwork.child?.id == initialChild?.id)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var isToday: Bool {
        DailyMemoryNavigation.isToday(displayedDate, calendar: calendar)
    }

    private var photoCount: Int {
        dayArtworks.count + pendingImages.count
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
                    let currentArtworks = dayArtworks
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
            refreshNote()
            persistPendingImagesIfNeeded()
        }
        .onChange(of: displayedDate) { _, _ in
            currentCardIndex = 0
            isEditingNote = false
            refreshNote()
        }
        .onChange(of: dayArtworks.map(\.id)) { _, _ in
            currentCardIndex = min(currentCardIndex, max(cardCount - 1, 0))
            if !noteFocused {
                refreshNote()
            }
        }
        .onChange(of: pendingImages.count) { _, _ in
            currentCardIndex = min(currentCardIndex, max(cardCount - 1, 0))
            persistPendingImagesIfNeeded()
        }
        .onDisappear {
            let currentArtworks = dayArtworks
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
        ZStack {
            Text(headerTitle)
                .font(FW.Font.caption(12))
                .foregroundStyle(FW.Color.onboardingInk)

            if !isToday {
                HStack {
                    Spacer()
                    Button("Today") {
                        commitCurrentNote()
                        withAnimation(.snappy(duration: 0.28)) {
                            displayedDate = Date()
                        }
                    }
                    .font(FW.Font.caption(12))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .frame(height: 44)
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
            photoDeck
                .padding(.top, 14)

            noteArea
                .padding(.top, 18)

            Spacer(minLength: 8)
        }
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
        .accessibilityLabel("Photos for \(headerTitle)")
    }

    @ViewBuilder
    private func card(at index: Int) -> some View {
        if index < dayArtworks.count {
            artworkCard(dayArtworks[index])
        } else if index < photoCount {
            imageCard(Image(uiImage: pendingImages[index - dayArtworks.count]))
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
        } else if !note.isEmpty {
            Button {
                isEditingNote = true
                noteFocused = true
            } label: {
                Text(note)
                    .font(FW.Font.body(18))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit memory message")
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

                let offset = value.translation.width < 0 ? -1 : 1
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
        note = dayArtworks.first?.title ?? ""
    }

    private func commitCurrentNote() {
        let currentArtworks = dayArtworks
        let currentNote = note
        Task {
            await viewModel.updateMemoryNote(
                currentNote,
                for: currentArtworks,
                context: modelContext
            )
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

    private var uploadIssueBinding: Binding<Bool> {
        Binding(
            get: { viewModel.uploadError != nil },
            set: { if !$0 { viewModel.uploadError = nil } }
        )
    }
}
