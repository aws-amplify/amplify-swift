//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// Each part must be at least 5 MB in size, except the last part.
// https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html

// Documented Limits
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html

/// Minimum size for upload part. (5 MB)
let minimumPartSize = Bytes.megabytes(5).bytes
/// Maximum size for upload part. (5 GB)
let maximumPartSize = Bytes.gigabytes(5).bytes
/// Minimum Object Size. (1 byte)
let minimumObjectSize = Bytes.bytes(1).bytes
/// Maximum Object Size. (5 TB)
let maximumObjectSize = Bytes.terabytes(5).bytes
/// Miniumum part count.
let minimumPartCount = 1
/// Maxiumum part count.
let maximumPartCount = 10_000

enum StorageUploadPart {
    case pending(bytes: Int)
    case queued(bytes: Int)
    case inProgress(bytes: Int, bytesTransferred: Int, taskIdentifier: TaskIdentifier)
    case failed(bytes: Int, bytesTransferred: Int, error: Error)
    case completed(bytes: Int, eTag: String)

    var isPending: Bool {
        if case .pending = self {
            return true
        } else {
            return false
        }
    }

    var isQueued: Bool {
        if case .queued = self {
            return true
        } else {
            return false
        }
    }

    var inProgress: Bool {
        if case .inProgress = self {
            return true
        } else {
            return false
        }
    }

    var failed: Bool {
        if case .failed = self {
            return true
        } else {
            return false
        }
    }

    var completed: Bool {
        if case .completed = self {
            return true
        } else {
            return false
        }
    }

    var progress: Double {
        let result: Double
        switch self {
        case .pending, .queued:
            result = 0.0
        case .inProgress(let bytes, let bytesTransferred, _):
            result = bytes > 0 ? Double(bytesTransferred) / Double(bytes) : 0.0
        case .failed:
            result = 0.0
        case .completed:
            result = 1.0
        }

        return result
    }

    var bytes: Int {
        let result: Int
        switch self {
        case .pending(let bytes), .queued(let bytes):
            result = bytes
        case .inProgress(let bytes, _, _):
            result = bytes
        case .failed(let bytes, _, _):
            result = bytes
        case .completed(let bytes, _):
            result = bytes
        }

        return result
    }

    var bytesTransferred: Int {
        let result: Int
        switch self {
        case .pending, .queued, .failed:
            result = 0
        case .inProgress(_, let bytesTransferred, _):
            result = bytesTransferred
        case .completed(let bytes, _):
            result = bytes
        }

        return result
    }

    var eTag: String? {
        let result: String?
        if case .completed(_, let eTag) = self {
            result = eTag
        } else {
            result = nil
        }
        return result
    }

    var error: Error? {
        if case .failed(_, _, let error) = self {
            return error
        } else {
            return nil
        }
    }

    var taskIdentifier: TaskIdentifier? {
        if case .inProgress(_, _, let taskIdentifier) = self {
            return taskIdentifier
        } else {
            return nil
        }
    }
}

typealias StorageUploadParts = [StorageUploadPart]

struct StorageUploadPartSize {
    enum Failure: Error {
        case belowMinimumObjectSize
        case belowMinimumPartSize
        case overMaximumPartSize
        case exceedsSupportedFileSize
        case exceedsMaximumObjectSize
    }
    let size: Int

    static let `default`: StorageUploadPartSize = StorageUploadPartSize()

    private init() {
        self.size = minimumPartSize
    }

    /// Creates custom part size in bytes. Throws if file part is invalid.
    /// - Parameter size: part size
    init(size: Int) throws {
        if size < minimumPartSize {
            throw Failure.belowMinimumPartSize
        } else if size > maximumPartSize {
            throw Failure.overMaximumPartSize
        }
        self.size = size
    }

    /// Creates optimal part size given the file size. Throws if file size is invalid.
    ///
    /// - Parameters:
    ///   - fileSize: file size
    ///   - logger: logger
    init(fileSize: UInt64, logger: Logger = storageLogger) throws {
        guard fileSize >= minimumObjectSize else {
            throw Failure.belowMinimumObjectSize
        }
        guard fileSize <= maximumObjectSize else {
            throw Failure.exceedsMaximumObjectSize
        }

        let defaultSize = Self.default
        let count = Int(ceil(Double(fileSize) / Double(defaultSize.size)))

        if count < maximumPartCount {
            // the vast majority of requests this is the expected return value
            self = defaultSize
            return
        } else {
            // double part size from minimum until number of parts is under limit
            var size = minimumPartSize * 2
            while size < maximumPartSize {
                let count = Int(ceil(Double(fileSize) / Double(size)))
                if count < maximumPartCount {
                    let partSize = try StorageUploadPartSize(size: size)
                    self = partSize
                    return
                }
                // double part size
                size *= 2
                logger.debug("Increased part size to \(size)")
            }
            let partSize = try StorageUploadPartSize(size: maximumPartSize)
            self = partSize
        }
    }

    func offset(for partNumber: PartNumber) -> Int {
        let result = (partNumber - 1) * size
        return result
    }

}

extension Array where Element == StorageUploadPart {
    enum Failure: Error {
        case invalidPartNumber
        case partNotFound
        case partCountBelowLowerLimit
        case partCountOverUpperLimit
        case invalidStateTransition
    }

    init(fileSize: UInt64, partSize: StorageUploadPartSize = .default, logger: Logger = storageLogger) throws {
        let size = partSize.size
        let count = Int(ceil(Double(fileSize) / Double(size)))

        if count < 1 {
            throw Failure.partCountBelowLowerLimit
        } else if count > maximumPartCount {
            logger.error("Part count exceeds upper limit: \(count). Increase part size to reduce part count.")
            throw Failure.partCountOverUpperLimit
        }

        let remainingBytes = Int(fileSize % UInt64(size))
        logger.debug("count = \(count), remainingBytes = \(remainingBytes), size = \(size), totalBytes = \(fileSize)")

        self.init(repeating: .pending(bytes: size), count: count)
        if remainingBytes > 0 {
            logger.debug("Setting remaining bytes: \(remainingBytes)")
            self[count - 1] = .pending(bytes: remainingBytes)
        }
    }

    func find(partNumber: Int) throws -> StorageUploadPart {
        let index = partNumber - 1
        if index < 0 || index > count - 1 {
            throw Failure.invalidPartNumber
        }
        let part = self[index]
        return part
    }
}

extension Sequence where Element == StorageUploadPart {

    /// Indicates that no parts are pending or in progress, but could also be failed.
    var isDone: Bool {
        // swiftlint:disable empty_count
        pending.count + inProgress.count == 0
        // swiftlint:enable empty_count
    }

    /// Indicates that there is at least 1 failed upload part.
    var isFailed: Bool {
        !failed.isEmpty
    }

    var hasPending: Bool {
        contains {
            $0.isPending
        }
    }

    var pending: StorageUploadParts {
        filter { $0.isPending }
    }

    var inProgress: StorageUploadParts {
        filter { $0.inProgress }
    }

    var failed: StorageUploadParts {
        filter { $0.failed }
    }

    var completed: StorageUploadParts {
        filter { $0.completed }
    }

    var totalBytes: Int {
        reduce(into: 0) { result, part in
            result += part.bytes
        }
    }

    var bytesTransferred: Int {
        reduce(into: 0) { result, part in
            result += part.bytesTransferred
        }
    }

    // 0.0 to 1.0
    var percentTransferred: Double {
        if totalBytes > 0, totalBytes >= bytesTransferred {
            return Double(bytesTransferred) / Double(totalBytes)
        } else {
            return -1.0
        }
    }

}
