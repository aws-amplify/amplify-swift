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
                         metadata: [String: String]?,
                         accelerate: Bool?,
                         expires: Int) async throws -> URL {
        return try await preSignedURLBuilder.getPreSignedURL(
            key: serviceKey,
            signingOperation: signingOperation,
            metadata: metadata,
            accelerate: accelerate,
            expires: Int64(expires)
        )
    }

    func validateObjectExistence(serviceKey: String) async throws {
        do {
            _ = try await self.client.headObject(input: .init(
                bucket: self.bucket,
                key: serviceKey
            ))
        } catch is AWSS3.NotFound {
            throw StorageError.keyNotFound(
                serviceKey,
                "Unable to generate URL for non-existent key: \(serviceKey)",
                "Please ensure the key is valid or the object has been uploaded",
                nil
            )
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch {
            throw StorageError.unknown(
                "Unable to get object information for \(serviceKey)",
                error
            )
        }
    }
}
