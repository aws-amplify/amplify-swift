# AmplifyCognitoClient (beta)

`AmplifyCognitoClient` is a standalone Amazon Cognito client. You construct it and hold it, like the other
clients in `AmplifyClients`. It needs no `Amplify.configure()` and no Auth plugin.

Each client is a handle onto one **session**, named by a `SessionID`. Several sessions can be signed in at the
same time, each with its own user, tokens, state and events. Every session can hand its AWS credentials to other
`AmplifyClients` (Kinesis, Firehose, Connect and the rest).

The Cognito logic (SRP, MFA, device tracking, token refresh, hosted UI, WebAuthn) is the same engine the Auth
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

- Open a GitHub issue on [aws-amplify/amplify-swift](https://github.com/aws-amplify/amplify-swift/issues) and put
  `AmplifyCognitoClient` in the title.
- Or comment on the pull request that introduces the client.

Useful things to include: the API you called, what you expected, what happened, the `AuthClientError` case with its
`errorDescription` and `recoverySuggestion`, and whether the app also uses the Auth plugin. Don't include tokens,
passwords, pool IDs or user identifiers.

## Install

Add the package with Swift Package Manager and link the `AmplifyCognitoClient` product. Link `AmplifyFoundation`
too if you use the credentials-provider protocol, `CredentialsError` or `StorageUnavailableReason`.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/aws-amplify/amplify-swift", branch: "feat/amplify-cognito-client-beta")
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

In Xcode, use **File > Add Package Dependencies**, enter the repository URL, and choose the branch.

Import the client with the SPI:

```swift
@_spi(AmplifyExperimental) import AmplifyCognitoClient

// Only where you match StorageUnavailableReason, read CredentialsError.disposition,
// or name the AWSCredentialsProvider protocol:
@_spi(AmplifyExperimental) import AmplifyFoundation
```

## Configure and create a client

The configuration is the `auth` section of `amplify_outputs.json`. The file is read when you build an
`AuthClientConfiguration`, never when you build a client, so constructing a client does no file I/O.

```swift
// Reads amplify_outputs.json from the main bundle; uses the default session.
let client = try AmplifyCognitoClient()

// Or load the configuration once and pass it to every client.
let configuration = try AuthClientConfiguration(from: "amplify_outputs", bundle: .main)
let work = try AmplifyCognitoClient(
    configuration: configuration,
    options: .init(sessionId: .named("work"))
)
```

Pass the resource name without `.json`. The initializer throws `AuthClientError.configuration` naming the problem:
a name with an extension, a missing file, a Gen1 file, a missing `auth` section or key, or a value outside the
schema.

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
| `SessionID.default` | The single-account session. It is also the only session that reads an existing Auth plugin session (see [Moving from the Auth plugin](#moving-from-the-auth-plugin)) |
| `SessionID.named(_:)` | An ID your app chooses: 1 to 64 characters from `A-Z a-z 0-9 _ -`, case-sensitive. Throws `AuthClientError.invalidSessionID` otherwise |
| `SessionID.new()` | An ID the library mints. Each call returns a new one, so save it |

To save an ID, store its `stringValue` and rebuild it with `named(_:)`. `SessionID` is also `Codable`.

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
- Listing also deletes interrupted sign-ins saved more than 15 minutes ago.
- A failure throws `AuthClientError.storageUnavailable`. You never get an empty list for a failure.

### Signing out or purging a saved session without a client

```swift
let id = try SessionID.named("work")

// Revokes the tokens, then clears them from this device. Keeps the row.
_ = try await AmplifyCognitoClient.signOutStoredSession(sessionId: id, configuration: configuration)

// Local only: deletes the records without revoking anything.
try await AmplifyCognitoClient.purgeStoredSession(sessionId: id, configuration: configuration)
```

If a client for that session is live in the process, both calls go through it, so its state, streams and
providers see the change at once. `signOutStoredSession` never signs out a different user: if someone else signed
in to that session meanwhile, it returns `.superseded`. A purge leaves the refresh token valid on the server until
it expires, so prefer `signOutStoredSession`.

There is no "sign out of every session" call. Loop over the listing:

```swift
for row in try await AmplifyCognitoClient.storedSessions(configuration: configuration) {
    do {
        _ = try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: row.sessionId,
            configuration: configuration
        )
    } catch {
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
away. A subscription does not keep the session alive.

```swift
Task {
    for await state in client.listenToSessionStateChanges() {
        print("New state:", state)
    }
}

Task {
    for await event in client.listenToAuthEvents() {
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
| `.sessionExpired` | The refresh token (or a federated session's provider token) was found dead. Sign in again |
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
sessions never block it. A guest session keeps its identity when it signs in. A session waiting on a challenge
starts over.

The result's `nextStep` is `.done` when the user is signed in. Otherwise it is the step to present; see
[Sign-in steps and confirmSignIn](#sign-in-steps-and-confirmsignin).

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
| `.challengeExpired` | Cognito no longer accepts the challenge (about three minutes). Call `signIn` again |
| `.invalidState` | No sign-in in progress, or it can no longer continue. Call `signIn` again |
| `.validation(field: "challengeResponse")` | Empty, or not one of the step's choices. Nothing was sent |

## Resuming an interrupted sign-in

When a sign-in stops on a challenge, the challenge is saved in the session's keychain storage (device-only, never
synchronized). The saved data is Cognito's challenge session and the step; for a TOTP setup it also holds the
shared secret. The password is never saved.

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

One system sheet (a hosted-UI sign-in, a hosted-UI sign-out page, or a passkey sheet) is shown at a time per
process, across every session. By default a second request throws `.browserBusy(holder:)`, naming the session that
holds it. `.wait(timeout:)` queues instead, for at most one hour.

### Adding another account

A browser can finish a sign-in from a cookie without the user typing anything, and return that account.
`identityExpectation` turns a wrong account into an error:

| Expectation | The returned user must be |
|---|---|
| `.none` | Anyone (the default) |
| `.matches("<sub-or-username>")` | This user ID (`sub`) or username, compared exactly. An alias never matches |
| `.distinctFromOtherSessions` | Not signed in to another saved session of this configuration |

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

`unexpectedIdentity`'s strings name no user, but its fields do. Log `errorDescription`, not the error itself,
where user identifiers must not appear.

### Cancelling and recovering

```swift
await client.cancelWebUISignIn()                        // this session's sign-in or passkey sheet
let holder = await AmplifyCognitoClient.systemSheetHolder // who holds the sheet, or nil
let freed = await AmplifyCognitoClient.resetSystemSheet() // free the sheet, whoever holds it
```

`resetSystemSheet()` is a recovery tool for a sheet that stopped responding. The call holding the sheet throws
`.userCancelled`.

## Tokens, sessions and credentials

### fetchAuthSession

`fetchAuthSession` returns the session's credentials, refreshed if needed. Each field has its own result.

```swift
let session = try await client.fetchAuthSession()

let tokens = try session.userPoolTokensResult.get()
let credentials = try session.awsCredentialsResult.get()
let identityId = try session.identityIdResult.get()
let sub = try session.userSubResult.get()
print(tokens.idToken, credentials.expiration, identityId, sub)

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
- A refresh already running for the session is joined, never duplicated.
- There is no `isSignedIn` field. Use `currentSessionState()`.
- Tokens and AWS credentials print redacted.

`getCurrentUser()` reads the saved tokens without the network. It throws `.notSignedIn` for a signed-out, guest or
federated session, and `.invalidState` while a sign-in waits on a challenge.

### Credentials for other AmplifyClients

`credentialsProvider` vends this session's AWS credentials to any client that takes an `AWSCredentialsProvider`.

```swift
import AmplifyKinesisClient

let kinesis = try AmplifyKinesisClient(
    region: "us-east-1",
    credentialsProvider: work.credentialsProvider
)
```

The provider:

- is bound to its session for life, and keeps the session alive;
- never falls back: a signed-out session throws `notSignedIn` and never quietly returns guest credentials. Call
  `fetchAuthSession()` first if you want a signed-out session to become a guest;
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
        break
    }
} catch {
    // CancellationError
}
```

| `CredentialsError` | `disposition` | When |
|---|---|---|
| `.notSignedIn` | `.discard` | Signed out, or waiting on a challenge. For the token provider also a guest |
| `.sessionExpired` | `.retryAfterReauthentication` | The refresh token (or a federated provider token) is dead |
| `.storageUnavailable(reason)` | `.retryWithBackoff`, or `.failLoudly` for `.denied` | The keychain could not be read or written |
| `.notConfigured` | `.failLoudly` | No identity pool, or a user-pool-only sign-in (credentials provider); no user pool, or a federated session (token provider) |
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
when this device has no device record for the user, as the plugin does.

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

```swift
let result = try await client.signOut()
switch result {
case .complete:
    break
case .partial(let partial):
    if let error = partial.revokeError {
        print("Refresh token not revoked:", error.errorDescription)
    }
    if let error = partial.globalSignOutError {
        print("Other devices still signed in:", error.errorDescription)
    }
    if let error = partial.hostedUIError {
        print("Browser still signed in:", error.errorDescription)
    }
case .superseded:
    print("Another user signed in meanwhile and was left signed in")
@unknown default:
    break
}

try await client.signOut(options: .init(globalSignOut: true))
try await client.signOut(options: .init(purgeStoredSession: true))
```

Outcomes are returned; failures are thrown. A thrown error (`storageUnavailable`) means the session may still be
signed in.

| Result | Meaning |
|---|---|
| `.complete` | Tokens revoked and cleared from this device, or there were none |
| `.partial(AuthClientPartialSignOut)` | Signed out on this device, but part of the work failed: `revokeError` (the refresh token stays valid until it expires), `globalSignOutError` (other devices stay signed in), or `hostedUIError` (the browser keeps its hosted-UI cookie) |
| `.superseded` | A different user signed in to the session meanwhile, and was left signed in |

| Option | Default | Effect |
|---|---|---|
| `globalSignOut` | `false` | Revokes all of the user's refresh tokens. Other sessions with the same user get `sessionExpired` at their next refresh |
| `purgeStoredSession` | `false` | Also removes the saved row, so `storedSessions` no longer lists it. Not recoverable |

Any pending sign-in on the session is cancelled. Other sessions are untouched.

### Hosted-UI sign-out

After a hosted-UI sign-in with `prefersEphemeralSession: false`, the browser holds a cookie. Clear it by signing
out with a window:

```swift
@MainActor
func hostedUISignOut(client: AmplifyCognitoClient, window: AuthClientPresentationAnchor) async throws {
    try await client.signOut(presentationAnchor: window)
}
```

- A private (default) hosted-UI sign-in left no cookie, so nothing is shown.
- `signOut(options:)` without a window can't clear the cookie, and reports it in `.partial` as `hostedUIError`.
- If the user closes the sign-out page, the call throws `.userCancelled` and the session stays signed in, as with
  the plugin.
- If the page can't be shown (sheet busy, window closed, no hosted UI configured), the session is still signed out
  here, with `.partial(hostedUIError:)`.

## Delete the user

```swift
try await client.deleteUser()
```

Deletes the signed-in user from the user pool, removes this session's row, and sends `.userDeleted`. Other sessions
with the same user find out at their next refresh. It never shows the hosted-UI sign-out, so after a shared-cookie
hosted-UI sign-in the browser keeps its cookie. Once Cognito is asked, the deletion runs to its end even if the task
is cancelled. If the user is deleted but the row can't be removed, it throws `.storageUnavailable` after the
deletion; purge or sign out to remove the row.

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
| `service(AuthClientServiceErrorCode?)` | Cognito rejected the request; the code if the client recognises it | Depends on the code |
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
} catch AuthClientError.service(.userNotConfirmed?, _, _, _) {
    print("Confirm the sign-up first")
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

A service response that isn't JSON (for example an HTML error page) is `.service` with no code and a suggestion to
retry. The client doesn't retry it itself.

Recovery suggestions name the client's calls (for example "Call signIn …"), not the plugin's.

## Moving from the Auth plugin

### The default session adopts the plugin's user

`SessionID.default` is the only session that reads the Auth plugin's saved session. While `.default` has no record
of its own, it reads the plugin's record in place, so an app moving from the plugin keeps its signed-in user.

- Its first write (a refresh, sign-out or label, say) goes to its own record and leaves the plugin's untouched, so
  rolling back to a plugin-only release still finds the user.
- `completeAdoption()` copies the plugin's record into `.default`'s own and deletes the plugin's. It is idempotent,
  and a no-op for any other session. It keeps the plugin's record, and throws, if that record holds a different
  user or changed while it was copying.

```swift
let client = try AmplifyCognitoClient() // .default
if case .signedIn = await client.currentSessionState() {
    try await client.completeAdoption()
}
```

- After adoption, `.default` and the plugin share one refresh token. Signing out through `Amplify.Auth`, or any
  other revocation of that token, ends `.default` on the server. `.default` keeps reporting `.signedIn` until its
  next refresh fails.
- After `completeAdoption()`, rolling back to a plugin release without the reader for client records loses the
  user. Plugin releases with that reader fall back to `.default`'s record.

### Side by side is not supported

Don't run the plugin and the client over the same session. From the first write on, they keep separate records,
and a sign-in or sign-out through one is not seen by the other. Use one or the other for the app's session.

When `.default` loads its own signed-in record while the plugin's record holds a different user or identity, the
client logs one warning under the `AmplifyCognitoClient` log category:

> The Auth plugin holds a different session than this client's default session; running both over the default
> session is not supported.

It names no one, is logged once each time the session is loaded (a new client instance logs again), and changes
nothing else. It warns for a different user, for a plugin user beside a client guest or federated session, and for
two guests with different identities. It is silent when either side is signed out or absent, for the same user,
for a plugin guest beside a client user, and when the plugin's record can't be read.

### Rolling back and forward

| Case | What happens |
|---|---|
| Back to a plugin release with the reader for client records | When the plugin has no saved session, it reads `.default`'s record. On sign-out it writes a signed-out marker instead of deleting, while a client record exists |
| Back to the plugin with refresh-token rotation on, after the client rotated the token | The plugin's next refresh fails with `AuthError.service` (`RefreshTokenReuseException`) and sends no `sessionExpired` Hub event. The user must sign in again |
| Forward to the client with rotation on, after the plugin rotated the token | `.default` resumes on its older record with a dead refresh token. The first refresh fails as retryable; a second, at least 30 seconds later with nothing saved meanwhile, reports `sessionExpired` (one `.sessionExpired` event). The session stays `.signedIn` until the user signs in again |

## Changing the configuration

Saved sessions are scoped to the configuration's pools (user pool ID, identity pool ID, or both) and to the
keychain access group. A client with a different configuration sees a different set of saved sessions.

When the pools change, a session is carried forward the first time it is restored, from the configuration the
app last used for that session:

| Change | The session after the change |
|---|---|
| Identity pool only, then a user pool added | The guest or federated identity, as it was |
| User pool only, then an identity pool added | Signed in; the identity is fetched on first use |
| Identity pool changed, same user pool | Signed in with **user pool tokens only**; the new identity pool issues a new identity on first use. (The plugin keeps the old pool's identity ID) |
| Identity pool removed, same user pool | Signed in with user pool tokens only |
| Anything else (another user pool, another access group) | Nothing carried. **The old record is kept**, where the plugin deletes it |

- Nothing is carried from a session whose last saved state is signed out.
- The old record is kept, so each configuration keeps its own session: switching back finds it as it was, unless
  it was signed out there. An app can switch configurations at runtime under one session ID.
- Two configurations that share a user pool but differ in identity pool are one carried session: a sign-out in
  either ends it in both.
- Signing out or purging a carried session also deletes the record it was carried from, but only if that record
  hasn't been written since, provably holds the same user, and isn't a guest's (an extension may still use that
  identity). An extension that only reads the old record loses it at sign-out.
- Sign-out revokes a deleted copy's refresh token when it differs from the one it revoked and belongs to the same
  user pool. Otherwise, and on purge, the copy's refresh token isn't revoked and stays valid until it expires.
- A rollback carries by the same rules: back on the old configuration, the kept record is used (a guest keeps its
  identity), unless the session, if not a guest, was signed out or purged under the new one.
- If a carried session's identity fetch fails, it keeps its user pool tokens and retries, as the plugin does. A
  known refusal isn't retried for that user until the app restarts or the session is signed out or purged; other
  failures not within 30 seconds. Until then the identity fields report the failure.
- A session saved by an earlier build without copy-forward isn't carried if the configuration changes before this
  build first restores it.
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
        config.maxAttempts = 5
    })
)
```

The closure runs after the client sets the region, signing region and credential resolver, so it can override
them. Only the handle that builds the session applies it. To change timeouts, replace `httpClientEngine`: setting
only `httpClientConfiguration` has no effect.

The client logs through AmplifyFoundation's logging, under the `AmplifyCognitoClient` category. Add a sink to see
it:

```swift
AmplifyLogging.addSink(AmplifyOSLogSink(logLevel: .warn))
```

## Differences from the Auth plugin

The client keeps the plugin's semantics except where listed here.

| Area | Auth plugin | AmplifyCognitoClient |
|---|---|---|
| Configuration | Gen1 and Gen2 | Gen2 `amplify_outputs` only; Gen1 refused |
| Sessions | One, in `Amplify.Auth` | Many, one per `SessionID`, each with its own state and events |
| Second sign-in | Refused while signed in | Refused only on the same session |
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
| Sign-out result | `AuthSignOutResult` | `.complete`, `.partial`, `.superseded`; failures throw |
| `isSignedIn` | On the session and results | Not provided; use `currentSessionState()` |
| Service error code | `underlyingError as? AWSCognitoAuthError` | `AuthClientError.service(code, …)` |
| MFA type `rawValue` | The Cognito name | `"sms"`, `"totp"`, `"email"`; use `challengeResponse` |
| Deprecated `validationData` on sign-in, `.custom` flow | Supported | Not mirrored: use `clientMetadata`, `.customWithSRP` |
| TOTP setup details | Printed in full | Secret redacted |
| Non-JSON service response | "Report a bug" suggestion | `.service` with no code and a retry suggestion |
| Configuration change | Carries some changes, deletes the old record otherwise | Carries the same changes, keeps the old record; a changed identity pool keeps user pool tokens only |
| Credential error types | Not applicable | `CredentialsError` and `StorageUnavailableReason` need `@_spi(AmplifyExperimental) import AmplifyFoundation` |
| Category plugins | Use its session | Don't see client sessions |

## Known limitations

- **Category plugins don't follow client sessions**, and nothing warns you. See
  [above](#amplify-category-plugins-do-not-follow-these-sessions).
- **Kinesis and Firehose share one local cache per region.** Two sessions with a Kinesis (or Firehose) client for
  the same region share the offline record cache, so one session's flush can send another session's records with
  its own credentials. Until those clients can scope their cache, don't give two sessions a record-caching client
  for the same region.
- **A provider is bound to a session ID, not to a user.** After a sign-out and a different user's sign-in on the
  same session ID, a consumer holding buffered data gets the new user's credentials without notice.
- **One system sheet at a time** per process: no concurrent hosted-UI sign-ins.
- **No "sign out of every session".** Loop over `storedSessions`.
- **How many sessions an app can hold** at once has no stated limit yet. Each costs memory and SDK clients.
- **An app and its extension sharing a session** (same access group and session ID) have no concurrency guard
  between them. With refresh-token rotation, this can leave a record that can't refresh, so expect to handle
  sign-in again.
- **Rollback with rotation** to the plugin: the plugin reports `AuthError.service` and sends no `sessionExpired`
  event; the user must sign in again.
- **Rollback to an older plugin release**: if the user signs out in a plugin release that predates the reader for
  client records, and the app then updates to a release with the reader, the reader finds the client's record and
  signs the user back in. Plugin releases before 2.51.0 can't refresh at all on an app client with rotation on.
- **A second refresh-token reuse counts as a dead token after 30 seconds.** Until then the failure is retryable.
- **Re-sign-in after an expired refresh token, interrupted on MFA**: on relaunch the saved challenge is discarded,
  and the user starts sign-in over.
- **The plugin-conflict warning** isn't logged when the plugin holds a guest beside a client user.
- **Carried copies' refresh tokens**: a copy under an earlier configuration is revoked at sign-out only with this
  configuration's app client, and never on purge.
- **Non-JSON service responses** fail that one call without a retry; retry it yourself.
- **Verbose logs** print keychain keys, and a device record's key contains the username. Verbose logging is
  opt-in.
- **Printed configuration**: `AuthClientConfiguration.UserPool` masks its IDs, but `OAuth` (domain, redirect URIs)
  and `IdentityPool` (pool ID) print in full. None is a secret.
- `AuthClientServiceErrorCode` conforms to `Error` but is never thrown on its own.
