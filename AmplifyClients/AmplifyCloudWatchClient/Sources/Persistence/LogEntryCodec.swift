//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct encode and decode LogEntry
struct LogEntryCodec {

    private static let lineDelimiter = Data([0x0a]) /* '\n' */

    func encode(entry: LogEntry) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        var data = try encoder.encode(entry)
        data.append(Self.lineDelimiter)
        return data
    }

    func decode(data: Data) throws -> LogEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(LogEntry.self, from: data)
    }

    func decode(string: String) throws -> LogEntry? {
        let trimmed = string.trim()
        let data = Data(trimmed.utf8)
        return try decode(data: data)
    }

    func decode(from fileURL: URL) throws -> [LogEntry] {
        guard fileURL.isFileURL else {
            throw CloudWatchError.storage(
                "The log file location is not a valid file URL: \(fileURL)",
                "This is an internal error. Please file a bug report."
            )
        }
        do {
            let data = try Data(contentsOf: fileURL)
            guard let contentAsString = String(data: data, encoding: .utf8) else {
                throw CloudWatchError.storage(
                    "The log file at \(fileURL) could not be decoded as UTF-8",
                    "This is an internal error. Please file a bug report."
                )
            }
            let lines = contentAsString.split(whereSeparator: \.isNewline).map { String($0) }
            let decoder = LogEntryCodec()
            return try lines.compactMap { line in
                return try decoder.decode(string: line)
            }
        } catch let error as CloudWatchError {
            throw error
        } catch {
            throw CloudWatchError.storage(
                "Failed to read log entries from \(fileURL)",
                "This is an internal error. Please file a bug report.",
                error
            )
        }
    }
}
