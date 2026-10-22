import SwiftUI
import SwiftData
import StoreKit
import UserNotifications

struct MeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Environment(\.requestReview) private var requestReview
    @Query private var profiles: [UserProfile]
    @Query(sort: \Child.createdAt) private var children: [Child]

    @AppStorage("fridgeTheme") private var fridgeTheme = "system"
    @AppStorage("memoryFont") private var memoryFont = "rounded"
    @AppStorage("memoryNotificationsEnabled") private var notificationsEnabled = false
    @AppStorage("memoryReminderTime") private var reminderTimeInterval = Date.now.timeIntervalSince1970

    @State private var showAddChild = false
    @State private var newChildName = ""
    @State private var childToEdit: Child?
    @State private var showEditChild = false
    @State private var showDeleteChild = false
    @State private var showHelpMessage = false

    private var orderedChildIDs: [UUID] { children.map(\.id) }
    private var reminderTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: reminderTimeInterval) },
            set: { reminderTimeInterval = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                settingsSection("Kids") {
                    VStack(spacing: 0) {
                        ForEach(children) { child in
                            childRow(child)
                            if child.id != children.last?.id { rowDivider }
                        }

                        if !children.isEmpty { rowDivider }
                        Button {
                            newChildName = ""
                            showAddChild = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(FW.Font.body(14, weight: .medium))
                                Text("Add a child")
                                    .font(FW.Font.body(15, weight: .medium))
                                Spacer()
                            }
                            .foregroundStyle(FW.Color.onboardingInk)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                settingsSection("Appearance") {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            settingsLabel("Fridge Theme", detail: "Choose light or dark")
                            Spacer(minLength: 4)
                            Menu {
                                themeMenuOption("System", asset: "FWThemeSystem", value: "system")
                                themeMenuOption("Light", asset: "FWThemeLight", value: "light")
                                themeMenuOption("Dark", asset: "FWThemeDark", value: "dark")
                            } label: {
                                themeIcon(selectedThemeAsset, selected: true)
                            }
                            .accessibilityLabel("Fridge Theme")
                            .accessibilityValue(selectedThemeName)
                        }
                        .padding(.vertical, 12)

                        rowDivider

                        HStack {
                            settingsLabel("Memory Font", detail: "Choose your memory style")
                            Spacer(minLength: 12)
                            Menu {
                                fontMenuOption("Rounded", value: "rounded")
                                fontMenuOption("Serif", value: "serif")
                                fontMenuOption("Handwritten", value: "handwritten")
                            } label: {
                                Text(selectedMemoryFontLabel)
                                    .font(memoryFontPreview(memoryFont))
                                    .foregroundStyle(FW.Color.onboardingInk)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(FW.Color.iris.opacity(0.25), in: Capsule())
                            }
                            .accessibilityLabel("Memory Font")
                            .accessibilityValue(selectedMemoryFontLabel)
                        }
                        .padding(.vertical, 12)
                    }
                }

                settingsSection("App settings") {
                    VStack(spacing: 0) {
                        Toggle(isOn: notificationBinding) {
                            settingsLabel("Notifications", detail: "A gentle nudge to save a memory")
                        }
                        .tint(FW.Color.onboardingInk)
                        .padding(.vertical, 12)

                        rowDivider

                        HStack {
                            settingsLabel("Reminder time", detail: "Choose when to be reminded")
                            Spacer(minLength: 12)
                            DatePicker("Reminder time", selection: reminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(FW.Color.onboardingInk)
                        }
                        .padding(.vertical, 8)

                        rowDivider

                        Button {
                            requestReview()
                        } label: {
                            actionRow("Review", detail: "Leave a review on the App Store", symbol: "heart")
                        }
                        .buttonStyle(.plain)

                        rowDivider

                        Button {
                            showHelpMessage = true
                        } label: {
                            actionRow("Help", detail: "Get help with Fridgeworthy", symbol: "questionmark.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(role: .destructive) {
                    Task { await authService.signOut() }
                } label: {
                    Text("Sign Out")
                        .font(FW.Font.body(14, weight: .medium))
                        .foregroundStyle(FW.Color.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(FWPaperBackground(topTint: FW.Color.lavender))
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(selectedColorScheme)
        .alert("Add a child", isPresented: $showAddChild) {
            TextField("Child’s name", text: $newChildName)
            Button("Add") { addChild() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Add a little artist to your family calendar.")
        }
        .sheet(isPresented: $showEditChild) {
            if let childToEdit {
                EditChildSheet(child: childToEdit, orderedChildIDs: orderedChildIDs)
            }
        }
        .alert("Delete \(childToEdit?.name ?? "")?", isPresented: $showDeleteChild) {
            Button("Delete", role: .destructive) { deleteChild() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete all their artwork and wallpapers.")
        }
        .alert("Help", isPresented: $showHelpMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Help and support options will be available here soon.")
        }
        .onAppear(perform: ensureProfile)
        .onChange(of: reminderTimeInterval) { _, _ in
            guard notificationsEnabled else { return }
            Task { try? await scheduleReminder() }
        }
    }

    private var selectedColorScheme: ColorScheme? {
        switch fridgeTheme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    private var selectedThemeAsset: String {
        switch fridgeTheme {
        case "light": "FWThemeLight"
        case "dark": "FWThemeDark"
        default: "FWThemeSystem"
        }
    }

    private var selectedThemeName: String {
        switch fridgeTheme {
        case "light": "Light"
        case "dark": "Dark"
        default: "System"
        }
    }

    private var selectedMemoryFontLabel: String {
        switch memoryFont {
        case "serif": "Serif"
        case "handwritten": "Handwritten"
        default: "Rounded"
        }
    }

    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { notificationsEnabled },
            set: { enabled in
                if enabled {
                    Task { await enableNotifications() }
                } else {
                    notificationsEnabled = false
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-memory-reminder"])
                }
            }
        )
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(FW.Font.body(20, weight: .regular))
                .foregroundStyle(FW.Color.onboardingInk)
                .padding(.leading, 3)
            VStack(spacing: 0, content: content)
                .padding(.horizontal, 15)
                .background(FW.Color.paper.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(FW.Color.border.opacity(0.7), lineWidth: 1)
                }
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(FW.Color.border.opacity(0.75))
            .frame(height: 1)
            .padding(.leading, 46)
    }

    private func settingsLabel(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(FW.Font.body(15, weight: .medium))
                .foregroundStyle(FW.Color.onboardingInk)
            Text(detail)
                .font(FW.Font.caption(12))
                .foregroundStyle(FW.Color.muted)
        }
    }

    private func themeMenuOption(_ title: String, asset: String, value: String) -> some View {
        Button {
            fridgeTheme = value
        } label: {
            HStack(spacing: 10) {
                themeIcon(asset, selected: false)
                    .frame(width: 30, height: 30)
                Text(title)
            }
        }
    }

    private func themeIcon(_ assetName: String, selected: Bool) -> some View {
        Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: selected ? 30 : 24, height: selected ? 30 : 24)
                .frame(width: selected ? 40 : 30, height: selected ? 40 : 30)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(FW.Color.iris.opacity(0.32))
                    }
                }
                .overlay {
                    if selected {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(FW.Color.onboardingInk.opacity(0.24), lineWidth: 1)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: selected ? 13 : 8, style: .continuous))
    }

    private func fontMenuOption(_ title: String, value: String) -> some View {
        Button {
            memoryFont = value
        } label: {
            Text(title)
                .font(memoryFontPreview(value))
                .foregroundStyle(FW.Color.onboardingInk)
        }
    }

    private func memoryFontPreview(_ value: String) -> Font {
        switch value {
        case "serif": .system(size: 15, weight: .medium, design: .serif)
        case "handwritten": .custom("Caveat", size: 17)
        default: .system(size: 14, weight: .medium, design: .rounded)
        }
    }

    private func childRow(_ child: Child) -> some View {
        Button {
            childToEdit = child
            showEditChild = true
        } label: {
            HStack(spacing: 12) {
                Text(child.name)
                    .font(FW.Font.body(14, weight: .medium))
                    .foregroundStyle(FW.Color.onboardingInk)
                    .lineLimit(1)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(FW.Color.childColor(id: child.id, orderedChildIDs: orderedChildIDs, customIndex: child.colorIndex).opacity(0.45), in: Capsule())

                Text("\(child.artworks.count) artwork\(child.artworks.count == 1 ? "" : "s")")
                    .font(FW.Font.caption(12))
                    .foregroundStyle(FW.Color.muted)

                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FW.Color.muted.opacity(0.8))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit name", systemImage: "pencil") {
                childToEdit = child
                showEditChild = true
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                childToEdit = child
                showDeleteChild = true
            }
        }
    }

    private func actionRow(_ title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(FW.Color.onboardingInk)
                .frame(width: 34, height: 34)
                .background(FW.Color.lavender.opacity(0.72), in: Circle())
            settingsLabel(title, detail: detail)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(FW.Color.muted.opacity(0.8))
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private func enableNotifications() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                notificationsEnabled = false
                return
            }
            try await scheduleReminder()
            notificationsEnabled = true
        } catch {
            notificationsEnabled = false
        }
    }

    private func scheduleReminder() async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-memory-reminder"])
        var components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime.wrappedValue)
        components.calendar = Calendar.current
        let content = UNMutableNotificationContent()
        content.title = "A little memory for today?"
        content.body = "Save a moment from your child's day in Fridgeworthy."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try await center.add(UNNotificationRequest(identifier: "daily-memory-reminder", content: content, trigger: trigger))
    }

    private func ensureProfile() {
        guard profiles.isEmpty else { return }
        modelContext.insert(UserProfile(supabaseID: authService.currentUserID?.uuidString ?? UUID().uuidString))
    }

    private func addChild() {
        let trimmed = newChildName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let child = Child(name: trimmed)
        modelContext.insert(child)

        guard let profileID = authService.currentUserID else { return }
        Task {
            _ = try? await SupabaseService.shared.insertChild(id: child.id, name: trimmed, profileID: profileID)
        }
    }

    private func deleteChild() {
        guard let child = childToEdit else { return }
        modelContext.delete(child)
        childToEdit = nil
    }
}

