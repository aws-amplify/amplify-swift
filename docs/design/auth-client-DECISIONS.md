# Auth Client design decisions

The decisions taken in review of the Auth Client design
([AGREED-DESIGN-AmplifyCognitoClient.md](AGREED-DESIGN-AmplifyCognitoClient.md)), with the options that were
weighed and the evidence behind each choice. All of them are written into the design.

Decisions 1–8 were taken in review on 2026-09-22. Decisions 9–20 were taken while the client was built, up to
the beta (2026-09-23 to 2026-10-05); they are summarised [below](#later-decisions-2026-09-23-to-2026-10-05). Where
a later decision changes an earlier one, the earlier entry says so and is kept as the record.

## Summary (decided 2026-09-22)

| # | Decision | Answer |
|---|---|---|
| 1 | Two clients, same session ID | **A** — in-process registry keyed by session ID + cross-process commit guard. No lock. |
| 2 | What `signOut()` leaves behind | **A + a purge option.** Default keeps the row; the caller may opt in to removing it in the same call. |
| 3 | Sign-out-all | **Deferred — not in this design.** #2's purge option covers "sign out and forget *this* session". |
| 4 | Rollback | **A + rollback stays an explicit app choice.** Read-old/write-new, never delete; the app remains rollback-safe until it explicitly commits (the `completeAdoption()` step is kept). *Superseded for the default session on 2026-10-02 by #12: it is the plugin's own saved login, so there is nothing to adopt. Named sessions are still siblings of the plugin's record.* |
| 5 | Plugin ↔ client | **A** — the bridge: the plugin owns a client and delegates, with an accessor. *Not built for the beta: see #13.* |
| 6 | `AuthSessionState.isSignedIn` | **A** — drop it. |
| 7 | `setLabel` | **A** — plain rename to `setSessionLabel`. Tags + `findStoredSessions` deferred; both are additive later, so nothing is lost. |
| 8 | Storage key shape | **Long key.** `amplify.<userPoolId>.<identityPoolId>.<sessionId>.session` stays (later given a version segment and a pool namespace: see the design's §6). |

The registry was later keyed by session ID alone, with the storage namespace and a configuration fingerprint
checked beside it, so that a session ID reused with a different pool throws instead of silently installing a
second session (design D.1).

**#4:** rollback is a capability we keep, explicitly so users can ship a previous version again. The two-step
adoption stays — read-through first, then an explicit take-over the app triggers when it is confident — so the
app controls when rollback stops being possible. Never delete the old key on migration; sign-out and purge
must delete **both**.

*Superseded for the default session (2026-10-02, #12).* The default session reads and writes the plugin's own
saved login, so there is no second key, no read-through and no `completeAdoption()`. Rollback still works, and
works better: a rolled-back plugin reads the newest login. The caveats that remain are #18.

**#8 follow-ons, now that the long key is settled:**
- **Validate `SessionID` eagerly** against `[A-Za-z0-9_-]`, non-empty, with a typed error naming the
  offending character. This is what removes the delimiter ambiguity from the long key — no `.` or `/` can
  reach a key segment. Two independent vendors already agree on this exact charset (Firebase's
  `applicationNameAllowedCharacters`, and the AWS shared-config profile-name rule).
- **`SessionID` is case-sensitive.** Lowercasing would silently merge `.named("Work")` and `.named("work")`
  into **one** session — a credential-crossover bug of exactly the class flagged in
  `AWSCognitoIdentityPoolOperations.kt:61`. Keychain accounts are case-sensitive, so case-sensitive is also
  the lower-surprise default. Note this leaves a pre-existing inconsistency untouched and unrelated to
  `SessionID`: `generateDeviceMetadataKey` lowercases the username while `generateASFDeviceKey` does not
  (`AWSCognitoAuthCredentialStore.swift:151, 158`).
- **Add a version segment now.** Free today, impossible to retrofit. Firebase's key carries the rationale
  in a comment: *"A number \"1\" is encoded in the prefix in case we need to upgrade the scheme in
  future."*
- **Say what the key does when a pool ID is absent** but a session name is present — Android's pool IDs are
  both optional so its key legitimately degenerates to three segments.
- **Do not claim we are "following Android's key format."** Android's key is byte-identical to Swift's
  today; ours adds a segment Android does not have.
- Store-level namespacing (Amplify Android's `com.amplify.credentialStore.$suffix`) was considered and **not
  chosen**.

## Hosted UI — decided 2026-09-22

**Two browser sign-ins at once: not supported.** That is the settled scope, and §9.1's limitation stays. The
design does not need to present two browser UIs simultaneously; sessions are established sequentially.

**§9's ephemeral/private-window statement stays** — every platform has the option and we default to it,
which is what makes signing into a *second account* possible.

**The attribution, not the limitation, changed.** An earlier revision of §9.1 called this *"an OS constraint,
not a design limitation."* That is falsifiable: Apple documents only a **per-instance** rule for
`ASWebAuthenticationSession.start()`, the error taxonomy has **no "already in progress" case**, and no OS
enforces a device-wide limit. Every such guard in the industry is library-invented. On Android the effective
limit comes from *our own* `launchMode="singleTask"` redirect activity, and the private-window option is real
(`setEphemeralBrowsingEnabled`) and already ships in Amplify Android. So the limitation is kept and called
what it is: **a deliberate library policy**, justified by UI presentation (one `presentationAnchor`, and an
iPhone cannot provide two foreground-active anchors) rather than by an OS guarantee. Cookie isolation
(multiple accounts) and simultaneity (two browsers at once) are separate questions.

**Two caveats that still apply:**
- **Ephemeral is best-effort, and failure is silent.** Apple: a non-Safari default browser *"might or might
  not respect the request."* androidx: *"and if the browser supports it."* When it is not honoured the user
  signs in as the **wrong account**. §9 says: request ephemeral **and verify the returned identity against
  the requested one.**
- **Serialization is not inherited.** Hosted-UI flows are serialized today *only* by the single global auth
  state machine (`HostedUIASWebAuthenticationSession` is minted fresh per action, with no in-flight guard of
  its own). Splitting into N sessions removes the only serialization that exists, on a seam with a five-issue
  history (#3362 → PR #3466 → #3678 → PR #3715 → #3766). Since the one-at-a-time rule stays, it needs an
  **explicit** home in the new architecture instead of being inherited by accident — plus a public
  cancel/reset, because Auth0 documented that a lock held by a session the OS silently tore down bricks
  sign-in until app restart.

**As built.** The rule has an explicit home, a process-wide system-sheet lock, with `cancelWebUISignIn()` (this
session's sheet) and the static `resetSystemSheet()` (whoever holds it) as the public cancel and reset. Its scope
was widened on 2026-10-02: see #16.

## Knock-on effects of deferring sign-out-all (#3)

- There is no `.others` scope. §11 Limits records that there is no sign-out-all, so nobody reads its absence
  as an oversight.
- `SignOutScope` as a `RawRepresentable` struct is **still worth doing** even for a two-value set — it is
  what makes adding `.global`/`.others` later a non-breaking change rather than a minor bump plus an
  exhaustive-switch break.
- `AuthSignOutResult` having zero requirements is **less urgent but not moot**: a purging sign-out can still
  partially fail — revoke succeeds and local clear fails, or revoke fails and we purge anyway — and there was
  nowhere to say so. (The client returns its own `AuthClientSignOutResult`; design §14.8.)

## Later decisions (2026-09-23 to 2026-10-05)

Taken while the client was built, from checking the design against the code and from review of the work.
Each is written into the design; the sections after #8 below give the detail.

| # | Decision | Answer |
|---|---|---|
| 9 | Which consumers multi-session reaches | **The standalone clients, not the category plugins.** Storage, API, Analytics and the rest keep following `Amplify.Auth`; DataStore is out of scope (2026-09-23). |
| 10 | What the client depends on | **AmplifyFoundation and AmplifyFoundationBridge, never Amplify core.** The client owns its model types, and the Cognito engine it shares with the plugin is Amplify-free (2026-09-24). |
| 11 | The beta's scope | **Gen2 `amplify_outputs` only, tested end to end on iOS, passkeys included** (2026-09-25). |
| 12 | Where the default session is saved | **In the plugin's own saved login.** Named sessions keep the client's records. Replaces #4's read-old/write-new for the default session (2026-10-02). |
| 13 | The plugin and the client side by side | **Not supported in one process over the default session.** They share the saved login at rest (#12). One warning when the client finds a different user or guest there (2026-09-24, 2026-09-27, revised 2026-10-02). |
| 14 | A configuration change on the default session | **The plugin's rule.** Named sessions keep each configuration's login, so runtime switching between backends uses named sessions (2026-10-02, refined to 2026-10-05). |
| 15 | Sign-out's result | **The plugin's shape: no throw.** `.complete`, `.partial(...)` or `.failed(error)`, with `signedOutLocally` (2026-10-02). |
| 16 | "One browser sign-in at a time" | **One system sheet per process, as library policy, on iOS, macOS and visionOS**: browser sign-in, the browser sign-out page and the passkey sheet (2026-10-02). |
| 17 | The default session's own items in the plugin's keychain operations | **They belong to the plugin's session**, wherever the plugin moves or clears its login (2026-10-02 to 2026-10-05). |
| 18 | Rollback caveats that remain | **Accepted for the beta and documented**, because the plugin behaves the same way (2026-10-05). |
| 19 | How long the client stays experimental | **Behind `@_spi(AmplifyExperimental)` until the other clients act on the provider's error contract** (2026-10-05). |
| 20 | Smaller decisions | Listed in [20](#20-smaller-decisions). |

---

## 1. Two clients, same session ID — what actually happens?

In-process there is only ever **one** state machine per session: both handles resolve to the same underlying
session (design D.1), so divergence is impossible. "Last write wins" is true only **across processes** (app +
widget). That requires something process-wide to hold live sessions, so the design's C.6 says "no public
static factory" rather than "no registry".

**Cross-process is the hard case.** If a customer turns on Cognito refresh-token rotation (a server-side
app-client setting the client can't see or control, grace period as low as 0 seconds), two processes
refreshing concurrently means the loser gets `RefreshTokenReuseException` and can write its stale refresh
token over the winner's — **permanently breaking the session, forcing re-auth.**

| | Option | What it means |
|---|---|---|
| **A** ✅ | **Registry in-process + commit guard cross-process** | An internal process-wide table so same-ID handles genuinely share one state machine. Cross-process, a "commit guard": re-read storage before writing, and discard your write if someone else moved it. |
| **B** | **Registry only; accept cross-process last-write-wins** | Simpler. Document that app+widget sharing one session ID can break under refresh-token rotation. Defensible only without `accessGroup` in `Options`, which advertises app+extension sharing. |
| **C** | **Registry + a real cross-process lock** | Strongest on paper, but Supabase built exactly this and it caused worse harm than the races it fixed: production deadlocks, and orphaned locks that hung every later auth call forever. |

---

## 2. Does `signOut()` delete the saved session, or keep it?

An earlier revision contradicted itself: two places said `signOut()` **clears the record**, two said it
**leaves a signed-out row** (§4.7's code comment, D.1, the 14.2 enum and the §5 table). This had to be settled
first, because "purge" is undefined until plain sign-out is.

| | Option | Consequence |
|---|---|---|
| **A** ✅ | **`signOut()` keeps the row. Only an explicit purge deletes.** | An account picker can show *"Alice — signed out, tap to resume"*, which is the whole point of a picker. |
| **B** | **`signOut()` deletes the row.** | Simpler mental model, but `.signedOut` becomes unreachable as a *stored* state and §4.2/§4.3's picker use cases stop working as written. |

Microsoft's MSAL agrees with A: its account enumeration has `returnOnlySignedInAccounts` defaulting to YES,
i.e. a signed-out-but-still-listed row is a first-class documented state. So `storedSessions()` gains
`includingSignedOut: Bool = false`.

---

## 3. Sign out of *all* sessions — does it exist, and what shape?

There was **no** sign-out-all API, and no purge toggle on either sign-out path. Few precedents exist — this is
genuinely new surface.

| | Option | Notes |
|---|---|---|
| **A** | **A scope on sign-out**: `signOut(scope: .local / .global / .others)`, default `.local` | `.others` = "sign out everywhere except me". Model `SignOutScope` as a `RawRepresentable` **struct, not an enum** — then adding a scope later is source *and* binary compatible. |
| **B** | **A separate static** `signOutAllStoredSessions(...)` returning per-session results | More explicit about blast radius. Must return `[SessionID: Result<...>]` — not throw on first failure — or the caller can't tell which sessions are still live. |

**Deferred** (see the summary). Either shape must stay distinct from **global sign-out** (server-side,
per-*user*, crosses sessions whether you want it to or not) — three different buttons with three different
blast radii.

---

## 4. Rollback: can a customer downgrade after migrating?

The likely case is a customer shipping an older version again because a release broke something, so blocking
the downgrade path matters.

**Rollback is structurally cheap.** The new key only *inserts* a `.<sessionId>` segment, so old and new keys
are **siblings** under the same keychain service — not a move. And the plugin already does copy-and-retain for
a namespace change (`AWSCognitoAuthCredentialStore.swift:103-105`).

**Two costs, both real:** the old copy goes stale because nothing refreshes it; and sign-out must then delete
**both** keys or you resurrect a signed-out session (Firebase hit exactly this and documented it).

| | Option | Cost |
|---|---|---|
| **A** ✅ | **Read-old / write-new / don't delete.** Rollback works. | Stale old copy; sign-out must delete both keys. |
| **B** | **Migrate and delete, the Amplify v2 precedent.** No rollback. | "Customer rolls back a bad release, all users are signed out." Android saw a one-way migration fail 5–10% of the time, and couldn't root-cause it *because* the migration was one-way and unversioned. |

**Also:** add a **version segment to the key now** (see #8's follow-ons).

---

## 5. Plugin and client side by side — or plugin delegates to client?

An earlier revision allowed plugin + client side by side *"with one rule: they must not share a session ID"* —
two deliberately isolated stores. Two state machines over one user are inconsistent across instances, which
breaks some auth flows.

| | Option | Consequence |
|---|---|---|
| **A** ✅ | **The bridge: the plugin owns a client and delegates, with an accessor** | Better migration story — no dual state, no "must not share a session ID" footgun, and it matches decision 1's end state. Customers move call sites one at a time. It means rewriting §4.9, decision 1's interim step, and §4.8's read-through/take-over modes together. |
| **B** | **Keep side-by-side isolation** | Less rework, but ships the footgun. |

One scheduling consequence: a forward-compatible *reader* has to ship in the **current plugin first**, before
the new client — otherwise there's no version of the plugin that can read the new format, and the bridge has
nothing to bridge from.

*Changed while building (#12, #13).* The bridge is not built for the beta, and the "reader ships first" rule is
gone with the reader: the default session is the plugin's own saved login, so there is no new format for the
plugin to read. A different release-order rule holds instead: the plugin's scoped keychain wipe ships before the
client writes records (#17).

---

## 6. Does `AuthSessionState.isSignedIn` survive?

It was a convenience extension justified as *"reads the same as today's `AuthSession.isSignedIn`"* — a
migration aid.

| | Option |
|---|---|
| **A** ✅ | **Drop it.** It is the exact Bool the enum exists to replace, and it's *wrong* for `.guest` and `.unavailable` — a caller reaching for `isSignedIn` gets `false` on a storage failure, which is the original bug decision 7 of the design was written to fix. |
| **B** | **Keep it** as a migration convenience, documented as lossy. |

Field evidence: both Amplify Android and Amplify Flutter shipped bugs from conflating "record present" with
"credentials usable." Android's maintainer: *"There were cases we were reporting that the user was signed out,
when in fact, the user was still signed in, but did not have valid credentials."* With N sessions that
multiplies.

---

## 7. `setLabel` — cheap rename, or do it properly?

| | Option |
|---|---|
| **A** ✅ | **Just rename** `setLabel` → `setSessionLabel`. Zero risk. |
| **B** | **Replace with `tags: [String: String]` + `find(where:)`**. Okta ships tags plus a predicate query that sees both developer tags *and* ID-token claims: `Credential.find { $0.subject == "jane@example.com" }`. That also answers "which of my sessions is Alice?" |

B is additive later, so nothing is lost by shipping A.

---

## 8. Storage key shape

Keep the long key `amplify.<pool>.<pool>.<sessionId>.session`, or namespace at the store level
(`com.amplify.credentialStore.<sessionId>`) as Amplify Android does? Either works, but the long key had a live
bug: **Cognito usernames can contain `.` and the key did not escape it** — and `generateDeviceMetadataKey`
lowercases the username while `generateASFDeviceKey` doesn't, *in exactly the position `sessionId`
occupies*. So this decision also settles whether `SessionID` is case-sensitive. The long key was chosen, with
the follow-ons in the summary.

---

## 9. Which consumers does multi-session reach?

Decided 2026-09-23, checking the design against the code. **The standalone clients.** Every client in the
`AmplifyClients` family already takes a credentials provider at construction, so a session's
`credentialsProvider` binds it to that session. The category plugins resolve auth through `Amplify.Auth`, so they
keep following the plugin's session however many Auth Clients exist; DataStore is out of scope. The failure is
silent (a Storage call succeeds, against the plugin user's prefix), so the design's limit 2 and the release notes
say so loudly.

## 10. What does the client depend on?

Decided 2026-09-24. **Only AmplifyFoundation and AmplifyFoundationBridge (with the AWS SDK), never Amplify core**,
as the CloudWatch and Kinesis clients do. So the client owns its model types: `AuthClientUser`,
`AuthClientSignInStep` (a case-for-case mirror of the plugin's `AuthSignInStep`) and `AuthClientError`, in place of
Amplify core's. The Cognito engine the plugin and the client share (`InternalAWSCognitoAuth`) is Amplify-free too,
and the shared modules live outside `AmplifyPlugins/`.

## 11. The beta's scope

Decided 2026-09-25.

- **Gen2 configuration only.** A Gen1 `amplifyconfiguration.json` is refused with `AuthClientError.configuration`,
  naming Gen2 `amplify_outputs` as what to use.
- **iOS first.** The beta is tested end to end on iOS. It builds for macOS, visionOS, tvOS and watchOS, which are
  untested in the beta.
- **Passkeys (WebAuthn) end to end**, sign-in and credential management, rather than deferred.

## 12. Where is the default session saved?

Decided 2026-10-02. **In the plugin's own saved login.** `SessionID.default` reads and writes the plugin's keychain
item (account `amplify.<poolNamespace>.session`, the plugin's `AmplifyCredentials` payload). Named sessions keep
the client's own records.

| | Option | Consequence |
|---|---|---|
| **A** ✅ | **Share the plugin's saved login** | One login at rest. A rolled-back plugin reads the newest login, including a refresh token the client rotated, so rollback with refresh-token rotation on keeps the user signed in. A user signed out through the client stays signed out on every plugin release, because the record holds the plugin's own signed-out value. |
| **B** | **Keep a client copy and adopt the plugin's record** (#4 as written) | Two copies, so the plugin falls behind after a client refresh. With rotation on, a rollback sends a token the client rotated away, and the user has to sign in again. |

What it removes, all unreleased: read-through, `completeAdoption()`, the first-load side-by-side check, and the
plugin's forward-compatible reader with its signed-out marker. What the plugin's record cannot hold (the label, and
the last user for a signed-out picker row) goes in a small client item beside it, bound to that user. The commit
guard on the default session compares the stored bytes, so it needs no generation number.

## 13. The plugin and the client side by side

Settled 2026-09-24 and 2026-09-27; revised 2026-10-02 with #12. **Not supported in one process over the default
session.** The plugin keeps its tokens in memory, so with refresh-token rotation on, a refresh by one side can break
the other's token until the app relaunches. The bridge of #5 would remove that, and is not built for the beta.

- **At rest they share one login** (#12), so an app can move from the plugin to the client, or back, and keep its
  user.
- **One warning, naming no one,** when the default session re-reads the shared login and finds a different
  principal from the one it holds: another user, a guest, a user replacing a guest, or another identity ID.
  Logged once while the session is in memory, under `AmplifyCognitoClient.DefaultSession`.
- **Named sessions are unaffected.** The plugin never reads them.

## 14. A configuration change on the default session

Decided 2026-10-02; refined while building, to 2026-10-05.

| | Option | Consequence |
|---|---|---|
| **A** ✅ | **The plugin's rule for the default session; "keep" for named sessions** | The default session carries the login on the changes the plugin carries, and deletes it on any other change of the key, exactly as the plugin does. Two rules over one shared login would fight each other. Named sessions keep each configuration's login, so an app that switches backends at runtime uses named sessions. |
| **B** | **"Never clear" for every session** | Would let the client and the plugin act differently on one shared login. |

The conditions that came with it:

- **The client records the configuration in the plugin's own item**, last, so a rolled-back plugin built with the
  same configuration sees no change and never writes an older copy over a newer login.
- **A login deleted by a change is revoked when it belongs to the same user pool**, once and best effort, with the
  previous configuration's app client. Otherwise, or if that fails, its refresh token stays valid until it expires.
  When only the app client changes, nothing is deleted, as in the plugin.
- **The static `signOutStoredSession` and `purgeStoredSession` apply the rule only when it would carry**, because
  they may be called with a configuration other than the app's. They never record a configuration: only a restore
  does. A static sign-out that carried a user's login also writes the signed-out value over the login it carried
  from, while that still holds the user it signed out (2026-10-03). A static purge revokes nothing and leaves it.
- **A deleted login takes the default session's label item and interrupted sign-in with it**, whoever applies the
  change. The plugin does it too (2026-10-05): when its change deletes the login, it removes them under the old
  configuration, best effort, right after the login. Without that, the client would list a signed-out row for a
  login nobody signed out of.

## 15. Sign-out's result

Decided 2026-10-02. **The plugin's shape.** No sign-out throws: `signOut(options:)`,
`signOut(presentationAnchor:options:)` and `signOutStoredSession` return `.complete`,
`.partial(revokeTokenError:globalSignOutError:hostedUIError:storageError:)` or `.failed(AuthClientError)`.
`signedOutLocally` is false only for `.failed`, and `.failed` leaves the user signed in. Any hosted-UI sign-out page
that could not be shown or completed is `.failed`, as in the plugin. The differences from the plugin are
deliberate and documented: `.partial` carries no raw tokens, a client-only `storageError` reports a purge that
failed after the local sign-out, a federated session can be signed out, and the hosted-UI sign-out page needs a
window. `purgeStoredSession` still throws, since the plugin has no such call.

## 16. One system sheet at a time

Decided 2026-10-02, extending the hosted-UI decision above. **One system sheet per process, on the platforms that
have hosted UI: iOS, macOS and visionOS.** It covers a browser sign-in, the browser sign-out page and the passkey
sheet. It is our library's policy, not an OS rule. The public API it needs is `WebUIOptions.whenBrowserBusy`, the
`browserBusy` error, `cancelWebUISignIn()` and `resetSystemSheet()`.

## 17. The default session's own items in the plugin's keychain operations

Decided 2026-10-02 to 2026-10-05. The default session keeps two items of its own beside the plugin's login: the
label item and the interrupted sign-in (`amplify.1.<poolNamespace>.$default.meta` and `.challenge`). **They belong
to the plugin's session.** So the plugin's access-group migration and the public `KeychainStoreMigrator` move them
with the login, and an access-group transition wipe and the migration's destination clear remove them. Every
other client record is spared by the plugin's wipes and migrations.

**Release order.** The plugin's scoped wipe ships in a plugin release before the client writes records, because a
released plugin's access-group transition wipes the whole keychain service, the client's records included.

## 18. Rollback caveats that remain

Accepted for the beta on 2026-10-05, because the plugin behaves the same way, and documented in the design's
rollback matrix (§4.8):

- **A purge, or the plugin's own sign-out, after a configuration carry** leaves the earlier configuration's copy,
  because a carry keeps its source. A rollback to the build with that configuration then reads the user signed in.
  A sign-out through the client does not do this: it writes the signed-out value, which every build carries.
- **A later change that the rule does not carry, onto an earlier configuration's key,** deletes the signed-out
  login and can find the user's old copy there, which then restores signed in.

Also stated, not fixable by the client: plugins older than 2.51.0 cannot refresh at all on an app client with
refresh-token rotation on.

## 19. How long the client stays experimental

Decided 2026-10-05. **The client stays behind `@_spi(AmplifyExperimental)` until Kinesis, Firehose, Connect and
CloudWatch read `CredentialsError.disposition` and act on it.** The error contract (design §15.2) does nothing for a
consumer that does not read it, so the client is not offered as stable before its consumers honour it.
AmplifyFoundation's `CredentialsError` and `StorageUnavailableReason` are behind the same SPI (2026-09-27), so they
do not become stable API with the next release either.

## 20. Smaller decisions

- **The dead-token rule keeps 30 seconds** (2026-10-02). A refresh refused as a reused refresh token is retryable
  the first time; a second, at least 30 seconds later, with nothing saved meanwhile, reports `sessionExpired`.
- **`AuthClientServiceErrorCode` is not an `Error`** (2026-10-02). It is a plain value carried by
  `AuthClientError.service`, never thrown on its own; `errorDescription` stays as a property.
- **Logging** (2026-10-02). Every client log line is under an `AmplifyCognitoClient.<area>` category, and the
  engine's static log sites log through the caller's logger, so a client path never logs under a plugin category.
- **Keychain keys stay out of log lines** (2026-10-02). A key can hold a username or a session ID, so log lines
  name the record kind instead.
- **A non-JSON service response** (an HTML error page from the service's edge, say) gets a "retry" recovery
  suggestion in the client. The plugin's error text is not changed (2026-10-02;
  [the issue](issues/sdk-non-json-response-not-retried.md)).
