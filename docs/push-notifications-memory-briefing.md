# Push Notifications, Memory System & Morning Briefing

Implementation documentation for the three agent features added to Ember iOS. These features transform Ember from a passive inbox viewer into a proactive personal agent.

**Key principle**: iOS is a thin client. All intelligence runs Gateway-side. iOS registers for events, caches locally, and displays results.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Gateway Protocol](#gateway-protocol)
- [Phase 0: Protocol Refactor](#phase-0-protocol-refactor)
- [Phase 1: Push Notifications](#phase-1-push-notifications)
- [Phase 2: Memory System](#phase-2-memory-system)
- [Phase 3: Morning Briefing](#phase-3-morning-briefing)
- [Settings & Configuration](#settings--configuration)
- [File Inventory](#file-inventory)
- [Testing](#testing)
- [Remote Access](#remote-access)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                   Ember iOS                      │
│                                                  │
│  EmberApp ─► AppState ─► InboxService (WS)      │
│     │            │            │                  │
│     │            ├── memories ─► MemoryStore     │
│     │            ├── briefings ─► BriefingStore  │
│     │            ├── inboxMessages ─► InboxStore │
│     │            └── notificationService         │
│     │                                            │
│     ├── MemoryScreen                             │
│     ├── BriefingScreen                           │
│     ├── InboxScreen                              │
│     └── SettingsScreen                           │
└──────────────────┬──────────────────────────────┘
                   │ Single WebSocket
                   ▼
┌──────────────────────────────────────────────────┐
│              OpenClaw Gateway                     │
│                                                  │
│  Capabilities: inbox, memory, briefing, push     │
│                                                  │
│  - Triages messages from iMessage/Slack/Teams    │
│  - Manages AI memory (facts, preferences, etc.)  │
│  - Generates morning briefings on schedule       │
│  - Sends APNs push notifications                 │
└──────────────────────────────────────────────────┘
```

All three features share the same WebSocket connection via `InboxService`. The connection registers with capabilities `["inbox", "memory", "briefing", "push"]`. Events are dispatched through `GatewayEvent` and handled in `AppState.handleGatewayEvent()`.

### Data Flow

1. `EmberApp.onAppear` → `AppState.startInboxIfNeeded()`
2. `InboxService.subscribe()` opens WebSocket, sends `register` + `inbox_subscribe`
3. After connection, sends config: inbox VIPs/topics, memory sync request, briefing config, device token
4. Gateway pushes events → parsed in `InboxService` → yielded as `GatewayEvent` → handled in `AppState`
5. Each event type updates the corresponding state array and persists to its actor-based store

### Local Caching

Each data type has an actor-based JSON file cache in `~/Library/Application Support/Ember/`:

| Store | File | Pattern |
|-------|------|---------|
| `InboxMessageStore` | `inbox.json` | Load on connect, save on every change |
| `MemoryStore` | `memories.json` | Load on startup, save on every change |
| `BriefingStore` | `briefings.json` | Load on startup, save on every change, 30-day retention |

---

## Gateway Protocol

All messages are JSON over WebSocket. The connection carries all event types.

### Registration (Client → Gateway)

```json
{
  "type": "register",
  "client": "ember-ios",
  "version": "1.0",
  "capabilities": ["inbox", "memory", "briefing", "push"]
}
```

### Client → Gateway Messages

| Type | Payload | Purpose |
|------|---------|---------|
| `inbox_subscribe` | `{}` | Start receiving triaged messages |
| `inbox_refresh` | `{}` | Re-poll all sources |
| `inbox_read` | `{"messageId": "..."}` | Mark message as read |
| `inbox_config` | `{"vips": [...], "topics": [...]}` | Send VIP list and priority topics |
| `device_token` | `{"token": "<hex>", "platform": "ios"}` | Register APNs token |
| `memory_sync` | `{}` | Request full memory list |
| `memory_delete` | `{"memoryId": "..."}` | Delete a memory |
| `briefing_config` | `{"enabled": true, "time": "07:00", "timezone": "America/New_York", "sources": ["iMessage","slack","teams"]}` | Configure briefing schedule |

### Gateway → Client Messages

| Type | Payload | Purpose |
|------|---------|---------|
| `inbox_messages` | `{"messages": [...]}` | Batch of triaged messages |
| `inbox_update` | `{"message": {...}}` | Single message add/update |
| `inbox_read_confirmed` | `{"messageId": "..."}` | Read confirmation |
| `memory_list` | `{"memories": [...]}` | Full memory sync response |
| `memory_created` | `{"memory": {...}}` | New memory from AI |
| `memory_updated` | `{"memory": {...}}` | Updated memory |
| `memory_deleted` | `{"memoryId": "..."}` | Memory deletion confirmed |
| `briefing` | `{"briefing": {...}}` | Morning briefing delivery |
| `device_token_confirmed` | `{}` | Token registration confirmed |
| `registered` | — | Connection registered |
| `pong` | — | Keepalive response |
| `ack` | — | Command acknowledged |
| `error` | `{"message": "..."}` | Error (closes stream) |

---

## Phase 0: Protocol Refactor

**Goal**: Widen the single WebSocket to carry all event types.

### `InboxEvent` → `GatewayEvent`

The enum was renamed and expanded with new cases:

```swift
enum GatewayEvent: Sendable {
    // Inbox (existing)
    case messages([InboxMessage])
    case update(InboxMessage)
    case readConfirmed(messageID: String)

    // Memory (new)
    case memoryList([Memory])
    case memoryCreated(Memory)
    case memoryUpdated(Memory)
    case memoryDeleted(memoryId: String)

    // Briefing (new)
    case briefing(Briefing)

    // Push (new)
    case deviceTokenConfirmed

    // Connection (existing)
    case disconnected
    case connected
}
```

### `InboxServiceProtocol` Expansion

Four new methods added:

```swift
func sendDeviceToken(_ token: String) async throws
func requestMemorySync() async throws
func deleteMemory(id: String) async throws
func sendBriefingConfig(enabled:time:timezone:sources:) async throws
```

### `InboxService` Changes

- Registration capabilities: `["inbox"]` → `["inbox", "memory", "briefing", "push"]`
- Receive loop handles 7 new message types
- 4 new send methods build and transmit JSON payloads

---

## Phase 1: Push Notifications

### Components

**`AppDelegate.swift`** — UIApplicationDelegate adapter:
- Receives APNs device token via `didRegisterForRemoteNotificationsWithDeviceToken`
- Converts token `Data` to hex string
- Implements `UNUserNotificationCenterDelegate` for foreground display and tap handling
- Posts `Notification.Name.navigateFromNotification` on tap with destination info

**`NotificationService.swift`** — Wraps `UNUserNotificationCenter`:
- `requestPermission()` → prompts user, returns `Bool`
- `postUrgentMessageNotification(sender:preview:messageID:)` → local notification
- `postBriefingNotification(title:summary:briefingID:)` → local notification
- Registers two categories: `INBOX_MESSAGE` and `BRIEFING`

**`Ember.entitlements`** — `aps-environment = development`

### Flow

```
1. User enables notifications in Settings
2. User taps "Request Permission" → OS prompt
3. If granted → UIApplication.registerForRemoteNotifications()
4. AppDelegate receives token → AppState.registerDeviceToken()
5. Token sent to Gateway: {"type": "device_token", "token": "...", "platform": "ios"}
6. Gateway confirms: {"type": "device_token_confirmed"}
```

### Local Notifications

When `notificationsEnabled` is true, AppState posts local notifications for:
- **Urgent inbox messages** (`.update` events where `urgency == .urgent && !isRead`)
- **New briefings** (every `.briefing` event)

### Deep Linking

Notification tap flow:
```
AppDelegate.didReceive → posts .navigateFromNotification
    → EmberApp.onReceive → reads "destination" from userInfo
        → "briefing" → router.navigate(to: .briefing)
        → default    → router.navigate(to: .inbox)
```

### Configuration Changes

| File | Change |
|------|--------|
| `Info.plist` | Added `UIBackgroundModes → [remote-notification]` |
| `project.yml` | Added `CODE_SIGN_ENTITLEMENTS: Ember/Ember.entitlements` |
| `EmberApp.swift` | Added `@UIApplicationDelegateAdaptor(AppDelegate.self)` |

---

## Phase 2: Memory System

### Data Model

```swift
struct Memory: Identifiable, Codable, Equatable {
    let id: String          // Gateway-assigned, opaque to iOS
    let category: MemoryCategory
    let content: String
    let source: MemorySource
    let createdAt: Date
    var updatedAt: Date
}

enum MemoryCategory: String, Codable, CaseIterable {
    case preference   // "Prefers bullet-point summaries"
    case fact         // "Works at Incendo AI"
    case correction   // "Name is Lindsay not Lindsey"
    case context      // "Currently working on Ember iOS"
}

enum MemorySource: String, Codable {
    case conversation  // Extracted from chat
    case manual        // User-created
    case inferred      // AI-inferred from patterns
}
```

**Key decision**: Memory `id` is `String` (Gateway-assigned). The Gateway automatically includes relevant memories in AI context during conversations — no iOS-side protocol change needed for `sendMessage()`.

### AppState Memory Lifecycle

```swift
// On startup: load from cache
memories = await memoryStore.load()

// After WebSocket connects:
inboxService.requestMemorySync()  // → Gateway sends memory_list

// Event handling:
handleMemoryList([Memory])     // Replace all, sort by updatedAt
handleMemoryCreated(Memory)    // Insert at front
handleMemoryUpdated(Memory)    // Replace by id, or insert
handleMemoryDeleted(String)    // Remove by id

// User action:
requestMemoryDelete(id: String)  // Optimistic local remove + send to Gateway
```

### UI Components

**MemoryScreen** (`Ember/Screens/Memory/MemoryScreen.swift`):
- Search bar with clear button
- Horizontal category filter chips (All, Preference, Fact, Correction, Context)
- Grouped list by category with section headers
- Swipe-to-delete on each memory card
- Empty state with explanation text

**MemoryCard** (`Ember/Screens/Memory/MemoryCard.swift`):
- Category icon with colored background
- Category label (uppercase)
- Content text (3-line limit)
- Relative timestamp

**MemoryViewModel** (`Ember/Screens/Memory/MemoryViewModel.swift`):
- `@Observable @MainActor`
- `searchText` filtering on `content.lowercased()`
- `selectedCategory` filtering
- `groupedMemories` computed property for section display
- `deleteMemory()` delegates to `AppState.requestMemoryDelete()`

**MemorySettingsView** (`Ember/Screens/Settings/MemorySettingsView.swift`):
- Enable/disable toggle
- Per-category toggles (which types of memories the AI can create)
- "Clear All Memories" with confirmation dialog

### Navigation

- Toolbar: **brain icon** in top-right (visible when OpenClaw selected + memory enabled)
- Route: `AppRouter.Destination.memory` (hash: 4)

---

## Phase 3: Morning Briefing

### Data Model

```swift
struct Briefing: Identifiable, Codable, Equatable {
    let id: String
    let title: String          // "Your Morning Briefing"
    let summary: String        // Markdown-formatted summary
    let date: Date
    let actionItems: [String]  // Checklist items
    let sourceMessages: [String]  // Original message IDs
    let messageCount: Int
    let urgentCount: Int
}
```

**Key decision**: Briefing time stored as `"HH:mm"` string + timezone identifier, not a `Date`. It's a recurring daily time, not a moment. Gateway sends the briefing as both push notification (background) and WebSocket message (foreground).

### AppState Briefing Lifecycle

```swift
// On startup: load from cache
briefings = await briefingStore.load()  // sorted newest first

// After WebSocket connects:
inboxService.sendBriefingConfig(enabled:time:timezone:sources:)

// Event handling:
handleBriefing(Briefing)  // Prepend to list, save, post local notification

// Settings change:
sendBriefingConfig()  // Re-sends config to Gateway
```

### UI Components

**BriefingScreen** (`Ember/Screens/Briefing/BriefingScreen.swift`):
- **Header card**: Sun icon, title, date, stats (messages/urgent/actions)
- **Summary section**: Rendered with MarkdownUI
- **Action items section**: Checklist with circle icons
- **Past briefings list**: Tap to view any previous briefing
- **Empty state**: Explanation with setup instructions

### Settings

In `SettingsScreen → Morning Briefing`:
- Enable/disable toggle
- Time picker (`DatePicker` with `.hourAndMinute` → stored as `"HH:mm"`)
- Timezone auto-detected from device (`TimeZone.current.identifier`)
- Source toggles (iMessage, Slack, Teams)

### Navigation

- Toolbar: **sun icon** in top-right (visible when briefing enabled + `latestBriefing != nil`)
- Route: `AppRouter.Destination.briefing` (hash: 5)

---

## Settings & Configuration

All new settings in `UserSettings` with backward-compatible Codable (uses `decodeIfPresent` with defaults):

| Setting | Type | Default | Purpose |
|---------|------|---------|---------|
| `notificationsEnabled` | `Bool` | `false` | Enable push/local notifications |
| `memoryEnabled` | `Bool` | `true` | Enable memory system |
| `memoryCategories` | `Set<MemoryCategory>` | all cases | Which categories the AI can create |
| `briefingEnabled` | `Bool` | `false` | Enable morning briefing |
| `briefingTime` | `String` | `"07:00"` | Delivery time (HH:mm) |
| `briefingTimezone` | `String` | device timezone | IANA timezone identifier |
| `briefingSources` | `Set<MessagePlatform>` | all cases | Which platforms to include |

All settings are persisted via `PersistenceService` (UserDefaults) and sent to the Gateway after connection.

---

## File Inventory

### New Files (14)

| File | Phase | Purpose |
|------|-------|---------|
| `Ember/Models/Memory.swift` | P2 | Memory, MemoryCategory, MemorySource |
| `Ember/Models/Briefing.swift` | P3 | Briefing struct |
| `Ember/App/AppDelegate.swift` | P1 | APNs + notification delegate |
| `Ember/Services/NotificationService.swift` | P1 | Permission, local notifications, categories |
| `Ember/Ember.entitlements` | P1 | aps-environment = development |
| `Ember/Services/MemoryStore.swift` | P2 | Actor-based memories.json cache |
| `Ember/Services/BriefingStore.swift` | P3 | Actor-based briefings.json cache (30-day retention) |
| `Ember/Screens/Memory/MemoryScreen.swift` | P2 | Searchable grouped list |
| `Ember/Screens/Memory/MemoryCard.swift` | P2 | Category icon + content card |
| `Ember/Screens/Memory/MemoryViewModel.swift` | P2 | Search, filter, delete |
| `Ember/Screens/Settings/MemorySettingsView.swift` | P2 | Memory settings UI |
| `Ember/Screens/Briefing/BriefingScreen.swift` | P3 | Summary + action items + past briefings |
| `EmberTests/Models/MemoryTests.swift` | Tests | 8 tests |
| `EmberTests/Models/BriefingTests.swift` | Tests | 5 tests |

### Modified Files (~11)

| File | Changes |
|------|---------|
| `InboxServiceProtocol.swift` | InboxEvent → GatewayEvent, 6 new cases, 4 new protocol methods |
| `InboxService.swift` | Parse 7 new message types, expanded capabilities, 4 new send methods |
| `AppState.swift` | memories/briefings/deviceToken state, stores, notification service, full lifecycle methods |
| `AppRouter.swift` | .memory (hash 4) and .briefing (hash 5) destinations |
| `EmberApp.swift` | AppDelegate adaptor, notification deep-linking, memory/briefing toolbar buttons |
| `UserSettings.swift` | 7 new settings fields with backward-compatible Codable |
| `SettingsScreen.swift` | Notifications, Memory, and Briefing sections |
| `MockInboxService.swift` | Expanded protocol conformance, new test hooks |
| `InboxServiceTests.swift` | 10 new parse/build/mock tests |
| `Info.plist` | UIBackgroundModes → [remote-notification] |
| `project.yml` | CODE_SIGN_ENTITLEMENTS |

---

## Testing

### Unit Tests

**MemoryTests** (8 tests):
- Codable round-trip (single + array)
- Category enum: allCases, displayNames, icons
- Source enum Codable
- Equatable conformance
- Identifiable (String id)

**BriefingTests** (5 tests):
- Codable round-trip (single + array)
- Default values
- Equatable conformance
- Gateway JSON format parsing

**InboxServiceTests** (10 new tests):
- Parse: `memory_list`, `memory_created`, `memory_updated`, `memory_deleted`, `briefing`, `device_token_confirmed`
- Build: `device_token`, `memory_sync`, `memory_delete`, `briefing_config`
- Mock tracking: `sendDeviceToken`, `requestMemorySync`, `deleteMemory`, `sendBriefingConfig`

### Running Tests

```bash
xcodegen generate
xcodebuild -project Ember.xcodeproj -scheme EmberTests \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' test
```

---

## Remote Access

To use Ember with OpenClaw Gateway when away from your home network:

### Tailscale (Recommended)
1. Install Tailscale on your Gateway machine + iPhone
2. Gateway gets a stable IP (e.g. `100.x.y.z`)
3. Set Gateway URL to `ws://100.x.y.z:3000`
4. Encrypted mesh VPN, no port forwarding needed

### Cloudflare Tunnel
1. Install `cloudflared` on Gateway machine
2. `cloudflared tunnel create openclaw`
3. `cloudflared tunnel route dns openclaw gateway.yourdomain.com`
4. Gateway URL: `wss://gateway.yourdomain.com`

### ngrok
1. `ngrok http 3000`
2. Gateway URL: `wss://abc123.ngrok-free.app`
3. URL changes on restart (paid plan for stable URL)

**Security**: Always ensure your Gateway has authentication enabled. Tailscale is the most secure since traffic stays off the public internet.
