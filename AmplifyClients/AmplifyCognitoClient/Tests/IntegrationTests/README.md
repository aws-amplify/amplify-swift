# AmplifyCognitoClient integration tests

These run against real Cognito resources in a **sandbox** AWS account. Nothing account-specific is committed.

## Infrastructure

```bash
AWS_PROFILE=<sandbox-profile> infra/provision.sh us-west-2     # idempotent; again whenever provisioning changes
AWS_PROFILE=<sandbox-profile> infra/prepare-run.sh             # before every test run
AWS_PROFILE=<sandbox-profile> infra/teardown.sh                # destructive; removes only what provision made
```

`provision.sh` creates one user pool with a public app client (SRP, password and refresh flows, token revocation
on), one identity pool with unauthenticated identities enabled, and two IAM roles for it that **grant no
permissions** (credentials are still vended, which is all the tests need). The pool's MFA is **optional** with
TOTP enabled; users with no MFA preference are never challenged. Every resource is tagged
`purpose=amplify-cognito-client-integ`; both scripts check that tag before every change they make, and
`teardown.sh` refuses to delete anything without it. The tests call this user pool and identity pool R-UP and
R-IP (and the identity-only pool below R-IP2).

Every script that calls AWS requires `AWS_PROFILE` (`require_aws_profile` in `lib.sh` and `parity.py`) and
exits with an error without it: none of them picks a profile, or falls back to the CLI's default one, itself.

| User | State | Set up by |
|---|---|---|
| `alice`, `bob` | Confirmed, permanent passwords, no MFA | `provision.sh` |
| `carol` | Confirmed, TOTP enrolled and preferred (`enroll_totp.py`; skipped if already enrolled) | `provision.sh` |
| `dave` | `FORCE_CHANGE_PASSWORD` with his stored temporary password; the challenge test sets `daveNew` | `prepare-run.sh`, every run |
| `erin` | Deleted and recreated with her stored password. The delete-user test uses a fresh user instead, so only the provisioning check signs her in | `prepare-run.sh`, every run |

`provision.sh` runs `prepare-run.sh` once at the end. After that, run `prepare-run.sh` before each run. It never
touches `alice`, `bob` or `carol`, and it keeps every password stable, so a `test-without-building` re-run needs
only `prepare-run.sh`, not a rebuild. No script prints a secret or passes one to the AWS CLI as an argument.

**AWS CLI history must be off.** Passwords, tokens and carol's TOTP secret reach the CLI through
`--cli-input-json`. With `cli_history = enabled` in `~/.aws/config`, the CLI would record them in
`~/.aws/cli/history/history.db`. It is off by default. Both scripts refuse to run when `aws configure get
cli_history` prints `enabled`. They also refuse when the caller's account differs from the one `state.json`
records. No script prints an account, pool, client or key identifier: they print resource names, and the AWS
CLI's error output passes through a redactor (`redact` in `lib.sh`, `redact()` in `parity.py`).

State is written outside the repo to `~/.amplify-cognito-client-integ/`. Override it with `COGNITO_CLIENT_INTEG_DIR`, the one variable both the scripts and the host app's build phase read:

| File | Contents |
|---|---|
| `state.json` | Resource ids; the parity resources under `parity` (mode 600) |
| `amplify_outputs.json` | Client configuration for the tests |
| `<pool>-amplify_outputs.json` | One per parity pool (below), plus `hosted-ui` and `identity-only`, mode 600. The plugin's naming (`XYZ-amplify_outputs.json`); `AuthClientConfiguration(from:)` rejects a name with a dot |
| `users.json` | Passwords (`alice`, `bob`, `carol`, `daveTemporary`, `daveNew`, `erin`), `carolTotpSecret`, the code sink's `codeSinkApiKey` and the custom-auth `customChallengeAnswer`, mode 600 — secrets, never commit it |
| `build/` | The custom sender's `npm ci` output, cached by the hash of its sources |

## Plugin-parity resources

`provision.sh` runs `infra/parity.py provision` after the resources above. It adds, all tagged and reused on
re-runs (by recorded id, then by name), and changed only after a tag check:

