# Rollback behaviours with refresh-token rotation and old plugin releases

**Status:** §1 and §2 solved for the default session by the shared saved login (2026-10-02). §3 was resolved
earlier. Earlier status: documented — for later discussion (2026-09-27).
**Source:** the executable rollback matrix (`RollbackMatrixPluginTests` and `RollbackMatrixClientTests`).

## 1. Rolling back to the plugin with refresh-token rotation on (matrix 03, row 3)

After an app has used the client with rotation on, a rollback to the plugin leaves the plugin holding a refresh
token the client has since rotated away. The plugin's next refresh gets `RefreshTokenReuseException`, which it
reports as `AuthError.service` (`InformSessionError` maps only `NotAuthorizedException` to `sessionExpired`), and
it sends no `sessionExpired` Hub event. The user still has to sign in again, but an app waiting for
`sessionExpired` only sees failing calls.

Options: map a reused refresh token to `sessionExpired` in the plugin (a behaviour change for every plugin user
with rotation on), or keep it and say so in the release notes.

Confirmed against live Cognito (2026-09-27, rotation on, 5 s grace): a token re-presented after it was rotated
away and the grace period passed returns HTTP 400 `RefreshTokenReuseException`, not `NotAuthorizedException`, so
this does happen. The reuse does not invalidate the newer token chain, so the plugin's stale token never recovers
by retrying. A revoked token returns `NotAuthorizedException`, which both sides already map to `sessionExpired`.
Plugin releases older than 2.51.0 refresh with `InitiateAuth` `REFRESH_TOKEN_AUTH`, which Cognito refuses outright
on a rotation client (`UnsupportedOperationException`).

**Solved for `.default` by the shared saved login (2026-10-02).** The client's default session now reads and writes the plugin's own
saved login, so there is no second copy for the plugin to fall behind. A rolled-back plugin from 2.51.0 reads the
newest refresh token, the one the client rotated, and its refresh succeeds
(`testMatrix_rotationRollback_isNowSignedIn`). Rolling forward again, the client resumes on the token the plugin last
saved (`testMatrix_rollForwardAfterAPluginRotation_resumesOnTheNewestToken`). Both rows run in the plugin's and the
client's rollback matrices. What remains:
- the plugin and the client running in one process over the default session, or the plugin plus an extension, each
  keep tokens in memory, so one side's refresh can still break the other's until relaunch. That is not
  supported;
- plugins older than 2.51.0 cannot refresh at all on an app client with rotation on, whatever the client does.

The text above describes the behaviour before the shared saved login, and is kept as the record.

## 2. Rolling back past the release that reads client records

Sequence: a client build, then a rollback to a plugin release older than the forward-compatible reader,
where the user signs out, then an update to a release with the reader. The old plugin deletes its own record and
writes no signed-out marker, so the reader finds the client's record and signs the user back in. With rotation
on, that session can be fully live again. The old binary cannot be fixed.

Options: state a minimum rollback target (the first plugin release with the reader), or add a release note.

**Solved by the shared saved login (2026-10-02).** The forward-compatible reader was removed before it shipped, and
the client no longer writes a `$default` session record. No plugin release reads a client record, so none can sign a
user back in from one. A user signed out through the client stays signed out on every plugin release, because the
shared record holds `{"noCredentials":{}}` (`testMatrix_signedOutUserIsNeverSignedBackIn`,
`testMatrix_clientSignOut_readByEveryPluginAsSignedOut`). One caveat remains, from the plugin's own rule: after a
configuration change that copied the login, a purge (or the plugin's own sign-out, which deletes) leaves the earlier
configuration's copy, which a rollback to the build with that configuration reads
(`testMatrix_purgeAfterACarry_leavesTheEarlierConfigurationsCopy_caveat`).

## 3. Rolling forward to the client after 1 (matrix 03, row 9) — resolved

The client used to stay `.signedIn` on a retryable error forever. It now reports `sessionExpired` when a second
reuse, spaced from the first, finds its record unchanged.
