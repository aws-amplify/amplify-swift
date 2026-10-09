//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// The custom email and SMS sender for the parity pools (P-5c). It is the plugin's
// integration-backend mechanism (AuthHostApp/AuthIntegrationTests/MFATests/EmailMFATests/README.md,
// steps 6-8): Cognito hands the Lambda a KMS-encrypted code instead of sending a message, the Lambda
// decrypts it with the AWS Encryption SDK and publishes it with the `createMfaInfo` mutation to an
// AppSync API backed by DynamoDB. The plugin's tests read it through an AppSync subscription; the
// client's tests, which cannot link AWSAPIPlugin, read it with a plain HTTPS `listMfaInfo` query.
//
// Differences from the plugin's handlers: one function serves both senders; the mutation is signed
// with the function's role (AWS_IAM; the API key can only read, and the function never holds it);
// the username is stored lower-cased (the plugin lower-cases when it reads); codes expire from the
// sink after 10 minutes; and neither the event nor the code is logged. Nothing is ever delivered.

import { createHash, createHmac } from "node:crypto";
import { buildClient, CommitmentPolicy, KmsKeyringNode } from "@aws-crypto/client-node";
import { SignatureV4 } from "@smithy/signature-v4";

const { decrypt } = buildClient(CommitmentPolicy.FORBID_ENCRYPT_ALLOW_DECRYPT);
const keyring = new KmsKeyringNode({ keyIds: [process.env.KMS_KEY_ARN] });
const endpoint = new URL(process.env.GRAPHQL_API_ENDPOINT);
const EXPIRATION_SECONDS = 10 * 60;

// Trigger sources that carry no code a test could use.
const IGNORED = new Set([
    "CustomEmailSender_AdminCreateUser",
    "CustomEmailSender_AccountTakeOverNotification",
    "CustomSMSSender_AdminCreateUser",
]);

// The selection set is what `onCreateMfaInfo` subscribers receive (AppSync forwards only the fields the
// mutation selected), so it names every field the plugin's subscription reads.
const MUTATION = `
mutation CreateMfaInfo($username: String!, $code: String!, $expirationTime: AWSTimestamp!) {
    createMfaInfo(input: { username: $username, code: $code, expirationTime: $expirationTime }) {
        username
        code
        expirationTime
    }
}`;

// SHA-256 for the signer, from Node's crypto (what @smithy/hash-node does).
class Sha256 {
    constructor(secret) {
        this.hash = secret ? createHmac("sha256", Buffer.from(secret)) : createHash("sha256");
    }
    update(data) {
        this.hash.update(typeof data === "string" ? data : Buffer.from(data));
    }
    async digest() {
        return new Uint8Array(this.hash.digest());
    }
}

const signer = new SignatureV4({
    service: "appsync",
    region: process.env.AWS_REGION,
    sha256: Sha256,
    credentials: async () => ({
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        sessionToken: process.env.AWS_SESSION_TOKEN,
    }),
});

async function publish(username, code) {
    const body = JSON.stringify({
        query: MUTATION,
        variables: { username, code, expirationTime: Math.floor(Date.now() / 1000) + EXPIRATION_SECONDS },
    });
    const signed = await signer.sign({
        method: "POST",
        protocol: "https:",
        hostname: endpoint.hostname,
        path: endpoint.pathname,
        headers: { host: endpoint.hostname, "content-type": "application/json" },
        body,
    });
    return fetch(endpoint, { method: "POST", headers: signed.headers, body });
}

export const handler = async (event) => {
    const source = event.triggerSource;
    const encrypted = event.request && event.request.code;
    if (IGNORED.has(source) || !encrypted) {
        console.log(`Skipping ${source}`);
        return event;
    }
    const { plaintext, messageHeader } = await decrypt(keyring, Buffer.from(encrypted, "base64"));
    // Cognito binds each code to its pool through the encryption context. Accept only a code encrypted
    // for the pool that invoked this trigger (the role's kms:Decrypt is limited to the parity pools).
    if ((messageHeader.encryptionContext || {})["userpool-id"] !== event.userPoolId) {
        throw new Error(`Rejected ${source}: the code was not encrypted for this user pool`);
    }
    const response = await publish(String(event.userName).toLowerCase(), plaintext.toString("ascii"));
    const result = await response.json().catch(() => ({}));
    if (!response.ok || result.errors) {
        // Fail the trigger, so a broken sink surfaces as a Cognito error rather than a missing code.
        throw new Error(`Code sink rejected ${source}: HTTP ${response.status}`);
    }
    console.log(`Stored the code for ${source}`);
    return event;
};
