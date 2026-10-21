# AmplifyCognitoClient (beta)

`AmplifyCognitoClient` is a standalone Amazon Cognito client. You construct it and hold it, like the other
clients in `AmplifyClients`. It needs no `Amplify.configure()` and no Auth plugin.

Each client is a handle onto one **session**, named by a `SessionID`. Several sessions can be signed in at the
same time, each with its own user, tokens, state and events. Every session can hand its AWS credentials to other
`AmplifyClients` (Kinesis, Firehose, Connect and the rest).

The Cognito logic (SRP, MFA, device tracking, token refresh, hosted UI, WebAuthn) is the same Cognito code the Auth
plugin uses.

## Contents

- [Status](#status)
- [Feedback](#feedback)
- [Install](#install)
- [Configure and create a client](#configure-and-create-a-client)
- [Sessions](#sessions)
- [Session state and events](#session-state-and-events)
- [Sign-up](#sign-up)
- [Sign-in](#sign-in)
- [Sign-in steps and confirmSignIn](#sign-in-steps-and-confirmsignin)
- [Resuming an interrupted sign-in](#resuming-an-interrupted-sign-in)
- [Hosted UI](#hosted-ui)
- [Tokens, sessions and credentials](#tokens-sessions-and-credentials)
- [Federation to the identity pool](#federation-to-the-identity-pool)
- [User attributes](#user-attributes)
- [Passwords](#passwords)
- [Devices](#devices)
- [MFA preferences and TOTP](#mfa-preferences-and-totp)
- [Passkeys (WebAuthn credentials)](#passkeys-webauthn-credentials)
- [Sign-out](#sign-out)
- [Delete the user](#delete-the-user)
- [Errors](#errors)
- [Moving from the Auth plugin](#moving-from-the-auth-plugin)
- [Changing the configuration](#changing-the-configuration)
- [Escape hatches and logging](#escape-hatches-and-logging)
- [Differences from the Auth plugin](#differences-from-the-auth-plugin)
- [Known limitations](#known-limitations)

## Status

| | |
|---|---|
| Stage | Beta, for feedback |
| API | Behind `@_spi(AmplifyExperimental)`. Any release may change or remove it |
| Platforms | iOS first: tested end to end on iOS only. It also builds for macOS, visionOS, tvOS and watchOS, which are untested in this beta. The hosted UI and passkeys are on iOS, macOS and visionOS only |
| Passkeys | iOS 17.4, macOS 13.5, visionOS 1.0 or later |
| Configuration | Gen2 `amplify_outputs.json` only. A Gen1 `amplifyconfiguration.json` is refused with `AuthClientError.configuration` |
| Amplify categories | Storage, API, Analytics and the other category plugins do **not** use these sessions. See [Tokens, sessions and credentials](#tokens-sessions-and-credentials) |

Public enums may gain cases in a minor release. Include `@unknown default` when you switch over them.

## Feedback

We want to hear what works, what doesn't, and what is confusing.

Open a GitHub issue on [aws-amplify/amplify-swift](https://github.com/aws-amplify/amplify-swift/issues) and put
`AmplifyCognitoClient` in the title.

Useful things to include: the API you called, what you expected, what happened, the `AuthClientError` case with its
`errorDescription` and `recoverySuggestion`, and whether the app also uses the Auth plugin. Don't include tokens,
passwords, pool IDs or user identifiers.

## Install

Add the package with Swift Package Manager and link the `AmplifyCognitoClient` product. Link `AmplifyFoundation`
too if you use the credentials-provider protocol, `CredentialsError`, `StorageUnavailableReason` or logging.

Pin the release exactly: any release may change or remove this beta API. One version applies to the whole package,
so the pin also sets the version of the Auth plugin and the other Amplify libraries your app uses.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/aws-amplify/amplify-swift", exact: "2.63.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "AmplifyCognitoClient", package: "amplify-swift"),
            .product(name: "AmplifyFoundation", package: "amplify-swift")
        ]
    )
]
```

In Xcode, use **File > Add Package Dependencies**, enter the repository URL, and choose the **Exact Version**
dependency rule with the release's version.

Import the client with the SPI:

```swift
@_spi(AmplifyExperimental) import AmplifyCognitoClient

// Only where you name CredentialsError or match a StorageUnavailableReason:
@_spi(AmplifyExperimental) import AmplifyFoundation
```

To name the `AWSCredentialsProvider` protocol or add a log sink (`AmplifyLogging`, `AmplifyOSLogSink`), a plain
`import AmplifyFoundation` is enough. See [Escape hatches and logging](#escape-hatches-and-logging).

## Configure and create a client

The configuration is the `auth` section of `amplify_outputs.json`. The file is read when an
`AuthClientConfiguration` is built from it. Building a client from an `AuthClientConfiguration` does no file I/O;
`AmplifyCognitoClient()` and `AmplifyCognitoClient(from:bundle:options:)` read the file first.

```swift
// Reads amplify_outputs.json from the main bundle; uses the default session.
let client = try AmplifyCognitoClient()

// The same configuration on its own: AuthClientConfiguration() loads amplify_outputs.json from the main bundle.
let defaultConfiguration = try AuthClientConfiguration()

// Or load the configuration once and pass it to every client.
let configuration = try AuthClientConfiguration(from: "amplify_outputs", bundle: .main)
let work = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(sessionId: .named("work"))
)
```

Pass the resource name without `.json`; a dotted name such as `"amplify_outputs.staging"` loads
`amplify_outputs.staging.json`. The initializer throws `AuthClientError.configuration` naming the problem: an empty
name, a name ending in `.json` (in any case), a missing file, a Gen1 file, a missing `auth` section or key, or a
value outside the schema.

To configure without a file:

```swift
let configuration = try AuthClientConfiguration(
    userPool: .init(
        poolId: "<user-pool-id>",
        appClientId: "<app-client-id>",
        region: "us-east-1"
    ),
    identityPool: .init(
        poolId: "<identity-pool-id>",
        region: "us-east-1",
        unauthenticatedIdentitiesEnabled: true
    )
)
let client = try AmplifyCognitoClient(configuration: configuration)
```

A configuration needs a user pool, an identity pool, or both. `UserPool` also takes the hosted UI settings
(`oauth`), the password policy, username attributes, required attributes, verification mechanisms and MFA
settings, all optional.

Construction is synchronous. The saved session is restored in the background, and every operation waits for that
restore, so you never have to sequence around it.

### Options

| Option | Default | What it does |
|---|---|---|
| `sessionId` | `.default` | The session this client is a handle onto |
| `accessGroup` | `nil` (the app's default) | The keychain access group the session is stored in, to share it with an extension or another app. Every handle on a session must pass the same value |
| `configureUserPoolClient` | `nil` | Customizes the user pool SDK client. See [Escape hatches and logging](#escape-hatches-and-logging) |

```swift
let client = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(sessionId: .default, accessGroup: "<team-id>.com.example.shared")
)
```

## Sessions

### Session IDs

| | |
|---|---|
| `SessionID.default` | The single-account session. It is also the only session that uses the Auth plugin's saved login: it reads and writes the plugin's own record (see [Moving from the Auth plugin](#moving-from-the-auth-plugin)) |
| `SessionID.named(_:)` | An ID your app chooses: 1 to 64 characters from `A-Z a-z 0-9 _ -`, case-sensitive. Throws `AuthClientError.invalidSessionID` otherwise |
| `SessionID.new()` | An ID the library mints. Each call returns a new one, so save it |

Use an opaque ID (`.new()`, or a tenant or workspace ID), not a username or `sub`: session IDs appear in error
descriptions.

To save an ID, store its `stringValue` and rebuild it with `named(_:)`. `named("$default")` gives `.default`, so a
saved `.default` comes back too. `SessionID` is also `Codable`.

Saved sessions, `.default` and named ones alike, live in the keychain, so on iOS they survive the app's uninstall and
reinstall, as the Auth plugin's saved login does: a reinstalled app finds them as they were, signed in or not. An ID
you saved in `UserDefaults` doesn't survive, so list the saved sessions (`storedSessions`) to find them again.

```swift
let id = SessionID.new()
UserDefaults.standard.set(id.stringValue, forKey: "lastSessionId")

// A later launch:
if let saved = UserDefaults.standard.string(forKey: "lastSessionId") {
    let client = try AmplifyCognitoClient(
        configuration: configuration,
        options: .init(sessionId: .named(saved))
    )
}
```

### Several sessions at once

Each session is independent. A sign-in, sign-out or deletion changes only its own session.

```swift
let personal = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(sessionId: .named("personal"))
)
let work = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(sessionId: .named("work"))
)

_ = try await personal.signIn(username: "user@example.com", password: "<password>")
_ = try await work.signIn(username: "other@example.com", password: "<password>")
```

Rules:

- Two clients with the same session ID are two handles onto one session. They share one state, one event stream
  and one token refresh. Building a second handle never fails because the ID is in use.
- Building a client for a session that is already live in the process under a different configuration (other
  pools, access group or settings, or `configureUserPoolClient` on one handle and not the other) throws
  `AuthClientError.sessionConfigurationMismatch`. Two different closures can't be compared, so the first handle's
  wins.
- A session stays in memory while any handle or credentials provider for it is alive. Its streams finish when the
  last one goes away.
- A global sign-out revokes the *user's* tokens everywhere, so another session holding the same user finds out at
  its next refresh.
- The same user may be signed in to two sessions.

### Labels

A label is the text your account picker shows for a session. The library cannot invent it. It survives sign-out,
and is cleared when a different user signs in to the session.

A label is bound to the session's user:

- It is kept when the same user signs in again after a sign-out.
- A label set before any user signed in to the session, or while a guest held it, is kept by the next user who
  signs in. A label set on a signed-out row belongs to the user who signed out: another user's sign-in drops it.
- It is dropped when another user, or a guest, takes the session. For example, alice's session is labelled "Work";
  alice signs out and bob signs in to the same session: the label is gone, and bob's row has no label until the app
  sets one.
- For `.default` the label is kept beside the plugin's record, which has no room for it. It is hidden while the
  plugin's record holds another user, for example because the plugin signed bob in over alice's session. See
  [Labels and the signed-out row after a plugin action](#labels-and-the-signed-out-row-after-a-plugin-action).

```swift
try await work.setSessionLabel("Work")
try await work.setSessionLabel(nil) // clear it
```

### Listing saved sessions

`storedSessions` lists the sessions saved on this device for one configuration and access group, without a network
call. Use it to build an account picker.

```swift
let rows = try await AmplifyCognitoClient.storedSessions(
    configuration: configuration,
    includingSignedOut: true
)
for row in rows {
    let title = row.label ?? row.username ?? "Guest"
    let subtitle: String
    switch row.kind {
    case .userPoolOnly, .userPoolAndIdentityPool:
        subtitle = "Signed in"
    case .guest:
        subtitle = "Guest"
    case .federated:
        subtitle = "Federated"
    case .signedOut:
        subtitle = "Signed out"
    @unknown default:
        subtitle = ""
    }
    print(title, subtitle)
}

// Open the session the user picked.
if let picked = rows.first {
    let client = try AmplifyCognitoClient(
        configuration: configuration,
        options: .init(sessionId: picked.sessionId)
    )
}
```

- A row says a session was saved. It cannot say the session still works: an expired refresh token is only found
  by using it.
- Signed-out rows are listed only with `includingSignedOut: true`.
- A session whose first sign-in stopped on a challenge is not listed until that sign-in completes.
- `.default`'s row comes from the Auth plugin's saved login, with its label while the label belongs to the user the
  plugin's record holds. After the plugin signs out (or deletes its record), `.default` is a signed-out row naming
  the last user *the client* saved it for: the client keeps that name beside the plugin's record and updates it only
  when it writes the session itself. So if the plugin signs bob in over alice's session and then signs out, without
  the client running in between, the row still names alice, with alice's label.
- A row's kind follows the current configuration: after a change that removes the identity pool, `.default`'s copied
  login is listed as `.userPoolOnly`, as a named session is, although its saved bytes are the plugin's as they were.
- Listing also deletes interrupted sign-ins saved more than 15 minutes ago.
- A failure throws `AuthClientError.storageUnavailable`. You never get an empty list for a failure.

### Signing out or purging a saved session without a client

```swift
let id = try SessionID.named("work")

// Revokes the tokens, then clears them from this device. Keeps the row. Never throws.
let result = await AmplifyCognitoClient.signOutStoredSession(sessionId: id, configuration: configuration)
if !result.signedOutLocally {
    print("Still signed in:", result)
}

// Local only: deletes the records without revoking anything.
try await AmplifyCognitoClient.purgeStoredSession(sessionId: id, configuration: configuration)
```

If a client for that session is live in the process, both calls go through it, so its state, streams and providers
see the change at once. `signOutStoredSession` returns the same result as `signOut` (see [Sign-out](#sign-out)) and
never throws. It never signs out a user who signs in while the call runs: if someone else signs in to that session
meanwhile, it returns `.failed(.invalidState)` and they stay signed in. A client for that session live with other
pools in the same access group makes it `.failed(.sessionConfigurationMismatch)` (a purge throws it); a client live
in another access group holds a different saved session, and is left alone. A purge leaves the refresh token valid
on the server until it expires, so prefer `signOutStoredSession`. A named session's purge deletes the session's
small configuration marker last; an app terminated just before that leaves the marker, which holds no credentials,
and the next purge of that session removes it.

There is no "sign out of every session" call. Loop over the listing, once per configuration and access group the
app has used:

```swift
for row in try await AmplifyCognitoClient.storedSessions(configuration: configuration) {
    let result = await AmplifyCognitoClient.signOutStoredSession(
        sessionId: row.sessionId,
        configuration: configuration
    )
    if case .failed(let error) = result {
        print("Could not sign out \(row.sessionId):", error)
    }
}
```

## Session state and events

### State

`currentSessionState()` says what the session is right now. It never throws.

| State | Meaning |
|---|---|
| `.signedIn(AuthClientUser)` | Signed in to the user pool, by any means |
| `.federated(identityId:)` | Federated to the identity pool with another provider's token. No user pool user |
| `.guest` | No user, but guest (unauthenticated) identity pool credentials. Reached only after something fetched them |
| `.signedOut` | No user and no credentials |
| `.awaitingChallenge(AuthClientSignInStep)` | A sign-in is waiting on the user. Can survive a relaunch |
| `.unavailable(StorageUnavailableReason)` | The keychain could not be read. **Not** signed out: don't show a sign-in screen; retry |
| `.failed(AuthClientError)` | Misconfigured or unrecoverable |

```swift
switch await client.currentSessionState() {
case .signedIn(let user):
    print("Signed in as", user.username)
case .federated(let identityId):
    print("Federated identity", identityId)
case .guest:
    print("Guest credentials")
case .signedOut:
    print("Show sign-in")
case .awaitingChallenge(let step):
    print("Resume sign-in at", step)
case .unavailable(let reason):
    // Storage could not be read. Not signed out: do not show sign-in.
    print("Storage unavailable:", reason)
case .failed(let error):
    print(error.errorDescription, error.recoverySuggestion)
@unknown default:
    break
}
```

There is no `isSignedIn`: it would be wrong for `.guest`, which has usable credentials, and for `.unavailable`,
which is a storage failure.

A dead refresh token leaves the state at `.signedIn(user)`, as the plugin's `isSignedIn` stays true: the session
sends `.sessionExpired` and its token requests fail with `sessionExpired`. React to the event or the error; the state
stream doesn't show it.

`StorageUnavailableReason` is `.locked` (the device is locked; retry after unlock), `.interrupted` (transient;
retry with backoff) or `.denied` (an entitlement or access-group problem; retrying won't help). Matching a reason
needs `@_spi(AmplifyExperimental) import AmplifyFoundation`:

```swift
if case .unavailable(.locked) = await client.currentSessionState() {
    print("Try again once the device is unlocked")
}
```

### State changes and events

Both streams are per session, have no replay, and finish when the last handle and provider for the session go
away. A subscription does not keep the session alive, but a task that captures the client does: take the streams
first, as below, or cancel the task (SwiftUI's `.task` does) to let the session go.

```swift
let states = client.listenToSessionStateChanges()
let events = client.listenToAuthEvents()

Task {
    for await state in states {
        print("New state:", state)
    }
}

Task {
    for await event in events {
        switch event {
        case .signedIn:
            print("Signed in")
        case .signedOut:
            print("Signed out")
        case .sessionExpired:
            print("Sign in again")
        case .userDeleted:
            print("User deleted")
        @unknown default:
            break
        }
    }
}
```

| Event | Sent when |
|---|---|
| `.signedIn` | A user signed in to this session, by any means. Federation sends none |
| `.signedOut` | The session's credentials were removed: sign-out, purge, or a cleared federation. Not sent if there were none |
| `.sessionExpired` | The refresh token (or a federated session's provider token) was found dead. Sign in again. The state stays `.signedIn(user)` |
| `.userDeleted` | The user was deleted and the session signed out |

Events come only from this session's own operations. A sign-in by another process (an app extension, say) sends
no event here. To see identity changes from federation, watch the state stream.

## Sign-up

Sign-up acts on a username, not on the session's user, so it runs whether the session is signed in or not.

```swift
let result = try await client.signUp(
    username: "user@example.com",
    password: "<password>",
    options: .init(userAttributes: [
        AuthClientUserAttribute(.email, value: "user@example.com")
    ])
)

switch result.nextStep {
case .confirmUser(let details, _, _):
    print("Code sent to", details?.destination as Any)
case .completeAutoSignIn:
    _ = try await client.autoSignIn()
case .done:
    break
@unknown default:
    break
}

let confirmed = try await client.confirmSignUp(
    for: "user@example.com",
    confirmationCode: "123456"
)
if case .completeAutoSignIn = confirmed.nextStep {
    let signIn = try await client.autoSignIn()
    print(signIn.nextStep)
}

let delivery = try await client.resendSignUpCode(for: "user@example.com")
print(delivery.destination)
```

A passwordless sign-up passes no password:

```swift
_ = try await client.signUp(
    username: "user@example.com",
    options: .init(userAttributes: [AuthClientUserAttribute(.email, value: "user@example.com")])
)
let confirmed = try await client.confirmSignUp(for: "user@example.com", confirmationCode: "123456")
if case .completeAutoSignIn = confirmed.nextStep {
    _ = try await client.autoSignIn()
}
```

About `autoSignIn()`:

- It signs the user in to **this** session. Another session's `autoSignIn()` never sees this sign-up.
- What the sign-up left is held in memory. **Keep a handle alive between `confirmSignUp` and `autoSignIn`**: if the
  session is released in between, there is nothing to complete.
- Only the session's last `signUp` or `confirmSignUp` counts. Signing in or out doesn't clear it, so calling
  `autoSignIn()` again after a sign-out reaches Cognito, which refuses the spent session with `.notAuthorized`.
- With nothing ready, or with the session already signed in, it throws `.invalidState`.

`AuthClientSignUpOptions` also takes `validationData` (for the pre-sign-up trigger) and `clientMetadata`.
`AuthClientConfirmSignUpOptions` takes `clientMetadata` and `forceAliasCreation`.

## Sign-in

`signIn` is refused (`.invalidState`) only when **this** session is already signed in or federated. Other
sessions never block it. A guest session signs in on the same session, but its identity ID is not kept: as with
the Auth plugin, the signed-in identity ID is the one the identity pool maps the login to. A session waiting on a
challenge starts over.

A session that reported `sessionExpired` in this process may sign in again without signing out. That is held in
memory only: after a relaunch, or once every handle and provider for the session is released, `signIn` is refused
with `.invalidState` again until a token request finds the dead token again, so sign out first, as with the plugin.

The result's `nextStep` is `.done` when the user is signed in. Otherwise it is the step to present; see
[Sign-in steps and confirmSignIn](#sign-in-steps-and-confirmsignin). A user who hasn't confirmed their sign-up
comes back as the `.confirmSignUp` step, not as a thrown `.service(.userNotConfirmed?)`, and so does one whose
password must be reset (`.resetPassword`).

### Password (SRP)

SRP is the default for an `amplify_outputs` configuration.

```swift
let result = try await client.signIn(username: "user@example.com", password: "<password>")
if result.nextStep == .done {
    print("Signed in")
} else {
    print("Next:", result.nextStep)
}
```

An SRP sign-in is two Cognito calls, and Cognito accepts the password proof only for about 25 to 30 seconds after
its challenge. If the app is suspended between the two (the user switches away right after tapping Sign in) and
the proof reaches Cognito later than that, the sign-in fails with `.notAuthorized` "Incorrect username or
password." although the password is right. The session stays signed out. The client doesn't retry it: ask the
user to sign in again.

### Password (USER_PASSWORD_AUTH)

```swift
let result = try await client.signIn(
    username: "user@example.com",
    password: "<password>",
    options: .init(authFlowType: .userPassword, clientMetadata: ["source": "ios"])
)
```

`clientMetadata` is passed to the user pool's Lambda triggers.

### Flows

| `authFlowType` | Use |
|---|---|
| `nil` | The configuration's flow (`userSRP` for `amplify_outputs`) |
| `.userSRP` | Password, with SRP |
| `.userPassword` | Password sent directly. Runs the user migration trigger if one is set |
| `.customWithSRP` | SRP, then a custom challenge |
| `.customWithoutSRP` | A custom challenge only |
| `.userAuth(preferredFirstFactor:)` | Choice-based sign-in: password, email or SMS code, or passkey |

### Passwordless: email or SMS code

```swift
let result = try await client.signIn(
    username: "user@example.com",
    options: .init(authFlowType: .userAuth(preferredFirstFactor: .emailOTP))
)
if case .confirmSignInWithOTP(let details) = result.nextStep {
    print("Code sent to", details.destination)
    let code = await ask("Code")
    _ = try await client.confirmSignIn(challengeResponse: code)
}
```

For SMS, use `.smsOTP`:

```swift
let result = try await client.signIn(
    username: "+15555550100",
    options: .init(authFlowType: .userAuth(preferredFirstFactor: .smsOTP))
)
```

`ask(_:)` in these examples stands for your own UI.

Without a preference, Cognito may ask which factor to use:

```swift
let result = try await client.signIn(
    username: "user@example.com",
    options: .init(authFlowType: .userAuth(preferredFirstFactor: nil))
)
if case .continueSignInWithFirstFactorSelection(let factors) = result.nextStep,
   factors.contains(.emailOTP) {
    _ = try await client.confirmSignIn(
        challengeResponse: AuthClientFactorType.emailOTP.challengeResponse
    )
}
```

### Passkeys (WebAuthn)

A passkey sign-in shows the system passkey sheet, so it needs a window: use the `signIn` overload that takes a
`presentationAnchor`. The client never looks for a window itself.

```swift
@MainActor
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
func signInWithPasskey(client: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async throws {
    let result = try await client.signIn(
        username: "user@example.com",
        presentationAnchor: window,
        options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
    )
    print(result.nextStep) // .done
}
```

If Cognito offers a passkey in a first-factor selection, answer `"WEB_AUTHN"`. The sheet uses the window given to
`signIn`, or the one you pass to `confirmSignIn`:

```swift
@MainActor
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
func selectPasskey(client: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async throws {
    let result = try await client.signIn(
        username: "user@example.com",
        presentationAnchor: window,
        options: .init(authFlowType: .userAuth(preferredFirstFactor: nil))
    )
    if case .continueSignInWithFirstFactorSelection(let factors) = result.nextStep,
       factors.contains(.webAuthn) {
        _ = try await client.confirmSignIn(
            challengeResponse: AuthClientFactorType.webAuthn.challengeResponse,
            presentationAnchor: window
        )
    }
}
```

Presentation anchor rules:

| Rule | Result |
|---|---|
| `signIn` or `confirmSignIn` without a window, asking for a passkey (`.userAuth(preferredFirstFactor: .webAuthn)`, or a `"WEB_AUTHN"` answer with no window at all) | `.validation(field: "presentationAnchor")` before anything is sent. A pending selection stays pending |
| The window has closed when the sheet would appear | `.validation(field: "presentationAnchor")`, nothing shown. The window is held weakly |
| Another sheet (hosted UI or passkey, any session) is up | `.browserBusy(holder:)` |
| The user closes the sheet | `.userCancelled` |
| The device cannot complete the ceremony | `.webAuthnCeremonyFailed(...)` |
| The calling task is cancelled | The sheet closes and the call throws `CancellationError` |

A failed passkey step ends the sign-in. Call `signIn` again to retry. Your app also needs the Associated Domains
entitlement (`webcredentials:`) for the relying party the user pool uses.

### Custom auth

```swift
let result = try await client.signIn(
    username: "user@example.com",
    options: .init(authFlowType: .customWithoutSRP)
)
if case .confirmSignInWithCustomChallenge(let parameters) = result.nextStep {
    print(parameters ?? [:])
    _ = try await client.confirmSignIn(challengeResponse: "<answer>")
}

// Custom auth after an SRP password check.
_ = try await client.signIn(
    username: "user@example.com",
    password: "<password>",
    options: .init(authFlowType: .customWithSRP)
)
```

### Cancellation

Once a sign-in is sent to Cognito it runs to its end even if the calling task is cancelled, so tokens Cognito
issued are never lost; the call can then succeed with `Task.isCancelled` true. A call cancelled while it still
waits (for the restore, or behind another sign-in on the session) throws `CancellationError` and sends nothing.

## Sign-in steps and confirmSignIn

`confirmSignIn(challengeResponse:options:)` answers the step the session is waiting on. It returns the next step,
or `.done`.

| Step | Answer with |
|---|---|
| `.confirmSignInWithSMSMFACode(details, info)` | The SMS code |
| `.confirmSignInWithTOTPCode` | The code from the authenticator app |
| `.confirmSignInWithOTP(details)` | The email or SMS code |
| `.continueSignInWithMFASelection(allowed)` | `AuthClientMFAType.<type>.challengeResponse` (`"SMS_MFA"`, `"SOFTWARE_TOKEN_MFA"`, `"EMAIL_OTP"`). Anything else is `.validation` |
| `.continueSignInWithMFASetupSelection(allowed)` | `AuthClientMFAType.<type>.challengeResponse` for the type to set up |
| `.continueSignInWithTOTPSetup(details)` | A code from the authenticator app, after the user adds `details`. `options.friendlyDeviceName` names the device |
| `.continueSignInWithEmailMFASetup` | The email address to use |
| `.confirmSignInWithNewPassword(info)` | The new password. Pass required attributes in `options.userAttributes` |
| `.confirmSignInWithPassword` | The password (after choosing `.password` or `.passwordSRP`) |
| `.continueSignInWithFirstFactorSelection(factors)` | `AuthClientFactorType.<type>.challengeResponse`. Anything else is `.validation` |
| `.confirmSignInWithCustomChallenge(info)` | Your custom answer |
| `.resetPassword(info)` | Not answered here: reset the password, then sign in again |
| `.confirmSignUp(info)` | Not answered here: confirm the sign-up, then sign in again |
| `.done` | Nothing: signed in |

`AuthClientMFAType.rawValue` (`"sms"`, `"totp"`, `"email"`) is not a valid answer. Use `challengeResponse`.

A loop over every step:

```swift
func completeSignIn(client: AmplifyCognitoClient, startingAt first: AuthClientSignInStep) async throws {
    var step = first
    while step != .done {
        let result: AuthClientSignInResult
        switch step {
        case .confirmSignInWithSMSMFACode(let details, _):
            print("Code sent to", details.destination)
            result = try await client.confirmSignIn(challengeResponse: await ask("SMS code"))

        case .confirmSignInWithOTP(let details):
            print("Code sent to", details.destination)
            result = try await client.confirmSignIn(challengeResponse: await ask("Code"))

        case .confirmSignInWithTOTPCode:
            result = try await client.confirmSignIn(challengeResponse: await ask("Authenticator code"))

        case .continueSignInWithMFASelection(let allowed):
            let type = await pick(allowed)
            result = try await client.confirmSignIn(challengeResponse: type.challengeResponse)

        case .continueSignInWithMFASetupSelection(let allowed):
            let type = await pick(allowed)
            result = try await client.confirmSignIn(challengeResponse: type.challengeResponse)

        case .continueSignInWithTOTPSetup(let details):
            let uri = try details.getSetupURI(appName: "ExampleApp")
            print("Open in an authenticator app:", uri)
            result = try await client.confirmSignIn(
                challengeResponse: await ask("Authenticator code"),
                options: .init(friendlyDeviceName: "My phone")
            )

        case .continueSignInWithEmailMFASetup:
            result = try await client.confirmSignIn(challengeResponse: await ask("Email address"))

        case .confirmSignInWithNewPassword:
            result = try await client.confirmSignIn(
                challengeResponse: await ask("New password"),
                options: .init(userAttributes: [AuthClientUserAttribute(.givenName, value: "Sam")])
            )

        case .confirmSignInWithPassword:
            result = try await client.confirmSignIn(challengeResponse: await ask("Password"))

        case .continueSignInWithFirstFactorSelection(let factors):
            let factor = await pick(factors)
            result = try await client.confirmSignIn(challengeResponse: factor.challengeResponse)

        case .confirmSignInWithCustomChallenge:
            result = try await client.confirmSignIn(challengeResponse: await ask("Answer"))

        case .resetPassword:
            // Not a confirmSignIn step: reset the password, then sign in again.
            return

        case .confirmSignUp:
            // Not a confirmSignIn step: confirm the sign-up, then sign in again.
            return

        case .done:
            return

        @unknown default:
            return
        }
        step = result.nextStep
    }
}
```

`ask(_:)` and `pick(_:)` stand for your UI. If the first factor could be a passkey, use the
`confirmSignIn(challengeResponse:presentationAnchor:options:)` overload for that answer.

Errors to expect from `confirmSignIn`:

| Error | Meaning |
|---|---|
| `.notAuthorized`, `.service(.codeMismatch?, …)` | Wrong answer. The challenge is still pending: let the user retry |
| `.challengeExpired` | Cognito no longer accepts the challenge (three minutes by default, at most 15). Call `signIn` again |
| `.invalidState` | No sign-in in progress, or it can no longer continue. Call `signIn` again |
| `.validation(field: "challengeResponse")` | Empty, or not one of the step's choices. Nothing was sent |

## Resuming an interrupted sign-in

When a sign-in stops on a challenge, the challenge is saved in the session's keychain storage (device-only, never
synchronized). The saved data is the username (and the alias you signed in with), Cognito's challenge session and
challenge parameters (which can include the user's attributes, such as an email address or phone number), and the
step; for a TOTP setup, also the shared secret. The password is never saved.

A client built later with the same session ID starts in `.awaitingChallenge(step)`. Answer it with
`confirmSignIn`, or start over with `signIn`.

```swift
let client = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(sessionId: .named("work"))
)
if case .awaitingChallenge(let step) = await client.currentSessionState() {
    do {
        try await completeSignIn(client: client, startingAt: step)
    } catch AuthClientError.challengeExpired {
        // Cognito no longer accepts the challenge: start sign-in over.
    }
}
```

- A challenge whose Cognito session has expired fails the answer with `.challengeExpired`.
- A challenge saved more than 15 minutes ago is discarded at launch.
- The Auth plugin does not do this: its interrupted sign-in is lost when the app closes.

## Hosted UI

The hosted UI (managed login) runs in an `ASWebAuthenticationSession` sheet over the window you pass. It needs
`auth.oauth` in the configuration. iOS, macOS and visionOS only.

```swift
@MainActor
func hostedUI(client: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async throws {
    // Private browser session (the default): no shared cookie.
    _ = try await client.signInWithWebUI(presentationAnchor: window)

    // Straight to a provider.
    _ = try await client.signInWithWebUI(for: .google, presentationAnchor: window)

    // The plugin's behaviour: share the browser's cookies.
    _ = try await client.signInWithWebUI(
        presentationAnchor: window,
        options: .init(prefersEphemeralSession: false)
    )
}
```

**`prefersEphemeralSession` is `true` by default**, the opposite of the plugin's `preferPrivateSession`. With a
shared cookie, signing a second session in would silently return the first session's user. It is best effort:
Safari honours it; another default browser might not.

An app client with a secret works too: an `AuthClientConfiguration.UserPool` built in code with an `appClientSecret`
and `oauth` sends the secret with the hosted UI's token exchange (`Authorization: Basic`), as the plugin does.
`amplify_outputs` carries no secret.

### WebUIOptions

| Option | Default | Plugin equivalent |
|---|---|---|
| `whenBrowserBusy` | `.fail` | None: the plugin queues silently |
| `prefersEphemeralSession` | `true` | `preferPrivateSession` (default `false`) |
| `scopes` | The configuration's scopes | `scopes` |
| `provider` | `nil` | The `for:` overload's provider |
| `idpIdentifier` | `nil` (wins over `provider`) | `idpIdentifier` |
| `nonce` | `nil` (the client mints one) | `nonce` |
| `language` | `nil` | `language` |
| `loginHint` | `nil` | `loginHint` |
| `prompt` | `nil` | `prompt` |
| `resource` | `nil` | `resource` |
| `identityExpectation` | `.none` | None: the plugin checks nothing |

### One sheet at a time

One system sheet (a hosted-UI sign-in, a hosted-UI sign-out page, or a passkey sheet) is shown at a time across the
client's sessions: every session of every `AmplifyCognitoClient` in the process. By default a second request throws
`.browserBusy(holder:)`, naming the session that holds it. A hosted-UI sign-in can queue with `.wait(timeout:)`
instead, for at most one hour; a passkey sheet or the sign-out page fails at once while another session holds the
sheet.

The Auth plugin's hosted UI and passkey sheets don't take part: one can be up beside a client sheet, and
`systemSheetHolder` doesn't report it.

### Adding another account

A browser can finish a sign-in from a cookie without the user typing anything, and return that account.
`identityExpectation` turns a wrong account into an error:

| Expectation | The returned user must be |
|---|---|
| `.none` | Anyone (the default) |
| `.matches("<sub-or-username>")` | This user ID (`sub`) or username, compared exactly. An alias never matches |
| `.distinctFromOtherSessions` | Not signed in to another saved session of this configuration |

`.distinctFromOtherSessions` reads the other sessions before the browser is shown, and throws `storageUnavailable` if
one can't be read. It reads them again once the browser returns, since another session may have signed the same user
in meanwhile, and then throws `unexpectedIdentity` naming that session. If that second read fails, the client logs a
warning under `AmplifyCognitoClient.HostedUI` and completes the sign-in on the first check.

```swift
@MainActor
func addAccount(client: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async throws {
    do {
        _ = try await client.signInWithWebUI(
            presentationAnchor: window,
            options: .init(
                whenBrowserBusy: .wait(timeout: 30),
                prompt: [.login],
                identityExpectation: .distinctFromOtherSessions
            )
        )
    } catch AuthClientError.browserBusy(let holder, _, _, _) {
        print("Finish signing in to \(holder) first")
    } catch AuthClientError.unexpectedIdentity(_, _, let description, _, _) {
        print(description)
    } catch AuthClientError.userCancelled {
        // The user closed the browser.
    }
}
```

Whatever the expectation, the client checks that the returned ID token belongs to this flow and this app
(`token_use`, `aud`, `iss` and the nonce). A failed check signs nobody in and stores nothing.

`unexpectedIdentity`'s strings name no user (unless your session IDs do: the description can name the session that
holds the returned user), but its fields do. Log `errorDescription`, not the error itself,
where user identifiers must not appear.

### Cancelling and recovering

```swift
await client.cancelWebUISignIn()                        // this session's sign-in, sign-out page or passkey sheet
let holder = await AmplifyCognitoClient.systemSheetHolder // who holds the sheet, or nil
let freed = await AmplifyCognitoClient.resetSystemSheet() // free the sheet, whoever holds it
```

A hosted-UI sign-in cancelled with `cancelWebUISignIn()` throws `.userCancelled` once its browser has closed, so
`systemSheetHolder` is `nil` by then and another sign-in can start at once. If the browser hasn't closed within a
second (its code exchange was already in flight, say), the call throws anyway, and the sheet stays held until it
closes.

`resetSystemSheet()` is a recovery tool for a sheet that stopped responding. A sign-in or passkey call holding it
throws `.userCancelled`; a sign-out page is closed, and its sign-out reports what it did (`.failed(.userCancelled)`
if it had not finished).

## Tokens, sessions and credentials

### fetchAuthSession

`fetchAuthSession` returns the session's credentials, refreshed if needed. Each field has its own result.

```swift
let session = try await client.fetchAuthSession()

let tokens = try session.userPoolTokensResult.get()
let credentials = try session.awsCredentialsResult.get()
let identityId = try session.identityIdResult.get()
let sub = try session.userSubResult.get()
print(tokens, credentials, identityId, sub) // tokens and credentials print redacted

_ = try await client.fetchAuthSession(options: .init(forceRefresh: true))

let user = try await client.getCurrentUser()
print(user.username, user.userId)

let accessToken = try await client.userPoolTokenProvider.accessToken()
```

- A field fails when the session can't provide it (user pool tokens of a guest, AWS credentials without an identity
  pool) or its refresh failed. A dead refresh token is `sessionExpired` in the fields.
- `fetchAuthSession` itself throws only for failures that aren't per field: `storageUnavailable`, an unreadable
  saved record (`unknown`), or cancellation.
- A signed-out session whose identity pool allows guests becomes `.guest` here, and only here.
- Concurrent refreshes of the same kind share one call. A forced refresh (`forceRefresh: true`) joins only other
  forced refreshes, and runs after a normal refresh already in flight, so it always calls Cognito. With an identity
  pool configured, that includes a session signed out in this process after an app extension or the Auth plugin
  saved a login in its record: it adopts that login, then refreshes it, where an unforced fetch hands out the saved
  tokens as they are. It does so even when an unforced fetch running alongside adopted the login first, and never
  joins that fetch's guest acquisition. Without an identity pool, a signed-out session's fetch doesn't read the
  record, and stays signed out in this process. A forced refresh that Cognito refuses as a reused refresh token
  never answers with the saved tokens it sent: its fields fail with the same retryable `unknown` an unforced refresh
  gets there (unless another writer saved a refresh meanwhile, with a new refresh token, which it adopts). An
  unforced fetch still returns valid saved tokens.
- There is no `isSignedIn` field. Use `currentSessionState()`.
- Tokens and AWS credentials print redacted.

`getCurrentUser()` reads the saved tokens without the network. It throws `.notSignedIn` for a signed-out, guest or
federated session, and `.invalidState` while a sign-in waits on a challenge.

### Credentials for other AmplifyClients

`credentialsProvider` vends this session's AWS credentials to any client that takes an `AWSCredentialsProvider`.
Link that client's product too: `AmplifyKinesisClient` for the example below.

```swift
import AmplifyKinesisClient

let kinesis = try AmplifyKinesisClient(
    region: "us-east-1",
    credentialsProvider: work.credentialsProvider
)
```

In Swift 6, calling `AmplifyKinesisClient`'s `record(…)` from a `@MainActor` type (a SwiftUI view model, say) or an
actor that holds the Kinesis client fails to compile with "sending 'kinesis' risks causing data races": the Kinesis
client isn't `Sendable`. Use `@preconcurrency import AmplifyKinesisClient`, or create and use the Kinesis client in
one nonisolated function.

The provider:

- is bound to its session for life, and keeps the session alive;
- never falls back: a signed-out session throws `notSignedIn` and never quietly returns guest credentials. Call
  `fetchAuthSession()` first if you want a signed-out session to become a guest;
- vends nothing while a sign-in on the session waits on a challenge, whatever the session held, a guest's
  credentials included: it throws `notSignedIn` (`.discard`), or `notConfigured` when the configuration has no
  identity pool, so a consumer that follows it drops what it has
  buffered so far. `.discard` marks the change of principal only when the sign-in stops on a challenge. A sign-in
  that completes at once (one that needs no challenge, or a hosted-UI sign-in) moves the session to the new login
  with no `notSignedIn` in between, and so hands the user's credentials to a consumer still holding a guest's buffer,
  which is then sent as the user. Flush a guest's buffered work before any sign-in: without a challenge it is sent as
  the user, and with one the provider answers `.discard`. `fetchAuthSession()` still reports what the session holds.
  The Auth plugin keeps vending a guest's credentials here;
- holds no credentials of its own: each call resolves through the live session, refreshing if needed.

`userPoolTokenProvider` does the same for the user pool access token.

Failures are `CredentialsError` from AmplifyFoundation. Read its `disposition` to decide what to do with buffered
work (needs the SPI import):

```swift
do {
    _ = try await client.credentialsProvider.resolve()
} catch let error as CredentialsError {
    switch error.disposition {
    case .discard:
        print("Signed out: drop buffered work")
    case .retryAfterReauthentication:
        print("Keep buffered work; sign in again")
    case .retryWithBackoff:
        print("Retry later")
    case .failLoudly:
        print("Misconfigured:", error.errorDescription)
    @unknown default:
        // A disposition added in a later release: never drop buffered work for it
        print("Retry later")
    }
} catch {
    // CancellationError
}
```

| `CredentialsError` | `disposition` | When |
|---|---|---|
| `.notSignedIn` | `.discard` | Signed out, or a sign-in on the session waiting on a challenge, whatever the session held (a guest, or an expired session, included). For the token provider also a guest |
| `.sessionExpired` | `.retryAfterReauthentication` | The refresh token (or a federated provider token) is dead |
| `.storageUnavailable(reason)` | `.retryWithBackoff`, or `.failLoudly` for `.denied` | The keychain could not be read or written |
| `.notConfigured` | `.failLoudly` | No identity pool, or a user-pool-only sign-in, or a session carried to a new identity pool that refuses its user (`notAuthorized`, `resourceNotFound`, `invalidParameter` or `configuration`; the refusal is the underlying error) (credentials provider); no user pool, or a federated session (token provider) |
| `.unknown` | `.retryWithBackoff` | Anything else, such as a network failure during refresh |

`CancellationError` passes through unwrapped.

### Amplify category plugins do not follow these sessions

Storage, API, Analytics and the other category plugins never ask this client for credentials. They use the
Auth plugin's session in `Amplify.Auth`, whichever session you use here, `.default` included. **Nothing warns
you.** With several sessions signed in, a category call does not fail: it runs as the Auth plugin's user, or its
guest, or fails only if the Auth plugin has no session. A Storage path built from the identity ID
(`StoragePath.fromIdentityID`, `.private`, `.protected`) resolves to the Auth plugin session's identity, and the call
succeeds there. Analytics sends events with the Auth plugin session's AWS credentials.

To make AWS calls as a particular session, pass its `credentialsProvider` to a client in the `AmplifyClients`
family.

## Federation to the identity pool

Exchange another provider's token for this session's identity pool credentials. Needs an identity pool.

```swift
let result = try await client.federateToIdentityPool(
    withProviderToken: "<provider-token>",
    for: .apple
)
print(result.identityId, result.credentials.expiration)

_ = try await client.federateToIdentityPool(
    withProviderToken: "<provider-token>",
    for: .oidc("<provider-name>"),
    options: .init(developerProvidedIdentityId: "<identity-id>")
)

try await client.clearFederationToIdentityPool()
```

- The session reports `.federated(identityId:)`. It has AWS credentials and no user pool user, so user operations
  throw `.notSignedIn` and the token provider throws `notConfigured`.
- The credentials refresh with the saved provider token. When the identity pool stops accepting it, the session
  sends `.sessionExpired`.
- `signIn` is refused on a federated session. Clear the federation or sign out first. Federating is refused on a
  session signed in to the user pool or waiting on a challenge.
- Federating sends no event; watch the state stream. Clearing sends `.signedOut` and keeps the row, as sign-out
  does.

Providers: `.amazon`, `.apple`, `.facebook`, `.google`, `.twitter`, `.oidc(name)`, `.saml(name)`, `.custom(name)`.
An empty token, or an empty name for `.oidc`, `.saml` or `.custom`, throws `.validation` before anything is sent.

## User attributes

These act on the session's signed-in user, with its access token (refreshed first if needed).

```swift
let attributes = try await client.fetchUserAttributes()
for attribute in attributes {
    print(attribute.key, attribute.value)
}

let result = try await client.update(
    userAttribute: AuthClientUserAttribute(.email, value: "new@example.com")
)
if case .confirmAttributeWithCode(let details, _) = result.nextStep {
    print("Code sent to", details.destination)
    try await client.confirm(userAttribute: .email, confirmationCode: "123456")
}

let results = try await client.update(userAttributes: [
    AuthClientUserAttribute(.givenName, value: "Sam"),
    AuthClientUserAttribute(.custom("plan"), value: "pro")
])
print(results[.givenName]?.isUpdated ?? false)

_ = try await client.sendVerificationCode(forUserAttributeKey: .email)
```

`.custom("plan")` is the Cognito attribute `custom:plan`. As in the plugin, arguments aren't validated locally:
Cognito answers an empty one.

## Passwords

A password reset acts on a username, so it works whether the session is signed in or not, and changes nothing in
the session.

```swift
let reset = try await client.resetPassword(for: "user@example.com")
if case .confirmResetPasswordWithCode(let details, _) = reset.nextStep {
    print("Code sent to", details.destination)
}
try await client.confirmResetPassword(
    for: "user@example.com",
    with: "<new-password>",
    confirmationCode: "123456"
)

// The signed-in user changes their password.
try await client.update(oldPassword: "<old-password>", to: "<new-password>")
```

A wrong old password is `.notAuthorized`.

## Devices

```swift
let devices = try await client.fetchDevices()
for device in devices {
    print(device.name, device.lastAuthenticatedDate as Any)
}
try await client.rememberDevice()
try await client.forgetDevice() // this device
if let other = devices.first {
    try await client.forgetDevice(other)
}
```

Device records on this device are kept per user, at the plugin's keys, so two sessions with the same user share
them. `rememberDevice()` and `forgetDevice()` for this device throw `.unknown` ("Unable to get device metadata")
when this device has no device record for the user, as the plugin does, which is always the case on a user pool
that doesn't track devices: no request is sent. On such a pool only the calls that reach Cognito, `fetchDevices()`
and `forgetDevice(_:)` of another device, throw `.configuration` ("Device tracking not currently enabled for this
pool.").

`forgetDevice()` keeps this device's record, as the plugin does. The next sign-in, in any flow, sends its device key,
finds that Cognito no longer knows it, drops the record and starts again without it.

## MFA preferences and TOTP

```swift
let preference = try await client.fetchMFAPreference()
print(preference.enabled ?? [], preference.preferred as Any)

let setup = try await client.setUpTOTP()
let uri = try setup.getSetupURI(appName: "ExampleApp", accountName: "user@example.com")
print(uri)
try await client.verifyTOTPSetup(code: "123456", options: .init(friendlyDeviceName: "My phone"))

try await client.updateMFAPreference(sms: .enabled, totp: .preferred)
try await client.updateMFAPreference(email: .disabled)
```

| `AuthClientMFAPreference` | Effect |
|---|---|
| `nil` (argument left out) | Unchanged |
| `.disabled` | Off |
| `.enabled` | On, keeping whether it is preferred |
| `.preferred` | On and preferred |
| `.notPreferred` | On, not preferred |

A wrong TOTP code is `.service(.softwareTokenMFANotEnabled, …)`; verify again with a right one. Preferring more
than one type is `.service(.invalidParameter, …)`. `AuthClientTOTPSetupDetails` prints its secret redacted.

## Passkeys (WebAuthn credentials)

Register a passkey for the signed-in user. The window is required.

```swift
@MainActor
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
func registerPasskey(client: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async throws {
    try await client.associateWebAuthnCredential(presentationAnchor: window)
}
```

List and delete them. These show nothing and work on every platform.

```swift
var passkeys: [AuthClientWebAuthnCredential] = []
var nextToken: String?
repeat {
    let page = try await client.listWebAuthnCredentials(
        options: .init(pageSize: 10, nextToken: nextToken)
    )
    passkeys += page.credentials
    nextToken = page.nextToken
} while nextToken != nil

if let passkey = passkeys.first {
    print(passkey.friendlyName ?? "Passkey", passkey.createdAt)
    try await client.deleteWebAuthnCredential(credentialId: passkey.credentialId)
}
```

- `pageSize` is 1 to 20, default 20. Outside that range the call throws `.validation(field: "pageSize")` before
  sending anything.
- Deleting removes the credential from the user pool. The passkey stays in the device's password manager until
  the user removes it there.
- `associateWebAuthnCredential` throws `.webAuthnCeremonyFailed(.credentialAlreadyExists)` if the device already
  holds a passkey for the user, and `.service(.webAuthnNotEnabled?, …)` if the pool has no WebAuthn.
- It uses one access token for the whole registration. If that token expires while the sheet is up, the call
  fails with `.notAuthorized`; retrying refreshes first and works.

## Sign-out

`signOut` has the Auth plugin's shape. It never throws: it returns `.complete`, `.partial(...)` or
`.failed(error)`, and `signedOutLocally` is `false` only for `.failed`.

```swift
let result = await client.signOut()
switch result {
case .complete:
    break
case .partial(let revokeTokenError, let globalSignOutError, let hostedUIError, let storageError):
    if let revokeTokenError {
        print("Refresh token not revoked:", revokeTokenError.errorDescription)
    }
    if let globalSignOutError {
        print("Other devices still signed in:", globalSignOutError.errorDescription)
    }
    if let hostedUIError {
        print("Browser still signed in:", hostedUIError.errorDescription)
    }
    if let storageError {
        print("Signed out, but the saved row was kept:", storageError.errorDescription)
    }
case .failed(let error):
    print("Still signed in:", error.errorDescription)
@unknown default:
    break
}

await client.signOut(options: .init(globalSignOut: true))
await client.signOut(options: .init(purgeStoredSession: true))
```

| Result | Meaning |
|---|---|
| `.complete` | Tokens revoked and cleared from this device, or there were none |
| `.partial(revokeTokenError:globalSignOutError:hostedUIError:storageError:)` | Signed out on this device, but part of the work failed. `revokeTokenError`: the refresh token stays valid until it expires, unless a global sign-out succeeded (`globalSignOutError` is `nil`), which already invalidated it. After a failed global sign-out the token isn't revoked and this holds a placeholder `.service` error with empty texts, as in the plugin. `globalSignOutError`: other devices stay signed in. Neither is retried, and signing out again doesn't retry it: the session is signed out on this device, so a second sign-out is `.complete` and sends nothing. `hostedUIError`: the browser keeps its hosted-UI cookie; only for a sign-out without a window (`signOut(options:)` or `signOutStoredSession`, as `.validation`), or a closed page on an already expired session. `storageError`: with `purgeStoredSession`, the row couldn't be removed; purge it again |
| `.failed(AuthClientError)` | Not signed out: the session is still signed in on this device. See below |

`.failed` carries:
- `storageUnavailable` when storage couldn't be read or written, or the saved record kept changing (`.interrupted`);
- `invalidState` when another sign-in replaced the session during the sign-out; that user stays signed in;
- `userCancelled` when the user closed the hosted UI's sign-out page;
- for `signOut(presentationAnchor:options:)`, whenever the hosted UI's sign-out page could not be shown or
  completed: `configuration` (no hosted UI, or no usable sign-out redirect URI, in the configuration),
  `browserBusy` (another sheet holds the browser), `validation` (the window has closed), or the browser's own
  failure. Nothing is revoked;
- `unknown`, with a `CancellationError` as its underlying error, when the task was cancelled before anything was
  revoked. Once a revoke has completed, cancellation never stops the local clear.

The sign-out revokes first, then clears this device, in the plugin's order. Termination is not cancellation: an app
terminated after the revoke and before the local clear (the user taps Sign out and swipes the app away) relaunches
signed in, holding the revoked refresh token. Its cached tokens and AWS credentials are still handed out until they
need a refresh, and that refresh reports `sessionExpired`, as the plugin does. Sign out again to clear the session.

`.partial` carries errors only, never tokens.

| Option | Default | Effect |
|---|---|---|
| `globalSignOut` | `false` | Revokes all of the user's refresh tokens. Other sessions with the same user get `sessionExpired` at their next refresh |
| `purgeStoredSession` | `false` | Also removes the saved row, so `storedSessions` no longer lists it. Not recoverable |

Any pending sign-in on the session is cancelled. Other sessions are untouched. A federated session signs out like
any other, with `.complete`.

Signing `.default` out or purging it (so also `deleteUser` and `clearFederationToIdentityPool` on `.default`) also
clears the AWSMobileClient (Amplify v1) logins, as the Auth plugin's sign-out does, so a plugin build's migration
can't bring an old login back over the signed-out one. Like the plugin's, it runs even when there was nothing to
sign out. It is best effort: each service that fails to clear logs one warning under
`AmplifyCognitoClient.SessionRecordStore`, and it never fails the sign-out. The services cleared follow the client's
pools: the user pool's with a user pool, every identity pool's, and AWSMobileClient's own. The identity pools'
services (`<bundle>.AWSCognitoCredentialsProvider.<identity pool ID>`) are cleared for every identity pool the app's
keychain holds one for, whatever the client is configured with: the client lists the app's keychain services to find
them, and the plugin's sign-out clears only the configured one's. Left behind, such a login would come back under a
plugin build as a guest holding the old user's identity and AWS credentials. If the listing fails, a warning says so
and only the configured identity pool's is cleared. The other two are cleared whole, as the plugin's sign-out clears
them: the user pool service (`<bundle>.AWSCognitoIdentityUserPool`) holds the logins of every app client, and the
AWSMobileClient service everything AWSMobileClient saved. The user pool service is cleared only when the client's
configuration has a user pool: an identity-pool-only configuration leaves it, and any user pool login in it, which a
plugin build then migrates without AWS credentials (see
[The default session uses the plugin's saved login](#the-default-session-uses-the-plugins-saved-login)). The
AWSMobileClient service is cleared on every `.default` sign-out or purge, a static one under another configuration
than the app's included. Named sessions never touch those logins.

### Hosted-UI sign-out

After a hosted-UI sign-in with `prefersEphemeralSession: false`, the browser holds a cookie. Clear it by signing
out with a window:

```swift
@MainActor
func hostedUISignOut(client: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async -> Bool {
    await client.signOut(presentationAnchor: window).signedOutLocally
}
```

- A private (default) hosted-UI sign-in left no cookie, so nothing is shown.
- `signOut(options:)` and `signOutStoredSession` have no window, so they can't clear the cookie, and report it in
  `.partial` as `hostedUIError` (`.validation`).
- If the user closes the sign-out page, the result is `.failed(.userCancelled)` and the session stays signed in,
  as with the plugin, unless the session had already expired. Then it signs out anyway and returns `.partial` with
  `hostedUIError` `.userCancelled`. The same goes when `cancelWebUISignIn()` closes this session's sign-out page, or
  `resetSystemSheet()` closes it before it finished.
- If the page can't be shown or completed, the result is `.failed` and the session stays signed in, with nothing
  revoked, as with the plugin: `.configuration` when the configuration has no hosted UI or no usable sign-out
  redirect URI, `.browserBusy` when another sheet holds the browser, `.validation` when the window has closed, or
  the browser's own failure. Fix the cause and sign out again, or call `signOut(options:)` to sign out on this
  device only.

## Delete the user

```swift
try await client.deleteUser()
```

Deletes the signed-in user from the user pool, removes this session's row, and sends `.userDeleted`. Other sessions
with the same user find out at their next refresh. It never shows the hosted-UI sign-out, so after a shared-cookie
hosted-UI sign-in the browser keeps its cookie. Once Cognito is asked, the deletion runs to its end even if the task
is cancelled. If the user is deleted but the row can't be removed, it throws `.storageUnavailable` after the
deletion; purge or sign out to remove the row. The deleted user's device records stay in the keychain, as with the
plugin. They are harmless: if the same username signs in on this device again, a device key Cognito no longer knows
is dropped and the sign-in starts again without it.

## Errors

Every operation throws `AuthClientError`, which conforms to `AmplifyError`: each case carries an
`errorDescription`, a `recoverySuggestion` and an optional `underlyingError`.

| Case | Meaning | What to do |
|---|---|---|
| `configuration` | The configuration is missing, unreadable, incomplete or Gen1, or lacks a pool the operation needs | Fix the configuration |
| `storageUnavailable(reason)` | The keychain could not be read or written | Don't show sign-in. Retry (`.locked`, `.interrupted`) or fix entitlements (`.denied`) |
| `sessionExpired` | The refresh token (or federated provider token) expired or was revoked | Sign this session in again. Other sessions are unaffected |
| `notSignedIn` | No user pool user: signed out, guest, federated, or waiting on a challenge | Sign in |
| `invalidSessionID` | Empty, too long, or a character outside `A-Z a-z 0-9 _ -` | Use a valid ID |
| `challengeExpired` | Cognito no longer accepts the challenge | Call `signIn` again |
| `browserBusy(holder:)` | The one system sheet is held, or a `.wait(timeout:)` expired | Finish or cancel the holder's sheet |
| `sessionConfigurationMismatch(SessionID)` | The session is live under a different configuration | Release its handles and providers, or use the same configuration |
| `validation(field:)` | An argument was invalid; `field` names it | Fix the argument |
| `service(AuthClientServiceErrorCode?)` | Cognito rejected the request, with the code if the client recognises it; or a network problem stopped the request, which may or may not have reached Cognito (offline, a failed DNS or host lookup, a refused or lost connection, a timeout, or a failed secure connection), or its answer couldn't be read, with no code | Depends on the code; with no code, retry later |
| `notAuthorized` | Wrong password, disabled user, revoked token | Ask the user again, or sign in |
| `invalidState` | Not valid in this state: already signed in, federated, no sign-in in progress, or cancelled by a sign-out | Check `currentSessionState()` |
| `userCancelled` | The user closed a system sheet, or it was cancelled | Nothing changed; let the user retry |
| `webAuthnCeremonyFailed(failure)` | The local passkey ceremony failed before Cognito was asked | `failure` is `.credentialAlreadyExists`, `.failed` or `.invalidCredential` |
| `unexpectedIdentity(expected:returned:)` | The hosted UI returned another user than expected; nobody was signed in | Retry with `prompt: [.login]` |
| `unknown` | Anything else, including a saved record this version can't read | Read the description |

Match cases directly. `service` carries its code in the case, so no downcast is needed:

```swift
do {
    _ = try await client.signIn(username: "user@example.com", password: "<password>")
} catch AuthClientError.notAuthorized(let description, _, _) {
    print("Wrong username or password:", description)
} catch AuthClientError.service(.requestLimitExceeded?, _, _, _) {
    print("Too many requests; try again later")
} catch AuthClientError.invalidState {
    print("This session is already signed in")
} catch AuthClientError.storageUnavailable(let reason, _, _, _) {
    print("Keychain unavailable:", reason)
} catch let error as AuthClientError {
    print(error.errorDescription)
    print(error.recoverySuggestion)
    print(error.underlyingError as Any)
} catch {
    // CancellationError
}
```

`AuthClientServiceErrorCode` has the same cases as the plugin's `AWSCognitoAuthError` (for example
`.codeMismatch`, `.codeExpired`, `.usernameExists`, `.invalidPassword`, `.limitExceeded`, `.userNotFound`,
`.webAuthnNotEnabled`). A cancellation is never `.service(.userCancelled?, …)`: it is always `.userCancelled`.

A network failure is `.service` with no code in every call: offline, a failed DNS or host lookup, a refused or lost
connection, a timeout, or a failed secure connection gives the description "A network problem stopped the request. It
may not have reached the service." and the suggestion "A network or service problem occurred. Check the connection
and retry the operation.", with the network error underneath. The description doesn't say the request never arrived:
a timed-out or lost connection may follow a request Cognito acted on, whose answer was lost. A transport failure that
isn't a network failure is `.service` with no code too, never `.unknown`: a response that couldn't be read (one that
isn't JSON, such as an HTML error page, or a malformed one) is "The service returned a response that could not be
read." with a suggestion to retry, and any other URL loading failure (an App Transport Security refusal, say) is "The
service request failed." with the network-or-service suggestion. The client doesn't retry any of them itself.

A sign-out's `revokeTokenError` that failed on the network is `.service` with no code too, described as "The refresh
token may not have been revoked: a network problem stopped the request, which may not have reached the service.
Unless it did, or a global sign-out succeeded, the refresh token stays valid until it expires.", with the suggestion
"The session was signed out on this device, and the revoke will not be retried. To end the refresh token on the
server, sign in again and sign out with globalSignOut: true." A `globalSignOutError` that failed on the network has
the network description, with the suggestion "The session was signed out on this device, and the global sign-out will
not be retried: unless the request reached the service, the user's other sessions stay signed in until their tokens
expire. To sign them out, sign in again and sign out with globalSignOut: true." Signing out again doesn't retry
either: the session is already signed out on this device, so the second sign-out is `.complete` and sends nothing.

Recovery suggestions name the client's calls (for example "Call signIn …"), not the plugin's.

## Moving from the Auth plugin

### The default session uses the plugin's saved login

`SessionID.default` reads and writes the Auth plugin's own saved login: the same keychain item, in the plugin's
format. An app moving from the plugin keeps its signed-in user, with nothing to migrate, and an app rolled back to
the plugin finds the newest login, a signed-out one included. Named sessions keep their own records, which the
plugin never reads.

Before you switch:

- **Use the plugin's access group.** If the plugin set an access group (`secureStoragePreferences.accessGroup`),
  pass the same `accessGroup` to the client and to `storedSessions`; otherwise `.default` reads the unshared
  keychain and starts signed out. The other stored-session calls (`signOutStoredSession`, `purgeStoredSession`)
  take it too.
- **Ship the plugin's migrations first.** The client does not migrate AWSMobileClient (Amplify v1) logins or move
  items between access groups: ship a plugin release first if your users may still need those migrations. It only
  clears the AWSMobileClient logins when `.default` signs out or is purged, as the plugin's sign-out does.
- **A migrated AWSMobileClient login without AWS credentials** fails the plugin's AWS credentials for a while. When
  the Auth plugin migrates an AWSMobileClient login that has user pool tokens but no saved AWS credentials (its user
  never fetched any, or an identity-pool-only client configuration's `.default` sign-out cleared them and kept the
  user pool login), every unforced `fetchAuthSession` of the plugin fails the AWS credentials with
  `invalidAccountTypeException` ("…Identity Pool is not configured"), across relaunches, until a refresh. Call the
  plugin's `fetchAuthSession` with `forceRefresh: true` once to fetch them. This client, reading the same login,
  fetches the identity on first use.
- **Migrating back to no access group keeps the items in the group.** The plugin's migration back
  (`AccessGroup.none(migrateKeychainItemsOfUserSession: true)`) changes only the items' keychain service, so they
  stay in the shared access group: the app, and `.default` without an access group, still read them, and so can an
  extension in the group. Keep the keychain-sharing entitlement: an update that drops it can no longer read them, and
  the user starts signed out.

```swift
// The plugin was configured with secureStoragePreferences.accessGroup = "<team-id>.com.example.shared".
let accessGroup = "<team-id>.com.example.shared"
let client = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(sessionId: .default, accessGroup: accessGroup)
)
let rows = try await AmplifyCognitoClient.storedSessions(
    configuration: configuration,
    accessGroup: accessGroup
)
```

One rollback caveat: a purge, or the plugin's own sign-out, after a configuration change that copied the login, then
a rollback to the build with the earlier configuration: that build finds the earlier copy and signs the user back
in. A sign-out through the client doesn't do this: it keeps the user signed out under the same configuration, and
across rollbacks, and clears the AWSMobileClient logins any plugin release would migrate over it (best effort; see
[Sign-out](#sign-out)). The exception, as with the plugin, is a later configuration change onto an earlier
configuration's copy. An AWSMobileClient login that failed to clear (a warning says so) can still undo it: any
plugin release migrates it over the signed-out login. See [Rolling back and forward](#rolling-back-and-forward).

### Labels and the signed-out row after a plugin action

For example: alice signs in through the client, and the app labels the session "Personal". Later the plugin
deletes alice (`deleteUser`). The plugin deletes its own record, but it doesn't know the client's note beside it,
so a picker that lists signed-out rows (`storedSessions(…includingSignedOut: true)`) still shows a row naming alice,
labelled "Personal". The row lasts until the client writes the session again, for example a sign-in through the
client, a client refresh of another user the plugin signed in, a guest fetch or a purge. A sign-in through the
plugin doesn't replace it.

The rule behind it: what the plugin's format has no room for, the label and the user a signed-out row names, is
kept beside the plugin's record and bound to the last user the client wrote the session for. The plugin never
updates it. A label is shown only while the plugin's record holds that user, and is hidden while it holds another
user. Once the plugin's record is signed out or gone, the row names the client's last user again, whoever the
plugin signed in meanwhile.

### Side by side is not supported

Don't run the plugin and the client over `.default` in one app. They share one saved login, but each keeps its
tokens in memory and reads the keychain only at times of its own (the plugin at configuration, and on
`fetchAuthSession` too when an access group is set). A sign-in or sign-out through one, or with refresh-token
rotation a refresh, can leave the other holding tokens that no longer work until the app relaunches. Use one or the
other for the app's session.

Until the plugin uses the client for the default session, when `.default` re-reads the saved login and finds a
different user or guest from the one it holds in memory, for example because the plugin signed someone else in, the
client logs one warning under the `AmplifyCognitoClient.DefaultSession` log category:

> The default session's saved login now holds a different user or a guest than this client held. The Auth plugin
> may be running beside this client over the default session, which is not supported.

It names no one and changes nothing else. Logged once while the session is in memory. All handles share it; after
every handle and provider is released, a new handle can log it again. It warns for another user, a guest over a
user, a user over a guest, and another guest or federated identity ID. It is silent when the saved login is signed
out or absent, for the same user, and for the same guest or federated identity with new credentials. Named sessions
never log it. The warning is temporary: it goes when the plugin uses the client internally.

### Rolling back and forward

| Case | What happens |
|---|---|
| Back to a plugin-only release | The plugin reads `.default`'s latest login, signed in or signed out. Named sessions are not seen, and come back on roll-forward, unless the released plugin wiped its keychain service: on an access-group transition, or at the first configuration of a release before 2.53.3 (the next row) |
| Back to a plugin release before 2.53.3, on an install where no such release has run (a fresh install of the client build, say) | **That release wipes the plugin's keychain service the first time it configures** (2.51.3 to 2.53.2 only without an access group): `.default`'s login, its label and interrupted sign-in, the named sessions and the device records. The plugin starts signed out, and nothing comes back on roll-forward. Plugin-only apps rolled back across 2.53.3 have the same hazard. Roll back to 2.53.3 or later |
| A purge, or the plugin's own sign-out, after a configuration change that copied the login, then a rollback to the build with the earlier configuration | **That build finds the earlier copy and signs the user back in.** The copy keeps its source, as the plugin's does, and a purge or the plugin's sign-out deletes only the current configuration's login. A sign-out through the client doesn't do this: it saves a signed-out login, which that build reads as signed out |
| A sign-out through the client, then a later configuration change that the rule doesn't copy across, onto a configuration whose key still holds an earlier copy of the user | **That copy is restored signed in**, as with the plugin: the change deletes the signed-out login and lands on the old copy. For example: alice signs in under A; B adds an identity pool and copies her, keeping A's copy; she signs out under B; D (the same user pool with a new app client, and A's identity pool) deletes B's signed-out login, and its key is A's, which still holds her |
| Back to a plugin release before 2.51.0, with refresh-token rotation on | That plugin can't refresh on the app client at all, whatever the client did |
| Forward from the plugin to the client, with refresh-token rotation on, after the plugin rotated the token | **The user stays signed in**: `.default` reads the plugin's record in place, so the client refreshes with the newest token the plugin saved |
| Back to a released plugin while AWSMobileClient (Amplify v1) logins are still on the device | **The plugin migrates the old login over whatever `.default` holds**: released plugins write it with no check, so a user signed in through the client is replaced by the old AWSMobileClient user. A sign-out or purge of `.default` through the client clears those logins, so after one there is nothing to migrate. Ship a plugin release that has migrated them before you move to the client. A migrated login with no AWS credentials saved fails the plugin's unforced AWS credentials until a forced refresh |
| To a plugin release that ships with this client, while AWSMobileClient (Amplify v1) logins are still on the device | **A user signed in through the client is kept**: the plugin clears the old logins without migrating them. **A guest the client saved is replaced**: an old user-pool or federated login migrates over it, as over a guest the plugin saved, and the guest identity is lost. An old guest doesn't replace it. After a sign-out or purge of `.default` through the client there is nothing to migrate. A migrated login with no AWS credentials saved fails the plugin's unforced AWS credentials until a forced refresh (`fetchAuthSession` with `forceRefresh: true`) |

## Changing the configuration

Saved sessions are scoped to the configuration's pools (user pool ID, identity pool ID, or both) and to the
keychain access group. A client with a different configuration sees a different set of saved sessions.

**For runtime switching between backends, use named sessions.** `.default` follows the Auth plugin's rule, which
deletes the old login on most changes; named sessions keep each configuration's login.

### The default session: the plugin's rule

`.default` uses the plugin's saved login, so it follows the plugin's configuration-change rule exactly. At its first
restore under a new configuration, it compares the configuration the plugin or the client last recorded with the
current one:

| Change | `.default` after the change, as with the plugin except where a row says otherwise |
|---|---|
| Identity pool only, then a user pool added (same identity pool) | The guest or federated identity, copied as it was; the old record is kept |
| An identity pool added, changed or removed, same user pool, app client and region | Signed in, copied as it was; the old record is kept. With an identity pool added, the client fetches the identity on first use, and that first fetch also refreshes the user pool tokens; the plugin instead fails its unforced fetches' AWS credentials (`invalidAccountTypeException`, "…Identity Pool is not configured") until a forced refresh. With the identity pool removed, the client reports AWS credentials as `notConfigured`, while the plugin still hands out the AWS credentials and identity copied with the login |
| Only the app client changed, same pools | Nothing is deleted or revoked: the record stays where it is. Its next refresh fails with `sessionExpired`, as the old app client's refresh token is refused, and the user signs in again |
| Anything else that changes the pools (another user pool, say) | **The old login is deleted**, and `.default` is signed out |

- **A changed identity pool keeps the old identity ID.** Under `.default`, a new identity pool keeps the old
  identity ID, as the plugin does. While the old pool exists, the app keeps getting the old pool's AWS credentials.
  Once Cognito refuses that ID (for example, the old pool is deleted), the client gets a new identity from the new
  pool. (Any other refusal is reported as an error at each refresh until the user signs out and in.) To switch at
  once, sign the user out and in. Named sessions switch at once: they keep only the user pool tokens and get a new
  identity.
- **A deleted login is revoked** when its user pool is the current one, once, in the background, with the previous
  configuration's app client ID, which the recorded configuration holds. This works when that app client has token
  revocation enabled. If the revoke fails, the warning "A login deleted by a configuration change could not be
  revoked; its refresh token stays valid until it expires." is logged under `AmplifyCognitoClient.DefaultSession`.
  A revoke that succeeds logs nothing, at any level, and nor do the rule's copy and delete, which log only on
  failure. A login of another user pool isn't revoked, and stays valid until it expires.
- **The client records the configuration for the plugin** when it restores `.default`, in the plugin's own
  `authConfiguration` item, so a plugin build started next compares with the client's configuration. A rollback to a plugin build after a
  configuration change never copies an older login over a newer one.
- A label goes with a copied login, and is deleted with a deleted one: no signed-out row is left under the old
  configuration for a login the user never signed out of. Two exceptions. When a plugin build applies a copying
  change first (a rollback to a plugin build that also changes the configuration), the plugin copies only the
  login, so under the new configuration the session has no label, and a signed-out row has no label or username.
  And a plugin release from before this client deletes the login but not the label, so after a rollback to one
  built with another configuration, and a roll-forward, the client can list a signed-out row for that login until
  it writes the session again.
- **`signOutStoredSession` and `purgeStoredSession` apply the rule only when it copies, and never record a
  configuration.** They may be called with a configuration other than the app's, so when the rule would delete they
  leave everything as it is: no delete and no revoke. When it copies, they sign out or delete the copy, but the
  recorded configuration stays the one the app last ran with: only a restore records one.
  - `signOutStoredSession` then also signs out the login it copied from, while that still holds the user (or
    federated identity) it just signed out, so the user stays signed out under both configurations: a restore under
    the app's configuration reads them signed out, and a later move to the new one copies the signed-out login. A
    login another writer has changed meanwhile is left alone, and so is a guest's: a restore under either
    configuration finds the same guest.
  - `purgeStoredSession` revokes nothing, so it leaves the login it copied from as it was: the app's login under its
    own configuration. The next restore under the new configuration copies it again, over the deleted copy. To end
    that login, sign it out instead. A named session differs: purged under a new configuration before its first
    restore there, its carry ends, so it comes up signed out under the new configuration, while the old
    configuration's login stays as it was (see [Named sessions](#named-sessions-each-configuration-keeps-its-login)).
- **An app and its extensions sharing an access group must use the same configuration for `.default`.** They share
  the plugin's saved login and its recorded configuration, so with two configurations each launch applies the rule
  against the other's. Where the rule deletes, each launch deletes the other's login, and on the same user pool
  revokes it, which also ends the refresh token the other process holds in memory. Give such an extension a named
  session instead.
- If the keychain can't be read (a locked device at launch), the restore fails with `storageUnavailable`, and nothing
  is copied, deleted or recorded; the next restore applies the rule. The plugin treats that case as "no previous
  configuration".
- `storedSessions` lists `.default` as the rule will leave it at the next restore.

### Named sessions: each configuration keeps its login

When the pools change, a named session is **carried forward** the first time it is restored. Carried forward means
the client copies the session's login from the record of the configuration the app last used for that session into
a record for the new configuration, and keeps the old record. Below, "carried" means the same.

The rule compares pool IDs only, not the app client: a named session is also carried when the app client changes
along with one of the changes below, where the plugin's rule would not carry. The carried session then gets
`sessionExpired` at its first refresh, as a change of app client alone gives, and its user signs in again.

| Change | The session after the change |
|---|---|
| Identity pool only, then a user pool added | The guest or federated identity, as it was |
| User pool only, then an identity pool added | Signed in; the identity is fetched on first use, and that first fetch also refreshes the user pool tokens |
| Identity pool changed, same user pool | Signed in with **user pool tokens only**; the new identity pool issues a new identity on first use. (The plugin, and `.default`, keep the old pool's identity ID) |
| Identity pool removed, same user pool | Signed in with user pool tokens only |
| Anything else (another user pool, another access group) | Nothing carried. **The old record is kept**, where the plugin and `.default` delete it on another user pool |

- Nothing is carried from a session whose last saved state is signed out.
- A purge under a new configuration, before the session's first restore there, ends the carry for that session: it
  comes up signed out under the new configuration, and the old configuration's login is left as it was.
- The old record is kept, so each configuration keeps its own session: switching back finds it as it was, unless
  it was signed out there. An app can switch configurations at runtime under one named session ID.
- Two configurations that share a user pool but differ in identity pool are one carried session: a sign-out in
  either ends it in both.
- Signing out or purging a carried session also deletes the record it was carried from, but only if that record
  hasn't been written since, provably holds the same user, and isn't a guest's (an extension may still use that
  identity). An extension that only reads the old record loses it at sign-out.
- Sign-out revokes a deleted copy's refresh token when it differs from the one it revoked and belongs to the same
  user pool. Otherwise, and on purge, the copy's refresh token isn't revoked and stays valid until it expires.

  For example: alice signs in to `.named("work")` under configuration A. The next release changes the identity
  pool (configuration B), so the session is carried to B, and A's record is kept. When alice signs out under B,
  the client also deletes A's record: nothing has written it since, and it holds alice. If A's refresh token differs
  from the one the sign-out revoked (B's was rotated since, say), it is revoked too. If an extension still on
  configuration A had refreshed A's record meanwhile, A's record would be kept, for the extension.
- A rollback carries by the same rules: back on the old configuration, the kept record is used (a guest keeps its
  identity), unless the session, if not a guest, was signed out or purged under the new one.
- If a carried session's identity fetch fails, it keeps its user pool tokens and retries, as the plugin does. A
  known refusal isn't retried for that user until the app restarts or the session is signed out or purged; other
  failures not within 30 seconds. Until then the identity fields report the failure.
- A session saved by an older build, which recorded no configuration for it, isn't carried if the configuration
  changes before this build first restores it.
- Remembered devices aren't carried. Remember the device again.
- While a client or provider for the session is live under the old configuration, building one under the new
  configuration throws `sessionConfigurationMismatch`. Release every handle and provider first.

## Escape hatches and logging

The session's Cognito SDK clients:

```swift
guard let userPool = client.getUserPoolClient() else { return }
let token = try await client.userPoolTokenProvider.accessToken()
let output = try await userPool.getUser(input: GetUserInput(accessToken: token))
print(output.username ?? "")
_ = client.getIdentityClient()
```

(`GetUserInput` needs `import AWSCognitoIdentityProvider`.) Both return `nil` without the matching pool. Operations
that need AWS (SigV4) credentials, such as the `Admin*` ones, throw by design unless you set an
`awsCredentialIdentityResolver` in `configureUserPoolClient`.

Customize the user pool SDK client when the session is built:

```swift
let client = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(configureUserPoolClient: { config in
        config.retryStrategyOptions = RetryStrategyOptions(
            backoffStrategy: config.retryStrategyOptions.backoffStrategy,
            maxRetriesBase: 5
        )
    })
)
```

(`RetryStrategyOptions` needs `import SmithyRetriesAPI`, and the closure's `config`, the SDK's
`CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig`, needs `import AWSCognitoIdentityProvider`
where member import visibility is on, as in new Xcode projects.)
The closure runs after the client sets the region, signing region and credential resolver, so it can override
them. Only the handle that builds the session applies it. It runs after the SDK has built its retry options and
HTTP client from the configuration, so some settings have no effect there:

- To change retries, set `retryStrategyOptions`, as the plugin does: setting `maxAttempts` or `awsRetryMode` has no
  effect.
- To change timeouts, replace `httpClientEngine`: setting only `httpClientConfiguration` has no effect.

The client logs through AmplifyFoundation's logging. Every line's category starts with `AmplifyCognitoClient`, so
a sink can tell the client's lines from the Auth plugin's:

- `AmplifyCognitoClient`: the Cognito flows themselves.
- `AmplifyCognitoClient.<step>`: one step of a flow, such as `AmplifyCognitoClient.InitiateAuthSRP`, and the
  value parsers `AmplifyCognitoClient.MFAType` and `AmplifyCognitoClient.AuthFactorType`.
- `AmplifyCognitoClient.SessionRecordStore`: saved sessions, their listing, carrying them forward to a new
  configuration, and the interrupted sign-in's record.
- `AmplifyCognitoClient.SessionSignOut`: sign-out.
- `AmplifyCognitoClient.HostedUI`: the hosted UI's sign-in, such as the warning that `.distinctFromOtherSessions`
  could not check the other sessions again (see [Adding another account](#adding-another-account)).
- `AmplifyCognitoClient.DefaultSession`: `.default`'s saved login, such as the warning that it holds a different
  user or guest (see [Side by side is not supported](#side-by-side-is-not-supported)), and the warning that a login
  deleted by a configuration change could not be revoked (see
  [Changing the configuration](#changing-the-configuration)). The first warning is temporary: it goes when the
  plugin uses the client internally.
- `AmplifyCognitoClient.KeychainItemStore` and `AmplifyCognitoClient.KeychainStore`: keychain access.
- `AmplifyCognitoClient.PlatformWebAuthnCredentials`: the passkey sheet.

No category includes a session ID: a session ID can be derived from a user identifier, such as a username or
`sub`. Most of the client's own lines are warnings and errors, and a step that succeeds usually logs nothing. The
Cognito flows' step-by-step lines are `verbose`, not `debug`, so a sink at `.debug` sees what one at `.info` sees.
Add a sink to see the lines:

```swift
import AmplifyFoundation

AmplifyLogging.addSink(AmplifyOSLogSink(logLevel: .warn))
```

The client redacts two things in every line, at every level, in each message; an error passed with a line reaches
the sink as it is. It replaces the query and fragment of each URL with `?<redacted>` (the hosted UI's authorize URL
holds `state`, the nonce, the PKCE challenge, `login_hint` and `userContextData`, and its redirect, a custom-scheme
one included, the authorization code), and the value of each user identifier the Cognito flows print with
`<redacted>`, such as `USERNAME` and `USER_ID_FOR_SRP` in a challenge's parameters, the username of a sign-in, a
passkey's `userHandle`, and the user's attributes. Debug and verbose lines can still hold Cognito's other challenge
parameters and responses, a challenge's `session` string among them, so keep a remote sink, such as
`AmplifyCloudWatchClient`, at `.info` or above. The Auth plugin's own lines are not redacted this way.

## Differences from the Auth plugin

The client keeps the plugin's semantics except where listed here.

| Area | Auth plugin | AmplifyCognitoClient |
|---|---|---|
| Configuration | Gen1 and Gen2 | Gen2 `amplify_outputs` only; Gen1 refused |
| Sessions | One, in `Amplify.Auth` | Many, one per `SessionID`, each with its own state and events |
| Saved login | One record | `.default` uses the plugin's own record; named sessions keep their own, which the plugin never reads |
| Session label and signed-out row | None | Kept beside the plugin's record for `.default`, bound to its user |
| Second sign-in | Refused while signed in | Refused only on the same session, and allowed there once the session reported `sessionExpired` in this process |
| Events | Hub | Per-session `AsyncStream`s |
| Storage failure | Reported as signed out | `.unavailable(reason)` / `storageUnavailable`, never signed out |
| Interrupted sign-in | Lost when the app closes | Saved, resumable for up to 15 minutes |
| Hosted UI private session | `preferPrivateSession` defaults to `false` | `prefersEphemeralSession` defaults to `true` |
| Hosted UI while another is up | Queues silently | `.browserBusy` by default; `.wait(timeout:)` to queue |
| Hosted UI returned user | No expectation | Optional `identityExpectation`; the returned ID token is always checked |
| Passkey registration window | Optional; falls back to a window of its own | Required |
| Passkey sign-in without a window | Window optional | The overloads without a window refuse a passkey with `.validation(field: "presentationAnchor")` |
| Passkey registration token | Fetched again after the sheet | One token for the whole registration |
| `listWebAuthnCredentials` page size | Sent as is; Cognito rejects bad values | Checked locally, 1 to 20 |
| Sign-out result | `AWSCognitoSignOutResult`; `.partial` carries the tokens | The same shape, never thrown; `.partial` carries errors only, never tokens |
| Sign-out of a federated session | `.failed`: call `clearFederationToIdentityPool` | Signed out, `.complete` |
| Sign-out that removes the saved row | Not available | `purgeStoredSession`; a removal that fails after the sign-out is `.partial` with `storageError` |
| Hosted-UI sign-out window | Optional; falls back to a window of its own | Required: `signOut(presentationAnchor:options:)`. Without one, the browser keeps its cookie and `.partial` reports `hostedUIError` |
| `isSignedIn` | On the session and results | Not provided; use `currentSessionState()` |
| Service error code | `underlyingError as? AWSCognitoAuthError` | `AuthClientError.service(code, …)` |
| MFA type `rawValue` | The Cognito name | `"sms"`, `"totp"`, `"email"`; use `challengeResponse` |
| Deprecated `validationData` on sign-in, `.custom` flow | Supported | Not mirrored: use `clientMetadata`, `.customWithSRP` |
| TOTP setup details | Printed in full | Secret redacted |
| Non-JSON service response | "Report a bug" suggestion | `.service` with no code and a retry suggestion |
| Configuration change | Carries some changes, deletes the old record otherwise | `.default`: the same, and a deleted login of the same user pool is revoked. Named sessions carry the same changes and keep the old record; a changed identity pool keeps user pool tokens only |
| Credential error types | Not applicable | `CredentialsError` and `StorageUnavailableReason` need `@_spi(AmplifyExperimental) import AmplifyFoundation` |
| Category plugins | Use its session | Don't see client sessions |
| Credentials during a pending sign-in challenge | Keeps vending a guest's credentials | `credentialsProvider` and `userPoolTokenProvider` throw `notSignedIn` (`.discard`), whatever the session held |

## Known limitations

- **Category plugins don't follow client sessions**, and nothing warns you. See
  [above](#amplify-category-plugins-do-not-follow-these-sessions).
- **Kinesis and Firehose share one local cache per region.** Two sessions with a Kinesis (or Firehose) client for
  the same region share the offline record cache, so one session's flush can send another session's records with
  its own credentials. Until those clients can scope their cache, don't give two sessions a record-caching client
  for the same region.
- **A provider is bound to a session ID, not to a user.** After a sign-out and a different user's sign-in on the
  same session ID, a consumer holding buffered data gets the new user's credentials without notice. The same goes for
  a guest's sign-in: one that completes at once (no challenge, or a hosted-UI sign-in) hands the user's credentials to
  a consumer still holding the guest's buffer, which is then sent as the user. `notSignedIn` (`.discard`) marks the
  change of principal only when the sign-in stops on a challenge. Flush a guest's buffered work before any sign-in:
  without a challenge it is sent as the user, and with one the provider answers `.discard`.
- **One system sheet at a time** across the client's sessions: no concurrent hosted-UI sign-ins. The Auth plugin's
  sheets are not counted.
- **No "sign out of every session".** Loop over `storedSessions`.
- **How many sessions an app can hold** at once has no stated limit yet. Each costs memory and SDK clients.
- **An app and its extension sharing a session** (same access group and session ID) have no concurrency guard
  between them. With refresh-token rotation, this can leave a record that can't refresh, so expect to handle
  sign-in again. Nor does a running app see the extension's sign-in or sign-out at once: its session keeps what it
  holds in memory until it reads the saved login again. A signed-in or guest session reads it at its next refresh
  (`fetchAuthSession(options: .init(forceRefresh: true))` forces one; a sign-out elsewhere is then reported as signed
  out), and, with an identity pool configured, a signed-out session at its next `fetchAuthSession` (without one, a
  signed-out session doesn't pick up another writer's login in that process). The Auth plugin with an access group
  reads it at every `fetchAuthSession`. An extension on the Auth plugin that keeps running across the app's first
  launch after an update, holding a guest in memory, can write that guest back over the login the app's
  access-group migration just moved when it next refreshes: relaunch the extension after an update.
- **The plugin and the client side by side over `.default`** in one app are not supported: they share one saved
  login, but each keeps its tokens in memory. See [Side by side is not supported](#side-by-side-is-not-supported).
- **`.default`'s signed-out row names the last user the client wrote**, not the plugin's: after the plugin deletes
  a user, or signs someone else in and out, the row names the last user the client wrote until the client writes the
  session again: a sign-in through the client, a client refresh of another user the plugin signed in, a guest fetch
  or a purge. See
  [Labels and the signed-out row after a plugin action](#labels-and-the-signed-out-row-after-a-plugin-action).
- **Rollback to an older plugin release**: plugin releases before 2.51.0 can't refresh at all on an app client with
  rotation on. Releases before 2.53.3 can wipe the plugin's keychain service, every saved session included, the
  first time they configure on an install that never ran one of them. Roll back to 2.53.3 or later.
- **After a relaunch, a session whose refresh token was revoked elsewhere refuses `signIn`.** Its expiry is known in
  memory only, so it restores signed in as its user, and `signIn` throws `.invalidState` ("There is already a user
  in signedIn state") until the session signs out, or a refresh in that launch reports `sessionExpired`. What to do:
  on `sessionExpired`, or on that refusal, sign the session out before showing sign-in.
- **A second refresh-token reuse counts as a dead token after 30 seconds, within one launch.** Until then the
  failure is retryable. The rule is kept in memory: after an app terminated in the middle of a refresh with
  refresh-token rotation on (Cognito rotated the token, and the new one was never saved), the saved, retired refresh
  token gives the retryable `unknown` at its first refusal in every launch, and never `sessionExpired`, until the
  user signs out or signs in again. What to do: after repeated refresh failures, offer the user to sign in again.
- **A sign-in after an expired session can't be resumed after a relaunch.** This affects a session whose refresh
  token expired (it reported `sessionExpired`) when its user signs in again, that sign-in stops on a challenge
  (an MFA code, say), and the app is closed before the user answers. The saved login still holds the expired user,
  so on relaunch the saved challenge is discarded. The session's expiry is known in memory only: after the relaunch
  it is signed in as that user again, its cached tokens and AWS credentials are handed out while they are still
  valid (when the expiry was found early, by a forced refresh or after a revoke elsewhere), and only its next
  refresh reports `sessionExpired` again. What to do: on `sessionExpired`, show sign-in and start it over. A first
  sign-in, or one after a sign-out, resumes as usual.
- **The side-by-side warning is temporary.** This affects apps that run the Auth plugin and the client over
  `.default` in one process, which is not supported. When `.default` finds a different user or guest in the saved
  login, it logs once under `AmplifyCognitoClient.DefaultSession` and changes nothing else. What to do: use one or
  the other for the default session, or give the client's work a named session. The warning goes when the plugin
  uses the client internally, which also makes running both over the default session supported.
- **A carried session's earlier copy can stay valid on the server.** This affects named sessions carried forward to
  a new configuration. Sign-out revokes the earlier configuration's copy with *this* configuration's app client, so
  a copy issued to another app client is not revoked, and a purge never revokes it. Either way its refresh token
  stays valid until it expires. What to do: sign out rather than purge, and to end every copy on the server, sign
  out with `globalSignOut: true`.
- **Non-JSON service responses** fail that one call without a retry; retry it yourself.
