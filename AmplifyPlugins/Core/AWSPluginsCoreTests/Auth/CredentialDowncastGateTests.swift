//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

/// Keeps credential and token resolution from collapsing back into `AuthError.unknown`.
///
/// Each downcast of an `AuthSession` to `AuthAWSCredentialsProvider`, `AuthCognitoTokensProvider` or
/// `AuthCognitoIdentityProvider` used to end in an `else` that threw `AuthError.unknown`, so signed-out,
/// no-identity-pool and a genuine misconfiguration were indistinguishable. They now go through
/// `AuthSession.resolveAWSCredentials()` / `resolveCognitoTokens()` / `resolveIdentityID()`, which
/// never produce `unknown`.
///
/// This scans the plugin sources so a new downcast fails CI rather than depending on review. It runs in
/// `AWSPluginsCoreTests`, which the `AWSPluginsCore` scheme already runs.
///
/// **What it matches:** `as?`, `as!`, `as` (as in `case let p as AuthCognitoTokensProvider`) and `is`,
/// followed by one of the three protocols, optionally parenthesised or prefixed with `any`.
///
/// **Limit:** matching is per line. A cast whose keyword and protocol name sit on different lines, or a
/// cast through a type alias or generic constraint, is not seen. Review still has to catch those.
class CredentialDowncastGateTests: XCTestCase {

    /// A place allowed to cast a session to a provider protocol, and why.
    private struct Allowance {
        /// The file, relative to the repository root.
        let path: String
        /// Text the allowed line contains, or `nil` to allow every cast in the file.
        let line: String?
        let reason: String
    }

    /// Casts that are allowed because they produce no error, or are the resolver itself.
    private static let allowedDowncasts: [Allowance] = [
        Allowance(
            path: "AmplifyPlugins/Core/AWSPluginsCore/Auth/AuthSession+CredentialResolution.swift",
            line: nil,
            reason: "The resolver itself: it classifies a session that does not conform."
        ),
        Allowance(
            path: "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/HubEvents/AuthHubEventHandler.swift",
            line: "sessionResult as? AuthCognitoTokensProvider",
            reason: "Decides whether to dispatch sessionExpired; a session that does not conform produces no error."
        ),
        Allowance(
            path: "AmplifyPlugins/Predictions/AWSPredictionsPlugin/Dependency/AWSTranscribeStreamingAdapter.swift",
            line: "authSession is AuthAWSCredentialsProvider",
            reason: """
            Runs after the resolver has thrown, only to choose between wrapping its error in the \
            PredictionsError.client this path has always thrown and rethrowing it.
            """
        )
    ]

    /// A cast to, or type check against, one of the three provider protocols.
    private static let downcastPattern =
        #"\b(as\s*[?!]?|is)\s*\(?\s*(any\s+)?(AuthAWSCredentialsProvider|AuthCognitoTokensProvider|AuthCognitoIdentityProvider)\b"#

    /// How far below a downcast an `else` branch that throws would sit.
    private static let branchWindow = 8

    /// The plugin sources, read once for all the tests here.
    private static let scan: Result<[Source], any Error> = Result { try scanPluginSources() }

    /// No plugin source casts a session to a provider protocol outside the allowlist.
    ///
    /// - Given: Every non-test Swift source under `AmplifyPlugins/`
    /// - When:
    ///    - It is scanned for casts and `is` checks against the three provider protocols
    /// - Then:
    ///    - Every match is allowed, so credential and token resolution goes through the resolver
    ///
    func testNoProviderDowncastOutsideResolver() throws {
        var violations: [String] = []
        for source in try pluginSources() {
            for line in downcastLines(in: source) where !Self.isAllowed(source.lines[line], in: source.path) {
                violations.append("\(source.path):\(line + 1): \(source.lines[line].trimmed)")
            }
        }
        XCTAssertTrue(
            violations.isEmpty,
            """
            Resolve AWS credentials, user pool tokens and identity IDs with AuthSession.resolveAWSCredentials(), \
            resolveCognitoTokens() or resolveIdentityID() instead of casting the session. A cast that throws \
            no error at all (such as AuthHubEventHandler's) can instead be added to \
            CredentialDowncastGateTests.allowedDowncasts, with the reason it is safe:
            \(violations.joined(separator: "\n"))
            """
        )
    }

    /// No cast that remains is followed by an `AuthError.unknown`.
    ///
    /// - Given: The casts the allowed places still contain
    /// - When:
    ///    - The lines below each one are scanned
    /// - Then:
    ///    - None of them throws or returns `.unknown`
    ///
    func testNoUnknownErrorInDowncastBranch() throws {
        var violations: [String] = []
        for source in try pluginSources() {
            for line in downcastLines(in: source) {
                let window = source.lines[line ..< min(line + Self.branchWindow, source.lines.count)]
                for (offset, text) in window.enumerated() where text.contains(".unknown(") {
                    violations.append("\(source.path):\(line + offset + 1): \(text.trimmed)")
                }
            }
        }
        XCTAssertTrue(violations.isEmpty, violations.joined(separator: "\n"))
    }

