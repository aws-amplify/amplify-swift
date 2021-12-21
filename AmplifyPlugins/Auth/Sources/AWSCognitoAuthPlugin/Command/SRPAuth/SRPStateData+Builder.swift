//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

//extension SRPStateData {
//    struct Builder: hierarchical_state_machine_swift.Builder {
//        typealias Product = SRPStateData
//
//        var username: String
//        var password: String
//        var srpPublicKeyBytes: [UInt8]
//        var srpPrivateKeyBytes: [UInt8]
//
//        init(
//            username: String = "",
//            password: String = "",
//            srpPublicKeyBytes: [UInt8] = [],
//            srpPrivateKeyBytes: [UInt8] = []
//        ) {
//            self.username = username
//            self.password = password
//            self.srpPublicKeyBytes = srpPublicKeyBytes
//            self.srpPrivateKeyBytes = srpPrivateKeyBytes
//        }
//
//        init(_ previousProduct: Product) {
//            self.username = previousProduct.username
//            self.password = previousProduct.password
//            self.srpPublicKeyBytes = previousProduct.srpPublicKeyBytes
//            self.srpPrivateKeyBytes = previousProduct.srpPrivateKeyBytes
//        }
//
//        func build() -> Product {
//            SRPStateData(
//                username: username,
//                password: password,
//                srpPublicKeyBytes: srpPublicKeyBytes,
//                srpPrivateKeyBytes: srpPrivateKeyBytes
//            )
//        }
//    }
//}