| Id | Resource |
|---|---|
| P-5a | KMS key `alias/amplify-cognito-client-integ-senders`. Its key policy lets `cognito-idp.amazonaws.com` encrypt only for the seven parity pools (for any pool in the account only while they are first created, narrowed at the end of that run) |
| P-5b | Lambdas (Node.js 22, arm64, no dependencies, `lambda/triggers/triggers.mjs`): `…-pre-sign-up` (**refuses** every sign-up whose username does not start `ccit-` or `confirm-`, or on `email-alias`, whose email does not; auto-confirms, and auto-verifies email and phone, except usernames or emails starting `confirm-` or `ccit-confirm-`), and `…-define-auth-challenge`, `…-create-auth-challenge`, `…-verify-auth-challenge` (`SRP_A → PASSWORD_VERIFIER → CUSTOM_CHALLENGE`, or `CUSTOM_CHALLENGE` alone; the answer is `customChallengeAnswer`, and the functions are configured with only its SHA-256) |
| P-5c | The **code sink**, below: Lambda `…-custom-sender`, AppSync API `…-codes`, DynamoDB table `…-codes` |
| P-5d | Roles `…-trigger-exec` (its own log streams), `…-sender-exec` (+ `kms:Decrypt` on P-5a when the `userpool-id` encryption context is a parity pool, and `appsync:GraphQL` on `Mutation.createMfaInfo` only), `…-appsync-codes` (`PutItem`, `Query` on the table; trusted by AppSync for the code sink API only). Each must carry exactly one inline policy equal to the script's document and nothing attached (`require_role_policy_exact`). Each Lambda's log group is created up front, tagged, with 7-day retention |
| P-6 | Six user pools from the full templates in `pools/*.json` (`default`, `passwordless`, `mfa-req-totp-sms`, `mfa-req-email`, `mfa-req-all`, `email-alias`), each with a public app client (no secret, revocation on, existence errors prevented). `UpdateUserPool` resets what it is not given, so drift re-sends the whole template; `UsernameAttributes` and `UsernameConfiguration` are create-only, and drift there stops the script |
| P-6′ | Identity pool `amplify_cognito_client_integ_identity_only`: guest access, no user pool, two permissionless roles |
| P-7 | Hosted UI on `default`: a domain `amplify-client-integ-<random>` (managed login version 1) and the client `…-default-hostedui` (code grant, `openid email phone profile aws.cognito.signin.user.admin`, callback `cognitoclienthostapp://signin/`, sign-out `cognitoclienthostapp://signout/`). `hosted-ui-amplify_outputs.json` carries the `oauth` block |
| P-8 | Email for the pools with email factors (`passwordless`, `mfa-req-email`, `mfa-req-all`): `EmailConfiguration` `DEVELOPER` from a **domain identity the account has already verified**, in an SES region Cognito accepts (`us-west-2`, `us-east-1`, `eu-west-1`) whose SES account is still in the sandbox. It is used read-only (never tagged, changed or deleted; teardown leaves it alone), Cognito sends through its email service-linked role, and the custom email sender means nothing is sent. `COGNITO_CLIENT_INTEG_SES_DOMAIN` picks the domain. Setting `COGNITO_CLIENT_INTEG_SES_EMAIL` uses an address identity the script creates and tags instead, which needs a human to click the link SES mails |
| P-10 | **WebAuthn**: a seventh pool, `webauthn` (`pools/webauthn.json`, U-WA, the plugin's WebAuthn backend): as `passwordless`, plus `WEB_AUTHN` as a first factor and `WebAuthnConfiguration` with user verification `preferred`. Its relying party is **the plugin's**, the domain in `CognitoClientHostApp/CognitoClientWebAuthnApp.entitlements` (committed, the same entry as the plugin's `AuthWebAuthnApp.entitlements`): the only app ID its apple-app-site-association lists is the plugin's `AuthWebAuthnApp` (team `94KV3E626L`), which is why the client's WebAuthn host app signs with that team and bundle identifier. The domain is not this sandbox's and is **used read-only**: provisioning makes one HTTPS GET of its apple-app-site-association to check it still lists that app ID (else `web-authn` stays pending; if the pool is already live, provisioning stops instead), and nothing on it is ever changed. The KMS key, the sender's decrypt condition and the SMS role cover this pool with the other six |
| P-9 | SNS caller role `…-cognito-sms`, as the plugin's Gen2 backends get from `multifactor: { sms: true }` (CDK's `smsRole`: `sns:Publish` on `*`, trusted by `cognito-idp` with an external id). Ours is narrower: the trust also requires `aws:SourceAccount` and `aws:SourceArn` = the seven parity pools, and the one inline policy limits `aws:RequestedRegion` to the sandbox region (`require_role_policy_exact`). Cognito refuses anything narrower than `*` (checked). The pools with SMS (`default`, `passwordless`, the three MFA-required pools) name it in `SmsConfiguration`, and provisioning refuses to enable SMS on a pool without the custom SMS sender, so nothing is ever sent; the account's SNS is in the SMS sandbox too. Tests use fictional `+1 555` numbers |

The tests label each parity pool's users by pool: U-DEF (`default`), U-PL (`passwordless`), U-WA
(`webauthn`), U-ALIAS (`email-alias`), and U-REQ-TS, U-REQ-E and U-REQ-ALL (`mfa-req-totp-sms`,
`mfa-req-email`, `mfa-req-all`).

A pool's template features that a missing prerequisite blocks are left off and listed in `state.json`
(`parity.pools.<pool>.pending`), and `parity.py` prints them. Today nothing is pending. Without a usable SES
domain the email factors would be (and `mfa-req-email` would have MFA off, `mfa-on`).
The pools' email depends on a **pre-existing, untagged** SES domain identity; teardown never touches it.
`parity.py verify` prints each resource's settings, read-only, with no identifiers.

**How codes are captured and read.** As the plugin's email-MFA and passwordless backends do: the pools' custom
email and SMS sender is a Lambda, so Cognito sends nothing and instead hands the Lambda each code (sign-up,
resend, forgot-password, attribute verification, MFA, OTP) encrypted with the KMS key. The Lambda decrypts it
with the AWS Encryption SDK (rejecting a code whose `userpool-id` encryption context is not the invoking pool)
and publishes `{username (lower-cased), code, expirationTime (+10 min)}` with the plugin's `createMfaInfo`
mutation to the AppSync API, which writes it to the table (TTL on `expirationTime`, server-set `createdAt`).
The mutation is `AWS_IAM` only and the Lambda signs it with its role, so the Lambda never holds the API key.
The plugin's tests subscribe to `onCreateMfaInfo` through `AWSAPIPlugin`, which the client target cannot link;
`CodeSink` polls `listMfaInfo(username:)` (the username is required; there is no full-table read) with a plain
`URLSession` POST and the `x-api-key` from `users.json`, and returns the newest unexpired code since a given
time; the resolver itself drops expired rows. The key can only read. Test addresses are `@example.com` and no
message is ever delivered. On `email-alias` the sink's username is the one Cognito generated, not the email.

The API key lives **7 days**. `prepare-run.sh` (`parity.py rotate-key`) makes a new one when the recorded key
has under 4 days left, and deletes expired ones. A test bundle holds the key it was built with, so rebuild (or
run `xcodebuild test`, not `test-without-building`) at least every 3 days.

Before anything else, `prepare-run.sh` runs `parity.py preflight`, which is read-only. It refuses the test run if:
- any live parity pool has `DEVELOPER` email or an SMS configuration without our custom sender for that channel
  and the KMS key;
- the borrowed SES domain is no longer verified, or its region's SES account has gained production access;
- the account's SNS has left the SMS sandbox;
- a parity pool is missing from `state.json` or the account (`MISSING`), or its self sign-up differs from its
  template or is not stated (`DRIFT`). `verify` reports the same and also exits non-zero.

**Self sign-up and the account's security tooling.** Every parity template allows self sign-up, because the
tests sign users up. The account's security tooling may flag each such pool, and an automated mitigation may
then turn self sign-up off with its own `UpdateUserPool` call. Provisioning then **keeps it off**: a re-run
never silently undoes a mitigation. Once that is settled for the account (an exception for the findings, or a
recorded choice to re-enable without one), `COGNITO_CLIENT_INTEG_REENABLE_SELF_SIGN_UP=1
infra/provision.sh` re-enables it. `python3 infra/test_parity.py` tests these rules without calling AWS.

Provisioning enforces the same rules. It refuses `DEVELOPER` email or SMS on a template that lacks the custom
sender, and refuses SMS outside the SMS sandbox. `parity.py verify` reports each pool's senders. It also exits
non-zero on a gap, and on a pool-wide wildcard left in the KMS policy, the sender's decrypt condition or the
SMS role's trust by a first run that stopped early.

`prepare-run.sh` also deletes users the tests created (usernames, or emails on `email-alias`, starting `ccit-`
or `confirm-`) more than 24 hours ago, in the parity pools only (P-12). `teardown.sh` removes all of it
(`parity.py teardown`, each resource after its tag check; the KMS key is scheduled for deletion in 7 days).
`provision.sh` needs `node` and `npm` for the custom sender's `npm ci`.

## Running the WebAuthn UI tests (WA-0, WA-1)

`CognitoClientWebAuthnUITests` is the client's copy of the plugin's `AuthWebAuthnAppUITests`: the same screen,
steps and passkey-sheet handling, in its own host app, `CognitoClientWebAuthnApp` (links the client and the AWS
SDK only). WA-0 runs the flow over the raw Cognito API; WA-1 through the client (`COGNITO_CLIENT_WEBAUTHN_API`,
on in `CognitoClientWebAuthn.xcconfig`). Face ID is
enrolled and matched by the plugin's simulator server, which must be running on the host.

**No local setup.** `CognitoClientHostApp/CognitoClientWebAuthnApp.entitlements` names the plugin's relying party,
committed, the same `webcredentials:` entry as the plugin's `AuthWebAuthnApp.entitlements`. The target signs with the
plugin app's team and bundle identifier (`DEVELOPMENT_TEAM`, `PRODUCT_BUNDLE_IDENTIFIER`), the app ID the relying
party's apple-app-site-association lists. So a fresh clone or worktree builds and runs WA-0 and WA-1 as it is.
`infra/parity.py` reads the same entitlements (and checks that their `webcredentials:` domain, without the
`?mode=` query, is the plugin's) and the project's signing settings: every build configuration that signs with those
entitlements must name one literal team and bundle id, with no per-SDK override. `SandboxParityProvisioningTests`
reads the entitlements from its bundle, and the build fails if they cannot be copied there. `infra/provision.sh`
refuses to run, rather than switch `WEB_AUTHN` off for every run on the sandbox, if the WebAuthn pool is live and
either the harness's settings or the relying party's apple-app-site-association cannot be used.

```bash
(cd AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/LocalServer && npm install && npm start) &
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/CognitoClientHostApp
xcodebuild test -project CognitoClientHostApp.xcodeproj -scheme CognitoClientWebAuthnUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -collect-test-diagnostics never \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 600
```

The time allowance fails a test that runs past 10 minutes instead of letting it hang the scheme: a passkey sheet
that never appears or never dismisses otherwise waits forever.

Simulator only: the simulated entitlements carry the team-prefixed app ID without a signing identity (the
plugin's CI runs the same way). Run it in its own `xcodebuild` invocation, not alongside the other schemes.

**It shares an app ID, and so a keychain, with the plugin's `AuthWebAuthnApp`.** Same team and bundle
identifier mean the same default keychain access group, and the client's session rows use the same service as
the plugin (`com.amplify.awsCognitoAuthPlugin`). Keychain items survive `simctl uninstall`, so either app can find
the other's leftovers on a simulator. Installing one app replaces the other, and each suite's `/uninstall` removes
the other's app. So: **never run the client's and the plugin's WebAuthn suites on the same simulator in one
job**. WA-1 signs out with `purgeStoredSession` and purges its session after deleting the user, so a passing run
leaves no row.

Each test uninstalls its app at teardown. That does not delete the passkeys: platform passkeys are kept per
relying party in the simulator's Passwords store, not in the app's container. The server-side credential is
deleted by step 5, or with the user at teardown, so a leftover passkey cannot sign anyone in; it can only appear
in the sheet's list, which is why the test picks this run's user by name.

## Running the hosted-UI UI tests (HU-1, HU-2)

`CognitoClientUITests` is the client's copy of the plugin's `AuthHostedUIAppUITests/HostedUISignInTests`,
in its own host app, `CognitoClientHostedUIApp` (links the client only). The app
signs in with `signInWithWebUI(presentationAnchor:)` on the hosted-UI app client of the `default` pool (P-7,
`hosted-ui-amplify_outputs.json`, copied into the app at build time), registers the `cognitoclienthostapp` URL
scheme of P-7's redirect URIs, and signs out with `signOut(presentationAnchor:)`.

| Test | Plugin test | What differs |
|---|---|---|
| HU-1 `HostedUISignInTests/testSignInSuccess` | `testSignInSuccess` | the app passes its view's window |
| HU-2 `HostedUISignInTests/testSignInWithoutPresentationAnchorSuccess` | `testSignInWithoutPresentationAnchorSuccess` | the app looks the window up itself (the foreground scene's key window), where the plugin's anchor-less call does it internally; the client's anchor is not optional |

Each test signs a fresh user up through the API (`SandboxSignUp`, in the test process; the UI-test target
compiles the six sandbox helpers from `CognitoClientIntegrationTests/`, and its build phase copies the same
fixtures), pastes its name and password into the hosted UI's form, checks that the session is signed in and that
`getCurrentUser` names the user, then signs out, checking no browser is shown. A teardown block signs a session
still signed in out, then the user deletes itself (`SandboxUserCleanup`). Both
sign in privately (ephemeral, the client's default; the plugin's app asks `.preferPrivateSession()`), so no
cookie can skip the form and no logout page is shown; the logout of a shared-cookie sign-in is pinned by the
live-engine unit tests.

**One browser per simulator.** On iOS 26 a simulator presents only its first `ASWebAuthenticationSession`, so
run each test in its own `xcodebuild` invocation on a new simulator, as the plugin's CI does:

```bash
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests
AWS_PROFILE=<sandbox-profile> infra/prepare-run.sh
cd CognitoClientHostApp
DD=/tmp/cognito-client-ui-dd
xcodebuild build-for-testing -project CognitoClientHostApp.xcodeproj -scheme CognitoClientUITests \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath $DD > /tmp/hu-build.log 2>&1
# As CI: no hardware keyboard. No pasteboard sync with the Mac while the tests paste. Saved, restored below
# (`defaults read` prints a boolean as 1 or 0, which `defaults write -bool` refuses, hence the mapping).
KB=$(defaults read com.apple.iphonesimulator ConnectHardwareKeyboard 2>/dev/null)
PB=$(defaults read com.apple.iphonesimulator PasteboardAutomaticSync 2>/dev/null)
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
defaults write com.apple.iphonesimulator PasteboardAutomaticSync -bool false
for test in testSignInSuccess testSignInWithoutPresentationAnchorSuccess; do
  UDID=$(xcrun simctl create hu com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-5)
  xcodebuild test-without-building -project CognitoClientHostApp.xcodeproj -scheme CognitoClientUITests \
    -destination "id=$UDID" -derivedDataPath $DD -parallel-testing-enabled NO -collect-test-diagnostics never \
    -only-testing:CognitoClientUITests/HostedUISignInTests/$test > /tmp/hu-$test.log 2>&1
  xcrun simctl delete "$UDID"
  # Redact, in case a change brings typed text back, then read only the summary.
  sed -i '' -E "s/Type '[^']*' into/Type '<redacted>' into/" /tmp/hu-$test.log
  grep -E "Test Case .*(passed|failed)|error:|\*\* TEST" /tmp/hu-$test.log
done
if [ -n "$KB" ]; then defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool "$([ "$KB" = 1 ] && echo true || echo false)"; else defaults delete com.apple.iphonesimulator ConnectHardwareKeyboard; fi
if [ -n "$PB" ]; then defaults write com.apple.iphonesimulator PasteboardAutomaticSync -bool "$([ "$PB" = 1 ] && echo true || echo false)"; else defaults delete com.apple.iphonesimulator PasteboardAutomaticSync; fi
rm -f /tmp/hu-build.log /tmp/hu-testSignIn*.log
rm -rf $DD   # also removes the result bundles
```

**No credential in the logs.** `typeText` would record its text in XCTest's activity log (the `xcodebuild` output
and the result bundle), so the tests paste instead: the UI-test process puts the secret on the simulator's
pasteboard (local only, expiring after a minute), taps the field's edit-menu Paste, clears the pasteboard at once
and at teardown, and checks the field by length only. Failure messages carry the app's result line, and a sheet
hierarchy only redacted (the hosted-UI domain, pool and client IDs, URLs and test users replaced). The commands
above still redact any `Type '…' into` line and delete the logs and the result bundles.

## Running the tests

The tests live in an iOS host app, `CognitoClientHostApp/`, following `AuthHostApp` and the other
`AmplifyClients` host apps. They run inside a signed app on a simulator, because that is the only way to
reach the real data-protection keychain: under `swift test` on macOS the runner is unsigned and every keychain
call fails with `errSecMissingEntitlement`.

```bash
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests
AWS_PROFILE=<sandbox-profile> infra/prepare-run.sh
cd CognitoClientHostApp

# The client suite. It links no Amplify.
xcodebuild test \
  -project CognitoClientHostApp.xcodeproj \
  -scheme CognitoClientIntegrationTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO

# The plugin-interop suite, in its own process: it links Amplify and AWSCognitoAuthPlugin as well.
xcodebuild test \
  -project CognitoClientHostApp.xcodeproj \
  -scheme CognitoClientPluginInteropTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO
```

**Run the two schemes one after the other, never concurrently on one booted simulator** (for example from
two checkouts or two concurrent runs). Both run in the same host app, so they share its keychain and `UserDefaults`, and the
interop suite wipes the plugin's services, which also hold the client suite's live session rows.

Add `-derivedDataPath <dir>` to keep the build out of the default DerivedData, and `-collect-test-diagnostics
never` to skip the diagnostics collection after a run.

The first run resolves about 30 packages and builds the AWS SDK, which takes several minutes. On a freshly booted
simulator, the first test launch can also stall with *"The test runner hung before establishing connection"*;
running it again with `test-without-building` clears it.

**Reusing a simulator: uninstall the host app first.** When the app is already installed, `xcodebuild` can launch
it from the previous install while it installs the new one. The old bundle is then moved aside and deleted about a
minute into the run, and every later test fails reading its fixtures (`NSCocoaErrorDomain Code=260`, a path under
`com.apple.containermanagerd/Dead/`). Before
each scheme on a reused simulator, boot it and remove the app (the keychain is kept, and the suites clean up their
rows):

```bash
xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl bootstatus "$UDID" -b
xcrun simctl uninstall "$UDID" com.aws.amplify.cognitoclient.CognitoClientHostApp
```

**Configuration.** The test target's *Copy sandbox configuration* build phase copies `amplify_outputs.json`,
every `<pool>-amplify_outputs.json`, `state.json` and `users.json` from `$COGNITO_CLIENT_INTEG_DIR` (default
`~/.amplify-cognito-client-integ`) into
the built test bundle, which only exists in DerivedData. This is the same build-time copy `AuthHostApp` does
from `~/.aws-amplify/amplify-ios/testconfiguration/`. If the directory is missing, the build still succeeds
with a warning. The keychain probes still run, and the tests that need the sandbox fail with a message
pointing at `provision.sh`. Change the directory by exporting `COGNITO_CLIENT_INTEG_DIR` before running
`xcodebuild`.

**How the client gets into the test targets.** Through the `AmplifyCognitoClient` package product of the local
package (the repository root). Its public API is `@_spi(AmplifyExperimental)`, and the tests reach its
`internal` symbols (the registry, `SessionRecordKey`) with `@_spi(AmplifyExperimental) @testable import
AmplifyCognitoClient`, which works because Xcode builds the package in Debug with testability on. New
dependencies of the client come through the product, so nothing here changes when the client gains one.

| Target | Links | Why |
|---|---|---|
| `CognitoClientIntegrationTests` | `AmplifyCognitoClient`, `AmplifyFoundation`, `AmplifyFoundationBridge`; `AWSCognitoIdentity`, `AWSCognitoIdentityProvider`, `AWSSTS` from `aws-sdk-swift` (pinned to the same exact version as `Package.swift`) | The client suite. Some tests call the SDK directly. No `Amplify` or `AWSCognitoAuthPlugin`, so the target is a standing proof that the client needs neither |
| `CognitoClientPluginInteropTests` | `Amplify`, `AWSCognitoAuthPlugin`, `AmplifyCognitoClient` | Tests that need a record the plugin wrote (the adoption tests). Its own scheme, so `Amplify` is configured in its own process |
| `CognitoClientHostedUIApp` (app) / `CognitoClientUITests` (UI tests) | the app: `AmplifyCognitoClient`; the UI tests: `AmplifyCognitoClient`, `AWSCognitoIdentityProvider` | HU-1 and HU-2 (above). The app's bundle identifier `com.aws.amplify.cognitoclient.CognitoClientHostedUIApp` and its keychain group are its own, so it shares no keychain with the other host apps |

Every scheme (the two above, `CognitoClientWebAuthnUITests` and `CognitoClientUITests`) sets
`LIBDISPATCH_COOPERATIVE_POOL_STRICT=1` for the test action, as the client's unit-test scheme
does, so keychain I/O cannot pin the one cooperative thread.

**Shared helpers** (`CognitoClientIntegrationTests/`):

| Helper | What it gives a test |
|---|---|
| `IntegrationTestEnvironment` | The fixtures (`configuration()`, `state()`, `users()`), a parity pool's configuration by name (`configuration(_: SandboxPool)`, e.g. `.standard`, `.passwordless`, `.emailAlias`), the raw `auth` section of an outputs file (`outputsAuthSection(_:)`, for `oauth` and the identity-only file), `uniqueSessionID(_:)` (`<tag>-<8 hex>`), `defaultAccessGroup()`, `sharedAccessGroup()` and `secondSharedAccessGroup()`, `rawKeychainAccounts(service:accessGroup:)`, `jwtClaims(_:)` |
| `CodeSink` | `code(for:since:timeout:)`: the newest code the custom senders captured for a user, polled over HTTPS (30 s by default). For a `FreshUser`: `code(for:_:since:)` with a `Kind` (`.signUp`, `.resetPassword`, `.attributeVerification`, `.mfa`, `.otp`) or the typed `signUpCode`, `resetPasswordCode`, `attributeVerificationCode`, `mfaCode`, `otpCode`; and `code(for:_:sentBy:)` / `snapshot(for:)` + `code(for:_:after:)`, which return only a code sent after the snapshot (use them for a resend or any second code) |
| `SandboxPools` | `SandboxPools.pool(_:)`: a parity pool's `configuration` for the client under test and a raw SDK `client` on its public app client (no AWS credentials): `passwordSignIn`, `userAuthSignIn`, `respond(to:_:session:)`, `signIn(_:sink:)` (to tokens, answering TOTP, email/SMS MFA and OTP, MFA selection and MFA setup), `enrollTOTP(_:accessToken:)`, `requireLive(_:)` |
| `SandboxSignUp` | `signUp(on:_:)`: a fresh `ccit-` user (`@example.com`, optional fictional `+1555` number, optional passwordless), auto-confirmed or, with `needsConfirmation`, `ccit-confirm-` and unconfirmed; `confirm(_:sentSince:on:sink:)`; the identity helpers. Returns a `FreshUser`, which redacts its password, TOTP secret and sub, records later changes (`recordPassword`, `recordTOTPSecret`, `recordDeleted`) and knows the sink's key (`sinkUsername`, the generated username on `email-alias`) |
| `SandboxUserCleanup` | `delete(_:)`: the user deletes itself through its own raw sign-in (no admin call), confirming it first if needed; `XCTestCase.deleteAtTeardown(_:)` and `signUpFreshUser(on:_:)` |
| `ClientIntegrationTestCase` | The base class for suites that create sessions. Mint IDs with `makeSessionID(_:pool:)` or clients with `makeClient(_:pool:)`; `tearDown` signs each one out against its own pool with `signOutStoredSession`, purges it, and waits until the registry has released it, then deletes the users from `makeFreshUser(on:_:)` |
| `ClientSignUpTestCase` | The base of `SignUpTests` and `AutoSignInTests`: `signUp(on:pool:needsConfirmation:withPassword:)` signs a fresh `ccit-` user up through the client under test and records it, `signUpAndConfirm(on:pool:)` also confirms it with the sink's code, and `tearDown` deletes every recorded user after the sessions are signed out; `assertValidation`, `assertService` and `assertReadyForAutoSignIn` |
| `ClientMFATestCase` | The base of `TOTPSetupTests`, `MFASignInTests`, `MFAPreferenceTests` and `ChallengeResumeTests`: `signedInFreshUser(_:withPhoneNumber:)`, a fresh `default` user signed in through a new client, and `enrollTOTP(_:_:friendlyDeviceName:)`, TOTP enrolled through the client's own `setUpTOTP` / `verifyTOTPSetup` (the secret is recorded first, so cleanup can answer TOTP). Failure messages name step and error cases only |
| `DeviceTestCase` (`DeviceTests/DeviceTestSupport.swift`) | The base of the three device suites: after the base class's teardown it removes each fresh user's device and advanced-security records from this device's keychain, which the client keeps per user and never removes itself. With it, `signInToDone`, `thisDeviceKey` (the access token's `device_key`), `forceRefresh`, `assertForgetsThisDevice` and `assertOnlyThisDevice`, which compare device keys as booleans |
| `TOTP` | `code(secret:at:)`, RFC 6238, and `freshCode(secret:)`, which waits for the next 30-second step when the current one is spent (Cognito rejects a reused code) |
| `RecordingHTTPClient` | Records each user pool request's `X-Amz-Target`, final `User-Agent`, and body `AuthFlow`, `ChallengeName` and `ClientMetadata`. Install it with `Options(configureUserPoolClient: recorder.configureUserPoolClient)` |
| `ConcurrentCalls` | Calls started at once in unstructured tasks, as the plugin's stress and race tests start theirs, awaited with `fulfillment(of:timeout:)` and the plugin's limit (`results(of:timeout:)`, `concurrently(_:timeout:_:)`) |

`TestUser`, `TOTPSecret` and `SandboxSecret` keep secrets out of every textual representation, so a failure message cannot
print one.

**Keychain groups.** `CognitoClientHostApp.entitlements` grants three access groups,
`$(AppIdentifierPrefix)com.aws.amplify.cognitoclient.CognitoClientHostApp` (the default), `…Shared` and
`…Shared2` (P-11, for CS-6).
Simulator builds are signed ad hoc with these entitlements, so no team or provisioning profile is needed.

| Suite | What it covers |
|---|---|
| `AuthClientConfigurationIntegrationTests` | The real `amplify_outputs.json` loads, and its pools and namespace match `state.json` |
| `DataProtectionKeychainProbeTests` | Raw `SecItem` behaviour that the keychain module depends on, including enumeration, access groups, and write statuses |
| `CognitoBackendSmokeTests` | Guest `GetId` + `GetCredentialsForIdentity` against the sandbox identity pool, and the users fixture |
| `SandboxParityProvisioningTests` | Each parity resource, through the SDK or HTTPS directly: every outputs file loads; `default` auto-confirms and tracks devices; custom auth completes with the stored answer; a `ccit-confirm-` sign-up code reaches the code sink and confirms; email MFA and SMS MFA codes (`mfa-req-email`, `mfa-req-totp-sms`) and `EMAIL_OTP` and `SMS_OTP` codes (`passwordless`) reach the sink and complete sign-in; `passwordless` offers choice-based sign-in; the MFA-required pools challenge a fresh user; `email-alias` signs in by email with 5-minute tokens; the hosted-UI login page answers; the identity-only pool vends guest credentials; the third keychain group works. Pending features are checked in their pending form |
| `SandboxProvisioningTests` | Each user is in the state the suites need, checked through the SDK directly: `alice` is not challenged, `carol` is challenged for TOTP and a fresh code completes it, `dave` must set a new password (or, once `ChallengeTests` has set it in this run, his new password signs in: only an administrator call can reset him, so CH-1 cannot use a fresh user), `erin` signs in |
| `HarnessHelperTests` | The shared helpers, including the recorder installed through the real client's escape hatch |
| `SandboxHelperTests` | The multi-pool helpers against the sandbox: every pool auto-confirms a fresh user and cleanup deletes it (answering each pool's MFA); sign-up, resent, reset-password, attribute-verification, MFA and OTP codes reach the sink; `email-alias` codes are found by the generated username; TOTP-enrolled and unconfirmed users are cleaned up; sessions on several pools are cleaned up with their own pool |
| `WebAuthnCredentialsIntegrationTests` | WebAuthn credential listing and deletion, headless, on the WebAuthn pool (U-WA): a fresh user with no passkey lists an empty page (default size and size 1); deleting a credential Cognito never issued is `.service(.resourceNotFound)` and leaves the session signed in; page sizes 0 and 21 are refused with `.validation(field: "pageSize")` and send nothing; a signed-out session is `.notSignedIn` with no request. Requests are checked with `RecordingHTTPClient`. No passkey is registered, so no simulator sheet is needed |
| `PasswordlessSignInTests` | PL-1 … PL-23, the plugin's `PasswordlessSignInTests` with its method names: choice-based sign-in (`USER_AUTH`) on `passwordless` (U-PL: `PASSWORD`, `PASSWORD_SRP`, `EMAIL_OTP`, `SMS_OTP`). Each preferred first factor signs in (PL-1, PL-2, PL-6, PL-7) or reaches its one-time-code step with the code in the sink (PL-12, PL-13); with no preference, the first-factor selection and each choice (PL-3, PL-5, PL-8 … PL-10); wrong passwords (PL-4, PL-14 … PL-17; in `USER_AUTH` a wrong password ends the attempt); right and wrong email and SMS codes, a wrong code keeping the step pending (PL-18 … PL-23). PL-11, `testSignInWithUnsupportedPreference_givenValidUser_expectSelectChallenge`: `userAuth(preferredFirstFactor: .webAuthn)` through the anchored overload gets `.continueSignInWithFirstFactorSelection` without `.webAuthn` after one `InitiateAuth` `USER_AUTH` and no challenge answer, since U-PL offers no `WEB_AUTHN`; no sheet is shown, so no simulator server is needed. Each test signs up its own user with a password, an `@example.com` email and a fictional `+1555` number; codes come from the sink. Requests are checked with `RecordingHTTPClient.answered` |
| `MultiSessionFlowTests` | The multi-session flows over the live engine with `alice` and `bob`: MS-1 two users signed in at once, MS-3 a sign-out keeps the stored row, MS-4 `storedSessions` lists every session, MS-5 a credentials provider per session; MS-2 (signing one session out leaves the other signed in, and the event goes to the signed-out session only) is in `MultiSessionFlowTests+SignOut`, and MS-6 (the same user in two independent sessions) in `MultiSessionFlowTests+SameUser` |
| `KeychainModuleRealKeychainTests` | Parity KM-1 … KM-11: the plugin's `ScopedWipeRealKeychainTests` (Q1–Q3, Q5, Q6), with their names, over `InternalAmplifyKeychain` reached through the client's product. Services unique to each test |
| `ChallengeTests` | CH-1 … CH-6: dave's new-password challenge, carol's TOTP challenge, a pending challenge is per session, a new sign-in supersedes it, a wrong code keeps it, an expired challenge session is `challengeExpired` (waits out the 3-minute validity, so about 3 minutes) |
| `DeleteUserTests` | DU-1: a fresh user (`SandboxSignUp`, on the default pool) is deleted, the row goes, and `.userDeleted` arrives once; DU-2 (`DeleteUserTests+SignedOut`): deleting the user of a signed-out session is `.notSignedIn` and sends nothing |
| `RefreshTests` | RF-2 (concurrent forced refreshes make one network refresh per session), RF-3 (a global sign-out expires the same user's other session; it stays signed in and sends `.sessionExpired` once). RF-3's user is a fresh one on the default pool (through the plugin suites' identity pool, P-13), so its global sign-out reaches no other run |
| `CredentialsProviderTests` | CR-2 (the token provider's access token), CR-4 (a signed-out session never falls back to guest), CR-5 (a guest signs in in place, and its credentials move from the unauthenticated role to the authenticated one) |
| `PersistenceTests` | PS-2 (unreadable storage is `.unavailable(.denied)`, never signed out, and sends nothing), PS-3 (a shared-group session is listed and restored only through its group) |
| `SignOutTests` | SO-1 (`signOut()` revokes the refresh token at Cognito), SO-2 (`signOutStoredSession` revokes with no live client and keeps the row), SO-3 (`purgeStoredSession` is local only), each checked against Cognito with a plain SDK client; SO-4 (`SignOutTests+SignedOut`: signing out a signed-out session is `.complete`, with no request, event or row) |
| `UserAgentTests` | UA-1: every user pool request carries `lib/amplify-swift#<version>` and `md/amplify-cognito#<version>`, once each |
| `SignInFlowTests` (`SignInFlowTests.swift`, `SignInFlowTests+Refusals.swift`) | The single-session cases, with `alice` and `bob`: SI-1 (alice's SRP sign-in: `.done`, `.signedIn` once, a v1 session record and no plugin record, `USER_SRP_AUTH` then `PASSWORD_VERIFIER` with the Amplify user agent), RF-1 (`testForcedRefreshCommitsNewTokens`: a forced refresh commits new tokens with one `GetTokensFromRefreshToken` and no event, and a new handle reads them back), CR-1 (the provider's credentials sign an STS `GetCallerIdentity` as the authenticated role), CR-3 (guest credentials, signing as the unauthenticated role), PS-1 (a signed-in session restores across a client re-creation with no request, over the same outputs and over outputs with unrelated sections added). In `+Refusals`: SI-2 (bob with `USER_PASSWORD_AUTH`, one request), SI-3 (a wrong password is `.notAuthorized` and writes nothing), SI-4 (a second sign-in is refused on the signed-in session only, while another session signs bob in) |
| `SignInFlowTests` (parity, `SignInFlowTests+Parity.swift`) | SV-1/SV-2 (an empty username is `.validation(field: "username")` with no request, twice), SI-5 (client metadata on `InitiateAuth` and `RespondToAuthChallenge`, seen by the recorder), SI-6 (an unknown user is `.notAuthorized`), SI-7 (a sign-in and a concurrent fetch both succeed, and the fetch is coherent) |
| `SessionTests` | SE-1 (a signed-in fetch has tokens, sub, identity and credentials), SE-2 (a record deleted from the keychain out of band reads `.signedOut`), SE-3 (repeated fetches make no request), SE-4 (100 concurrent fetches across a sign-out, then 50 more, all coherent) |
| `GuestTests` | GU-1 (a guest signed out gets a new identity), GU-2 (repeated guest fetches keep one identity and one set of credentials), GU-3 (a guest has no user pool tokens) |
| `SigningTests` | SG-1: a guest's `credentialsProvider`, through `FoundationToSDKCredentialsAdapter` and the SDK's `AWSSigV4Signer`, signs the plugin's AppSync request with `Authorization`, `X-Amz-Security-Token` and `X-Amz-Date` (not sent), and an STS `GetCallerIdentity` signed the same way, which is sent and accepted |
| `StorageConfigurationTests` | CS-1 … CS-3 (a pool added or changed is a new namespace, and the client carries a session forward as the plugin does, from the namespace its marker records: a guest from identity-pool-only as it is, a user-pool session with its identity fetched on first use, a changed identity pool beside the same user pool with the tokens only (read back from the carried record); an identity-pool-only change carries nothing; the record moves. Built programmatically, since the identity-only outputs file has no user pool), CS-4 … CS-6 (a session in one access group is not visible from another, including the third group, P-11) |
| `StressTests` | ST-2 … ST-5: 50 concurrent fetches after a sign-in (no refresh), with one forced refresh (one `GetTokensFromRefreshToken`), as a guest (one identity), and 50 concurrent `getCurrentUser()` (no request) |
| `CustomAuthTests` | CA-1 … CA-3, the plugin's `AuthCustomSignInTests`, on `default`, whose P-5b triggers add a custom challenge and accept `users.json`'s `customChallengeAnswer` (a secret, never printed or recorded): CA-1 `customWithSRP` answers `PASSWORD_VERIFIER`, then the custom challenge, whose public parameters are checked; CA-2 signs out and signs in again on the same session with `userSRP`, which asks no custom challenge and answers the remembered device's `DEVICE_SRP_AUTH`; CA-3 `customWithoutSRP`, the custom challenge alone after one `InitiateAuth`. Each test signs up its own user; requests are checked with `RecordingHTTPClient` |
| `SignUpTests` (`ClientSignUpTestCase`) | SU-1 … SU-15, the plugin's `AuthSignUpTests`, `AuthConfirmSignUpTests`, `AuthResendSignUpCodeTests`, `PasswordlessSignUpTests` and `PasswordlessConfirmSignUpTests`, with their names. On `default` (SU-1 … SU-7): a sign-up auto-confirms and returns the user's `sub`; two concurrent sign-ups; an empty username or code is `.validation` with no request; an existing username is `usernameExists`; confirming an unknown user is `codeMismatch` or `codeExpired` (the app client prevents existence errors); resending to an unknown user answers a simulated email delivery. On `passwordless` (SU-8 … SU-15): a sign-up without a password waits in `.confirmUser`; the concurrent, validation and `usernameExists` cases; SU-15 confirms with the sink's code and reaches `.completeAutoSignIn`. Every user is a fresh `ccit-` (or `ccit-confirm-`) user, deleted at teardown |
| `AutoSignInTests` (`ClientSignUpTestCase`) | AS-1 … AS-3, the plugin's `PasswordlessAutoSignInTests`, on `passwordless`: `autoSignIn()` with no sign-up is `invalidState` and sends nothing; a sign-up confirmed with the sink's code, then `autoSignIn()`, signs the session in and its stream delivers `.signedIn`, and only the signing-up session is signed in and stored; a second `autoSignIn()` after a global sign-out reaches Cognito and is `notAuthorized`. Fresh `ccit-confirm-` users |
| `PasswordResetTests` | RP-1, RP-2, the plugin's `AuthResetPasswordTests` and `AuthConfirmResetPasswordTests`, on `default`, whose app client prevents existence errors: resetting an unknown user gets Cognito's simulated `.confirmResetPasswordWithCode`, and confirming a reset for one fails with a service error the plugin accepts; plus RP-3 (not counted), a whole reset of a fresh user with the sink's code, then a sign-in with the new password |
| `UserAttributesTests` | AT-1 … AT-7, the plugin's `AuthUserAttributesTests`, with their names, on `default` (no verification needed before an update; every code reaches the sink): fetch; update the email (a code to the new address, which then verifies it); update two attributes; a wrong confirmation code is `codeMismatch`; resend and confirm a verification code; send one for the signed-up email; change the password and sign in with the new one. A fresh user signed in through the client each; checks on usernames, emails and codes are booleans |
| `UserAttributesStressTests` | ST-1, the plugin's `AuthStressTests.testMultipleFetchUserAttributes`: 50 concurrent `fetchUserAttributes()` for a fresh `default` user all finish within the plugin's 30 seconds and return the signed-up email |
| `TOTPSetupTests` (`ClientMFATestCase`) | MF-1, MF-2, on `default`: `setUpTOTP()` then `verifyTOTPSetup(code:)` while signed in, the details naming the user and giving an `otpauth` URI; a wrong code first is `.service(.softwareTokenMFANotEnabled)`, then the right one succeeds with a device name |
| `MFASignInTests` (`ClientMFATestCase`) | MF-3 … MF-6, the plugin's `MFASignInTests`, on `default`: the user sets MFA up through the client, signs out, and signs in with TOTP, with SMS (confirmed with the code the custom SMS sender captured, where the plugin stops at the step), and choosing TOTP or SMS when both are enabled (`[.sms, .totp]` offered). SMS users get a fictional `+1555` number |
| `MFAPreferenceTests` (`ClientMFATestCase`) | MF-7 … MF-12, the plugin's `MFAPreferenceTests`, with their names and steps, on `default`: a new user has no preference; TOTP and SMS each enabled, preferred, not preferred and disabled; both together; two preferred types are `.service(.invalidParameter)`; `.enabled` keeps the preferred type preferred |
| `RequiredMFATests` (`RequiredMFATests.swift`, `RequiredMFATests+Email.swift`) | MF-13 … MF-23, through `signIn` and `confirmSignIn` only, with the plugin's method names. On `mfa-req-totp-sms` (U-REQ-TS), the plugin's `TOTPSetupWhenUnauthenticatedTests` (MF-13 … MF-17): a user without a phone number must set up TOTP; one with a number gets an SMS code, confirmed from the sink; TOTP set up during sign-in, also after a wrong (`softwareTokenMFANotEnabled`) or non-numeric (`invalidParameter`) code, which keeps the setup. On `mfa-req-email` (U-REQ-E, the plugin's `EmailMFAOnlyTests`, MF-18, MF-19): email MFA set up during sign-in; a wrong email code (`codeMismatch`), then the right one. On `mfa-req-all` (U-REQ-ALL, `EmailMFAWithAllMFATypesRequiredTests`, MF-20 … MF-23): the setup selection offers TOTP and email, not SMS; an emailed code; choosing email, then TOTP, at the selection. Email codes come from the sink, in place of the plugin's AppSync subscription. Each user is deleted, by the client once signed in or by `tearDown`'s raw sign-in, which answers the pool's MFA |
| `DeviceTests` (`DeviceTestCase`) | DV-1 … DV-3, the plugin's `AuthFetchDeviceTests`, `AuthRememberDeviceTests` and `AuthForgetDeviceTests`, on `default` (device tracking "always remember") with a fresh user each: after sign-in `fetchDevices()` lists this session's device with its details; after `rememberDevice()` it is listed; after `forgetDevice()` none is |
| `DeviceKeyPersistenceTests` (`DeviceTestCase`) | DV-4 … DV-9, the plugin's `DeviceKeyPersistenceIntegrationTests`, on `default`: the device key survives a sign-out and an SRP sign-in, is presented by a second session of the same user and never by another user's session; it survives SRP → password, password → SRP and four alternating cycles (one device listed each time); one and two forced refreshes succeed with a remembered device |
| `DeviceAliasTests` (`DeviceTestCase`) | DV-10 … DV-19, the plugin's `DeviceAliasTokenRefreshIntegrationTests` (#4207), on `email-alias` (email as the username, device tracking "always remember", 5-minute tokens): the user signs in by email, so the typed name differs from the tokens' username, and every refresh (one, two, after a re-sign-in, after the device persisted), remember, forget (also after a refresh), fetch with details, the same device across a sign-out and sign-in, and the whole lifecycle must find the device record under the typed name. This session's device is identified by its access token's `device_key` |
| `FederationTests` | FE-1, the plugin's `FederatedSessionTests.testUnsuccessfulFederation`, against the sandbox identity pool (R-IP), which has no external provider, so only the rejection is reachable: a made-up Facebook token is `notAuthorized`, and the signed-out session stays signed out with no record; plus (not counted) a failed federation from a guest keeps the same guest identity, as the plugin keeps the previous credentials |
| `ChallengeResumeTests` (`ClientMFATestCase`) | Design §4.11 (`docs/design/AGREED-DESIGN-AmplifyCognitoClient.md`), its own CR-1 … CR-3 (not the credentials rows): a sign-in interrupted on an MFA challenge survives the app being closed (the client released, the registry holding no live session for it, a new client with the same session ID over the same keychain). CR-1: a TOTP challenge (a fresh `default` user with TOTP enrolled and enabled) is answered in a new client, the challenge record stored while it waits and gone after; CR-2: an emailed code on `mfa-req-email`; CR-3: the new client signs in again instead, superseding the saved challenge |
| `PluginRecordLocationTests` (interop target) | The plugin, in the same app, writes its record under the legacy key the client's `.default` reads through, and writes no v1 record |
| `CredentialStoreTransitionRealKeychainTests` (interop target) | Parity IO-1 … IO-3: the plugin's access-group transition clear and migration (Q7), with their names; a row the client wrote is still listed afterwards. Wipes the plugin's (and client's) real services |
| `PluginAdoptionTests` (interop target) | AD-1, AD-2: `.default` reads the plugin's record at its first load with no user pool request, `completeAdoption()` moves it into `.default`'s own record, and later plugin writes (a forced refresh, a sign-out and a new sign-in) are ignored by a re-created `.default`; a named session reads `.signedOut` beside a signed-in plugin. Signs `alice` in through the plugin |
| `AccessGroupRemovalRealKeychainTests` (interop target) | IO-4: after the plugin's access group is removed, the moved session keeps its group and a group-less read (plugin and client listing) still finds it. Signs `alice` in through the plugin |

## Verified 2026-09-24

Against `us-west-2`: both users sign in with `USER_PASSWORD_AUTH`, map to **distinct** identity-pool identities,
and receive AWS credentials; unauthenticated (guest) credentials are also vended; re-running `provision.sh`
reuses every resource.
