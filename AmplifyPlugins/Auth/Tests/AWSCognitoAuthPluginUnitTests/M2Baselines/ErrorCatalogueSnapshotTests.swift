//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AuthenticationServices
import AWSClientRuntime
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AwsCommonRuntimeKit
import Foundation
import Smithy
import SmithyHTTPAPI
import XCTest
@testable import Amplify
@_spi(KeychainStore) @testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime

/// The error-catalogue gate: every error the plugin can surface keeps its case, its strings and its
/// underlying error.
///
/// `TestResources/GoldenErrors/catalogue.json` was captured before the engine extraction. It records, for every
/// `AuthErrorConvertible` conformance and every case of the plugin's internal error enums, the `AuthError`
/// the plugin builds: case, field, `errorDescription`, `recoverySuggestion`, the underlying error's type
/// and case. It also records every `AWSCognitoAuthError` description and every `AuthPluginErrorConstants`
/// string. Any change fails the test with the entries that differ.
///
/// Regenerate only for a reviewed, intended change: `AMPLIFY_GENERATE_GOLDEN=1 swift test --filter ErrorCatalogueSnapshotTests`.
final class ErrorCatalogueSnapshotTests: XCTestCase {

    // MARK: Snapshot model

    struct Entry: Codable, Equatable {
        /// The input, as `<conforming type>/<variant>`.
        let input: String
        let authErrorCase: String
        let field: String?
        let errorDescription: String
        let recoverySuggestion: String
        /// `AuthError.debugDescription`, which log lines print when they interpolate the error.
        let debugDescription: String
        /// The input's own `debugDescription`, when the input is the credential store's error
        /// (`EngineCredentialStoreError` since the credential store moved into the engine, `KeychainStoreError`
        /// before).
        let keychainStoreErrorDebugDescription: String?
        let underlyingErrorType: String?
        let underlyingErrorCase: String?
        /// The call sites `AmplifyErrorMessages.reportBugToAWS()` embedded in the strings above, which read
        /// `file: <file>\nfunction: <function>\nline: <line>` there. Kept apart because they change
        /// whenever a later step edits or moves the calling file (`#file` is `#fileID` in Swift 6).
        let reportBugLocations: [Location]?

        /// This entry with each location reduced to its stable part: file name and function.
        var stable: Entry {
            Entry(
                input: input,
                authErrorCase: authErrorCase,
                field: field,
                errorDescription: errorDescription,
                recoverySuggestion: recoverySuggestion,
                debugDescription: debugDescription,
                keychainStoreErrorDebugDescription: keychainStoreErrorDebugDescription,
                underlyingErrorType: underlyingErrorType,
                underlyingErrorCase: underlyingErrorCase,
                reportBugLocations: reportBugLocations?.map(\.stable)
            )
        }
    }

    struct Location: Codable, Hashable {
        /// `#fileID`: `<module>/<file>.swift`.
        let file: String
        let function: String
        let line: Int

        var stable: Location {
            Location(file: String(file.split(separator: "/").last ?? ""), function: function, line: 0)
        }
    }

    struct ConstantEntry: Codable, Equatable {
        let name: String
        let field: String?
        let errorDescription: String?
        let recoverySuggestion: String
    }

    struct Catalogue: Codable, Equatable {
        let note: String
        let conversions: [Entry]
        let notInvoked: [String]
        let awsCognitoAuthErrorDescriptions: [String: String]
        let errorConstants: [ConstantEntry]

        var stable: Catalogue {
            Catalogue(
                note: note,
                conversions: conversions.map(\.stable),
                notInvoked: notInvoked,
                awsCognitoAuthErrorDescriptions: awsCognitoAuthErrorDescriptions,
                errorConstants: errorConstants
            )
        }
    }

    enum ErrorConstantValue {
        case pair(AuthPluginErrorString)
        case validation(AuthPluginValidationErrorString)
        case suggestion(RecoverySuggestion)
    }

    /// A non-convertible error, for the "anything else" branches.
    struct SentinelError: Error {}

    static var fileURL: URL {
        GoldenFiles.directory("GoldenErrors").appendingPathComponent("catalogue.json")
    }

    static let message = "fixture service message"

    // MARK: Tests

