//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Log levels are modeled as Ints to allow for easy comparison of levels
public enum LogLevel: Int {
    case error
    case warn
    case info
    case debug
    case verbose
}
