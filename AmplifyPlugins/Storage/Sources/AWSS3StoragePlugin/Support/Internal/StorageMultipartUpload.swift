//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

enum StorageMultipartUpload {
    enum Failure: Error {
        case invalidStateTransition(reason: String)
        case invalidateParts(reason: String)
    }

    case none
    case creating
    case created(uploadId: UploadID, uploadFile: UploadFile)
    case paused(uploadId: UploadID, uploadFile: UploadFile, partSize: StorageUploadPartSize, parts: StorageUploadParts)
    case parts(uploadId: UploadID, uploadFile: UploadFile, partSize: StorageUploadPartSize, parts: StorageUploadParts)
    case completing(taskIdentifier: TaskIdentifier)
    case completed(uploadId: UploadID)
    case aborting(uploadId: UploadID, error: Error?)
    case aborted(uploadId: UploadID, error: Error?)
    case failed(uploadId: UploadID?, parts: StorageUploadParts?, error: Error)

    init(uploadId: UploadID, uploadFile: UploadFile, partSize: StorageUploadPartSize, parts: StorageUploadParts) {
        self = .parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
    }

    var uploadFile: UploadFile? {
        switch self {
        case .created(_, let uploadFile),
                .parts(_, let uploadFile, _, _):
            return uploadFile
        default:
            return nil
        }
    }

    var uploadId: UploadID? {
        switch self {
        case .created(let uploadId, _),
                .parts(let uploadId, _, _, _),
                .completed(let uploadId),
                .aborting(let uploadId, _),
                .aborted(let uploadId, _):
            return uploadId
        default:
            return nil
        }
    }

    var partSize: StorageUploadPartSize? {
        let result: StorageUploadPartSize?
        switch self {
        case .parts(_, _, let partSize, _):
            result = partSize
        default:
            result = nil
        }
        return result
    }

    var taskIdentifier: TaskIdentifier? {
        let result: Int?
        switch self {
        case .completing(let taskIdentifier):
            result = taskIdentifier
        default:
            result = nil
        }
        return result
    }

    var parts: StorageUploadParts? {
        if case .parts(_, _, _, let parts) = self {
            return parts
        } else {
            return nil
        }
    }

    var hasPendingParts: Bool {
        (parts ?? []).hasPending
    }

    var hasParts: Bool {
        if case .parts = self {
            return true
        } else {
            return false
        }
    }

    var isCompleted: Bool {
        if case .completed = self {
            return true
        } else {
            return false
        }
    }

    var isPaused: Bool {
        if case .paused = self {
            return true
        } else {
            return false
        }
    }

