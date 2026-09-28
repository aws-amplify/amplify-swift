# Rollback behaviours with refresh-token rotation and old plugin releases

**Status:** documented — for later discussion (2026-09-27).
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

## 2. Rolling back past the release that reads client records

Sequence: a client build, then a rollback to a plugin release older than the forward-compatible reader,
where the user signs out, then an update to a release with the reader. The old plugin deletes its own record and
writes no signed-out marker, so the reader finds the client's record and signs the user back in. With rotation
on, that session can be fully live again. The old binary cannot be fixed.

Options: state a minimum rollback target (the first plugin release with the reader), or add a release note.

## 3. Rolling forward to the client after 1 (matrix 03, row 9) — resolved

The client used to stay `.signedIn` on a retryable error forever. It now reports `sessionExpired` when a second
reuse, spaced from the first, finds its record unchanged.
