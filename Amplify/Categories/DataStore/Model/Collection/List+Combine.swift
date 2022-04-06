//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

@available(iOS 13.0, *)
extension List {

    public typealias LazyListPublisher = AnyPublisher<[Element], DataStoreError>
    
}
