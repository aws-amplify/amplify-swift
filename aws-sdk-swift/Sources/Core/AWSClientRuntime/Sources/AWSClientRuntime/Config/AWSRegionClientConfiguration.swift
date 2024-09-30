//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AWSRegionClientConfiguration {

    /// The AWS region to use, i.e. `us-east-1` or `us-west-2`, etc.
    ///
    /// If no region is specified here, one must be specified in the `~/.aws/configuration` file.
    var region: String? { get set }

    /// The signing region to be used for signing AWS requests.
    ///
    /// If none is specified, it is supplied by the SDK.
    var signingRegion: String? { get set }
}
