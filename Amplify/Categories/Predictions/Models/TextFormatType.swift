//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// describing different text formats passed a type parameter
/// to identify().
/// `plain` is used when detecting text in an image
/// `table`, `form` or `all` are used to do document analysis(find forms, tables)
/// as well as text detection

public enum TextFormatType: String {
    case form
    case table
    case plain
    case all
}
