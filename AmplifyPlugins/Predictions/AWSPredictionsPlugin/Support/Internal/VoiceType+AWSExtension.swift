//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Amplify
import AWSPolly

extension VoiceType {

    init?(voice: String?) {
        var type: VoiceType?
        guard let voice = voice else {
            return nil
        }
        for vType in VoiceType.allCases where vType.rawStringValue == voice {
            type = vType
        }
        if let realType = type {
            self = realType
        } else {
            return nil
        }
    }

    var pollyVoiceType: AWSPollyVoiceId {
        switch self {
        case .arabicFemaleZeina:
            return .zeina
        case .chineseFemaleZhiyu:
            return .zhiyu
        case .danishFemaleNaja:
            return .naja
        case .danishMaleMads:
            return .mads
        case .dutchFemaleLotte:
            return .lotte
        case .dutchMaleRuben:
            return .ruben
        case .ausEnglishFemaleNicole:
            return .nicole
        case .ausEnglishMaleRussell:
            return .russell
        case .britEnglishFemaleAmy:
            return .amy
        case .britEnglishFemaleEmma:
            return .emma
        case .britEnglishMaleBrian:
            return .brian
        case .indiEnglishAndHindFemaleAditi:
            return .aditi
        case .indiEnglishFemaleRaveena:
            return .raveena
        case .englishFemaleIvy:
            return .ivy
        case .englishFemaleJoanna:
            return .joanna
        case .englishFemaleKendra:
            return .kendra
        case .englishFemaleKimberly:
            return .kimberly
        case .englishFemaleSalli:
            return .salli
        case .englishMaleJoey:
            return .joey
        case .englishMaleJustin:
            return .justin
        case .englishMaleMatthew:
            return .matthew
        case .welshEnglishMaleGeraint:
            return .geraint
        case .frenchFemaleCeline:
            return .celine
        case .frenchFemaleLea:
            return .lea
        case .frenchMaleMathieu:
            return .mathieu
        case .canadianFrenchFemaleChantal:
            return .chantal
        case .germanFemaleMarlene:
            return .marlene
        case .germanFemaleVicki:
            return .vicki
        case .germanMaleHans:
            return .hans
        case .icelandicFemaleDora:
            return .dora
        case .icelandicMaleKarl:
            return .karl
        case .italianFemaleCarla:
            return .carla
        case .italianFemaleBianca:
            return .bianca
        case .italianMaleGiorgio:
            return .giorgio
        case .japaneseFemaleMizuki:
            return .mizuki
        case .japaneseMaleTakumi:
            return .takumi
        case .koreanFemaleSeoyeon:
            return .seoyeon
        case .norwegianFemaleLiv:
            return .liv
        case .polishFemaleEwa:
            return .ewa
        case .polishFemaleMaja:
            return .maja
        case .polishMaleJacek:
            return .jacek
        case .polishMaleJan:
            return .jan
        case .brazPortugueseFemaleVitoria:
            return .vitoria
        case .brazPortugueseMaleRicardo:
            return .ricardo
        case .euroPortugueseFemaleInes:
            return .ines
        case .euroPortugueseMaleCristiano:
            return .cristiano
        case .romanianFemaleCarmen:
            return .carmen
        case .russianFemaleTatyana:
            return .tatyana
        case .russianMaleMaxim:
            return .maxim
        case .euroSpanishFemaleConchita:
            return .conchita
        case .euroSpanishFemaleLucia:
            return .lucia
        case .euroSpanishMaleEnrique:
            return .enrique
        case .mexSpanishFemaleMia:
            return .mia
        case .usSpanishFemalePenelope:
            return .penelope
        case .usSpanishMaleMiguel:
            return .miguel
        case .swedishFemaleAstrid:
            return .astrid
        case .turkishFemaleFiliz:
            return .filiz
        case .welshFemaleGwyneth:
            return .gwyneth
        }
    }

    var rawStringValue: String {
        switch self {
        case .arabicFemaleZeina:
            return "Zeina"
        case .ausEnglishFemaleNicole:
            return "Nicole"
        case .ausEnglishMaleRussell:
            return "Russell"
        case .brazPortugueseFemaleVitoria:
            return "Vitoria"
        case .brazPortugueseMaleRicardo:
            return "Ricardo"
        case .britEnglishFemaleAmy:
            return "Amy"
        case .britEnglishFemaleEmma:
            return "Emma"
        case .britEnglishMaleBrian:
            return "Brian"
        case .canadianFrenchFemaleChantal:
            return "Chantal"
        case .chineseFemaleZhiyu:
            return "Zhiyu"
        case .danishFemaleNaja:
            return "Naja"
        case .danishMaleMads:
            return "Mads"
        case .dutchFemaleLotte:
            return "Lotte"
        case .dutchMaleRuben:
            return "Ruben"
        case .indiEnglishAndHindFemaleAditi:
            return "Aditi"
        case .indiEnglishFemaleRaveena:
            return "Raveena"
        case .englishFemaleIvy:
            return "Ivy"
        case .englishFemaleJoanna:
            return "Joanna"
        case .englishFemaleKendra:
            return "Kendra"
        case .englishFemaleKimberly:
            return "Kimberly"
        case .englishFemaleSalli:
            return "Salli"
        case .englishMaleJoey:
            return "Joey"
        case .englishMaleJustin:
            return "Justin"
        case .englishMaleMatthew:
            return "Matthew"
        case .welshEnglishMaleGeraint:
            return "Geraint"
        case .frenchFemaleCeline:
            return "Celine"
        case .frenchFemaleLea:
            return "Lea"
        case .frenchMaleMathieu:
            return "Mathieu"
        case .germanFemaleMarlene:
            return "Marlene"
        case .germanFemaleVicki:
            return "Vicki"
        case .germanMaleHans:
            return "Hans"
        case .icelandicFemaleDora:
            return "Dora"
        case .icelandicMaleKarl:
            return "Karl"
        case .italianFemaleCarla:
            return "Carla"
        case .italianFemaleBianca:
            return "Bianca"
        case .italianMaleGiorgio:
            return "Giorgio"
        case .japaneseFemaleMizuki:
            return "Mizuki"
        case .japaneseMaleTakumi:
            return "Takumi"
        case .koreanFemaleSeoyeon:
            return "Seoyeon"
        case .norwegianFemaleLiv:
            return "Liv"
        case .polishFemaleEwa:
            return "Ewa"
        case .polishFemaleMaja:
            return "Maja"
        case .polishMaleJacek:
            return "Jacek"
        case .polishMaleJan:
            return "Jan"
        case .euroPortugueseFemaleInes:
            return "Ines"
        case .euroPortugueseMaleCristiano:
            return "Cristiano"
        case .romanianFemaleCarmen:
            return "Carmen"
        case .russianFemaleTatyana:
            return "Tatyana"
        case .russianMaleMaxim:
            return "Maxim"
        case .euroSpanishFemaleConchita:
            return "Conchita"
        case .euroSpanishFemaleLucia:
            return "Lucia"
        case .euroSpanishMaleEnrique:
            return "Enrique"
        case .mexSpanishFemaleMia:
            return "Mia"
        case .usSpanishFemalePenelope:
            return "Penelope"
        case .usSpanishMaleMiguel:
            return "Miguel"
        case .swedishFemaleAstrid:
            return "Astrid"
        case .turkishFemaleFiliz:
            return "Filiz"
        case .welshFemaleGwyneth:
            return "Gwyneth"
        }
    }
}
