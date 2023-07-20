//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// swiftlint:disable line_length

enum StorageTransferType {
    enum RawValues: Int, RawRepresentable {
        case getPreSignedURL = 0
        case download = 1
        case upload = 2
        case multiPartUpload = 3
        case multiPartUploadPart = 4
        case list = 5
        case remove = 6
    }

    case getPreSignedURL(onEvent: AWSS3StorageServiceBehavior.StorageServiceGetPreSignedURLEventHandler)
    case download(onEvent: AWSS3StorageServiceBehavior.StorageServiceDownloadEventHandler)
    case upload(onEvent: AWSS3StorageServiceBehavior.StorageServiceUploadEventHandler)
    case multiPartUpload(onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler)
    case multiPartUploadPart(uploadId: UploadID, partNumber: PartNumber)
    case list(onEvent: AWSS3StorageServiceBehavior.StorageServiceListEventHandler)
    case remove(onEvent: AWSS3StorageServiceBehavior.StorageServiceDeleteEventHandler)

    var name: String {
        switch self {
        case .getPreSignedURL:
            return "GetPreSignedURL"
        case .download:
            return "Download"
        case .upload:
            return "Upload"
        case .multiPartUpload:
            return "MultiPartUpload"
        case .multiPartUploadPart:
            return "MultiPartUploadPart"
        case .list:
            return "List"
        case .remove:
            return "Remove"
        }
    }

    var uploadId: UploadID? {
        if case .multiPartUploadPart(let uploadId, _) = self {
            return uploadId
        } else {
            return nil
        }
    }

    var partNumber: PartNumber? {
        if case .multiPartUploadPart(_, let partNumber) = self {
            return partNumber
        } else {
            return nil
        }
    }

    var rawValue: Int {
        let result: Int
        switch self {
        case .getPreSignedURL:
            result = StorageTransferType.RawValues.getPreSignedURL.rawValue
        case .download:
            result = StorageTransferType.RawValues.download.rawValue
        case .upload:
            result = StorageTransferType.RawValues.upload.rawValue
        case .multiPartUpload:
            result = StorageTransferType.RawValues.multiPartUpload.rawValue
        case .multiPartUploadPart:
            result = StorageTransferType.RawValues.multiPartUploadPart.rawValue
        case .list:
            result = StorageTransferType.RawValues.list.rawValue
        case .remove:
            result = StorageTransferType.RawValues.remove.rawValue
        }
        return result
    }

    func fail(error: Error) {
        let storageError = StorageError(error: error)

        switch self {
        case .getPreSignedURL(let onEvent):
            onEvent(.failed(storageError))
        case .download(let onEvent):
            onEvent(.failed(storageError))
        case .upload(let onEvent):
            onEvent(.failed(storageError))
        case .multiPartUpload(let onEvent):
            onEvent(.failed(storageError))
        case .multiPartUploadPart:
            break
        case .list(let onEvent):
            onEvent(.failed(storageError))
        case .remove(let onEvent):
            onEvent(.failed(storageError))
        }
    }

    func notify(progress: Progress) {
        switch self {
        case .download(let onEvent):
            onEvent(.inProcess(progress))
        case .upload(let onEvent):
            onEvent(.inProcess(progress))
        case .multiPartUpload(let onEvent):
            onEvent(.inProcess(progress))
        default:
            return
        }
    }

    struct Defaults {
        static func createDefaultTransferType(persistableTransferTask: StoragePersistableTransferTask) -> StorageTransferType? {
            let result: StorageTransferType

            guard let value = StorageTransferType.RawValues(rawValue: persistableTransferTask.transferTypeRawValue) else {
                return nil
            }

            switch value {
            case .getPreSignedURL:
                result = .getPreSignedURL(onEvent: defaultGetPreSignedURLEvent)
            case .download:
                result = .download(onEvent: defaultDownloadEvent)
            case .upload:
                result = .upload(onEvent: defaultUploadEvent)
            case .multiPartUpload:
                result = .multiPartUpload(onEvent: defaultMultiPartUploadEvent)
            case .multiPartUploadPart:
                guard let uploadId = persistableTransferTask.uploadId,
                        let partNumber = persistableTransferTask.partNumber else {
                    return nil
                }
                result = .multiPartUploadPart(uploadId: uploadId, partNumber: partNumber)
            case .list:
                result = .list(onEvent: defaultListEvent)
            case .remove:
                result = .remove(onEvent: defaultRemoveEvent)
            }

            return result
        }

        private static var defaultGetPreSignedURLEvent: AWSS3StorageServiceBehavior.StorageServiceGetPreSignedURLEventHandler = { _ in  }
        private static var defaultDownloadEvent: AWSS3StorageServiceBehavior.StorageServiceDownloadEventHandler = { _ in  }
        private static var defaultUploadEvent: AWSS3StorageServiceBehavior.StorageServiceUploadEventHandler = { _ in }
        private static var defaultMultiPartUploadEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { _ in }
        private static var defaultListEvent: AWSS3StorageServiceBehavior.StorageServiceListEventHandler = { _ in  }
        private static var defaultRemoveEvent: AWSS3StorageServiceBehavior.StorageServiceDeleteEventHandler = { _ in  }
    }
}
