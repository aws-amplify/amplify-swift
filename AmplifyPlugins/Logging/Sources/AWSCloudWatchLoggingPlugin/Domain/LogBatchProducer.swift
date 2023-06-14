//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

/// - Tag: LogBatchProducer
protocol LogBatchProducer {
    /// Publisher that produces individual [LogBatch](x-source-tag://LogBatch) values.
    ///
    /// - Tag: LogBatchProducer.logBatchPublisher
    var logBatchPublisher: AnyPublisher<LogBatch, Never> { get }
}
