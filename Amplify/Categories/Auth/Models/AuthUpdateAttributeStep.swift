//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public enum AuthUpdateAttributeStep {

    /// <#Description#>
    case confirmAttributeWithCode(AuthCodeDeliveryDetails, AdditionalInfo?)

    /// <#Description#>
    case done
}
