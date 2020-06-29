//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//
//  AmplifyDevMenuItem.swift
//  AmplifyDevMenu
//
//  Created by Singh, Abhash Kumar on 6/20/20.
//  Copyright © 2020 Amazon Web Services. All rights reserved.
//

import Foundation

@available(iOS 13.0.0, *)
struct AmplifyDevMenuItem: Identifiable {
    var id = UUID()
    var title: String

    init?(title: String) {

        // The name must not be empty
        guard !title.isEmpty else {
            return nil
        }

        // Initialize stored properties.
        self.title = title
    }
}
