//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The log-transcript gate's normaliser. Both the recorded and the live transcript go through it before they
/// are compared.
///
/// Only the message is normalised. Category, namespace and level are compared exactly.
///
/// 1. `(AWSCognitoAuthPlugin|InternalAWSCognitoAuth)/<File>.swift` (a `#fileID`) becomes `<module>/<File>.swift`.
/// 2. `scripts/cognito-engine/rename_table.json` is applied in reverse: module-qualified names first, then bare names.
/// 3. The module qualifier `InternalAWSCognitoAuth.` becomes `AWSCognitoAuthPlugin.`, for types that moved
///    unchanged.
/// 4. Values that differ from run to run: JWTs, UUIDs, printed dates, heap addresses, and the key order of
///    printed Swift dictionaries.
///
/// It cannot hide an `AuthError:` / `KeychainStoreError:` prefix regression: those are not fork names, and
/// the error-catalogue gate checks `debugDescription` directly.
struct LogTranscriptNormaliser {

    struct RenameTable: Decodable {
        struct Name: Decodable {
            let module: String
            let name: String
        }

        struct Rename: Decodable {
            let step: String
            let from: Name
            let to: Name
        }

        let renames: [Rename]
    }

    let renames: [RenameTable.Rename]

    /// Never mapped back. `AuthError:` and `KeychainStoreError:` are the literal `debugDescription` prefixes
    /// the forks must keep printing, so `EngineAuthError:` / `EngineCredentialStoreError:` in a
    /// message is a regression the normaliser must not hide.
    static let literalNames: Set<String> = ["AuthError", "KeychainStoreError"]

    /// The renames the message normaliser applies in reverse.
    var messageRenames: [RenameTable.Rename] {
        renames.filter { !Self.literalNames.contains($0.from.name) }
    }

    static func fromRepository() throws -> LogTranscriptNormaliser {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0 ..< 6 {
            root.deleteLastPathComponent()
        }
        let url = root.appendingPathComponent("scripts/cognito-engine/rename_table.json")
        let table = try JSONDecoder().decode(RenameTable.self, from: Data(contentsOf: url))
        return LogTranscriptNormaliser(renames: table.renames)
    }

    func normalise(_ line: CapturingLoggingPlugin.Line) -> CapturingLoggingPlugin.Line {
        .init(
            shape: line.shape,
            // Category and namespace are compared exactly: the gate must fail if a fork's name leaks into the
            // scope a line is logged under (for example `EngineAuthFactorType` for `AuthFactorType`).
            category: line.category,
            namespace: line.namespace,
            level: line.level,
            message: normaliseText(line.message)
        )
    }

    func normaliseText(_ text: String) -> String {
        var text = text
        // 1. #fileID module prefix
        text = replace(#"\b(?:AWSCognitoAuthPlugin|InternalAWSCognitoAuth)/([A-Za-z0-9_+\-]+\.swift)"#, in: text, with: "<module>/$1")
        // 2. The rename table in reverse, qualified first
        for rename in messageRenames {
            text = text.replacingOccurrences(
                of: "\(rename.to.module).\(rename.to.name)",
                with: "\(rename.from.module).\(rename.from.name)"
            )
        }
        for rename in messageRenames {
            text = replace(#"\b\#(rename.to.name)\b"#, in: text, with: rename.from.name)
        }
        // 3. Types that moved unchanged
        text = text.replacingOccurrences(of: "InternalAWSCognitoAuth.", with: "AWSCognitoAuthPlugin.")
        // 4. Run-to-run values
        text = replace(#"eyJ[A-Za-z0-9_\-]*\.[A-Za-z0-9_\-]*\.[A-Za-z0-9_\-]*"#, in: text, with: "<jwt>")
        text = replace(#"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"#, in: text, with: "<uuid>")
        text = replace(#"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}"#, in: text, with: "<date>")
        text = replace(#"0x[0-9a-fA-F]{6,16}"#, in: text, with: "0x<address>")
        // SRP's ephemeral key pair is random per sign-in; only its masked ends are printed.
        text = replace(#"<(privateKey|publicKey) [0-9A-Fa-f]*\**[0-9A-Fa-f]*>"#, in: text, with: "<$1 <random>>")
        return SwiftCollectionPrint.sortingDictionaryKeys(text)
    }

    private func replace(_ pattern: String, in text: String, with template: String) -> String {
        text.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
    }
}

/// Printed Swift dictionaries (`[key: value, …]`) list their entries in hash order, which changes from
/// process to process. Log lines print them directly and, escaped, inside the string values of printed
/// `NSDictionary`s (which are already key-sorted). This sorts the entries of every dictionary-like
/// bracketed list, innermost first, so two prints of equal dictionaries compare equal. Lists whose entries
/// are not all `key: value` pairs (arrays) keep their order.
///
/// Entries are split on `, ` outside parentheses. A value that itself contains `, ` is split too, but
/// consistently, so equal dictionaries still normalise equally.
enum SwiftCollectionPrint {

    private static let innermostList = try! NSRegularExpression(pattern: #"\[([^\[\]]*)\]"#)
    private static let keyValue = try! NSRegularExpression(pattern: #"^(?:\\?"[^"\\]*\\?"|[A-Za-z_][A-Za-z0-9_.]*): "#)

    static func sortingDictionaryKeys(_ text: String) -> String {
        var text = text
        var done: [String] = []
        // Rewrite the innermost list, then hide it behind a placeholder so its parent becomes innermost.
        while let match = innermostList.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let whole = Range(match.range, in: text),
              let inner = Range(match.range(at: 1), in: text) {
            done.append("[\(sortedIfDictionary(String(text[inner])))]")
            text.replaceSubrange(whole, with: "\u{1}\(done.count - 1)\u{2}")
        }
        // Restore, innermost last-in first-out.
        while let open = text.lastIndex(of: "\u{1}"), let close = text[open...].firstIndex(of: "\u{2}"),
              let index = Int(text[text.index(after: open) ..< close]) {
            text.replaceSubrange(open ... close, with: done[index])
        }
        return text
    }

    private static func sortedIfDictionary(_ inner: String) -> String {
        let entries = topLevelEntries(inner)
        let isDictionary = entries.count > 1 && entries.allSatisfy { entry in
            keyValue.firstMatch(in: entry, range: NSRange(entry.startIndex..., in: entry)) != nil
        }
        return isDictionary ? entries.sorted().joined(separator: ", ") : inner
    }

    /// Splits on `, ` outside parentheses and outside quotes. Any `"` toggles quoting, so this works both
    /// for a plain print and for one escaped (`\"`) inside another string.
    private static func topLevelEntries(_ text: String) -> [String] {
        var entries: [String] = []
        var current = ""
        var depth = 0
        var quoted = false
        let characters = Array(text)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "\"" { quoted.toggle() }
            if !quoted, character == "(" { depth += 1 }
            if !quoted, character == ")" { depth -= 1 }
            if !quoted, depth == 0, character == ",", index + 1 < characters.count, characters[index + 1] == " " {
                entries.append(current)
                current = ""
                index += 2
                continue
            }
            current.append(character)
            index += 1
        }
        entries.append(current)
        return entries
    }
}
