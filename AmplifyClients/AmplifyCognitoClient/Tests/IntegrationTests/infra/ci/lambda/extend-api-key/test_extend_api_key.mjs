//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Tests the code sink key's extension over a fake AppSync, with no AWS SDK and no AWS call:
//
//   node --test infra/ci/lambda/extend-api-key/test_extend_api_key.mjs

import assert from "node:assert/strict";
import test from "node:test";
import { DESCRIPTION, day, extendedExpiry, plan, run, settings } from "./index.mjs";

const DAY = 24 * 60 * 60;
// One minute past an hour, so the rounding down shows.
const NOW = Date.parse("2026-10-05T12:01:00Z") / 1000;
const LIMITS = { days: 365, allowanceSeconds: 600, extendWithinDays: 120 };
const EXTENDED = extendedExpiry(NOW, LIMITS);

const key = (id, expires, extra = {}) => ({ id, description: DESCRIPTION, expires, ...extra });

// A fake AppSync over `keys`: update() sets a key's expiry, or throws `refusal` (an error name) when it is given.
function fakeAppSync(keys, refusal) {
    const updates = [];
    return {
        updates,
        listKeys: async () => structuredClone(keys),
        update: async (id, expires) => {
            updates.push({ id, expires });
            if (refusal) {
                throw Object.assign(new Error("refused"), { name: refusal });
            }
        },
    };
}

// Runs `body` with console.log captured; returns its result and the lines logged.
async function logged(body) {
    const lines = [];
    const original = console.log;
    console.log = (line) => lines.push(line);
    try {
        return { result: await body(), lines };
    } finally {
        console.log = original;
    }
}

test("the extension asks for 365 days from now, less the allowance, rounded down to the hour", () => {
    assert.equal(EXTENDED, Date.parse("2027-10-05T11:00:00Z") / 1000);
    assert.equal(EXTENDED % 3600, 0);
    assert.ok(EXTENDED <= NOW + 365 * DAY - 600 && EXTENDED > NOW + 365 * DAY - 600 - 3600);
});

test("a key with more than 120 days left is kept; one with 120 or fewer is extended, at the edge too", () => {
    assert.equal(plan([key("a", NOW + 120 * DAY + 1)], NOW, LIMITS).action, "keep");
    assert.deepEqual(plan([key("a", NOW + 120 * DAY)], NOW, LIMITS),
        { action: "extend", id: "a", from: NOW + 120 * DAY, expires: EXTENDED });
    assert.equal(plan([key("a", NOW + 1)], NOW, LIMITS).action, "extend");
});

test("an expired key AppSync still keeps is extended; one past its deletion, or another key, is not a candidate", () => {
    assert.equal(plan([key("a", NOW)], NOW, LIMITS).action, "extend-expired");
    assert.equal(plan([key("a", NOW - 59 * DAY)], NOW, LIMITS).action, "extend-expired");
    assert.equal(plan([key("a", NOW - 61 * DAY)], NOW, LIMITS).action, "none");
    assert.equal(plan([key("a", NOW - DAY, { deletes: NOW - 1 })], NOW, LIMITS).action, "none");
    assert.equal(plan([key("a", NOW - DAY, { deletes: NOW + DAY })], NOW, LIMITS).action, "extend-expired");
    assert.equal(plan([{ id: "b", description: "another team's", expires: NOW + DAY }], NOW, LIMITS).action, "none");
    assert.equal(plan([], NOW, LIMITS).action, "none");
});

test("of several tests' keys, the one that expires last is the one decided on, as provision-ci.sh picks it", () => {
    const keys = [key("old", NOW - DAY), key("new", NOW + 30 * DAY), key("older", NOW - 2 * DAY)];
    assert.deepEqual(plan(keys, NOW, LIMITS), { action: "extend", id: "new", from: NOW + 30 * DAY, expires: EXTENDED });
    assert.equal(plan([key("old", NOW - DAY), key("new", NOW + 200 * DAY)], NOW, LIMITS).action, "keep");
});

test("run extends a key that is due, in place, and logs the dates only", async () => {
    const appsync = fakeAppSync([key("da2-secret", NOW + 10 * DAY)]);
    const { result, lines } = await logged(() => run(appsync, NOW, LIMITS));
    assert.deepEqual(appsync.updates, [{ id: "da2-secret", expires: EXTENDED }]);
    assert.deepEqual(result, { action: "extended", expires: "2027-10-05" });
    assert.deepEqual(lines, [`Extended the tests' API key from ${day(NOW + 10 * DAY)} to 2027-10-05.`]);
    assert.ok(!lines.join("\n").includes("da2-secret"));
});

test("run keeps a key that is not due, with no update", async () => {
    const appsync = fakeAppSync([key("da2-secret", NOW + 200 * DAY)]);
    const { result, lines } = await logged(() => run(appsync, NOW, LIMITS));
    assert.deepEqual(appsync.updates, []);
    assert.equal(result.action, "kept");
    assert.ok(lines[0].endsWith("more than 120 days from now: kept.") && !lines[0].includes("da2-secret"));
});

test("run extends an expired key when AppSync takes it, and fails with the rerun when AppSync refuses", async () => {
    const taken = fakeAppSync([key("da2-secret", NOW - DAY)]);
    const { result, lines } = await logged(() => run(taken, NOW, LIMITS));
    assert.deepEqual(taken.updates, [{ id: "da2-secret", expires: EXTENDED }]);
    assert.equal(result.action, "extended-expired");
    assert.ok(lines[0].includes(", which had expired, from"));
    const refused = fakeAppSync([key("da2-secret", NOW - DAY)], "BadRequestException");
    await assert.rejects(run(refused, NOW, LIMITS), (error) => {
        assert.match(error.message, /refused to extend .* \(BadRequestException\)\. Run infra\/ci\/provision-ci\.sh --apply --scope all/);
        assert.ok(!error.message.includes("da2-secret"));
        return true;
    });
});

test("run fails when no key is left, and passes on any refusal of a key that has not expired", async () => {
    await assert.rejects(run(fakeAppSync([]), NOW, LIMITS), /No "ccit-ci tests" API key is left to extend/);
    await assert.rejects(run(fakeAppSync([key("a", NOW + DAY)], "AccessDeniedException"), NOW, LIMITS),
        (error) => error.name === "AccessDeniedException");
});

test("settings need the API, default the limits as provision-ci.sh sets them, and refuse others", () => {
    assert.throws(() => settings({}), /API_ID must be set/);
    assert.deepEqual(settings({ API_ID: "api" }), { apiId: "api", limits: LIMITS });
    assert.deepEqual(settings({ API_ID: "api", KEY_DAYS: "365", CLOCK_ALLOWANCE_SECONDS: "600",
        EXTEND_WITHIN_DAYS: "120" }).limits, LIMITS);
    assert.throws(() => settings({ API_ID: "api", KEY_DAYS: "366" }), /KEY_DAYS must be a whole number/);
    assert.throws(() => settings({ API_ID: "api", EXTEND_WITHIN_DAYS: "1.5" }), /EXTEND_WITHIN_DAYS/);
});
