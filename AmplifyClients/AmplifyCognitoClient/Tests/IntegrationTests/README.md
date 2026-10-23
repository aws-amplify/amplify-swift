# AmplifyCognitoClient integration tests

These run against real Cognito resources: the **AWSCognitoAuthPlugin integration suites' own backends**. The
suites read the plugin's test configuration, by the plugin's file names: in CI, the files
`.github/composite_actions/download_test_configuration` (`resource_subfolder: auth`) puts in
`~/.aws-amplify/amplify-ios/testconfiguration/`; locally, the same files, downloaded into a directory of their own
("Running locally", below). This directory's own **sandbox** is optional ("Optional: the sandbox", at the end): CI
runs every client test, and the sandbox serves the plugin's credential-gated tests, which the plugin's CI skips or does
not run, and anyone without read access to CI's configuration bucket. Nothing account-specific is committed, no user
or secret is seeded, and no test needs AWS credentials. The client reads Gen2 `amplify_outputs` only; where the
plugin's CI has only a Gen1 file for a backend, the harness translates it to Gen2 before the client reads it ("Gen1
files", below).

## Running locally

### Run as CI does (recommended)

Run on CI's file set, as CI's client jobs read it, from a copy of your own. No backend of your own is needed. This is
CI's setup, described once here and referred to from the rest of this README:

- CI downloads the plugin's `auth` test configuration: the plugin's files at the top level, and the client's own CI
  resources' files in a `cognito-client-ci/` subfolder ("CI's additive resources", below);
- `infra/ci/ci-overlay.sh` overlays the client's roles onto a copy of the plugin's files (`email-alias extended` for
  the client suite, `extended` for the interop suite), and the build phases copy from that copy;
- no skip variable is set, and the jobs allow no skip (`enforce_no_skips: true`, `allowed_skips: 0`): every test
  runs, and a missing resource fails its tests.

The files go into a **temporary directory**, never into `~/.aws-amplify/amplify-ios/testconfiguration`, which holds
your own plugin configuration. The download is the command `.github/composite_actions/download_test_configuration`
runs for `resource_subfolder: auth`, `aws s3 cp <AWS_S3_BUCKET_INTEG_V2>/auth/ <destination> --recursive`.
`<ci-config>` is the value of CI's `AWS_S3_BUCKET_INTEG_V2`: a bucket with a path, `s3://<bucket>/<path>`, the folder
that holds `auth/`. `<ci-config-profile>` is an AWS CLI profile that can read it (CI assumes `AWS_ROLE_TO_ASSUME`).
Neither is in the repository.

```bash
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests
DOWNLOAD=$(mktemp -d /tmp/ccit-ci-download.XXXXXX)
# The download, behind checks: it refuses a directory inside ~/.aws-amplify or one that is not empty, writes the
# files mode 600, masks identifiers in errors, and has --dry-run (no AWS call).
COGNITO_CLIENT_INTEG_CI_BUCKET=s3://<bucket>/<path> COGNITO_CLIENT_INTEG_CI_PROFILE=<ci-config-profile> \
  infra/fetch-ci-config.sh "$DOWNLOAD"
# The client's roles, as the client suite's job overlays them. The new directory must not exist yet, and must not
# be inside $DOWNLOAD. For the interop suite alone, CI overlays "extended"; the client suite's set serves both.
DIR=$(mktemp -d /tmp/ccit-ci-set.XXXXXX) && rmdir "$DIR"
infra/ci/ci-overlay.sh "$DOWNLOAD" "$DIR" "email-alias extended"
```

`bash infra/test_fetch_ci_config.sh` and `bash infra/ci/test_ci_overlay.sh` test the two helpers offline, with no
AWS call.

The download is the nine top-level files listed under "CI's test configuration" (below), with no credentials file
among them, and the `cognito-client-ci/` subfolder, which holds the client's own files, its credentials file
(`ccit-ci-default-credentials.json`) among them. They name CI's backends, their code APIs' keys and the extended
role's custom-auth answer and new-password users, so keep them out of the repository and remove both directories
when you are done. No other step needs AWS credentials: the tests need none, and nothing toggles self sign-up.

Build each scheme with `COGNITO_CLIENT_INTEG_DIR="$DIR"`. The copy phases read it at build time, so rebuild after
downloading or overlaying again. From `CognitoClientHostApp/`:

```bash
cd CognitoClientHostApp
DD=/tmp/ccit-ci-dd
UDID=<simulator-udid>    # an iOS 26 simulator, e.g. from `xcrun simctl create`
build() {                # the scheme
  env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild build-for-testing -project CognitoClientHostApp.xcodeproj \
    -scheme "$1" -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD"
}
run() {                  # the scheme, then any further xcodebuild arguments
  local scheme="$1"; shift
  xcodebuild test-without-building \
    -project CognitoClientHostApp.xcodeproj -scheme "$scheme" -destination "id=$UDID" -derivedDataPath "$DD" \
    -parallel-testing-enabled NO -collect-test-diagnostics never "$@"
}

# The client suite, then the interop suite: one after the other, never at once (they share the host app).
# Before each one on a reused simulator, uninstall the host app ("Reusing a simulator", below).
build CognitoClientIntegrationTests && run CognitoClientIntegrationTests
xcrun simctl uninstall "$UDID" com.aws.amplify.cognitoclient.CognitoClientHostApp
build CognitoClientPluginInteropTests && run CognitoClientPluginInteropTests

# The hosted-UI tests (HU-1, HU-2): one test per xcodebuild invocation, each on a new simulator, with the hardware
# keyboard and pasteboard sync off. Build, then run the loop in "Running the hosted-UI UI tests" (below).
build CognitoClientUITests

# The WebAuthn tests (WA-0, WA-1). First start the plugin's simulator server, as the CI job does (Node 18 or later;
# CI uses 20.x). It enrolls and matches Face ID for the passkey sheet, and listens on 127.0.0.1 only. Use a
# simulator no plugin WebAuthn suite runs on ("Running the WebAuthn UI tests", below).
(cd ../../../../../AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/LocalServer && npm install && npm start) \
  > /tmp/ccit-localserver.log 2>&1 &
SERVER=$!
build CognitoClientWebAuthnUITests
run CognitoClientWebAuthnUITests -test-timeouts-enabled YES -default-test-execution-time-allowance 600
kill "$SERVER"           # the server you started, by its PID

rm -rf "$DOWNLOAD" "$DIR" "$DD"
```

**What to expect.** The same results as CI: every test runs, and none skips. CI's files carry no sandbox mark, so the
sandbox checks run only where the overlaid capabilities file names them for one of the client's roles ("Sandbox
checks", below). The counts change as tests are added, so they are not written down here: read them from the run's
result bundle (`xcrun xcresulttool get test-results summary --path <bundle>`), as CI's skip gate does.

The sandbox is not involved. No test asks for `infra/self-sign-up.sh`, because the self sign-up gate applies only to
files with the sandbox mark, and no `infra/` script runs. Each test signs up its own users on CI's backends and
deletes them, so a local run does not collide with a CI job.

### Only the plugin's files (a local approximation)

Skipping the overlay (building with `COGNITO_CLIENT_INTEG_DIR="$DOWNLOAD"`) runs on the plugin's own files alone.
That run is **not** CI's: the plugin's backends lack the resources some tests need ("What the plugin's CI backends
must provide", below), so those tests fail, each naming its resource, and RT-1 and RT-2 skip without the rotation
client. To turn those failures into skips that name the resource, run the tests with
`TEST_RUNNER_COGNITO_CLIENT_INTEG_CI_SKIPS=1` in `xcodebuild`'s environment, which passes it to the test process as
`COGNITO_CLIENT_INTEG_CI_SKIPS=1` ("Skips on the plugin's own files", below). A green run that way says
nothing about custom auth, new-password users, the code API on the default backend, the device-alias tests, the
sandbox checks or rotation, all of which CI runs. Never add a test "behind a CI-only skip": CI sets no skip variable
and fails the job on any skip.

### Only the files in your home directory

Without `COGNITO_CLIENT_INTEG_DIR`, the build reads `~/.aws-amplify/amplify-ios/testconfiguration`. If that holds
only the default backend's `AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json`, and no other `auth`
file, the run covers **the default backend only**:

- the interop suite and the client suite's tests on the default backend run;
- everything else fails, naming its missing files: the client tests on the other backends, HU-1, HU-2, WA-0 and
  WA-1;
- the build warns once for each missing file.

Download CI's set as above for a full run.

### On the sandbox

The sandbox's own file set is for the plugin's credential-gated tests, and for runs without read access to CI's
configuration bucket ("Optional: the sandbox", at the end).

## Test configuration: the plugin's file set

The host app's "Copy test configuration" build phases copy the files from `$COGNITO_CLIENT_INTEG_DIR`, default
`~/.aws-amplify/amplify-ios/testconfiguration`, into the built bundles (only in DerivedData), as `AuthHostApp`
does. So CI needs no switch. A missing file is named in a build warning, and every test that needs it fails with a
message naming it; nothing skips. The sandbox's `state.json`, `users.json` and `<role>-amplify_outputs.json` are
no longer read: the plugin's file set replaces them (the former "sandbox mode" is retired).

| Client role (`SandboxPool`) | Plugin file it reads (without it, the Gen1 file) | On the sandbox (`plugin-configs.py`) |
|---|---|---|
| `.standard` (`default`), also the main configuration (`configuration()`) | `AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json` (`…-amplifyconfiguration.json`) | U-DEF through its `plugin` app client (user-existence errors on, `LEGACY`), with P-13's identity pool |
| `.hostedUI` | `AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs.json` (`…-amplifyconfiguration.json`) | U-DEF's `hostedui-plugin` client, redirects `myapp://` |
| `.passwordless` | `AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json` | U-PL |
| `.mfaRequiredTOTPSMS` | `AWSCognitoAuthPluginMFARequiredIntegrationTests-amplify_outputs.json` (`…-amplifyconfiguration.json`) | U-REQ-TS |
| `.mfaRequiredEmail` | `AWSCognitoEmailMFARequiredTests-amplify_outputs.json` | U-REQ-E |
| `.mfaRequiredAll` | `AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json` | U-REQ-ALL |
| `.emailAlias` | `AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json` | U-ALIAS |
| `.webAuthn` | `AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json` | U-WA |
| identity-only (derived) | the default file's identity pool, guest flag and region, without its user pool (`identityOnlyAuthSection()`) | P-13 |
| CS-3's second identity pool (derived) | the first other outputs file whose identity pool differs from the default's and allows guests, else the default credentials file's `second_identity_pool_id` (`secondIdentityPool()`) | P-6′, named in the credentials file |
| each role's codes | that role's own file's `data` block (`url`, `api_key`), the plugin's MfaInfo API | the code sink, in every file |
| custom auth, new-password users | `AWSCognitoAuthPluginIntegrationTests-credentials.json`: `custom_challenge_answer`, `new_password_required_usernames`, `new_password_required_temporary_password`, as the plugin's `AWSAuthBaseTest` reads them. An absent file is read as empty, as the plugin reads it; a test that needs a key fails naming the file and the key | P-5b's answer; the eight `ccit-plugin-new-password-` users on `default` |

`CognitoClientIntegrationTests` and `CognitoClientUITests` copy the eight outputs files (for the three roles above
with a Gen1 name, the Gen1 file where the Gen2 one is absent) and the default credentials file,
`CognitoClientPluginInteropTests` the default outputs, `CognitoClientHostedUIApp` the hosted-UI outputs (each, or its
Gen1 file) and `CognitoClientWebAuthnApp` the WebAuthn outputs. The build warning names, for each role with neither,
both files.

### Gen1 files

The plugin's CI provides the default, MFA-required and hosted-UI backends as Gen1 `amplifyconfiguration.json` files
only. The client is Gen2 only and refuses them. So the harness (`PluginTestConfiguration.swift`, shared by the client
suites, the interop suite, the UI tests and the hosted-UI app) reads a role's Gen2 file when it is there, and
otherwise translates the plugin's Gen1 file for the same backend into the equivalent Gen2 outputs, writes it under the
Gen2 name into a directory of its own, and hands the client that directory as the bundle. The client then loads it
with `AuthClientConfiguration(from:bundle:)`, as an app loads its outputs file; the interop suite configures the
plugin with the same translation. The mapping follows where the plugin's `ConfigurationHelper` reads each value in
Gen1 and, for the settings the plugin reads only from Gen2, the Amplify CLI's `Auth.Default` keys:

| Gen2 `auth` key | Gen1 source | Without it in Gen1 |
|---|---|---|
| `aws_region`, `user_pool_id`, `user_pool_client_id` | `CognitoUserPool.Default`: `Region`, `PoolId`, `AppClientId` | required |
| `identity_pool_id` | `CredentialsProvider.CognitoIdentity.Default`, only with both `PoolId` and `Region`, as the plugin requires | no identity pool |
| `unauthenticated_identities_enabled` | none | not stated: the plugin reads no guest flag, and asks for guest credentials whenever it has an identity pool |
| `oauth` | `Auth.Default.OAuth`, only with all of `WebDomain`, `Scopes`, `AppClientId`, `SignInRedirectURI` and `SignOutRedirectURI`, as the plugin requires; a scope that is not a string becomes `""`, as for the plugin; each redirect URI as the one the plugin uses | no hosted UI |
| `oauth.identity_providers` | `Auth.Default.socialProviders` (`AMAZON` and `APPLE` renamed `LOGIN_WITH_AMAZON` and `SIGN_IN_WITH_APPLE`) | `[]` |
| `oauth.response_type` | none | `code`: the plugin's Gen1 hosted UI always uses the code grant |
| `password_policy` | carried from the CLI's `Auth.Default.passwordProtectionSettings` (`passwordPolicyMinLength`, a number or a numeric string, and `passwordPolicyCharacters`) | none, as the plugin's Gen1 path |
| `username_attributes`, `standard_required_attributes`, `user_verification_types` | carried from the CLI's `Auth.Default.usernameAttributes`, `signupAttributes`, `verificationMechanisms`, lower-cased | `[]`, as the plugin's Gen1 path |
| `mfa_configuration` | carried from the CLI's `Auth.Default.mfaConfiguration` (`OFF`, `OPTIONAL`, `ON` become `NONE`, `OPTIONAL`, `REQUIRED`; any other value is refused) | not stated |
| `mfa_methods` | carried from the CLI's `Auth.Default.mfaTypes` | `[]` |
| `data` (the code API) | the first GraphQL API of `api.plugins.awsAPIPlugin`; other API types are skipped | no code API |

The rows "carried from the CLI's" keys are ones the plugin's Gen1 path does not read, and nothing in the client acts
on them either: the client only exposes them on its configuration. The harness reads `mfa_methods` to name a backend
without SMS MFA, and, on the sandbox's file set only ("Sandbox checks", below), without email MFA: the sandbox writes
the list from each pool as provisioned, so a sandbox whose email MFA is pending fails the email-MFA tests naming the
file. Elsewhere it does not read `EMAIL`: the plugin's two email-MFA backends turn email MFA on outside `defineAuth`,
so their outputs list only `SMS` (and `TOTP`), and the plugin's email-MFA suites pass on them.

Gen2 has no key for `PinpointAppId`, so it is not carried. What Gen2 cannot express is refused with the Gen1 file's
name rather than dropped: an `AppClientSecret` on the user pool or on the hosted UI (the plugin sends the latter with
its token exchange), a custom `Endpoint`, an OAuth `AppClientId` other than the user pool's, an identity pool in
another region, and an `authenticationFlowType` other than `USER_SRP_AUTH` or `MigrationEnabled: true`, both of which
change the plugin's default flow (the client's sign-ins default to SRP, as with Gen2 outputs).
`PluginTestConfigurationTests` checks the mapping, the defaults and the refusals offline.

