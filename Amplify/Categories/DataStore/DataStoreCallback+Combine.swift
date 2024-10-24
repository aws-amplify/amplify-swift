//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

public extension DataStoreResult where Success: Any {

    func resolve(promise: Future<Success, DataStoreError>.Promise) {
        switch self {
        case .success(let result):
            promise(.success(result))
        case .failure(let error):
            promise(.failure(causedBy: error))
        }
    }
}
