//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSS3StorageService {

    var allTransfers: AmplifyAsyncSequence<StorageTransfer> {
        get async throws {
            Fatal.notImplemented()

//            try await withCheckedThrowingContinuation({ continuation in
//                storageTransferDatabase.recover(urlSession: urlSession) { result in
//                    do {
//                        let pairs = try result.get()
//
//                        let sequence = AmplifyAsyncSequence<StorageTransfer>()
//                        continuation.resume(returning: sequence)
//                        for pair in pairs {
//                            let transfer: StorageTransfer!
//                            // TODO: implement
//                            try await sequence.send(transfer)
//                        }
//
//                    } catch {
//                        continuation.resume(throwing: error)
//                    }
//                }
//            })
            // TODO: connect with StorageTransferDatabase
        }
    }

}
