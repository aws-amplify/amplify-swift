//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public enum IdentifyAction {

    /// <#Description#>
    case detectCelebrity

    /// <#Description#>
    case detectLabels(LabelType)

    /// <#Description#>
    case detectEntities

    /// <#Description#>
    case detectText(TextFormatType)
}