**Codes** (sign-up, reset, attribute verification, MFA, OTP) come from each role's own `data` API, as the plugin's
`AWSAuthBaseTest.subscribeToOTPCreation` and `listMfaInfo` take them: `CodeSink` subscribes to `onCreateMfaInfo`
over AppSync's real-time WebSocket protocol before a user is signed up (every sign-up calls
`CodeSink.prepare(_:)` first: `SandboxSignUp`, the parity checks' raw sign-up, and `ClientSignUpTestCase`'s
sign-ups through the client), waits 2 seconds after the acknowledgement as the plugin does, and also queries
`listMfaInfo`, in the sandbox's `listMfaInfo(username:)` form and the plugin backends' argument-less one, matching
every row to the user by its username, lower-cased. Once a form has answered, only it is asked, whatever fails
later. Until then, a form refused with untyped GraphQL errors only (AppSync's validation and type-mismatch
errors: the schema has no such query or argument) is not asked again; a typed GraphQL error (authorization, a
resolver error, throttling, an internal failure), an HTTP error or a transport error is asked again on the next
poll (`ListMfaInfoForms`, checked offline by `HarnessHelperTests`). The plugin backends answer neither form:
their argument-less `listMfaInfo` resolves a table scan into a list field (`PasswordlessTests/README.md`), so
AppSync answers it with an untyped type mismatch, for the plugin's own query too. There, as for the plugin, codes
come from the subscription alone, and a code sent before it was acknowledged is never seen: a timeout says when
the subscription was acknowledged after the code was asked for. To run that way locally, set
`TEST_RUNNER_COGNITO_CLIENT_INTEG_CODES_FROM=subscription` in `xcodebuild`'s environment (not as an argument): no
query is made, and the log shows each subscription event.

**Users.** Every test signs up its own users (`SandboxSignUp`, `makeFreshUser(on:_:)`, `makeSignInUser()`) and
deletes them, so no test changes a user another run, job or suite could be using. The one exception is CH-1: only an
administrator can put a user in `FORCE_CHANGE_PASSWORD`, so it takes the first of the credentials file's
new-password users still in that state, as the plugin's `testNewPasswordRequired` does, and moves on to the next
when another run (the plugin's suite, or a concurrent job) takes one first; it fails only when none is left. A pool
with no pre-sign-up trigger (the plugin's passwordless backend) has each user confirmed with its sign-up code. A role
known up front to be unable to confirm a fresh user gets no sign-up at all: its file is not the sandbox's (no
sandbox mark), it names no code API, and the plugin's setup for its backend promises no confirming pre-sign-up
trigger (`SandboxPool.promisesConfirmingTrigger`: all but the passwordless and device-alias backends), nor does its
outputs file carry the `confirming_trigger` mark (`IntegrationTestEnvironment.promisesConfirmingTrigger`). That is the
plugin's own device-alias backend; CI overlays the client's `ccit-ci-email-alias` pool in its place, whose file
carries the mark. Every test that signs a user up on such a role fails naming the file before `SignUp` is sent
(`SandboxSignUp.requireNotKnownUnconfirmable(_:)`), so no confirmation email is sent (CI's account has a daily email
limit) and no user is left that could be neither confirmed nor deleted. A role whose backend promises a trigger but leaves a sign-up unconfirmed anyway, with no code
API, fails that test, and every later sign-up on the role in the process fails before signing a user up. The
sandbox's set is unchanged: every file carries the mark. The harness's raw sign-ins (setup, raw checks, cleanup) use
`USER_PASSWORD_AUTH`, or SRP where the app client offers no such flow: the plugin's MFA-required, email-MFA and
device-alias backends, and the hosted-UI clients.

**Sandbox checks.** A few harness self-checks check what only this sandbox provisions and no plugin backend
promises: the default pool's pre-sign-up trigger refusing users who are not test users, a password-reset code on the
default pool, and email-alias codes keyed by the generated username. `plugin-configs.py --dir` marks every Gen2 file
of the full set as the sandbox's (`"custom": {"amplify_cognito_client_integ": {"sandbox": true}}`, which the plugin
and the client ignore); each sandbox check runs where its role's file carries the mark
(`IntegrationTestEnvironment.isSandbox`) and elsewhere skips, saying it is a sandbox check and what it needs. CI's
files and the CI shape carry no mark. A backend that is not the sandbox's can have what a check needs too: the
capabilities file, `AmplifyCognitoClientIntegrationTests-capabilities.json` (`{"capabilities": {"<role>":
["<capability>"]}}`, `IntegrationTestEnvironment.capabilitiesResource`), names it for one of the client's own roles,
and the check then runs on that role (`requireCapability(_:on:)`, `SandboxCapability`): on CI, the refusal check
(`refuses_non_test_users`) and the reset-code check (`reset_password_codes`) on `extended`, and the email-alias code
check (`email_alias_codes`) on `email-alias-codes` ("CI's additive resources", below). A capability is no sandbox
mark: the self sign-up gate and `isSandboxFileSet` read only the mark.

### Which backend a code-reading test runs on

Of the plugin's CI backends, the passwordless one and the two email-MFA ones capture every email and SMS code
and name their code API in their outputs; the others do not. So a test that reads a code runs on one of those
three, the one whose settings fit it (MFA mode and types, username or email sign-in, auto-verify, account
recovery), and keeps its assertions as they are. It stays on the plugin equivalent's backend only when no
code-capturing backend has the setting it asserts on; those are listed below as needing a code API there.

