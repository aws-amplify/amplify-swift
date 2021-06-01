//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// swiftlint:disable file_length
// swiftlint:disable type_body_length
/// Language type supported by Predictions category
///
/// The associated value represents the iso language code.
public enum LanguageType: String {
    /// Afar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case afar = "aa"
    /// Abkhazian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case abkhazian = "ab"
    /// Achinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case achinese = "ace"
    /// Acoli language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case acoli = "ach"
    /// Adangme language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case adangme = "ada"
    /// Adyghe language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case adyghe = "ady"
    /// Avestan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case avestan = "ae"
    /// TunisianArabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tunisianArabic = "aeb"
    /// Afrikaans language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case afrikaans = "af"
    /// Afrihili language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case afrihili = "afh"
    /// Aghem language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case aghem = "agq"
    /// Ainu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ainu = "ain"
    /// Akan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case akan = "ak"
    /// Akkadian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case akkadian = "akk"
    /// Alabama language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case alabama = "akz"
    /// Aleut language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case aleut = "ale"
    /// GhegAlbanian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ghegAlbanian = "aln"
    /// SouthernAltai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case southernAltai = "alt"
    /// Amharic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case amharic = "am"
    /// Aragonese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case aragonese = "an"
    /// OldEnglish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oldEnglish = "ang"
    /// Angika language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case angika = "anp"
    /// Arabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case arabic = "ar"
    /// Aramaic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case aramaic = "arc"
    /// Mapuche language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mapuche = "arn"
    /// Araona language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case araona = "aro"
    /// Arapaho language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case arapaho = "arp"
    /// AlgerianArabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case algerianArabic = "arq"
    /// NajdiArabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case najdiArabic = "ars"
    /// Arawak language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case arawak = "arw"
    /// MoroccanArabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case moroccanArabic = "ary"
    /// EgyptianArabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case egyptianArabic = "arz"
    /// Assamese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case assamese = "as"
    /// Asu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case asu = "asa"
    /// AmericanSignLanguage language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case americanSignLanguage = "ase"
    /// Asturian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case asturian = "ast"
    /// Avaric language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case avaric = "av"
    /// Kotava language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kotava = "avk"
    /// Awadhi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case awadhi = "awa"
    /// Aymara language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case aymara = "ay"
    /// Azerbaijani language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case azerbaijani = "az"
    /// Bashkir language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bashkir = "ba"
    /// Baluchi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case baluchi = "bal"
    /// Balinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case balinese = "ban"
    /// Bavarian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bavarian = "bar"
    /// Basaa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case basaa = "bas"
    /// Bamun language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bamun = "bax"
    /// BatakToba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case batakToba = "bbc"
    /// Ghomala language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ghomala = "bbj"
    /// Belarusian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case belarusian = "be"
    /// Beja language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case beja = "bej"
    /// Bemba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bemba = "bem"
    /// Betawi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case betawi = "bew"
    /// Bena language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bena = "bez"
    /// Bafut language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bafut = "bfd"
    /// Badaga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case badaga = "bfq"
    /// Bulgarian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bulgarian = "bg"
    /// WesternBalochi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case westernBalochi = "bgn"
    /// Bhojpuri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bhojpuri = "bho"
    /// Bislama language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bislama = "bi"
    /// Bikol language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bikol = "bik"
    /// Bini language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bini = "bin"
    /// Banjar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case banjar = "bjn"
    /// Kom language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kom = "bkm"
    /// Siksika language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case siksika = "bla"
    /// Bambara language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bambara = "bm"
    /// Bangla language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bangla = "bn"
    /// Tibetan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tibetan = "bo"
    /// Bishnupriya language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bishnupriya = "bpy"
    /// Bakhtiari language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bakhtiari = "bqi"
    /// Breton language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case breton = "br"
    /// Braj language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case braj = "bra"
    /// Brahui language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case brahui = "brh"
    /// Bodo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bodo = "brx"
    /// Bosnian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bosnian = "bs"
    /// Akoose language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case akoose = "bss"
    /// Buriat language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case buriat = "bua"
    /// Buginese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case buginese = "bug"
    /// Bulu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bulu = "bum"
    /// Blin language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case blin = "byn"
    /// Medumba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case medumba = "byv"
    /// Catalan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case catalan = "ca"
    /// Caddo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case caddo = "cad"
    /// Carib language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case carib = "car"
    /// Cayuga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cayuga = "cay"
    /// Atsam language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case atsam = "cch"
    /// Chakma language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chakma = "ccp"
    /// Chechen language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chechen = "ce"
    /// Cebuano language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cebuano = "ceb"
    /// Chiga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chiga = "cgg"
    /// Chamorro language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chamorro = "ch"
    /// Chibcha language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chibcha = "chb"
    /// Chagatai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chagatai = "chg"
    /// Chuukese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chuukese = "chk"
    /// Mari language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mari = "chm"
    /// ChinookJargon language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chinookJargon = "chn"
    /// Choctaw language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case choctaw = "cho"
    /// Chipewyan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chipewyan = "chp"
    /// Cherokee language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cherokee = "chr"
    /// Cheyenne language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cheyenne = "chy"
    /// CentralKurdish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case centralKurdish = "ckb"
    /// Corsican language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case corsican = "co"
    /// Coptic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case coptic = "cop"
    /// Capiznon language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case capiznon = "cps"
    /// Cree language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cree = "cr"
    /// CrimeanTurkish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case crimeanTurkish = "crh"
    /// Czech language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case czech = "cs"
    /// Kashubian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kashubian = "csb"
    /// ChurchSlavic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case churchSlavic = "cu"
    /// Chuvash language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chuvash = "cv"
    /// Welsh language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case welsh = "cy"
    /// Danish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case danish = "da"
    /// Dakota language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dakota = "dak"
    /// Dargwa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dargwa = "dar"
    /// Taita language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case taita = "dav"
    /// German language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case german = "de"
    /// Delaware language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case delaware = "del"
    /// Slave language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case slave = "den" // swiftlint:disable:this inclusive_language
    /// Dogrib language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dogrib = "dgr"
    /// Dinka language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dinka = "din"
    /// Zarma language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zarma = "dje"
    /// Dogri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dogri = "doi"
    /// LowerSorbian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lowerSorbian = "dsb"
    /// CentralDusun language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case centralDusun = "dtp"
    /// Duala language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case duala = "dua"
    /// MiddleDutch language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case middleDutch = "dum"
    /// Dhivehi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dhivehi = "dv"
    /// JolaFonyi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case jolaFonyi = "dyo"
    /// Dyula language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dyula = "dyu"
    /// Dzongkha language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dzongkha = "dz"
    /// Dazaga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dazaga = "dzg"
    /// Embu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case embu = "ebu"
    /// Ewe language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ewe = "ee"
    /// Efik language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case efik = "efi"
    /// Emilian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case emilian = "egl"
    /// AncientEgyptian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ancientEgyptian = "egy"
    /// Ekajuk language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ekajuk = "eka"
    /// Greek language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case greek = "el"
    /// Elamite language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case elamite = "elx"
    /// English language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case english = "en"
    /// AustralianEnglish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case australianEnglish = "en-AU"
    /// BritishEnglish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case britishEnglish = "en-GB"
    /// UsEnglish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case usEnglish = "en-US"
    /// MiddleEnglish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case middleEnglish = "enm"
    /// Esperanto language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case esperanto = "eo"
    /// Spanish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case spanish = "es"
    /// UsSpanish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case usSpanish = "es-US"
    /// CentralYupik language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case centralYupik = "esu"
    /// Estonian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case estonian = "et"
    /// Basque language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case basque = "eu"
    /// Ewondo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ewondo = "ewo"
    /// Extremaduran language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case extremaduran = "ext"
    /// Persian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case persian = "fa"
    /// Fang language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case fang = "fan"
    /// Fanti language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case fanti = "fat"
    /// Fulah language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case fulah = "ff"
    /// Finnish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case finnish = "fi"
    /// Filipino language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case filipino = "fil"
    /// TornedalenFinnish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tornedalenFinnish = "fit"
    /// Fijian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case fijian = "fj"
    /// Faroese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case faroese = "fo"
    /// Fon language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case fon
    /// French language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case french = "fr"
    /// CanadianFrench language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case canadianFrench = "fr-CA"
    /// CajunFrench language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cajunFrench = "frc"
    /// MiddleFrench language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case middleFrench = "frm"
    /// OldFrench language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oldFrench = "fro"
    /// Arpitan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case arpitan = "frp"
    /// NorthernFrisian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case northernFrisian = "frr"
    /// EasternFrisian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case easternFrisian = "frs"
    /// Friulian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case friulian = "fur"
    /// WesternFrisian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case westernFrisian = "fy"
    /// Irish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case irish = "ga"
    /// Ga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ga = "gaa" // swiftlint:disable:this identifier_name
    /// Gagauz language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gagauz = "gag"
    /// GanChinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ganChinese = "gan"
    /// Gayo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gayo = "gay"
    /// Gbaya language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gbaya = "gba"
    /// ZoroastrianDari language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zoroastrianDari = "gbz"
    /// ScottishGaelic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case scottishGaelic = "gd"
    /// Geez language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case geez = "gez"
    /// Gilbertese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gilbertese = "gil"
    /// Galician language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case galician = "gl"
    /// Gilaki language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gilaki = "glk"
    /// MiddleHighGerman language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case middleHighGerman = "gmh"
    /// Guarani language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case guarani = "gn"
    /// OldHighGerman language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oldHighGerman = "goh"
    /// GoanKonkani language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case goanKonkani = "gom"
    /// Gondi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gondi = "gon"
    /// Gorontalo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gorontalo = "gor"
    /// Gothic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gothic = "got"
    /// Grebo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case grebo = "grb"
    /// AncientGreek language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ancientGreek = "grc"
    /// SwissGerman language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case swissGerman = "gsw"
    /// Gujarati language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gujarati = "gu"
    /// Wayuu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case wayuu = "guc"
    /// Frafra language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case frafra = "gur"
    /// Gusii language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gusii = "guz"
    /// Manx language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case manx = "gv"
    /// Gwichʼin language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case gwichʼin = "gwi"
    /// Hausa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hausa = "ha"
    /// Haida language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case haida = "hai"
    /// HakkaChinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hakkaChinese = "hak"
    /// Hawaiian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hawaiian = "haw"
    /// Hebrew language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hebrew = "he"
    /// Hindi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hindi = "hi"
    /// FijiHindi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case fijiHindi = "hif"
    /// Hiligaynon language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hiligaynon = "hil"
    /// Hittite language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hittite = "hit"
    /// Hmong language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hmong = "hmn"
    /// HiriMotu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hiriMotu = "ho"
    /// Croatian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case croatian = "hr"
    /// UpperSorbian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case upperSorbian = "hsb"
    /// XiangChinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case xiangChinese = "hsn"
    /// HaitianCreole language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case haitianCreole = "ht"
    /// Hungarian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hungarian = "hu"
    /// Hupa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case hupa = "hup"
    /// Armenian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case armenian = "hy"
    /// Herero language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case herero = "hz"
    /// Interlingua language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case interlingua = "ia"
    /// Iban language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case iban = "iba"
    /// Ibibio language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ibibio = "ibb"
    /// Indonesian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case indonesian = "id"
    /// Interlingue language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case interlingue = "ie"
    /// Igbo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case igbo = "ig"
    /// SichuanYi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sichuanYi = "ii"
    /// Inupiaq language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case inupiaq = "ik"
    /// Iloko language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case iloko = "ilo"
    /// Ingush language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ingush = "inh"
    /// Ido language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ido = "io"
    /// Icelandic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case icelandic = "is"
    /// Italian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case italian = "it"
    /// Inuktitut language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case inuktitut = "iu"
    /// Ingrian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ingrian = "izh"
    /// Japanese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case japanese = "ja"
    /// JamaicanCreoleEnglish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case jamaicanCreoleEnglish = "jam"
    /// Lojban language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lojban = "jbo"
    /// Ngomba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ngomba = "jgo"
    /// Machame language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case machame = "jmc"
    /// JudeoPersian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case judeoPersian = "jpr"
    /// JudeoArabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case judeoArabic = "jrb"
    /// Jutish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case jutish = "jut"
    /// Javanese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case javanese = "jv"
    /// Georgian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case georgian = "ka"
    /// KaraKalpak language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case karaKalpak = "kaa"
    /// Kabyle language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kabyle = "kab"
    /// Kachin language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kachin = "kac"
    /// Jju language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case jju = "kaj"
    /// Kamba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kamba = "kam"
    /// Kawi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kawi = "kaw"
    /// Kabardian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kabardian = "kbd"
    /// Kanembu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kanembu = "kbl"
    /// Tyap language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tyap = "kcg"
    /// Makonde language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case makonde = "kde"
    /// Kabuverdianu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kabuverdianu = "kea"
    /// Kenyang language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kenyang = "ken"
    /// Koro language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case koro = "kfo"
    /// Kongo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kongo = "kg"
    /// Kaingang language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kaingang = "kgp"
    /// Khasi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case khasi = "kha"
    /// Khotanese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case khotanese = "kho"
    /// KoyraChiini language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case koyraChiini = "khq"
    /// Khowar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case khowar = "khw"
    /// Kikuyu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kikuyu = "ki"
    /// Kirmanjki language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kirmanjki = "kiu"
    /// Kuanyama language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kuanyama = "kj"
    /// Kazakh language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kazakh = "kk"
    /// Kako language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kako = "kkj"
    /// Kalaallisut language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kalaallisut = "kl"
    /// Kalenjin language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kalenjin = "kln"
    /// Khmer language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case khmer = "km"
    /// Kimbundu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kimbundu = "kmb"
    /// Kannada language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kannada = "kn"
    /// Korean language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case korean = "ko"
    /// KomiPermyak language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case komiPermyak = "koi"
    /// Konkani language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case konkani = "kok"
    /// Kosraean language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kosraean = "kos"
    /// Kpelle language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kpelle = "kpe"
    /// Kanuri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kanuri = "kr"
    /// KarachayBalkar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case karachayBalkar = "krc"
    /// Krio language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case krio = "kri"
    /// KinarayA language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kinarayA = "krj"
    /// Karelian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case karelian = "krl"
    /// Kurukh language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kurukh = "kru"
    /// Kashmiri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kashmiri = "ks"
    /// Shambala language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case shambala = "ksb"
    /// Bafia language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case bafia = "ksf"
    /// Colognian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case colognian = "ksh"
    /// Kurdish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kurdish = "ku"
    /// Kumyk language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kumyk = "kum"
    /// Kutenai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kutenai = "kut"
    /// Komi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case komi = "kv"
    /// Cornish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cornish = "kw"
    /// Kyrgyz language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kyrgyz = "ky"
    /// Latin language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case latin = "la"
    /// Ladino language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ladino = "lad"
    /// Langi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case langi = "lag"
    /// Lahnda language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lahnda = "lah"
    /// Lamba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lamba = "lam"
    /// Luxembourgish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case luxembourgish = "lb"
    /// Lezghian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lezghian = "lez"
    /// LinguaFrancaNova language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case linguaFrancaNova = "lfn"
    /// Ganda language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ganda = "lg"
    /// Limburgish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case limburgish = "li"
    /// Ligurian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ligurian = "lij"
    /// Livonian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case livonian = "liv"
    /// Lakota language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lakota = "lkt"
    /// Lombard language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lombard = "lmo"
    /// Lingala language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lingala = "ln"
    /// Lao language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lao = "lo"
    /// Mongo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mongo = "lol"
    /// Lozi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lozi = "loz"
    /// NorthernLuri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case northernLuri = "lrc"
    /// Lithuanian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lithuanian = "lt"
    /// Latgalian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case latgalian = "ltg"
    /// LubaKatanga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lubaKatanga = "lu"
    /// LubaLulua language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lubaLulua = "lua"
    /// Luiseno language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case luiseno = "lui"
    /// Lunda language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lunda = "lun"
    /// Luo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case luo
    /// Mizo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mizo = "lus"
    /// Luyia language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case luyia = "luy"
    /// Latvian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case latvian = "lv"
    /// LiteraryChinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case literaryChinese = "lzh"
    /// Laz language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case laz = "lzz"
    /// Madurese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case madurese = "mad"
    /// Mafa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mafa = "maf"
    /// Magahi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case magahi = "mag"
    /// Maithili language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case maithili = "mai"
    /// Makasar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case makasar = "mak"
    /// Mandingo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mandingo = "man"
    /// Masai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case masai = "mas"
    /// Maba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case maba = "mde"
    /// Moksha language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case moksha = "mdf"
    /// Mandar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mandar = "mdr"
    /// Mende language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mende = "men"
    /// Meru language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case meru = "mer"
    /// Morisyen language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case morisyen = "mfe"
    /// Malagasy language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case malagasy = "mg"
    /// MiddleIrish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case middleIrish = "mga"
    /// MakhuwaMeetto language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case makhuwaMeetto = "mgh"
    /// Meta language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case meta = "mgo"
    /// Marshallese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case marshallese = "mh"
    /// Maori language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case maori = "mi"
    /// Mikmaq language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mikmaq = "mic"
    /// Minangkabau language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case minangkabau = "min"
    /// Macedonian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case macedonian = "mk"
    /// Malayalam language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case malayalam = "ml"
    /// Mongolian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mongolian = "mn"
    /// Manchu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case manchu = "mnc"
    /// Manipuri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case manipuri = "mni"
    /// Mohawk language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mohawk = "moh"
    /// Mossi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mossi = "mos"
    /// Marathi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case marathi = "mr"
    /// WesternMari language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case westernMari = "mrj"
    /// Malay language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case malay = "ms"
    /// Maltese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case maltese = "mt"
    /// Mundang language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mundang = "mua"
    /// Creek language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case creek = "mus"
    /// Mirandese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mirandese = "mwl"
    /// Marwari language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case marwari = "mwr"
    /// Mentawai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mentawai = "mwv"
    /// Burmese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case burmese = "my"
    /// Myene language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case myene = "mye"
    /// Erzya language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case erzya = "myv"
    /// Mazanderani language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mazanderani = "mzn"
    /// Nauru language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nauru = "na"
    /// MinnanChinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case minnanChinese = "nan"
    /// Neapolitan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case neapolitan = "nap"
    /// Nama language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nama = "naq"
    /// NorwegianBokmål language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case norwegianBokmål = "nb"
    /// NorthNdebele language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case northNdebele = "nd"
    /// LowGerman language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lowGerman = "nds"
    /// Nepali language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nepali = "ne"
    /// Newari language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case newari = "new"
    /// Ndonga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ndonga = "ng"
    /// Nias language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nias = "nia"
    /// Niuean language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case niuean = "niu"
    /// AoNaga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case aoNaga = "njo"
    /// Dutch language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case dutch = "nl"
    /// Kwasio language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kwasio = "nmg"
    /// NorwegianNynorsk language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case norwegianNynorsk = "nn"
    /// Ngiemboon language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ngiemboon = "nnh"
    /// Norwegian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case norwegian = "no"
    /// Nogai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nogai = "nog"
    /// OldNorse language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oldNorse = "non"
    /// Novial language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case novial = "nov"
    /// Nko language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nko = "nqo"
    /// SouthNdebele language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case southNdebele = "nr"
    /// NorthernSotho language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case northernSotho = "nso"
    /// Nuer language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nuer = "nus"
    /// Navajo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case navajo = "nv"
    /// ClassicalNewari language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case classicalNewari = "nwc"
    /// Nyanja language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nyanja = "ny"
    /// Nyamwezi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nyamwezi = "nym"
    /// Nyankole language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nyankole = "nyn"
    /// Nyoro language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nyoro = "nyo"
    /// Nzima language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nzima = "nzi"
    /// Occitan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case occitan = "oc"
    /// Ojibwa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ojibwa = "oj"
    /// Oromo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oromo = "om"
    /// Odia language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case odia = "or"
    /// Ossetic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ossetic = "os"
    /// Osage language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case osage = "osa"
    /// OttomanTurkish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ottomanTurkish = "ota"
    /// Punjabi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case punjabi = "pa"
    /// Pangasinan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pangasinan = "pag"
    /// Pahlavi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pahlavi = "pal"
    /// Pampanga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pampanga = "pam"
    /// Papiamento language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case papiamento = "pap"
    /// Palauan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case palauan = "pau"
    /// Picard language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case picard = "pcd"
    /// PennsylvaniaGerman language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pennsylvaniaGerman = "pdc"
    /// Plautdietsch language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case plautdietsch = "pdt"
    /// OldPersian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oldPersian = "peo"
    /// PalatineGerman language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case palatineGerman = "pfl"
    /// Phoenician language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case phoenician = "phn"
    /// Pali language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pali = "pi"
    /// Polish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case polish = "pl"
    /// Piedmontese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case piedmontese = "pms"
    /// Pontic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pontic = "pnt"
    /// Pohnpeian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pohnpeian = "pon"
    /// Prussian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case prussian = "prg"
    /// OldProvençal language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oldProvençal = "pro"
    /// Pashto language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case pashto = "ps"
    /// Portuguese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case portuguese = "pt"
    /// Quechua language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case quechua = "qu"
    /// Kʼicheʼ language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kʼicheʼ = "quc"
    /// ChimborazoHighlandQuichua language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chimborazoHighlandQuichua = "qug"
    /// Rajasthani language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rajasthani = "raj"
    /// Rapanui language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rapanui = "rap"
    /// Rarotongan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rarotongan = "rar"
    /// Romagnol language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case romagnol = "rgn"
    /// Riffian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case riffian = "rif"
    /// Romansh language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case romansh = "rm"
    /// Rundi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rundi = "rn"
    /// Romanian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case romanian = "ro"
    /// Rombo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rombo = "rof"
    /// Romany language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case romany = "rom"
    /// Rotuman language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rotuman = "rtm"
    /// Russian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case russian = "ru"
    /// Rusyn language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rusyn = "rue"
    /// Roviana language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case roviana = "rug"
    /// Aromanian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case aromanian = "rup"
    /// Kinyarwanda language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kinyarwanda = "rw"
    /// Rwa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case rwa = "rwk"
    /// Sanskrit language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sanskrit = "sa"
    /// Sandawe language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sandawe = "sad"
    /// Sakha language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sakha = "sah"
    /// SamaritanAramaic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case samaritanAramaic = "sam"
    /// Samburu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case samburu = "saq"
    /// Sasak language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sasak = "sas"
    /// Santali language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case santali = "sat"
    /// Saurashtra language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case saurashtra = "saz"
    /// Ngambay language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ngambay = "sba"
    /// Sangu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sangu = "sbp"
    /// Sardinian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sardinian = "sc"
    /// Sicilian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sicilian = "scn"
    /// Scots language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case scots = "sco"
    /// Sindhi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sindhi = "sd"
    /// SassareseSardinian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sassareseSardinian = "sdc"
    /// SouthernKurdish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case southernKurdish = "sdh"
    /// NorthernSami language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case northernSami = "se"
    /// Seneca language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case seneca = "see"
    /// Sena language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sena = "seh"
    /// Seri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case seri = "sei"
    /// Selkup language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case selkup = "sel"
    /// KoyraboroSenni language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case koyraboroSenni = "ses"
    /// Sango language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sango = "sg"
    /// OldIrish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case oldIrish = "sga"
    /// Samogitian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case samogitian = "sgs"
    /// Tachelhit language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tachelhit = "shi"
    /// Shan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case shan = "shn"
    /// ChadianArabic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chadianArabic = "shu"
    /// Sinhala language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sinhala = "si"
    /// Sidamo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sidamo = "sid"
    /// Slovak language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case slovak = "sk"
    /// Slovenian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case slovenian = "sl"
    /// LowerSilesian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case lowerSilesian = "sli"
    /// Selayar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case selayar = "sly"
    /// Samoan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case samoan = "sm"
    /// SouthernSami language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case southernSami = "sma"
    /// LuleSami language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case luleSami = "smj"
    /// InariSami language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case inariSami = "smn"
    /// SkoltSami language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case skoltSami = "sms"
    /// Shona language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case shona = "sn"
    /// Soninke language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case soninke = "snk"
    /// Somali language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case somali = "so"
    /// Sogdien language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sogdien = "sog"
    /// Albanian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case albanian = "sq"
    /// Serbian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case serbian = "sr"
    /// SrananTongo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case srananTongo = "srn"
    /// Serer language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case serer = "srr"
    /// Swati language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case swati = "ss"
    /// Saho language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case saho = "ssy"
    /// SouthernSotho language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case southernSotho = "st"
    /// SaterlandFrisian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case saterlandFrisian = "stq"
    /// Sundanese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sundanese = "su"
    /// Sukuma language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sukuma = "suk"
    /// Susu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case susu = "sus"
    /// Sumerian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case sumerian = "sux"
    /// Swedish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case swedish = "sv"
    /// Swahili language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case swahili = "sw"
    /// Comorian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case comorian = "swb"
    /// ClassicalSyriac language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case classicalSyriac = "syc"
    /// Syriac language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case syriac = "syr"
    /// Silesian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case silesian = "szl"
    /// Tamil language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tamil = "ta"
    /// Tulu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tulu = "tcy"
    /// Telugu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case telugu = "te"
    /// Timne language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case timne = "tem"
    /// Teso language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case teso = "teo"
    /// Tereno language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tereno = "ter"
    /// Tetum language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tetum = "tet"
    /// Tajik language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tajik = "tg"
    /// Thai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case thai = "th"
    /// Tigrinya language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tigrinya = "ti"
    /// Tigre language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tigre = "tig"
    /// Tiv language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tiv
    /// Turkmen language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case turkmen = "tk"
    /// Tokelau language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tokelau = "tkl"
    /// Tsakhur language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tsakhur = "tkr"
    /// Tagalog language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tagalog = "tl"
    /// Klingon language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case klingon = "tlh"
    /// Tlingit language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tlingit = "tli"
    /// Talysh language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case talysh = "tly"
    /// Tamashek language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tamashek = "tmh"
    /// Tswana language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tswana = "tn"
    /// Tongan language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tongan = "to"
    /// NyasaTonga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nyasaTonga = "tog"
    /// TokPisin language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tokPisin = "tpi"
    /// Turkish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case turkish = "tr"
    /// Turoyo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case turoyo = "tru"
    /// Taroko language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case taroko = "trv"
    /// Tsonga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tsonga = "ts"
    /// Tsakonian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tsakonian = "tsd"
    /// Tsimshian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tsimshian = "tsi"
    /// Tatar language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tatar = "tt"
    /// MuslimTat language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case muslimTat = "ttt"
    /// Tumbuka language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tumbuka = "tum"
    /// Tuvalu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tuvalu = "tvl"
    /// Twi language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case twi = "tw"
    /// Tasawaq language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tasawaq = "twq"
    /// Tahitian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tahitian = "ty"
    /// Tuvinian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case tuvinian = "tyv"
    /// CentralAtlasTamazight language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case centralAtlasTamazight = "tzm"
    /// Udmurt language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case udmurt = "udm"
    /// Uyghur language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case uyghur = "ug"
    /// Ugaritic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ugaritic = "uga"
    /// Ukrainian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case ukrainian = "uk"
    /// Umbundu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case umbundu = "umb"
    /// Urdu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case urdu = "ur"
    /// Uzbek language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case uzbek = "uz"
    /// Vai language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case vai
    /// Venda language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case venda = "ve"
    /// Venetian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case venetian = "vec"
    /// Veps language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case veps = "vep"
    /// Vietnamese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case vietnamese = "vi"
    /// WestFlemish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case westFlemish = "vls"
    /// MainFranconian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mainFranconian = "vmf"
    /// Volapük language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case volapük = "vo"
    /// Votic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case votic = "vot"
    /// Võro language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case võro = "vro"
    /// Vunjo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case vunjo = "vun"
    /// Walloon language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case walloon = "wa"
    /// Walser language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case walser = "wae"
    /// Wolaytta language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case wolaytta = "wal"
    /// Waray language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case waray = "war"
    /// Washo language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case washo = "was"
    /// Warlpiri language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case warlpiri = "wbp"
    /// Wolof language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case wolof = "wo"
    /// Shanghainese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case shanghainese = "wuu"
    /// Kalmyk language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case kalmyk = "xal"
    /// Xhosa language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case xhosa = "xh"
    /// Mingrelian language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case mingrelian = "xmf"
    /// Soga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case soga = "xog"
    /// Yao language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case yao
    /// Yapese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case yapese = "yap"
    /// Yangben language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case yangben = "yav"
    /// Yemba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case yemba = "ybb"
    /// Yiddish language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case yiddish = "yi"
    /// Yoruba language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case yoruba = "yo"
    /// Nheengatu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case nheengatu = "yrl"
    /// Cantonese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case cantonese = "yue"
    /// Zhuang language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zhuang = "za"
    /// Zapotec language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zapotec = "zap"
    /// Blissymbols language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case blissymbols = "zbl"
    /// Zeelandic language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zeelandic = "zea"
    /// Zenaga language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zenaga = "zen"
    /// StandardMoroccanTamazight language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case standardMoroccanTamazight = "zgh"
    /// Chinese language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case chinese = "zh"
    /// Zulu language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zulu = "zu"
    /// Zuni language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zuni = "zun"
    /// Zaza language type supported by Predictions category
    ///
    /// The associated value represents the iso language code.
    case zaza = "zza"

    case undetermined
}

extension LanguageType {

    public init(locale: Locale) {
        guard let languageCode = locale.languageCode,
              let type = LanguageType(rawValue: languageCode) else {
            self = .undetermined
            return
        }
        self = type
    }
}
