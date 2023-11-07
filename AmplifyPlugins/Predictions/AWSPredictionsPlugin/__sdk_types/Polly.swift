//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum AWSPolly {}

extension AWSPolly {
    struct InvalidSampleRateException: Error {}
    struct LanguageNotSupportedException: Error {}
    struct ServiceFailureException: Error {}
    struct TextLengthExceededException: Error {}
    struct LexiconNotFoundException: Error {}
    struct InvalidSsmlException: Error {}
    struct SsmlMarksNotSupportedForTextTypeException: Error {}
    struct EngineNotSupportedException: Error {}
    struct MarksNotSupportedForFormatException: Error {}
}

public struct SynthesizeSpeechOutputResponse: Swift.Equatable {
    public var audioStream: Data?
    // "Content-Type"
    public var contentType: Swift.String?
    // "x-amzn-RequestCharacters"
    public var requestCharacters: Swift.Int?

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case audioStream = "AudioStream"
    }
}


public struct SynthesizeSpeechInput: Swift.Equatable {
    public var engine: PollyClientTypes.Engine?
    public var languageCode: PollyClientTypes.LanguageCode?
    public var lexiconNames: [Swift.String]?
    /// This member is required.
    public var outputFormat: PollyClientTypes.OutputFormat
    public var sampleRate: Swift.String?
    public var speechMarkTypes: [PollyClientTypes.SpeechMarkType]?
    /// This member is required.
    public var text: Swift.String
    public var textType: PollyClientTypes.TextType?
    /// This member is required.
    public var voiceId: PollyClientTypes.VoiceId

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case engine = "Engine"
        case languageCode = "LanguageCode"
        case lexiconNames = "LexiconNames"
        case outputFormat = "OutputFormat"
        case sampleRate = "SampleRate"
        case speechMarkTypes = "SpeechMarkTypes"
        case text = "Text"
        case textType = "TextType"
        case voiceId = "VoiceId"
    }
}

public enum PollyClientTypes {}

extension PollyClientTypes {
    public enum TextType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case ssml
        case text
        case sdkUnknown(Swift.String)

        public static var allCases: [TextType] {
            return [
                .ssml,
                .text,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .ssml: return "ssml"
            case .text: return "text"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = TextType(rawValue: rawValue) ?? TextType.sdkUnknown(rawValue)
        }
    }
}

extension PollyClientTypes {
    public enum SpeechMarkType: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case sentence
        case ssml
        case viseme
        case word
        case sdkUnknown(Swift.String)

        public static var allCases: [SpeechMarkType] {
            return [
                .sentence,
                .ssml,
                .viseme,
                .word,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .sentence: return "sentence"
            case .ssml: return "ssml"
            case .viseme: return "viseme"
            case .word: return "word"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = SpeechMarkType(rawValue: rawValue) ?? SpeechMarkType.sdkUnknown(rawValue)
        }
    }
}

extension PollyClientTypes {
    public enum OutputFormat: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case json
        case mp3
        case oggVorbis
        case pcm
        case sdkUnknown(Swift.String)

        public static var allCases: [OutputFormat] {
            return [
                .json,
                .mp3,
                .oggVorbis,
                .pcm,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .json: return "json"
            case .mp3: return "mp3"
            case .oggVorbis: return "ogg_vorbis"
            case .pcm: return "pcm"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = OutputFormat(rawValue: rawValue) ?? OutputFormat.sdkUnknown(rawValue)
        }
    }
}

extension PollyClientTypes {
    public enum LanguageCode: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case arAe
        case arb
        case caEs
        case cmnCn
        case cyGb
        case daDk
        case deAt
        case deDe
        case enAu
        case enGb
        case enGbWls
        case enIe
        case enIn
        case enNz
        case enUs
        case enZa
        case esEs
        case esMx
        case esUs
        case fiFi
        case frBe
        case frCa
        case frFr
        case hiIn
        case isIs
        case itIt
        case jaJp
        case koKr
        case nbNo
        case nlBe
        case nlNl
        case plPl
        case ptBr
        case ptPt
        case roRo
        case ruRu
        case svSe
        case trTr
        case yueCn
        case sdkUnknown(Swift.String)

