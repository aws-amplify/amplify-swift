//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests (the hosted-UI UI tests), which compiles this file and the five other
// shared sandbox helpers (IntegrationTestEnvironment, SandboxPools, SandboxSignUp, SandboxUserCleanup,
// CodeSink, TOTP) and nothing else from this folder. Keep it self-contained: it may use only those files,
// AmplifyCognitoClient, AWSCognitoIdentityProvider, Foundation, Security, CryptoKit and XCTest.

import CryptoKit
import Foundation

/// RFC 6238 time-based one-time passwords, as Cognito's software-token MFA computes them: HMAC-SHA1,
/// 30-second steps, 6 digits. `infra/enroll_totp.py` uses the same algorithm to enroll carol.
enum TOTP {

    static let stepSeconds: TimeInterval = 30

    /// The code for `secret` in the step containing `date`.
    static func code(secret: TOTPSecret, at date: Date) throws -> String {
        try code(secret: secret, step: step(at: date))
    }

    /// The 30-second step `date` falls in.
    static func step(at date: Date) -> UInt64 {
        UInt64(date.timeIntervalSince1970 / stepSeconds)
    }

    /// The code for `secret` in `step`.
    static func code(secret: TOTPSecret, step: UInt64) throws -> String {
        guard let key = base32Decode(secret.base32) else {
            throw HarnessError.malformedFixture("carolTotpSecret is not base32.")
        }
        let counter = withUnsafeBytes(of: step.bigEndian) { Data($0) }
        let digest = Array(HMAC<Insecure.SHA1>.authenticationCode(for: counter, using: SymmetricKey(data: key)))
        let offset = Int(digest[digest.count - 1] & 0x0f)
        let truncated = (UInt32(digest[offset]) & 0x7f) << 24
            | UInt32(digest[offset + 1]) << 16
            | UInt32(digest[offset + 2]) << 8
            | UInt32(digest[offset + 3])
        return String(format: "%06u", truncated % 1_000_000)
    }

    /// A six-digit code that none of the steps Cognito accepts around now (the current one and one on
    /// either side, with a margin) produces for `secret`: a wrong code that cannot be right by chance.
    static func wrongCode(secret: TOTPSecret) throws -> String {
        let step = Self.step(at: Date())
        let accepted = try Set((step - 2 ... step + 2).map { try code(secret: secret, step: $0) })
        let current = try code(secret: secret, step: step)
        var candidate = (Int(current) ?? 0) + 1
        while accepted.contains(String(format: "%06d", candidate % 1_000_000)) {
            candidate += 1
        }
        return String(format: "%06d", candidate % 1_000_000)
    }

    /// A code from a step no earlier call has used, in this run or a recent one. Cognito rejects a code
    /// whose step has already been accepted, so a test that needs a code waits here for the next step
    /// if the current one is spent. Waits at most one step.
    ///
    /// The last step used is kept in the host app's defaults, which survive between runs on one
    /// simulator, so two runs started within 30 seconds of each other do not reuse a step either.
    static func freshCode(secret: TOTPSecret) async throws -> String {
        try await sharedSource.freshCode(secret: secret)
    }

    private static let sharedSource = FreshCodeSource(lastStepStore: .hostAppDefaults)

    /// Where `FreshCodeSource` keeps the last step it handed out.
    struct LastStepStore: Sendable {
        let load: @Sendable () -> UInt64?
        let save: @Sendable (UInt64) -> Void

        static let inMemoryOnly = LastStepStore(load: { nil }, save: { _ in })

        static let hostAppDefaults: LastStepStore = {
            let key = "CognitoClientIntegrationTests.lastTOTPStep"
            return LastStepStore(
                load: { (UserDefaults.standard.object(forKey: key) as? NSNumber)?.uint64Value },
                save: { UserDefaults.standard.set(NSNumber(value: $0), forKey: key) }
            )
        }()
    }

    /// Hands out codes from strictly increasing steps. The clock, the sleep and the store are
    /// injectable so the rule can be tested without waiting.
    actor FreshCodeSource {
        private let now: @Sendable () -> Date
        private let sleep: @Sendable (TimeInterval) async throws -> Void
        private let lastStepStore: LastStepStore
        private var lastStep: UInt64?

        init(
            now: @escaping @Sendable () -> Date = { Date() },
            sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { seconds in
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            },
            lastStepStore: LastStepStore = .inMemoryOnly
        ) {
            self.now = now
            self.sleep = sleep
            self.lastStepStore = lastStepStore
            self.lastStep = lastStepStore.load()
        }

        func freshCode(secret: TOTPSecret) async throws -> String {
            var date = now()
            // A stored step ahead of the clock (the clock moved back, or the value is bad) is clamped
            // to the current step: it cannot be waited out, and treating the current step as spent is
            // the safe reading.
            if let stored = lastStep, stored > TOTP.step(at: date) {
                lastStep = TOTP.step(at: date)
            }
            if let lastStep, TOTP.step(at: date) <= lastStep {
                let nextStepStart = TimeInterval(lastStep + 1) * TOTP.stepSeconds
                try await sleep(max(0, nextStepStart - date.timeIntervalSince1970) + 0.5)
                date = now()
            }
            let step = TOTP.step(at: date)
            guard lastStep.map({ step > $0 }) ?? true else {
                throw HarnessError.timedOut("a TOTP step later than \(step)")
            }
            lastStep = step
            lastStepStore.save(step)
            return try TOTP.code(secret: secret, step: step)
        }
    }

    /// RFC 4648 base32, case-insensitive, padding optional.
    static func base32Decode(_ string: String) -> Data? {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var buffer: UInt32 = 0
        var bits = 0
        var output = Data()
        for character in string.uppercased() where character != "=" {
            guard let index = alphabet.firstIndex(of: character) else {
                return nil
            }
            buffer = (buffer << 5) | UInt32(index)
            bits += 5
            if bits >= 8 {
                bits -= 8
                output.append(UInt8((buffer >> UInt32(bits)) & 0xff))
            }
        }
        return output
    }
}
