//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Cognito trigger Lambdas for the parity pools (P-5b). One zip, four functions, each
// with its own handler export. No dependencies. Nothing here logs a user attribute or an answer.

import { createHash, timingSafeEqual } from "node:crypto";

// Usernames that must reach the confirm-sign-up step, on pools that auto-confirm everyone else.
const needsConfirmation = (username) => /^(ccit-)?confirm-/.test((username || "").toLowerCase());
// The only sign-ups the pools accept: test users, which prepare-run.sh (P-12) deletes after a day.
const isTestUser = (value) => /^(ccit-|confirm-)/.test((value || "").toLowerCase());
// The plugin's own integration suites (AmplifyPlugins/Auth/Tests/AuthHostApp, AuthHostedUIApp) name
// their users `integTest<UUID>` / `integtest<UUID>`, `hostedUI-<UUID>@…`, `test-<UUID>@…` (an email
// used as the username) or a bare `UUID().uuidString` (Cognito passes it lower-cased). They are accepted as test users
// too, and P-12 deletes them after a day like the rest.
const UUID_UPPER = "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}";
const PLUGIN_USER = new RegExp(`^((integtest|hostedui-)[0-9a-f]{8}-|test-[0-9a-f]{8}-[0-9a-f-]{27}@)`, "i");
// A bare UUID is only a plugin test user on the pools that list it: elsewhere (email-alias) Cognito
// generates UUID usernames itself, and the email decides.
const PLUGIN_BARE_UUID = new RegExp(`^${UUID_UPPER}$`, "i");
const poolList = (name) => (process.env[name] || "").split(",").filter(Boolean);
const isPluginTestUser = (value, poolId) => PLUGIN_USER.test(value || "")
    || (PLUGIN_BARE_UUID.test(value || "") && poolList("PLUGIN_UUID_USERNAME_POOL_IDS").includes(poolId));
// Pools whose plugin suites expect sign-up to stop at the confirm step (the plugin's passwordless
// backend has no pre-sign-up trigger): a comma-separated list of pool ids, set by parity.py.
const pluginConfirmPools = () => poolList("PLUGIN_CONFIRM_POOL_IDS");
// App clients shaped as the plugin's CI backends' on pools whose CI backend confirms no sign-up (the
// passwordless and device-alias ones): every sign-up through them is left unconfirmed, as on a pool with no
// pre-sign-up trigger. A comma-separated list of client ids, set by parity.py (CI_SHAPE_UNCONFIRMED_POOLS).
const ciShapeUnconfirmedClients = () => poolList("CI_SHAPE_UNCONFIRMED_CLIENT_IDS");

// Pre sign-up: auto-confirms the user, and auto-verifies the email and phone number when given,
// as the plugin's backends do. Usernames starting with `confirm-` (or `ccit-confirm-`) are left
// unconfirmed, so a sign-up test can reach the confirm step and read the code from the code sink.
// On the email-alias pool the username Cognito passes is generated, so the email is checked too.
export const preSignUp = async (event) => {
    const attributes = event.request.userAttributes || {};
    // Anyone with a client id can call SignUp: refuse everything but test users, so no one else can
    // mint auto-confirmed, auto-verified accounts here, and P-12 finds every user. The email counts
    // only where Cognito generated the username (a UUID, on the email-alias pool).
    const generated = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(event.userName || "");
    const plugin = isPluginTestUser(event.userName, event.userPoolId)
        || (generated && isPluginTestUser(attributes.email, event.userPoolId));
    if (!isTestUser(event.userName) && !(generated && isTestUser(attributes.email)) && !plugin) {
        throw new Error("Sign-up is limited to integration-test users");
    }
    if (needsConfirmation(event.userName) || needsConfirmation(attributes.email)) {
        // Where no code can confirm them (infra/ci's pools: REFUSE_CONFIRMATION_USERS=1), such users are refused
        // rather than left unconfirmed, so no sign-up code is ever sent for one.
        if (process.env.REFUSE_CONFIRMATION_USERS === "1") {
            throw new Error("Sign-up of users that need confirmation is refused on this pool");
        }
        return event;
    }
    if (plugin && pluginConfirmPools().includes(event.userPoolId)) {
        return event;
    }
    if (ciShapeUnconfirmedClients().includes((event.callerContext || {}).clientId)) {
        return event;
    }
    event.response.autoConfirmUser = true;
    if (Object.prototype.hasOwnProperty.call(attributes, "email")) {
        event.response.autoVerifyEmail = true;
    }
    if (Object.prototype.hasOwnProperty.call(attributes, "phone_number")) {
        event.response.autoVerifyPhone = true;
    }
    return event;
};

// Define auth challenge, as in the plugin's AuthCustomSignInTests doc comments:
//   customWithSRP:    SRP_A -> PASSWORD_VERIFIER -> CUSTOM_CHALLENGE -> tokens
//   customWithoutSRP: CUSTOM_CHALLENGE -> tokens
export const defineAuthChallenge = async (event) => {
    const session = event.request.session || [];
    const last = session[session.length - 1];
    const issue = (tokens, fail, challengeName) => {
        event.response.issueTokens = tokens;
        event.response.failAuthentication = fail;
        if (challengeName) {
            event.response.challengeName = challengeName;
        }
        return event;
    };
    if (session.length === 0) {
        return issue(false, false, "CUSTOM_CHALLENGE");
    }
    if (session.length === 1 && last.challengeName === "SRP_A") {
        return issue(false, false, "PASSWORD_VERIFIER");
    }
    if (session.length === 2 && last.challengeName === "PASSWORD_VERIFIER" && last.challengeResult === true) {
        return issue(false, false, "CUSTOM_CHALLENGE");
    }
    if (last.challengeName === "CUSTOM_CHALLENGE" && last.challengeResult === true) {
        return issue(true, false);
    }
    // A wrong custom answer gets up to three attempts, then the sign-in fails.
    if (last.challengeName === "CUSTOM_CHALLENGE" && session.length < 5) {
        return issue(false, false, "CUSTOM_CHALLENGE");
    }
    return issue(false, true);
};

// Create auth challenge: the answer is the fixed secret users.json holds as customChallengeAnswer.
// The function is configured with only its SHA-256 (CUSTOM_CHALLENGE_ANSWER_SHA256), never the answer.
// The public parameters say what kind of challenge it is.
export const createAuthChallenge = async (event) => {
    if (event.request.challengeName === "CUSTOM_CHALLENGE") {
        event.response.publicChallengeParameters = { challenge: "fixed-answer" };
        event.response.privateChallengeParameters = { answerSha256: process.env.CUSTOM_CHALLENGE_ANSWER_SHA256 || "" };
        event.response.challengeMetadata = "FIXED_ANSWER";
    }
    return event;
};

// Verify auth challenge response: correct when the answer's SHA-256 equals the stored one.
export const verifyAuthChallenge = async (event) => {
    const expected = Buffer.from((event.request.privateChallengeParameters || {}).answerSha256 || "", "hex");
    const actual = createHash("sha256").update(String(event.request.challengeAnswer || "")).digest();
    event.response.answerCorrect = expected.length === actual.length && timingSafeEqual(expected, actual);
    return event;
};
