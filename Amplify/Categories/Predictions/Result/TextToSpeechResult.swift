//
//  TextToSpeechResult.swift
//  Amplify
//
//  Created by Stone, Nicki on 11/14/19.
//

import Foundation

public struct TextToSpeechResult: ConvertResult {
     public let audioData: Data

    public init(audioData: Data) {
        self.audioData = audioData
    }
}
