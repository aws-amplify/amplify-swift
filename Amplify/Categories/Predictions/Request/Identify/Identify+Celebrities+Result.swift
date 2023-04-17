//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension Predictions.Identify.Celebrities {
    /// Results are mapped to IdentifyCelebritiesResult when .detectCelebrity in passed in the type: field
    /// in identify() API
    public struct Result {
        public let celebrities: [Celebrity]

        public init(celebrities: [Celebrity]) {
            self.celebrities = celebrities
        }
    }
}
