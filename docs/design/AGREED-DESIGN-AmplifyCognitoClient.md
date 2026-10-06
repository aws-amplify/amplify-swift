# Design: AmplifyCognitoClient - a standalone auth client, and the concurrent sessions it enables


**Author:** Amplify Swift

**Status:** Proposal, for review.

Review date: 2026-09-03

---

NOTE: Swift is used throughout the design doc showcasing API changes and a per platform API doc can be created after an agreement on the design approach.

> **The design in one paragraph.** Amplify auth is reachable only as a configured plugin behind a process-global (`Amplify.Auth`). This design proposes **`AmplifyCognitoClient`** - the **Auth Client** - a self-contained client you construct and hold, built the same way as the standalone clients already shipping. Because it is an ordinary object rather than a registry singleton, an app can hold **more than one**, which is what makes concurrent signed-in sessions possible. The Cognito protocol logic (SRP, MFA, device tracking, refresh, OAuth) is **not rewritten**.

## Changes since the previous revision

**Revision 2026-10-02.** What changed in this revision:

- **The default session shares the plugin's own saved login**: key `amplify.<ns>.session`, payload
  `AmplifyCredentials`, plus a sidecar for the label and last user (`amplify.1.<ns>.$default.meta`). No `$default` session record. → [§4.8](#48-migrating-an-existing-app) · [§6](#6-storage-model)
- **Read-through, `completeAdoption()` and the "reader ships first" rule are removed**, with the plugin's
  forward-compatible reader and signed-out marker (all unreleased). → [§4.8](#48-migrating-an-existing-app) · [§14.3](#143-managing-saved-sessions)
- **Migration and rollback** are one section with a rollback matrix, each row pinned by a test; no separate document. A user signed out through the client stays signed out under the same configuration, and across rollbacks. The exception is a later configuration change onto an earlier configuration's copy: a change the rule does not carry deletes the signed-out record, and can land on a key that still holds the user's old copy, which then restores signed in, as with the plugin. A purge, or the plugin's own sign-out, after a configuration carry is a further caveat. → [§4.8](#48-migrating-an-existing-app)
- **Side by side**: the plugin and the client share one saved login at rest. Running both in one process over the
  default session is not supported: the bridge, in which the plugin would use the client internally, is not built. → [§3](#3-the-auth-client-contract) · [§4.9](#49-plugin-and-auth-client-side-by-side)
- **A configuration change on `.default` follows the plugin's rule**; named sessions keep "keep". → [§6](#6-storage-model)
- **Storage corrections** found against the code: "all three read one key", "never delete", "byte-identical", and the
  device-ID row. → [§6](#6-storage-model) · [A.3](#a3-where-the-session-lives)
- **Sign-out takes the plugin's shape**: no throw; `.complete`, `.partial(...)` or `.failed(error)`, with
  `signedOutLocally`. Two more cases follow the plugin: the placeholder `revokeTokenError` after a failed global
  sign-out, and `.failed` for a hosted-UI sign-out page that could not be shown or completed. → [§4.7](#47-sign-out-variants) · [§14.8](#148-amendments-2026-09-27-public-api-review)
- **One system sheet at a time** is library policy on iOS, macOS and visionOS, covering browser sign-in, the sign-out
  page and the passkey sheet. → [§9.1](#91-one-browser-sign-in-at-a-time-and-how-the-api-says-so) · [§11](#11-limits) limit 1
- **Decision 1** now states that the bridge is not built, with the shared login in its place for now. → [§12](#12-decisions)
- **Concern 13.1**: Storage and Pinpoint are closed; the Kinesis and Firehose cache remains a stated concern. → [§13.1](#131-two-same-region-record-caching-clients-can-attribute-one-users-data-to-another)
- **`CredentialsError`** lists the shipped `.notConfigured`. → [§15.2](#152-the-credential-provider-contract)
- **The sidecar, the challenge record and the label**: the sidecar and challenge keys, and the sidecar's rules. A
  signed-out row's label survives a sign-in only by the same user, or when no one had signed in yet. `.default`'s
  sidecar and challenge record are the plugin session's items everywhere: the access-group transition wipe, the
  access-group migration, the public `KeychainStoreMigrator` and the migration's destination clear remove or move
  them, and the "does the shared service already hold items?" check ignores them. → [§4.8](#48-migrating-an-existing-app) · [§6](#6-storage-model)
- **The temporary warning** for a different principal in `.default`'s saved login covers any different principal: a
  guest replaced by a user, and a federated identity ID, included. → [§4.9](#49-plugin-and-auth-client-side-by-side)
- **The carried cases, the macOS re-read, `identityPending` for `.default`, the plugin's `deleteUser`, and the
  carried identity ID** are described. Only the app client changing deletes nothing. A deleted login of the same user
  pool is revoked with the previous configuration's app client, and takes its sidecar with it. The static
  `signOutStoredSession` and `purgeStoredSession` apply the configuration rule only when it would carry, so a call
  with another configuration never deletes the app's login. Even when they carry, they never write
  `authConfiguration`: only a restore records the configuration. A static sign-out that carried a user's login also
  writes `{"noCredentials":{}}` over the record it carried from, through the byte guard, while that still holds the
  login it signed out; a static purge revokes nothing and leaves it. → [§6](#6-storage-model)
- **The `.wait(timeout:)` signature** matches the public API. → [§9.1](#91-one-browser-sign-in-at-a-time-and-how-the-api-says-so)
- **Logging**: every client log line is under an `AmplifyCognitoClient.<area>` category, and the engine's six static log sites go through the caller's logger. → [§15.3](#153-logging)

**Earlier revision.** These points were settled in review of the previous revision. Each links to where it landed.

1. **Two clients with the same session ID** - divergence is structurally impossible in-process: sharing resolves through an internal table keyed by session ID, so there is one state machine per session. Cross-process gets a commit guard rather than a lock, and the residual risk is stated rather than claimed away. → D.1 handle model · C.6 · §6 storage · limit 5

2. **Does `signOut()` purge?** - no: it keeps the stored row so a picker can offer "signed out, tap to resume". Purging is opt-in, on the same call. → 4.7 · D.1 · 14.3

3. **Sign out of *all* sessions** - deliberately not shipped in this revision, recorded as a limit so its absence reads as a decision. → limit 4

4. **Plugin and client side by side** - the bridge model: the plugin owns a client and delegates, so there is one implementation underneath instead of two isolated stores. The "must not share a session ID" rule is gone. → 4.9 *(Revised 2026-10-02: the bridge is not built, and side by side over the default session in one process is not supported.)*

5. **The downgrade path** - rollback is preserved. The session segment is an *insertion*, so old and new records are siblings; read-old/write-new, never delete, with an app-triggered take-over. → §6 key · 4.8 *(Superseded 2026-10-02: the default session is the plugin's own record, so there is no take-over; named sessions are still siblings.)*

6. **`isSignedIn`** - dropped, with the reasoning in place of the code. → 14.2

7. **Hosted UI and private windows** - every platform has ephemeral/private browsing. One browser sign-in at a time stands, but is attributed to **library policy** rather than an OS constraint. → 9.1

8. **`setLabel` naming** - now `setSessionLabel`. → 4.6 · 14.3

9. **Storage safe for concurrent reads and mutation** - explicit for *different* records, not just the same one, with per-session single-flight refresh as a named invariant. → §6

10. **The downstream error contract** - it ships alongside and does not block. The error set is part of the provider contract, with a table of what each consumer should do. → 15.2 · 13.1

11. **4.11 in the storage model** - the interrupted-sign-in record has a key, a level, and a lifecycle. → §6

Also stated in the doc: one user at a time per session, the same human *can* hold two sessions, and the app owns session-ID uniqueness → §5; removing a row from a picker → 4.3; and `.awaitingChallenge` keeps its name → 14.2.

**Decided during implementation planning (2026-09-23)** - these came out of checking the design against the code:

- **Multi-session reaches the standalone clients, not the category plugins.** The `AmplifyClients` family already takes a provider at construction; Storage, API, Analytics and the rest keep following the global. DataStore is out of scope. This keeps limit 2 as written - but Storage and Analytics then fail *silently* against the wrong user, so limit 2 says so loudly. → limit 2

- **The registry is keyed by session ID alone**, with the storage namespace and a configuration fingerprint checked beside it. Keying by configuration would make the different-pool case a silent miss instead of a throw. → D.1

- **The key format is `amplify.1.<poolNamespace>.<sessionId>.session`**, because apps with only one pool type have one fewer segment. **The default session is stored as `$default`**, which `named(_:)` cannot produce, so it cannot be spoofed. **It is also the session that adopts the plugin's record** - there is no separate adoption session ID, so the plugin, the bridge and the client all read one key. → §6 key *(Superseded 2026-10-02: `.default` is the plugin's own record, `amplify.<ns>.session`, and there is no `$default` session record; `.default`'s challenge record and sidecar stay under `$default`. The "one key" claim was also not true of the code: the plugin read `$default` only as a fallback.)*

- **The providers are concrete `Sendable` types**, `CognitoCredentialsProvider` and `CognitoUserPoolTokenProvider`, not existentials. AmplifyFoundation's `AWSCredentialsProvider` is not `Sendable` and changing that would break every existing conformer; the token provider is new, since no Foundation protocol exists for it. → 14.4

- **The client does not depend on Amplify core** - only on AmplifyFoundation and AmplifyFoundationBridge, like the CloudWatch and Kinesis clients. So `AuthSessionState` uses client-owned `AuthClientUser`, `AuthClientSignInStep` and `AuthClientError` in place of Amplify core's `AuthUser`, `AuthSignInStep` and `AuthError`, and the plugin bridge maps between them. It also means the extracted Cognito engine must itself be Amplify-free before the client can use it. → 14.2 · 14.6

- **Release order.** A forward-compatible *reader* has to ship in the current plugin **before** the new client does, so that a released plugin version can read the new record format. → 4.9 *(Removed 2026-10-02: with the shared login there is no new format for the plugin to read.)*

## Contents

| Section | Read this if |
|---|---|
| [Changes since the previous revision](#changes-since-the-previous-revision) | You read the previous revision and want what changed |
| [Terminology](#terminology) | You are about to read anything below |
| [1. Goals](#1-goals) | You want to know why this work exists |
| [2. What this design is not](#2-what-this-design-is-not) | You are worried about your existing app |
| [3. The Auth Client contract](#3-the-auth-client-contract) | You care about API shape and family consistency |
| [4. Use cases](#4-use-cases) | **Start here.** This is the spine of the document |
| [5. Session model](#5-session-model) | You want to know what a "session" is |
| [6. Storage model](#6-storage-model) | You are implementing persistence |
| [7. Credential providers](#7-credential-providers) | You are wiring another client to a session |
| [8. Events](#8-events) | You subscribe to auth events |
| [9. Hosted UI](#9-hosted-ui-browser-based-sign-in) | Your app uses browser sign-in |
| [10. Alternative considered](#10-alternative-considered-one-active-session-plus-a-stored-list) | You want the simpler option |
| [11. Limits](#11-limits) | You want to know what this declines to do |
| [12. Decisions](#12-decisions) | You are reviewing scope |
| [13. Concerns](#13-concerns) | You want the problem we found while validating |
| [14. API surface](#14-api-surface) | You want to see the actual API |
| [15. Notes and callouts](#15-notes-and-callouts-optional-reading) | Optional. Lifecycle detail, the credential provider contract and logging |
| [Appendix A](#appendix-a-swift-before-and-after) | You want concrete Swift, before and after |
| [Appendix B](#appendix-b-the-alternative-in-full) | You are weighing the other design in depth |
| [Appendix C](#appendix-c-investigation-notes-and-evidence) | You want the evidence behind the claims |
| [Appendix D](#appendix-d-client-family-conventions-and-construction-reference) | You are implementing and want the checklist |
| [Appendix E](#appendix-e-android-prerequisites-for-later-discussion) | You are picking up the two Android prerequisites left for later discussion |

## Terminology

Three words carry the design.

| Term | Meaning |
|---|---|
| **Session** | One signed-in (or guest, or federated) identity plus its credentials. The thing this design lets you have more than one of. |
| **Session ID** | The identifier a session is saved under. App-chosen (`"work"`) or library-minted. |
| **Auth Client** | A live `AmplifyCognitoClient` object: a handle to one session. Two Auth Clients built with the same session ID are two handles onto the same session. "Auth Client" stays the prose term for the concept; `AmplifyCognitoClient` is the type. |

Other terms used below, one line each:

| Term | Meaning |
|---|---|
| **Engine** | The Cognito logic (SRP, MFA, refresh, hosted UI, WebAuthn) that the plugin and the client both run: the `InternalAWSCognitoAuth` module. |
| **Session core** | The one object (`SessionCore`) that holds a live session's state in a process. Every handle on that session shares it. |
| **Sidecar** | A small client item beside the plugin's record (`amplify.1.<ns>.$default.meta`) that holds what the plugin's format has no room for: `.default`'s label and last user. |
| **Principal** | Who a saved record belongs to: a user (the `sub`, else the username) or, with no user, a guest's or federated identity's identity ID. |
| **Commit guard** | A write that succeeds only if the stored record has not changed since it was read: by generation for a named session, by the stored bytes for `.default`. |
| **Gate** | The lock (`SessionRecordGate`) that runs one session record's operations one at a time: restore, refresh, sign-out, label, purge. |
| **Carry** | Copying a session's login to the new configuration's record when the configuration changes, keeping the old record. "Carried forward" means the same. |
| **Namespace marker** | A named session's per-app note (`amplify.1.<sessionId>.<app>.configuration`) of the configuration it was last kept under, and the copies a carry left, so the next restore knows where to carry from. |
| **Bridge** | The plugin using the client internally for the default session (§4.9). Not built. |
| **Golden** | A recorded fixture (stored format, errors, logs, keychain queries, configuration) that a test compares byte for byte, to prove the plugin's behaviour has not changed. |

## 1. Goals

Being clear about motivation matters, because it determines what "done" means.

1. **Move auth off the plugin architecture** - the primary goal, and the one that puts this document in a series. Kinesis, Firehose, Connect, EventEnrichment and CloudWatch Logging already ship as standalone clients that need no `Amplify.configure()` and no plugin registry. Auth is the largest remaining category, and the one every other client needs for credentials.

2. **Enable concurrent sessions** - a real goal, not a side effect. Session IDs, listing saved sessions, and per-instance events exist only for it.** The current plugin supports one session at a time.** A second sign-in is not merely unimplemented - it is deliberately refused, with a clear error and a recovery suggestion. In Swift the caller gets: `"There is already a user in signedIn state. SignOut the user first before calling signIn"` Android and Flutter refuse it too, equally deliberately.

## 2. What this design is not

**Not a removal of the plugin.** This design deletes nothing: the auth plugin keeps working, and category consumers (API, Storage, DataStore) are unaffected. What it adds is the standalone Auth Client that new code, and the other standalone clients, can build on.

## 3. The Auth Client contract

Standalone clients are the established Amplify pattern: self-contained libraries an app uses directly, with no `Amplify.configure()` and no plugin registry, depending only on the shared foundation packages. Several already ship this way, and the Auth Client takes a specific lesson from each:

| Client | What the Auth Client takes from it |
|---|---|
| **Kinesis**, **Firehose** | The construction shape: a `Configuration` value loadable from `amplify_outputs.json`, an `Options` struct with defaults, and a synchronous throwing `init`. |
| **Connect** | The convenience overloads, and the proof that two instances of one client can coexist in a process. |
| **EventEnrichment** | Actor-internals-with-a-plain-facade, and the naming conventions. |
| **CloudWatch Logging** | How to coexist with an existing plugin: extract the shared core into an internal module, leave the plugin working over it, ship the client behind an experimental flag. |

Construction is therefore the family's shape, unchanged - precisely what the Kinesis and Firehose row above describes. The declaration itself is in **14.1**, with the rest of the API surface.

**What that looks like at a call site**, to set the preface for everything below - construction is the whole setup step, and holding two is the design in one line:

```swift
// The single-account case. No Amplify.configure(), no plugin registration.
let client = try AmplifyCognitoClient(from: "amplify_outputs")

// Two sessions is the same call twice, with a session ID each. Nothing global
// changes, and neither handle can be mistaken for the other.
let config = try AuthClientConfiguration(from: "amplify_outputs")
let work = try AmplifyCognitoClient(configuration: config,
                                    options: .init(sessionId: .named("work")))
let home = try AmplifyCognitoClient(configuration: config,
                                    options: .init(sessionId: .named("home")))


// fetching sessions
let workSession = try await work.fetchAuthSession()
let homeSession = try await home.fetchAuthSession()
```

One deliberate difference: **auth takes no `credentialsProvider`, because auth is what produces one.** Every other client consumes credentials; auth sits at the root of that graph and vends providers to the rest. That is the only place the Auth Client differs from the family's parameter list, and it is inherent rather than a deviation. The rest of the family checklist - actors, strict concurrency, error protocol, escape hatches, privacy manifest - is adopted as-is and listed in Appendix D.

**How the plugin and the Auth Client coexist:** two top layers over one shared core, following the CloudWatch Logging recipe in the table above.

> **As of 2026-10-02:**
> - **At rest, they share one saved login.** The default session reads and writes the plugin's own keychain item (§4.8, §6).
> - **In one process, over the default session, side by side is not supported.** The plugin keeps its tokens in memory, so with refresh-token rotation on a refresh by one side can break the other's token until relaunch.
> - **The bridge, in which the plugin delegates to the client's session core, is not built** (§4.9).

## 4. Use cases

**Who would want this.** Multi-account is ordinary in shipped software, and the pattern is consistent: the app shows a list of accounts, you pick one, and you are not asked to re-authenticate.

**A customer has asked for this.** Beyond that, runtime reconfiguration and multi-account are among the most-requested open items across Amplify: `amplify-swift#1584` (open since 2022, 70 👍), `amplify-flutter#1902` (23 👍, a maintainer confirming in 2026 that it is "actively being worked on"), and `amplify-android#560` (17 👍, a maintainer calling it "a commonly requested feature"). Customers in those threads describe exactly this shape — one account per country in a single app, siloed multi-tenancy, and separate EU/US identities for data-residency. Note the honest distinction: that demand is stated as multi-*configuration*; concurrent multi-*session* is our inference from it. The remaining examples below are still illustrative rather than requested:

- **Slack** - one app, many workspaces, with a workspace switcher. You stay signed into all of them.

- **Gmail and Google** - an account picker, with several accounts signed in at once.

- **Microsoft Teams and Outlook** - work and personal accounts side by side.

- **GitHub and the AWS console** - profile or role switching without a full re-login.

The Amplify-shaped equivalents would be:

- **Multi-tenant apps** where a user legitimately holds accounts in several organisations - a consultant working across client orgs, an agency across brands.

- **Field and logistics apps** - a delivery driver signing in across depots, staff across store locations.

- **Shared devices** - a tablet in a clinic or on a shop floor where several staff use one device in a shift and re-authenticating each time is friction.

The design exists to serve these, and the rest of this section takes them one at a time. Each one states the user-visible story, what the app does, and the new API it introduces. Appendix A shows the same shift as before-and-after Swift, if you would rather read it that way first.

### 4.1 Two users signed in at once

*A field consultant is signed into their own org and a client's org, and moves between them without re-authenticating.*

The app holds two Auth Clients. Each signs in independently; both stay live; neither disturbs the other.

```swift
// Ordinary construction. Same shape as every other standalone client.
let work = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: .named("work")))
let home = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: .named("home")))

try await work.signIn(username: "alice@corp",     password: pw1)
try await home.signIn(username: "alice@personal", password: pw2)

try await work.getCurrentUser()   // alice@corp
try await home.getCurrentUser()   // alice@personal
```

**New API:** `AmplifyCognitoClient.init(configuration:options:)` and `Options.sessionId`. The session ID is the only thing that distinguishes these two clients, which is why it is a construction parameter rather than something you set later - an Auth Client is never briefly pointed at the wrong session. Declared in 14.1.

#### 4.1.1 Where the single-session limit lives

The limit is *not* in the Cognito flow logic. Today a session is saved under a key built only from Cognito pool IDs, so it cannot say *who* is inside. Section 6 sets out that key, before and after.

Two users signing in on the same pool produce the *same* key today, so the second sign-in has nowhere to go except on top of the first. Adding the session ID to the key is the change. On all three platforms the state machine is already an ordinary object you can instantiate, with no static session state anywhere - Swift and Android constructs one per `configure()`, Flutter holds one as a plain instance field, and Flutter's tests build them standalone.

It is imposed from above and below. Above, the plugin registry admits exactly one auth plugin per process, and every consumer reaches it through a global. Below, it is the storage key.

So the work is: **give sessions an ID, and let consumers hold a reference instead of reaching for a global.** Neither half requires rewriting the Cognito flow logic, which is why this is a tractable change rather than a rewrite.

### 4.2 Account picker on cold launch

*The app relaunches and shows "who do you want to continue as?", with no network call and no spinner.*

The app lists the saved sessions, renders a row each, and resumes the one the user taps. Each row renders from data already in the saved record.

```swift
// No network. Throws rather than returning [] if storage is unreadable.
let rows = try await AmplifyCognitoClient.storedSessions(configuration: config)
//  -> [ StoredSession(sessionId: "work", label: "Acme Corp", username: "alice@corp",     kind: .userPoolAndIdentityPool),
//       StoredSession(sessionId: "home", label: nil,         username: "alice@personal", kind: .userPoolAndIdentityPool) ]

let client = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: rows[0].sessionId))

switch await client.currentSessionState() {
case .unavailable:                 waitForUnlock()   // storage locked, NOT "no session"
case .failed:                      showSignIn()
case .awaitingChallenge(let step): resume(step)      // a sign-in was interrupted
case .signedIn:
    // The saved record said "signed in". A session read is what confirms it still
    // works, refreshing expired tokens as part of the call.
    do { _ = try await client.fetchAuthSession(); showHome() }
    catch AuthClientError.storageUnavailable { waitForUnlock() }   // NOT signed out
    catch { showSignIn() }                                         // refresh token dead
case .guest, .signedOut:
    // This app offers sign-in for both. 4.10 shows one that browses as a guest
    // instead - the difference between the two states is a UI decision. See 14.2.
    showSignIn()
}
```

**New API:** `AmplifyCognitoClient.storedSessions(configuration:)`, the `StoredSession` row type, and `currentSessionState()`. `storedSessions` is static because a picker has to render before any session is chosen, so there is no Auth Client to call it on yet. Declared in 14.3 (`storedSessions`), 14.6 (`StoredSession`) and 14.2 (`currentSessionState()`).

**What a row can and cannot tell you.** A row tells you a session was saved and who it belonged to. **It cannot tell you the session still works.** Access- and id-token expiry can be checked offline, but refresh-token expiry cannot: the refresh token is never parsed.

**Refresh happens on use, and only on use.** Listing never refreshes and never makes a network call. Reading a session refreshes expired tokens as part of the call, exactly as the plugin does today. There is no background timer and no refresh of sessions you are not using. If the refresh token has expired or been revoked, that call surfaces `sessionExpired` and the app sends the user to sign-in for that session only. The others are untouched.

**Storage-unavailable is not "no sessions."** On a locked device the read can fail transiently, so listing must distinguish "no sessions" from "cannot read sessions" and the app must wait rather than offer sign-in. Returning an empty list would show a sign-in screen to a signed-in user.

### 4.3 An app resuming with several saved sessions

*A consultant's app has five orgs saved. On launch it shows a picker, and the last-used one is preselected.*

This is 4.2 at realistic scale, and it answers a practical question: **the app does not have to remember any session IDs.** Listing returns them. The only thing worth persisting is which one was last used, and that is an ordinary user preference rather than auth state.

```swift
func showAccountPicker() async throws {
    // 1. Everything saved on this device. No network, no Auth Clients constructed yet.
    let saved = try await AmplifyCognitoClient.storedSessions(configuration: config)

    // 2. Render rows straight from the saved data. Prefer the app's label, fall back
    //    to the username, fall back to the session ID, which always exists.
    let rows = saved.map { session in
        AccountRow(id: session.sessionId,
                   title: session.label ?? session.username ?? session.sessionId.stringValue,
                   isGuest: session.kind == .guest)
    }

    // 3. Preselect whatever was used last. An app preference, not auth state.
    let preferred = UserDefaults.standard.string(forKey: "lastUsedSession")
    present(rows, preselecting: preferred)
}

func userTapped(_ id: SessionID) async throws {
    // 4. Construct just the one they picked. Five saved sessions do not mean five
    //    live Auth Clients, because listing is a storage read.
    let client = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: id))

    switch await client.currentSessionState() {
    case .unavailable:                 showTryAgain()                // do NOT offer sign-in
    case .awaitingChallenge(let step): resume(step, using: client)
    case .signedIn:
        do {
            _ = try await client.fetchAuthSession()   // confirms it still works
            UserDefaults.standard.set(id.stringValue, forKey: "lastUsedSession")
            showHome(using: client)
        } catch AuthClientError.storageUnavailable {
            showTryAgain()            // transient; do NOT offer sign-in
        } catch {
            showSignIn(reusing: id)   // refresh token died while the app was closed
        }
    default:
        showSignIn(reusing: id)
    }
}
```

**New API:** `SessionID.stringValue` and `SessionID: Codable`. Both exist so an app can persist a session ID in its own storage and construct the same session directly next launch, without listing first. Declared in 14.6.

**Removing a row from the picker** is `purgeStoredSession(sessionId:configuration:)`, also static and also without a network call - the counterpart to the listing above, for the "remove this account" affordance every picker needs. It is local-only, so prefer `signOutStoredSession` where reaching Cognito is acceptable. Both in 14.3.

### 4.4 Guest browsing, then signing in

*A shopper browses anonymously, adds to a cart, then signs in.*

This is one session moving through its own lifecycle, and it needs no new concept. A fresh Auth Client starts with no credentials; the first `fetchAuthSession()` on a session with no signed-in user mints guest credentials and establishes a guest session; signing in takes over the same session. Sign out and it is signed out again - and becomes a guest once more only when something explicitly fetches guest credentials that way, not the instant sign-out returns.

```swift
let client = try AmplifyCognitoClient(configuration: config)   // default session ID
let feed = try await loadPublicFeed(using: client.credentialsProvider)

try await client.signIn(username: entered, password: pw)    // same session, now signed in
```

**New API:** none. `SessionID.default` is what an omitted `sessionId` resolves to, and it is a stable value, so this is the single-account case with no session-ID thinking required at all.

#### Holding a guest session and a signed-in user at once

A different request from the flow above, and the answer is short: **that is two sessions, so it is two session IDs.** Nothing special is required. A guest session is saved under its own ID like any other, and gets its own identity.

**Can several sessions be guests at the same time?** Yes, and it is a legitimate state: nothing in the design limits how many session IDs are guests at once. They are distinguished the same way any other sessions are: by session ID, and by the `label` the app sets. A picker row falls back through label, then username, then session ID, so guest rows are never an indistinguishable pile of "Guest". If an app does not *want* several guest sessions, it does not create them: a guest session only comes into existence when the app constructs an Auth Client with a new session ID and makes an unauthenticated call. The default session ID makes the common case a single one automatically.

### 4.5 Wiring a downstream client to a specific user

*Two accounts are live, and work done for each must be attributed to the right one.*

This is the payoff, and the target shape already ships in the newer clients: they take a credential provider at construction.

```swift
// Two Connect clients, same region, two different users. Each holds its own
// session and signs with its own credentials.
let workConnect = AmplifyConnectClient(configuration: connectConfig,
                                       credentialsProvider: work.credentialsProvider)
let homeConnect = AmplifyConnectClient(configuration: connectConfig,
                                       credentialsProvider: home.credentialsProvider)
```

`work.credentialsProvider` resolves `work`'s session, always. There is no ambient lookup, so which user a consumer acts as is fixed, visibly, at construction. Contrast today, where a consumer asks a global "who is signed in right now?" on every call, and therefore silently follows whoever that happens to be.

**New API:** `credentialsProvider` on the Auth Client. It is a property rather than a method because it must be handed over once, at another client's construction, and then resolve through the live session on every later call. Declared in 14.4.

Connect is used in this example rather than Kinesis for a reason that is a genuine concern in its own right; see 13.1.

### 4.6 Adding an account while already signed in

*The user is signed in as Alice, taps "Add account", and signs in as Bob, without losing Alice.*

The most common multi-account flow, and the one that forces a real design question: **the app must name the session before it knows who will occupy it.** So the library mints the ID and hands it back, and the app may attach a display label afterwards.

```swift
// The library mints the ID; the app does not have to invent or remember one.
let added = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: .new()))
try await added.signIn(username: entered, password: pw)   // the session is saved here, not before
try await added.setSessionLabel("Acme Corp")              // optional; see below

added.sessionId   // the durable handle, if the app wants to deep-link into this session
```

**New API:** `SessionID.new()`, `SessionID.named(_:)`, and `setSessionLabel(_:)`. `new()` exists because of the ordering problem above. `setSessionLabel` is separate from construction because the label is usually only knowable after sign-in has told you which tenant you got. Declared in 14.6 (`SessionID`) and 14.3 (`setSessionLabel`).

Note what this rules out: **keying a session by user id cannot work**, because there is no user id until sign-in succeeds, and the session must exist in memory before that. This is why a session ID is an opaque identifier chosen by the app or minted by the library, never derived from an identity.

**What `setSessionLabel` is for.** It is display text for a picker row, chosen by the app, and it exists because the library cannot invent it. The library knows the username (`alice@corp`) and the user id (a UUID). Neither is what a user recognises: in a multi-tenant app the same person may hold two accounts whose usernames are identical apart from the tenant, and a picker showing `alice@corp` twice is useless. The app knows the tenant name, the workspace, the store number. Slack shows workspace names, not email addresses. `setSessionLabel` is where that goes, so it can be read back later without the app maintaining its own ID-to-name map. It is deliberately one string rather than a `tags` dictionary with a predicate query: richer metadata and a `findStoredSessions(where:)` lookup are both purely additive later, so nothing is foreclosed by starting simple.

**Choosing an ID yourself versus letting the library mint one.** Both are supported, and the choice is whether the app has a stable identifier for the session:

- **Mint one (`.new()`)** for open-ended multi-account, where the app cannot know in advance who or how many. Listing gives them back later, so nothing needs to be remembered.

- **Name it (`.named("work")`)** when the app has its own stable identifier - a tenant id, a workspace id, a store number. Then the app can construct the same session directly on launch without listing first, which is useful for deep links.

- **Omit it** and you get `.default`, a stable ID that resumes the same session every launch. This is the single-account case and it needs no thought.

### 4.7 Sign-out variants

*Signing out of the work account leaves the personal account untouched.*

```swift
// Revokes tokens and clears credentials, but KEEPS work's saved row, so a picker can
// still show it as signed-out-and-resumable. home is untouched and still signed in.
// Sign-out does not throw: it returns .complete, .partial(...) or .failed(error).
let result = await work.signOut()
if !result.signedOutLocally { showRetry() }   // .failed: the session is still signed in
try await home.getCurrentUser()   // still alice@personal

// Sign out AND forget the row, in one call. Opt-in, because deleting is not recoverable.
await work.signOut(options: .init(purgeStoredSession: true))

// Signing out a session the app is not currently holding, straight from the picker.
// named(_:) throws for an invalid ID, so it needs `try`.
let workID = try SessionID.named("work")
await AmplifyCognitoClient.signOutStoredSession(sessionId: workID, configuration: config)

// Removing a saved row entirely, without contacting Cognito. The refresh token stays
// valid server-side until it expires, so prefer signOutStoredSession where you can.
try await AmplifyCognitoClient.purgeStoredSession(sessionId: workID, configuration: config)
```

**New API:** `signOut(options:)` with `AuthClientSignOutOptions.purgeStoredSession` (default `false`), plus the statics `signOutStoredSession(sessionId:configuration:)` and `purgeStoredSession(sessionId:configuration:)`. The statics take a session ID because a picker needs to offer "sign out" or "remove" on a row without first constructing a client for it, and they are named apart because only one of them revokes anything. All declared in 14.3.

**Sign-out keeps the row by default; purging is opt-in.** Deleting a saved record is not recoverable, so the non-destructive behaviour is the default on every path.

**The result takes the plugin's shape.** The type is `AuthClientSignOutResult` (`Sources/Models/AuthClientSignOutResult.swift`).

- **No sign-out throws.** `signOut(options:)`, `signOut(presentationAnchor:options:)` and `signOutStoredSession` return `.complete`, `.partial(revokeTokenError:globalSignOutError:hostedUIError:storageError:)` or `.failed(AuthClientError)`. `signedOutLocally` is false only for `.failed`.
- **Another sign-in replacing the session during the sign-out is `.failed(.invalidState(…))`**, and that user stays signed in.
- **These also return `.failed`**, with the session still signed in on this device:
  - a storage failure before the local sign-out, or a saved record that kept changing (`storageUnavailable(.interrupted)`). A revoke may already have run;
  - `sessionConfigurationMismatch`, and any other error before anything was revoked;
  - a closed hosted-UI sign-out page, as `.failed(.userCancelled)`. One exception: if the session's refresh token was already dead, it signs out anyway and reports `.partial(hostedUIError: .userCancelled)`;
  - a hosted-UI sign-out with no hosted-UI configuration or no sign-out redirect URI, as the plugin returns it. It is one `configuration` error whether the client or the engine finds it, with the engine's error underneath;
  - any other hosted-UI sign-out page that could not be shown or completed: another sheet holds the browser (`browserBusy`), the window has gone (`validation`), or the browser's own failure. As with the two cases above, nothing is revoked;
  - task cancellation before anything was revoked, as `.failed(.unknown("The sign-out was cancelled before anything was revoked; the session is still signed in.", "Retry the sign-out.", CancellationError()))`.
- **A purge that fails after the local sign-out succeeded returns `.partial`** with the client-only `storageError` field set, and `signedOutLocally == true`. The session is signed out; its saved row may still be listed.
- **Once a revoke has completed, cancellation never stops the local clear.**
- **A failed global sign-out reports the plugin's placeholder `revokeTokenError`**. As in the plugin, `RevokeToken` is then skipped, and `.partial` carries the global sign-out's error and the placeholder revoke error.
- **Deliberate differences from the plugin, documented:**
  - `.partial` carries no raw tokens (a security fix);
  - `.partial` has the client-only `storageError`;
  - a federated session can be signed out (the plugin refuses);
  - `purgeStoredSession`;
  - the window is required for the hosted-UI sign-out page (the plugin falls back to one of its own). Without one (`signOut(options:)`, `signOutStoredSession`), the session is signed out on this device, the browser keeps its cookie, and `.partial(hostedUIError: .validation(…))` says so.

For example, an app that offers a retry only when the user is still signed in:

```swift
// The window overload is main-actor isolated, so call it from main-actor code (a view or view model).
@MainActor
func signOutOfWork(_ work: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async {
    switch await work.signOut(presentationAnchor: window) {
    case .complete:
        showSignedOut()
    case .partial(_, _, let hostedUIError, _):
        showSignedOut()                       // signed out here; some server-side step failed
        if hostedUIError != nil { remindToUsePromptLogin() }
    case .failed(let error):
        showRetry(error)                      // still signed in on this device
    @unknown default:
        showSignedOut()
    }
}
```

The declaration is in 14.8.

**Deliberately out of scope: there is no "sign out of all sessions".** An app that wants it loops over `storedSessions()`. We are not shipping a bulk operation in this revision — the precedents are uniformly bad (`aws sso logout` prints *"Successfully signed out of all SSO profiles"*; MSAL documents `wipeAccount` as *"a dangerous operation"*; Auth0's `clearAll()` warns it *"may delete non-Auth0 data as well"*), and doing it safely needs per-session result reporting that `AuthClientSignOutResult` cannot currently express. Noted in §11 so its absence reads as a decision rather than an oversight.

Two caveats the design must state plainly:

- **Global sign-out crosses sessions**, unavoidably. It is a server-side revocation scoped to a *user*, so if two sessions hold the same human, revoking one kills both. Session isolation is client-side; it cannot override a server-side revocation.

- **The other session finds out late.** Because events are per Auth Client, a sibling whose tokens were revoked elsewhere discovers it on its next refresh, as a session-expired condition.

### 4.8 Migrating an existing app

*An app that ships the plugin today adopts the Auth Client, and users do not notice.*

**The default session is the plugin's saved login** (`SessionRecordStore+DefaultSession.swift`). `SessionID.default` reads and writes the plugin's own keychain item:

- service `com.amplify.awsCognitoAuthPlugin`, or `com.amplify.awsCognitoAuthPluginShared` with an access group;
- account `amplify.<poolNamespace>.session`;
- payload the plugin's `AmplifyCredentials` JSON, as the plugin writes it.

So there is nothing to adopt and nothing to take over. An app that moves from the plugin to the client keeps its user, because both read the same item. An app that moves back keeps it for the same reason.

```swift
// No migration step. The default session is the plugin's saved login.
let migrated = try AmplifyCognitoClient(configuration: config)   // sessionId: .default
```

- **What the plugin's record cannot hold goes in a sidecar** (§6): the display label, and the last signed-in user's username and user ID for the signed-out picker row.
- **Sign-out of `.default`** revokes, writes the sidecar for the signed-out row (the last user and the label), then writes the plugin's signed-out value, `{"noCredentials":{}}`, through the commit guard. Every plugin release reads that value as signed out. **Purge** deletes the record, then the sidecar, then the challenge record.
- **A sign-out by the plugin is seen by the client.** Say the client holds alice, and the plugin signs out (or deletes its record). The client's next guarded write, a refresh say, is discarded, because the stored bytes changed. The re-read finds the plugin's signed-out value, or no record, so the session becomes `.signedOut`, listed as the sidecar's signed-out row naming alice. The client never writes alice's record back.
- **A plugin `deleteUser` leaves the sidecar.** The plugin deletes its own record and does not know the sidecar, so the deleted user can show as a signed-out picker row (its last username and label) until the client writes the session again: a sign-in through the client, or a client refresh of another user the plugin signed in. A sign-in through the plugin doesn't replace it. This is documented.
- **Named sessions never touch the plugin's item.** They keep the client's own records (§6).

**Removed from the design, all unreleased:**

- read-through, and `completeAdoption()`;
- the side-by-side check at first load;
- read-through reconciliation;
- the plugin's forward-compatible reader and its signed-out marker;
- the rule that the plugin's reader must ship before the client.

Development builds wrote `amplify.1.<ns>.$default.session` records. They exist only on development and sandbox devices. Listing ignores them (§6), so they never show as a ghost row.

**What the client does not do: the plugin's migrations.** The plugin runs the AWSMobileClient legacy migration and the access-group migration at configure. The client does neither, so a client-only app gets no AWSMobileClient migration and no access-group migration. The plugin's access-group migration moves `.default`'s sidecar and challenge record (`amplify.1.<ns>.$default.meta` and `.challenge`) with its own record, because they now belong to the plugin's session. For the same reason, the migration's destination clear and a transition wipe without migration remove them, and the check "does the shared service already hold the plugin's items?" ignores them, so they alone never block a migration. It still leaves named sessions where they are.

**Release order: the scoped wipe ships first.** The plugin's scoped wipe ships in a plugin release before the client writes records. Named sessions, the sidecar and the challenge record live in the plugin's keychain service, and a released plugin's access-group transition wipes the whole service. The rule removed above is a different one: that the plugin's forward-compatible *reader* ship first.

**A configuration change** on `.default` follows the plugin's rule, and the client writes the plugin's `authConfiguration` item (§6). When only the app client changes, nothing is deleted: the key holds the pool IDs and no client ID, so the record stays where it is, and its next refresh gives `sessionExpired`, as in the plugin. A login deleted because the key changed is revoked when its user pool is the same, with the old app client ID that `authConfiguration` records. Otherwise, or if that revoke fails, its refresh token stays valid until it expires.

#### Rolling back and forward

Each row is pinned by a test in both rollback matrices (`RollbackMatrixPluginTests` and `RollbackMatrixClientTests`), named in brackets. They run the client, the current plugin store and a view of the released plugin (2.62.0, which knows no `amplify.<digits>.` item) over one keychain.

| Case | What happens |
|---|---|
| Back to a plugin-only release, 2.51.0 or later | The plugin reads its own key, which holds the newest saved login, including a refresh token the client rotated: its refresh sends that token and succeeds (`testMatrix_rotationRollback_isNowSignedIn`). A client sign-in is seen by the plugin (`testMatrix_clientSignIn_isSeenByThePlugin`) |
| A user signed out through the client, then a rollback | **Stays signed out**, because the record holds `{"noCredentials":{}}`, which every plugin release reads as signed out (`testMatrix_clientSignOut_readByEveryPluginAsSignedOut`). That holds on a build with the earlier configuration too, even when its key still holds a copy an earlier carry left: that build's own rule carries the signed-out record over the copy (`testMatrix_signedOutUserIsNeverSignedBackIn`). It does not hold for a later change the rule does not carry that lands on an earlier configuration's key: the rule deletes the signed-out record, and that key's old copy restores the user signed in, as with the plugin. One caveat for guests: after a rollback, a plugin build with an identity pool that allows guests may start a guest session in the shared login on its first `fetchAuthSession`, as it does after its own sign-out. The guest then replaces the signed-out row. It is never the old user |
| A purge, or the plugin's own sign-out, after a configuration carry, then a rollback to the build with the earlier configuration | **Caveat: that build signs the user back in.** A carry copies and keeps the source (the plugin's rule). A purge deletes only the current configuration's record, and the plugin's own sign-out deletes its record the same way, so the earlier configuration's copy survives and that build reads it (`testMatrix_purgeAfterACarry_leavesTheEarlierConfigurationsCopy_caveat`). So a **sign-out through the client**, which writes `noCredentials` instead of deleting, survives this rollback; only a later change onto an earlier configuration's copy undoes it (the row above) |
| Back to a plugin older than 2.51.0, with refresh-token rotation on | The plugin cannot refresh, whatever the client did: it refreshes with `REFRESH_TOKEN_AUTH`, which Cognito refuses on a rotation client. Without rotation, as the first row |
| Back to a plugin-only release, with named sessions | **Named sessions disappear**, because the plugin never reads `amplify.1.` records. They stay in the keychain and **come back on roll-forward**. A released plugin's access-group transition wipes the whole service, client records included; the current plugin's scoped wipe spares them. The scoped wipe ships before the client writes records (`testMatrix_namedSessionsDisappearOnRollbackAndReturnOnRollForward`) |
| A newer build's sidecar (`schemaVersion` 2) | Shown as absent (no label), never overwritten or deleted, except by a purge; the session itself still signs in, refreshes and signs out (`testMatrix_newerSchemaSidecar_isLeftAlone`) |
| Back to the plugin after a configuration change, built with the same configuration | Safe. The client wrote the plugin's `authConfiguration` item, so a rolled-back plugin built with the configuration the client last used sees no change, and does not copy an older record over the newer login (`testMatrix_configurationChangeThenPluginRollback_noStaleOverwrite`) |
| Back to a plugin build that carries the **old** configuration, after the client wrote a newer `authConfiguration` | The plugin sees a change from the client's configuration to its own, and runs its own rule. On a change it carries, it copies the newer login to the old key (`_set`), so the newest login wins. On a change it does not carry, it deletes the newer login and reads what its own key still holds: for the reverse of an added user pool, the guest the earlier carry kept there. It never writes an older copy over the newer login (`testMatrix_pluginBuildWithTheOldConfiguration_runsItsOwnRuleAfterTheClient`) |
| Forward from the plugin to the client | `.default` reads the plugin's record in place. A token the plugin rotated is already in it, so the client refreshes with the newest token and there is no dead refresh token at rest (`testMatrix_rollForwardAfterAPluginRotation_resumesOnTheNewestToken`, replacing the old matrix row 9). A plugin sign-out is seen by the client (`testMatrix_oldPluginSignOut_isSeenByTheClient`) |
| An app extension on the plugin and the app on the client, at rest | Each sees the other's latest login after a relaunch (`testMatrix_mixedBinaries_extensionOnThePluginAppOnTheClient_atRest`) |
| The plugin and the client in one process, over `.default` | Not supported (§4.9). The plugin keeps its tokens in memory, so with rotation on a refresh by one side can break the other's token until relaunch |
| A client-only app upgraded from AWSMobileClient, or changing its access group | No migration. That is the plugin's job |

The bytes the client writes (each `AmplifyCredentials` shape, `noCredentials` and `authConfiguration`) decode with the released plugin's own types, and the client's items have the plugin's keychain attributes (`KeychainAttributeParityTests`).

This solves rollback with rotation, and rollback past the reader, for the default session. The in-process rotation case, the plugin and the client together in one process, is not solved: running both there is not supported (§4.9).

### 4.9 Plugin and Auth Client side by side

*A large app migrates gradually: existing screens use the categories, new features use the Auth Client.*

> **Revised 2026-10-02.** The previous revision described the bridge, the plugin owning a client and delegating to it, in the present tense. It is not built.

**Shared at rest; in one process, over the default session, not supported.**

- **At rest, one saved login.** The default session reads and writes the plugin's own item (§4.8, §6). There is no second login to fall out of sync, and either side can be rolled back to the other.
- **In one process, two in-memory states.** The plugin reads the keychain only at configure, and on `fetchAuthSession` when an access group is set. Otherwise it keeps its tokens in memory. With refresh-token rotation on, a refresh by one side can break the other's in-memory token until the app relaunches. So running both over the default session in one process is not supported.
- **Named sessions are unaffected.** The plugin never reads them.
- **A temporary warning.** When `.default` re-reads the shared record and finds a **different principal** from the one it holds in memory, it logs one warning, naming no one. That happens when another writer, such as the plugin, signed someone else in, or a guest. As built (`SessionCore+SharedRecordWarning.swift`):
  - **A principal** is a user (the `sub`, else the username) or, with no user, an identity ID: a guest's or a federated identity's. So it warns for another user, a guest over a user, a user over a guest in memory, and another guest or federated identity ID. It is silent for a signed-out or absent record, the same user refreshed, and the same guest with new credentials.
  - **Every read of the shared record under the session's gate counts**, not only the refresh: a discarded write's re-read, sign-out's re-checks, setting the label, deleting the user, purging and clearing federation.
  - **Logged once while the session is in memory.** All handles share it; after every handle and provider is released, a new handle can log it again. (Every handle of `.default` in a process shares one session core, which holds the flag.) It logs at `warn`, under `AmplifyCognitoClient.DefaultSession`.
  - **Named sessions never log it.**

  The text is: "The default session's saved login now holds a different user or a guest than this client held. The Auth plugin may be running beside this client over the default session, which is not supported." The `DefaultSession` category also carries other `.default` warnings (§15.3).
- Categories continue resolving through the global, so from the categories' point of view the setup is still single-user; extra sessions remain visible only to code the app wired explicitly.

**New API:** none.

### 4.10 Reading a session's state

*A picker row has to render the right thing, and a screen has to decide between a sign-in form and the signed-in view - without a network call.*

**We already have a way to ask this, and the Auth Client keeps it.** Today an app calls `fetchAuthSession()` and reads `isSignedIn`, and a multi-step sign-in reports progress through `AuthSignInResult.nextStep` (an `AuthSignInStep`). That is the whole public surface today, and it is close to sufficient. Only two things are genuinely missing, and both are worth fixing on their own merits:

- **A storage failure is indistinguishable from being signed out.** Today a keychain read failure at startup is caught, logged, and coerced to "no credentials", which resolves to signed-out - so an app can show a sign-in screen to a signed-in user.

- **A guest session is indistinguishable from a signed-out one** by `isSignedIn` alone, and a picker needs to tell them apart.

So the type is deliberately small, and it reuses the existing types like `AuthSignInStep`. It is declared in 14.2, alongside the calls that return it.

**Grabbing it, and using it.** Read it once for a decision the app makes now, or follow it for UI that has to re-render when the session changes underneath it:

```swift
// Read it once. Every case here is a different thing to put on screen.
switch await client.currentSessionState() {
case .signedIn(let user):          show(signedInView(for: user))
case .guest:                       show(browseAsGuestView())
case .signedOut:                   show(signInForm())
case .awaitingChallenge(let step): presentChallengePrompt(for: step)   // see 4.11
case .unavailable(let reason):     show(retryView(reason))  // NOT a sign-in form
case .failed(let error):           show(configurationError(error))
}

// Or follow it. One stream per session, so a picker row updates itself when
// that row's session expires - and no other row moves.
for await state in client.listenToSessionStateChanges() {
    accountRow.render(state)
}
```

**There is no in-flight dimension in this type, on purpose.** With async/await, "is a sign-in running?" is answered by the fact that your own `await` has not returned yet.

**New API:** `currentSessionState()` returning `AuthSessionState`, and `listenToSessionStateChanges()` for updates.

### 4.11 Resuming an interrupted sign-in

*A user leaves the app to fetch a code from their authenticator, the OS reclaims it, and they come back to a form that has forgotten everything.*

**This is a proposed new feature: no platform's plugin does it today.** Today, if the app is killed while sitting on an MFA prompt, the user starts sign-in over. We want to fix that.

The user-visible case is specific and common: they switch to their authenticator app or wait for an SMS, the OS reclaims the app, and they come back to a reset form.

**The plan.** Persist the in-flight challenge - the Cognito session string, the challenge type and parameters, and the resolved `AuthSignInStep` - when a session enters a challenge state, and delete it on success, on failure, or when a fresh `signIn` supersedes it. There is no separate cancel call: abandoning the flow means starting sign-in over. It is scoped to the session ID like the session record itself, and it goes in the same protected, device-only storage as tokens, so it never syncs.

**The app decides whether to resume.** The Cognito challenge session's lifetime is a configurable backend property, and its expiry is neither exposed to the client nor derivable from the stored value. So the library does not try to predict it. On launch, a session with a stored challenge reports `.awaitingChallenge`, and the app chooses: present the prompt the user was on, or start sign-in over. If the app resumes and the challenge has in fact expired, the `confirmSignIn` call fails and the app handles that as an ordinary expected error - the library surfaces a typed `challengeExpired` so the app does not have to pattern-match a service message.

**As built (decided 2026-09-27).** The record is written when a sign-in step stops on a challenge, and it is removed when the engine's attempt ends. The rules are:

- **What is saved.** Every step `confirmSignIn` can answer is saved: MFA and OTP codes, a new password, a custom challenge, MFA and first-factor selection, and a password. **TOTP setup is saved too.** Its shared secret goes into the same device-only keychain storage.
  - `confirmSignUp` and `resetPassword` are not saved, because there is nothing to answer.
  - WebAuthn is not saved, because no attempt is kept.
  - Hosted UI is not saved, because it has no Cognito challenge.
- **Never stored.** The password, the `signIn` call's client metadata, SRP state and tokens are never stored.
- **Failures.** A wrong answer keeps the record. Only a final failure deletes it.
- **The 15-minute ceiling.** A record saved more than 15 minutes ago is deleted on read instead of resumed. 15 minutes is Cognito's longest `AuthSessionValidity`, so such a record is certainly dead. This is a bound, not a prediction: within it, the app still decides.
- **Leftover records.** A record found next to a signed-in or federated session is a leftover and is deleted. So is one this build cannot resume, and so are corrupt bytes. A record with a newer schema is left alone.
- **Unreadable storage.** For a signed-out, absent or guest session, a failed read fails the restore (`storageUnavailable`). A signed-in or federated session never reads its record to decide anything: a leftover there is read and deleted best effort, so an unreadable one cannot make the session unavailable.
- **Failed writes and deletes.** These are logged and never fail the sign-in.
- **Listing.** `storedSessions()` sweeps, best effort, this namespace's records that are past the ceiling. A session whose only record is a challenge is not listed.

The record and its lifecycle are implemented in `ChallengeRecord.swift` and `SessionRecordStore+Challenge.swift`
(`AmplifyClients/AmplifyCognitoClient/Sources/Storage/`).

```swift
let client = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: id))

if case .awaitingChallenge(let step) = await client.currentSessionState() {
    // The app's choice: resume, or call signIn again and start over.
    presentChallengePrompt(for: step)
    do    { try await client.confirmSignIn(challengeResponse: code) }
    catch AuthClientError.challengeExpired { restartSignIn() }
}
```

**New API:** `.awaitingChallenge(AuthSignInStep)` on `AuthSessionState`, and the `challengeExpired` error. Nothing else changes - `confirmSignIn` is today's call. Declared in 14.2 (`AuthSessionState`) and 14.7 (the error).

## 5. Session model

**A session is one identity plus its credentials.** Which credentials it holds depends on how the app's Cognito backend is set up, and there are five combinations. These are Cognito configurations, not library bookkeeping, which is why all three platforms already model exactly the same five:

| Session kind | Signed in? | Has AWS credentials? | When you see it |
|---|---|---|---|
| **User pool only** | Yes | No | The backend has a user pool but no identity pool. Tokens only. |
| **User pool and identity pool** | Yes | Yes | The common full setup. Tokens *and* AWS credentials. |
| **Guest** | No | Yes | Unauthenticated access via the identity pool. Credentials, no user. |
| **Federated** | Yes, via an external provider | Yes | An outside identity provider exchanged for AWS credentials. |
| **None** | No | No | Nothing yet. A fresh session before anything happens, or one left this way by `signOut()`. |

**One rule covers the whole model: a session holds exactly one of these at a time, and sessions do not affect each other.**

That single sentence answers every "can I be X and Y at once?" question: not in one session, yes in two. Signed in *and* guest? Two sessions. Signed in as two people? Two sessions. Federated *and* user-pool? Two sessions.

Three clarifications, stated plainly because the rule above implies them without saying them:

- **One user at a time per session. You can sign out and back in as a different user within one session** - the session is the container, not the person.
- **The same human can be signed into two sessions at once.** Nothing dedupes by identity: if an app constructs two clients with different session IDs and signs the same user into both, that is two independent sessions with two independent token sets and two sign-out paths. A design where that matters should reconcile by reading `StoredSession.username`.
- **The app owns session-ID uniqueness.** A session ID is a namespace the app chooses, not a value the library validates for meaning. Reusing one is not an error and does not create a second session - per decision 4 you get the existing session back.

It also explains why **federation needs no new concept.** A federated session is just one of the five kinds. A session is either signed in or federated, never both, which every platform already enforces. What changes is that a federated session and a user-pool session can now coexist.

One more thing worth knowing: **signing in is multi-step** - MFA, a new-password challenge, TOTP setup - and that partial progress belongs to the session. So one session sitting on an MFA prompt does not block another's sign-in.

## 6. Storage model

**What changes, in one line.** 4.1.1 covers why this key is where the single-session limit lives; this is the key itself:

```text
today:    amplify.<userPoolId>.<identityPoolId>.session
proposed: amplify.1.<poolNamespace>.<sessionId>.session
          |______ schema version, added now because it is free now and
                 impossible to retrofit later

<poolNamespace> is exactly what today's key already carries, which depends on
what the app configures:
    user pool only       ->  <userPoolId>
    identity pool only   ->  <identityPoolId>
    both                 ->  <userPoolId>.<identityPoolId>
So the segment count varies, and the two single-pool shapes look identical.
A listing parser must therefore anchor on the "amplify.1." prefix and the
".session" suffix, never on segment arity.

The default session has no record of this shape (decided 2026-10-02): it is
the plugin's own record, amplify.<poolNamespace>.session, below. Its stringValue
is "$default". '$' is outside the permitted charset below, so
SessionID.named(_:) can never produce it: an app that happens to name a session
"default" gets its own record rather than the plugin's saved login.

The sessionId segment is an INSERTION, not a move: named-session records are
siblings of the plugin's record under the same keychain service, differing only
in kSecAttrAccount. So the plugin never reads a named session, and a rollback to
a plugin-only release leaves named sessions in place for the roll-forward.
See 4.8.

SessionID is validated eagerly at construction against [A-Za-z0-9_-], non-empty,
and throws naming the offending character. That is what keeps a '.' or '/' from
ever reaching a key segment, so the flat key has no delimiter ambiguity. The same
charset is independently enforced by Firebase (app names) and documented for AWS
shared-config profile names. SessionID is CASE-SENSITIVE: lowercasing would
silently merge .named("Work") and .named("work") into one session, which is a
credential-crossover bug, and keychain accounts are case-sensitive anyway.
```

**Two key families.**

Both families live in the plugin's keychain service, `com.amplify.awsCognitoAuthPlugin` (or `…Shared` with an access group).

| Item | Account | Payload |
|---|---|---|
| `.default`'s session record | the plugin's key, `amplify.<poolNamespace>.session` | the plugin's `AmplifyCredentials` JSON, exactly as the plugin writes it |
| `.default`'s sidecar | `amplify.1.<poolNamespace>.$default.meta` | the label, and the last signed-in user's username and user ID |
| `.default`'s challenge record | `amplify.1.<poolNamespace>.$default.challenge`, unchanged | as for a named session (4.11) |
| a named session | `amplify.1.<poolNamespace>.<sessionId>.<kind>`, kind `session` or `challenge` | `SessionRecordEnvelope`: a schema version, a generation, the kind, the label, the username and user ID, and the same `AmplifyCredentials` JSON in its `credentials` field |

- **No `$default` session record.** Only the **session** record of `.default` moves to the plugin's key. Its challenge record and its sidecar stay in the client's own family, under `$default`. `SessionID.default` stays in the API, and is still distinct from `.named("default")`.
- **Development leftovers.** Listing ignores `amplify.1.<poolNamespace>.$default.session`, the session record development builds wrote.
- **The sidecar** holds what the plugin's record cannot hold: the display label, and the last signed-in user (username and user ID). The plugin rewrites its record on every refresh and drops keys it does not know, so this metadata cannot live inside the record. The suffix `meta` is not a record kind, so no listing reads it as a session. It is bound to that user:
  - **while the shared record holds that user**, the label is used;
  - **while the shared record is signed out** (`noCredentials`) **or absent**, the picker shows a signed-out row with the sidecar's label and last username;
  - **when the shared record holds a different user**, the sidecar's label is hidden. The sidecar is rewritten for the new user, without the label, only at the client's next write of the record: a plugin sign-in leaves it as it is, so after a later plugin sign-out the row names the sidecar's user and label again;
  - **a sign-in over a signed-out row keeps its label only for the same user**, or when the sidecar has no user yet (a label set before anyone signed in). A different user drops it.
- **The commit guard on `.default` compares the stored bytes.** `setIfUnchanged` already does this, so the default session has no generation number. The plugin itself writes unguarded (`_set`). That is one reason running both in one process is not supported (§4.9). Whether another writer changed the *credentials* is decided on the decoded value, not on the bytes, because the plugin may save the same credentials again with other bytes.
- **macOS: absent once is not signed out.** There the keychain's `set` deletes the item and adds it again, so a reader in another process can find it absent in between. A `.default` read that finds the shared record absent reads it once more before concluding "signed out".
- **Sign-out and purge of `.default`.** Sign-out revokes, writes the sidecar for the signed-out row, then writes `{"noCredentials":{}}` through the guard. Purge deletes the record, then the sidecar, then the challenge record.
- **Named sessions are decode-compatible, not byte-identical.** Their envelope wraps the plugin's payload, and the payload bytes are not deterministic, so the code compares decoded values (`ClientCredentialStore.swift:18-21`). The earlier "byte-identical" wording (A.3) was wrong.
- **Wipe protection.** The plugin's wipes skip `amplify.<digits>.` accounts, which are the client's records, the sidecar and challenge record included (`SessionRecordAccount.isClientSessionRecord`). Its access-group migration skips them too, **except** `.default`'s sidecar and challenge record (`amplify.1.<ns>.$default.meta` and `.challenge`). Those now belong to the plugin's session, so they are treated as the plugin's own items wherever the plugin moves or clears its session (`SessionRecordAccount.isDefaultSessionItem`):
  - the access-group migration moves them, and so does the public `KeychainStoreMigrator.migrate()`;
  - an access-group transition without migration wipes them;
  - the migration's destination clear removes them.

  One check deliberately ignores them: whether the shared service already holds items (`hasItemsExceptSessionRecords`). So a shared service holding only those two never blocks the migration and strands the signed-in record. The `.default` session record is the plugin's own, so it moves and is wiped as the plugin's record always has been. The scoped wipe ships before the client writes records.
- **Corrected against the code.** The text before 2026-10-02 said this layout was "read-old/write-new/never-delete", and the beta guide said a client sign-out left the plugin's record untouched. Neither held. Now there is one record: sign-out writes the signed-out value, and purge deletes it.

**When the configuration changes, `.default` follows the plugin's rule.**

The default session follows the plugin's configuration-change rules exactly. The decision is the plugin's own code, extracted so both call it: `AWSCognitoAuthCredentialStore.configurationChange(from:to:)` (`AWSCognitoAuthCredentialStore+ConfigurationChange.swift`), which the plugin's `restoreCredentialsOnConfigurationChanges` runs at configure and the client runs for `.default` (`SessionRecordStore+PluginConfiguration.swift`). It compares the configuration with the plugin's `authConfiguration` item, which holds the last configuration the record was written under.

| Change | The plugin, and `.default` |
|---|---|
| A user pool added to an identity-pool-only setup, with the same identity pool | The record is copied to the new namespace as it is (a guest stays that guest); the old one is kept |
| An identity pool added, changed or removed, under the same user pool, app client and region | The same: copied as it is, the old one kept. On a changed identity pool the old identity ID goes along |
| Only the app client changed, with the same pools | Nothing: the key has no client ID, so the record stays where it is. Its next refresh, with the new app client, gives `sessionExpired`, as in the plugin, and the user signs in again. Nothing to revoke |
| Any other change of the key (another user pool, say) | The old record is deleted, and `.default` is signed out |

For example: an app ships with a user pool only and alice signs in. The next release adds an identity pool. At the first restore, `.default` copies alice's record to the new key, unchanged; the identity is fetched on first use, because a `userPoolOnly` payload under a configuration with an identity pool is identity-pending (derived, since `.default` has no envelope to hold the flag). If the release had moved to another user pool instead, alice's record would be deleted and `.default` would start signed out.

As built, beside the table:

- **A changed identity pool keeps the old identity ID.** The carried session reports the old identity ID and the old pool's AWS credentials, with no Cognito call, until they expire. A refresh then sends that ID to `GetCredentialsForIdentity`, with no `GetId`. That call names no identity pool, so while the old pool exists Cognito keeps answering with the **old** pool's credentials. If Cognito refuses the ID with one of the two refusals the engine retries (`ResourceNotFoundException`, as once the old pool is deleted, or `NotAuthorizedException` "Access to Identity … is forbidden"), the engine calls `GetId` on the new pool and goes on with that identity, as the plugin does. Any other refusal is reported as an error until the user signs out and in again. Named sessions carry user-pool tokens only (below). Pinned with scripted Cognito, and against real Cognito by the integration suite (CS-D3).
- **A deleted login is revoked, best effort, when its user pool is the current one**. With the same user pool, the key changes only through the identity pool, and the plugin then deletes only if the app client (or the region) changed too. So the revoke uses the **previous** configuration, which `authConfiguration` records: its region, app client ID (and secret, if one was recorded) and custom endpoint, without the app's `configureUserPoolClient` escape hatch, which belongs to the current configuration (`LiveSessionRevoker(previous:)`). It runs once, detached, after the delete, so the restore never waits on the network; nothing is persisted. A failure logs one warning under `AmplifyCognitoClient.DefaultSession`, naming no one: "A login deleted by a configuration change could not be revoked; its refresh token stays valid until it expires." A login of another user pool is not revoked, and stays valid until it expires.
- **It writes `authConfiguration`, last.** Otherwise a rolled-back plugin would see a configuration change and run its unconditional carry (`_set(old, key: new)`), writing an older copy over a newer login. It is written only after the carry or delete succeeded, and only when it changes: the configuration is compared by value, not by bytes, because neither `authConfiguration` nor the session's bytes are stable across encodes.
- **Unlike the plugin, a failed read is never "no previous configuration".** The plugin reads with `try?`, so a locked keychain at launch overwrites `authConfiguration` and loses a pending carry. The client fails the restore with `storageUnavailable` and changes nothing; the next restore applies the rule again. Bytes that are not a configuration are "no previous configuration", as in the plugin.
- **Two writes the plugin makes are skipped**, since neither changes what is stored: a carry onto the same account (an identity-pool-only configuration started again, or a Gen1 plugin configuration that differs only outside the key), and `authConfiguration` rewritten with the configuration it already holds.
- **The sidecar goes with the record.** A carried record takes its sidecar (label and last user) when the new namespace has none. A deleted record's sidecar is deleted too, so no signed-out row is left for a login the user never signed out of, and so is the old namespace's interrupted sign-in (`$default.challenge`). Both are best effort. **The plugin does the same when it applies the change itself**: its deleting branch (`restoreCredentialsOnConfigurationChanges`, `.clear`) removes `amplify.1.<old ns>.$default.meta` and `amplify.1.<old ns>.$default.challenge` right after the old record, best effort, and only if the record's removal succeeded. They are the client's items, but they describe the plugin's login, which `.default` shares: its label and last user, and its unfinished sign-in. Left behind, the client would list a signed-out row (label, last username) under the old configuration for a login nobody signed out of. The client cannot tell that case apart on its own: a carry keeps the old record and its sidecar, and the static calls write sidecars outside the recorded namespace, so the plugin, which knows it just deleted the login, removes them. On a carry, or no change, the plugin removes nothing new. The plugin builds the two accounts with `SessionRecordAccount.defaultSessionItemAccounts(poolNamespace:)` (`InternalAmplifyKeychain`, which both depend on), and tests pin them to the client's own. This adds two deletes to the plugin's keychain queries on a deleting change, so the keychain-query golden was re-locked.
- **Where the rule runs.** At `.default`'s restore, under the gates of the current namespace and of the one the previous configuration names, taken in the global order, as a named session does with its marker. `storedSessions` shows `.default` as the rule will leave it at the next restore (a preview that changes nothing), and a hosted-UI sign-in's `.distinctFromOtherSessions` counts the user a pending carry would bring.
- **The static `signOutStoredSession` and `purgeStoredSession` apply the rule only when it would carry**. They may be called with a configuration other than the app's: say the app runs with A, and a settings screen signs out a stored session under B. Running the whole rule would delete (and, on the same user pool, revoke) alice's A login. So when the rule would delete, they change nothing at all, `authConfiguration` included; the next restore under the new configuration applies the rule in full. **When it would carry, they carry but still never write `authConfiguration`**: only the app actually running a configuration, a restore, records it. Otherwise, with the app on X, a static purge under Y would record Y, and the app's next restore under X would see a change from Y, carry nothing back (Y was purged), and restore X's copy as if the login had moved and come back. **A static sign-out also signs out the record it carried from**: it writes `{"noCredentials":{}}` over X's record through the byte guard (`setIfUnchanged`), only while X's record still holds exactly the bytes it carried, the login it just signed out, and only for a user's login (a guest's carry revokes nothing). So neither a restore under X nor a later move to Y, whose carry copies X's signed-out record, brings the user back. A record another writer changed meanwhile is left alone, and a failed write logs one warning under `AmplifyCognitoClient.DefaultSession`. **A static purge revokes nothing, so it leaves X's record as it was**: the app's login under its own configuration. The cost: a later restore under Y applies the rule from X again, and copies X's login over the purged copy.
- **An app and its extensions sharing an access group must give `.default` the same configuration.** They share the plugin's record and its `authConfiguration`, so with two configurations each launch would apply the rule against the other's, and where it deletes, delete (and on the same user pool revoke) the other's login. Such an extension uses a named session.
- **For runtime switching between backends, use named sessions.** They keep each configuration's login. This narrows the 2026-09-26 and 2026-09-27 rule ("never clear; switching configuration must work") to named sessions.
- Two rules acting on one shared record would fight each other. That is why `.default` follows the plugin and not the client.

**When the pool configuration changes, for named sessions (decided 2026-09-26: copy forward like the plugin;
scoped to named sessions 2026-10-02).** Named sessions keep the rules below, including "keep the old record"; the
default session follows the plugin's rule above. Adding or
changing a pool is a new `<poolNamespace>`, which starts with no record. The plugin keeps the configuration it last
ran with and compares it on start (`restoreCredentialsOnConfigurationChanges`). The client keeps the same fact per
session and per app: a **namespace marker** `amplify.1.<sessionId>.<app>.configuration` (`<app>` a digest of the
bundle identifier, so an app and an extension sharing an access group and a session ID never act on each other's
marker; the last segment is not a record kind, so no listing, of this build or an earlier one, reads it), recording
the namespace the app last kept the session's record under. It is written when a record with credentials is created
or written over a signed-out row, and when a restore finds a record that is not signed out and that the marker does
not name; reading a session that has no record writes nothing. A marker this build cannot read (corrupt, or a newer
schema) carries nothing and is never overwritten. A process with no bundle identifier (a command-line tool) uses the
scope of `"unknown-bundle"`, shared with every other such process on the device.

When a restore finds no record at all under the current namespace, the session is carried **only from the namespace
its marker records**, only on the changes the plugin accepts:

| Recorded namespace | Current namespace | Carried |
|---|---|---|
| `<identityPoolId>` | `<userPoolId>.<identityPoolId>` (same identity pool) | the record as it is: a guest or federated identity |
| `<userPoolId>` | `<userPoolId>.<identityPoolId>` | the user pool tokens; the identity is fetched on first use |
| `<userPoolId>.<otherIdentityPoolId>` | `<userPoolId>.<identityPoolId>` | the user pool tokens **only**, never the other pool's identity (a deliberate difference from the plugin, which copies its bytes and so the old identity); the new identity is fetched on first use |
| `<userPoolId>.<identityPoolId>` | `<userPoolId>` | the user pool tokens only |
| anything else | | nothing; the record under the recorded namespace is **kept** (the plugin's `removeSession(for:)` clears it: below) |

The latest recorded state wins: a signed-out or absent record there carries nothing, even if an older namespace still
holds the user, and records under namespaces the session is not recorded under are never read. A signed-out row
under the current namespace is the session's own answer too, so it also blocks carrying back on a rollback (the safe
direction); a sign-in over it makes the marker name the current namespace again.

**For a named session, a change the client does not carry keeps the old record** (a deliberate difference: the
plugin's `:149-155` branch clears it, and so does `.default`, which follows the plugin). An app can switch pool configuration at runtime under one session ID (an organisation picker), which the
plugin cannot: clearing would delete the other configuration's live session, unrevoked, on every switch. The first
record started under the new namespace remembers the old one as a copy, with its digest and its own user, whoever
starts, so its user's sign-out or purge there sweeps it while it is untouched. Switching or rolling back reads the old
session as it was, unless it was signed out there.

**Copy and keep, as the plugin does.** The record is re-wrapped, not copied byte for byte: written through the commit
guard as a new record (generation 1, the same label, username and user ID). The old record is **kept**: a rollback
reads it again, as the plugin's does (so rolling back an added user pool keeps a guest's identity). The marker then
names the new namespace and remembers the old record as a copy, with a SHA-256 of its bytes at carry time. Sign-out
(best effort, after the signed-out row) and purge (first) delete a remembered copy **only while its bytes still have
that digest, it provably holds the same user, and it is not a guest's**. The digest detects a write after the carry (an app
extension on the old configuration that refreshed the record, or signed another user in): that record belongs to
the other writer and is left, and logged. It does not detect that the record is still read without being written: an
extension that only reads it loses it at sign-out. A guest's copy is never swept, since an extension on the old
configuration may use its identity ID, which a new guest would not get back. The marker is per app; records are
shared by every app and extension in the access group, so the sweeps are what digest-guards the other writers. A
sign-out first revokes a swept copy whose refresh token differs from the one it revoked (rotated under the old
configuration since the carry) when the copy's user pool is this configuration's (a carry needs the same user pool);
otherwise, and at purge, a deleted copy's refresh token is not revoked, and stays valid until it expires.

**A rollback.** Back under a namespace whose record is the untouched copy the marker remembers, with the session
signed out or purged under the namespace the marker names (by another app or extension, which does not know this
app's copies, or by a sign-out whose sweep failed), the copy reads as swept and is deleted; a guest's is not. Otherwise
the session is kept there from then on, and the record under the namespace the marker named, if not signed out, is
remembered as a copy with its own user (its `userId`, or for a guest or federated identity its identity ID), whoever
holds the record here.

**Whose each copy is.** The marker records the user of every copy (`user:<userId>`, else `identity:<identityId>`)
and the user of the record under the namespace it names, as additive keys (the schema stays 1; an earlier build
ignores them, and a marker of an earlier build decodes with none). Copies are kept whoever starts a session afterwards
(bob signing in at B keeps alice's copies), and each is taken only by its own user:
- a sign-out or purge sweeps a copy (a sign-out also revokes it first, if rotated) only when the copy's recorded user
  is the session's: the record signed out or purged, else the user the marker recorded for this namespace;
- a rollback reads a copy here as swept only when its recorded user is the user whose session ended under the
  namespace the marker names (the marker's recorded user, else the signed-out row's);
- a copy with no recorded user (an earlier build's) is never swept: it is kept, and logged.
A restore that finds no record while the marker names the current namespace (another writer purged it) sweeps
nothing, and the marker keeps its copies for their users. The record under the namespace the marker named is
remembered as a copy with its own user whoever starts or restores a session here, so its user's later sign-out, purge
or rollback check still finds it.

**A purge keeps the marker while it remembers other users' copies.** After its sweep, a purge deletes the marker,
unless copies of other users (with a recorded user) are left, such as alice's when bob's session is purged. Then the
marker stays, rewritten to name the purged namespace, where no record is left, with no user and only those copies: it
carries nothing, even when it named a later namespace (a purge under an older configuration), and a rollback reads none
of the copies as swept, since no user's session is recorded as ended there. Their own users' sign-out or purge still
sweeps them. A marker whose copies record no user (an earlier build's) is deleted: nothing would ever sweep them.

If the old record vanished or was signed out between the carry's read and its re-read after the commit (a purge or
sign-out under the old configuration raced the carry), the carry is undone: the new record is deleted while it still
holds exactly the committed bytes. The re-reads and deletes are not atomic (the keychain has no compare-and-delete).
The marker remembers one copy per namespace, with no other bound. On macOS the keychain's `set` is delete-then-add, so
the marker's read-modify-write can lose a concurrent update by another process of the same app. A purge under an
older configuration than the one the marker names deletes that configuration's record and its user's remembered
copies, not the record under the configuration the marker names, which then stands as a session of its own there.

A restore that may carry holds the source namespace's record gate as well as its own, and `purgeStoredSession` and
`signOutStoredSession` hold the gates of every namespace the marker names, all taken in one global order; each reads
the marker again under the gates and takes them again if it changed; a restore whose marker keeps changing fails as
`storageUnavailable(.interrupted)`, not cached, so the next call restores and carries again. The stored-session calls
refuse
(`sessionConfigurationMismatch`) when the session is live in the process under another pool configuration in the same
access group. A keychain failure reading the marker or the recorded record fails the restore (`storageUnavailable`); it
is never read as "nothing to carry". A carried user pool session whose identity step fails reports its tokens and sub
and fails only the identity, with that failure; the record keeps waiting for its identity, as the plugin retries on
every fetch across launches. In the process (per record, shared by every client of it: `SessionRecordGates.memory`), a
known refusal (`notAuthorized`, `invalidParameter`, `resourceNotFound`, `configuration`) stops the retries for the
refused user until the app restarts or the session is signed out or purged, any other failure (a cancellation aside)
delays the next by 30 seconds, and until then the last failure answers for the identity fields and AWS credentials. A
sign-out or purge also forgets the reused refresh token the dead-token check holds.
Only an identity-step failure keeps the tokens: a refused or expired refresh token, or tokens that still need a
refresh, fail every field with `sessionExpired`. If the refresh's commit lost to another writer whose record has its
identity, that record is the answer.
`storedSessions` lists a session that would be carried, once, as it would be carried. Device metadata and the ASF
device ID are not carried, as the plugin does not carry them. (Removed 2026-10-02: the rule for "`.default` adopted
from the plugin in the same release as a configuration change". `.default` is the plugin's record, and follows the
plugin's rule above.) Implementation: `SessionRecordStore+CopyForward.swift`; the integration tests are
CS-1 … CS-3 (`StorageConfigurationTests`).

**Proposed session is saved under a session ID, and the ID is part of the storage key.** The naming rule is universal, with no exceptions and no unnamed fallback:

- **Every session has an ID.** `.default` when the app supplies nothing, `.named(_:)` when it has its own stable identifier, `.new()` for a minted UUID. Guest and federated sessions are named exactly the same way as signed-in ones, so there is no separate case to reason about.

- **A session record is written atomically**, or at least becomes visible atomically. Free where a session is one blob; needs an explicit write-set where a session is many discrete keys.

- **Only one writer per record, in one process.** Two Auth Clients built with the same session ID are two handles onto one session, so there is exactly one thing writing that record. Storage access for a session is mutually exclusive, so two writes to one record cannot interleave. The exception is the plugin: its state machine is outside this exclusion, which is why the plugin and the client over `.default` in one process are unsupported until the bridge (§4.9).

- **Per-session single-flight refresh is an explicit invariant, not an emergent one.** Today coalescing is an accident of there being one global state machine: a second concurrent fetch simply awaits the in-flight refresh. With N sessions that property has to be built deliberately, per session. Different sessions must never wait on each other, so per-record exclusion must not become a process-wide lock or it re-creates the serialization this design exists to remove.

- **Across processes there is no guard, and under refresh-token rotation that is worse than "last write wins".** An app and its extension sharing a keychain group are two state machines over one record. If the app client has refresh-token rotation enabled — a **server-side** setting the SDK caller neither chooses nor can detect, whose grace period can be as low as zero — the losing refresher gets `RefreshTokenReuseException` and may persist its now-stale refresh token over the winner's, leaving a record that can never refresh again. The mitigation is a **commit guard**, not a lock: re-read the record before writing and discard the write if another writer has moved it. Deliberately not a cross-process mutex — Supabase built one and it caused worse harm than the races it prevented (production deadlocks, and orphaned locks that hung every later auth call).

- **A failed refresh must never be read as "signed out".** `RefreshTokenReuseException` usually means *another* handle or process refreshed, so it means "discard this attempt and re-read storage" — never "this session is invalid, clear it". The exception: a second reuse in a row, at least 30 seconds after the first, whose re-read credentials are still exactly the ones sent means nobody refreshed (a record rolled forward over a token the plugin rotated away); the session is then `sessionExpired`, its record kept. The same applies to a keychain read failure: unreadable is not empty.

- **Device metadata survives sign-out.** Signing out clears that session's tokens but must leave the per-user device record intact, so a remembered device stays remembered and the next sign-in can still skip MFA. Only an explicit forget-device or delete-user removes it. All three platforms already do this correctly.

- **The interrupted-sign-in record is per session too, and it is a second record.** 4.11 depends on a partly-completed sign-in outliving app death, so the challenge state is stored rather than held in memory. It gets its own key, `amplify.1.<userPoolId>.<identityPoolId>.<sessionId>.challenge`, at the **per-session** level - so one session sitting on an MFA prompt is invisible to every other session. Lifecycle: written on entering a challenge, deleted on success, on failure, and on being superseded by a new sign-in attempt for the same session. It holds a short-lived Cognito `Session` string and the pending step, so it goes in the same protected, device-only storage as tokens and **must not sync** to another device, where it would be useless and misleading. Nothing persists this today (C.11, C.17), so it is new storage rather than a re-keying. It is never carried to a new pool configuration: its session string belongs to the old configuration's app client. Sign-out and purge also delete it under the namespaces the session's namespace marker remembers, only with the copies they delete there (the same user's, unchanged since carried, not a guest's). As built: see 4.11. The 2026-10-02 revision leaves the challenge record a separate client item for every session; `.default`'s stays at `amplify.1.<ns>.$default.challenge`. The plugin has no equivalent.

**Three levels of scoping.** Every stored item belongs to exactly one level, and this is what prevents accidental sharing:

| Level | Examples | Shared across sessions? |
|---|---|---|
| **Per session** | tokens, AWS credentials, sign-in method, identity id, including a guest session's identity id; the challenge record; for `.default`, the sidecar; for a named session, its namespace marker (per session and per app) | No. This is what the session ID names |
| **Per user** | device metadata (`amplify.<ns>.<username, lower-cased>.deviceMetadata`), remembered-device keys, and the ASF device ID (`amplify.<ns>.<username>.deviceASF`, not lower-cased) | Yes, for the same username in a namespace, plugin and client alike |
| **Per keychain service** | the plugin's `authConfiguration` item, the last configuration it ran with; since the 2026-10-02 revision the client also writes it for `.default` | Yes, app-wide, and shared with the plugin |

*Corrected 2026-10-02:* the earlier table had a "per device" row with the device ID. The ASF device ID is keyed per username (`DeviceRecordStore.swift:11-28`; `AWSCognitoAuthCredentialStore.swift:188-198`), so it is per user.

Every level above is already how the code works today. The two changes are adding the session ID to the per-session level, and adding the challenge record as a second per-session item.

**Listing.** The account picker needs to enumerate saved sessions and read their display data with no network call. Whether the underlying store can list keys differs by platform. The `.default` row comes from the plugin's record and the sidecar. Listing ignores any old `amplify.1.<ns>.$default.session` record, a development leftover, so it never shows as a ghost row. For example, with alice signed in through the plugin and the sidecar labelled "Work" for alice, the picker shows one `.default` row, "Work", alice; if the plugin then signs bob in, the row is bob with no label.

## 7. Credential providers

**One session, three distinct outputs.** Consumers need different ones, and they are not interchangeable:

| Output | Used for |
|---|---|
| Temporary **AWS credentials** (access key, secret, session token) | Signed AWS calls: analytics, storage, any SDK client |
| **Access token** (and id token) | Bearer auth: AppSync user-pools mode, REST authorization headers |
| **Identity id** | Request attribution, unauthenticated identity. Read from a session (`fetchAuthSession().identityId`) rather than vended as a provider, which is why 14.4 lists only the other two |

**What using them looks like.** A provider is a value the app hands to whatever needs credentials. Which session it resolves is fixed when it is handed over, so the receiving code cannot end up acting as a different user. Each session refreshes its own tokens on demand with no coordination between sessions, so an app holding several needs to do nothing to keep them all live. A rule worth stating here rather than leaving to 15.2: on a signed-out session, resolution **fails** with `notSignedIn` rather than falling back to guest credentials.

```swift
// 1. AWS credentials -> anything that signs AWS requests. A sibling Amplify
//    client takes the provider directly; a raw AWS SDK client takes it through
//    AmplifyFoundationBridge's adapter.
let workS3 = S3Client(config: try await S3Client.S3ClientConfiguration(
    awsCredentialIdentityResolver: FoundationToSDKCredentialsAdapter(
        provider: work.credentialsProvider),
    region: "us-east-1"))

// 2. The user-pool token -> a bearer header, for AppSync user-pools mode or an
//    app's own API. Resolved per call, so it refreshes on demand and can never
//    hand back a snapshot that outlived a sign-out.
var request = URLRequest(url: endpoint)
request.setValue("Bearer \(try await work.userPoolTokenProvider.accessToken())",
                 forHTTPHeaderField: "Authorization")
```

## 8. Events

Each Auth Client exposes its **own** event stream, and keeps the existing four coarse lifecycle events: **signed in, signed out, session expired, user deleted**. All three platforms have exactly those four today, and the deliberate collapse from many granular API events down to four is worth preserving.

The reason the stream is per client rather than global is concrete: on two of the three platforms an event carries no session identity at all, just a name. With one session that is sufficient. With two, a subscriber cannot tell which session an event refers to.

**How the old events survive.** They are the same four names with the same meanings, delivered on a stream that belongs to one Auth Client. So an app that today listens for "signed out" and clears its cache keeps working - it just attaches the listener to the session it cares about instead of to the Hub:

```swift
// Today: one global listener, and no way to tell which session an event is about.
Amplify.Hub.listen(to: .auth) { payload in
    if payload.eventName == HubPayload.EventName.Auth.signedOut { clearCaches() }
}

// Proposed: one stream per session. The identity of the session is the stream you
// are reading from, so nothing has to be carried in the payload.
for await event in work.listenToAuthEvents() {
    switch event {
    case .signedOut:      clearCaches(for: work.sessionId)   // unambiguously the work session
    case .sessionExpired: promptReauth(for: work.sessionId)
    case .signedIn, .userDeleted: break
    }
}

// A second session's events arrive on its own stream, concurrently.
for await event in home.listenToAuthEvents() { ... }
```

**New API:** `listenToAuthEvents()`, returning an `AsyncStream<AuthEvent>` per Auth Client. `AuthEvent` carries the same four cases the Hub sends today. The Hub path is unchanged for the plugin, so an app migrating one screen at a time can use both (over named sessions until the bridge; see 4.9). Declared in 14.2 (`listenToAuthEvents()`) and 14.6 (`AuthEvent`).

**Events are delivered from the point of subscription.** The stream does not replay what happened before a subscriber attached, so an app that needs to know where a session stands asks for it rather than waiting for an event to arrive. That is the division of labour: `listenToAuthEvents()` says *what happened*, and `currentSessionState()` - with `listenToSessionStateChanges()` for updates, both in 14.2 - says *where things are now*. Both are per session.

## 9. Hosted UI (browser-based sign-in)

Hosted UI is supported, with one limit and one API requirement.

**Cookie isolation is required.** By default the system browser shares one Cognito session cookie, so a second sign-in would silently return the *same* user. Every platform has an ephemeral or private browser-session option that avoids the shared cookie jar, and this design **defaults to it**. The platforms today default to sharing, which is wrong for this design. As a second layer, the OIDC `prompt=login` parameter forces re-authentication at the Cognito end, so the user is asked who they are even if a cookie survives.

For sign outs, some platforms already skip the browser round trip on sign-out when the sign-in used a private session, so ephemeral-by-default removes a visible browser flash on sign-out at no cost. It does not narrow what a sign-out revokes server-side; that is A.6, and it is unchanged.

**Redirect delivery must be correlated.** The callback must reach the session that started it, via the OAuth `state` parameter rather than via a global.

### 9.1 One browser sign-in at a time, and how the API says so

> **Scope (2026-10-02).** The rule is our library's policy on the platforms that have hosted UI, **iOS, macOS and visionOS**. It covers **one system sheet**: browser sign-in, the browser sign-out page and the passkey sheet. This section stays because it documents public API: `whenBrowserBusy`, `browserBusy` and `resetSystemSheet`.

**Only one system sheet is up at a time, per process, on iOS, macOS and visionOS: a browser sign-in, the browser sign-out page or the passkey sheet. This is a deliberate library policy, not an OS guarantee.** The distinction matters because the doc previously claimed the latter and a reviewer can falsify it: Apple documents only a *per-instance* rule for `ASWebAuthenticationSession.start()`, its error taxonomy has no "already in progress" case, and no Apple platform enforces a device-wide limit. On Android the effective limit is also ours — the redirect-handling activity is `launchMode="singleTask"` and one redirect scheme cannot be disambiguated between two pending requests. What genuinely constrains us is **UI presentation**: a flow needs a foreground-active `presentationAnchor`, and an iPhone cannot provide two. Concurrent browser sign-ins are therefore out of scope by decision; sessions are established sequentially.

**This exclusivity cannot be inherited, and that is a risk to name rather than a detail.** The thing serializing browser flows today is the single global auth state machine — the session layer has no in-flight guard of its own. Splitting into N sessions removes the only serialization that exists, on a seam with a five-issue history (#3362 → PR #3466 → #3678 → PR #3715 → #3766). So the rule needs an explicit owner in the new architecture, plus a public cancel/reset: a guard left held by a flow the OS silently tore down otherwise blocks sign-in until the app restarts.

The rule: **a process-wide browser lock, acquired for the duration of a hosted-UI sign-in, with the caller choosing what happens when it is already held.**

```swift
public struct WebUIOptions: Sendable {
    /// What to do when another session already has a browser sign-in in flight.
    public var whenBrowserBusy: BrowserBusyPolicy = .fail
    /// Private or ephemeral browser session. The default for the Auth Client.
    public var prefersEphemeralSession: Bool = true

    // A struct with two constructors rather than an enum, so a timeout is checked
    // when the policy is made (this matches the public API).
    public struct BrowserBusyPolicy: Sendable {
        /// Throw `.browserBusy` immediately. The default.
        public static let fail: BrowserBusyPolicy
        /// The longest a caller can wait: one hour.
        public static let maximumWaitTimeout: TimeInterval   // 3_600
        /// Wait for the in-flight sign-in to finish, then proceed. Throws `.browserBusy`
        /// if `timeout` seconds pass first. Seconds rather than `Duration`, which needs
        /// iOS 16; a longer timeout is capped at one hour, and zero or less gives `.fail`.
        public static func wait(timeout: TimeInterval) -> BrowserBusyPolicy
    }
}

public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor?,
                            options: WebUIOptions = .init()) async throws -> AuthSignInResult
```

```swift
do {
    try await work.signInWithWebUI(presentationAnchor: anchor)
} catch AuthClientError.browserBusy(let holder) {
    // Another session is mid-sign-in. Surface it; do not silently queue.
    showAlert("Finish signing in to \(name(for: holder)) first.")
}
```

**New API:** `WebUIOptions`, with `whenBrowserBusy` (and its nested `BrowserBusyPolicy`) and `prefersEphemeralSession`, and the `browserBusy(holder:)` error. The error carries the session ID holding the lock so an app can name it in the message. `WebUIOptions` is declared just above rather than in 14.6, because the option and the call it modifies read better together; the error is in 14.7.

**Why `.fail` is the default.** A browser sign-in needs the foreground and the user's attention. Queuing one silently means the user finishes one sign-in and a *second* browser appears unprompted, which reads as a bug. Failing fast lets the app say something useful. `.wait` exists for apps that genuinely want to serialize two sign-ins back to back, and it is bounded, because an unbounded wait turns a stuck operation into a hang with no error.

This is one dimension where the alternative in Section 10 is simply better: with one active session, the problem largely does not arise.

## 10. Alternative considered: one active session plus a stored list

A second design solves multi-account a different way: **keep one active session, and store a list of the others.** A pointer names which stored session is active, and switching moves the pointer. This is the shape JavaScript chose, prototyped in [amplify-js#14875](https://github.com/aws-amplify/amplify-js/pull/14875) (open, unmerged).

### 10.1 How it works

Storage gains one key, scoped to the app client and with no username in it, whose value is the list of signed-in usernames. **Position 0 is the active user; everything else is parked.**

```text
CognitoIdentityServiceProvider.<clientId>.AuthUserList  ->  ["alice@corp", "alice@personal"]
                                                              ^ active      ^ parked
```

Two new calls, and nothing else in the token-reading path changes:

```text
setCurrentUser(username)   ->  make a parked session active
listCurrentUsers()         ->  every signed-in user, active one first
```

`setCurrentUser` is deliberately cheap and offline. It checks that the username is in the list, moves it to the head, clears the cached identity-pool credentials so the next call re-derives them, and emits an event. **It performs no network call and cannot create or delete a session.**

### 10.2 What app code looks like in each design

This is the clearest way to see the difference. The same task, twice: show a picker, let the user choose, then do work as that user.

**One active session plus a stored list.**

```swift
// 1. List. No object per session; these are values read out of storage.
let users = try await Amplify.Auth.listCurrentUsers()
present(users.map { AccountRow(title: $0.username) })

// 2. Switch. A pointer move. Everything in the process now resolves to Bob.
try await Amplify.Auth.setCurrentUser(username: "bob@corp")

// 3. Work. Unchanged code, and this is the real advantage: every existing
//    category call follows the pointer with no re-wiring at all.
let result = try await Amplify.API.query(request: .list(Todo.self))   // as Bob
try await Amplify.Storage.downloadData(key: "report.pdf")            // as Bob

// 4. And the cost: this function has no way to say which user it acts as.
func uploadReceipt(_ data: Data) async throws {
    try await Amplify.Storage.uploadData(key: "receipt", data: data)  // whoever is active NOW
}
```

### 10.3 What each approach delivers

**Choose alternative deisgn of one active session plus a stored list if you want:**

- **Your existing categories to keep working, as the newly selected user.** The decisive advantage. API, Storage, and DataStore all resolve auth through the global, so they follow with no re-wiring.

- **Nothing new to hold.** No object lifecycle, no per-session resource cost. Sessions are data, not objects.

- **Migration to be a non-event.** Existing apps gain two functions, and nothing they hold changes shape.

- **The hosted-UI and cookie problem to mostly disappear**, because one session is ever active.

**Choose this proposed design if you want:**

- **Two users' work genuinely in flight at once** - two requests, two identities, concurrently. This is the other design's stated non-goal, and no amount of switching produces it.

- **A guest session and a signed-in user at the same time.** One active session cannot hold both.

- **Which user a piece of code acts as to be fixed and visible at construction**, rather than depending on global state at call time. A downstream client wired to a session cannot drift to another user.

- **No shared mutable pointer.** Nothing to contend over, and no read-modify-write to get wrong.

**If one-active-at-a-time is acceptable for your app, it is the cheaper and simpler option.** What it cannot give you is genuine concurrency, so on the primary goal the two designs point in opposite directions rather than merely trading off. Appendix B has the full treatment: why the JS diff is small and why that does not transfer to mobile, the seven things a mobile port would need.

## 11. Limits

Restated together, because a design is judged partly on what it declines:

1. **One system sheet at a time, per process, on iOS, macOS and visionOS**: browser sign-in, the browser sign-out page and the passkey sheet. This is our library's policy rather than an OS rule, and 9.1 says why we keep it.

2. **No multi-user through the existing categories. Multi-session reaches the standalone clients, not the plugins.** Every client in the `AmplifyClients` family (Kinesis, Firehose, Connect, EventEnrichment, CloudWatch) already takes a credentials provider at construction, so handing one `client.credentialsProvider` binds it to that session with no further work. The category plugins - Storage, API, Analytics, Predictions, and the rest - resolve auth through the global, so they follow the plugin's session regardless of how many Auth Clients exist. DataStore is out of scope entirely: its local database is a single file shared by every identity.

    **This one fails silently, so it is worth stating loudly.** With two sessions live, a Storage call does not follow the session the developer was thinking of; it follows the global. Storage derives its `.private` and `.protected` path prefixes from that identity, so the call *succeeds* - against the wrong user's prefix - rather than erroring. Analytics behaves the same way, caching its context by app and region with no notion of an owner. An app using several sessions must route per-user data through the standalone clients, not through the categories. Release notes must say this in so many words.

3. Sessions are not free, so concurrent sessions are bounded in practice, though the supported number is not yet decided.

4. **No "sign out of all sessions".** Decided, not overlooked: an app loops `storedSessions()`. A safe bulk operation needs per-session result reporting that `AuthClientSignOutResult` cannot express today, and every surveyed precedent for it is a footgun (see 4.7).

5. **Cross-process record sharing has no concurrency guard.** An app and its extension sharing a keychain group are two state machines over one record. A commit guard bounds the damage; it does not eliminate it. Under Cognito refresh-token rotation this can leave a record that cannot refresh, so an app that shares a session ID across processes should expect to handle re-auth. Detail in §6.

6. **The session model is client-side.** Cognito has no first-class concept of a session that this design could build on. If Cognito later adds one, this model may be revisited.

## 12. Decisions

Settled, and recorded here.

1. **The plugin eventually becomes a thin layer over the Auth Client. Yes.** One implementation, with the plugin as a compatibility shell. It requires full parity first, so it cannot be step one. The interim state follows CloudWatch Logging: extract the shared Cognito core into an internal module, keep the plugin working over it, and ship the Auth Client behind an experimental flag.

    > **As of 2026-10-02:** the thin layer, in which the plugin delegates to the client's session core, is not built (§4.9). The plugin and the client keep separate in-memory state. **The default session shares the plugin's saved login** (§4.8).

2. **The Auth Client must reach full parity with the plugin, in its entirety. Yes.** Every feature set, not a subset: federation, hosted UI, device tracking, MFA and TOTP, sign-up and confirmation, password reset, user attributes, delete-user, and the escape hatches. Federation needs no new design, being one of the five session kinds, so its inclusion is purely API scope. Parity is a release requirement, and decision 1 depends on it.

3. **We ship one approach, not both. This design**, because it is the only one of the two that serves the primary goal and the only one that delivers genuinely concurrent sessions. Section 10 and Appendix B present the alternative in enough detail that another platform or team could implement it instead. What we will not do is ship both over one storage layout: the two want different layouts, and running both over one storage service would first require fixing pre-existing defects in the store's constructor side effects.

4. **Two Auth Clients with the same session ID share one session. Yes.** Construction never fails for "already in use", and resources belong to the session rather than to a handle. A credential provider is a handle too, so it keeps its session alive.

5. **Hosted UI is one browser sign-in at a time, and the API says so explicitly.** A process-wide browser lock, `.fail` by default, `.wait(timeout:)` opt-in. Scoped on 2026-10-02: one system sheet, covering browser sign-in, the sign-out page and the passkey sheet, as library policy on iOS, macOS and visionOS (9.1).

6. **Session state stays close to today's surface.** One small enum over `isSignedIn`, adding only the two distinctions a Bool cannot make, and reusing the existing `AuthSignInStep`. No in-flight dimension in the type.

7. **A storage failure is made distinguishable from being signed out - in the Auth Client. The plugin is left as it is.** Today a keychain read failure at startup is swallowed and reported as signed-out, so an app can show a sign-in screen to a signed-in user. The Auth Client fixes it: that is what `AuthSessionState.unavailable`, the `storageUnavailable` error, and the listing rule in 4.2 are for, and a reason to retry is carried so an app can tell "wait" apart from "this is misconfigured".

## 13. Concerns

One thing we found while validating the design is serious enough to state in the main line. It is a problem to fix rather than an open design choice, so it does not change the design's shape - but it needs a decision, on whether remediation blocks this work or ships alongside it, before the client it affects can ship. Two Android prerequisites that came out of the same validation are in **Appendix E**, for later discussion.

### 13.1 Two same-region record-caching clients can attribute one user's data to another

The failure is silent, confirmed, and needs no unusual API call to trigger, which is why it is here rather than in an appendix.

`AmplifyKinesisClient` (and `AmplifyFirehoseClient`) keep a local SQLite cache so records survive being offline. **The filename is derived from the region alone** (`<prefix>_<region>.db`) and the records table has **no owner column**. So:

> Alice's session and Bob's session each get a Kinesis client for `us-east-1`. Both buffer records. Both auto-flush every 30 seconds by default. The first to flush reads `FROM records` **unfiltered**, picks up Bob's rows along with Alice's, and sends them **signed with Alice's credentials**. Bob's data is now attributed to Alice. Nobody called anything unusual, and no explicit `flush()` is needed.

Two smaller consequences from the same root: `clearCache()` deletes across users, and the cached-size counter sums the whole table, so one client mis-accounts its own budget.

**A fix exists and is small.** The storage layer already takes an `identifier` parameter that the client hard-codes to the region. Exposing it, for example as `Options(cacheNamespace:)`, would let the caller scope the cache per session, with today's behaviour as the default. **Decided: it ships alongside and does not block this work** - it is a change to a shipped client, owned by that client rather than by auth. The reasoning, from the downstream-client side, is that an app supplying its own `credentialsProvider` implementation can already hit the discard-versus-retry ambiguity today, at one session, so it is a pre-existing gap rather than one multi-session introduces. Until it is resolved, this document uses Connect rather than Kinesis for the per-user wiring example in 4.5.

> **As of 2026-10-02:**
> - **Kinesis and Firehose are not scoped yet.** Their cache has no namespace per session, so this concern stands for them.
> - **Storage and Pinpoint are closed.** They follow `Amplify.Auth`, so plugin-only apps are unaffected. The existing release note covers them (limit 2).

## 14. API surface

### 14.1 Construction

```swift
public final class AmplifyCognitoClient {        // actor internals

    // The family shape: synchronous and throwing, exactly like AmplifyKinesisClient.
    // Two Auth Clients with the same session ID are two handles onto one session,
    // so this never throws for "already in use".
    public init(configuration: AuthClientConfiguration,
                options: Options = Options()) throws

    public init(from resource: String = "amplify_outputs",
                bundle: Bundle = .main,
                options: Options = Options()) throws

    public struct Options {
        public var sessionId: SessionID                        // default `.default`
        public var accessGroup: String?                        // shared storage, as the plugin has today
        public var configureUserPoolClient: ConfigurationProvider?   // family escape-hatch closure
        public init(sessionId: SessionID = .default,
                    accessGroup: String? = nil,
                    configureUserPoolClient: ConfigurationProvider? = nil)
    }

    public nonisolated var sessionId: SessionID { get }
}
```

`AuthClientConfiguration` is the pool IDs and region, loadable from `amplify_outputs.json` exactly as every sibling's `Configuration` is - which is what the second `init` does. `ConfigurationProvider` is the family's escape-hatch closure type, unchanged here. `ConfigurationProvider` is not new at all, and `AuthClientConfiguration` is new only as a name - each sibling has its own equivalently-named `Configuration` type. So neither is specified further in this document. (Amended during implementation: `AuthClientConfiguration` also carries every Gen2 `auth` setting as public `@_spi(AmplifyExperimental)` fields. These are OAuth, password policy, username, required and verification attributes, MFA, and guest access.) `Options` is the family's per-client options struct - `sessionId`, the keychain access group, and the escape-hatch closure - and it is declared above, nested in the client exactly as each sibling nests its own.

### 14.2 Session state and events

```swift
/// What this session is, right now. Deliberately close to today's
/// `fetchAuthSession().isSignedIn`, with the cases a Bool cannot express.
public enum AuthSessionState: Sendable, Equatable {

    /// Signed in, by any means, including federated.
    case signedIn(AuthClientUser)

    /// No user, and no credentials of any kind. Where a session starts, and
    /// where `signOut()` leaves it. Nothing to sign with.
    case signedOut

    /// No user, but this session holds live unauthenticated identity-pool
    /// credentials, so it can sign AWS requests as nobody in particular.
    /// Reachable ONLY when an identity pool is configured, and only once
    /// something has actually fetched guest credentials - `signedOut` does
    /// not turn into `guest` by itself.
    case guest

    /// A sign-in is part-way through and waiting on the user. The client's own
    /// mirror of the plugin's `AuthSignInStep`, because the client does not
    /// depend on Amplify core (see 14.6).
    case awaitingChallenge(AuthClientSignInStep)

    /// Could not read storage. NOT "signed out" - a retry may succeed.
    case unavailable(StorageUnavailableReason)

    /// Misconfigured or unrecoverable.
    case failed(AuthClientError)
}

// NOTE: an `isSignedIn` convenience was considered and deliberately dropped.
// It is the exact Bool this enum exists to replace, and it answers wrongly for
// two of the cases above: a caller reaching for it gets `false` for `.guest`
// (which does hold usable credentials) and `false` for `.unavailable` (a storage
// failure, not a signed-out user) - the original bug decision 7 was written to
// fix. Both Amplify Android and Amplify Flutter have shipped field bugs from
// conflating "record present" with "credentials usable"; with N sessions that
// multiplies. Switch over the enum instead.
```

```swift
extension AmplifyCognitoClient {
    // A verb rather than a property, because it can await a restore.
    public func currentSessionState() async -> AuthSessionState

    // For UI that has to re-render when a session's state changes - a picker row
    // going stale, a screen reacting to its own session expiring - without polling.
    // Each element is the new state after a transition, not a change object.
    public func listenToSessionStateChanges() -> AsyncStream<AuthSessionState>

    // The same four events the Hub sends today, on a per-session stream.
    public func listenToAuthEvents() -> AsyncStream<AuthEvent>
}
```

### 14.3 Managing saved sessions

Updated to the shipped API (2026-10-02); §14.8 lists what changed from the first revision.

```swift
extension AmplifyCognitoClient {
    // Display text for a picker row. The library cannot invent this.
    public func setSessionLabel(_ label: String?) async throws

    // Listing, and acting on a saved record the app is not holding, without a network call
    // (sign-out revokes, so it calls Cognito). Each takes the same per-session storage lock
    // every Auth Client does, and each reports a storage failure rather than silently
    // reporting "nothing there": the listing and the purge throw it, and the sign-out
    // returns it as .failed.
    //
    // Saved sessions are scoped to the pools and the keychain access group, so each call
    // names both. Pass the same accessGroup as the clients' Options.accessGroup.
    //
    // signOut() keeps the row, so a signed-out session is still listed and resumable.
    // Pass includingSignedOut: true to see those rows; the default hides them, matching
    // MSAL's returnOnlySignedInAccounts.
    public static func storedSessions(
        configuration: AuthClientConfiguration,
        accessGroup: String? = nil,
        includingSignedOut: Bool = false
    ) async throws -> [StoredSession]

    // Never throws: .complete, .partial(...) or .failed(error), as signOut (4.7, 14.8).
    public static func signOutStoredSession(
        sessionId: SessionID,
        configuration: AuthClientConfiguration,
        accessGroup: String? = nil
    ) async -> AuthClientSignOutResult

    // LOCAL-ONLY: deletes the saved record without contacting Cognito, so the refresh
    // token stays valid server-side until it expires. Prefer signOutStoredSession,
    // which revokes first and then deletes.
    public static func purgeStoredSession(
        sessionId: SessionID,
        configuration: AuthClientConfiguration,
        accessGroup: String? = nil
    ) async throws

    // Migration: no call. The default session is the plugin's saved login, so there
    // is nothing to take over (4.8).
}
```

### 14.4 Credentials, and the escape hatch

Updated to the shipped API (2026-10-02; §14.8).

```swift
extension AmplifyCognitoClient {
    // What auth vends that no other client does: it is the credentials source.
    // The client is a Sendable final class, so these need no isolation.
    public var credentialsProvider: CognitoCredentialsProvider { get }
    public var userPoolTokenProvider: CognitoUserPoolTokenProvider { get }

    // Both are concrete, Sendable types bound to this session, rather than
    // existentials. CognitoCredentialsProvider conforms to AmplifyFoundation's
    // AWSCredentialsProvider, whose one operation is:
    //   func resolve() async throws -> AWSCredentials
    // so it can be handed to any client in the family unchanged. That protocol is
    // not Sendable, and making it so would break every existing conformer, so a
    // concrete Sendable type is what lets a Sendable client vend it without an
    // unsafe escape. Failures are AmplifyFoundation's CredentialsError (15.2).
    //
    // CognitoUserPoolTokenProvider is new here - AmplifyFoundation has no
    // token-provider protocol - with one operation:
    //   func accessToken() async throws -> String
    //
    // Note: AWSPluginsCore declares a *different* protocol also named
    // AWSCredentialsProvider (method: fetchAWSCredentials()). This client uses
    // only the AmplifyFoundation one.

    // Family convention. Each is nil without the matching pool: a configuration may have
    // an identity pool only, or a user pool only.
    public func getUserPoolClient() -> CognitoIdentityProviderClient?
    public func getIdentityClient() -> CognitoIdentityClient?
}
```

### 14.5 Everything else keeps today's semantics

Addressed per session, and required to reach full plugin parity: `signIn`, `confirmSignIn`, `signInWithWebUI`, `signOut`, `fetchAuthSession`, `getCurrentUser`, `deleteUser`, the sign-up family, password reset, user attributes, TOTP, devices, and federation.

### 14.6 Types

Every type this design adds, except the construction types 14.1 accounts for and two that are declared where the call explaining them lives: `AuthSessionState` is in 14.2, and `WebUIOptions` in 9.1. `StoredSession` and `SessionKind` are updated to the shipped API (2026-10-02; §14.8).

```swift
public struct StoredSession: Sendable, Equatable {   // one row of the picker
    public let sessionId: SessionID         // to construct the Auth Client the user picked
    public let label: String?               // the only name a user recognises
    public let username: String?            // fallback row title; nil for a guest row
    public let kind: SessionKind            // to render or filter rows

    // For an app's test doubles.
    public init(sessionId: SessionID, label: String?, username: String?, kind: SessionKind)
}

// The client depends only on AmplifyFoundation and AmplifyFoundationBridge - never on
// Amplify core - exactly as the CloudWatch and Kinesis clients do. So it owns the few
// model types the plugin borrows from Amplify core, and the plugin bridge maps them.

public struct AuthClientUser: Sendable, Equatable {
    public let username: String
    public let userId: String        // the user pool `sub`
}

/// The next step of a multi-step sign-in. Mirrors the plugin's `AuthSignInStep` case for
/// case (MFA code, TOTP setup, new password, custom challenge, email/SMS OTP, factor
/// selection, ...), with client-owned payload types in place of Amplify core's.
public enum AuthClientSignInStep: Sendable, Equatable { /* case-for-case mirror */ }

public struct SessionID: Hashable, Sendable, Codable {
    public var stringValue: String { get }                        // for app-side persistence
    public static let `default`: SessionID                        // stable; stringValue "$default", unforgeable via named(_:); the plugin's saved login (4.8)
    public static func named(_ id: String) throws -> SessionID     // [A-Za-z0-9_-]{1,64}
    public static func new() -> SessionID                          // library-minted
}

/// What a *saved* row is - the five combinations in Section 5. Distinct from
/// `AuthSessionState` in 14.2, which is what a live session is right now.
public enum SessionKind: Sendable, Equatable {
    case userPoolOnly, userPoolAndIdentityPool, guest, federated, signedOut   // signedOut is stored as "none"
}

/// The same four events the Hub sends today, and nothing more.
public enum AuthEvent: Sendable, Equatable {
    case signedIn, signedOut, sessionExpired, userDeleted
}

/// Why storage could not be read. Carried by `.unavailable` and by
/// `storageUnavailable`, so an app can tell "wait" apart from "this is misconfigured".
public enum StorageUnavailableReason: Sendable, Equatable {
    case locked         // device locked, so the keychain is unreadable. Retry later
    case interrupted    // transient I/O or keystore failure. Retry later
    case denied         // entitlement or access-group misconfiguration. Retrying will not help
}
```

### 14.7 Errors

All of these are cases of `AuthClientError`, which conforms to the foundation error protocol as every client in the family does.

| Error | Meaning |
|---|---|
| `configuration` | The configuration is missing, unreadable or incomplete - for example `amplify_outputs.json` lacks an `auth` key. The message names the missing key. |
| `storageUnavailable(reason:)` | Could not read or write secure storage. Usually transient, so do **not** show sign-in. |
| `sessionExpired` | The refresh token expired or was revoked, so this session needs a fresh sign-in. Other sessions are unaffected. |
| `notSignedIn` | Provider resolution against a signed-out session. Never a silent guest fallback. |
| `invalidSessionID` | Malformed session ID: character set or length. |
| `challengeExpired` | A persisted mid-sign-in challenge is no longer valid, so restart sign-in. |
| `browserBusy(holder: SessionID)` | Another session has a hosted-UI sign-in in flight. |
| `sessionConfigurationMismatch(SessionID)` | A client was constructed with a session ID that is already live under a different user pool, identity pool or settings. Thrown instead of silently attaching - see D.1. |
| `validation(field:)` | An argument the caller passed is invalid - for example a malformed issuer or account name for a TOTP setup URI. Names the offending field; retrying with the same input will not help. |

### 14.8 Amendments (2026-09-27, public API review)

The shipped `@_spi(AmplifyExperimental)` surface differs from 14.1 to 14.7 as follows. The API docs in
`AmplifyClients/AmplifyCognitoClient/Sources` are the reference.

- **`getUserPoolClient()` is optional** (`CognitoIdentityProviderClient?`, `nil` without a user pool), like
  `getIdentityClient()`, since a configuration may have an identity pool only (14.4).
- **Sign-outs return `AuthClientSignOutResult`, in the plugin's shape**, not the plugin's
  `AuthSignOutResult` (14.3). The client does not depend on Amplify core, so it owns the type. §4.7 has the
  full list of outcomes.
  - **No throw.** `signOut(options:)`, `signOut(presentationAnchor:options:)` and
    `signOutStoredSession(sessionId:configuration:accessGroup:)` are `async`, not `async throws`. The two
    `signOut` calls are `@discardableResult`, as the plugin's is. `purgeStoredSession` still throws: the plugin
    has no such call.
  - **Cases.** `.complete`, `.partial(revokeTokenError:globalSignOutError:hostedUIError:storageError:)` and
    `.failed(AuthClientError)`. `signedOutLocally` is false only for `.failed`. `storageError` is client-only.
    `==` compares errors as `AuthSessionState.failed` does (`isEquivalent(to:)`).
  - **`.failed`, with the session still signed in:** another sign-in replaced the session during the sign-out
    (`.invalidState`); a storage failure before the local sign-out; `sessionConfigurationMismatch` and any other
    error before anything was revoked; a closed hosted-UI sign-out page (`.userCancelled`), unless the session
    was already expired; any hosted-UI sign-out page that could not be shown or completed, including no hosted-UI
    configuration or sign-out redirect URI; task cancellation before anything was revoked, as
    `.failed(.unknown("The sign-out was cancelled before anything was revoked; the session is still signed in.",
    "Retry the sign-out.", CancellationError()))`.
  - **A purge that fails after the local sign-out succeeded** returns `.partial` with `storageError` set, and
    `signedOutLocally == true`.
  - **As the plugin does:** a failed global sign-out adds the plugin's placeholder `revokeTokenError`.
  - **Once a revoke has completed, cancellation never stops the local clear.**
  - **Documented differences from the plugin:** `.partial` carries errors only, no raw tokens (a security fix),
    and has the client-only `storageError`; a federated session can be signed out; `purgeStoredSession`; the
    window is required for the hosted-UI sign-out page.
  - *Earlier revision (2026-09-27):* sign-outs threw on failure, and returned a `.partial` struct or a separate
    case for a sign-out that another sign-in overtook. Replaced on 2026-10-02.
- **`AuthSessionState` has a separate `.federated(identityId:)`** (14.2). A federated session has no user pool
  user, so it is not `.signedIn(AuthClientUser)`.
- **The static calls take `accessGroup:`**: `storedSessions(configuration:accessGroup:includingSignedOut:)`,
  `signOutStoredSession(sessionId:configuration:accessGroup:)` and
  `purgeStoredSession(sessionId:configuration:accessGroup:)` (14.3). Saved sessions are scoped to the pools and
  the keychain access group, so a listing or a stored-session call names both.
- **`SessionKind.none` is renamed `.signedOut`** (14.6). `.none` collided with `Optional.none`: with an optional
  row, `row?.kind == .none` compiled as a `nil` check. The stored spelling is unchanged (`"none"`).
- **`SessionID.named("$default")` returns `.default`** (14.6), so a persisted `stringValue` always rebuilds its
  ID; every other spelling with a `$` is still refused.
- **`StoredSession` has a public initializer**, for an app's test doubles, like the client's other result types.
- **`CredentialsError` and `StorageUnavailableReason` are `@_spi(AmplifyExperimental)`** in AmplifyFoundation
  (decided 2026-09-27), like the rest of the client, so they do not become stable API with the next release.
- **Public enums may gain cases** in a minor release, and each says so. `AuthEvent` is no longer "the same four
  events, and nothing more" (14.6).
- **Errors** (14.7). `AuthClientError`'s cases are:

| Error | Meaning |
|---|---|
| `configuration` | The configuration is missing, unreadable, incomplete, or a Gen1 `amplifyconfiguration.json`; or the session has no pool the operation needs. |
| `storageUnavailable(reason)` | Secure storage could not be read or written, or did not answer in time. Usually transient, so do **not** show sign-in. |
| `sessionExpired` | The refresh token (or a federated session's provider token) expired or was revoked, so this session needs a fresh sign-in. Other sessions are unaffected. |
| `notSignedIn` | The session has no user pool user: signed out, a guest, federated, or (for the operations on the signed-in user) waiting on a challenge. Never a silent guest fallback. |
| `invalidSessionID` | Malformed session ID: empty, too long, or a character outside `[A-Za-z0-9_-]`. |
| `challengeExpired` | Cognito no longer accepts the sign-in's challenge session, so restart sign-in. |
| `browserBusy(holder:)` | The process's one system sheet (hosted-UI sign-in or sign-out page, or passkey sheet) is held, or a `.wait(timeout:)` expired first. |
| `sessionConfigurationMismatch(SessionID)` | A session ID already live under a different user pool, identity pool, keychain access group or settings. Thrown instead of silently attaching - see D.1. |
| `validation(field:)` | An argument the caller passed is invalid. Names the offending field. |
| `service(AuthClientServiceErrorCode?)` | Cognito rejected the request; the code when the client recognises the exception. `AuthClientServiceErrorCode` is a plain value this error carries: it is not an `Error`, so it is never thrown or caught on its own, and its `errorDescription` is an ordinary property. Match it inside the case: `catch AuthClientError.service(.userNotConfirmed?, _, _, _)`. |
| `notAuthorized` | The caller is not allowed to perform the operation: a wrong password, a disabled user, a revoked token. |
| `invalidState` | The operation is not valid in the session's state: signed in already, federated, no sign-in in progress, or cancelled by a sign-out. |
| `userCancelled` | The user closed a system sheet, or `cancelWebUISignIn()` or `resetSystemSheet()` closed it. |
| `webAuthnCeremonyFailed(AuthClientWebAuthnCeremonyFailure)` | A local passkey ceremony failed before Cognito was asked anything. |
| `unexpectedIdentity(expected:returned:)` | A hosted-UI sign-in returned another user than the one asked for; nobody was signed in. |
| `unknown` | Anything else, including a saved record this version cannot read. |

---

OPTIONAL READ

---

## 15. Notes and callouts (optional reading)

Nothing here changes the design. These are the rules an implementer needs and a reviewer does not, collected out of the main line so the sections above stay short. Skip this on a first read.

### 15.1 Lifecycle

- **Configured by construction.** An Auth Client takes its configuration as a constructor argument and is usable the moment it exists. No global configure step and no "unconfigured" crash path, exactly like its siblings.

- **Restore is asynchronous, construction is not.** Operations wait internally for the saved session to load, so a caller never has to sequence around it. Only direct state inspection needs `currentSessionState()`. Restore decodes a stored record; it does not check expiry and does not touch the network, so waiting longer buys no information. Whether a session works is only ever established by a session read. **That internal wait is bounded, and a restore that cannot complete surfaces `storageUnavailable` rather than hanging.** The plugin's equivalent readiness check has neither a bound nor a failure state (C.4), and that is deliberately not inherited.

- **An Auth Client is a handle, and two handles can share one session.** Constructing a second `AmplifyCognitoClient` with the same session ID does not create a second session and does not throw. Both handles resolve to the same underlying session. A session's resources are released deterministically once the last handle to it goes away - which is what the Android sequencing in C.19 depends on, and why N handles cost one session's resources rather than N.

- **The mechanism, stated rather than implied.** Sharing is resolved by an internal process-wide table **keyed by session ID alone**, held weakly, with the entry removed when the last handle drops. Beside each entry the table records the configuration it was built with, in two parts: the **storage namespace** (the pool identifiers, region and access group that decide which keychain record the session reads) and a **fingerprint of the full configuration**. Constructing a client with a session ID that is already live then has exactly three outcomes:

| Same session ID, and... | Outcome |
|---|---|
| same namespace, same fingerprint | The handle joins the existing session |
| same namespace, different fingerprint | **Throws.** Same record, contradictory settings |
| different namespace | **Throws.** A session pointed at another user pool must not be silently attached to |

Keying on session ID alone is deliberate. Keying on the configuration would make the different-pool case a *miss* - a second session installed silently, which is the very case this rule exists to catch - and would let a cosmetic configuration change address a different session over the same stored record. This table is internal: no public static accessor, per C.6. **Why it has to exist at all:** it is what makes "one state machine per session ID" true, and therefore what makes divergence structurally impossible in-process. Without it, two handles are two state machines over one storage record — the shape Supabase ships and has publicly documented the cost of, whose observed harm is repeated unintended sign-out (`auth-js#213`, `supabase-js#2126`, `#2145`).

- **Two operations end a session, and they are named apart.** `signOut()` revokes tokens and clears the *credentials*, but **keeps the stored row** so a picker can still show "Alice — signed out, tap to resume"; the session lands in `.signedOut`. Deleting the row is a separate, explicit act: either `signOut(options: .init(purgeStoredSession: true))` in the same call, or the static `purgeStoredSession(sessionId:configuration:)` for a row no Auth Client is holding. Microsoft's cache behaves the same way — MSAL's account enumeration has `returnOnlySignedInAccounts` defaulting to true, i.e. a signed-out-but-still-listed record is a first-class state, which is why `storedSessions()` takes `includingSignedOut:` and defaults it to `false`.

- **Operations on one session are serialized; different sessions do not wait on each other.** Within a session, a sign-in and a sign-out are ordered and a refresh happens once rather than several times over. Across sessions, work proceeds independently, so one slow sign-in does not block another user. Today it blocks every auth call in the process.

### 15.2 The credential provider contract

One operation returning currently-valid credentials, refreshing on demand. Four rules, and rule 2 is the one with a security consequence:

1. **Bound to its session for life.** No ambient lookup. Which session a provider resolves is fixed when it is handed over. It is bound to the session, not to the user: after a sign-out and another user's sign-in on the same session ID, it serves the new user, and nothing tells the consumer the user changed.

2. **Fail rather than fall back.** If the session is signed out, resolution *fails* with `notSignedIn`. It must not quietly return guest credentials. A consumer wired to an authenticated identity receiving unauthenticated credentials is a privilege bug dressed as graceful degradation.

3. **Never serve a stale snapshot.** The provider resolves *through* the live session on every call. It must not keep its own cached credentials, or it can outlive sign-out.

4. **A provider keeps its session alive.** Handing a provider to a downstream client means that client's lifetime extends the session's, exactly as holding an Auth Client does. Downstream clients must still surface a credentials failure, which is the correct behaviour for an expired or revoked session and is what rule 2 produces.

5. **The error set is part of the contract, not an implementation detail.** A downstream client cannot decide between discarding buffered records and retrying a flush unless the failure tells it which. So the provider commits to raising these, and consumers commit to treating them this way:

| Error | What a downstream client should do |
|---|---|
| `notSignedIn` | Permanent for this session. Discard buffered records; do not retry. |
| `sessionExpired` | Recoverable by re-auth. Retain the buffer and retry the flush after sign-in. |
| `storageUnavailable(.locked / .interrupted)` | Transient. Retry with backoff. |
| `storageUnavailable(.denied)` | Permanent, and a misconfiguration. Fail loudly. |
| `notConfigured` | Permanent, and a misconfiguration: the provider cannot vend this kind of credential in its configuration, for example AWS credentials from a session with no identity pool. Fail loudly (`.failLoudly`). **Already shipped.** |

This lives in AmplifyFoundation rather than here, because `AWSCredentialsProvider` is shared and Kinesis, Firehose, Connect and EventEnrichment all consume it. **It is built:** `CredentialsError` (`notSignedIn`, `sessionExpired`, `storageUnavailable(StorageUnavailableReason)`, `notConfigured`, `unknown`), with the table above encoded on the error itself as `disposition` - `.discard`, `.retryAfterReauthentication`, `.retryWithBackoff`, `.failLoudly` - so consumers read one property instead of each re-deriving the mapping and getting one wrong. An unrecognised failure deliberately maps to retry rather than discard, so a case nobody anticipated can never cost buffered data.

### 15.3 Logging

The client logs through AmplifyFoundation's logging, as its siblings do (D.1).

- **Every client log line is under an `AmplifyCognitoClient.<area>` category** (`Sources/Support/ClientLog.swift`). The client's own areas are `SessionRecordStore`, `SessionSignOut`, `KeychainItemStore` and `DefaultSession`, beside the engine resources' existing names, such as `AmplifyCognitoClient.InitiateAuthSRP`. No category holds a session ID, because an app-chosen ID can be an email address.
- **The engine's six static log sites go through the caller's logger**: `MFAType`, `AuthFactorType`, `PlatformWebAuthnCredentials`, `KeychainStore`, and `AWSCognitoAuthCredentialStore` with `KeychainStoreMigrator`. Each takes a `logger:` from its caller, or the environment's (`environment.engineLogger`). So a client path never logs under a plugin category: an unknown MFA type parsed by the client logs under `AmplifyCognitoClient.MFAType`, not the plugin's `MFAType`. A plugin path logs exactly as before (the G5 golden is unchanged). One accepted leak stays: the plugin's public `AuthFlowType` decode, with no logger in its decoder, keeps the global router (`EngineAuthFactorType(decodingRawValue:)`); the client's decodes pass one.
- **The temporary warning** (§4.9) is logged at `warn`, under `AmplifyCognitoClient.DefaultSession`, naming no one. Logged once while the session is in memory. All handles share it; after every handle and provider is released, a new handle can log it again. The category also carries the warning that a login deleted by a configuration change could not be revoked (§6).
- **Verbose keychain lines name the record kind, not the keychain key**, because a key can hold a username or a session ID.

---

STOP READING

---

## Appendix A: Swift before and after

Swift-specific in mechanics, though the same shape holds on Android and Flutter.

### A.1 The shape of the change, in signatures

Today, auth is a global you configure once and then address implicitly:

```swift
try Amplify.add(plugin: AWSCognitoAuthPlugin())
try Amplify.configure()

try await Amplify.Auth.signIn(username: "alice", password: pw)
let user = try await Amplify.Auth.getCurrentUser()             // whoever is signed in
let session = try await Amplify.Auth.fetchAuthSession()         // ditto
```

With the Auth Client, the session is a value you hold. Nothing is implicit, and the type carries which user you mean:

```swift
// No global configure step, no plugin registry. Same construction as Kinesis or Connect.
let work = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: .named("work")))

try await work.signIn(username: "alice", password: pw)
let user = try await work.getCurrentUser()                      // unambiguously work's user
let session = try await work.fetchAuthSession()                  // unambiguously work's session

// And a second user is simply a second value:
let home = try AmplifyCognitoClient(configuration: config, options: .init(sessionId: .named("home")))
```

That is the entire design in eight lines: `Amplify.Auth.x()` becomes `authClient.x()`.

### A.2 Second sign-in, from refusal to legality

The plugin refuses, via a state-machine guard that runs after the call is admitted, and on one path cancels an in-flight sign-in rather than returning:

> `"There is already a user in signedIn state. SignOut the user first before calling signIn"`

It appears verbatim at three sites. The Auth Client keeps the rule but scopes it: a second sign-in on `work` is still that error, because one session is still one user. A second *user* is a second session, so the operation the plugin forbids no longer needs to exist. The guard fires on a session that is already *signed in*; a session sitting on a challenge is not, which is why 4.11 can tell the app to call `signIn` again and start the interrupted flow over.

### A.3 Where the session lives

One keychain blob under `amplify.<userPoolId>.<identityPoolId>.session`, pool ids only, no user component. The Auth Client adds the session ID to the key for named sessions. *Corrected 2026-10-02:* the record format is not byte-identical. A named session wraps the same `AmplifyCredentials` payload in an envelope, which is decode-compatible rather than byte-identical. The default session is the plugin's own record (decided 2026-10-02, §4.8), so it has nothing to migrate.

### A.4 How other code gets credentials

This pair is the design in miniature. **Before**, a consumer reaches for the global at the moment of each request:

```swift
// Inside the shared auth service every category uses:
let session = try await Amplify.Auth.fetchAuthSession()   // follows whoever is signed in
```

**After**, a consumer is handed a provider bound to one session, at construction:

```swift
let connect = AmplifyConnectClient(configuration: connectConfig,
                                   credentialsProvider: work.credentialsProvider)
```

The first form silently follows the current user; the second cannot. The "after" shape already ships in the newer clients, so this design does not invent it. It makes it the only form it participates in.

### A.5 The session cache is a state, not a dictionary

Worth knowing because it pre-empts the obvious objection. The plugin's cached session *is* a case of its authorization state machine, not a side cache keyed by user, so "just add a dictionary of users" does not work. The cardinality has to move to the object you hold.

### A.6 Sign-out blast radius

Global sign-out sends the **access token** and revokes all of that user's tokens server-side; ordinary sign-out revokes only **that session's** refresh token. Unchanged by this design, which is the proof that session isolation is client-side only.

### A.7 Device tracking, already correct

Device metadata is already keyed per username, and sign-out deliberately preserves it. This is the one thing the current design already gets right for multi-user, and it is where the three-level scoping model comes from.

### A.8 What the Auth Client must add rather than inherit

Two things exist today only as a side effect of being a singleton, and must be rebuilt deliberately:

- **Which lock protects the credential store.** Not the visible top-level facade queue, but a separate inner queue, which internal actions bypass entirely. Re-scope it per session, and do not assume actor isolation substitutes for it.

- **Browser exclusivity.** Enforced today only because the global queue happens to serialize everything.

And one thing must move: constructing the credential store performs keychain migration and can clear it, so migration is hoisted to a once-per-app step.

## Appendix B: the alternative in full

Section 10 has the summary and the side-by-side code. This is the detail, for anyone weighing the two designs or implementing the other one on another platform.

### B.1 Why JavaScript could do it cheaply

Amplify JS already stored token *values* per username, under keys shaped `CognitoIdentityServiceProvider.<clientId>.<username>.accessToken` and siblings. **Several users' tokens already coexisted on disk**, and the only thing missing was a way to resolve *which* username to read. So a list plus one resolver change was sufficient, and the whole production diff is a few hundred lines. That is a fact about the JS storage layout, not a criticism.

The resolver change is effectively one line. Every per-user key already derived from a single "who is the last auth user?" accessor, and that accessor is redefined to return the head of the list. The pre-existing `LastAuthUser` key stays as a compatibility mirror, always equal to position 0, so older code keeps working.

`listCurrentUsers` returns username, user id, and sign-in details, read from stored tokens with no refresh. Entries whose stored token is missing or undecodable are filtered out. An early revision of `setCurrentUser` triggered a refresh; review removed it, and that property is the one most worth preserving in any port.

### B.2 Events, and how existing apps keep working

New per-session events (`userSignedIn`, `userSignedOut`) fire on every sign-in and sign-out. The legacy `signedIn` and `signedOut` fire **only** at the empty-to-non-empty edges, so an existing single-session app sees exactly what it saw before. A `switchActiveUser` event fires whenever the active identity changes, whether from an explicit switch, from signing in while someone else is active, or from promotion after the active user signs out.

Sign-out clears the active user's tokens, removes them from the list, and **automatically promotes the next entry**. A consequence worth knowing: because the head *is* the active user, you cannot sign out the active user and land in a signed-out state while keeping others parked. There is also no public API to sign out a parked user.

Parked sessions are never refreshed. Their tokens sit and expire. A switch is instant, and the staleness is paid on first use, when a refresh runs and may fail. **So a successful switch is not a liveness guarantee**, and `listCurrentUsers` lists "sessions we have bytes for" rather than "sessions that will work". Same honesty problem as 4.2, and the same answer: validate on use.

### B.3 What it would take on mobile

The cost advantage is largely a JS-specific artifact, and being honest about that matters. Swift and Android store a session as **one opaque blob under one key**; Flutter uses discrete keys prefixed by client id. **None has a per-user dimension.** So JS's "we already stored tokens per user, we only needed a pointer" does not transfer. A mobile implementation would need:

1. **A session container type and its codec**, with a version field from day one.

2. **A migration** adopting today's single blob as a one-entry list: idempotent, tolerant of interruption, and **downgrade-aware**. That last point is a real trap. An older app version reading a new container gets a decode error, which today's startup path treats as "no session" and turns into a silent sign-out of *every* user. JS avoids this because its migration is additive. Keeping the legacy key as a live mirror of the active session, which is JS's compatibility trick, restores that property.

3. **Store and protocol changes** for per-session read, write, and delete, plus listing and setting the active session.

4. **State-machine work, the largest and least obvious part.** Today the session is held *by value* inside the authorization state, and duplicated in the authentication state. A switch must retarget both, atomically, from any resting state, without racing an in-flight refresh or sign-out. JS had nothing comparable, because its "state" was a single storage read. **This is where a mobile estimate actually lives, and the small JS diff badly understates it.**

5. **One accessor that everything resolving "the current user" funnels through**, the way JS's single accessor does.

6. **Per-session events and the boundary model**, so existing listeners keep working.

7. **A decision about where guest sessions live**, which the JS design leaves entirely open. Its list holds only user-pool usernames, and the guest identity sits in a separate pool-scoped key.

**One thing mobile could do better than JS.** Because only one session is active at a time, mobile could keep **all sessions plus the active pointer in a single record**. A single keychain item is one atomic unit, so every mutation - add, remove, switch, refresh - is one self-consistent write. That structurally removes several classes of bug the JS prototype has to manage: no skew between the list and the compatibility pointer, no delete-ordering hazard, no ghost or orphan entries, and no separator problem.

**And the asymmetry that makes a single shared layout hard.** That cheap single-record layout is available to the one-active design *precisely because* it never writes two sessions at once. This design cannot use it: two sessions refreshing concurrently would read-modify-write one record, and the storage layer has no compare-and-swap. **So the simplest layout is available to one design and structurally unavailable to the other**, which is the real reason "just share a layout and ship both" is not a free lunch.

### B.4 Defects in the prototype a port would have to fix

Cited as work items, not as reasons to reject the approach.

- **An unescaped separator.** Usernames are joined with commas, unescaped and unvalidated, so a comma-bearing username splits into phantom entries, makes the real user's tokens unreachable, and cannot be removed.

- **A multi-step sign-in resolves the storage namespace before granting list membership**, so completing an MFA challenge can write the new user's tokens over the previous user's.

- **Concurrent switch calls are an unguarded read-modify-write.**

### B.5 What this design takes from it

Credited rather than reinvented, whichever approach ships:

- **Decoupling token storage from the active pointer**, the strongest idea in the prototype, and a good invariant even when there is no pointer.

- **The boundary-event model**, which is why Section 8 keeps the legacy four events.

- **Switching as a non-destructive, membership-checked operation** that can neither create nor delete a session.

- **Skipping an event rather than emitting one with an empty user id.**

- **Per-user scoping on failure cleanup.** The prototype's sharpest lesson: a blanket "clear everything" call is exactly what breaks when storage gains a session dimension, and it existed in four places. Any mobile implementation should audit its own clear-everything paths first.

Where we differ, deliberately: a structured encoding rather than a delimiter-joined string, and sessions keyed by a stable ID rather than by username.

## Appendix C: investigation notes and evidence

Verified against `amplify-swift`, `amplify-android`, and `amplify-flutter` at `origin/main` as of 2026-08-11, the CloudWatch Logging client, and amplify-js PR #14875 (open, unmerged).

**C.1 The refusal is deliberate, not missing.** The "already a user in signedIn state" error appears at three sites in the Swift plugin, with a recovery suggestion. Android and Flutter refuse equivalently. So this design relaxes a deliberate constraint; it does not fix a bug.

**C.2 The state machine is already per-instance.** No static session state on any platform. Flutter constructs one per plugin instance and its tests build them standalone. This is the finding that makes the change tractable.

**C.3 Refresh-token expiry is not derivable offline.** The stored "refresh expired" marker is set only inside a session-expired error path, after a refresh has already failed over the network, and the refresh token is never parsed. Hence the rule in 4.2 that a picker row cannot promise liveness, and why the field is not on `StoredSession`.

**C.4 The plugin's readiness check has no timeout.** Every task file waits on an internal "did configuration finish?" check with no bound and no failure state. It is safe today only because there is exactly one credential store per process, serialized by its own **inner** queue, not by the visible facade queue (see A.8). Stating this as "a process-wide queue" is the sloppiness that invites the reply "then just make more instances"; the point is that the load-bearing lock is the inner one. Two things follow for the implementer: do not assume the visible facade queue is what serializes access, and do not inherit the unbounded wait. The Android analogue, where a dropped store event could turn a readiness wait into an invisible hang rather than an error, is **Appendix E.1** - stated there as something to validate rather than something established, and an Android prerequisite either way.

**C.5 Storage failure is currently reported as signed-out.** At startup, a keychain read failure other than "not found" is caught, logged, and coerced to "no credentials", which resolves to signed-out. So a locked keychain is indistinguishable from a signed-out user. Fixing this in the Auth Client is decision 7 in Section 12, and a prerequisite for both `AuthSessionState.unavailable` and the listing rule in 4.2.

**C.6 No client in the family uses a static factory or vends instances.** Every public client facade uses `public init`; there is no singleton and no static function returning a client. This is why 14.1 keeps a plain `init`, and why the handle model resolves sharing *inside* the initializer rather than by adding a static `shared(for:)` accessor, which would be a family deviation. Note this is a statement about **public API shape**, not about internals: resolving sharing inside `init` necessarily means an internal process-wide session table exists (see D.1). What the family forbids is exposing it.

**C.7 CloudWatch Logging did not make the plugin an adapter.** The shared plumbing was extracted into an internal module; the plugin file is byte-identical to main and does not reference the client. The client takes identity via a `setUserIdentifier(_:)` setter and never touches `Amplify.Auth`. It ships behind an experimental SPI flag. This is the precedent Section 3 and decision 1 rest on.


**C.9 The plugin already tracks every in-flight state, privately.** The internal authentication and authorization state machines cover signing in, signing out, fetching a session (unauthenticated and user-pool), refreshing, storing credentials, and deleting a user, at finer granularity than `AuthSessionState` exposes and none of it public. The machine also already has an internal replay-on-subscribe stream. One caution for whoever implements the public stream: the machine suppresses no-op transitions using equality that ignores payloads, so consecutive distinct challenges can compare equal and not emit, and a public stream must derive equality on the projected type.

**C.10 The Authenticator separates steps from busy-ness.** Amplify UI's Swift Authenticator models 24 UI steps in one type and keeps a separate `isBusy` flag for in-flight work, with errors as a third channel. 21 of its 24 steps are UI navigation. That separation is part of why 4.10 keeps in-flight work out of the state type entirely: the Authenticator's steps are mostly navigation, and a library state enum should not import them.

**C.11 Mid-sign-in is not durable today.** Nothing persists the Cognito challenge session, and the only persisted shapes are completed auth results. The state machine has no persisted initial state and always starts from "not configured". So a killed app loses partial sign-in progress.

**C.12 Two same-region Kinesis clients share one cache.** The SQLite filename is `<prefix>_<region>.db` and the records table has no owner column, so reads are unfiltered, `clearCache()` deletes across users, and the cached-size counter sums the whole table. No test constructs two clients simultaneously; RecordCache tests deliberately use in-memory or distinct identifiers. This is the basis of concern 13.1.

**C.13 The categories hold a stateless resolver, not a session.** Swift's `AWSAuthService` has no stored properties and calls the global on every request, and each plugin constructs its own instance, so N instances are indistinguishable from one. Cross-platform, only Android has a real injection seam and only for API; no platform has one for Storage or DataStore. DataStore additionally resolves sibling *plugins* from the global registry and names its SQLite file from the app bundle, and `clear()` deletes that file. Analytics and Push are worse than a missing seam: they resolve credentials through a process-wide static keyed only by app id and region, so two sessions targeting one Pinpoint app would share a context, which is structural rather than fixable by adding a parameter. This is the basis of limit 2.

**C.14 Whether a guest identity id survives sign-in is platform-dependent, and the platforms differ.** Recorded so nobody assumes continuity that is not there. The mechanics are an implementation detail, not a design decision.

**C.15 Why today's single record is not a live bug in the plugin.** The mechanism for one is present - one config-derived key, no discriminator, and guest and signed-in writes are the same operation - but within one plugin instance it is not reachable: the guest-fetch event is accepted only from two authorization states, a signed-in user with intact credentials reaches neither, and the plugin's facade queue serializes API calls. Today's real exposure is cross-process via a shared keychain group, mitigated only heuristically. Under this design the guard stops being what protects you, which is why the naming rule in Section 6 is universal rather than a special case for guests.

**C.16 Hosted UI already persists its own interrupted-flow state.** Flutter stores the OAuth `state` and PKCE `codeVerifier` and reads them back on configure, so it can validate and complete the flow once the OS relaunches the app through the redirect callback. Noted for the implementer as an existing storage shape to look at, not as a precedent for challenge persistence: the OAuth case is driven by an OS-level browser redirect rather than by the library holding a challenge.

**C.17 Mid-sign-in state is not merely unpersisted on Flutter; it is not serializable.** The Cognito session string, challenge name, challenge parameters, and SRP intermediates are private mutable fields on a live sign-in state-machine object. That machine has no storage access at all, its state type has only equality and debug conformances and no codec, and the session string is not even part of the challenge state a caller can observe. The only serializable state in that tree is the post-sign-in credential record. So Flutter's work for 4.11 starts one step earlier than Swift's, which already has a `Codable` challenge type. Android is uninspected on this point.

**C.18 The plugin's event suppression is process-wide.** The plugin keeps a single "last event" value and suppresses a repeat, which is correct with one session and wrong with two, since one session's sign-in could suppress another's. Any per-session event stream must scope that suppression per session.

**C.19 The Android credential store, in full.** This is **Appendix E** - both entries - written out so an Android maintainer can judge them rather than take them on faith. It is an implementation detail; it is here only for completeness. Everything below is from reading the code, and **no test anywhere exercises two concurrent store callers**, which is itself why concurrent safety cannot be ruled in or out from the code alone. The items below are what reading the code raised, not findings we have confirmed under two callers.

- **No request correlation.** Nothing ties a response back to the request that asked for it, so concurrent callers appear able to consume each other's results. Unverified, and the first thing E.1 asks to establish. With one session it cannot surface either way, because there is only ever one caller in flight.

- **Silent event dropping.** A store event can be dropped with no error surfaced, which would turn a readiness wait into an invisible hang rather than a failure.

- **Thread lifecycle.** Each `configure()` constructs two state machines, auth and credential store, and each gets its own `newSingleThreadContext`. **Nothing ever closes them.** So it is two dedicated OS threads per `configure()` call, and because `configure()` overwrites `lateinit` fields it is re-callable, with each extra call stranding two more thread contexts that are now both unreachable and unstoppable. One session hides this; several sessions make it observable. The handle model reduces the exposure, since N handles on one session cost one session's threads rather than 2N, but it does not remove the need for deterministic teardown when the last handle goes.

- **Suggested sequencing.** Validate correlation and silent-drop first, because if they are real they are correctness and they are what multi-session makes reachable, and either way they need test coverage that does not exist today. Then decide the dispatcher strategy: either move off dedicated thread contexts to a shared dispatcher with limited parallelism, which also fixes the re-callable-`configure()` leak, or add explicit lifecycle close wired to session teardown, which is the smaller change. Either satisfies the design, which needs only that a session's resources be released deterministically once nothing holds it.

## Appendix D: client-family conventions and construction reference

### D.1 The checklist every standalone client satisfies

Adopted here as-is. In the body only the two auth-specific points are called out: no `credentialsProvider` parameter, because auth produces one, and the CloudWatch-style coexistence with the plugin.

- Actors for mutable state.

- `StrictConcurrency` enabled, and everything `Sendable`.

- A public error enum conforming to the foundation error protocol, with `errorDescription` and `recoverySuggestion`.

- The shared logger.

- An `Options` struct with defaults, including a `configureClient`-style escape-hatch closure.

- An escape hatch exposing the underlying SDK client.

- Storage and network behind protocols, for testability.

- A privacy manifest.

- Dependencies limited to the shared foundation packages, not the plugin registry.

- A synchronous, throwing `public init`. No static factory and no instance vending.

### D.2 The sibling signatures the Auth Client matches

For anyone checking the claim in Section 3 that construction is the family's existing shape rather than something new.

```swift
// Connect
public init(configuration: ConnectClientConfiguration,
            credentialsProvider: any AWSCredentialsProvider)
public init(region: String, endpoint: String,
            credentialsProvider: any AWSCredentialsProvider)
public init(from resource: String = "amplify_outputs",   // on the Configuration type
            bundle: Bundle = .main) throws

// Kinesis
public init(region: String,
            credentialsProvider: any AmplifyFoundation.AWSCredentialsProvider,
            options: Options = Options()) throws

// Auth, proposed
public init(configuration: AuthClientConfiguration,
            options: Options = Options()) throws
```

### D.3 Document provenance

This is a proposal built on work already shipped: the construction shape, packaging, and conventions are taken from the standalone clients already in the repository rather than invented for auth. It joins the standalone clients already shipped - Kinesis, Firehose, Connect, EventEnrichment and CloudWatch Logging. The design itself is platform-agnostic; Swift is used as the worked example throughout. The body covers goals, use cases, and the API surface; the evidence, the alternative design, and the family conventions live in these appendices, which is what keeps the body short.

## Appendix E: Android prerequisites, for later discussion

Two things Android needs settled before it can ship this. Neither changes the design's shape and neither is a design choice, which is why they are parked here rather than carried in Section 13. Appendix C.19 holds the underlying evidence; these two entries are the open items themselves.

### E.1 Concurrent access to the Android credential store needs validation

The Android credential store has never had to serve two concurrent callers, because one session cannot produce them. Two sessions are two concurrent callers by construction, so **its safety under concurrent access has to be validated before Android ships this, and that validation has not been done.** Two things stood out while reading it and are where the investigation should start: there is no request correlation between a store request and its response, and events can be dropped with no error surfaced. Both are unreachable with one session. Whether they are genuine defects under two, or are prevented by something upstream that we did not read, is exactly what needs establishing rather than asserting.

This is an Android prerequisite rather than a design question. Appendix C.19 has the detail and a suggested sequencing, so an Android maintainer can assess it.

### E.2 Android thread contexts are never closed

Separate from E.1, and not a concurrency question - which is why it is its own entry. Nothing ever closes the single-thread contexts a session's state machines run on, and because `configure()` overwrites `lateinit` fields it is re-callable, so each extra call strands more of them. That makes this reachable today, without two sessions at all; one session merely hides it. What the design needs from Android is a session's resources released deterministically once nothing holds it. C.19's thread-lifecycle entry has the mechanism in full, along with two remediation options.
