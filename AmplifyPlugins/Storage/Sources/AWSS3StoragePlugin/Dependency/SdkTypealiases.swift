//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SmithyHTTPAPI

/// - Tag: NetworkResult
public typealias NetworkResult = (Result<HTTPResponse, Error>) -> Void
