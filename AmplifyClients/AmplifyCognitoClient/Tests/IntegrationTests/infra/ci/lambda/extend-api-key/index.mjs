//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Keeps the code sink's read-only API key (infra/ci/provision-ci.sh, the "ccit-ci tests" key of the ccit-ci-codes
// AppSync API) from expiring. Run once a week by an EventBridge rule. It picks the key a rerun of provision-ci.sh
// would pick, the one that expires last, and, once it has EXTEND_WITHIN_DAYS or fewer left, extends it in place to
// KEY_DAYS days from now (AppSync's maximum is 365), rounded down to the hour after CLOCK_ALLOWANCE_SECONDS, as
// provision-ci.sh does. The key keeps its id, so the uploaded files that name it stay valid.
//
// An expired key that AppSync has not deleted yet (it keeps one for 60 days) is extended the same way. When AppSync
// refuses that, or no key is found, the invocation fails, with what to run in the log: provision-ci.sh makes a new
// key, which this function cannot (its role may only list and update keys).
//
// Logs dates only, never the key, whose id is its secret. The AWS SDK is the one the Node.js runtime ships, loaded
// only by the handler, so the logic below can be tested with no SDK installed (test_extend_api_key.mjs).

export const DESCRIPTION = "ccit-ci tests";
const DAY_SECONDS = 24 * 60 * 60;
// How long AppSync keeps a key after it expires, when ListApiKeys gives no `deletes`.
const KEPT_AFTER_EXPIRY_SECONDS = 60 * DAY_SECONDS;

/// The expiry, in seconds since the epoch, that an extension at `now` asks for.
export function extendedExpiry(now, { days, allowanceSeconds }) {
    return Math.floor((now + days * DAY_SECONDS - allowanceSeconds) / 3600) * 3600;
}

/// What to do with the tests' key, from ListApiKeys's keys and `now` (seconds since the epoch): `none` (no key to
/// extend), `keep`, `extend` or `extend-expired`, with the key's id and its expiry before and after.
export function plan(keys, now, limits) {
    const candidates = keys.filter((key) => key.description === DESCRIPTION
        && (key.deletes ?? key.expires + KEPT_AFTER_EXPIRY_SECONDS) > now);
    if (candidates.length === 0) {
        return { action: "none" };
    }
    const key = candidates.reduce((last, next) => (next.expires > last.expires ? next : last));
    if (key.expires > now + limits.extendWithinDays * DAY_SECONDS) {
        return { action: "keep", id: key.id, expires: key.expires };
    }
    return {
        action: key.expires > now ? "extend" : "extend-expired",
        id: key.id,
        from: key.expires,
        expires: extendedExpiry(now, limits),
    };
}

/// A date, as the log names it.
export function day(seconds) {
    return new Date(seconds * 1000).toISOString().slice(0, 10);
}

const RERUN = "Run infra/ci/provision-ci.sh --apply --scope all, which makes a new key, and replace the uploaded "
    + "files that name the old one, as it says.";

/// Lists the keys and extends the tests' key when it is due, on `appsync`, an object with listKeys() and
/// update(id, expires). Returns what was done; throws when nothing could keep the key alive.
export async function run(appsync, now, limits) {
    const step = plan(await appsync.listKeys(), now, limits);
    switch (step.action) {
    case "none":
        throw new Error(`No "${DESCRIPTION}" API key is left to extend. ${RERUN}`);
    case "keep":
        console.log(`The tests' API key expires on ${day(step.expires)}, more than ${limits.extendWithinDays} days `
            + "from now: kept.");
        return { action: "kept", expires: day(step.expires) };
    default:
        try {
            await appsync.update(step.id, step.expires);
        } catch (error) {
            if (step.action === "extend-expired") {
                throw new Error(`AppSync refused to extend the tests' API key, which expired on ${day(step.from)} `
                    + `(${(error && error.name) || "error"}). ${RERUN}`);
            }
            // A fixed text with the error's name only, never the SDK's message, which Lambda would log with its stack.
            throw new Error(`AppSync refused to extend the tests' API key, which expires on ${day(step.from)} `
                + `(${(error && error.name) || "error"}). The key is unchanged: a rerun of infra/ci/provision-ci.sh `
                + "--apply --scope all extends it in place.");
        }
        console.log(`Extended the tests' API key${step.action === "extend-expired" ? ", which had expired," : ""} `
            + `from ${day(step.from)} to ${day(step.expires)}.`);
        return { action: step.action === "extend" ? "extended" : "extended-expired", expires: day(step.expires) };
    }
}

/// A whole number from the environment, within [min, max].
function whole(environment, name, fallback, min, max) {
    const text = environment[name] ?? String(fallback);
    const value = Number(text);
    if (!/^[0-9]+$/.test(text) || value < min || value > max) {
        throw new Error(`${name} must be a whole number from ${min} to ${max}`);
    }
    return value;
}

/// The settings, from the function's environment.
export function settings(environment) {
    if (!environment.API_ID) {
        throw new Error("API_ID must be set");
    }
    return {
        apiId: environment.API_ID,
        limits: {
            days: whole(environment, "KEY_DAYS", 365, 2, 365),
            allowanceSeconds: whole(environment, "CLOCK_ALLOWANCE_SECONDS", 600, 0, 3600),
            extendWithinDays: whole(environment, "EXTEND_WITHIN_DAYS", 120, 1, 364),
        },
    };
}

export const handler = async () => {
    const { apiId, limits } = settings(process.env);
    const { AppSyncClient, ListApiKeysCommand, UpdateApiKeyCommand } = await import("@aws-sdk/client-appsync");
    const client = new AppSyncClient({});
    const appsync = {
        async listKeys() {
            const keys = [];
            let nextToken;
            do {
                const page = await client.send(new ListApiKeysCommand({ apiId, nextToken }));
                keys.push(...(page.apiKeys || []));
                nextToken = page.nextToken;
            } while (nextToken);
            return keys;
        },
        update: (id, expires) => client.send(new UpdateApiKeyCommand({ apiId, id, expires })),
    };
    return run(appsync, Math.floor(Date.now() / 1000), limits);
};