    var isAborted: Bool {
        if case .aborted = self {
            return true
        } else {
            return false
        }
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        } else {
            return false
        }
    }

    var pendingPartNumbers: [Int] {
        guard let parts = parts else {
            return []
        }
        let allNumbers = Array(1 ... parts.count)
        let result: [Int] = allNumbers.reduce(into: []) { numbers, number in
            if parts[number - 1].isPending {
                numbers.append(number)
            }
        }
        return result
    }

    var partsCompleted: Bool {
        guard let parts = parts else {
            return false
        }
        let result = parts.completed.count == parts.count
        return result
    }

    var partsFailed: Bool {
        guard let parts = parts else {
            return false
        }
        let result = !parts.failed.isEmpty
        return result
    }

    func part(for number: PartNumber) -> StorageUploadPart? {
        guard let parts = parts,
              parts.count >= number else { return nil }
        let part = parts[number - 1]
        return part
    }

    func validateForCompletion() throws {
        guard case .parts(let uploadId, let uploadFile, let partSize, let parts) = self else {
            throw Failure.invalidateParts(reason: "not prepared to complete")
        }

        if uploadId.isEmpty {
            throw Failure.invalidateParts(reason: "uploadId is not valid")
        }

        if partSize.size < Bytes.megabytes(5).bytes {
            throw Failure.invalidateParts(reason: "parts size is below minimim size")
        }

        for part in parts {
            if part.eTag == nil || part.eTag?.isEmpty ?? false {
                throw Failure.invalidateParts(reason: "part has invalid eTag")
            }
        }

        let totalBytes = parts.reduce(into: 0) { result, part in
            result += part.bytes
        }

        if uploadFile.size != totalBytes {
            throw Failure.invalidateParts(reason: "total bytes uploaded does not match file size")
        }
    }

    // swiftlint:disable cyclomatic_complexity
    mutating func transition(multipartUploadEvent: StorageMultipartUploadEvent, logger: Logger = storageLogger) throws {
        switch multipartUploadEvent {
        case .creating:
            self = .creating
        case .created(let uploadFile, let uploadId):
            self = .created(uploadId: uploadId, uploadFile: uploadFile)
            try createParts(uploadFile: uploadFile, uploadId: uploadId, logger: logger)
        case .pausing:
            switch self {
            case .parts(let uploadId, let uploadFile, let partSize, let parts):
                self = .paused(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
            default:
                throw Failure.invalidStateTransition(reason: "Cannot abort from current state: \(self)")
            }
        case .resuming:
            switch self {
            case .paused(let uploadId, let uploadFile, let partSize, let parts):
                self = .parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
            default:
                throw Failure.invalidStateTransition(reason: "Cannot abort from current state: \(self)")
            }
            break
        case .completing(let taskIdentifier):
            self = .completing(taskIdentifier: taskIdentifier)
        case .completed(let uploadId):
            switch self {
            case .parts:
                self = .completed(uploadId: uploadId)
            default:
                throw Failure.invalidStateTransition(reason: "Cannot complete from current state: \(self)")
            }
        case .aborting(let error):
            if let uploadId = uploadId {
                self = .aborting(uploadId: uploadId, error: error)
            } else {
                throw Failure.invalidStateTransition(reason: "Cannot abort from current state: \(self)")
            }
        case .aborted(let uploadId, let error):
            switch self {
            case .created, .parts, .aborting:
                self = .aborted(uploadId: uploadId, error: error)
            default:
                throw Failure.invalidStateTransition(reason: "Cannot abort from current state: \(self)")
            }
        case .failed(let uploadId, let error):
            switch self {
            case .none:
                self = .failed(uploadId: uploadId, parts: nil, error: error)
            case .parts(_, _, _, let parts):
                self = .failed(uploadId: uploadId, parts: parts, error: error)
            default:
                throw Failure.invalidStateTransition(reason: "Cannot fail from current state: \(self)")
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity

    mutating func transition(uploadPartEvent: StorageUploadPartEvent) throws {
        guard case .parts(let uploadId, let uploadFile, let partSize, var parts) = self else {
            throw Failure.invalidStateTransition(reason: "Parts are required for this transition: \(uploadPartEvent)")
        }

        let partNumber = uploadPartEvent.number

        guard partNumber <= parts.count else {
            let reason = "Number out of bounds for parts: \(partNumber) of \(parts.count)"
            throw Failure.invalidStateTransition(reason: reason)
        }

        let part = try parts.find(partNumber: partNumber)
        let index = partNumber - 1

        switch uploadPartEvent {
        case .queued:
            parts[index] = .queued(bytes: part.bytes)
        case .started(_, let taskIdentifier):
            parts[index] = .inProgress(bytes: part.bytes, bytesTransferred: 0, taskIdentifier: taskIdentifier)
        case .progressUpdated(_, let bytesTransferred, _):
            guard case .inProgress(let bytes, _, let taskIdentifier) = part else {
                throw Failure.invalidStateTransition(reason: "Part cannot update progress in current state: \(self)")
            }
            parts[index] = .inProgress(bytes: bytes, bytesTransferred: bytesTransferred, taskIdentifier: taskIdentifier)
        case .completed(_, let eTag, _):
            guard case .inProgress(let bytes, _, _) = part else {
                throw Failure.invalidStateTransition(reason: "Part cannot be completed in current state: \(self)")
            }
            parts[index] = StorageUploadPart.completed(bytes: bytes, eTag: eTag)
        case .failed:
            // handle part failure in the session with Transfer Task which has retry count and limit
            break
        }
        self = .parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
    }

    mutating func fail(error: Error) {
        self = .failed(uploadId: uploadId, parts: parts, error: error)
    }

    private mutating func createParts(uploadFile: UploadFile,
                                      uploadId: UploadID,
                                      logger: Logger = storageLogger) throws {
        let partSize = try StorageUploadPartSize(fileSize: uploadFile.size)
        let parts = try StorageUploadParts(fileSize: uploadFile.size, partSize: partSize, logger: logger)
        self = .parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
    }
}