    /// Test that the error catalogue is unchanged
    ///
    /// - Given: The committed catalogue, as the plugin builds it on this platform (`onThisPlatform(_:)`)
    /// - When:
    ///    - The catalogue is rebuilt from today's code
    /// - Then:
    ///    - It is identical, entry for entry
    ///
    func testCatalogueIsUnchanged() throws {
        let current = try Self.buildCatalogue()
        let currentData = try GoldenFiles.snapshotData(current)
        if GoldenFiles.isGenerating {
            try GoldenFiles.write(currentData, to: Self.fileURL)
            return
        }
        let committedData = try Data(contentsOf: Self.fileURL)
        let committed = try Self.onThisPlatform(JSONDecoder().decode(Catalogue.self, from: committedData))
        // The gate: equal as parsed JSON trees, with `reportBugToAWS` call sites compared by file name and
        // function only. Their module and line are reported below, not gated.
        XCTAssertTrue(
            try CanonicalJSON.areEqual(GoldenFiles.snapshotData(current.stable), GoldenFiles.snapshotData(committed.stable)),
            "catalogue.json differs; details follow"
        )

        let committedByInput = Dictionary(uniqueKeysWithValues: committed.conversions.map { ($0.input, $0) })
        for entry in current.conversions where committedByInput[entry.input]?.stable != entry.stable {
            XCTFail("\(entry.input) drifted:\n  was \(String(describing: committedByInput[entry.input]))\n  now \(entry)")
        }
        for entry in current.conversions {
            let recorded = committedByInput[entry.input]?.reportBugLocations
            if let recorded, recorded != entry.reportBugLocations {
                print("note: \(entry.input) reportBugToAWS call site moved: \(recorded) -> \(entry.reportBugLocations ?? [])")
            }
        }
        let currentInputs = Set(current.conversions.map(\.input))
        for missing in committed.conversions.map(\.input) where !currentInputs.contains(missing) {
            XCTFail("\(missing) is no longer in the catalogue")
        }
        XCTAssertEqual(current.notInvoked, committed.notInvoked)
        XCTAssertEqual(current.awsCognitoAuthErrorDescriptions, committed.awsCognitoAuthErrorDescriptions)
        XCTAssertEqual(current.errorConstants, committed.errorConstants)
    }

    /// Test that the catalogue covers every `AuthErrorConvertible` conformance and every error constant
    ///
    /// - Given: The plugin's and the engine's error-mapping sources
    /// - When:
    ///    - Each conformance to `AuthErrorConvertible` (or, in the engine, `EngineAuthErrorConvertible`) and
    ///      each `AuthPluginErrorConstants` member is listed
    /// - Then:
    ///    - Every one of them is in the catalogue
    ///
    func testCatalogueCoversEverySource() throws {
        // By input name and by input type: the `KeychainStoreError/…` inputs are its engine copy.
        let covered = Set(Self.conversionInputs.map { $0.input.components(separatedBy: "/")[0] })
            .union(Self.conversionInputs.map { String(describing: type(of: $0.error)) })
        let conformance = try NSRegularExpression(
            pattern: #"^extension ([A-Za-z0-9_.]+): (?:Engine)?AuthErrorConvertible"#,
            options: [.anchorsMatchLines]
        )
        var found: Set<String> = []
        for file in try Self.swiftSources() {
            let text = try String(contentsOf: file, encoding: .utf8)
            for match in conformance.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let range = Range(match.range(at: 1), in: text) {
                    found.insert(String(text[range]))
                }
            }
        }
        // `AuthError` and `EngineAuthError` convert to themselves; they are not error sources.
        found.remove("AuthError")
        found.remove("EngineAuthError")
        XCTAssertGreaterThan(found.count, 50)
        XCTAssertEqual(found.subtracting(covered), [], "conformances missing from the catalogue")

