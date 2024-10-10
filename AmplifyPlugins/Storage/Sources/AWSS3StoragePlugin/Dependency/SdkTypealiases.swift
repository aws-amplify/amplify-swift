//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import ClientRuntime
import Foundation

/// - Tag: NetworkResult
public typealias NetworkResult = (Result<HttpResponse, Error>) -> Void
