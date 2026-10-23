//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The challenge record's stored format, pinned the way the plugin's stored-format goldens pin the engine's: literal bytes for each
/// shape, a throwing decode of frozen fixtures with field-by-field expectations, key order that does not matter, and
/// the newer-schema and corrupt cases told apart. Changing any expectation here changes what is on users' devices.
final class ChallengeRecordFormatTests: XCTestCase {

    private let createdAt = Date(timeIntervalSince1970: 1_790_000_000.123)

    private let smsChallenge = ChallengeRecord.Challenge(
        challengeName: "SMS_MFA",
        availableChallenges: [],
        username: "alice",
        inputUsername: "alice@example.com",
        session: "session-1",
        parameters: ["CODE_DELIVERY_DELIVERY_MEDIUM": "SMS", "CODE_DELIVERY_DESTINATION": "+1***"],
        signInMethod: .init(authFlow: "userSRP"),
        step: .init(
            kind: .confirmSignInWithSMSMFACode,
            codeDelivery: .init(medium: "sms", destination: "+1***", attributeKey: "phone_number")
        )
    )

    private let totpSetup = ChallengeRecord.TOTPSetup(
        secretCode: "SECRET",
        session: "setup-session",
        username: "alice",
        signInUsername: "alice",
        signInMethod: .init(authFlow: "userAuth", preferredFirstFactor: "PASSWORD_SRP")
    )

    /// The challenge shape's bytes, frozen.
    static let challengeJSON =
        #"{"challenge":{"availableChallenges":[],"challengeName":"SMS_MFA","inputUsername":"alice@example.com","# +
        #""parameters":{"CODE_DELIVERY_DELIVERY_MEDIUM":"SMS","CODE_DELIVERY_DESTINATION":"+1***"},"# +
        #""session":"session-1","signInMethod":{"authFlow":"userSRP"},"# +
        #""step":{"codeDelivery":{"attributeKey":"phone_number","destination":"+1***","medium":"sms"},"# +
        #""kind":"confirmSignInWithSMSMFACode"},"username":"alice"},"createdAt":1790000000123,"schemaVersion":1}"#

    /// The TOTP setup shape's bytes, frozen.
    static let totpSetupJSON =
        #"{"createdAt":1790000000123,"schemaVersion":1,"totpSetup":{"secretCode":"SECRET","session":"setup-session","# +
        #""signInMethod":{"authFlow":"userAuth","preferredFirstFactor":"PASSWORD_SRP"},"signInUsername":"alice","# +
        #""username":"alice"}}"#

    // MARK: Frozen bytes

    /// - Given: a record of each shape, every field set
    /// - When: it is encoded
    /// - Then:
    ///    - the bytes are exactly the frozen JSON: sorted keys, literal key and kind spellings, `createdAt` as integer
    ///      milliseconds since 1970, and exactly one of `challenge` and `totpSetup`
    func testEncodingIsTheFrozenJSON() throws {
        let challenge = try ChallengeRecord(createdAt: createdAt, state: .challenge(smsChallenge)).encoded()
        let setup = try ChallengeRecord(createdAt: createdAt, state: .totpSetup(totpSetup)).encoded()

        XCTAssertEqual(String(decoding: challenge, as: UTF8.self), Self.challengeJSON)
        XCTAssertEqual(String(decoding: setup, as: UTF8.self), Self.totpSetupJSON)
    }

    /// - Given: the frozen bytes of each shape
    /// - When: they are decoded
    /// - Then:
    ///    - every field reads back as written, the timestamp at millisecond precision
    func testTheFrozenBytesDecodeFieldByField() throws {
        guard case .record(let challenge) = ChallengeRecord.decode(Data(Self.challengeJSON.utf8)),
              case .record(let setup) = ChallengeRecord.decode(Data(Self.totpSetupJSON.utf8)) else {
            return XCTFail("the frozen fixtures must decode")
        }

        XCTAssertEqual(challenge.createdAt.timeIntervalSince1970, 1_790_000_000.123, accuracy: 0.000_5)
        XCTAssertEqual(challenge.state, .challenge(smsChallenge))
        XCTAssertEqual(setup.state, .totpSetup(totpSetup))
        XCTAssertEqual(challenge.state.session, "session-1")
        XCTAssertEqual(setup.state.session, "setup-session")
    }