        let constantsSource = try XCTUnwrap(
            Self.repositoryFiles([
                "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/Support/Constants/AuthPluginErrorConstants.swift",
                "AmplifyClients/Internal/InternalAWSCognitoAuth/Sources/Support/Constants/AuthPluginErrorConstants.swift"
            ]).first
        )
        let declaration = try NSRegularExpression(pattern: #"^\s*static let ([A-Za-z0-9_]+):"#, options: [.anchorsMatchLines])
        let text = try String(contentsOf: constantsSource, encoding: .utf8)
        let declared = declaration.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
            Range($0.range(at: 1), in: text).map { String(text[$0]) }
        }
        XCTAssertEqual(declared, Self.errorConstants.map(\.name), "rerun scripts/m2/gen_error_constants_list.py")
    }

    // MARK: The platform-dependent entry

    struct PlatformAdjustmentError: Error, CustomStringConvertible {
        let description: String
    }

    /// The line of `KeychainStoreError.recoverySuggestion`'s `#else` branch, whose
    /// `shouldNotHappenReportBugToAWS()` call reports every security error off macOS. The engine copy embeds the
    /// same line (`EngineCredentialStoreError.recoverySuggestion`).
    static let offMacOSReportBugLine = 88

    /// The committed catalogue as the plugin builds it on this platform.
    ///
    /// The catalogue was captured on macOS, and one entry depends on the platform:
    /// `KeychainStoreError.recoverySuggestion`, and the engine's `EngineCredentialStoreError` copy of it, return
    /// the Keychain Sharing guidance for `errSecMissingEntitlement` under `#if os(macOS)` only. Every other
    /// platform takes the `#else` branch: the `shouldNotHappenReportBugToAWS()` text that the committed
    /// `securityError-interactionNotAllowed` entry records. So off macOS the expected
    /// `securityError-missingEntitlement` entry is the committed one with that text in place of the guidance, in
    /// its recovery suggestion and in both debug descriptions. Its call site is that entry's file and function, at
    /// the `#else` branch's line (`offMacOSReportBugLine`), which is where the text comes from off macOS. Both
    /// texts come from the committed file, and every other entry is compared as committed.
    static func onThisPlatform(_ committed: Catalogue) throws -> Catalogue {
        #if os(macOS)
        return committed
        #else
        let byInput = Dictionary(uniqueKeysWithValues: committed.conversions.map { ($0.input, $0) })
        let entitlementInput = "KeychainStoreError/securityError-missingEntitlement"
        let entitlement = try XCTUnwrap(byInput[entitlementInput])
        let reportBug = try XCTUnwrap(byInput["KeychainStoreError/securityError-interactionNotAllowed"])
        let guidance = entitlement.recoverySuggestion
        func withoutGuidance(_ text: String) throws -> String {
            guard text.contains(guidance) else {
                throw PlatformAdjustmentError(description: "\(entitlementInput) no longer embeds its macOS guidance")
            }
            return text.replacingOccurrences(of: guidance, with: reportBug.recoverySuggestion)
        }
        let adjusted = try Entry(
            input: entitlement.input,
            authErrorCase: entitlement.authErrorCase,
            field: entitlement.field,
            errorDescription: entitlement.errorDescription,
            recoverySuggestion: withoutGuidance(entitlement.recoverySuggestion),
            debugDescription: withoutGuidance(entitlement.debugDescription),
            keychainStoreErrorDebugDescription: entitlement.keychainStoreErrorDebugDescription.map(withoutGuidance),
            underlyingErrorType: entitlement.underlyingErrorType,
            underlyingErrorCase: entitlement.underlyingErrorCase,
            reportBugLocations: reportBug.reportBugLocations?.map {
                Location(file: $0.file, function: $0.function, line: offMacOSReportBugLine)
            }
        )
        return Catalogue(
            note: committed.note,
            conversions: committed.conversions.map { $0.input == entitlementInput ? adjusted : $0 },
            notInvoked: committed.notInvoked,
            awsCognitoAuthErrorDescriptions: committed.awsCognitoAuthErrorDescriptions,
            errorConstants: committed.errorConstants
        )
        #endif
    }

    // MARK: Building the catalogue

    static func buildCatalogue() throws -> Catalogue {
        // CRT error names and messages come from tables registered at initialization. An app always has
        // them (the SDK clients initialize the CRT); without this, a CRTError reads "Unknown Error Code"
        // when this test runs before any other test has touched the CRT.
        CommonRuntimeKit.initialize()
        return Catalogue(
            note: "Captured at M2 step S0. Strings from AmplifyErrorMessages.reportBugToAWS() embed the call site's #file (= #fileID), #function and #line.",
            conversions: conversionInputs.map { entry($0.input, $0.error) },
            notInvoked: [
                "SignUpError/invalidState: authError calls fatalError",
                "SignUpError/invalidConfirmationCode: authError calls fatalError"
            ],
            awsCognitoAuthErrorDescriptions: Dictionary(uniqueKeysWithValues: awsCognitoAuthErrors.map {
                (caseName($0), $0.errorDescription ?? "<nil>")
            }),
            errorConstants: errorConstants.map { name, value in
                switch value {
                case .pair(let pair):
                    ConstantEntry(name: name, field: nil, errorDescription: pair.errorDescription, recoverySuggestion: pair.recoverySuggestion)
                case .validation(let triple):
                    ConstantEntry(name: name, field: triple.field, errorDescription: triple.errorDescription, recoverySuggestion: triple.recoverySuggestion)
                case .suggestion(let suggestion):
                    ConstantEntry(name: name, field: nil, errorDescription: nil, recoverySuggestion: suggestion)
                }
            }
        )
    }

    static func entry(_ input: String, _ source: Error) -> Entry {
        let error = convert(source)
        let field: String? = if case .validation(let field, _, _, _) = error { field } else { nil }
        var locations: [Location] = []
        func text(_ string: String) -> String {
            let (stripped, found) = extractLocations(normalized(string))
            for location in found where !locations.contains(location) {
                locations.append(location)
            }
            return stripped
        }
        return Entry(
            input: input,
            authErrorCase: caseName(error),
            field: field,
            errorDescription: text(error.errorDescription),
            recoverySuggestion: text(error.recoverySuggestion),
            debugDescription: text(error.debugDescription),
            keychainStoreErrorDebugDescription: keychainStoreErrorDebugDescription(source).map(text),
            underlyingErrorType: error.underlyingError.map { String(reflecting: type(of: $0)) },
            underlyingErrorCase: error.underlyingError.flatMap(enumCaseName),
            reportBugLocations: locations.isEmpty ? nil : locations
        )
    }

    /// The input's own `debugDescription`, when it is the credential store's error: the engine's copy, or
    /// the public `KeychainStoreError`, which print the same text.
    static func keychainStoreErrorDebugDescription(_ source: Error) -> String? {
        (source as? EngineCredentialStoreError)?.debugDescription ?? (source as? KeychainStoreError)?.debugDescription
    }

    /// The `AuthError` the plugin surfaces for `source`. The SDK exceptions and the engine's error enums
    /// convert in the engine (`EngineAuthErrorConvertible`), and the plugin maps the result with
    /// `AuthError(_:)`; `AuthError(converting:)` is the one path the glue uses for both families.
    static func convert(_ source: Error) -> AuthError {
        guard let error = AuthError(converting: source) else {
            preconditionFailure("\(type(of: source)) is not convertible to AuthError")
        }
        return error
    }

    /// `AmplifyErrorMessages.reportBugToAWS()` ends with `file: …\nfunction: …\nline: …`.
    static func extractLocations(_ text: String) -> (String, [Location]) {
        let pattern = try! NSRegularExpression(pattern: #"file: (\S+)\nfunction: (\S+)\nline: (\d+)"#)
        var locations: [Location] = []
        for match in pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            let group = { (index: Int) in Range(match.range(at: index), in: text).map { String(text[$0]) } ?? "" }
            locations.append(Location(file: group(1), function: group(2), line: Int(group(3)) ?? -1))
        }
        let stripped = pattern.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "file: <file>\nfunction: <function>\nline: <line>"
        )
        return (stripped, locations)
    }

    /// Replaces heap addresses, the only run-to-run variation in `debugDescription` output.
    static func normalized(_ text: String) -> String {
        text.replacingOccurrences(of: #"0x[0-9a-fA-F]{6,16}"#, with: "0x<address>", options: .regularExpression)
    }

    static func caseName(_ value: Any) -> String {
        enumCaseName(value) ?? String(describing: value)
    }

    /// The case name of an enum value, or `nil` for anything that is not an enum.
    static func enumCaseName(_ value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .enum else { return nil }
        return mirror.children.first?.label ?? FieldDump.caseName(of: value)
    }

    static func swiftSources() throws -> [URL] {
        let directories = repositoryFiles([
            "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin",
            "AmplifyClients/Internal/InternalAWSCognitoAuth/Sources"
        ])
        var files: [URL] = []
        for directory in directories {
            let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
            while let url = enumerator?.nextObject() as? URL {
                if url.pathExtension == "swift" { files.append(url) }
            }
        }
        return files
    }

    /// The repository root is five levels above this file.
    static func repositoryFiles(_ relativePaths: [String]) -> [URL] {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0 ..< 6 {
            root.deleteLastPathComponent()
        }
        return relativePaths.map { root.appendingPathComponent($0) }.filter {
            FileManager.default.fileExists(atPath: $0.path)
        }
    }

    // MARK: Inputs

    typealias Input = (input: String, error: Error)

    static var conversionInputs: [Input] {
        var inputs: [Input] = []
        inputs += cognitoIdentityProviderInputs
        inputs += cognitoIdentityInputs
        inputs += runtimeInputs
        inputs += pluginEnumInputs
        inputs += keychainInputs
        return inputs
    }

    /// Both variants of an SDK exception: with a message, and without one (`fallbackDescription`).
    static func sdk(_ name: String, _ withMessage: Error, _ withoutMessage: Error) -> [Input] {
        [("\(name)/message", withMessage), ("\(name)/nil", withoutMessage)]
    }

    static var cognitoIdentityProviderInputs: [Input] {
        var inputs: [Input] = []
        inputs += sdk("ForbiddenException", AWSCognitoIdentityProvider.ForbiddenException(message: message), AWSCognitoIdentityProvider.ForbiddenException())
        inputs += sdk("InternalErrorException", AWSCognitoIdentityProvider.InternalErrorException(message: message), AWSCognitoIdentityProvider.InternalErrorException())
        inputs += sdk("InvalidParameterException", AWSCognitoIdentityProvider.InvalidParameterException(message: message), AWSCognitoIdentityProvider.InvalidParameterException())
        inputs += sdk("InvalidPasswordException", AWSCognitoIdentityProvider.InvalidPasswordException(message: message), AWSCognitoIdentityProvider.InvalidPasswordException())
        inputs += sdk("LimitExceededException", AWSCognitoIdentityProvider.LimitExceededException(message: message), AWSCognitoIdentityProvider.LimitExceededException())
        inputs += sdk("NotAuthorizedException", AWSCognitoIdentityProvider.NotAuthorizedException(message: message), AWSCognitoIdentityProvider.NotAuthorizedException())
        inputs += sdk("PasswordResetRequiredException", AWSCognitoIdentityProvider.PasswordResetRequiredException(message: message), AWSCognitoIdentityProvider.PasswordResetRequiredException())
        inputs += sdk("ResourceNotFoundException", AWSCognitoIdentityProvider.ResourceNotFoundException(message: message), AWSCognitoIdentityProvider.ResourceNotFoundException())
        inputs += sdk("TooManyRequestsException", AWSCognitoIdentityProvider.TooManyRequestsException(message: message), AWSCognitoIdentityProvider.TooManyRequestsException())
        inputs += sdk("UserNotConfirmedException", AWSCognitoIdentityProvider.UserNotConfirmedException(message: message), AWSCognitoIdentityProvider.UserNotConfirmedException())
        inputs += sdk("UserNotFoundException", AWSCognitoIdentityProvider.UserNotFoundException(message: message), AWSCognitoIdentityProvider.UserNotFoundException())
        inputs += sdk("CodeMismatchException", AWSCognitoIdentityProvider.CodeMismatchException(message: message), AWSCognitoIdentityProvider.CodeMismatchException())
        inputs += sdk("InvalidLambdaResponseException", AWSCognitoIdentityProvider.InvalidLambdaResponseException(message: message), AWSCognitoIdentityProvider.InvalidLambdaResponseException())
        inputs += sdk("ExpiredCodeException", AWSCognitoIdentityProvider.ExpiredCodeException(message: message), AWSCognitoIdentityProvider.ExpiredCodeException())
        inputs += sdk("TooManyFailedAttemptsException", AWSCognitoIdentityProvider.TooManyFailedAttemptsException(message: message), AWSCognitoIdentityProvider.TooManyFailedAttemptsException())
        inputs += sdk("UnexpectedLambdaException", AWSCognitoIdentityProvider.UnexpectedLambdaException(message: message), AWSCognitoIdentityProvider.UnexpectedLambdaException())
        inputs += sdk("UserLambdaValidationException", AWSCognitoIdentityProvider.UserLambdaValidationException(message: message), AWSCognitoIdentityProvider.UserLambdaValidationException())
        inputs += sdk("AliasExistsException", AWSCognitoIdentityProvider.AliasExistsException(message: message), AWSCognitoIdentityProvider.AliasExistsException())
        inputs += sdk(
            "InvalidUserPoolConfigurationException",
            AWSCognitoIdentityProvider.InvalidUserPoolConfigurationException(message: message),
            AWSCognitoIdentityProvider.InvalidUserPoolConfigurationException()
        )
        inputs += sdk("CodeDeliveryFailureException", AWSCognitoIdentityProvider.CodeDeliveryFailureException(message: message), AWSCognitoIdentityProvider.CodeDeliveryFailureException())
        inputs += sdk(
            "InvalidEmailRoleAccessPolicyException",
            AWSCognitoIdentityProvider.InvalidEmailRoleAccessPolicyException(message: message),
            AWSCognitoIdentityProvider.InvalidEmailRoleAccessPolicyException()
        )
        inputs += sdk(
            "InvalidSmsRoleAccessPolicyException",
            AWSCognitoIdentityProvider.InvalidSmsRoleAccessPolicyException(message: message),
            AWSCognitoIdentityProvider.InvalidSmsRoleAccessPolicyException()
        )
        inputs += sdk(
            "InvalidSmsRoleTrustRelationshipException",
            AWSCognitoIdentityProvider.InvalidSmsRoleTrustRelationshipException(message: message),
            AWSCognitoIdentityProvider.InvalidSmsRoleTrustRelationshipException()
        )
        inputs += sdk("MFAMethodNotFoundException", AWSCognitoIdentityProvider.MFAMethodNotFoundException(message: message), AWSCognitoIdentityProvider.MFAMethodNotFoundException())
        inputs += sdk(
            "SoftwareTokenMFANotFoundException",
            AWSCognitoIdentityProvider.SoftwareTokenMFANotFoundException(message: message),
            AWSCognitoIdentityProvider.SoftwareTokenMFANotFoundException()
        )
        inputs += sdk("UsernameExistsException", AWSCognitoIdentityProvider.UsernameExistsException(message: message), AWSCognitoIdentityProvider.UsernameExistsException())
        inputs += sdk(
            "AWSCognitoIdentityProvider.ConcurrentModificationException",
            AWSCognitoIdentityProvider.ConcurrentModificationException(message: message),
            AWSCognitoIdentityProvider.ConcurrentModificationException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.EnableSoftwareTokenMFAException",
            AWSCognitoIdentityProvider.EnableSoftwareTokenMFAException(message: message),
            AWSCognitoIdentityProvider.EnableSoftwareTokenMFAException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.WebAuthnChallengeNotFoundException",
            AWSCognitoIdentityProvider.WebAuthnChallengeNotFoundException(message: message),
            AWSCognitoIdentityProvider.WebAuthnChallengeNotFoundException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.WebAuthnClientMismatchException",
            AWSCognitoIdentityProvider.WebAuthnClientMismatchException(message: message),
            AWSCognitoIdentityProvider.WebAuthnClientMismatchException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.WebAuthnCredentialNotSupportedException",
            AWSCognitoIdentityProvider.WebAuthnCredentialNotSupportedException(message: message),
            AWSCognitoIdentityProvider.WebAuthnCredentialNotSupportedException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.WebAuthnNotEnabledException",
            AWSCognitoIdentityProvider.WebAuthnNotEnabledException(message: message),
            AWSCognitoIdentityProvider.WebAuthnNotEnabledException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.WebAuthnOriginNotAllowedException",
            AWSCognitoIdentityProvider.WebAuthnOriginNotAllowedException(message: message),
            AWSCognitoIdentityProvider.WebAuthnOriginNotAllowedException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.WebAuthnRelyingPartyMismatchException",
            AWSCognitoIdentityProvider.WebAuthnRelyingPartyMismatchException(message: message),
            AWSCognitoIdentityProvider.WebAuthnRelyingPartyMismatchException()
        )
        inputs += sdk(
            "AWSCognitoIdentityProvider.WebAuthnConfigurationMissingException",
            AWSCognitoIdentityProvider.WebAuthnConfigurationMissingException(message: message),
            AWSCognitoIdentityProvider.WebAuthnConfigurationMissingException()
        )
        inputs += sdk(
            "AWSClientRuntime.UnknownAWSHTTPServiceError",
            UnknownAWSHTTPServiceError(
                httpResponse: HTTPResponse(body: .empty, statusCode: .badRequest),
                message: message,
                requestID: "fixture-request-id",
                requestID2: nil,
                typeName: "FixtureUnknownType"
            ),
            UnknownAWSHTTPServiceError(
                httpResponse: HTTPResponse(body: .empty, statusCode: .internalServerError),
                message: nil,
                requestID: nil,
                requestID2: nil,
                typeName: nil
            )
        )
        return inputs
    }

    static var cognitoIdentityInputs: [Input] {
        var inputs: [Input] = []
        inputs += sdk("AWSCognitoIdentity.ExternalServiceException", AWSCognitoIdentity.ExternalServiceException(message: message), AWSCognitoIdentity.ExternalServiceException())
        inputs += sdk("AWSCognitoIdentity.InternalErrorException", AWSCognitoIdentity.InternalErrorException(message: message), AWSCognitoIdentity.InternalErrorException())
        inputs += sdk(
            "AWSCognitoIdentity.InvalidIdentityPoolConfigurationException",
            AWSCognitoIdentity.InvalidIdentityPoolConfigurationException(message: message),
            AWSCognitoIdentity.InvalidIdentityPoolConfigurationException()
        )
        inputs += sdk("AWSCognitoIdentity.InvalidParameterException", AWSCognitoIdentity.InvalidParameterException(message: message), AWSCognitoIdentity.InvalidParameterException())
        inputs += sdk("AWSCognitoIdentity.NotAuthorizedException", AWSCognitoIdentity.NotAuthorizedException(message: message), AWSCognitoIdentity.NotAuthorizedException())
        inputs += sdk("AWSCognitoIdentity.ResourceConflictException", AWSCognitoIdentity.ResourceConflictException(message: message), AWSCognitoIdentity.ResourceConflictException())
        inputs += sdk("AWSCognitoIdentity.ResourceNotFoundException", AWSCognitoIdentity.ResourceNotFoundException(message: message), AWSCognitoIdentity.ResourceNotFoundException())
        inputs += sdk("AWSCognitoIdentity.TooManyRequestsException", AWSCognitoIdentity.TooManyRequestsException(message: message), AWSCognitoIdentity.TooManyRequestsException())
        inputs += sdk("AWSCognitoIdentity.LimitExceededException", AWSCognitoIdentity.LimitExceededException(message: message), AWSCognitoIdentity.LimitExceededException())
        return inputs
    }

    static var runtimeInputs: [Input] {
        [
            ("SmithyHTTPAPI.HTTPClientError/pathCreationFailed", HTTPClientError.pathCreationFailed(message)),
            ("SmithyHTTPAPI.HTTPClientError/queryItemCreationFailed", HTTPClientError.queryItemCreationFailed(message)),
            ("Smithy.ClientError/serializationFailed", ClientError.serializationFailed(message)),
            ("Smithy.ClientError/dataNotFound", ClientError.dataNotFound(message)),
            ("Smithy.ClientError/invalidValue", ClientError.invalidValue(message)),
            ("Smithy.ClientError/authError", ClientError.authError(message)),
            ("Smithy.ClientError/unknownError", ClientError.unknownError(message)),
            // A connectivity code (network) and a non-connectivity one (unknown).
            ("CommonRunTimeError/connectivity", CommonRunTimeError.crtError(CRTError(code: 1_059))),
            ("CommonRunTimeError/other", CommonRunTimeError.crtError(CRTError(code: 1)))
        ]
    }

    static var hostedUIErrors: [(String, HostedUIError)] {
        [
            ("signInURI", .signInURI),
            ("tokenURI", .tokenURI),
            ("signOutURI", .signOutURI),
            ("signOutRedirectURI", .signOutRedirectURI),
            ("proofCalculation", .proofCalculation),
            ("codeValidation", .codeValidation),
            ("tokenParsing", .tokenParsing),
            ("serviceMessage", .serviceMessage(message)),
            ("pluginConfiguration", .pluginConfiguration(message)),
            ("cancelled", .cancelled),
            ("invalidContext", .invalidContext),
            ("unableToStartASWebAuthenticationSession", .unableToStartASWebAuthenticationSession),
            ("unknown", .unknown)
        ]
    }

    static var webAuthnErrors: [(String, WebAuthnError)] {
        [
            ("assertionFailed-canceled", .assertionFailed(error: ASAuthorizationError(.canceled))),
            ("assertionFailed-failed", .assertionFailed(error: ASAuthorizationError(.failed))),
            ("creationFailed-canceled", .creationFailed(error: ASAuthorizationError(.canceled))),
            ("creationFailed-matchedExcludedCredential", .creationFailed(error: ASAuthorizationError(ASAuthorizationError.Code(rawValue: 1_006)!))),
            ("creationFailed-failed", .creationFailed(error: ASAuthorizationError(.failed))),
            ("service", .service(error: AWSCognitoIdentityProvider.WebAuthnNotEnabledException(message: message))),
            ("unknown-withError", .unknown(message: message, error: SentinelError())),
            ("unknown-nilError", .unknown(message: message))
        ]
    }

    static var pluginEnumInputs: [Input] {
        let convertible = AWSCognitoIdentityProvider.NotAuthorizedException(message: message)
        var inputs: [Input] = []

        inputs += [
            ("SignInError/configuration", SignInError.configuration(message: message)),
            ("SignInError/service-convertible", SignInError.service(error: convertible)),
            ("SignInError/service-other", SignInError.service(error: SentinelError())),
            ("SignInError/inputValidation", SignInError.inputValidation(field: "fixtureField")),
            ("SignInError/invalidServiceResponse", SignInError.invalidServiceResponse(message: message)),
            ("SignInError/calculation", SignInError.calculation(.calculation)),
            ("SignInError/hostedUI", SignInError.hostedUI(.cancelled)),
            ("SignInError/webAuthn", SignInError.webAuthn(.assertionFailed(error: ASAuthorizationError(.canceled)))),
            ("SignInError/unknown", SignInError.unknown(message: message))
        ]
        inputs += hostedUIErrors.map { ("HostedUIError/\($0.0)", $0.1) }
        inputs += webAuthnErrors.map { ("WebAuthnError/\($0.0)", $0.1) }

        inputs += [
            ("FetchSessionError/noIdentityPool", FetchSessionError.noIdentityPool),
            ("FetchSessionError/noUserPool", FetchSessionError.noUserPool),
            ("FetchSessionError/invalidTokens", FetchSessionError.invalidTokens),
            ("FetchSessionError/notAuthorized", FetchSessionError.notAuthorized),
            ("FetchSessionError/invalidIdentityID", FetchSessionError.invalidIdentityID),
            ("FetchSessionError/invalidAWSCredentials", FetchSessionError.invalidAWSCredentials),
            ("FetchSessionError/noCredentialsToRefresh", FetchSessionError.noCredentialsToRefresh),
            ("FetchSessionError/federationNotSupportedDuringRefresh", FetchSessionError.federationNotSupportedDuringRefresh),
            ("FetchSessionError/service-convertible", FetchSessionError.service(convertible)),
            ("FetchSessionError/service-other", FetchSessionError.service(SentinelError()))
        ]

        inputs += [
            ("AuthorizationError/configuration", AuthorizationError.configuration(message: message)),
            ("AuthorizationError/service-convertible", AuthorizationError.service(error: convertible)),
            ("AuthorizationError/service-other", AuthorizationError.service(error: SentinelError())),
            ("AuthorizationError/invalidState", AuthorizationError.invalidState(message: message)),
            ("AuthorizationError/sessionError", AuthorizationError.sessionError(.notAuthorized, .noCredentials)),
            ("AuthorizationError/sessionExpired", AuthorizationError.sessionExpired(error: convertible))
        ]

        inputs += [
            ("AuthenticationError/configuration", AuthenticationError.configuration(message: message)),
            ("AuthenticationError/service-convertible", AuthenticationError.service(message: message, error: convertible)),
            ("AuthenticationError/service-other", AuthenticationError.service(message: message, error: SentinelError())),
            ("AuthenticationError/service-nil", AuthenticationError.service(message: message, error: nil)),
            ("AuthenticationError/unknown", AuthenticationError.unknown(message: message))
        ]

        inputs += [
            ("SignOutError/hostedUI", SignOutError.hostedUI(.signOutURI)),
            ("SignOutError/localSignOut", SignOutError.localSignOut)
        ]

        inputs += [
            ("SignUpError/invalidUsername", SignUpError.invalidUsername(message: message)),
            ("SignUpError/invalidPassword", SignUpError.invalidPassword(message: message)),
            ("SignUpError/service-convertible", SignUpError.service(error: convertible)),
            ("SignUpError/service-other", SignUpError.service(error: SentinelError()))
        ]
        return inputs
    }

    /// The credential store's error. The engine throws `EngineCredentialStoreError`, so the inputs are the
    /// engine's copy, under the names `KeychainStoreError` was recorded with.
    static var keychainInputs: [Input] {
        [
            ("KeychainStoreError/configuration", EngineCredentialStoreError.configuration(message: message)),
            ("KeychainStoreError/unknown-withError", EngineCredentialStoreError.unknown(message, SentinelError())),
            ("KeychainStoreError/unknown-nilError", EngineCredentialStoreError.unknown(message)),
            ("KeychainStoreError/conversionError", EngineCredentialStoreError.conversionError(message, SentinelError())),
            ("KeychainStoreError/codingError", EngineCredentialStoreError.codingError(message, SentinelError())),
            ("KeychainStoreError/itemNotFound", EngineCredentialStoreError.itemNotFound),
            ("KeychainStoreError/securityError-missingEntitlement", EngineCredentialStoreError.securityError(errSecMissingEntitlement)),
            ("KeychainStoreError/securityError-interactionNotAllowed", EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)),
            ("KeychainStoreError/securityError-duplicateItem", EngineCredentialStoreError.securityError(errSecDuplicateItem))
        ]
    }

    static var awsCognitoAuthErrors: [AWSCognitoAuthError] {
        [
            .userNotFound, .userNotConfirmed, .usernameExists, .aliasExists, .codeDelivery, .codeMismatch,
            .codeExpired, .invalidParameter, .invalidPassword, .limitExceeded, .mfaMethodNotFound,
            .softwareTokenMFANotEnabled, .passwordResetRequired, .resourceNotFound, .failedAttemptsLimitExceeded,
            .requestLimitExceeded, .lambda, .deviceNotTracked, .errorLoadingUI, .userCancelled,
            .invalidAccountTypeException, .network, .smsRole, .emailRole, .externalServiceException,
            .limitExceededException, .resourceConflictException, .webAuthnChallengeNotFound,
            .webAuthnClientMismatch, .webAuthnNotSupported, .webAuthnNotEnabled, .webAuthnOriginNotAllowed,
            .webAuthnRelyingPartyMismatch, .webAuthnConfigurationMissing
        ]
    }

    /// Compile-time exhaustiveness for `awsCognitoAuthErrors`: a new case breaks this switch.
    func testAWSCognitoAuthErrorListIsExhaustive() {
        for error in Self.awsCognitoAuthErrors {
            switch error {
            case .userNotFound, .userNotConfirmed, .usernameExists, .aliasExists, .codeDelivery, .codeMismatch,
                 .codeExpired, .invalidParameter, .invalidPassword, .limitExceeded, .mfaMethodNotFound,
                 .softwareTokenMFANotEnabled, .passwordResetRequired, .resourceNotFound, .failedAttemptsLimitExceeded,
                 .requestLimitExceeded, .lambda, .deviceNotTracked, .errorLoadingUI, .userCancelled,
                 .invalidAccountTypeException, .network, .smsRole, .emailRole, .externalServiceException,
                 .limitExceededException, .resourceConflictException, .webAuthnChallengeNotFound,
                 .webAuthnClientMismatch, .webAuthnNotSupported, .webAuthnNotEnabled, .webAuthnOriginNotAllowed,
                 .webAuthnRelyingPartyMismatch, .webAuthnConfigurationMissing:
                break
            }
        }
        XCTAssertEqual(Set(Self.awsCognitoAuthErrors.map { "\($0)" }).count, 34)
    }
}