        public static var allCases: [LanguageCode] {
            return [
                .arAe,
                .arb,
                .caEs,
                .cmnCn,
                .cyGb,
                .daDk,
                .deAt,
                .deDe,
                .enAu,
                .enGb,
                .enGbWls,
                .enIe,
                .enIn,
                .enNz,
                .enUs,
                .enZa,
                .esEs,
                .esMx,
                .esUs,
                .fiFi,
                .frBe,
                .frCa,
                .frFr,
                .hiIn,
                .isIs,
                .itIt,
                .jaJp,
                .koKr,
                .nbNo,
                .nlBe,
                .nlNl,
                .plPl,
                .ptBr,
                .ptPt,
                .roRo,
                .ruRu,
                .svSe,
                .trTr,
                .yueCn,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .arAe: return "ar-AE"
            case .arb: return "arb"
            case .caEs: return "ca-ES"
            case .cmnCn: return "cmn-CN"
            case .cyGb: return "cy-GB"
            case .daDk: return "da-DK"
            case .deAt: return "de-AT"
            case .deDe: return "de-DE"
            case .enAu: return "en-AU"
            case .enGb: return "en-GB"
            case .enGbWls: return "en-GB-WLS"
            case .enIe: return "en-IE"
            case .enIn: return "en-IN"
            case .enNz: return "en-NZ"
            case .enUs: return "en-US"
            case .enZa: return "en-ZA"
            case .esEs: return "es-ES"
            case .esMx: return "es-MX"
            case .esUs: return "es-US"
            case .fiFi: return "fi-FI"
            case .frBe: return "fr-BE"
            case .frCa: return "fr-CA"
            case .frFr: return "fr-FR"
            case .hiIn: return "hi-IN"
            case .isIs: return "is-IS"
            case .itIt: return "it-IT"
            case .jaJp: return "ja-JP"
            case .koKr: return "ko-KR"
            case .nbNo: return "nb-NO"
            case .nlBe: return "nl-BE"
            case .nlNl: return "nl-NL"
            case .plPl: return "pl-PL"
            case .ptBr: return "pt-BR"
            case .ptPt: return "pt-PT"
            case .roRo: return "ro-RO"
            case .ruRu: return "ru-RU"
            case .svSe: return "sv-SE"
            case .trTr: return "tr-TR"
            case .yueCn: return "yue-CN"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = LanguageCode(rawValue: rawValue) ?? LanguageCode.sdkUnknown(rawValue)
        }
    }
}

extension PollyClientTypes {
    public enum Engine: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case neural
        case standard
        case sdkUnknown(Swift.String)

        public static var allCases: [Engine] {
            return [
                .neural,
                .standard,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .neural: return "neural"
            case .standard: return "standard"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = Engine(rawValue: rawValue) ?? Engine.sdkUnknown(rawValue)
        }
    }
}

extension PollyClientTypes {
    public enum VoiceId: Swift.Equatable, Swift.RawRepresentable, Swift.CaseIterable, Swift.Codable, Swift.Hashable {
        case aditi
        case adriano
        case amy
        case andres
        case aria
        case arlet
        case arthur
        case astrid
        case ayanda
        case bianca
        case brian
        case camila
        case carla
        case carmen
        case celine
        case chantal
        case conchita
        case cristiano
        case daniel
        case dora
        case elin
        case emma
        case enrique
        case ewa
        case filiz
        case gabrielle
        case geraint
        case giorgio
        case gwyneth
        case hala
        case hannah
        case hans
        case hiujin
        case ida
        case ines
        case isabelle
        case ivy
        case jacek
        case jan
        case joanna
        case joey
        case justin
        case kajal
        case karl
        case kazuha
        case kendra
        case kevin
        case kimberly
        case laura
        case lea
        case liam
        case lisa
        case liv
        case lotte
        case lucia
        case lupe
        case mads
        case maja
        case marlene
        case mathieu
        case matthew
        case maxim
        case mia
        case miguel
        case mizuki
        case naja
        case niamh
        case nicole
        case ola
        case olivia
        case pedro
        case penelope
        case raveena
        case remi
        case ricardo
        case ruben
        case russell
        case ruth
        case salli
        case seoyeon
        case sergio
        case sofie
        case stephen
        case suvi
        case takumi
        case tatyana
        case thiago
        case tomoko
        case vicki
        case vitoria
        case zayd
        case zeina
        case zhiyu
        case sdkUnknown(Swift.String)

