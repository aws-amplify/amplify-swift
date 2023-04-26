//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Predictions {
    public enum Convert {
        public struct Request<Input, Options, Output> {
            public let input: Input
            @_spi(PredictionsConvertRequestKind)
            public let kind: Kind
        }
    }
}

extension Predictions.Convert.Request {
    @_spi(PredictionsConvertRequestKind)
    public enum Kind {
        public typealias BidirectionalLift<T, U> = ((T) -> U, (U) -> T)

        // TODO: Add request kind cases
    }
}
