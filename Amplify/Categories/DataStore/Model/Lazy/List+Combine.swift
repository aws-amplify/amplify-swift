//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Combine

public extension List {

    typealias LazyListPublisher = AnyPublisher<[Element], DataStoreError>

}
#endif
