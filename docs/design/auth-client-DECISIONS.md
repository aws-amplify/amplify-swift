# Auth Client design decisions

The decisions taken in review of the Auth Client design
([AGREED-DESIGN-AmplifyCognitoClient.md](AGREED-DESIGN-AmplifyCognitoClient.md)), with the options that were
weighed and the evidence behind each choice. Decisions 1–19 are written into the design; each dated section below
says where its decisions are written.

Decisions 1–8 were taken in review on 2026-09-22. Decisions 9–19 were taken while the client was built, up to
the beta (2026-09-23 to 2026-10-05); they are summarised [below](#later-decisions-2026-09-23-to-2026-10-05).
Decisions 20–28 were taken on 2026-10-19, after end-to-end testing of the beta, decisions 29–34 on 2026-10-22, on
the review of its last round, and decisions 35–40 on 2026-10-23, on the review that followed; they are summarised
[below](#decisions-of-2026-10-19), [below](#decisions-of-2026-10-22) and [below](#decisions-of-2026-10-23). Where
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
- **Validate `SessionID` eagerly** against `[A-Za-z0-9_-]`, 1 to 64 characters, with a typed error naming the
  offending character. This is what removes the delimiter ambiguity from the long key — no `.` or `/` can
  reach a key segment. Two independent vendors already agree on this exact charset (Firebase's
  `applicationNameAllowedCharacters`, and the AWS shared-config profile-name rule). One exception:
  `named("$default")` returns `.default`, so a persisted `stringValue` round-trips; every other `$` is refused. An
  app that builds session IDs from outside input rejects `"$default"` first, or that input lands on the plugin's
  saved login.
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
  signs in as the **wrong account**. §9 says: request ephemeral, and verify the returned identity where it
  matters. *As built,* the verification is opt-in, through `WebUIOptions.identityExpectation` (`.none` by
  default; `.matches(_:)` or `.distinctFromOtherSessions`), with `prompt: [.login]` beside it.
- **Serialization is not inherited.** Hosted-UI flows are serialized today *only* by the single global auth
  state machine (`HostedUIASWebAuthenticationSession` is minted fresh per action, with no in-flight guard of
  its own). Splitting into N sessions removes the only serialization that exists, on a seam with a five-issue
  history (#3362 → PR #3466 → #3678 → PR #3715 → #3766). Since the one-at-a-time rule stays, it needs an
  **explicit** home in the new architecture instead of being inherited by accident — plus a public
  cancel/reset, because Auth0 documented that a lock held by a session the OS silently tore down bricks
  sign-in until app restart.

**As built.** The rule has an explicit home, a system-sheet lock across the client's sessions in the process, with
`cancelWebUISignIn()` (this session's sheet) and the static `resetSystemSheet()` (whichever session holds it) as the
public cancel and reset. Its scope was widened on 2026-10-02: see #16.

## Knock-on effects of deferring sign-out-all (#3)

- There is no `.others` scope. §11 Limits records that there is no sign-out-all, so nobody reads its absence
  as an oversight.
- *As built,* there is no `SignOutScope`: the option is `AuthClientSignOutOptions.globalSignOut: Bool`, as in
  the plugin, beside `purgeStoredSession`.
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
| 19 | Smaller decisions | Listed in [19](#19-smaller-decisions). |

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
| **B** | **Migrate and delete, the Amplify v2 precedent.** No rollback. | "Customer rolls back a bad release, all users are signed out." Android saw a one-way migration fail in the field, and couldn't root-cause it *because* the migration was one-way and unversioned. |

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
plugin to read. A different release-order rule holds instead: the plugin's scoped keychain wipe ships with the
client, in the same release (#17). Both shipped in 2.63.0.

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
`AmplifyClients` family that calls AWS (Kinesis, Firehose, Connect and CloudWatch) takes a credentials provider at
construction, so a session's `credentialsProvider` binds it to that session. The category plugins resolve auth through `Amplify.Auth`, so they
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
- **iOS first.** iOS is the beta's first platform; the client also builds for macOS, visionOS, tvOS and
  watchOS.
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
  from, while that still holds the user it signed out (2026-10-03). A static purge revokes nothing and leaves it,
  so until `.default` first restores under the configuration the purge carried to, the purge is undone there: the
  login is still listed, and the next restore carries it back signed in. `signOutStoredSession` ends it.
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

**Release order.** The plugin's scoped wipe ships with the client, in the same release, because the access-group
transition of a plugin release without it wipes the whole keychain service, the client's records included. Both
shipped in 2.63.0, so the releases that wipe the whole service are those before 2.63.0.

## 18. Rollback caveats that remain

Documented in the design's rollback matrix (§4.8). The first two were accepted for the beta on 2026-10-05,
because the plugin behaves the same way; the third is the client's own:

- **A purge, or the plugin's own sign-out without an access group, after a configuration carry** leaves the earlier
  configuration's copy, because a carry keeps its source. A rollback to the build with that configuration then reads
  the user signed in. A sign-out through the client does not do this: it writes the signed-out value, which every
  build carries. Nor does the plugin's sign-out under an access group from the release after 2.63.0, which writes the
  same value (#40); releases up to 2.63.0 delete the record there too.
- **A later change that the rule does not carry, onto an earlier configuration's key,** deletes the signed-out
  login and can find the user's old copy there, which then restores signed in.
- **A rollback to a plugin release before 2.63.0 while AWSMobileClient logins are still on the device** replaces
  whatever `.default` holds with the old AWSMobileClient user: those releases migrate that data at configure with no
  check. 2.63.0 keeps a user signed in through the client, but migrates over a guest and over a signed-out
  `.default`; later releases also keep a signed-out `.default` (#36). The plugin's own migration deletes those logins at its first configure, so a plugin-only app has none
  left; a client-only app keeps them until `.default` signs out or is purged. An app moving from AWSMobileClient
  ships a plugin release that migrated them first.

Also stated, not fixable by the client: plugins older than 2.51.0 cannot refresh at all on an app client with
refresh-token rotation on.

## 19. Smaller decisions

- **The dead-token rule keeps 30 seconds** (2026-10-02). A refresh refused as a reused refresh token is retryable
  the first time; a second, at least 30 seconds later, with nothing saved meanwhile, reports `sessionExpired`.
  *Refined 2026-10-19 (#28):* the rule holds within one launch, and a refused forced refresh fails rather than
  returning the tokens it sent. *Refined 2026-10-23 (#35):* a refused forced refresh counts toward the rule, and the
  expiry has its own `sessionExpired` text.
- **`AuthClientServiceErrorCode` is not an `Error`** (2026-10-02). It is a plain value carried by
  `AuthClientError.service`, never thrown on its own; `errorDescription` stays as a property.
- **Logging** (2026-10-02). Every client log line is under an `AmplifyCognitoClient.<area>` category, and the
  engine's static log sites log through the caller's logger, so a client path never logs under a plugin category.
- **Keychain keys stay out of log lines** (2026-10-02). A key can hold a username or a session ID, so log lines
  name the record kind instead.
- **A non-JSON service response** (an HTML error page from the service's edge, say) gets a "retry" recovery
  suggestion in the client. The plugin's error text is not changed (2026-10-02;
  [the issue](issues/sdk-non-json-response-not-retried.md)).

## Decisions of 2026-10-19

Taken after end-to-end testing of the beta on devices and simulators, each a change to the client or to the plugin's
access-group migration. Each is written into the release notes, and into the design and the client's README where
they describe what it changes: #26 and #27, fixes in the Cognito code the plugin and the client share, are not in the
design.

| # | Decision | Answer |
|---|---|---|
| 20 | A guest's session record in the shared service at the access-group migration | **It doesn't stop the migration of a login.** An app extension, or the client's `.default`, that fetched a session before the app's first launch after the update saved it; the app's login replaces it, on a fresh or a resumed migration. A login in the shared service is never replaced, and only a login replaces a guest: one under the app's current configuration, or the one the configuration change at the same launch carries to it, not a stale copy under another configuration's key. |
| 21 | A signed-out record in the shared service at the access-group migration | **It still stops the migration**, as a login does, so a user who signed out through the client's `.default` (which saves that record) is never signed back in by another process's old login. A plugin sign-out deleted the record instead, so after one only a device record stopped an extension's first migration. *Changed 2026-10-23 (#40):* a plugin sign-out of a login under an access group saves the same record, so it stops the migration too. |
| 22 | A known refusal of a carried session's identity step | **The AWS credentials provider fails loudly**: `CredentialsError.notConfigured` (`.failLoudly`), with the refusal underneath. `fetchAuthSession`'s identity fields keep the refusal itself, and the token provider still vends the access token. |
| 23 | Which AWSMobileClient credentials a `.default` sign-out clears | **Every identity pool's** credentials service the app's keychain holds, not only the configured one's. The plugin is unchanged. |
| 24 | A network failure (the request may not have reached Cognito) | **A retryable `.service` with no code**, in every call, with the client's network texts. The plugin keeps its mapping. |
| 25 | When a hosted-UI sign-in cancelled with `cancelWebUISignIn()` answers | **Once it has released the system sheet**: `systemSheetHolder` no longer names the session. If the sheet isn't released within a second, the call throws anyway, and the sheet stays held until the sign-in's remaining calls, or the passkey ceremony, finish. A passkey call too. |
| 26 | A forgotten device key on a sign-in that isn't SRP | **Dropped and retried once**, in the shared engine: the password (`USER_PASSWORD_AUTH`), `USER_AUTH`, custom and auto sign-in flows remove the device record and resend without a device key. Plugin and client alike. |
| 27 | The user ID of a `signUp` that completes with auto sign-in | **Carried**: Cognito's sub, as `.done` and `.confirmUser` already carried it. Plugin and client alike. `confirmSignUp`'s `.completeAutoSignIn` and `.done` still carry none, since Cognito's answer there has no sub. |
| 28 | A refresh refused as a reused refresh token | **The 30-second dead-token rule holds within one launch**, and is not persisted; a refused forced refresh fails with the retryable error instead of returning the tokens it sent, and counts toward the rule: a second one at least 30 seconds later expires the session, with its own `sessionExpired` text (`refreshTokenReused` underneath; #35). |

**#20 and #21.** An extension that fetches a session first finds the shared service empty and saves a guest identity
there. Counting that record as a migrated login aborted the app's migration and stranded its login in the old
service, so the user started as a guest. A guest's record is an identity pool identity without user pool tokens or a
federated identity. It is weighed against what the migration would move: with a login to move, the guest is
replaced; with nothing but a guest or nothing to move, the shared guest is kept, as before, so a migration with
nothing to move never discards a guest identity the app already migrated. An extension's first migration whose own
old service holds a login does move it over that guest. A signed-out record is not a guest's: it keeps blocking, so
a stale login in another process's old service cannot undo a sign-out through the client's `.default`, which saves
that record. A plugin sign-out under an access group saves the same record from the release after 2.63.0 (#40), so it
blocks too. Releases up to 2.63.0 delete the record instead, so after one only a device record stops an extension's
first migration: the device metadata a user-pool sign-in saves for a tracked device, or the advanced-security device
ID that any user-pool sign-in, hosted-UI sign-in, sign-up or password-reset attempt saves when no device metadata is
held. Without one, an extension whose old service holds a login moves it in.
The access-group transition without migration is unchanged.

**#22.** The client doesn't retry a known refusal (`notAuthorized`, `resourceNotFound`, `invalidParameter`,
`configuration`) in the same process until the user pool tokens next need a refresh or a fetch forces a refresh, so
reporting it as `.unknown` (`.retryWithBackoff`) made a consumer that follows the disposition buffer for up to an
hour, with no retry of its own able to help. It is a misconfiguration of the identity pool for this user, not a user
state, which is what `.failLoudly` means. A sign-in under the same configuration asks the same pool, so it is not
`.retryAfterReauthentication` either.

**#23.** An AWSMobileClient login kept for an identity pool the client isn't configured with would otherwise be
migrated by a later plugin build as a guest holding the old user's identity ID and AWS credentials. The client lists
the app's keychain services (attributes only) to find them; a failed listing logs one warning and clears the
configured services only.

**#24.** The sign-in flows reported a transport failure as `.unknown` with an empty description and a "report a bug"
suggestion. Only network failures count: offline, a failed DNS or host lookup, a refused or lost connection, a
timeout, or a failed secure connection. The text doesn't say the request never reached the service, since a lost
connection may follow a request the service acted on. A response that arrived but couldn't be read, App Transport
Security and authentication failures are `.service` with no code and their own texts, never an empty `.unknown`. A
sign-out's revoke or global sign-out that failed on the network keeps the sign-out's context in its suggestion in a
`.partial` result: it is not retried.

**#25.** The caller was answered at once while the browser was still closing, so `systemSheetHolder` still named the
session and an immediate retry got `browserBusy`. The caller's own task cancellation and `resetSystemSheet()` still
answer at once; a sheet not released within a second (the browser slow to close, or the code exchange already
running) doesn't hold the caller longer, and stays held until the sign-in's remaining calls, or the passkey
ceremony, finish.

**#26.** `forgetDevice` keeps this device's record, as the plugin does, so the next sign-in sends the forgotten key.
Only an SRP sign-in's password verifier and the answers to a sign-in's challenges handled Cognito's answer; a
`USER_PASSWORD_AUTH` sign-in failed on every attempt with "Device does not exist." The flows that send a device key
in their first request now do the same: any `ResourceNotFoundException` to a request that sent a device key removes
the record, and the request is sent once more without one. The rule doesn't read the message, so a
`ResourceNotFoundException` for another reason also deletes the record before the second attempt reports it. The key
can be one Cognito no longer knows for other reasons too (the device forgotten elsewhere, or the user deleted and
created again), and the rule covers them alike. Auto sign-in, added on 2026-10-22, is one of those flows: a user who
deleted their account and signs up again with the same username sends the deleted user's key. Its second attempt
reuses the sign-up's session, and if Cognito refuses that, the auto sign-in ends with the error.

**#27.** Cognito returns the sub in every `SignUp` answer, and an app keying anything on the new user needs it in the
auto sign-in case too. Its `ConfirmSignUp` answer has no sub, so an app that confirms a sign-up keeps the `userID`
from `signUp`'s `.confirmUser`.

**#28.** The rule needs two refusals in one launch, because a second writer (an app extension between Cognito's
answer and its keychain write) may still save the refresh that used the token. Persisting the first refusal was not
taken: it would make a launch-time race look like a dead token. Instead apps are told to sign the session out, then
show sign-in, after repeated refresh failures: `signIn` refuses a session still signed in as its user. A forced
refresh asks Cognito for new tokens, so answering it with the tokens it sent hid the refusal; it now fails, and
counts toward the rule like any refusal: a second forced refusal at least 30 seconds later expires the session though
its saved tokens are valid, since the token is just as dead. That expiry no longer reuses the "expired or been
revoked" text: it says the refresh token was already used and no refreshed tokens were saved, so the session cannot
be renewed (sign in again), with `refreshTokenReused` underneath (#35).

## Decisions of 2026-10-22

Taken on the review of the beta's last round. Each is written into the release notes or the client's README, and into
the design where it describes what the decision changes: #32, #33 and #34 are not in the design.

| # | Decision | Answer |
|---|---|---|
| 29 | An AWSMobileClient (Amplify v1) guest against a guest the plugin already saved | **The legacy guest replaces it**, as every plugin release does; a saved login still wins, and a failed legacy read still keeps every legacy location. Reverses the earlier rule that an old guest does not replace a saved one. The plugin's migration only: the client runs none. |
| 30 | A guest or federated `.default` copied to a configuration without an identity pool | **It reads as signed out**, as a named session there does, with its saved bytes kept, so `signIn` works and writes over them. |
| 31 | A rollback that finds a newer login of the same user under the configuration it leaves | **The newer login is carried back over the untouched copy**, by the carry's rules, with its guards. |
| 32 | A `signIn` or `confirmSignIn` whose identity pool step fails after the user pool signed the user in | **It ends signed out**, as documented: the call throws the identity pool's error, and the issued tokens are revoked. |
| 33 | `fetchAuthSession` on a session that adopted another writer's login | **It answers as for a signed-in session**, refreshing what needs it, forced or not. |
| 34 | How the plugin's public `TOTPSetupDetails` prints | **With its shared secret redacted**, as the client's details print. |

**#29.** The saved guest is often seconds old: an app extension that fetched a session first, or a launch before
first unlock that kept the legacy locations and then fetched one, saved it. Keeping it cleared the legacy locations
and cost the user their AWSMobileClient identity, and the data keyed to it. So a saved guest now counts as no
session, and the user keeps the old identity ID. A saved user-pool or federated login is never overwritten, and a
legacy login still migrates over a saved guest.

**#30.** After a change that removes the identity pool under the same user pool, the plugin's rule copies the record
as it was, and a guest or federated record restored as a kind the new configuration cannot have: every field of
`fetchAuthSession` failed, and a federated row refused `signIn`. A user's login there already reads as user pool
only. The bytes stay as the signed-out row's version, so a sign-in writes over them through the commit guard.

**#31.** With refresh-token rotation on, a refresh under the new configuration retires the kept copy's refresh
token, so a rollback that read the copy came back with a dead session. The newer record is carried back only when
the change back is one the client carries; both records are the same user pool user (the same `userId`); the newer
one holds tokens issued strictly later than the copy's (a refresh there, or a sign-in again); and the copy's bytes
are unchanged since the carry. It is written through the commit guard, and undone, as after any carry, if the newer
record was signed out or purged meanwhile. Another user's login, a guest's or federated identity's, a signed-out
one, and a copy an extension rewrote are never carried over it.

**#32.** The user pool issued tokens, but the sign-in can't finish what its configuration asks for, so the client
revokes them and leaves the session signed out, for `signIn` and `confirmSignIn` alike. The plugin's `confirmSignIn`
doesn't return in that case. The README's differences table and the release notes record it.

**#33.** A session signed out in this process adopts the login an app extension, the Auth plugin or another call has
saved since. An unforced fetch handed it out as it was, so it could return tokens and AWS credentials that had
expired since they were saved. It is now refreshed by the rule any signed-in session follows: an unforced fetch only
if it needs it, a forced one whatever its expiry.

**#34.** The plugin's tasks log their result at info, and a TOTP setup's result holds the details, which printed the
secret in full. `description`, `debugDescription`, interpolation and `dump` now show it redacted; the `sharedSecret`
property and the setup URI are unchanged.

## Decisions of 2026-10-23

Taken on the review that followed the beta's last round. #35, #36, #37 and #40 are written into the design, the
client's README and the release notes. #38 and #39 keep limitations that the client's README documents; #39's is also in
`signOutStoredSession`'s API documentation and the release notes.

| # | Decision | Answer |
|---|---|---|
| 35 | A second refusal of a reused refresh token, at least 30 seconds after the first, with nothing saved meanwhile | **The session still expires, forced or not**, even while its saved tokens are valid, and from then on, while the session is in memory (until every handle and provider for it is released, or a relaunch), its fields and providers answer `sessionExpired` until its credentials change to ones with another refresh token, or none; the same login saved again, before or after the expiry, in other bytes or with the plugin's expired flag set, is not a change. Its text says the refresh token was already used and no refreshed tokens were saved, so the session cannot be renewed, and to sign in again, with `refreshTokenReused` underneath, not the "expired or been revoked" text of a refused refresh token. Refines #28. |
| 36 | AWSMobileClient (Amplify v1) logins against a signed-out `.default` | **The signed-out record stops the plugin's migration**, as a login does: nothing migrates over it, and the old logins are cleared. A `.default` sign-out or purge through the client clears those logins before it writes the signed-out record or deletes the record. |
| 37 | A Cognito internal error (`InternalErrorException`, from either pool) and an error status the SDK does not model, in the client | **`.service` with no code**, in every call, `USER_AUTH`, auto, device SRP and passkey sign-ins, `deleteUser`, a sign-out's revoke or global sign-out, and the passkey credential calls included, with a recovery suggestion to retry (a 5xx, an internal error) or naming the refusal (a 4xx). In a `.partial` sign-out, the revoke's or global sign-out's suggestion says instead that it will not be retried; a sign-out that could not finish (`.failed`) carries the failure as any other call maps it. The plugin keeps `AuthError.unknown`. |
| 38 | A named session's configuration marker left naming an earlier configuration, by a purge stopped before its last step | **Not changed.** The next restore under the purge's configuration carries the session from the earlier one again, and the README says to purge the session again before building a client for it. |
| 39 | `signOutStoredSession` with no client for the session live in the process, and `configureUserPoolClient` | **Not given one.** Its revoke uses SDK clients built from the configuration alone, so an app's `configureUserPoolClient` (a custom endpoint, a proxy, certificate pinning) is not applied; hold a client for the session to sign out through it. A purge revokes nothing. |
| 40 | The plugin's own sign-out under a keychain access group | **It saves the signed-out record**, `{"noCredentials":{}}`, in the shared service instead of deleting the session record, on every path that ends a login: `signOut` (local or global), `clearFederationToIdentityPool` and the local sign-out after `deleteUser`, when the record holds a login (user pool tokens or a federated identity) or is already signed out. A guest's sign-out still deletes the guest's record, as does one over a record the plugin cannot read, and a sign-out with nothing saved writes nothing, as the client's `.default` writes nothing when there is nothing to sign out. A plugin sign-out of a login then counts as migrated, as a sign-out through the client's `.default` does. The migration rule is unchanged: a login or a signed-out record stops it; a guest or a configuration record alone doesn't stop a login. Not limited to `migrateKeychainItems`. Without an access group the record is still deleted. Changes #21. |

**#35.** The rule exists because a second writer may still save the refresh that used the token, and a forced
refresh refused this way is evidence of the same dead token as an unforced one, so it counts too. Keeping the
session retryable while its saved tokens last would only postpone the expiry, and hand out tokens whose refresh token
is known to be dead. The text had said the refresh token expired or was revoked, which is not what happened: the
token was used, and no one saved the refresh that used it.

**#36.** A sign-out through the client's `.default` saves that record, and so, under an access group, does the
plugin's own sign-out from the release after 2.63.0 (#40). Without an access group the plugin's sign-out deletes the
record, so an app that uses only the plugin without one is not affected; with one, the plugin's sign-out has already
cleared the old logins, so only a login that survived that clear, or was saved there since, is dropped instead of
migrated. Before, the plugin read the record as no session, so an
AWSMobileClient login that the client's sign-out failed to clear, or that an app stopped part-way kept, was migrated
over it and signed the user back in. The clear comes first so that a failed write or delete, or a process stopped
after it, leaves no login behind. A purge leaves no record, so after one only the clear protects the user. The record
protects the user only until a guest replaces it, since a guest is no session to the migration. The client's guest
fetch over `.default`'s signed-out record clears the logins again first, best effort; never over an absent record,
whose logins a plugin build must still migrate, a label alone (the sidecar, with no record) included. This rule ships in the first plugin release after 2.63.0: 2.63.0
reads the signed-out record as no session.

**#37.** These are failures Cognito reports as its own, which the `.service` case's documentation already described.
Where the client saw the failure's cause, the description and recovery suggestion are the ones it gave before, and
only the case changes. The engine kept nothing under an internal error, so it now carries the service's exception
beside the engine error for `deleteUser`, a sign-out's revoke and global sign-out, and the passkey credential calls,
which lose the engine's "report a bug" suggestion. Under a sign-out, the revoke and the global sign-out keep the
sign-out's not-retried suggestion, as a transport failure does: the sign-out has already finished on this device, so
"retry" does not fit. The plugin reads only the engine error, so its errors are unchanged.

**#38.** Rewriting the marker to the purge's own configuration before deleting it would close the window, but
changes a tested ordering for a case that needs the app terminated just before the purge's last step. The limitation
stays documented instead.

**#39.** The stored-session calls take a configuration, not a client's options. With a client for the session live
in the process, the sign-out goes through it, and so through its SDK clients.

**#40.** After a plugin sign-out under an access group, only a device record stopped an extension's first migration,
so an extension whose own old service still held a login moved it in over the user who signed out. Only ending a login
writes the record: a sign-out with nothing saved, or a guest's, writing it would let an extension that signed out
that way before the app's first launch with the group stop the app's migration and strand its login. The record is
the bytes the client's `.default` saves on sign-out, which every plugin release reads as signed out: releases back to
2.10.0 decode it as `AmplifyCredentials.noCredentials`, the value for no saved session. The next sign-in replaces it.
It ships in the plugin release after 2.63.0; releases up to 2.63.0 delete the record. With #36 it also stops the
AWSMobileClient migration, until a guest replaces the record: the plugin's own guest, or an app extension's, clears
nothing, and a guest the client's `.default` fetches over it clears the old logins first, as over the client's own
signed-out record. The client's `storedSessions(…, includingSignedOut: true)` in that access group lists `.default`
as a signed-out row after such a sign-out, with no label or username unless the client saved them beside the record.
After a configuration carry, such a sign-out survives a rollback to the build with the earlier configuration, since
that build's rule carries the signed-out record over the earlier copy (the caveat in §18 remains without an access
group). Under an access group, the transition without migration also counts the record, as it counts a login, so an
app extension configured with the group for the first time keeps its own old service's items instead of clearing
them.
