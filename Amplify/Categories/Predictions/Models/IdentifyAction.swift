//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// enum describing different criteria for detection in an image
public enum IdentifyAction {
    case detectCelebrity
    case detectLabels(LabelType)
    case detectEntities
    case detectText(TextFormatType)
}