| Test | Reads | Runs on | Its plugin equivalent's backend | Why this one |
|---|---|---|---|---|
| MF-4 `testSignInWithSMSMFA`, MF-6 `testSelectMFATypeWithSMSWhileSigningIn` | an SMS MFA code | passwordless | default | the only code-capturing backend with MFA optional, TOTP and SMS, as the default's |
| MF-10 `testFetchAndUpdateMFAPreferenceForSMSAndTOTP`, MF-12 `testFetchAndUpdateMFAPreferenceForAlreadyPreferredMethod` | an SMS MFA code at teardown (SMS is left preferred, so the cleanup's sign-in is challenged `SMS_MFA`) | passwordless | default | as MF-4 |
| MF-14 `testSMSMFANextStepDuringSignIn` | an SMS MFA code | all-MFA-required, the user with no email | MFA required (TOTP and SMS) | the code-capturing backend with MFA required and TOTP and SMS; without an email, SMS is the user's one MFA type, as on the TOTP-and-SMS backend |
| AT-5 `testSuccessfulSendVerificationCodeWithUpdatedEmail`, AT-6 `testSuccessfulSendVerificationCode` | attribute verification codes | passwordless | default | MFA optional and username sign-in, as the default's; both hold whether or not an update waits for verification |
| MF-18…23, CR-2 (`ChallengeResumeTests`) | email MFA codes | email-MFA-required, all-MFA-required | the same | unchanged |
| PL-6…23, SU-8…15, AS-1…3 | OTP and sign-up codes | passwordless | passwordless | unchanged |
| sandbox checks: sign-up and resent codes, attribute codes, the confirm-then-delete cleanup, the sign-up code check | sign-up and attribute codes | passwordless | (none) | leaves sign-ups to confirm (no pre-sign-up trigger in the plugin's; the sandbox's leaves `ccit-confirm-` users) |
| sandbox checks: SMS MFA code, the raw sign-in's SMS answer | an SMS MFA code | all-MFA-required | (none) | as MF-14 |
| AT-2's second half, `testUpdatedEmailIsVerifiedWithTheCodeSentToIt` (not counted; AT-2 itself, as the plugin's test, reads no code) | an attribute verification code | default | (none: the plugin's test stops at the update) | asserts the email is updated before it is verified: only the default backend's README empties `AttributesRequireVerificationBeforeUpdate` |
| RP-3 `testSuccessfulResetPasswordEndToEnd`, the reset-code check (a sandbox check) | a password-reset code | default (on CI the client's own `extended`) | (none; not counted) | needs account recovery by verified email; the code-capturing backends' READMEs set account recovery to `NONE` |
| the `email-alias` code check (a sandbox check) | a sign-up code, by the generated username | device alias (on CI the client's own `email-alias-codes`) | (none) | only that backend signs in by email |

Only MF-4, MF-6, MF-10, MF-12 (passwordless, not default: no device tracking, account recovery `NONE`, no
pre-sign-up trigger) and MF-14 (all-MFA-required, not TOTP-and-SMS-required: email MFA also on, and the user
has no email) run on a backend with other settings than their plugin equivalents'; none of their assertions
changed.

### What the plugin's CI backends must provide

The file set alone is not enough for every test: some need a backend setting the sandbox has and the plugin's CI
backends may not. Tests that could accept either setting do (user-existence errors, a pool without a pre-sign-up
trigger, an app client without `USER_PASSWORD_AUTH`, a hosted-UI backend of its own, device confirmation requests).
The last column is what the plugin's own backends provide, as the client suites found them on CI before the client's
own CI resources existed:

| Backend (file) | Must provide | Tests that need it | On the plugin's own CI files |
|---|---|---|---|
| default (`AWSCognitoAuthPluginIntegrationTests-*`) | Custom email senders publishing every code to an MfaInfo API, and that API as a `data` block in the outputs | the code-reading tests no code-capturing backend fits (above): AT-2's second half (`testUpdatedEmailIsVerifiedWithTheCodeSentToIt`), RP-3 | **missing**: the Gen1 file names no API; `AuthIntegrationTests/README.md` deploys no senders |
| default | Custom-auth triggers: define `SRP_A → PASSWORD_VERIFIER → CUSTOM_CHALLENGE` and `CUSTOM_CHALLENGE` alone, create publishing `challenge: fixed-answer`, verify accepting the credentials file's `custom_challenge_answer` | CA-1…3, the parity check's custom auth | **missing**: no credentials file, so no answer; the plugin's `AuthCustomSignInTests` skipped all three |
| default | `new_password_required_usernames` and `new_password_required_temporary_password` in the credentials file, users reset to `FORCE_CHANGE_PASSWORD` often enough for every concurrent run | CH-1, P-3 | **missing**: no credentials file; the plugin's `testNewPasswordRequired` skipped |
| default | The credentials file itself, `AWSCognitoAuthPluginIntegrationTests-credentials.json`, with the three keys above | the fixture check (`CognitoBackendSmokeTests.testProvisionedUsersAreAvailable`) | **missing**: CI downloads no `-credentials.json` |
| default | A pre-sign-up trigger that auto-verifies email (not only auto-confirms) | RP-3 (a verified email) | **missing**: `ForgotPassword` answered "no registered/verified email or phone_number"; the README's handler only sets `autoConfirmUser` |
| device alias (`AWSCognitoAuthPluginDeviceAliasTests-*`) | A way to confirm a fresh sign-up: a pre-sign-up trigger that confirms it, or custom senders and a `data` block to confirm it with its sign-up code; and 5-minute access and id tokens | DV-10…19, the parity check of the pool, and that pool in the every-pool cleanup check | **missing**: a fresh sign-up came back unconfirmed and the file names no `data` block. No user is signed up there at all (the file is not the sandbox's, names no code API, and promises no confirming trigger): each sign-up there had sent a confirmation email, and repeated runs reached the account's daily email limit (`LimitExceededException`). The plugin's `DeviceAliasTokenRefreshIntegrationTests` read no code (they sign in a user pre-created for them, from `AWSCognitoAuthPluginDeviceAliasTests-credentials.json`, which CI does not download) and run on no CI workflow (only the `AuthGen2IntegrationTests` target has them) |
| default | `ALLOW_USER_PASSWORD_AUTH` and `ALLOW_CUSTOM_AUTH` on the app client; token revocation on; refresh-token rotation off; device tracking always remembered; attribute updates without verification; MFA optional with TOTP and SMS; an identity pool with guest access | SI-2; SO-1, SO-2; MS-6; DV-1…9, CA-2; AT-2; MF-*; CR-*, GU-*, SE-*, ST-* | provided: all passed |
| passwordless | Every code captured and a `data` block; SMS codes to phone numbers set at sign-up | PL-*, SU-8…15, AS-*, MF-4, MF-6, MF-10, MF-12, AT-5, AT-6 | provided: all passed (the backend confirms no sign-up, so each user is confirmed with its sign-up code) |
| both email-MFA backends | Email MFA on, every code captured and a `data` block | MF-18…23, CR-2 | provided: the plugin's `EmailMFARequiredTests` and `EmailMFAWithAllMFATypesRequiredTests` passed; the outputs list no `EMAIL` in `mfa_methods`, which the harness no longer reads |
| passwordless or WebAuthn | An identity pool that federates the backend's user pool, with guest access, named in its outputs: CS-2 and CS-3 refresh a session carried to a new pool namespace, which leaves its device record behind, so they need a pool that tracks no devices (the default backend tracks them) | CS-2, CS-3 | provided: both passed |
| any backend but the one CS-2 and CS-3 run on | A second identity pool that allows guests (another backend's), or `second_identity_pool_id` in the default credentials file | CS-3 | provided: another Gen2 backend's identity pool; CS-3 passed |
| hosted UI | An app client the cleanup can sign a user in with: SRP (the raw sign-in's fallback) or `USER_PASSWORD_AUTH` | HU-1, HU-2 cleanup | provided: both passed |

The MFA-required, both email-MFA and the device-alias backends' app clients have no `USER_PASSWORD_AUTH`; the
harness's raw sign-ins fall back to SRP there, so no test needs it on them.

**How CI provides them.** CI does not skip these tests. The client's jobs overlay the client's own CI resources
("CI's additive resources", below), which provide every **missing** row beside the plugin's backends, changing none
of them: the `extended` role gives the default backend's rows (custom auth and its answer, the new-password users, the
credentials file, a code API and a verified email at sign-up), and `ccit-ci-email-alias` replaces the device-alias
file with a pool whose pre-sign-up trigger confirms every test sign-up and whose outputs carry the
`confirming_trigger` mark, which the harness reads, so nothing in the code names the role. The jobs set no skip
variable and allow no skip ("Run as CI does (recommended)", above). On the plugin's own files alone, the tests these
rows name fail, each naming its resource, or skip with `TEST_RUNNER_COGNITO_CLIENT_INTEG_CI_SKIPS=1` ("Skips on the
plugin's own files", below).

**On the sandbox's set** all of these hold. P-13 federates the passwordless pool's app clients too, and
`passwordless-amplify_outputs.json` names it (`parity.py`, `name_plugin_identity_pool_in_outputs`), as the
plugin's Gen2 passwordless backend names its own identity pool; the plugin's passwordless suites sign in through it.

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
(cd AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/LocalServer && npm install && npm start) > /tmp/ccit-localserver.log 2>&1 &
SERVER=$!
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/CognitoClientHostApp
# $DIR: CI's file set, overlaid ("Run as CI does (recommended)"). The copy happens at build time.
DD=/tmp/ccit-webauthn-dd
env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild build-for-testing -project CognitoClientHostApp.xcodeproj \
  -scheme CognitoClientWebAuthnUITests -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD"
xcodebuild test-without-building -project CognitoClientHostApp.xcodeproj \
  -scheme CognitoClientWebAuthnUITests -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath "$DD" -collect-test-diagnostics never \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 600
kill "$SERVER"
rm -rf "$DD"
```

On the sandbox's file set, run the test step through `../infra/self-sign-up.sh on -- …` instead ("Optional: the
sandbox").

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
signs in with `signInWithWebUI(presentationAnchor:)` on the plugin's hosted-UI backend
(`AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs.json`, copied into the app at build time, or on CI
its Gen1 file, which the app translates to Gen2; on the sandbox, the `default` pool's `hostedui-plugin` client,
P-7), registers the plugin's `myapp` URL scheme its
redirect URIs use (and its own `cognitoclienthostapp`), and signs out with `signOut(presentationAnchor:)`, purging
the session. The app's client is on `.default`, whose saved login is the plugin's own record, `amplify.<ns>.session`
, in the app's own keychain group. The app's result line after a sign-out: "User is signed out" for
`.complete`; the same, with what failed after it, for `.partial` (signed out on this device); "Sign Out failed:
<error>" for `.failed`, which keeps the app signed in: a closed sign-out page, or one that could not be shown or
completed. A test's own sign-out expects `.complete`; `setUp`'s sign-out of a leftover session accepts
`.partial`, since that session's user may already be gone.

| Test | Plugin test | What differs |
|---|---|---|
| HU-1 `HostedUISignInTests/testSignInSuccess` | `testSignInSuccess` | the app passes its view's window |
| HU-2 `HostedUISignInTests/testSignInWithoutPresentationAnchorSuccess` | `testSignInWithoutPresentationAnchorSuccess` | the app looks the window up itself (the foreground scene's key window), where the plugin's anchor-less call does it internally; the client's anchor is not optional |

Each test signs a fresh user up on the hosted-UI backend through the API (`SandboxSignUp`, in the test process;
the UI-test target compiles the seven sandbox helpers from `CognitoClientIntegrationTests/`, and its build phase
copies the same files), pastes its name and password into the hosted UI's form, checks that the session is
signed in and that `getCurrentUser` names the user, then signs out, checking no browser is shown. A teardown block
signs a session still signed in out, then the user deletes itself (`SandboxUserCleanup`, through the client's SRP
sign-in: the hosted-UI app client has no password flow). Both
sign in privately (ephemeral, the client's default; the plugin's app asks `.preferPrivateSession()`), so no
cookie can skip the form and no logout page is shown; the logout of a shared-cookie sign-in is pinned by the
live-engine unit tests.

**One browser per simulator.** On iOS 26 a simulator presents only its first `ASWebAuthenticationSession`, so
run each test in its own `xcodebuild` invocation on a new simulator, as the plugin's CI does:

```bash
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests
# $DIR: CI's file set, downloaded and overlaid as in "Run as CI does (recommended)".
cd CognitoClientHostApp
DD=/tmp/cognito-client-ui-dd
COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild build-for-testing -project CognitoClientHostApp.xcodeproj -scheme CognitoClientUITests \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath $DD > /tmp/hu-build.log 2>&1
# As CI: no hardware keyboard. No pasteboard sync with the Mac while the tests paste. Saved, restored below
# (`defaults read` prints a boolean as 1 or 0, which `defaults write -bool` refuses, hence the mapping).
KB=$(defaults read com.apple.iphonesimulator ConnectHardwareKeyboard 2>/dev/null)
PB=$(defaults read com.apple.iphonesimulator PasteboardAutomaticSync 2>/dev/null)
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
defaults write com.apple.iphonesimulator PasteboardAutomaticSync -bool false
for test in testSignInSuccess testSignInWithoutPresentationAnchorSuccess; do
  UDID=$(xcrun simctl create hu com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-5)
  # On the sandbox's file set, put `AWS_PROFILE=<sandbox-profile> ../infra/self-sign-up.sh on --` before `env`.
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
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/CognitoClientHostApp
# COGNITO_CLIENT_INTEG_DIR: CI's file set, overlaid ("Run as CI does (recommended)"); unset, the plugin's own
# directory. On the sandbox's file set, each run goes through ../infra/self-sign-up.sh instead, with
# COGNITO_CLIENT_INTEG_DIR after `--` ("Optional: the sandbox").

# The client suite. It links no Amplify.
env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project CognitoClientHostApp.xcodeproj \
  -scheme CognitoClientIntegrationTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO

# The plugin-interop suite, in its own process: it links Amplify and AWSCognitoAuthPlugin as well.
env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project CognitoClientHostApp.xcodeproj \
  -scheme CognitoClientPluginInteropTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO
```

`xcodebuild test` builds and tests in one step, so the variable goes on it.

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

**Configuration.** The test target's *Copy test configuration* build phase copies the plugin's file set
("Test configuration", above) from `$COGNITO_CLIENT_INTEG_DIR` (default
`~/.aws-amplify/amplify-ios/testconfiguration`) into the built test bundle, which only exists in DerivedData. This
is the same build-time copy `AuthHostApp` does, from the same directory and variable. If a file is
missing, the build still succeeds with a warning naming it. The keychain probes still run, and every test that
needs the file fails with a message naming it.

**How the client gets into the test targets.** Through the `AmplifyCognitoClient` package product of the local
package (the repository root). Its public API is `@_spi(AmplifyExperimental)`, and the tests reach its
`internal` symbols (the registry, `SessionRecordKey`) with `@_spi(AmplifyExperimental) @testable import
AmplifyCognitoClient`, which works because Xcode builds the package in Debug with testability on. New
dependencies of the client come through the product, so nothing here changes when the client gains one.

| Target | Links | Why |
|---|---|---|
| `CognitoClientIntegrationTests` | `AmplifyCognitoClient`, `AmplifyFoundation`, `AmplifyFoundationBridge`; `AWSCognitoIdentity`, `AWSCognitoIdentityProvider`, `AWSSTS` from `aws-sdk-swift` (pinned to the same exact version as `Package.swift`) | The client suite. Some tests call the SDK directly. No `Amplify` or `AWSCognitoAuthPlugin`, so the target is a standing proof that the client needs neither |
| `CognitoClientPluginInteropTests` | `Amplify`, `AWSCognitoAuthPlugin`, `AmplifyCognitoClient` | Tests that need the plugin itself: the saved login `.default` shares with it, and its keychain transitions. Its own scheme, so `Amplify` is configured in its own process |
| `CognitoClientHostedUIApp` (app) / `CognitoClientUITests` (UI tests) | the app: `AmplifyCognitoClient`; the UI tests: `AmplifyCognitoClient`, `AWSCognitoIdentityProvider` | HU-1 and HU-2 (above). The app's bundle identifier `com.aws.amplify.cognitoclient.CognitoClientHostedUIApp` and its keychain group are its own, so it shares no keychain with the other host apps |

Every scheme (the two above, `CognitoClientWebAuthnUITests` and `CognitoClientUITests`) sets
`LIBDISPATCH_COOPERATIVE_POOL_STRICT=1` for the test action, as the client's unit-test scheme
does, so keychain I/O cannot pin the one cooperative thread.

**Shared helpers** (`CognitoClientIntegrationTests/`):

| Helper | What it gives a test |
|---|---|
| `IntegrationTestEnvironment` | The plugin's file set: the main configuration (`configuration()`, the default backend's), a role's configuration by name (`configuration(_: SandboxPool)`, e.g. `.standard`, `.passwordless`, `.emailAlias`, each read from its plugin file, or its Gen1 file translated), a role's outputs as the client reads them (`hasOutputs(_:)`, `outputsBundle(_:)`, `outputsData(_:)`), the raw `auth` section of a role's outputs (`outputsAuthSection(_:)`, for `oauth`), the derived identity-only role (`identityOnlyAuthSection()`) and second identity pool (`secondIdentityPool()`), a role's code API (`codeSinkAPI(_:)`, its `data` block), the default credentials file (`credentials()`, empty when absent: `requireCustomChallengeAnswer()`, `requireNewPasswordUsers()`), `uniqueSessionID(_:)` (`<tag>-<8 hex>`), `defaultAccessGroup()`, `sharedAccessGroup()` and `secondSharedAccessGroup()`, `rawKeychainAccounts(service:accessGroup:)`, `jwtClaims(_:)`, and `isSandbox(_:)` / `requireSandbox(_:_:)` for the sandbox checks ("Sandbox checks", above) |
| `PluginTestConfiguration` | A plugin outputs resource as the client reads it: the Gen2 file, or the Gen2 translation of the plugin's Gen1 file for the same backend (`Gen1TestConfiguration`, "Gen1 files" above), in a bundle of its own. Foundation only; also compiled into the interop suite, the UI tests and the hosted-UI app |
| `CodeSink` | `code(for:on:since:timeout:)`: the newest code the custom senders published for a user of a role, from that role's `data` API: an `onCreateMfaInfo` subscription (`CodeSink.prepare(_:)`, which every sign-up calls first; one silent past AppSync's keep-alive timeout is replaced) and both `listMfaInfo` forms, each row matched to the user here, polled once a second (60 s by default, as the plugin's `otp(for:)`). For a `FreshUser`: `code(for:_:since:)` with a `Kind` (`.signUp`, `.resetPassword`, `.attributeVerification`, `.mfa`, `.otp`) or the typed `signUpCode`, `resetPasswordCode`, `attributeVerificationCode`, `mfaCode`, `otpCode`; and `code(for:_:sentBy:)` / `snapshot(for:)` + `code(for:_:after:)`, which return only a code sent after the snapshot (use them for a resend or any second code, and for any code after a sign-up a pool may have confirmed with a sign-up code); the same by a username and a role (`snapshot(for:on:)`, `code(for:on:after:)`, `code(for:on:sentBy:)`) for a user a check signed up by hand |
| `SandboxPools` | `SandboxPools.pool(_:)`: a role's `configuration` for the client under test and a raw SDK `client` on its public app client (no AWS credentials): `passwordSignIn` (`USER_PASSWORD_AUTH`, or SRP, `srpSignIn`, where the app client offers no password flow; a `RawSignInStep`), `userAuthSignIn`, `respond(to:_:session:)`, `signIn(_:sink:)` (to tokens, answering TOTP, email/SMS MFA and OTP, MFA selection and MFA setup), `enrollTOTP(_:accessToken:)`, `requireLive(_:)` (fails when the role's outputs show no `SMS` MFA, or, on the sandbox's set, no `EMAIL` MFA; elsewhere email MFA is taken as live, "Gen1 files") |
| `SandboxSignUp` | `signUp(on:_:)`: a fresh `ccit-` user (`@example.com`, optional fictional `+1555` number, optional passwordless), confirmed (by the pool's pre-sign-up trigger, or else with its sign-up code; without a code API it fails naming the file, `requireCodeAPIToConfirm(_:)`, and every later sign-up on that role in the process fails before signing a user up; on a role known up front to be unable to confirm one, `cannotConfirmUpFront(_:)`, every sign-up fails before `SignUp` is sent, `requireNotKnownUnconfirmable(_:)`) or, with `needsConfirmation`, `ccit-confirm-` and unconfirmed; `confirm(_:sentSince:on:sink:)`; the identity helpers. Returns a `FreshUser`, which redacts its password, TOTP secret and sub, records later changes (`recordPassword`, `recordTOTPSecret`, `recordDeleted`) and knows the sink's key (`sinkUsername`, the generated username on `email-alias`) |
| `SandboxUserCleanup` | `delete(_:)`: the user deletes itself through its own raw sign-in (no admin call; SRP where the app client offers no password flow), confirming it first if needed (failing, naming the file, where no code API can), signing in again when a global sign-out revoked the new token, or, on an app client with neither flow, through another role's app client on the same pool, else the client's SRP sign-in and `deleteUser()`, else (a UI-test runner has no keychain for the client) leaves it, `.left`; `XCTestCase.deleteAtTeardown(_:)` and `signUpFreshUser(on:_:)` |
| `ClientIntegrationTestCase` | The base class for suites that create sessions. Mint IDs with `makeSessionID(_:pool:)` or clients with `makeClient(_:pool:)`; `tearDown` signs each one out against its own pool with `signOutStoredSession` (a `.failed` result, the session still signed in, fails the teardown; a `.partial` one does not), purges it, and waits until the registry has released it, then deletes the users from `makeFreshUser(on:_:)` and `makeSignInUser()` (a fresh default-backend user as a `TestUser`: the suites' `alice` and `bob`) |
| `ClientSignUpTestCase` | The base of `SignUpTests` and `AutoSignInTests`: `signUp(on:pool:needsConfirmation:withPassword:)` signs a fresh `ccit-` user up through the client under test and records it (after `SandboxSignUp.requireNotKnownUnconfirmable(_:)` and `CodeSink.prepare(_:)`), `signUpAndConfirm(on:pool:)` also confirms it with the sink's code, and `tearDown` deletes every recorded user after the sessions are signed out; `assertValidation`, `assertService` and `assertReadyForAutoSignIn` |
| `ClientMFATestCase` | The base of `TOTPSetupTests`, `MFASignInTests`, `MFAPreferenceTests` and `ChallengeResumeTests`: `signedInFreshUser(_:withPhoneNumber:)`, a fresh `default` user signed in through a new client, and `enrollTOTP(_:_:friendlyDeviceName:)`, TOTP enrolled through the client's own `setUpTOTP` / `verifyTOTPSetup` (the secret is recorded first, so cleanup can answer TOTP). Failure messages name step and error cases only |
| `DeviceTestCase` (`DeviceTests/DeviceTestSupport.swift`) | The base of the three device suites: after the base class's teardown it removes each fresh user's device and advanced-security records from this device's keychain, which the client keeps per user and never removes itself. With it, `signInToDone`, `thisDeviceKey` (the access token's `device_key`), `forceRefresh`, `assertForgetsThisDevice` and `assertOnlyThisDevice`, which compare device keys as booleans |
| `TOTP` | `code(secret:at:)`, RFC 6238, and `freshCode(secret:)`, which waits for the next 30-second step when the current one is spent (Cognito rejects a reused code) |
| `RecordingHTTPClient` | Records each user pool request's `X-Amz-Target`, final `User-Agent`, and body `AuthFlow`, `ChallengeName` and `ClientMetadata`. Install it with `Options(configureUserPoolClient: recorder.configureUserPoolClient)`. It sits inside the SDK's retry loop, so `requests` and `operations` hold every attempt; an exact list or count reads `answered` or `answeredOperations`, which leave out the attempts the SDK sent again, and `operations` stays for the `== []` checks |
| `ConcurrentCalls` | Calls started at once in unstructured tasks, as the plugin's stress and race tests start theirs, awaited with `fulfillment(of:timeout:)` and the plugin's limit (`results(of:timeout:)`, `concurrently(_:timeout:_:)`) |

`TestUser`, `TOTPSecret` and `SandboxSecret` keep secrets out of every textual representation, so a failure message cannot
print one.

**Keychain groups.** `CognitoClientHostApp.entitlements` grants three access groups,
`$(AppIdentifierPrefix)com.aws.amplify.cognitoclient.CognitoClientHostApp` (the default), `…Shared` and
`…Shared2` (P-11, for CS-6).
Simulator builds are signed ad hoc with these entitlements, so no team or provisioning profile is needed.

| Suite | What it covers |
|---|---|
| `AuthClientConfigurationIntegrationTests` | The default backend's outputs file loads, and its pools and namespace match the ids the file names, read as raw JSON; for that namespace, `.default`'s session record is the plugin's key, its sidecar and challenge record are `amplify.1.<ns>.$default.meta` and `.challenge` (the sidecar never parses as a session record), and a named session's v1 key round-trips |
| `DataProtectionKeychainProbeTests` | Raw `SecItem` behaviour that the keychain module depends on, including enumeration, access groups, and write statuses, over the plugin's service's full sibling set: the plugin's records (one of them `.default`'s), named sessions' records, `.default`'s sidecar and challenge record, and a development leftover `$default.session` |
| `CognitoBackendSmokeTests` | Guest `GetId` + `GetCredentialsForIdentity` against the default backend's identity pool, and the fixtures the suites cannot make: every role's outputs file and code API, and the credentials file's custom-auth answer and new-password users |
| `SandboxParityProvisioningTests` | Each role's backend, through the SDK or HTTPS directly: every outputs file loads (seven distinct pools; the hosted-UI client on the default pool or on one of its own); `default` auto-confirms and tracks devices; custom auth completes with the stored answer; a `ccit-confirm-` sign-up code reaches the code sink and confirms; email MFA and SMS MFA codes (`mfa-req-email`, `mfa-req-totp-sms`) and `EMAIL_OTP` and `SMS_OTP` codes (`passwordless`) reach the sink and complete sign-in; `passwordless` offers choice-based sign-in; the MFA-required pools challenge a fresh user; `email-alias` signs in by email with 5-minute tokens; the hosted-UI login page answers; the identity-only role vends guest credentials; the third keychain group works. On the plugin's CI backends they check what those backends promise (SRP sign-ins, users confirmed with their code, the first code sent after a request); what only the sandbox provisions is a sandbox check ("Sandbox checks", above), which skips elsewhere |
| `SandboxProvisioningTests` | The users the suites need are in the state they need, checked through the SDK directly: a fresh user with no MFA preference is not challenged; a fresh user who enrolled TOTP through the client is challenged for TOTP and a fresh code completes it; the first of the new-password users still in `FORCE_CHANGE_PASSWORD` must set a new password (or, once `ChallengeTests` has set one in this run, that user's new password signs in: only an administrator call can reset one, so CH-1 cannot use a fresh user); a fresh user signs in with its password |
| `HarnessHelperTests` | The shared helpers, including the recorder installed through the real client's escape hatch, and, offline, which `listMfaInfo` forms the code reader retires (`ListMfaInfoForms`) |
| `PluginTestConfigurationTests` | The Gen1 translation, offline, over made-up documents: every mapped key reaches the client's configuration, absent keys get the plugin's Gen1 values, values the plugin tolerates are read as it reads them (an identity pool without a region, a non-string scope, an incomplete hosted UI, each MFA mode, a string minimum length, a REST API), what Gen2 cannot carry is refused with the file's name, and the Gen2 file wins over the Gen1 one |
| `SandboxHelperTests` | The multi-pool helpers against every role's backend: every pool confirms a fresh user and cleanup deletes it (answering each pool's MFA); sign-up, resent, reset-password, attribute-verification, MFA and OTP codes reach the sink; `email-alias` codes are found by the generated username; TOTP-enrolled and unconfirmed users are cleaned up; sessions on several pools are cleaned up with their own pool. On the plugin's CI backends they check what those backends promise (SRP sign-ins, users confirmed with their code, the first code sent after a request); what only the sandbox provisions is a sandbox check ("Sandbox checks", above), which skips elsewhere |
| `WebAuthnCredentialsIntegrationTests` | WebAuthn credential listing and deletion, headless, on the WebAuthn pool (U-WA): a fresh user with no passkey lists an empty page (default size and size 1); deleting a credential Cognito never issued is `.service(.resourceNotFound)` and leaves the session signed in; page sizes 0 and 21 are refused with `.validation(field: "pageSize")` and send nothing; a signed-out session is `.notSignedIn` with no request. Requests are checked with `RecordingHTTPClient`. No passkey is registered, so no simulator sheet is needed |
| `PasswordlessSignInTests` | PL-1 … PL-23, the plugin's `PasswordlessSignInTests` with its method names: choice-based sign-in (`USER_AUTH`) on `passwordless` (U-PL: `PASSWORD`, `PASSWORD_SRP`, `EMAIL_OTP`, `SMS_OTP`). Each preferred first factor signs in (PL-1, PL-2, PL-6, PL-7) or reaches its one-time-code step with the code in the sink (PL-12, PL-13); with no preference, the first-factor selection and each choice (PL-3, PL-5, PL-8 … PL-10); wrong passwords (PL-4, PL-14 … PL-17; in `USER_AUTH` a wrong password ends the attempt); right and wrong email and SMS codes, a wrong code keeping the step pending (PL-18 … PL-23). PL-11, `testSignInWithUnsupportedPreference_givenValidUser_expectSelectChallenge`: `userAuth(preferredFirstFactor: .webAuthn)` through the anchored overload gets `.continueSignInWithFirstFactorSelection` without `.webAuthn` after one `InitiateAuth` `USER_AUTH` and no challenge answer, since U-PL offers no `WEB_AUTHN`; no sheet is shown, so no simulator server is needed. Each test signs up its own user with a password, an `@example.com` email and a fictional `+1555` number; codes come from the sink. Requests are checked with `RecordingHTTPClient.answered` |
| `MultiSessionFlowTests` | The multi-session flows over the live engine with `alice` and `bob`, two fresh users per test: MS-1 two users signed in at once, MS-3 a sign-out (`.complete`) keeps the stored row, MS-4 `storedSessions` lists every session, `.default` from the plugin's record, MS-5 a credentials provider per session; MS-2 (signing one session out leaves the other signed in, and the event goes to the signed-out session only) is in `MultiSessionFlowTests+SignOut`, and MS-6 (the same user in two independent sessions) in `MultiSessionFlowTests+SameUser` |
| `KeychainModuleRealKeychainTests` | Parity KM-1 … KM-11: the plugin's `ScopedWipeRealKeychainTests` (Q1–Q3, Q5, Q6), with their names, over `InternalAmplifyKeychain` reached through the client's product. Services unique to each test |
| `ChallengeTests` | CH-1 … CH-6: the new-password challenge of the first of the credentials file's new-password users still in `FORCE_CHANGE_PASSWORD` (moving on when another run takes one), a fresh TOTP user's challenge, a pending challenge is per session, a new sign-in supersedes it, a wrong code keeps it, an expired challenge session is `challengeExpired` (waits out the 3-minute validity, so about 3 minutes) |
| `DeleteUserTests` | DU-1: a fresh user (`SandboxSignUp`, on the default pool) is deleted, the row goes, and `.userDeleted` arrives once; DU-2 (`DeleteUserTests+SignedOut`): deleting the user of a signed-out session is `.notSignedIn` and sends nothing |
| `RefreshTests` | RF-2 (concurrent forced refreshes make one network refresh per session), RF-3 (a global sign-out expires the same user's other session; it stays signed in and sends `.sessionExpired` once). RF-3's user is a fresh one on the default backend, through its identity pool, so its global sign-out reaches no other run |
| `CredentialsProviderTests` | CR-2 (the token provider's access token), CR-4 (a signed-out session never falls back to guest), CR-5 (a guest signs in in place, and its credentials move from the unauthenticated role to the authenticated one) |
| `PersistenceTests` | PS-2 (unreadable storage is `.unavailable(.denied)`, never signed out, and sends nothing), PS-3 (a shared-group session is listed and restored only through its group) |
| `SignOutTests` | SO-1 (`signOut()` revokes the refresh token at Cognito), SO-2 (`signOutStoredSession` revokes with no live client and keeps the row), each `.complete` and signed out locally (a sign-out never throws), SO-3 (`purgeStoredSession` is local only), each checked against Cognito with a plain SDK client; SO-4 (`SignOutTests+SignedOut`: signing out a signed-out session is `.complete`, with no request, event or row) |
| `UserAgentTests` | UA-1: every user pool request carries `lib/amplify-swift#<version>` and `md/amplify-cognito#<version>`, once each |
| `SignInFlowTests` (`SignInFlowTests.swift`, `SignInFlowTests+Refusals.swift`) | The single-session cases, with `alice` and `bob`, fresh users per test: SI-1 (alice's SRP sign-in: `.done`, `.signedIn` once, a v1 session record and no plugin record, `USER_SRP_AUTH` then `PASSWORD_VERIFIER` with the Amplify user agent), RF-1 (`testForcedRefreshCommitsNewTokens`: a forced refresh commits new tokens with one `GetTokensFromRefreshToken` and no event, and a new handle reads them back), CR-1 (the provider's credentials sign an STS `GetCallerIdentity` as the authenticated role), CR-3 (guest credentials, signing as the unauthenticated role), PS-1 (a signed-in session restores across a client re-creation with no request, over the same outputs and over outputs with unrelated sections added). In `+Refusals`: SI-2 (bob with `USER_PASSWORD_AUTH`, one request, and the device confirmation on a device-tracking pool), SI-3 (a wrong password is `.notAuthorized` and writes nothing), SI-4 (a second sign-in is refused on the signed-in session only, while another session signs bob in) |
| `SignInFlowTests` (parity, `SignInFlowTests+Parity.swift`) | SV-1/SV-2 (an empty username is `.validation(field: "username")` with no request, twice), SI-5 (client metadata on `InitiateAuth` and `RespondToAuthChallenge`, seen by the recorder), SI-6 (an unknown user is `.notAuthorized`, or `userNotFound` where existence errors are on), SI-7 (a sign-in and a concurrent fetch both succeed, and the fetch is coherent) |
| `SessionTests` | SE-1 (a signed-in fetch has tokens, sub, identity and credentials), SE-2 (a record deleted from the keychain out of band reads `.signedOut`), SE-3 (repeated fetches make no request), SE-4 (100 concurrent fetches across a sign-out, then 50 more, all coherent) |
| `GuestTests` | GU-1 (a guest signed out gets a new identity), GU-2 (repeated guest fetches keep one identity and one set of credentials), GU-3 (a guest has no user pool tokens) |
| `SigningTests` | SG-1: a guest's `credentialsProvider`, through `FoundationToSDKCredentialsAdapter` and the SDK's `AWSSigV4Signer`, signs the plugin's AppSync request with `Authorization`, `X-Amz-Security-Token` and `X-Amz-Date` (not sent), and an STS `GetCallerIdentity` signed the same way, which is sent and accepted |
| `StorageConfigurationTests` | CS-1 … CS-3 (the identity-only role, and CS-3's second identity pool; a pool added or changed is a new namespace, and the client carries a session forward as the plugin does, from the namespace its marker records: a guest from identity-pool-only as it is, a user-pool session with its identity fetched on first use, a changed identity pool beside the same user pool with the tokens only (read back from the carried record); an identity-pool-only change carries nothing; the old record is kept, as the plugin keeps it. Built programmatically, since Gen2 outputs need a user pool), CS-4 … CS-6 (a session in one access group is not visible from another, including the third group, P-11). These are named sessions' rows; `.default` follows the plugin's rule, in `StorageConfigurationTests+DefaultSession.swift`: CS-D1 an identity pool added carries the record's bytes and keeps the old one, CS-D2 a user pool change deletes the record and its sidecar and does not revoke it (another user pool), CS-D3 a changed identity pool carries the old identity ID, which keeps getting the old pool's credentials while that pool exists, and the static-call case: a static `signOutStoredSession` or `purgeStoredSession` with another configuration leaves the app's login and `authConfiguration` alone. They own `.default`'s items and `authConfiguration`, removed before and after each |
| `StressTests` | ST-2 … ST-5: 50 concurrent fetches after a sign-in (no refresh), with one forced refresh (one `GetTokensFromRefreshToken`), as a guest (one identity), and 50 concurrent `getCurrentUser()` (no request) |
| `CustomAuthTests` | CA-1 … CA-3, the plugin's `AuthCustomSignInTests`, on `default`, whose custom-auth triggers (P-5b) add a custom challenge and accept the credentials file's `custom_challenge_answer`, as the plugin's test reads it (a secret, never printed or recorded): CA-1 `customWithSRP` answers `PASSWORD_VERIFIER`, then the custom challenge, whose public parameters are checked; CA-2 signs out and signs in again on the same session with `userSRP`, which asks no custom challenge and answers the remembered device's `DEVICE_SRP_AUTH`; CA-3 `customWithoutSRP`, the custom challenge alone after one `InitiateAuth`. Each test signs up its own user; requests are checked with `RecordingHTTPClient` |
| `SignUpTests` (`ClientSignUpTestCase`) | SU-1 … SU-15, the plugin's `AuthSignUpTests`, `AuthConfirmSignUpTests`, `AuthResendSignUpCodeTests`, `PasswordlessSignUpTests` and `PasswordlessConfirmSignUpTests`, with their names. On `default` (SU-1 … SU-7): a sign-up auto-confirms and returns the user's `sub`; two concurrent sign-ups; an empty username or code is `.validation` with no request; an existing username is `usernameExists`; confirming an unknown user is `codeMismatch` or `codeExpired` where the app client prevents existence errors, `userNotFound` where it does not; resending to an unknown user answers a simulated email delivery, or `userNotFound` or `limitExceeded`, as the plugin accepts. On `passwordless` (SU-8 … SU-15): a sign-up without a password waits in `.confirmUser`; the concurrent, validation and `usernameExists` cases; SU-15 confirms with the sink's code and reaches `.completeAutoSignIn`. Every user is a fresh `ccit-` (or `ccit-confirm-`) user, deleted at teardown |
| `AutoSignInTests` (`ClientSignUpTestCase`) | AS-1 … AS-3, the plugin's `PasswordlessAutoSignInTests`, on `passwordless`: `autoSignIn()` with no sign-up is `invalidState` and sends nothing; a sign-up confirmed with the sink's code, then `autoSignIn()`, signs the session in and its stream delivers `.signedIn`, and only the signing-up session is signed in and stored; a second `autoSignIn()` after a global sign-out reaches Cognito and is `notAuthorized`. Fresh `ccit-confirm-` users |
| `PasswordResetTests` | RP-1, RP-2, the plugin's `AuthResetPasswordTests` and `AuthConfirmResetPasswordTests`, on `default`: resetting an unknown user gets Cognito's simulated `.confirmResetPasswordWithCode` (or, with existence errors on, `userNotFound` or `limitExceeded`), and confirming a reset for one fails with a service error the plugin accepts; plus RP-3 (not counted), a whole reset of a fresh user with the sink's code, then a sign-in with the new password |
| `UserAttributesTests` | AT-1 … AT-7, the plugin's `AuthUserAttributesTests`, with their names, on `default` (no verification needed before an update; AT-5 and AT-6 on `passwordless`, whose outputs name a code API): fetch; update the email (a code to the new address; as the plugin's test, no code is read; `testUpdatedEmailIsVerifiedWithTheCodeSentToIt`, not counted, then verifies it with the code, which needs a code API on `default`); update two attributes; a wrong confirmation code is `codeMismatch`; resend and confirm a verification code; send one for the signed-up email; change the password and sign in with the new one. A fresh user signed in through the client each; checks on usernames, emails and codes are booleans |
| `UserAttributesStressTests` | ST-1, the plugin's `AuthStressTests.testMultipleFetchUserAttributes`: 50 concurrent `fetchUserAttributes()` for a fresh `default` user all finish within the plugin's 30 seconds and return the signed-up email |
| `TOTPSetupTests` (`ClientMFATestCase`) | MF-1, MF-2, on `default`: `setUpTOTP()` then `verifyTOTPSetup(code:)` while signed in, the details naming the user and giving an `otpauth` URI; a wrong code first is `.service(.softwareTokenMFANotEnabled)`, then the right one succeeds with a device name |
| `MFASignInTests` (`ClientMFATestCase`) | MF-3 … MF-6, the plugin's `MFASignInTests`, on `default` (MF-4 and MF-6, which read SMS codes, on `passwordless`): the user sets MFA up through the client, signs out, and signs in with TOTP, with SMS (confirmed with the code the custom SMS sender captured, where the plugin stops at the step), and choosing TOTP or SMS when both are enabled (`[.sms, .totp]` offered). SMS users get a fictional `+1555` number |
| `MFAPreferenceTests` (`ClientMFATestCase`) | MF-7 … MF-12, the plugin's `MFAPreferenceTests`, with their names and steps, on `default` (MF-10 and MF-12, whose cleanup reads an SMS code, on `passwordless`): a new user has no preference; TOTP and SMS each enabled, preferred, not preferred and disabled; both together; two preferred types are `.service(.invalidParameter)`; `.enabled` keeps the preferred type preferred |
| `RequiredMFATests` (`RequiredMFATests.swift`, `RequiredMFATests+Email.swift`) | MF-13 … MF-23, through `signIn` and `confirmSignIn` only, with the plugin's method names. On `mfa-req-totp-sms` (U-REQ-TS), the plugin's `TOTPSetupWhenUnauthenticatedTests` (MF-13 … MF-17): a user without a phone number must set up TOTP; one with a number (MF-14, on `mfa-req-all` with no email, which reads the SMS code there) gets an SMS code, confirmed from the sink; TOTP set up during sign-in, also after a wrong (`softwareTokenMFANotEnabled`) or non-numeric (`invalidParameter`) code, which keeps the setup. On `mfa-req-email` (U-REQ-E, the plugin's `EmailMFAOnlyTests`, MF-18, MF-19): email MFA set up during sign-in; a wrong email code (`codeMismatch`), then the right one. On `mfa-req-all` (U-REQ-ALL, `EmailMFAWithAllMFATypesRequiredTests`, MF-20 … MF-23): the setup selection offers TOTP and email, not SMS; an emailed code; choosing email, then TOTP, at the selection. Email codes come from the sink, in place of the plugin's AppSync subscription. Each user is deleted, by the client once signed in or by `tearDown`'s raw sign-in, which answers the pool's MFA |
| `DeviceTests` (`DeviceTestCase`) | DV-1 … DV-3, the plugin's `AuthFetchDeviceTests`, `AuthRememberDeviceTests` and `AuthForgetDeviceTests`, on `default` (device tracking "always remember") with a fresh user each: after sign-in `fetchDevices()` lists this session's device with its details; after `rememberDevice()` it is listed; after `forgetDevice()` none is |
| `DeviceKeyPersistenceTests` (`DeviceTestCase`) | DV-4 … DV-9, the plugin's `DeviceKeyPersistenceIntegrationTests`, on `default`: the device key survives a sign-out and an SRP sign-in, is presented by a second session of the same user and never by another user's session; it survives SRP → password, password → SRP and four alternating cycles (one device listed each time); one and two forced refreshes succeed with a remembered device |
| `DeviceAliasTests` (`DeviceTestCase`) | DV-10 … DV-19, the plugin's `DeviceAliasTokenRefreshIntegrationTests` (#4207), on `email-alias` (email as the username, device tracking "always remember", 5-minute tokens): the user signs in by email, so the typed name differs from the tokens' username, and every refresh (one, two, after a re-sign-in, after the device persisted), remember, forget (also after a refresh), fetch with details, the same device across a sign-out and sign-in, and the whole lifecycle must find the device record under the typed name. This session's device is identified by its access token's `device_key` |
| `FederationTests` | FE-1, the plugin's `FederatedSessionTests.testUnsuccessfulFederation`, against the default backend's identity pool (R-IP), which has no external provider, so only the rejection is reachable: a made-up Facebook token is `notAuthorized`, and the signed-out session stays signed out with no record; plus (not counted) a failed federation from a guest keeps the same guest identity, as the plugin keeps the previous credentials |
| `ChallengeResumeTests` (`ClientMFATestCase`) | Design §4.11, its own CR-1 … CR-3 (not the credentials rows): a sign-in interrupted on an MFA challenge survives the app being closed (the client released, the registry holding no live session for it, a new client with the same session ID over the same keychain). CR-1: a TOTP challenge (a fresh `default` user with TOTP enrolled and enabled) is answered in a new client, the challenge record stored while it waits and gone after; CR-2: an emailed code on `mfa-req-email`; CR-3: the new client signs in again instead, superseding the saved challenge |
| `PluginRecordLocationTests` (interop target) | The plugin, in the same app, writes its record under its own key, `amplify.<ns>.session`, which is also the client's `.default` session record, writes no v1 record, and deletes its record on sign-out (no signed-out marker). Removes `.default`'s three items (the plugin's record, `$default.meta` and `$default.challenge`) before and after, and the user's device records and the plugin's `authConfiguration` at teardown. The record is checked straight after the sign-out: the signed-out fetch then saves the plugin's guest record (`identityPoolOnly`) under the same key when it returns guest credentials, and none when it does not, which the test pins from the fetch's result (the plugin's CI's Gen1 translation states no guest flag) |
| `CredentialStoreTransitionRealKeychainTests` (interop target) | Parity IO-1 … IO-3: the plugin's access-group transition clear and migration (Q7), with their names; a named row the client wrote is still listed afterwards. `.default`'s `$default.meta` and `$default.challenge` belong to the plugin's session: the clear removes them, the migration moves them, a label the client set on `.default` included, which the client then lists under the shared group. IO-5: the migration's clear of a non-empty destination removes them there and keeps named records, which do not block the migration. IO-6: the plugin, started under another user pool, applies the configuration change to the `authConfiguration` the client recorded, and deletes that configuration's login with `.default`'s sidecar and challenge item, keeping named records. Offline: no request. Wipes the plugin's (and client's) real services |
| `PluginSharedLoginTests` (interop target, formerly `PluginAdoptionTests`) | AD-1 … AD-8, the shared saved login: `.default` restores in place, with no request, the user the plugin signed in, and reads the plugin's later writes (AD-1); a named session never reads the plugin's record (AD-2); the plugin's `fetchAuthSession`, configured again as at a relaunch, sees the user the client signed in, with the client's tokens (AD-3); a plugin sign-out deletes the record, and the next `.default` is signed out (AD-4); a client sign-out (`.complete`) leaves `{"noCredentials":{}}` and the sidecar, a signed-out `.default` row naming the user, and the relaunched plugin signed out (AD-5); a client refresh is what the relaunched plugin holds (AD-6); the plugin signing out the client's login leaves `.default` signed out with a signed-out row naming the user, from the sidecar (AD-7); the client signing out the plugin's login leaves the relaunched plugin signed out (AD-8). The two never run side by side over `.default`. Signs `alice`, a fresh user of the test's own (signed up and deleted through the client), in through the plugin or the client; removes her device records and the plugin's `authConfiguration` at teardown |
| `PluginRotationTests` (interop target) | RT-1, RT-2: refresh-token rotation across the plugin and `.default` on live Cognito, the shared login's rollback claim. The client rotates and a relaunched plugin refreshes with the rotated token (no `RefreshTokenReuseException`); the plugin rotates and `.default` restores and refreshes with it (no `sessionExpired`), and a plugin relaunched after that reads the client's newest token. Needs the default pool's `rotation` app client (rotation on, no grace period, `infra/pools/default.json`) and `AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json`, which `infra/plugin-configs.py` writes once `provision.sh` has made the client; the build phase copies it when present. On CI the overlaid `extended` role brings it (`infra/ci`). Without it, it **skips** on any backend that is not the sandbox (the outputs' sandbox marker), such as the plugin's own files, and **fails** on the sandbox, asking for `provision.sh`. Wipes the plugin's unshared service before and after |
| `AccessGroupRemovalRealKeychainTests` (interop target) | IO-4: after the plugin's access group is removed, the moved session keeps its group and a group-less read (plugin, client listing, and a group-less `.default` restoring it as `.signedIn`) still finds it. Signs a fresh user of the test's own in through the plugin |

## Running in CI

`.github/workflows/integ_test_auth_client.yml` runs every suite on iOS, one job each: `CognitoClientIntegrationTests`,
`CognitoClientPluginInteropTests`, each `CognitoClientUITests` test in its own job (one browser per simulator), and
`CognitoClientWebAuthnUITests` with the plugin's simulator server (after its own tests, `npm test`) and a 10-minute
limit per test. It uses the plugin's CI: the `IntegrationTest` environment, the plugin's `auth` test configuration
downloaded to `~/.aws-amplify/amplify-ios/testconfiguration/`, `run_integration_tests.yml` for the first three (which
turns the simulator's hardware keyboard off, as for the plugin; pasteboard sync is not changed), and the steps of the
plugin's WebAuthn workflow for the last. The client and interop jobs add the client's own roles through
`run_integration_tests.yml`'s `cognito_client_ci_overlay` input, set no skip variable, and fail on any skip: the setup
"Run as CI does (recommended)" (above) describes and reproduces.

It runs from `integ_test.yml`: on pull requests to `main` when the client, its host app, the Cognito engine, the
shared internals, `AmplifyFoundation`, `AmplifyFoundationBridge` or the WebAuthn LocalServer change (the
`auth_client` group in `scripts/python/integ_test_groups.json`), and on every push to `main`. Once the workflow is on
the default branch, it can also be started by hand from the Actions tab, with a toggle per suite.

**The client suite's time limit.** `run_integration_tests.yml` runs an unscoped suite with `-test-iterations`
and `-retry-tests-on-failure`, then, if it failed, once more in its retry step. After a failure each iteration runs
the whole suite again, not only the failed tests: about half an hour a pass, after about 10 minutes of cold build
and before about 4 minutes to set the retry step up. A 120-minute limit once cancelled a failing job in its retry
step before it reported. So the client job passes `test_iterations: 2` (an optional input of
`run_integration_tests.yml`, 3 by default, so its other callers are unchanged) and `timeout-minutes: 180`: a failing
job makes at most four passes and reports within its limit. With `-retry-tests-on-failure`, a pass with no failure
ends the run, so a green job makes one pass and no retry.

### Skips on the plugin's own files

CI runs every test ("Running in CI", above). Only a run on the plugin's own files, without the client's roles
overlaid, lacks the resources some tests need ("What the plugin's CI backends must provide", above). Such a run can
turn those tests' failures into skips, each naming the resource, through one helper,
`IntegrationTestEnvironment.skipOnCIIfMissing(_:present:)`. It throws `XCTSkip` only when all three hold:

1. **The run asks for the skips.** The test process has `COGNITO_CLIENT_INTEG_CI_SKIPS=1`: set
   `TEST_RUNNER_COGNITO_CLIENT_INTEG_CI_SKIPS=1` in `xcodebuild`'s environment, which passes it to the test process
   without the prefix, or pass `cognito_client_integ_ci_skips: '1'` to `run_integration_tests.yml`. No CI job sets
   it: the client's jobs get every resource from the client's own CI resources ("CI's additive resources", below), so
   a missing one fails its tests instead, and their skip gate ("No skips on CI", below) fails the job on any skip. The
   variable is a local approximation only ("Only the plugin's files (a local approximation)", above). So a new test
   that needs a resource must get it from CI's resources, never from a skip.
2. **The file set is not the sandbox's**: no role's outputs carry the sandbox mark (`isSandboxFileSet`). A sandbox
   run never skips, even with the variable set by mistake.
3. **The resource is in fact missing.** A file set that has it runs the test, with no code change. For
   `deviceAliasConfirmation`, the outputs file shows a confirming pre-sign-up trigger with the `confirming_trigger`
   mark, as the client's own device-alias pool's does, or names a code API.

Otherwise it returns, and the test fails naming the resource. A run without the variable stays strict. On the
sandbox's CI shape ("Optional: the sandbox"), CS-3 `testChangedIdentityPoolDoesNotSeeTheOldGuestRecord` and CS-D3
`testDefaultSessionCarriesItsIdentityIdWhenTheIdentityPoolChanges` fail too: both take their second identity pool
from `secondIdentityPool(besides:)`, which the CI shape cannot give (no other Gen2 file names an identity pool with
guest access, and no credentials file names one), while on CI another Gen2 backend's identity pool serves.
`HarnessHelperTests.testCISkipHappensOnlyOnCIOffTheSandboxWithTheResourceMissing` checks the rule offline, over the
8 combinations of the three conditions, for every reason.

Each reason is a case of `CISkipReason`, whose message is the skip's and names the missing resource:

| Reason | Where | Tests |
|---|---|---|
| `customAuthAnswer` | `PluginCredentials.requireCustomChallengeAnswer()` | CA-1…3 (`CustomAuthTests`, in its `setUp`), `SandboxParityProvisioningTests.testCustomAuthCompletesWithTheStoredAnswer` |
| `newPasswordUsers` | `PluginCredentials.requireNewPasswordUsers()` | CH-1 `ChallengeTests.testNewPasswordRequiredChallenge`, P-3 `SandboxProvisioningTests.testForceChangePasswordUserIsAskedForANewPassword` |
| `credentialsFile` | `CognitoBackendSmokeTests.testProvisionedUsersAreAvailable`, after its outputs checks | that test |
| `defaultCodeAPI` | `IntegrationTestEnvironment.codeSinkAPI(.standard, ciSkip:)` | AT-2's second half `UserAttributesTests.testUpdatedEmailIsVerifiedWithTheCodeSentToIt` |
| `defaultCodeAPIAndVerifiedEmail` | `IntegrationTestEnvironment.codeSinkAPI(.standard, ciSkip:)` | RP-3 `PasswordResetTests.testSuccessfulResetPasswordEndToEnd` |
| `deviceAliasConfirmation` | `SandboxSignUp.requireNotKnownUnconfirmable(_:)` (`SandboxSignUp.ciSkip(for:)`), before any sign-up | DV-10…19 (`DeviceAliasTests`), `SandboxParityProvisioningTests.testEmailAliasPoolSignsInByEmailWithShortTokens`; and in `SandboxHelperTests.testEveryPoolAutoConfirmsAFreshUserAndCleanupDeletesIt` the device-alias pool is left out of the loop, the reason recorded as an `XCTContext` activity, so the test still checks every other pool and passes |

On the plugin's own files, `PluginRotationTests` (RT-1, RT-2) skip without the rotation client's outputs, which the
plugin's backends lack. CI's interop job overlays `extended`, whose rotation client they run on, and runs every
interop test, RT-1 and RT-2 included, with no skip. HU-1, HU-2, WA-0 and WA-1 need nothing the plugin's files lack.

### CI's test configuration

At the top level, the plugin's `auth` test configuration is nine files, with no credentials file among them:

| File | Format | Role |
|---|---|---|
| `AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json` | Gen1 | `.standard`, translated ("Gen1 files") |
| `AWSCognitoAuthPluginMFARequiredIntegrationTests-amplifyconfiguration.json` | Gen1 | `.mfaRequiredTOTPSMS`, translated |
| `AWSCognitoAuthPluginHostedUIIntegrationTests-amplifyconfiguration.json` | Gen1 | `.hostedUI`, translated |
| `AWSAuthStressTests-amplifyconfiguration.json` | Gen1 | none (the plugin's stress backend) |
| `AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json` | Gen2 | `.passwordless` |
| `AWSCognitoEmailMFARequiredTests-amplify_outputs.json` | Gen2 | `.mfaRequiredEmail` |
| `AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json` | Gen2 | `.mfaRequiredAll` |
| `AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json` | Gen2 | `.emailAlias` |
| `AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json` | Gen2 | `.webAuthn` |

Beside them, the `cognito-client-ci/` subfolder holds the client's own CI resources' files, its credentials file
among them, which `infra/ci/ci-overlay.sh` maps in for the client's jobs ("CI's additive resources", below).

### CI's additive resources (`infra/ci`)

The CI-only skips and RT-1 and RT-2 need resources the plugin's CI backends lack. Adding them to those backends would
change them, so `infra/ci/provision-ci.sh` adds **new** ones beside them in the CI account instead, and changes
nothing that exists. Everything is named `ccit-ci-…` (the identity pool `ccit_ci_default`, the parameters
`/ccit-ci/…`) and tagged `purpose=amplify-cognito-client-integ`. It comes in two phases.

**Phase 1, the device-alias role** (`--scope email-alias`, the default). It replaces the plugin's device-alias file
in the client's CI job only.

| New resource | Why |
|---|---|
| Pool `ccit-ci-email-alias` (`pools/email-alias.json`) and its `client` app client, on the **Lite** plan | DV-10…19 and the short-token parity check need email as the username, devices always remembered, 5-minute tokens and a confirming pre-sign-up trigger, all of which Lite has |
| Lambda `ccit-ci-pre-sign-up` (`lambda/triggers/triggers.mjs` with `REFUSE_CONFIRMATION_USERS=1`) | Confirms and verifies every `ccit-` sign-up; refuses others, and refuses `ccit-confirm-` users, which no code API on this pool could confirm, so no sign-up code is ever sent. Phase 2's `ccit-ci-default` uses the same trigger, so it refuses them too |
| Lambda `ccit-ci-discard-sender` (`infra/ci/lambda/discard-sender`), the pool's custom email and SMS sender, and the KMS key `alias/ccit-ci-senders` that Cognito encrypts codes with | Cognito sends nothing for the pool, so its runs can never reach the account's daily email limit. No test there reads a code, so there is no code sink |
| Role `ccit-ci-trigger-exec` (its own log streams only) and the two log groups (7 days) | |

The outputs file names no code API. Instead it carries `"custom": {"amplify_cognito_client_integ":
{"confirming_trigger": true}}`, which the harness reads (`IntegrationTestEnvironment.promisesConfirmingTrigger`):
no user is signed up on a role that cannot confirm one, so without the mark the tests would fail before any sign-up.
The mark is not the sandbox's, so it opens no sandbox check: those run on CI only through the capabilities file.

**Phase 2, the extended role** (`--scope all`, which keeps phase 1). The plugin's default role is not replaced:
the client gains a role of its own, `SandboxPool.extended`, backed by `ccit-ci-default` (`pools/default.json`, on
Essentials). Only the tests that need the default backend's extras use it, through `IntegrationTestEnvironment.extrasRole`:
CA-1…3 and the stored-answer check, CH-1, P-3, the fixture check, AT-2's second half and RP-3. RT-1 and RT-2 sign
their user up through it too (`InteropEnvironment.rotationBaseResource`), and still require the rotation client to
be on that user's pool. Every other test on the default role keeps the plugin's pool. When the extended file is
absent, `extrasRole` is the default role, so on the plugin's own files those tests fail naming the resource (or skip
with their skip messages, when the run asks for the skips), and on the sandbox they run on its default pool. `.extended` is not in `SandboxPool.allCases`, the plugin's roles,
but in `SandboxPool.optionalRoles`, and the build phases copy its files as optional.

| New resource | Gives |
|---|---|
| Pool `ccit-ci-default`, its `plugin` and `rotation` app clients, and identity pool `ccit_ci_default` with two permissionless roles. Its pre-sign-up trigger is `ccit-ci-pre-sign-up`, so it refuses `ccit-confirm-` sign-ups, although its codes reach the code sink | The extended role, and the rotation client (RT-1, RT-2) |
| The define, create and verify custom-auth triggers, and the answer in SSM `/ccit-ci/custom-challenge-answer` (a SecureString under the key `alias/ccit-ci-senders`, as the temporary password is; the Lambda holds only its SHA-256) | CA-1…3 and the stored-answer check |
| `ccit-ci-new-password-1` … `-12`, kept in `FORCE_CHANGE_PASSWORD` every 10 minutes by `ccit-ci-new-password-reset` (`infra/ci/lambda/new-password-reset`) and an EventBridge rule; the temporary password in SSM | CH-1, P-3, and the fixture check with the credentials file |
| The custom sender (`lambda/custom-sender`), the code sink (AppSync API and table `ccit-ci-codes`, `codesink/`), their roles, and the SNS caller role for SMS MFA | AT-2's second half, RP-3; Cognito sends nothing |
| Pool `ccit-ci-email-alias-codes` (`pools/email-alias.json`, on **Lite**) and its `client` app client, with Lambda `ccit-ci-pre-sign-up-confirmable` (`triggers.mjs` without `REFUSE_CONFIRMATION_USERS`, so it leaves `ccit-confirm-` users to confirm) and the custom sender into the code sink | The client's own role `SandboxPool.emailAliasCodes` (optional, not in `allCases`): the email-alias code check; Cognito sends nothing |
| `ccit-ci-capabilities.json`: `refuses_non_test_users` and `reset_password_codes` on `extended`, `email_alias_codes` on `email-alias-codes` | The three sandbox checks, on those roles ("Sandbox checks", above) |

The alias-codes pool and the capabilities came after the first phase-2 run uploaded its four files, so they are new
files beside them: `--upload` never rewrites a key, and a rerun of `--apply --scope all --upload` finds the four
unchanged (`=`, byte for byte) and puts only the two new keys. That rerun creates the pool, its trigger, the
trigger's log group and its app client, and updates, each after its tag check, only these of its own: the key
`alias/ccit-ci-senders`'s policy (opened to the account's pools while the pool is made, as on a first run, then
narrowed to the three pools), the inline policies of `ccit-ci-trigger-exec` (the new trigger's log group),
`ccit-ci-sender-exec` (the decrypt, narrowed to `ccit-ci-default` and the new pool; never widened on a rerun) and
`ccit-ci-reset-exec` (`kms:Decrypt` on that key, through SSM, for the temporary password's parameter only),
`ccit-ci-custom-sender`'s resource policy (Cognito may invoke it for the new pool), and the two SSM parameters: the
first phase 2 stored them under the account's AWS-managed `alias/aws/ssm`, so each is stored again
(`put-parameter --overwrite`), with the same value, under `alias/ccit-ci-senders`. `verify-unchanged` lists a change
to a `ccit-ci-` resource as the script's own, and an AWS-managed KMS alias (`alias/aws/*`) that appears as
AWS-managed (AWS makes `alias/aws/ssm` the first time a SecureString uses SSM's default key, as that first phase 2
did), and fails on any other change, removal or addition.

`provision-ci.sh` finds each resource by name, creates only what is missing, and refuses any resource with one of
its names that lacks the tag. It reads the account's headroom first, and checks it only for what the run creates: a
new role needs 50 roles left under the quota, the code sink's API two APIs free beyond it under the AppSync quota
(25, AWS's default, unless `CCIT_CI_APPSYNC_API_QUOTA` names a raised one), and the reset schedule at most 250
rules on the default bus. A rerun that creates none of them (one that extends the code sink's key, say) checks
none. Every change it makes goes through one guard that refuses a name that is not
`ccit-ci-`, and outside `--apply` only get, list, describe and head calls can be made at all. A dry run is the default
and prints each call, masked; `--apply` runs that dry run first and stops before its first change if it refuses.
`--upload` puts new keys only. A key that exists is left alone when it holds the same bytes (so phase 2 leaves phase 1's
file as it is), and any other existing key refuses the whole upload. `snapshot` and `verify-unchanged` detect changes
to the metadata they read of the rest of the account: every user pool, its MFA settings and app clients, the Lambdas
they name and those Lambdas' resource policies; every identity pool and its roles; every role, with its trust and its
inline and attached policies; every function, with its configuration and resource policy; every KMS alias and key
policy; every AppSync API as listed; every table, with its key schema, billing mode and TTL; every rule, with its
targets; every SSM parameter's metadata (never its value); every log group, with its retention; and the `auth/`
objects with their ETags. Not read: AppSync schemas, resolvers, data sources and keys, and S3 objects' contents. The
Cognito lists are read page by page to the last (`read_all_pages`: `--max-results` turns the CLI's own pagination
off), and every other list is one the CLI pages itself. The documents leave out what AWS changes by itself: a user
pool's user count, a Lambda's state and its runtime version (`RuntimeVersionConfig`, which the runtime's automatic
updates move), and a role's last use; `verify-unchanged` leaves them out of an older snapshot's documents too. A
snapshot (version 3) hashes each document normalized: lists
AWS keeps in no order (a policy's principals, actions, resources and condition values, `"x"` read as `["x"]`, its
statements; tags; Cognito's auth flows, attributes, URLs, OAuth settings, schema and identity providers) are sorted
first, and a Lambda's `Layers` keep their order. Its `.docs.json` beside it keeps the documents, so a diff can name
the fields that changed, with every secret in them hashed first (the Lambdas' environment values, app client
secrets and the SMS external ids). Given both `.docs.json` files, `verify-unchanged` hashes both sides again that
way, so an earlier version's snapshot compares with a version-3 one, over the kinds both read. `teardown` removes
only these resources, and is a dry run by default.

```bash
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests
export COGNITO_CLIENT_INTEG_CI_CONFIG_URL=s3://<bucket>/<path>   # CI's AWS_S3_BUCKET_INTEG_V2, the folder above auth/
infra/ci/provision-ci.sh snapshot                       # read-only; /tmp/ci-disc/snapshot-<time>.json
infra/ci/provision-ci.sh                                # phase 1 dry run: every call it would make, masked
infra/ci/provision-ci.sh --apply --upload               # phase 1; then CI's client job overlays email-alias
infra/ci/provision-ci.sh snapshot
infra/ci/provision-ci.sh verify-unchanged /tmp/ci-disc/snapshot-<before>.json /tmp/ci-disc/snapshot-<after>.json
infra/ci/provision-ci.sh --scope all [--apply --upload] # phase 2, later
infra/ci/provision-ci.sh teardown [--apply]             # later, if ever
```

`bash infra/ci/test_provision_ci.sh` (over a fake `aws`), `bash infra/ci/test_ci_overlay.sh`, and `node --test` on
`infra/ci/lambda/test_pre_sign_up_refusal.mjs` and each `infra/ci/lambda/*/test_*.mjs` test these offline. CI runs
them, with every other `infra/` self-test, on each change to `infra/` (`auth_client_infra_self_tests.yml`).

**How CI uses them.** CI downloads `auth/` recursively for every auth job, so the files land in
`testconfiguration/cognito-client-ci/` on the plugin's runners too. They do not affect the plugin's tests: none has a
plugin file name, and the plugin's tests read their files by exact path (`testconfiguration/<name>.json`). They are
not inert, though: the copy phases of `AuthHostApp` and `AuthHostedUIApp` copy the whole `testconfiguration`
directory (`cp -r`), so the subfolder, `ccit-ci-default-credentials.json` included, lands in those apps' test bundles
under `Build/`, and so in the build cache `run_integration_tests.yml` saves. `AuthWebAuthnApp` copies only the top
level. Only the client's jobs read them, through `run_integration_tests.yml`'s `cognito_client_ci_overlay`
input, which runs `infra/ci/ci-overlay.sh`. That script copies the plugin's top-level files into a directory of its
own and sets `COGNITO_CLIENT_INTEG_DIR` to it. The `email-alias` role puts in `AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json`.
The `extended` role adds `AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs.json`, its `-credentials.json`
and `AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json`, and, when present,
`AmplifyCognitoClientEmailAliasCodesIntegrationTests-amplify_outputs.json` and
`AmplifyCognitoClientIntegrationTests-capabilities.json` (kept only for the roles the overlay gives), and replaces
nothing. The client suite passes `email-alias extended`, and the interop suite `extended`. The plugin's jobs pass
nothing and read the plugin's files only. Without the subfolder, or when a file there does not check out (no user
pool, the sandbox's mark, a credentials file that is not all strings, a rotation client on another pool, an
alias-codes file without email as the username or a code API, a capability the harness does not know), nothing is
set, and the tests that need those files fail, or skip as sandbox checks, which the skip gate fails.

**No skips on CI.** Both client jobs pass `enforce_no_skips: true` and `allowed_skips: 0` to
`run_integration_tests.yml`. The test runs then write their result bundles to the runner's temporary directory
(`run_xcodebuild_test`'s `result_bundle_path`), and a last step reads the last run's (the retry's, when there was
one) with `xcrun xcresulttool get test-results summary`, lists the skipped tests, and fails the job when more than
`allowed_skips` skipped. The plugin's jobs leave it off. On CI: 0 skipped in `CognitoClientIntegrationTests` and 0 in
`CognitoClientPluginInteropTests`. To reproduce it locally, see "Run as CI does (recommended)", above.

The code sink's API key (phase 2) lives 364 days. A rerun of `--apply --scope all` in its last 30 days extends it to
364 days from then, keeping its id, so the two uploaded files that name it (`ccit-ci-default-amplify_outputs.json` and
`ccit-ci-email-alias-codes-amplify_outputs.json`) stay valid. Rerun before it expires: once it has, the rerun makes a
new key, and both files must be replaced, which `--upload` never does (it never overwrites), so replacing this
script's own objects is then a separate step.

A rerun never updates a user pool or a Lambda's code. After a change to a pool template, to
`infra/lambda/triggers/triggers.mjs`, `infra/lambda/custom-sender` or `infra/ci/lambda/*`, delete that pool or function
by hand and rerun: the rerun makes it again, and replaces the invoke permissions that name a pool's old ARN.

## Optional: the sandbox

This directory's own Cognito sandbox (`infra/`) is no longer the default for local runs: run on the plugin's CI
configuration instead ("Run as CI does (recommended)", above). No client test needs it any
more: CI runs them all, the sandbox checks and RT-1 and RT-2 included, and fails on any skip
(`integ_test_auth_client.yml`: `enforce_no_skips: true`, `allowed_skips: 0`). The sandbox stays as the only backend
for the plugin's credential-gated tests, which the plugin's CI skips or does not run, as it downloads no credentials
file for them (`AuthCustomSignInTests`, `testNewPasswordRequired` and `DeviceAliasTokenRefreshIntegrationTests`;
"What the plugin's CI backends must provide", above), and for anyone without read access to CI's configuration bucket. Each self sign-up toggle on the sandbox
account can raise a security finding, which is why it isn't the default.

### Running on the sandbox's file set

Write the plugin file set from the sandbox into a directory of its own, and point the build at it. Never at
`~/.aws-amplify/amplify-ios/testconfiguration`, which holds your own plugin configuration: `--dir` writes only
the directory it is given (mode 600 files in a 700 directory, no manifest, no backups), and refuses that
directory and one inside it, however the path is spelt (another case of a name on a case-insensitive volume, a
symlink).

```bash
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests
DIR=$(mktemp -d /tmp/ccit-plugin-set.XXXXXX)
infra/plugin-configs.py --dir "$DIR"                  # reads the sandbox's state; makes no AWS call
AWS_PROFILE=<sandbox-profile> infra/prepare-run.sh    # optional: resets the new-password users, as a fresh CI backend
cd CognitoClientHostApp
COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild build-for-testing -project CognitoClientHostApp.xcodeproj \
  -scheme CognitoClientIntegrationTests -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD"
# Self sign-up on for the run, off again after ("Self sign-up is off at rest"); it reads no COGNITO_CLIENT_INTEG_DIR.
AWS_PROFILE=<sandbox-profile> ../infra/self-sign-up.sh on -- \
  xcodebuild test-without-building -project CognitoClientHostApp.xcodeproj -scheme CognitoClientIntegrationTests \
  -destination "id=$UDID" -derivedDataPath "$DD" -parallel-testing-enabled NO -collect-test-diagnostics never
rm -rf "$DIR"
```

Set `COGNITO_CLIENT_INTEG_DIR` on the build only: the `infra/` scripts read the same variable as the sandbox's
state directory. Rebuild (`build-for-testing`) after writing the file set again, for example after `prepare-run.sh`
rotated the code sink's API key. The sandbox has eight single-use new-password users (`ccit-plugin-new-password-1` to `-8` on `default`, reset to `FORCE_CHANGE_PASSWORD` by `prepare-run.sh`), and every run that
reaches one uses one up: the client suites' CH-1, and the plugin's `testNewPasswordRequired` in its Gen1 and its
Gen2 suite, once more for each retry iteration. So between two `prepare-run.sh`, eight such runs in all, client
and plugin together, find a user, and a ninth fails CH-1 with none left; one round of the plugin's two suites and
the client suite takes three. CI has no credentials file, so there CH-1 fails naming it instead.

**CI's file set, from the sandbox (the CI shape).** `infra/plugin-configs.py --dir "$DIR" --ci-shape` writes, from the same sandbox backends, exactly
the nine files the plugin's CI downloads, by CI's names and in CI's formats: Gen1 `amplifyconfiguration.json` for the
default, MFA-required, hosted-UI and stress backends (`AWSAuthStressTests-amplifyconfiguration.json`), in the shape
it writes for the plugin's own Gen1 suites; Gen2 outputs for the passwordless, the two email-MFA, the device-alias
and the WebAuthn backends, with a `data` block only on the first three; no `EMAIL` in the two email-MFA files'
`mfa_methods`, as CI's; no sandbox mark; and no credentials file. Where CI's backends differ from the sandbox's in
a way no file states, the CI shape names each pool's `ci` app client instead, which `parity.py` shapes as CI's
(`CI_SHAPE_CLIENT_POOLS`): no `USER_PASSWORD_AUTH` on the MFA-required, email-MFA and device-alias pools, and, on
the passwordless and device-alias pools, every sign-up through it left unconfirmed by the pre-sign-up trigger, as on
a backend with no confirming trigger (`CI_SHAPE_UNCONFIRMED_POOLS`). Build with it to see locally what CI will run:
the tests that fail are the ones those skips cover ("Skips on the plugin's own files") and CS-3 and CS-D3. It writes only into a directory of its own, and removes from
it any file of the full set.

### Infrastructure

```bash
AWS_PROFILE=<sandbox-profile> infra/provision.sh us-west-2     # idempotent; again whenever provisioning changes
AWS_PROFILE=<sandbox-profile> infra/prepare-run.sh             # optional before a run: resets the new-password users
AWS_PROFILE=<sandbox-profile> infra/self-sign-up.sh on -- <command>  # self sign-up on for one run, off again after
AWS_PROFILE=<sandbox-profile> infra/self-sign-up.sh off [--force]   # recovery only
AWS_PROFILE=<sandbox-profile> infra/teardown.sh                # destructive; removes only what provision made
```

`provision.sh`, `prepare-run.sh` and `self-sign-up.sh on` refuse to start, before any AWS call, when the volume
holding the state directory (`COGNITO_CLIENT_INTEG_DIR`, default `~/.amplify-cognito-client-integ`) has less than
`COGNITO_CLIENT_INTEG_MIN_FREE_GIB` free: a whole number of GiB, **2** when unset or empty, and `0` skips the check.
With a full disk the AWS CLI binary itself crashes part-way through a change, and says only that its launcher
failed. `self-sign-up.sh off`, the recovery, never checks. When an AWS call does fail, `parity.py` prints the
CLI's last stderr line and, when there is more, the last five lines, redacted (ids, ARNs, emails, the home
directory and the user name masked).

`provision.sh` creates one user pool with a public app client (SRP, password and refresh flows, token revocation
on), one identity pool with unauthenticated identities enabled, and two IAM roles for it that **grant no
permissions** (credentials are still vended, which is all the tests need). The pool's MFA is **optional** with
TOTP enabled; users with no MFA preference are never challenged. Every resource is tagged
`purpose=amplify-cognito-client-integ`; both scripts check that tag before every change they make, and
`teardown.sh` refuses to delete anything without it. The tests call this user pool and identity pool R-UP and
R-IP (and the identity-only pool below R-IP2).

The scripts use whatever credentials the AWS CLI resolves, and the first `provision.sh` records that account in
`state.json`. From then on `provision.sh`, `prepare-run.sh`, `self-sign-up.sh`, `teardown.sh` and `parity.py`
refuse any other account (`require_recorded_account` in `lib.sh` and `parity.py`). While no account is recorded
yet, `lib.sh`'s check exits before any AWS call unless `AWS_PROFILE` is set and none of `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN` is exported (the CLI would use exported keys instead of the
profile). That is all it checks: it doesn't know which account the profile belongs to. Set `AWS_PROFILE` to the
sandbox account's profile and check `aws sts get-caller-identity` before that first run.

The sandbox lives in one region, because its IAM roles are global. `provision.sh` refuses a region other than the one
`state.json` records, and, with none recorded (a first run, a lost or another state directory), one other than the
region of the identity pool that `amplify-cognito-client-integ-authenticated` already trusts. Another
`COGNITO_CLIENT_INTEG_DIR` is no way round it: it would build a second sandbox and re-point the roles at it. To move
the sandbox, run `teardown.sh` first.

| User | State | Set up by |
|---|---|---|
| `alice`, `bob` | Confirmed, permanent passwords, no MFA | `provision.sh` |
| `carol` | Confirmed, TOTP enrolled and preferred (`enroll_totp.py`; skipped if already enrolled) | `provision.sh` |
| `dave` | `FORCE_CHANGE_PASSWORD` with his stored temporary password; the challenge test sets `daveNew` | `prepare-run.sh`, every run |
| `erin` | Deleted and recreated with her stored password | `prepare-run.sh`, every run |

**The client suites no longer sign any of these in**: they read only the plugin's file set, sign up their own
users, and take CH-1's user from the sandbox's new-password users (`ccit-plugin-new-password-`, on `default`). The users, R-UP and R-IP stay for the
scripts' checks. `provision.sh` runs `prepare-run.sh` once at the end; after that, `prepare-run.sh` is optional
before a run (it resets the new-password users and rotates the code sink's key). It never touches `alice`, `bob` or
`carol`, and it keeps every password stable. Two `prepare-run.sh` runs may overlap (two runners): a user the other
run created or deleted first, or a device it forgot first, is tolerated; `erin`'s reset is tried again (up to five
times) when the other run deletes her before her password is set; and `plugin-configs.py --refresh` waits for the
other run's (up to two minutes). No script prints a secret or passes one to the AWS CLI as an argument.

**AWS CLI history must be off.** Passwords, tokens and carol's TOTP secret reach the CLI through
`--cli-input-json`. With `cli_history = enabled` in `~/.aws/config`, the CLI would record them in
`~/.aws/cli/history/history.db`. It is off by default. Both scripts refuse to run when `aws configure get
cli_history` prints `enabled`. They also refuse when the caller's account differs from the one `state.json`
records. No script prints an account, pool, client or key identifier: they print resource names, and the AWS
CLI's error output passes through a redactor (`redact` in `lib.sh`, `redact()` in `parity.py`).

State is written outside the repo to `~/.amplify-cognito-client-integ/`. The scripts read it from
`COGNITO_CLIENT_INTEG_DIR` when set (the host app's build phase reads the same variable as the plugin file set's
directory instead, so set it for one or the other). `infra/plugin-configs.py` turns it into the plugin's file set:

| File | Contents |
|---|---|
| `state.json` | Resource ids; the parity resources under `parity` (mode 600) |
| `amplify_outputs.json` | R-UP and R-IP's configuration (no longer read by the suites) |
| `<pool>-amplify_outputs.json` | One per parity pool (below), plus `hosted-ui` and `identity-only`, mode 600: what `plugin-configs.py` builds the plugin's files from |
| `users.json` | Passwords (`alice`, `bob`, `carol`, `daveTemporary`, `daveNew`, `erin`), `carolTotpSecret`, the code sink's `codeSinkApiKey`, the custom-auth `customChallengeAnswer` and the plugin users' passwords, mode 600 — secrets, never commit it |
| `build/` | The custom sender's `npm ci` output, cached by the hash of its sources |

### Plugin-parity resources

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
| P-15 | **Refresh-token rotation** on `default`: the app client `…-rotation` (`client`'s flows without `ALLOW_CUSTOM_AUTH`, and no `ALLOW_REFRESH_TOKEN_AUTH`, which Cognito refuses with rotation on; `RefreshTokenRotation` enabled with a 0-second grace period, so a replaced token is refused at once), named only in `rotation-amplify_outputs.json` (no identity pool), which `plugin-configs.py` writes as `AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json` (not in the CI shape). For `PluginRotationTests`. **Not provisioned yet**: the next `provision.sh` makes it (an `ensure_client` on the existing, tagged pool). It needs **AWS CLI 2.26.7 or later**, the first release whose Cognito model has `RefreshTokenRotation` (the CLI's `CHANGELOG.rst`: "cognito-idp: This release adds refresh token rotation"); an older CLI rejects the client's template. Until then those tests skip on CI and off the sandbox, and fail on the sandbox, asking for this client |

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
`CodeSink` subscribes too, over AppSync's real-time WebSocket protocol, and also queries
`listMfaInfo(username:)` (the username is required; there is no full-table read) with a plain `URLSession` POST,
both with the API key from the outputs' `data` block, which `plugin-configs.py` writes into every plugin file. It
returns the newest unexpired code since a given time; the resolver itself drops expired rows. The key can only
read. Test addresses are `@example.com` and no message is ever delivered. On `email-alias` the sink's username is
the one Cognito generated, not the email.

The API key lives **7 days**. `prepare-run.sh` (`parity.py rotate-key`) makes a new one when the recorded key
has under 4 days left, and deletes expired ones. A test bundle holds the key it was built with, so write the
plugin file set again and rebuild at least every 3 days.

Before anything else, `prepare-run.sh` runs `parity.py preflight`, which is read-only. It refuses the test run if:
- any live parity pool has `DEVELOPER` email or an SMS configuration without our custom sender for that channel
  and the KMS key;
- the borrowed SES domain is no longer verified, or its region's SES account has gained production access;
- the account's SNS has left the SMS sandbox;
- a parity pool is missing from `state.json` or the account (`MISSING`), has self sign-up on while no
  `infra/self-sign-up.sh` run holds a lease (`LEFT-ON`), or has it on against its template, or unstated
  (`DRIFT`). Self sign-up **off** is the resting state, never a gap;
- a parity pool's MFA (`MfaConfiguration`, its methods, and its WebAuthn relying party and user verification)
  differs from its template as provisioned, degraded as `state.json`'s `pending` list says (`MFA`).
  `provision.sh` re-applies it. The template's `${WEBAUTHN_RP_ID}` is resolved as provision resolves it, from the
  WebAuthn harness's committed `webcredentials:` entitlement; when those files cannot be read, or disagree with
  the plugin's, the gap is `WEBAUTHN`, and the fix is the files, not `provision.sh`. A pool whose template has no
  WebAuthn accepts any answer Cognito gives for none (it leaves `WebAuthnConfiguration` out). `self-sign-up.sh on`
  makes the same comparison; `off`, its release and `status` leave the WebAuthn settings out and never read the
  harness's files, so a release always turns self sign-up off.

`verify` reports the same and also exits non-zero.

**Self sign-up is off at rest, and on only for the length of a local run.** The tests sign users up, so a
run needs self sign-up, and every parity template keeps `"AllowAdminCreateUserOnly": false` as the shape a run
needs. But the account's security tooling flags a pool that allows it, and an automated mitigation may then turn it
off with its own `UpdateUserPool` call. So `provision.sh` always creates and updates the
parity pools with it **off**, and only `infra/self-sign-up.sh` turns it on, for the length of one run:

```bash
cd AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests
AWS_PROFILE=<sandbox-profile> infra/self-sign-up.sh on -- <command> [arguments…]
AWS_PROFILE=<sandbox-profile> infra/self-sign-up.sh off [--force]                  # recovery only
```

**Environment for the command goes after `--`.** `COGNITO_CLIENT_INTEG_DIR` is also the `infra/` scripts' state
directory, so the script itself must not see the file set's directory: write
`infra/self-sign-up.sh on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild …`, never
`COGNITO_CLIENT_INTEG_DIR="$DIR" infra/self-sign-up.sh …`. `AWS_PROFILE` goes before it, as for the other
`infra/` scripts. Only the step that runs tests needs the wrapper: `build-for-testing` signs no user up.

- `on -- <command>` checks the account, CLI history and the `purpose=amplify-cognito-client-integ` tag of every
  recorded parity pool, and refuses before any change if one lacks the tag. It then takes a **lease** for the run,
  turns self sign-up on for every parity pool (refusing, before any change, if a pool's MFA is not its
  template's), runs the command with `COGNITO_CLIENT_INTEG_SELF_SIGN_UP=on` and
  `TEST_RUNNER_COGNITO_CLIENT_INTEG_SELF_SIGN_UP=on` (which `xcodebuild` passes to the test runner), and exits with
  the command's status, or 128 plus the signal that stopped it.
- A `trap` on `EXIT`, `INT`, `TERM`, `HUP` and `QUIT` releases the run's lease however the command ends: success,
  failure, Ctrl-C, `Ctrl-\`, `kill`, or a closed terminal (only a `kill -9` of the script itself skips it). Self
  sign-up is turned off when no other run's lease remains. The trap is set before self sign-up is turned on, so an
  `on` that fails part-way (later pools are not tried) is undone too. If the release itself does not finish (its
  `parity.py` killed, say), the script reads the pools again (`parity.py self-sign-up status`, read-only) and says
  which are still on or have lost their MFA configuration, that self sign-up is on only for other runs that
  still hold leases (their end turns it off), or that every pool is at rest, and exits non-zero.
- **Piping the output is supported** (`… | xcbeautify`, with or without `2>&1`). The release needs neither stdout
  nor stderr: it ignores `SIGPIPE`, writes nothing to stdout, and drops any write that fails, and `parity.py`
  writes to a log in `$STATE_DIR` that is copied to stderr once it has finished (and kept if the release fails).
  So a Ctrl-C that also stops the pipe's reader, or a terminal that closes, still releases.
- The command runs in its own process group, and `INT`, `TERM` and `HUP` are forwarded to it at once (`QUIT` as
  `INT`; the run then exits 131). It cannot read the terminal.
- **Overlapping runs share self sign-up.** Each run holds a lease (its PID and start time, in
  `$STATE_DIR/self-sign-up-leases.json`), and the last run to end turns it off. A lease whose process has gone,
  or whose PID now belongs to another process, is dropped. The start time is read with `LC_ALL=C TZ=UTC`, so a
  lease holds whatever locale or time zone a later `off` or run uses. A lease without that `clock` mark cannot
  be compared and counts as dead, so a reused PID never holds self sign-up on. Every change happens under one lock
  (`$STATE_DIR/self-sign-up.lock`, `fcntl.flock`), so two toggles never interleave. `provision.sh` refuses while
  a lease is held, since provisioning turns self sign-up off. Preflight inside a run sees the lease and accepts
  self sign-up on.
- `off` turns it off, for recovery after a run that could not release (a `kill -9`, a lost machine). It refuses
  while a live run holds a lease; `off --force` turns it off anyway and drops every lease, for a run that is stuck.
  It turns off every tagged pool it can, skips any without the tag, and is a no-op on pools already off. Preflight
  reports a pool left on as `LEFT-ON` until then.
- It **never runs on CI**: it refuses when `CI` or `GITHUB_ACTIONS` is set. CI's backends are the plugin's, which
  allow self sign-up and are not this sandbox.
- It changes the flag only through `parity.py self-sign-up on|release|off`, which:
  - sends each pool's full configuration back with only the flag changed (`UpdateUserPool` resets any field it is
    not sent), with the pool's own tags;
  - checks the tag again just before each update;
  - restores an MFA configuration the update reset, even when something fails after the update, and reports any
    other field or tag that changed;
  - carries on, dropping its output, when its stdout or stderr has gone (a pipe whose reader died, a closed
    terminal), so a failed write never cuts a toggle between its update and its MFA restore;
  - ignores Ctrl-C once it holds the lock, so a toggle is never cut between its update and its MFA restore. The
    script acts on the signal once `parity.py` returns. A Ctrl-C while `on` still waits for the lock (another
    run's toggle, or a provision, holds it) ends the run at once, with nothing changed and no lease taken; its
    release then has nothing to do and does not wait.

  `on` and `release` run only with the script's token, so they are never run without its trap. The script refuses
  to nest.

While self sign-up is off, every test that signs a user up on the sandbox fails fast, before any request, with
"Self sign-up is off on the sandbox. Run the suite through infra/self-sign-up.sh on -- <command>."
(`SandboxSignUp.requireSelfSignUp`, and the interop suite's `InteropEnvironment.requireSelfSignUp`). Files that are
not the sandbox's (no `custom.amplify_cognito_client_integ` mark, as on CI) are never checked. As a backstop,
Cognito's own refusal (`NotAuthorizedException`, "SignUp is not permitted") becomes the same message, and the role
is remembered for the rest of the run. Inside a run, which had turned self sign-up on, the message says instead
that it was turned off during the run (an automated mitigation, another run's `off --force`, or a change by hand).
The WebAuthn app reports the refusal as `SelfSignUpIsOff`.

**The plugin's own suites on the sandbox need the wrapper too.** Their host apps' copy phases (`AuthHostApp`'s
"Copy Configuration folder", `AuthHostedUIApp`'s "Copy Integ test configuration folder", `AuthWebAuthnApp`'s "Copy
Test Config") read `$COGNITO_CLIENT_INTEG_DIR` as the client's host app does, default
`~/.aws-amplify/amplify-ios/testconfiguration`, so CI is unchanged. Point them at the same `--dir` file set, which
leaves your own plugin configuration unread and untouched. Without the wrapper, their sign-ups fail with
`AuthError.notAuthorized` and Cognito's "SignUp is not permitted for this user pool". From the repository root, one
wrapper per `xcodebuild`, with `COGNITO_CLIENT_INTEG_DIR` after `--` ("Environment for the command goes after
`--`", above):

```bash
SSU="$PWD/AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/infra/self-sign-up.sh"
DEST='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
DIR=$(mktemp -d /tmp/ccit-plugin-set.XXXXXX)
AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/infra/plugin-configs.py --dir "$DIR"
cd AmplifyPlugins/Auth/Tests/AuthHostApp
AWS_PROFILE=<sandbox-profile> "$SSU" on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project AuthHostApp.xcodeproj -scheme AuthIntegrationTests -destination "$DEST"          # Gen1
AWS_PROFILE=<sandbox-profile> "$SSU" on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project AuthHostApp.xcodeproj -scheme AuthGen2IntegrationTests -destination "$DEST"      # Gen2
AWS_PROFILE=<sandbox-profile> "$SSU" on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project AuthHostApp.xcodeproj -scheme AuthStressTests -destination "$DEST"
cd ../AuthHostedUIApp
AWS_PROFILE=<sandbox-profile> "$SSU" on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project AuthHostedUIApp.xcodeproj -scheme AuthHostedUIAppUITests -destination "$DEST"    # Gen1
AWS_PROFILE=<sandbox-profile> "$SSU" on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project AuthHostedUIApp.xcodeproj -scheme AuthHostedUIAppGen2UITests -destination "$DEST" # Gen2
cd ../AuthWebAuthnApp
(cd LocalServer && npm install && npm start) &                          # the simulator server
AWS_PROFILE=<sandbox-profile> "$SSU" on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test \
  -project AuthWebAuthnApp.xcodeproj -scheme AuthWebAuthnAppUITests -destination "$DEST"
rm -rf "$DIR"
```

The copy happens at build time, so rebuild after writing the file set again. `infra/plugin-configs.py` without
`--dir` still writes the file set into `~/.aws-amplify/amplify-ios/testconfiguration` itself, backing up what it
replaces (`--remove` puts it back), for a run that sets no `COGNITO_CLIENT_INTEG_DIR`.

The hosted-UI and WebAuthn suites have the simulator constraints described under "Running the WebAuthn UI tests"
and "Running the hosted-UI UI tests"; the same apply to the plugin's copies.

`python3 -m unittest discover -s infra -p 'test_*.py'` and `bash infra/test_self_sign_up.sh` test these rules
without calling AWS: the second runs the script end to end over a fake `aws` on `PATH`, whose `UpdateUserPool`
resets the MFA configuration as Cognito's does. It also sets `COGNITO_CLIENT_INTEG_SELF_SIGN_UP_TEST_SIGNAL`, a
test-only hook in `self-sign-up.sh` that is inert unless set: `before` or `after` makes the script send itself
SIGTERM just before or just after it learns the command's PID. Never set it outside the test.

Provisioning enforces the same rules. It refuses `DEVELOPER` email or SMS on a template that lacks the custom
sender, and refuses SMS outside the SMS sandbox. `parity.py verify` reports each pool's senders. It also exits
non-zero on a gap, and on a pool-wide wildcard left in the KMS policy, the sender's decrypt condition or the
SMS role's trust by a first run that stopped early.

`prepare-run.sh` also deletes users the tests created (usernames, or emails on `email-alias`, starting `ccit-`
or `confirm-`) more than 24 hours ago, in the parity pools only (P-12). `teardown.sh` removes all of it
(`parity.py teardown`, each resource after its tag check; the KMS key is scheduled for deletion in 7 days).
`provision.sh` needs `node` and `npm` for the custom sender's `npm ci`. The custom sender's `package.json` overrides
`bowser` to 2.11.0: Dependency Review reads bowser 2.12.0 and later as `MIT AND MITNFA`, which the amazon-ospo
configuration `.github/workflows/dependency-review.yml` uses rejects. `@aws-sdk/core` asks for `^2.11.0` and loads
bowser only for its browser user-agent parser, so it never runs in the Lambda. An override applies whatever range a dependent asks for:
after a bump of `@aws-crypto/client-node` or a new lockfile, check that `@aws-sdk/core`'s range still admits 2.11.0, and
remove the override only together with a `pkg:npm/bowser` entry in `dependency-review.yml`'s
`allow-dependencies-licenses`.

### Verified 2026-09-24

Against `us-west-2`: both users sign in with `USER_PASSWORD_AUTH`, map to **distinct** identity-pool identities,
and receive AWS credentials; unauthenticated (guest) credentials are also vended; re-running `provision.sh`
reuses every resource.
