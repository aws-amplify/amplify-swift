//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct encode and decode LogEntry 
struct LogEntryCodec {

    private static let lineDelimiter = Data([0x0A]) /* '\n' */

    enum DecodingError: Error {
        case stringNotUtf8(String)
        case invalidScheme(log: URL)
        case invalidEncoding(log: URL)
    }
    
    func encode(entry: LogEntry) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = .sortedKeys
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
        guard let data = trimmed.data(using: .utf8) else {
            throw DecodingError.stringNotUtf8(string)
        }
        return try decode(data: data)
    }
    
    func decode(from fileURL: URL) throws -> [LogEntry] {
        guard fileURL.isFileURL else {
            throw DecodingError.invalidScheme(log: fileURL)
        }
        let data = try Data(contentsOf: fileURL)
        guard let contentAsString = String(data: data, encoding: .utf8) else {
            throw DecodingError.invalidEncoding(log: fileURL)
        }
        let lines = contentAsString.split(whereSeparator: \.isNewline).map { String($0) }
        let decoder = LogEntryCodec()
        return try lines.compactMap { line in
            return try decoder.decode(string: line)
        }
    }
}
