//
//  IdentifyFacesResult.swift
//  Amplify
//
//  Created by Stone, Nicki on 11/8/19.
//

import Foundation

public struct IdentifyCelebritiesResult: IdentifyResult {
    public let celebrities: [Celebrity]

    public init(celebrities: [Celebrity]) {
        self.celebrities = celebrities
    }
}


