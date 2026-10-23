//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Keeps the CI default pool's new-password users (infra/ci/provision-ci.sh) usable by the client's CH-1 and
// P-3: each in FORCE_CHANGE_PASSWORD with the temporary password, and no email or phone number. Run every
// 10 minutes by an EventBridge rule, and once by provision-ci.sh, which creates the users this way.
//
//   - a waiting user (FORCE_CHANGE_PASSWORD, no email or phone) is left alone, or, once its temporary password
//     is REFRESH_AFTER_DAYS old, given it again (the pool's TemporaryPasswordValidityDays is 20);
//   - a used one (any other state) is deleted and created again, but only once it has been left alone for
//     USED_AFTER_MINUTES, so a run that is still using it (P-3 signs CH-1's user in again) is not disturbed;
//   - a missing one is created.
//
// Logs usernames and states only, never the password. The password is read from an SSM SecureString
// parameter, never from the environment. The AWS SDK is the one the Node.js runtime ships, loaded only by the
// handler, so the logic below can be tested with no SDK installed (test_new_password_reset.mjs).

const MINUTE_MS = 60 * 1000;
const DAY_MS = 24 * 60 * MINUTE_MS;

/// What to do with one user, from its AdminGetUser answer (null when it does not exist).
export function decide(user, now, { usedAfterMs, refreshAfterMs }) {
    if (!user) {
        return "create";
    }
    const names = new Set((user.UserAttributes || []).map((attribute) => attribute.Name));
    const clean = !names.has("email") && !names.has("phone_number");
    const age = now - new Date(user.UserLastModifiedDate).getTime();
    if (user.UserStatus === "FORCE_CHANGE_PASSWORD" && clean) {
        return age >= refreshAfterMs ? "refresh" : "ready";
    }
    return age >= usedAfterMs ? "recreate" : "in-use";
}

/// Resets every user in `usernames` on `cognito`, an object with getUser, createUser, deleteUser and
/// setTemporaryPassword (each taking the username), and returns each username's outcome.
export async function resetAll(cognito, usernames, now, limits) {
    const states = {};
    for (const username of usernames) {
        states[username] = await resetOne(cognito, username, now, limits);
    }
    return states;
}

async function resetOne(cognito, username, now, limits) {
    const action = decide(await cognito.getUser(username), now, limits);
    switch (action) {
    case "ready":
    case "in-use":
        return action;
    case "refresh":
        await cognito.setTemporaryPassword(username);
        return "refreshed";
    case "recreate":
        await cognito.deleteUser(username);
        return (await create(cognito, username)) ? "recreated" : "recreated by another run";
    default:
        return (await create(cognito, username)) ? "created" : "created by another run";
    }
}

/// Creates the user with the temporary password and no message. False when another invocation created it
/// first.
async function create(cognito, username) {
    try {
        await cognito.createUser(username);
        return true;
    } catch (error) {
        if (error && error.name === "UsernameExistsException") {
            return false;
        }
        throw error;
    }
}

/// The settings, from the function's environment.
export function settings(environment) {
    const usernames = (environment.USERNAMES || "").split(",").map((name) => name.trim()).filter(Boolean);
    if (!environment.POOL_ID || usernames.length === 0 || !environment.TEMP_PASSWORD_PARAMETER) {
        throw new Error("POOL_ID, USERNAMES and TEMP_PASSWORD_PARAMETER must be set");
    }
    return {
        poolId: environment.POOL_ID,
        usernames,
        parameter: environment.TEMP_PASSWORD_PARAMETER,
        limits: {
            usedAfterMs: Number(environment.USED_AFTER_MINUTES || 60) * MINUTE_MS,
            refreshAfterMs: Number(environment.REFRESH_AFTER_DAYS || 10) * DAY_MS,
        },
    };
}

export const handler = async () => {
    const { poolId, usernames, parameter, limits } = settings(process.env);
    const idp = await import("@aws-sdk/client-cognito-identity-provider");
    const { SSMClient, GetParameterCommand } = await import("@aws-sdk/client-ssm");
    const client = new idp.CognitoIdentityProviderClient({});
    const { Parameter } = await new SSMClient({}).send(new GetParameterCommand({ Name: parameter, WithDecryption: true }));
    const password = Parameter.Value;
    const cognito = {
        async getUser(Username) {
            try {
                return await client.send(new idp.AdminGetUserCommand({ UserPoolId: poolId, Username }));
            } catch (error) {
                if (error && error.name === "UserNotFoundException") {
                    return null;
                }
                throw error;
            }
        },
        createUser: (Username) => client.send(new idp.AdminCreateUserCommand({
            UserPoolId: poolId, Username, TemporaryPassword: password, MessageAction: "SUPPRESS",
        })),
        async deleteUser(Username) {
            try {
                await client.send(new idp.AdminDeleteUserCommand({ UserPoolId: poolId, Username }));
            } catch (error) {
                if (!(error && error.name === "UserNotFoundException")) {
                    throw error;
                }
            }
        },
        setTemporaryPassword: (Username) => client.send(new idp.AdminSetUserPasswordCommand({
            UserPoolId: poolId, Username, Password: password, Permanent: false,
        })),
    };
    const states = await resetAll(cognito, usernames, Date.now(), limits);
    console.log(JSON.stringify(states));
    return states;
};
