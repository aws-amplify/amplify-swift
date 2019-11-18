//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum IdentifyAction {
    case detectCelebrity
    case detectLabels
    case detectEntities
    case detectText(TextFormatType)
}
