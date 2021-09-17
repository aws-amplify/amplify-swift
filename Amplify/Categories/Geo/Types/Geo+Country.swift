//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Geo {

    /// Country codes for use with Amplify Geo.
    enum Country: String { // swiftlint:disable:this type_body_length
        /// Afghanistan
        case AFG = "Afghanistan"
        /// Albania
        case ALB = "Albania"
        /// Algeria
        case DZA = "Algeria"
        /// American Samoa
        case ASM = "American Samoa"
        /// Andorra
        case AND = "Andorra"
        /// Angola
        case AGO = "Angola"
        /// Anguilla
        case AIA = "Anguilla"
        /// Antarctica
        case ATA = "Antarctica"
        /// Antigua and Barbuda
        case ATG = "Antigua and Barbuda"
        /// Argentina
        case ARG = "Argentina"
        /// Armenia
        case ARM = "Armenia"
        /// Aruba
        case ABW = "Aruba"
        /// Australia
        case AUS = "Australia"
        /// Austria
        case AUT = "Austria"
        /// Azerbaijan
        case AZE = "Azerbaijan"
        /// Bahamas (the)
        case BHS = "Bahamas (the)"
        /// Bahrain
        case BHR = "Bahrain"
        /// Bangladesh
        case BGD = "Bangladesh"
        /// Barbados
        case BRB = "Barbados"
        /// Belarus
        case BLR = "Belarus"
        /// Belgium
        case BEL = "Belgium"
        /// Belize
        case BLZ = "Belize"
        /// Benin
        case BEN = "Benin"
        /// Bermuda
        case BMU = "Bermuda"
        /// Bhutan
        case BTN = "Bhutan"
        /// Bolivia (Plurinational State of)
        case BOL = "Bolivia (Plurinational State of)"
        /// Bonaire, Sint Eustatius and Saba
        case BES = "Bonaire, Sint Eustatius and Saba"
        /// Bosnia and Herzegovina
        case BIH = "Bosnia and Herzegovina"
        /// Botswana
        case BWA = "Botswana"
        /// Bouvet Island
        case BVT = "Bouvet Island"
        /// Brazil
        case BRA = "Brazil"
        /// British Indian Ocean Territory (the)
        case IOT = "British Indian Ocean Territory (the)"
        /// Brunei Darussalam
        case BRN = "Brunei Darussalam"
        /// Bulgaria
        case BGR = "Bulgaria"
        /// Burkina Faso
        case BFA = "Burkina Faso"
        /// Burundi
        case BDI = "Burundi"
        /// Cabo Verde
        case CPV = "Cabo Verde"
        /// Cambodia
        case KHM = "Cambodia"
        /// Cameroon
        case CMR = "Cameroon"
        /// Canada
        case CAN = "Canada"
        /// Cayman Islands (the)
        case CYM = "Cayman Islands (the)"
        /// Central African Republic (the)
        case CAF = "Central African Republic (the)"
        /// Chad
        case TCD = "Chad"
        /// Chile
        case CHL = "Chile"
        /// China
        case CHN = "China"
        /// Christmas Island
        case CXR = "Christmas Island"
        /// Cocos (Keeling) Islands (the)
        case CCK = "Cocos (Keeling) Islands (the)"
        /// Colombia
        case COL = "Colombia"
        /// Comoros (the)
        case COM = "Comoros (the)"
        /// Congo (the Democratic Republic of the)
        case COD = "Congo (the Democratic Republic of the)"
        /// Congo (the)
        case COG = "Congo (the)"
        /// Cook Islands (the)
        case COK = "Cook Islands (the)"
        /// Costa Rica
        case CRI = "Costa Rica"
        /// Croatia
        case HRV = "Croatia"
        /// Cuba
        case CUB = "Cuba"
        /// Curaçao
        case CUW = "Curaçao"
        /// Cyprus
        case CYP = "Cyprus"
        /// Czechia
        case CZE = "Czechia"
        /// Côte d'Ivoire
        case CIV = "Côte d'Ivoire"
        /// Denmark
        case DNK = "Denmark"
        /// Djibouti
        case DJI = "Djibouti"
        /// Dominica
        case DMA = "Dominica"
        /// Dominican Republic (the)
        case DOM = "Dominican Republic (the)"
        /// Ecuador
        case ECU = "Ecuador"
        /// Egypt
        case EGY = "Egypt"
        /// El Salvador
        case SLV = "El Salvador"
        /// Equatorial Guinea
        case GNQ = "Equatorial Guinea"
        /// Eritrea
        case ERI = "Eritrea"
        /// Estonia
        case EST = "Estonia"
        /// Eswatini
        case SWZ = "Eswatini"
        /// Ethiopia
        case ETH = "Ethiopia"
        /// Falkland Islands (the) [Malvinas]
        case FLK = "Falkland Islands (the) [Malvinas]"
        /// Faroe Islands (the)
        case FRO = "Faroe Islands (the)"
        /// Fiji
        case FJI = "Fiji"
        /// Finland
        case FIN = "Finland"
        /// France
        case FRA = "France"
        /// French Guiana
        case GUF = "French Guiana"
        /// French Polynesia
        case PYF = "French Polynesia"
        /// French Southern Territories (the)
        case ATF = "French Southern Territories (the)"
        /// Gabon
        case GAB = "Gabon"
        /// Gambia (the)
        case GMB = "Gambia (the)"
        /// Georgia
        case GEO = "Georgia"
        /// Germany
        case DEU = "Germany"
        /// Ghana
        case GHA = "Ghana"
        /// Gibraltar
        case GIB = "Gibraltar"
        /// Greece
        case GRC = "Greece"
        /// Greenland
        case GRL = "Greenland"
        /// Grenada
        case GRD = "Grenada"
        /// Guadeloupe
        case GLP = "Guadeloupe"
        /// Guam
        case GUM = "Guam"
        /// Guatemala
        case GTM = "Guatemala"
        /// Guernsey
        case GGY = "Guernsey"
        /// Guinea
        case GIN = "Guinea"
        /// Guinea-Bissau
        case GNB = "Guinea-Bissau"
        /// Guyana
        case GUY = "Guyana"
        /// Haiti
        case HTI = "Haiti"
        /// Heard Island and McDonald Islands
        case HMD = "Heard Island and McDonald Islands"
        /// Holy See (the)
        case VAT = "Holy See (the)"
        /// Honduras
        case HND = "Honduras"
        /// Hong Kong
        case HKG = "Hong Kong"
        /// Hungary
        case HUN = "Hungary"
        /// Iceland
        case ISL = "Iceland"
        /// India
        case IND = "India"
        /// Indonesia
        case IDN = "Indonesia"
        /// Iran (Islamic Republic of)
        case IRN = "Iran (Islamic Republic of)"
        /// Iraq
        case IRQ = "Iraq"
        /// Ireland
        case IRL = "Ireland"
        /// Isle of Man
        case IMN = "Isle of Man"
        /// Israel
        case ISR = "Israel"
        /// Italy
        case ITA = "Italy"
        /// Jamaica
        case JAM = "Jamaica"
        /// Japan
        case JPN = "Japan"
        /// Jersey
        case JEY = "Jersey"
        /// Jordan
        case JOR = "Jordan"
        /// Kazakhstan
        case KAZ = "Kazakhstan"
        /// Kenya
        case KEN = "Kenya"
        /// Kiribati
        case KIR = "Kiribati"
        /// Korea (the Democratic People's Republic of)
        case PRK = "Korea (the Democratic People's Republic of)"
        /// Korea (the Republic of)
        case KOR = "Korea (the Republic of)"
        /// Kuwait
        case KWT = "Kuwait"
        /// Kyrgyzstan
        case KGZ = "Kyrgyzstan"
        /// Lao People's Democratic Republic (the)
        case LAO = "Lao People's Democratic Republic (the)"
        /// Latvia
        case LVA = "Latvia"
        /// Lebanon
        case LBN = "Lebanon"
        /// Lesotho
        case LSO = "Lesotho"
        /// Liberia
        case LBR = "Liberia"
        /// Libya
        case LBY = "Libya"
        /// Liechtenstein
        case LIE = "Liechtenstein"
        /// Lithuania
        case LTU = "Lithuania"
        /// Luxembourg
        case LUX = "Luxembourg"
        /// Macao
        case MAC = "Macao"
        /// Madagascar
        case MDG = "Madagascar"
        /// Malawi
        case MWI = "Malawi"
        /// Malaysia
        case MYS = "Malaysia"
        /// Maldives
        case MDV = "Maldives"
        /// Mali
        case MLI = "Mali"
        /// Malta
        case MLT = "Malta"
        /// Marshall Islands (the)
        case MHL = "Marshall Islands (the)"
        /// Martinique
        case MTQ = "Martinique"
        /// Mauritania
        case MRT = "Mauritania"
        /// Mauritius
        case MUS = "Mauritius"
        /// Mayotte
        case MYT = "Mayotte"
        /// Mexico
        case MEX = "Mexico"
        /// Micronesia (Federated States of)
        case FSM = "Micronesia (Federated States of)"
        /// Moldova (the Republic of)
        case MDA = "Moldova (the Republic of)"
        /// Monaco
        case MCO = "Monaco"
        /// Mongolia
        case MNG = "Mongolia"
        /// Montenegro
        case MNE = "Montenegro"
        /// Montserrat
        case MSR = "Montserrat"
        /// Morocco
        case MAR = "Morocco"
        /// Mozambique
        case MOZ = "Mozambique"
        /// Myanmar
        case MMR = "Myanmar"
        /// Namibia
        case NAM = "Namibia"
        /// Nauru
        case NRU = "Nauru"
        /// Nepal
        case NPL = "Nepal"
        /// Netherlands (the)
        case NLD = "Netherlands (the)"
        /// New Caledonia
        case NCL = "New Caledonia"
        /// New Zealand
        case NZL = "New Zealand"
        /// Nicaragua
        case NIC = "Nicaragua"
        /// Niger (the)
        case NER = "Niger (the)"
        /// Nigeria
        case NGA = "Nigeria"
        /// Niue
        case NIU = "Niue"
        /// Norfolk Island
        case NFK = "Norfolk Island"
        /// Northern Mariana Islands (the)
        case MNP = "Northern Mariana Islands (the)"
        /// Norway
        case NOR = "Norway"
        /// Oman
        case OMN = "Oman"
        /// Pakistan
        case PAK = "Pakistan"
        /// Palau
        case PLW = "Palau"
        /// Palestine, State of
        case PSE = "Palestine, State of"
        /// Panama
        case PAN = "Panama"
        /// Papua New Guinea
        case PNG = "Papua New Guinea"
        /// Paraguay
        case PRY = "Paraguay"
        /// Peru
        case PER = "Peru"
        /// Philippines (the)
        case PHL = "Philippines (the)"
        /// Pitcairn
        case PCN = "Pitcairn"
        /// Poland
        case POL = "Poland"
        /// Portugal
        case PRT = "Portugal"
        /// Puerto Rico
        case PRI = "Puerto Rico"
        /// Qatar
        case QAT = "Qatar"
        /// Republic of North Macedonia
        case MKD = "Republic of North Macedonia"
        /// Romania
        case ROU = "Romania"
        /// Russian Federation (the)
        case RUS = "Russian Federation (the)"
        /// Rwanda
        case RWA = "Rwanda"
        /// Réunion
        case REU = "Réunion"
        /// Saint Barthélemy
        case BLM = "Saint Barthélemy"
        /// Saint Helena, Ascension and Tristan da Cunha
        case SHN = "Saint Helena, Ascension and Tristan da Cunha"
        /// Saint Kitts and Nevis
        case KNA = "Saint Kitts and Nevis"
        /// Saint Lucia
        case LCA = "Saint Lucia"
        /// Saint Martin (French part)
        case MAF = "Saint Martin (French part)"
        /// Saint Pierre and Miquelon
        case SPM = "Saint Pierre and Miquelon"
        /// Saint Vincent and the Grenadines
        case VCT = "Saint Vincent and the Grenadines"
        /// Samoa
        case WSM = "Samoa"
        /// San Marino
        case SMR = "San Marino"
        /// Sao Tome and Principe
        case STP = "Sao Tome and Principe"
        /// Saudi Arabia
        case SAU = "Saudi Arabia"
        /// Senegal
        case SEN = "Senegal"
        /// Serbia
        case SRB = "Serbia"
        /// Seychelles
        case SYC = "Seychelles"
        /// Sierra Leone
        case SLE = "Sierra Leone"
        /// Singapore
        case SGP = "Singapore"
        /// Sint Maarten (Dutch part)
        case SXM = "Sint Maarten (Dutch part)"
        /// Slovakia
        case SVK = "Slovakia"
        /// Slovenia
        case SVN = "Slovenia"
        /// Solomon Islands
        case SLB = "Solomon Islands"
        /// Somalia
        case SOM = "Somalia"
        /// South Africa
        case ZAF = "South Africa"
        /// South Georgia and the South Sandwich Islands
        case SGS = "South Georgia and the South Sandwich Islands"
        /// South Sudan
        case SSD = "South Sudan"
        /// Spain
        case ESP = "Spain"
        /// Sri Lanka
        case LKA = "Sri Lanka"
        /// Sudan (the)
        case SDN = "Sudan (the)"
        /// Suriname
        case SUR = "Suriname"
        /// Svalbard and Jan Mayen
        case SJM = "Svalbard and Jan Mayen"
        /// Sweden
        case SWE = "Sweden"
        /// Switzerland
        case CHE = "Switzerland"
        /// Syrian Arab Republic
        case SYR = "Syrian Arab Republic"
        /// Taiwan (Province of China)
        case TWN = "Taiwan (Province of China)"
        /// Tajikistan
        case TJK = "Tajikistan"
        /// Tanzania, United Republic of
        case TZA = "Tanzania, United Republic of"
        /// Thailand
        case THA = "Thailand"
        /// Timor-Leste
        case TLS = "Timor-Leste"
        /// Togo
        case TGO = "Togo"
        /// Tokelau
        case TKL = "Tokelau"
        /// Tonga
        case TON = "Tonga"
        /// Trinidad and Tobago
        case TTO = "Trinidad and Tobago"
        /// Tunisia
        case TUN = "Tunisia"
        /// Turkey
        case TUR = "Turkey"
        /// Turkmenistan
        case TKM = "Turkmenistan"
        /// Turks and Caicos Islands (the)
        case TCA = "Turks and Caicos Islands (the)"
        /// Tuvalu
        case TUV = "Tuvalu"
        /// Uganda
        case UGA = "Uganda"
        /// Ukraine
        case UKR = "Ukraine"
        /// United Arab Emirates (the)
        case ARE = "United Arab Emirates (the)"
        /// United Kingdom of Great Britain and Northern Ireland (the)
        case GBR = "United Kingdom of Great Britain and Northern Ireland (the)"
        /// United States Minor Outlying Islands (the)
        case UMI = "United States Minor Outlying Islands (the)"
        /// United States of America (the)
        case USA = "United States of America (the)"
        /// Uruguay
        case URY = "Uruguay"
        /// Uzbekistan
        case UZB = "Uzbekistan"
        /// Vanuatu
        case VUT = "Vanuatu"
        /// Venezuela (Bolivarian Republic of)
        case VEN = "Venezuela (Bolivarian Republic of)"
        /// Viet Nam
        case VNM = "Viet Nam"
        /// Virgin Islands (British)
        case VGB = "Virgin Islands (British)"
        /// Virgin Islands (U.S.)
        case VIR = "Virgin Islands (U.S.)"
        /// Wallis and Futuna
        case WLF = "Wallis and Futuna"
        /// Western Sahara
        case ESH = "Western Sahara"
        /// Yemen
        case YEM = "Yemen"
        /// Zambia
        case ZMB = "Zambia"
        /// Zimbabwe
        case ZWE = "Zimbabwe"
        /// Åland Islands
        case ALA = "Åland Islands"
    }
} // swiftlint:disable:this file_length
