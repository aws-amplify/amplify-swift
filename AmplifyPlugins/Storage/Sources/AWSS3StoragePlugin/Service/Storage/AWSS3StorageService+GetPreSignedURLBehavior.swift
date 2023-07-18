//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import ClientRuntime
import Foundation
import Amplify

extension AWSS3StorageService {

    func getPreSignedURL(serviceKey: String,
                         signingOperation: AWSS3SigningOperation,
                         expires: Int) async throws -> URL {
        return try await preSignedURLBuilder.getPreSignedURL(key: serviceKey, signingOperation: signingOperation, expires: Int64(expires))
    }

    func validateObjectExistence(serviceKey: String) async throws {
        do {
            _ = try await self.client.headObject(input: .init(
                bucket: self.bucket,
                key: serviceKey
            ))
        } catch let error as HeadObjectOutputError {
            // Because the AWS SDK may wrap the HeadObjectOutputError in an
            // SdkError<HeadObjectOutputError>, it is necessary to do some more
            // complex error pattern matching.
            throw Self.validateObjectExistenceMap(headObjectOutputError: error, serviceKey: serviceKey)
        } catch let error as SdkError<HeadObjectOutputError> {
            throw Self.validateObjectExistenceMap(sdkError: error, serviceKey: serviceKey)
        }
    }

    private static func validateObjectExistenceMap(sdkError: SdkError<HeadObjectOutputError>, serviceKey: String) -> StorageError {
        switch sdkError {
        case .service(let serviceError, _):
            return validateObjectExistenceMap(headObjectOutputError: serviceError, serviceKey: serviceKey)
        case .client(let clientError, _):
            switch clientError {
            case .retryError(let error as HeadObjectOutputError):
                return validateObjectExistenceMap(headObjectOutputError: error, serviceKey: serviceKey)
            case .retryError(let error as SdkError<HeadObjectOutputError>):
                return validateObjectExistenceMap(sdkError: error, serviceKey: serviceKey)
            default:
                return validateObjectExistenceMap(unexpectedError: clientError, serviceKey: serviceKey)
            }
        case .unknown(let error):
            return validateObjectExistenceMap(unexpectedError: error, serviceKey: serviceKey)
        }
    }

    private static func validateObjectExistenceMap(headObjectOutputError: HeadObjectOutputError, serviceKey: String) -> StorageError {
        switch headObjectOutputError {
        case .notFound:
            return StorageError.keyNotFound(
                serviceKey,
                "Unable to generate URL for non-existent key: \(serviceKey)",
                "Please ensure the key is valid or the object has been uploaded",
                nil
            )
        default:
            return validateObjectExistenceMap(unexpectedError: headObjectOutputError, serviceKey: serviceKey)
        }
    }

    private static func validateObjectExistenceMap(unexpectedError: Error?, serviceKey: String) -> StorageError {
        return StorageError.unknown("Unable to get object information for \(serviceKey)", unexpectedError)
    }
}
