//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
import Amplify

// swiftlint:disable cyclomatic_complexity
extension AWSPollyVoiceId {
    // swiftlint:disable function_body_length
    static func from(voiceType: VoiceType) -> AWSPollyVoiceId {
        guard case let .voice(name) = voiceType else {
            return .ivy
        }
        switch name {
        case "Ivy":
            return .ivy
        case "Chantal":
            return .chantal
        case "Gwyneth":
            return .gwyneth
        case "Filiz":
            return .filiz
        case "Astrid":
            return .astrid
        case "Miguel":
            return .miguel
        case "Penelope":
            return .penelope
        case "Enrique":
            return .enrique
        case "Lucia":
            return .lucia
        case "Conchita":
            return .conchita
        case "Maxim":
            return .maxim
        case "Tatyana":
            return .tatyana
        case "Carmen":
            return .carmen
        case "Cristiano":
            return .cristiano
        case "Ines":
            return .ines
        case "Ricardo":
            return .ricardo
        case "Vitoria":
            return .vitoria
        case "Jan":
            return .jan
        case "Jacek":
            return .jacek
        case "Maja":
            return .maja
        case "Ewa":
            return .ewa
        case "Liv":
            return .liv
        case "Seoyeon":
            return .seoyeon
        case "Takumi":
            return .takumi
        case "Mizuki":
            return .mizuki
        case "Giorgio":
            return .giorgio
        case "Bianca":
            return .bianca
        case "Carla":
            return .carla
        case "Karl":
            return .karl
        case "Dora":
            return .dora
        case "Hans":
            return .hans
        case "Vicki":
            return .vicki
        case "Marlene":
            return .marlene
        case "Mathieu":
            return .mathieu
        case "Lea":
            return .lea
        case "Celine":
            return .celine
        case "Geraint":
            return .geraint
        case "Matthew":
            return .matthew
        case "Justin":
            return .justin
        case "Joey":
            return .joey
        case "Salli":
            return .salli
        case "Kimberly":
            return .kimberly
        case "Kendra":
            return .kendra
        case "Joanna":
            return .joanna
        case "Raveena":
            return .raveena
        case "Aditi":
            return .aditi
        case "Brian":
            return .brian
        case "Emma":
            return .emma
        case "Amy":
            return .amy
        case "Russell":
            return .russell
        case "Nicole":
            return .nicole
        case "Ruben":
            return .ruben
        case "Lotte":
            return .lotte
        case "Mads":
            return .mads
        case "Naja":
            return .naja
        case "Zhiyu":
            return .zhiyu
        case "Zeina":
            return .zeina
        default:
            return .ivy
        }
    }
}
