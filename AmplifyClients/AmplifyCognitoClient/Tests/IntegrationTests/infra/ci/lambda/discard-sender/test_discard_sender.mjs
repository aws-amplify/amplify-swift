//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// node --test infra/ci/lambda/discard-sender/test_discard_sender.mjs

import assert from "node:assert/strict";
import test from "node:test";
import { handler } from "./index.mjs";

test("every message is returned unchanged, and nothing but the trigger source is logged", async () => {
    const logged = [];
    const original = console.log;
    console.log = (line) => logged.push(line);
    try {
        const event = { triggerSource: "CustomEmailSender_SignUp", request: { code: "c2VjcmV0" }, userName: "u" };
        assert.deepEqual(await handler(structuredClone(event)), event);
    } finally {
        console.log = original;
    }
    assert.deepEqual(logged, ["Discarded CustomEmailSender_SignUp"]);
});
