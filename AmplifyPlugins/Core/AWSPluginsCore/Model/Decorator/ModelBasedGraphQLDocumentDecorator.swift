//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol ModelBasedGraphQLDocumentDecorator {
    func decorate(_ document: SingleDirectiveGraphQLDocument, modelType: Model.Type) -> SingleDirectiveGraphQLDocument
}
