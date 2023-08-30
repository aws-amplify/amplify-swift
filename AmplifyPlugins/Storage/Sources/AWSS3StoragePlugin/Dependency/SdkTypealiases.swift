//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSClientRuntime
import ClientRuntime

/// - Tag: SdkResult
//public typealias SdkResult<R, E> = Result<R, SdkError<E>>

/// - Tag: NetworkResult
public typealias NetworkResult = (Result<HttpResponse, Error>) -> Void
