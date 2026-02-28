import SwiftUI

// MARK: - APIKeySettingView

/// Manages the Claude API key: entry via SecureField, masked display of saved keys,
/// save/delete actions backed by KeychainService, and a status indicator.
struct APIKeySettingView: View {

    // MARK: - Constants

    static let keychainKey = "claude_api_key"

    // MARK: - State

    @State private var apiKeyInput: String = ""
    @State private var savedKeyPreview: String? = nil
    @State private var isSaving: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var statusMessage: String? = nil
    @State private var statusIsError: Bool = false

    // MARK: - Dependencies

    private let keychainService: KeychainService

    // MARK: - Init

    init(keychainService: KeychainService = .shared) {
        self.keychainService = keychainService
    }

    // MARK: - Body

    var body: some View {
        EmberCard(header: "API Key") {
            VStack(alignment: .leading, spacing: EmberTheme.Spacing.md) {
                // Status row
                statusRow

                // Key input
                keyInputField

                // Action buttons
                actionButtons
            }
        }
        .onAppear {
            loadExistingKey()
        }
    }

    // MARK: - Status Row

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: EmberTheme.Spacing.sm) {
            if let preview = savedKeyPreview {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.green)

                Text(preview)
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)
                    .monospaced()
            } else {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.ember.textSecondary.opacity(0.5))

                Text("No API key configured")
                    .font(EmberTheme.Typography.caption)
                    .foregroundStyle(Color.ember.textSecondary)
            }

            Spacer()
        }

        // Transient status feedback
        if let message = statusMessage {
            Text(message)
                .font(EmberTheme.Typography.caption)
                .foregroundStyle(statusIsError ? .red : .green)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Key Input Field

    private var keyInputField: some View {
        SecureField("sk-ant-...", text: $apiKeyInput)
            .font(EmberTheme.Typography.body)
            .foregroundStyle(Color.ember.textPrimary)
            .tint(Color.ember.primary)
            .padding(.horizontal, EmberTheme.Spacing.md)
            .padding(.vertical, EmberTheme.Spacing.sm + 2)
            .background(Color.ember.background)
            .clipShape(RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: EmberTheme.Radii.medium, style: .continuous)
                    .stroke(Color.ember.textSecondary.opacity(0.3), lineWidth: 1)
            )
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: EmberTheme.Spacing.sm) {
            // Save button
            EmberButton("Save Key", style: .primary, isLoading: isSaving) {
                saveKey()
            }

            // Delete button (only shown when a key exists)
            if savedKeyPreview != nil {
                EmberButton("Remove", style: .secondary) {
                    showDeleteConfirmation = true
                }
                .confirmationDialog(
                    "Remove API Key?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Remove Key", role: .destructive) {
                        deleteKey()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will remove your saved Claude API key. You can add a new one at any time.")
                }
            }
        }
    }

    // MARK: - Actions

    private func loadExistingKey() {
        do {
            if let existingKey = try keychainService.retrieve(key: Self.keychainKey),
               !existingKey.isEmpty {
                savedKeyPreview = maskedKey(existingKey)
            } else {
                savedKeyPreview = nil
            }
        } catch {
            savedKeyPreview = nil
        }
    }

    private func saveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showStatus("Please enter an API key", isError: true)
            return
        }

        isSaving = true

        do {
            try keychainService.save(key: Self.keychainKey, value: trimmed)
            savedKeyPreview = maskedKey(trimmed)
            apiKeyInput = ""
            showStatus("API key saved successfully", isError: false)
        } catch {
            showStatus("Failed to save: \(error.localizedDescription)", isError: true)
        }

        isSaving = false
    }

    private func deleteKey() {
        do {
            try keychainService.delete(key: Self.keychainKey)
            savedKeyPreview = nil
            apiKeyInput = ""
            showStatus("API key removed", isError: false)
        } catch {
            showStatus("Failed to remove: \(error.localizedDescription)", isError: true)
        }
    }

    private func showStatus(_ message: String, isError: Bool) {
        withAnimation(.emberSubtle) {
            statusMessage = message
            statusIsError = isError
        }

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.emberSubtle) {
                statusMessage = nil
            }
        }
    }

    // MARK: - Helpers

    private func maskedKey(_ key: String) -> String {
        guard key.count > 10 else { return String(repeating: "*", count: key.count) }
        let prefix = String(key.prefix(6))
        let suffix = String(key.suffix(4))
        return "\(prefix)...\(suffix)"
    }
}

// MARK: - Preview

#Preview("APIKeySettingView") {
    ScrollView {
        VStack(spacing: EmberTheme.Spacing.md) {
            APIKeySettingView()
        }
        .padding(EmberTheme.Spacing.lg)
    }
    .background(Color.ember.background)
}
