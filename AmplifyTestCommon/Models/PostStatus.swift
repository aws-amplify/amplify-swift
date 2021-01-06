//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public enum PostStatus: String, EnumPersistable {

    case `private` = "PRIVATE"
    case draft = "DRAFT"
    case published = "PUBLISHED"

}
