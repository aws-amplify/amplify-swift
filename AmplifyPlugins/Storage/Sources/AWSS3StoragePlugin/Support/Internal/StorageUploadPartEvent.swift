//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum StorageUploadPartEvent {
    case queued(partNumber: PartNumber)
    case started(partNumber: PartNumber, taskIdentifier: TaskIdentifier)
    case progressUpdated(partNumber: PartNumber, bytesTransferred: Int, taskIdentifier: TaskIdentifier)
    case completed(partNumber: PartNumber, eTag: String, taskIdentifier: TaskIdentifier)
    case failed(partNumber: PartNumber, error: Error)

    var number: Int {
        switch self {
        case .queued(let number),
                .started(let number, _),
                .progressUpdated(let number, _, _),
                .completed(let number, _, _),
                .failed(let number, _):
            return number
        }
    }

    var taskIdentifier: TaskIdentifier? {
        let result: Int?
        switch self {
        case .started(_, let taskIdentifier),
                .progressUpdated(_, _, let taskIdentifier),
                .completed(_, _, let taskIdentifier):
            result = taskIdentifier
        default:
            result = nil
        }
        return result
    }

    var isCompleted: Bool {
        let result: Bool
        if case .completed = self {
            result = true
        } else {
            result = false
        }
        return result
    }

    var error: Error? {
        let result: Error?
        if case .failed(_, let error) = self {
            result = error
        } else {
            result = nil
        }
        return result
    }

}
