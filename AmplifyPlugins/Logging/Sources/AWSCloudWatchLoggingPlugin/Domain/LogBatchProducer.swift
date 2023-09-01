//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

protocol LogBatchProducer {
    var logBatchPublisher: AnyPublisher<LogBatch, Never> { get }
}
