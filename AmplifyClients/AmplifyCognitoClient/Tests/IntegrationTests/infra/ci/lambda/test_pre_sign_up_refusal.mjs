//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// The pre-sign-up trigger's REFUSE_CONFIRMATION_USERS option (infra/ci's pools), with the sandbox's behaviour
// unchanged without it:
//
//   node --test infra/ci/lambda/test_pre_sign_up_refusal.mjs

import assert from "node:assert/strict";
import test from "node:test";
import { preSignUp } from "../../lambda/triggers/triggers.mjs";

const event = (userName, email) => ({
    userName,
    userPoolId: "us-east-1_placeholder",
    request: { userAttributes: email ? { email } : {} },
    response: {},
});

test("with the option, a ccit-confirm- user is refused, by username or, on the email-alias pool, by email", async () => {
    process.env.REFUSE_CONFIRMATION_USERS = "1";
    try {
        await assert.rejects(preSignUp(event("ccit-confirm-0123456789ab")), /need confirmation is refused/);
        await assert.rejects(preSignUp(event("00000000-0000-4000-8000-000000000000",
            "ccit-confirm-0123456789ab@example.com")), /need confirmation is refused/);
        const plain = await preSignUp(event("00000000-0000-4000-8000-000000000000", "ccit-0123456789ab@example.com"));
        assert.equal(plain.response.autoConfirmUser, true);
        assert.equal(plain.response.autoVerifyEmail, true);
        await assert.rejects(preSignUp(event("outsider-0123456789ab")), /limited to integration-test users/);
    } finally {
        delete process.env.REFUSE_CONFIRMATION_USERS;
    }
});

test("without it, as on the sandbox, a ccit-confirm- user is left unconfirmed", async () => {
    const result = await preSignUp(event("ccit-confirm-0123456789ab"));
    assert.notEqual(result.response.autoConfirmUser, true);
});