    /// - Given: the challenge shape with its keys in reverse order, and with no optional field
    /// - When: they are decoded
    /// - Then:
    ///    - the permuted one reads as the frozen one: key order is not part of the format
    ///    - the minimal one reads with every optional field `nil`
    func testKeyOrderAndOptionalFieldsDoNotMatter() throws {
        let permuted = Data(#"""
        {"schemaVersion":1,"createdAt":1790000000123,"challenge":{"username":"alice","step":{"kind":"confirmSignInWithSMSMFACode",
        "codeDelivery":{"medium":"sms","destination":"+1***","attributeKey":"phone_number"}},"signInMethod":{"authFlow":"userSRP"},
        "session":"session-1","parameters":{"CODE_DELIVERY_DESTINATION":"+1***","CODE_DELIVERY_DELIVERY_MEDIUM":"SMS"},
        "inputUsername":"alice@example.com","challengeName":"SMS_MFA","availableChallenges":[]}}
        """#.utf8)
        let minimal = Data(#"""
        {"schemaVersion":1,"createdAt":0,"challenge":{"challengeName":"SOFTWARE_TOKEN_MFA","availableChallenges":[],
        "username":"bob","signInMethod":{"authFlow":"customWithSRP"},"step":{"kind":"confirmSignInWithTOTPCode"}}}
        """#.utf8)

        XCTAssertEqual(ChallengeRecord.decode(permuted), ChallengeRecord.decode(Data(Self.challengeJSON.utf8)))
        guard case .record(let record) = ChallengeRecord.decode(minimal),
              case .challenge(let challenge) = record.state else {
            return XCTFail("a record without optional fields must decode")
        }
        XCTAssertNil(challenge.session)
        XCTAssertNil(challenge.inputUsername)
        XCTAssertNil(challenge.parameters)
        XCTAssertEqual(challenge.step, .init(kind: .confirmSignInWithTOTPCode))
    }

    /// The step kinds are spelled as `AuthClientSignInStep`'s cases, frozen.
    ///
    /// - Given: every step kind
    /// - When: its raw value is read
    /// - Then:
    ///    - it is the frozen spelling, and the set is exactly the answerable steps
    func testStepKindSpellingsAreFrozen() {
        XCTAssertEqual(ChallengeRecord.Step.Kind.allCases.map(\.rawValue), [
            "confirmSignInWithSMSMFACode",
            "confirmSignInWithCustomChallenge",
            "confirmSignInWithNewPassword",
            "confirmSignInWithPassword",
            "confirmSignInWithTOTPCode",
            "continueSignInWithMFASelection",
            "continueSignInWithEmailMFASetup",
            "continueSignInWithMFASetupSelection",
            "confirmSignInWithOTP",
            "continueSignInWithFirstFactorSelection"
        ])
    }

    // MARK: Newer and corrupt

    /// - Given: a well-formed record of schema 2, carrying fields this build cannot read
    /// - When: it is decoded
    /// - Then:
    ///    - it is `.unsupportedSchema(version: 2)`, not corrupt
    func testANewerSchemaIsToldApartFromCorrupt() {
        let newer = Data(#"{"schemaVersion":2,"createdAt":"later","passkey":{"new":true}}"#.utf8)

        XCTAssertEqual(ChallengeRecord.decode(newer), .unsupportedSchema(version: 2))
    }

    /// - Given: bytes that are not a record, a version below 1, both shapes at once, neither shape, and a step kind
    ///   this schema does not define
    /// - When: they are decoded
    /// - Then:
    ///    - each is `.corrupt`
    func testMalformedRecordsAreCorrupt() {
        let cases = [
            "not json",
            #"{"schemaVersion":0,"createdAt":1,"challenge":{}}"#,
            #"{"createdAt":1}"#,
            #"{"schemaVersion":1,"createdAt":1}"#,
            #"{"schemaVersion":1,"createdAt":1,"challenge":\#(Self.challengeBody),"totpSetup":\#(Self.setupBody)}"#,
            #"{"schemaVersion":1,"createdAt":1,"challenge":{"challengeName":"X","availableChallenges":[],"username":"u","# +
                #""signInMethod":{"authFlow":"userSRP"},"step":{"kind":"passkeyEverywhere"}}}"#
        ]
        for text in cases {
            XCTAssertEqual(ChallengeRecord.decode(Data(text.utf8)), .corrupt, text)
        }
    }

    private static let challengeBody =
        #"{"challengeName":"X","availableChallenges":[],"username":"u","signInMethod":{"authFlow":"userSRP"},"# +
        #""step":{"kind":"confirmSignInWithTOTPCode"}}"#
    private static let setupBody =
        #"{"secretCode":"S","session":"s","username":"u","signInMethod":{"authFlow":"userSRP"}}"#

    // MARK: The ceiling

    /// - Given: a record created at `t`
    /// - When: its ceiling is checked at `t + 15 min`, one millisecond later, one minute before `t`, and more than
    ///   15 minutes before `t`
    /// - Then:
    ///    - it is past the ceiling only more than 15 minutes away from `t`, either way: a clock moved back by less
    ///      keeps it, one moved back by more cannot date it
    func testTheCeilingIsFifteenMinutesEitherWay() {
        let record = ChallengeRecord(createdAt: createdAt, state: .totpSetup(totpSetup))

        XCTAssertEqual(ChallengeRecord.ceiling, 900)
        XCTAssertFalse(record.isPastCeiling(at: record.createdAt.addingTimeInterval(900)))
        XCTAssertTrue(record.isPastCeiling(at: record.createdAt.addingTimeInterval(900.001)))
        XCTAssertFalse(record.isPastCeiling(at: record.createdAt.addingTimeInterval(-60)))
        XCTAssertTrue(record.isPastCeiling(at: record.createdAt.addingTimeInterval(-900.001)))
    }

    /// The record holds a live Cognito session string, a username and a TOTP secret: none is ever printed.
    ///
    /// - Given: a record of each shape, whose secret, session, username and parameter values are known strings
    /// - When: each is interpolated, `String(reflecting:)`-ed and `dump`-ed, with its state and payload
    /// - Then:
    ///    - no output contains any of those strings; each shows `<redacted>` and the step kind or flow
    func testNothingSecretIsPrinted() {
        let secrets = ["SECRET", "session-1", "setup-session", "alice", "+1***", "alice@example.com"]
        let records = [
            ChallengeRecord(createdAt: createdAt, state: .challenge(smsChallenge)),
            ChallengeRecord(createdAt: createdAt, state: .totpSetup(totpSetup))
        ]
        for record in records {
            var dumped = ""
            dump(record, to: &dumped)
            var dumpedState = ""
            dump(record.state, to: &dumpedState)
            let outputs = [
                "\(record)", String(reflecting: record), dumped,
                "\(record.state)", String(reflecting: record.state), dumpedState
            ]
            for output in outputs {
                for secret in secrets {
                    XCTAssertFalse(output.contains(secret), "printed a secret in: \(output.prefix(40))")
                }
                XCTAssertTrue(output.contains("<redacted>"))
            }
        }
        var dumpedChallenge = ""
        dump(smsChallenge, to: &dumpedChallenge)
        var dumpedSetup = ""
        dump(totpSetup, to: &dumpedSetup)
        for output in ["\(smsChallenge)", String(reflecting: smsChallenge), dumpedChallenge,
                       "\(totpSetup)", String(reflecting: totpSetup), dumpedSetup] {
            for secret in secrets {
                XCTAssertFalse(output.contains(secret), "printed a secret in: \(output.prefix(40))")
            }
        }
        XCTAssertTrue("\(smsChallenge)".contains("confirmSignInWithSMSMFACode"))
        XCTAssertTrue("\(totpSetup)".contains("userAuth"))
    }
}
