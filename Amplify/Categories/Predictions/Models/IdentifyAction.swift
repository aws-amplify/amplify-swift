//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum IdentifyAction {
    case detectCelebrity
    case detectLabels(LabelType)
    case detectEntities
    case detectText(TextFormatType)
}
