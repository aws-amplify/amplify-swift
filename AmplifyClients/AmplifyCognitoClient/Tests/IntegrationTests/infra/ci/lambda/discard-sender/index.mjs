//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// The custom email and SMS sender of infra/ci's device-alias pool (ccit-ci-email-alias). Cognito hands it every
// message it would send, with the code encrypted, and it discards them: nothing is sent, so no CI run on that pool
// can reach the account's daily email limit. No test there reads a code (its pre-sign-up trigger confirms every
// accepted sign-up and refuses ccit-confirm- users), so it needs no code sink and no decrypt permission. It logs the
// trigger source only, never the event.
export const handler = async (event) => {
    console.log(`Discarded ${event.triggerSource}`);
    return event;
};
