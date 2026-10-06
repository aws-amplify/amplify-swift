# Auth Client design decisions

The decisions taken in review of the Auth Client design
([AGREED-DESIGN-AmplifyCognitoClient.md](AGREED-DESIGN-AmplifyCognitoClient.md)), with the options that were
weighed and the evidence behind each choice. All of them are written into the design.

## Summary (decided 2026-09-22)

| # | Decision | Answer |
|---|---|---|
| 1 | Two clients, same session ID | **A** — in-process registry keyed by session ID + cross-process commit guard. No lock. |
| 2 | What `signOut()` leaves behind | **A + a purge option.** Default keeps the row; the caller may opt in to removing it in the same call. |
| 3 | Sign-out-all | **Deferred — not in this design.** #2's purge option covers "sign out and forget *this* session". |
| 4 | Rollback | **A + rollback stays an explicit app choice.** Read-old/write-new, never delete; the app remains rollback-safe until it explicitly commits (the `completeAdoption()` step is kept). |
| 5 | Plugin ↔ client | **A** — the bridge: the plugin owns a client and delegates, with an accessor. |
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

## Knock-on effects of deferring sign-out-all (#3)

- There is no `.others` scope. §11 Limits records that there is no sign-out-all, so nobody reads its absence
  as an oversight.
- `SignOutScope` as a `RawRepresentable` struct is **still worth doing** even for a two-value set — it is
  what makes adding `.global`/`.others` later a non-breaking change rather than a minor bump plus an
  exhaustive-switch break.
- `AuthSignOutResult` having zero requirements is **less urgent but not moot**: a purging sign-out can still
  partially fail — revoke succeeds and local clear fails, or revoke fails and we purge anyway — and there was
  nowhere to say so. (The client returns its own `AuthClientSignOutResult`; design §14.8.)

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
