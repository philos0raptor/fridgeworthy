import SwiftUI
import SwiftData

struct MeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Environment(RevenueCatService.self) private var revenueCatService
    @Query private var profiles: [UserProfile]
    @Query(sort: \Child.createdAt) private var children: [Child]

    @State private var showRolePicker = false
    @State private var showAddChild = false
    @State private var newChildName = ""
    @State private var childToEdit: Child?
    @State private var showEditChild = false
    @State private var showDeleteChild = false
    @State private var showPaywall = false

    private var userProfile: UserProfile? { profiles.first }

    var body: some View {
        List {
            // MARK: - My Account
            Section {
                HStack(spacing: 14) {
                    Circle()
                        .fill(FW.Color.accent.opacity(0.12))
                        .frame(width: 56, height: 56)
                        .overlay {
                            if let rel = userProfile?.relationship {
                                Text(rel.emoji)
                                    .font(.system(size: 26))
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(FW.Color.accent)
                            }
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(userProfile?.greeting ?? "Set your role")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(userProfile?.relationship != nil ? FW.Color.ink : FW.Color.accent)
                        Text(revenueCatService.isProUser ? "Pro" : "Free plan")
                            .font(.system(size: 14))
                            .foregroundStyle(FW.Color.ink3)
                    }

                    Spacer()

                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(FW.Color.ink3)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    showRolePicker = true
                }
            }

            // MARK: - Kids
            Section {
                ForEach(children) { child in
                    childRow(child)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                childToEdit = child
                                showDeleteChild = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                Button {
                    newChildName = ""
                    showAddChild = true
                } label: {
                    Label("Add a child", systemImage: "plus.circle")
                        .foregroundStyle(FW.Color.accent)
                }
            } header: {
                Text("Kids")
            }

            // MARK: - Subscription
            Section("Subscription") {
                if !revenueCatService.isProUser {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Upgrade to Pro", systemImage: "crown")
                                .foregroundStyle(FW.Color.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(FW.Color.ink4)
                        }
                    }
                } else {
                    Label("Fridgeworthy Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(FW.Color.accent)
                }
            }

            // MARK: - Support
            Section("Support") {
                Label("Help & FAQ", systemImage: "questionmark.circle")
                Label("Send Feedback", systemImage: "envelope")
                Label("Privacy Policy", systemImage: "hand.raised")
                Label("Terms of Use", systemImage: "doc.text")
            }

            // MARK: - Sign Out
            Section {
                Button(role: .destructive) {
                    Task { await authService.signOut() }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Account")
        // Role picker
        .sheet(isPresented: $showRolePicker) {
            RolePickerSheet(profile: userProfile)
        }
        // Add child
        .alert("Add a Child", isPresented: $showAddChild) {
            TextField("Child's name", text: $newChildName)
            Button("Add") { addChild() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can set their emoji and age after adding")
        }
        // Edit child
        .sheet(isPresented: $showEditChild) {
            if let child = childToEdit {
                EditChildSheet(child: child)
            }
        }
        // Delete child
        .alert("Delete \(childToEdit?.name ?? "")?", isPresented: $showDeleteChild) {
            Button("Delete", role: .destructive) { deleteChild() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete all their artwork and wallpapers.")
        }
        // Paywall
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            if userProfile == nil {
                ensureProfile()
            }
        }
    }

    // MARK: - Child Row

    private func childRow(_ child: Child) -> some View {
        Button {
            childToEdit = child
            showEditChild = true
        } label: {
            HStack(spacing: 12) {
                Text(child.avatarEmoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(FW.Color.accent.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(FW.Color.ink)

                    HStack(spacing: 8) {
                        if let ageText = child.ageText {
                            Text("\(ageText) old")
                        } else {
                            Text("Age not set")
                        }
                        Text("·")
                        Text("\(child.artworks.count) piece\(child.artworks.count == 1 ? "" : "s")")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(FW.Color.ink3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FW.Color.ink4)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

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

        guard let profileID = authService.currentUserID else { return }
        Task {
            _ = try? await SupabaseService.shared.insertChild(
                id: child.id, name: trimmed, profileID: profileID
            )
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
    @Environment(\.dismiss) private var dismiss
    @Bindable var child: Child
    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var hasBirthDate: Bool = false
    @State private var birthDate: Date = Date()

    private let emojiOptions = ["🎨", "🦊", "🐱", "🦁", "🐶", "🐼", "🦄", "🐸", "🐰", "🐻", "🌟", "🌈", "🚀", "🎸", "⚽️", "🧸"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Child's name", text: $name)
                }

                Section("Avatar Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { option in
                            Text(option)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(emoji == option ? FW.Color.accent.opacity(0.15) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(emoji == option ? FW.Color.accent : .clear, lineWidth: 2)
                                )
                                .onTapGesture { emoji = option }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Birthday") {
                    Toggle("Set birthday", isOn: $hasBirthDate)
                    if hasBirthDate {
                        DatePicker(
                            "Birthday",
                            selection: $birthDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                }
            }
            .navigationTitle("Edit \(child.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = child.name
                emoji = child.avatarEmoji
                hasBirthDate = child.birthDate != nil
                birthDate = child.birthDate ?? Calendar.current.date(byAdding: .year, value: -5, to: Date())!
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { child.name = trimmed }
        child.avatarEmoji = emoji
        child.birthDate = hasBirthDate ? birthDate : nil
    }
}

// MARK: - Role Picker Sheet

struct RolePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var profile: UserProfile?
    @State private var selectedRole: UserRelationship?
    @State private var customName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("I am...")
                    .font(FW.Font.sectionTitle(24))
                    .tracking(-0.5)
                    .padding(.top, 8)

                // Role grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(UserRelationship.allCases, id: \.self) { role in
                        Button {
                            selectedRole = role
                        } label: {
                            HStack(spacing: 10) {
                                Text(role.emoji)
                                    .font(.system(size: 24))
                                Text(role.displayLabel)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(FW.Color.ink)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedRole == role ? FW.Color.accent.opacity(0.1) : FW.Color.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(selectedRole == role ? FW.Color.accent : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                // Custom name field for "Other"
                if selectedRole == .other {
                    TextField("Your name", text: $customName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("My Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedRole == nil || (selectedRole == .other && customName.trimmingCharacters(in: .whitespaces).isEmpty))
                }
            }
            .onAppear {
                selectedRole = profile?.relationship
                customName = profile?.displayName ?? ""
            }
        }
    }

    private func save() {
        guard let profile, let role = selectedRole else { return }
        profile.relationship = role
        if role == .other {
            let trimmed = customName.trimmingCharacters(in: .whitespaces)
            profile.displayName = trimmed.isEmpty ? nil : trimmed
        } else {
            profile.displayName = nil
        }
    }
}
