import XCTest

/// UI tests for the Ember chat screen.
///
/// These tests exercise real app binary through XCUITest, targeting the
/// accessibility identifiers that ChatScreen, ChatInputBar, and
/// MessageListView are expected to expose.
///
/// Accessibility identifiers assumed to exist (add `.accessibilityIdentifier()`
/// modifiers to the corresponding SwiftUI views):
///   - "message-list"          — the ScrollView / List in MessageListView
///   - "chat-input-field"      — the TextField in ChatInputBar
///   - "send-button"           — the send Button in ChatInputBar
///   - "voice-button"          — the microphone Button in ChatInputBar
final class ChatScreenUITests: XCTestCase {

    private var app: XCUIApplication!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        // Stop immediately when a failure occurs — later tests likely depend on
        // the app being in a known state.
        continueAfterFailure = false

        app = XCUIApplication()
        // Pass a launch argument that the app can detect to bypass onboarding /
        // API-key checks and navigate directly to the chat screen.
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - 1. App launches successfully

    /// The app must reach a running state and show at least one element.
    func test_appLaunchesSuccessfully() {
        XCTAssertEqual(app.state, .runningForeground, "App must be running in the foreground after launch")
    }

    // MARK: - 2. Core chat UI elements are present

    /// The message list area, text input field, and send button must all be
    /// accessible (i.e. present in the accessibility tree) on the chat screen.
    func test_coreUIElementsAreVisible() {
        let messageList  = app.scrollViews["message-list"]
        let inputField   = app.textFields["chat-input-field"]
            .firstMatch
            .exists
            ? app.textFields["chat-input-field"]
            : app.textViews["chat-input-field"]   // multiline TextField renders as textView
        let sendButton   = app.buttons["send-button"]

        XCTAssertTrue(
            messageList.waitForExistence(timeout: 5),
            "Message list area (accessibility id: 'message-list') must be present on the chat screen"
        )
        XCTAssertTrue(
            inputField.waitForExistence(timeout: 5),
            "Chat input field (accessibility id: 'chat-input-field') must be present"
        )
        XCTAssertTrue(
            sendButton.waitForExistence(timeout: 5),
            "Send button (accessibility id: 'send-button') must be present"
        )
    }

    // MARK: - 3. Send button is disabled when input is empty

    /// With no text in the input field the send button must be disabled so
    /// users cannot submit an empty message.
    func test_sendButtonIsDisabledWhenInputIsEmpty() {
        // Resolve the input field — SwiftUI's multi-line TextField with axis:.vertical
        // may render as either a UITextField or UITextView in the accessibility tree.
        let inputField = resolveInputField()

        // Ensure the field is present before asserting button state.
        XCTAssertTrue(inputField.waitForExistence(timeout: 5))

        // Clear any pre-filled text.
        if let existingText = inputField.value as? String, !existingText.isEmpty {
            inputField.tap()
            inputField.clearText()
        }

        let sendButton = app.buttons["send-button"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        XCTAssertFalse(
            sendButton.isEnabled,
            "Send button must be disabled when the input field is empty"
        )
    }

    // MARK: - 4. Send button is enabled when input has text

    /// After typing a non-empty message the send button must become enabled so
    /// the user can submit it.
    func test_sendButtonIsEnabledWhenInputHasText() {
        let inputField = resolveInputField()
        XCTAssertTrue(inputField.waitForExistence(timeout: 5))

        inputField.tap()
        inputField.typeText("Hello, Ember!")

        let sendButton = app.buttons["send-button"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        XCTAssertTrue(
            sendButton.isEnabled,
            "Send button must be enabled once the input field contains non-whitespace text"
        )
    }

    // MARK: - 5. Typing updates the input field value

    /// Characters typed into the input field must be reflected in its
    /// accessibility value, confirming the binding is wired correctly.
    func test_typingInInputFieldUpdatesValue() {
        let inputField = resolveInputField()
        XCTAssertTrue(inputField.waitForExistence(timeout: 5))

        let message = "Testing 1-2-3"
        inputField.tap()
        inputField.typeText(message)

        // The accessibility value mirrors the text content for both UITextField
        // and UITextView.
        let value = inputField.value as? String ?? ""
        XCTAssertEqual(
            value, message,
            "Input field value must match the typed text"
        )
    }

    // MARK: - 6. Voice button is present

    /// The microphone / voice-input button must be accessible on the chat screen.
    func test_voiceButtonIsPresent() {
        let voiceButton = app.buttons["voice-button"]
        XCTAssertTrue(
            voiceButton.waitForExistence(timeout: 5),
            "Voice button (accessibility id: 'voice-button') must be present in the input bar"
        )
    }

    // MARK: - 7. Send button disabled for whitespace-only input

    /// Submitting a message that is purely whitespace must not enable the send
    /// button, because `ChatViewModel.sendMessage()` trims before validation.
    func test_sendButtonRemainsDisabledForWhitespaceInput() {
        let inputField = resolveInputField()
        XCTAssertTrue(inputField.waitForExistence(timeout: 5))

        inputField.tap()
        inputField.typeText("   ")   // only spaces

        let sendButton = app.buttons["send-button"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        XCTAssertFalse(
            sendButton.isEnabled,
            "Send button must remain disabled when the input contains only whitespace"
        )
    }

    // MARK: - 8. Navigation bar shows a title

    /// The navigation bar title area must contain at least one static-text
    /// element (the conversation title).
    func test_navigationBarTitleIsPresent() {
        // The default title for a new conversation is "New Conversation".
        let navBars = app.navigationBars
        XCTAssertTrue(
            navBars.firstMatch.waitForExistence(timeout: 5),
            "A navigation bar must be visible on the chat screen"
        )
        // Check that a static text element with the default title exists.
        let title = navBars.staticTexts["New Conversation"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Navigation bar must display the conversation title 'New Conversation' for a new chat"
        )
    }

    // MARK: - Private Helpers

    /// Returns the first matching input field element regardless of whether
    /// SwiftUI rendered the multi-line `TextField` as a `UITextField` or
    /// `UITextView` in the accessibility hierarchy.
    private func resolveInputField() -> XCUIElement {
        let textField = app.textFields["chat-input-field"]
        let textView  = app.textViews["chat-input-field"]
        // Prefer whichever type is already in the tree without waiting.
        return textField.exists ? textField : textView
    }
}

// MARK: - XCUIElement Extension

private extension XCUIElement {
    /// Clears all existing text from a text field or text view by selecting all
    /// and deleting, so tests start from a clean slate.
    func clearText() {
        guard let stringValue = value as? String, !stringValue.isEmpty else { return }
        // Triple-tap selects all text, then Delete removes it.
        tap()
        // Use the built-in "Select All" menu item when available.
        press(forDuration: 1.0)
        if XCUIApplication().menuItems["Select All"].waitForExistence(timeout: 1) {
            XCUIApplication().menuItems["Select All"].tap()
            typeText(XCUIKeyboardKey.delete.rawValue)
        } else {
            // Fallback: replace via coordinate press + type replacement.
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            typeText(deleteString)
        }
    }
}