// MARK: - Edit Child Sheet

struct EditChildSheet: View {
    @Bindable var child: Child
    let orderedChildIDs: [UUID]
    @AppStorage("fridgeTheme") private var fridgeTheme = "system"
    @AppStorage("memoryFont") private var memoryFont = "rounded"

    private let colorChoices = Array(FW.Color.childPalette.indices)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Edit child")
                    .font(editorFont(21))
                    .foregroundStyle(FW.Color.onboardingInk)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(editorFont(15, weight: .medium))
                        .foregroundStyle(FW.Color.onboardingInk)

                    TextField("Child’s name", text: $child.name)
                        .font(editorFont(17))
                        .foregroundStyle(FW.Color.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(FW.Color.paper.opacity(0.86), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(FW.Color.border, lineWidth: 1)
                        }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Child color")
                        .font(editorFont(15, weight: .medium))
                        .foregroundStyle(FW.Color.onboardingInk)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(colorChoices, id: \.self) { index in
                            let isSelected = child.colorIndex == index || (child.colorIndex == nil && defaultColorIndex == index)
                            Button {
                                child.colorIndex = index
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(FW.Color.childColor(at: index))
                                        .frame(width: 25, height: 25)
                                    Circle()
                                        .strokeBorder(
                                            isSelected ? FW.Color.onboardingInk : FW.Color.ink.opacity(0.18),
                                            lineWidth: isSelected ? 2 : 1
                                        )
                                        .frame(width: 39, height: 39)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Color \(index + 1)")
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(FWPaperBackground(topTint: FW.Color.lavender))
        .scrollIndicators(.hidden)
        .preferredColorScheme(selectedColorScheme)
        .presentationDragIndicator(.visible)
    }

    private var defaultColorIndex: Int {
        orderedChildIDs.firstIndex(of: child.id) ?? 0
    }

    private var selectedColorScheme: ColorScheme? {
        switch fridgeTheme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    private func editorFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch memoryFont {
        case "serif": .system(size: size, weight: weight, design: .serif)
        case "handwritten": .custom("Caveat", size: size).weight(weight)
        default: .system(size: size, weight: weight, design: .rounded)
        }
    }
}