        public static var allCases: [VoiceId] {
            return [
                .aditi,
                .adriano,
                .amy,
                .andres,
                .aria,
                .arlet,
                .arthur,
                .astrid,
                .ayanda,
                .bianca,
                .brian,
                .camila,
                .carla,
                .carmen,
                .celine,
                .chantal,
                .conchita,
                .cristiano,
                .daniel,
                .dora,
                .elin,
                .emma,
                .enrique,
                .ewa,
                .filiz,
                .gabrielle,
                .geraint,
                .giorgio,
                .gwyneth,
                .hala,
                .hannah,
                .hans,
                .hiujin,
                .ida,
                .ines,
                .isabelle,
                .ivy,
                .jacek,
                .jan,
                .joanna,
                .joey,
                .justin,
                .kajal,
                .karl,
                .kazuha,
                .kendra,
                .kevin,
                .kimberly,
                .laura,
                .lea,
                .liam,
                .lisa,
                .liv,
                .lotte,
                .lucia,
                .lupe,
                .mads,
                .maja,
                .marlene,
                .mathieu,
                .matthew,
                .maxim,
                .mia,
                .miguel,
                .mizuki,
                .naja,
                .niamh,
                .nicole,
                .ola,
                .olivia,
                .pedro,
                .penelope,
                .raveena,
                .remi,
                .ricardo,
                .ruben,
                .russell,
                .ruth,
                .salli,
                .seoyeon,
                .sergio,
                .sofie,
                .stephen,
                .suvi,
                .takumi,
                .tatyana,
                .thiago,
                .tomoko,
                .vicki,
                .vitoria,
                .zayd,
                .zeina,
                .zhiyu,
                .sdkUnknown("")
            ]
        }
        public init?(rawValue: Swift.String) {
            let value = Self.allCases.first(where: { $0.rawValue == rawValue })
            self = value ?? Self.sdkUnknown(rawValue)
        }
        public var rawValue: Swift.String {
            switch self {
            case .aditi: return "Aditi"
            case .adriano: return "Adriano"
            case .amy: return "Amy"
            case .andres: return "Andres"
            case .aria: return "Aria"
            case .arlet: return "Arlet"
            case .arthur: return "Arthur"
            case .astrid: return "Astrid"
            case .ayanda: return "Ayanda"
            case .bianca: return "Bianca"
            case .brian: return "Brian"
            case .camila: return "Camila"
            case .carla: return "Carla"
            case .carmen: return "Carmen"
            case .celine: return "Celine"
            case .chantal: return "Chantal"
            case .conchita: return "Conchita"
            case .cristiano: return "Cristiano"
            case .daniel: return "Daniel"
            case .dora: return "Dora"
            case .elin: return "Elin"
            case .emma: return "Emma"
            case .enrique: return "Enrique"
            case .ewa: return "Ewa"
            case .filiz: return "Filiz"
            case .gabrielle: return "Gabrielle"
            case .geraint: return "Geraint"
            case .giorgio: return "Giorgio"
            case .gwyneth: return "Gwyneth"
            case .hala: return "Hala"
            case .hannah: return "Hannah"
            case .hans: return "Hans"
            case .hiujin: return "Hiujin"
            case .ida: return "Ida"
            case .ines: return "Ines"
            case .isabelle: return "Isabelle"
            case .ivy: return "Ivy"
            case .jacek: return "Jacek"
            case .jan: return "Jan"
            case .joanna: return "Joanna"
            case .joey: return "Joey"
            case .justin: return "Justin"
            case .kajal: return "Kajal"
            case .karl: return "Karl"
            case .kazuha: return "Kazuha"
            case .kendra: return "Kendra"
            case .kevin: return "Kevin"
            case .kimberly: return "Kimberly"
            case .laura: return "Laura"
            case .lea: return "Lea"
            case .liam: return "Liam"
            case .lisa: return "Lisa"
            case .liv: return "Liv"
            case .lotte: return "Lotte"
            case .lucia: return "Lucia"
            case .lupe: return "Lupe"
            case .mads: return "Mads"
            case .maja: return "Maja"
            case .marlene: return "Marlene"
            case .mathieu: return "Mathieu"
            case .matthew: return "Matthew"
            case .maxim: return "Maxim"
            case .mia: return "Mia"
            case .miguel: return "Miguel"
            case .mizuki: return "Mizuki"
            case .naja: return "Naja"
            case .niamh: return "Niamh"
            case .nicole: return "Nicole"
            case .ola: return "Ola"
            case .olivia: return "Olivia"
            case .pedro: return "Pedro"
            case .penelope: return "Penelope"
            case .raveena: return "Raveena"
            case .remi: return "Remi"
            case .ricardo: return "Ricardo"
            case .ruben: return "Ruben"
            case .russell: return "Russell"
            case .ruth: return "Ruth"
            case .salli: return "Salli"
            case .seoyeon: return "Seoyeon"
            case .sergio: return "Sergio"
            case .sofie: return "Sofie"
            case .stephen: return "Stephen"
            case .suvi: return "Suvi"
            case .takumi: return "Takumi"
            case .tatyana: return "Tatyana"
            case .thiago: return "Thiago"
            case .tomoko: return "Tomoko"
            case .vicki: return "Vicki"
            case .vitoria: return "Vitoria"
            case .zayd: return "Zayd"
            case .zeina: return "Zeina"
            case .zhiyu: return "Zhiyu"
            case let .sdkUnknown(s): return s
            }
        }
        public init(from decoder: Swift.Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self = VoiceId(rawValue: rawValue) ?? VoiceId.sdkUnknown(rawValue)
        }
    }
}
