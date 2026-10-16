//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Tests the new-password reset's decisions over a fake Cognito, with no AWS SDK and no AWS call:
//
//   node --test infra/ci/lambda/new-password-reset/test_new_password_reset.mjs

import assert from "node:assert/strict";
import test from "node:test";
import { decide, resetAll, settings } from "./index.mjs";

const MINUTE = 60 * 1000;
const DAY = 24 * 60 * MINUTE;
const NOW = Date.parse("2026-10-05T12:00:00Z");
const LIMITS = { usedAfterMs: 60 * MINUTE, refreshAfterMs: 10 * DAY };

const user = (status, ageMs, attributes = []) => ({
    UserStatus: status,
    UserLastModifiedDate: new Date(NOW - ageMs).toISOString(),
    UserAttributes: attributes.map((Name) => ({ Name, Value: "x" })),
});

test("a missing user is created", () => {
    assert.equal(decide(null, NOW, LIMITS), "create");
});

test("a waiting user is left alone until its temporary password is due a refresh", () => {
    assert.equal(decide(user("FORCE_CHANGE_PASSWORD", DAY), NOW, LIMITS), "ready");
    assert.equal(decide(user("FORCE_CHANGE_PASSWORD", 10 * DAY), NOW, LIMITS), "refresh");
});

test("a used user is recreated only after it has been left alone for a while", () => {
    assert.equal(decide(user("CONFIRMED", 5 * MINUTE), NOW, LIMITS), "in-use");
    assert.equal(decide(user("CONFIRMED", 61 * MINUTE), NOW, LIMITS), "recreate");
});

test("a user given an email or a phone number counts as used, whatever its status", () => {
    assert.equal(decide(user("FORCE_CHANGE_PASSWORD", 2 * DAY, ["email"]), NOW, LIMITS), "recreate");
    assert.equal(decide(user("FORCE_CHANGE_PASSWORD", 2 * DAY, ["phone_number"]), NOW, LIMITS), "recreate");
    assert.equal(decide(user("FORCE_CHANGE_PASSWORD", MINUTE, ["email"]), NOW, LIMITS), "in-use");
});

test("resetAll acts on each user once, and tolerates another invocation creating one first", async () => {
    const users = {
        ready: user("FORCE_CHANGE_PASSWORD", DAY),
        used: user("CONFIRMED", 2 * 60 * MINUTE),
        busy: user("CONFIRMED", MINUTE),
        old: user("FORCE_CHANGE_PASSWORD", 11 * DAY),
    };
    const calls = [];
    const cognito = {
        getUser: async (name) => users[name] || null,
        createUser: async (name) => {
            calls.push(`create ${name}`);
            if (name === "raced") {
                const error = new Error("exists");
                error.name = "UsernameExistsException";
                throw error;
            }
        },
        deleteUser: async (name) => calls.push(`delete ${name}`),
        setTemporaryPassword: async (name) => calls.push(`refresh ${name}`),
    };
    const states = await resetAll(cognito, ["ready", "used", "busy", "old", "missing", "raced"], NOW, LIMITS);
    assert.deepEqual(states, {
        ready: "ready",
        used: "recreated",
        busy: "in-use",
        old: "refreshed",
        missing: "created",
        raced: "created by another run",
    });
    assert.deepEqual(calls, ["delete used", "create used", "refresh old", "create missing", "create raced"]);
});

test("any other create error fails the run", async () => {
    const cognito = {
        getUser: async () => null,
        createUser: async () => {
            throw Object.assign(new Error("throttled"), { name: "TooManyRequestsException" });
        },
    };
    await assert.rejects(resetAll(cognito, ["a"], NOW, LIMITS), /throttled/);
});

test("settings need the pool, the users and the parameter, and default the limits", () => {
    assert.throws(() => settings({}), /must be set/);
    const parsed = settings({ POOL_ID: "p", USERNAMES: "a, b,,", TEMP_PASSWORD_PARAMETER: "/x" });
    assert.deepEqual(parsed.usernames, ["a", "b"]);
    assert.equal(parsed.limits.usedAfterMs, 60 * MINUTE);
    assert.equal(parsed.limits.refreshAfterMs, 10 * DAY);
});
