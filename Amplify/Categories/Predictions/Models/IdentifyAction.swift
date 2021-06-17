//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Identification criteria provided to
/// type parameter in identify() API
public enum IdentifyAction {
    case detectCelebrity
    case detectLabels(LabelType)
    case detectEntities
    case detectText(TextFormatType)
}