    /// The resolver never produces `AuthError.unknown`.
    ///
    /// - Given: The resolver's source
    /// - When:
    ///    - It is scanned for `.unknown(`
    /// - Then:
    ///    - There is none
    ///
    func testResolverHasNoUnknownError() throws {
        let resolver = try XCTUnwrap(
            pluginSources().first { $0.path.hasSuffix("AuthSession+CredentialResolution.swift") },
            "The resolver moved; update allowedDowncasts"
        )
        let unknown = resolver.lines.indices.filter { resolver.lines[$0].contains(".unknown(") }
        XCTAssertEqual(unknown.map { $0 + 1 }, [])
    }

    /// Every allowance still matches a cast.
    ///
    /// - Given: The allowlist
    /// - When:
    ///    - Each entry's file is looked up
    /// - Then:
    ///    - The file exists and still has a cast the entry allows, so a stale entry cannot silently widen
    ///      the gate
    ///
    func testAllowlistIsCurrent() throws {
        let sources = try pluginSources()
        for allowance in Self.allowedDowncasts {
            let source = try XCTUnwrap(
                sources.first { $0.path == allowance.path },
                "\(allowance.path) no longer exists"
            )
            let allowed = downcastLines(in: source).filter { index in
                allowance.line.map { source.lines[index].contains($0) } ?? true
            }
            XCTAssertFalse(
                allowed.isEmpty,
                "\(allowance.path) no longer has the cast \(allowance.line ?? "") allows; remove the entry"
            )
        }
    }

    /// The pattern catches every cast form it documents.
    ///
    /// - Given: One line per documented form
    /// - When:
    ///    - Each is matched against the pattern
    /// - Then:
    ///    - Every form matches, and a conformance declaration does not
    ///
    func testPatternMatchesDocumentedForms() {
        let forms = [
            "guard let p = session as? AuthAWSCredentialsProvider else {",
            "let p = session as! AuthCognitoTokensProvider",
            "(session as? AuthCognitoIdentityProvider)?.getIdentityId()",
            "if session is AuthAWSCredentialsProvider {",
            "case let p as AuthCognitoTokensProvider:",
            "let p = session as? any AuthCognitoIdentityProvider"
        ]
        for form in forms {
            XCTAssertTrue(matchesDowncast(form), form)
        }
        XCTAssertFalse(matchesDowncast("public struct S: AuthSession, AuthAWSCredentialsProvider {"))
    }

    // MARK: - Scanning

    private struct Source: Sendable {
        let path: String
        let lines: [String]
    }

    private static func isAllowed(_ line: String, in path: String) -> Bool {
        allowedDowncasts.contains { allowance in
            allowance.path == path && (allowance.line.map { line.contains($0) } ?? true)
        }
    }

    private func matchesDowncast(_ line: String) -> Bool {
        !line.trimmed.hasPrefix("//") && line.range(of: Self.downcastPattern, options: .regularExpression) != nil
    }

    private func downcastLines(in source: Source) -> [Int] {
        source.lines.indices.filter { matchesDowncast(source.lines[$0]) }
    }

    private func pluginSources() throws -> [Source] {
        let sources = try Self.scan.get()
        XCTAssertFalse(sources.isEmpty, "No plugin sources found under AmplifyPlugins/")
        return sources
    }

    /// Every Swift file under `AmplifyPlugins/` that is compiled into a shipping module.
    private static func scanPluginSources() throws -> [Source] {
        let root = try repositoryRoot()
        let plugins = root.appendingPathComponent("AmplifyPlugins")
        guard let enumerator = FileManager.default.enumerator(at: plugins, includingPropertiesForKeys: nil) else {
            throw ScanError(description: "Could not enumerate \(plugins.path)")
        }
        var sources: [Source] = []
        for case let url as URL in enumerator {
            let relative = String(url.standardizedFileURL.path.dropFirst(root.standardizedFileURL.path.count + 1))
            if isTestOrHostPath(relative) {
                if url.hasDirectoryPath { enumerator.skipDescendants() }
                continue
            }
            guard url.pathExtension == "swift" else { continue }
            let contents = try String(contentsOf: url, encoding: .utf8)
            sources.append(Source(path: relative, lines: contents.components(separatedBy: .newlines)))
        }
        return sources
    }

    private static func isTestOrHostPath(_ relative: String) -> Bool {
        relative.split(separator: "/").contains { component in
            component == "Tests" || component.hasSuffix("Tests") || component.hasSuffix("TestCommon")
                || component.hasSuffix("HostApp") || component.hasPrefix(".")
        }
    }

    /// The checkout this file was compiled from: the nearest ancestor holding `Package.swift`.
    private static func repositoryRoot() throws -> URL {
        var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while directory.path != "/" {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent("Package.swift").path) {
                return directory
            }
            directory.deleteLastPathComponent()
        }
        #if os(macOS)
        throw ScanError(
            description: "No directory above \(#filePath) contains Package.swift, so the plugin sources cannot be scanned"
        )
        #else
        // A simulator can normally read the host checkout; if this one cannot, the macOS run still gates.
        throw XCTSkip("The sources are not readable from this platform")
        #endif
    }
}

private struct ScanError: Error, CustomStringConvertible {
    let description: String
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }
}
