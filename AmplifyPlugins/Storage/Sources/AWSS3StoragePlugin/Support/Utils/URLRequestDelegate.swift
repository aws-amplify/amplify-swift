//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Internal protocol that may be to inspect or decorate instances of
/// [URLRequest](x-source-tag://URLRequest) created through the AWSS3StoragePlugin.
///
/// See:
///
/// * [HttpClientEngineProxy](x-source-tag://HttpClientEngineProxy)
///
/// - Tag: URLRequestDelegate
protocol URLRequestDelegate: AnyObject {

    /// Called **before** a [NSURLSessionTask](x-source-tag://NSURLSessionTask) for the
    /// request is created.
    ///
    /// - Tag: URLRequestDelegate.willSend
    func willSend(request: URLRequest)

    /// Called **after** a [NSURLSessionTask](x-source-tag://NSURLSessionTask) for the
    /// request is created.
    ///
    /// - Tag: URLRequestDelegate.didSend
    func didSend(request: URLRequest)
}
