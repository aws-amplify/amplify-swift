//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import hierarchical_state_machine_swift
@testable import AWSCognitoAuthPlugin

class SRPClientTests: XCTestCase {

    func srpClient(NHexValue N: String, gHexValue g: String) throws -> SRPClientBehavior {
        return try AmplifySRPClient(NHexValue: N, gHexValue: g)
    }

    func srpClientType() -> SRPClientBehavior.Type {
        return AmplifySRPClient.self
    }

    func testGenerateKeys() throws {
        let srpClient = try srpClient(NHexValue: validNHexValue, gHexValue: "2")
        let keyPair = srpClient.generateClientKeyPair()

        XCTAssertNotNil(keyPair.privateKeyHexValue)
        XCTAssertNotNil(keyPair.publicKeyHexValue)
    }

    //MARK: - Test K value

    func testGeneratedK() throws {
        let expectedK = "538282c4354742d7cbbde2359fcf67f9f5b3a6b08791e5011b43b8a5b66d9ee6"
        let srpClient = try srpClient(NHexValue: validNHexValue, gHexValue: "2")
        XCTAssertEqual(srpClient.kHexValue, expectedK.uppercased())
    }

    //MARK: - Test U value
    func testCalculateU_1() throws {
        let clientPublicKey =
        "27042f8575322fee79d27caaec003ab3dd7bf6b7c40c3438ebac8c7532" +
        "9d2fdcf8f344c33dce23fcb7d265b681600eeef19a83be4bed41e368f2" +
        "5a3913a71203c1744f66cd2a7b5e4c06a0c062c5fce4b07b1a73fc7adc" +
        "f6233db976d1ce417ff4eb9153df873970326a9c18e36c2ae8490149d9" +
        "8422ce57a001853279761260316321f4b4e90d6fd9e4ff55b3cea2a55b" +
        "e9446f13736aad842e9af0763e83f4208320a326fb592eac84f3c65ac4" +
        "6573c41443f4c4673189e6b4afe8b84a43327de73577145927bc240839" +
        "0ab63724a17b150225cbb1620f5607c8676641ee49f6c06071a5a009be" +
        "48b7449efabfdfa9b26edea8f731b579aa803d1333dd1472dd1ae59fea" +
        "12d0a5200925be31979ac37911f67aed2f9ba4b1a326488e1a03b1e10f" +
        "2287f06df83b04c955a4776dffb49dd4cc17f9a20f0f14ec22342c2d97" +
        "795a24e5e86810d21430713fd6c9612a59e864ba251fca59e36555c4ab" +
        "b28cf6b1049544dcea3cfe3d024ed57b81a3366e0e9daee4616e7b2774" +
        "12032ec6b50e57"

        let serverPublicKey =
        "b5619b2e02a66d7681acc7ab0d4baa69921d8b8e2e1b67828c5d88d403" +
        "c93b176879a0f9c93127109f2b72120231238a3b56adefb53e8e454679" +
        "f5d3e4874926a7b1cd9515999f57867e265b30a918628bba40ccffc7ef" +
        "29f71e92e60c1acb3f48e7240ad621add7fb8c80646309d2fc980976b2" +
        "f41219d877d1264a13f52cb7233ab06e4c056bcd0af7a4a3f5e4e887e9" +
        "0da816c1e599fcc8b62d9ee2fd5f9c011f14119af03e1b39ffbfc54426" +
        "14746f1b9a8f3650244ae7711b9e0b5adb499711c81ad65d5e50f554e4" +
        "add08e499f387f517d8269cc80302f935cb6c4029782bd65ef55b315fb" +
        "ec657288b2dab1699cf32ef8c09b822e650ffe9f7ecac5eed47bc6e63a" +
        "9f9f46bd9bb3eabc7c758ca944aedb7a5a4a204fc4f5a67093a7f4ea44" +
        "4417b85e71bf7363b98a982d4f5bb77e4a6ac66f15054663775bc56744" +
        "5b62685f1d4e9bf20ac14bf00453c5b666e88e1c72a6539bfda079e4de" +
        "05b324629b160935d15cdb18d1f8dfe55f2d84afaef0f761bec33eba21" +
        "78b426a7bf2985"

        let u = try srpClientType().calculateUHexValue(clientPublicKeyHexValue: clientPublicKey,
                                                       serverPublicKeyHexValue: serverPublicKey)
        XCTAssertEqual(u, "c3a1193f8683863acc9c1d9532105c589696e3347b860080853435906b61342a".uppercased())
    }

    func testCalculateU_2() throws {
        let clientPublicKey =
        "1d94bc5059a67964f140f984f6d643eab4318e14985010490f040be249" +
        "4563f52c9039706e50aaa907e6cbafa7b6c16d44b2d14a77f179d4e173" +
        "861af911145893f7a20459cd4fb17aa7dbc57fd5ba0d330427b239d73c" +
        "5708dffea7192c6dce30b77401273e7258b9589f6cc5df3498c974877c" +
        "e7e9965412127658dfa4b8dfef440c8b2ee1b9a1ac96bcf4c135d8e73b" +
        "d7bfb3c04301af3c517e71f7bc8c2ab05df5233443a1d0b49457e4b0c7" +
        "33a3294260254f662d66b6ea49f41be84c28ee40e94f252c17f523a35c" +
        "2e90e552d20cc72230785afcfad7ac9788fa47995fa0273542ea2568c6" +
        "85318468cc499c3973db3dc8a3ab8912d99e19a5f6d2993aba81580394" +
        "cd0b1549832f28b77fd5b5cb384e09e18c90b6d04982a5d51340190774" +
        "a71021012a07469259e7e38e4c8e49cb5a8d8e60196960835d0828e848" +
        "e8edf4d614d81ecb957038dfffaa34e7174444ee677ad61cf6a53c27a3" +
        "7bed745b489e664dd289c142dcdd2ce81a264f3df98f202cdbff662633" +
        "04307dfeb598c7"

        let serverPublicKey =
        "de50cd57c08dd576667bdb03c1bb666d3e07768b8d180d5298d65b3cd3" +
        "6f697eba451bf48cb06b5e4a997650d01f3941d02ea07e8141db50ea69" +
        "57472a21b2a6055a726cbd2f09eb77a6490068e771ff8a6fc85c04d683" +
        "93d5c4913c4230f26e43bbc04c258f669f3f17d7748bceae8e23010d7d" +
        "71deae345f8f70f0f6d23f8267eed2b57a24233d33214bfb12a870bac1" +
        "d99e81a45bfcde038f7e775a1ff2c471d81b4f1cf4b2dfa9b018f0efe4" +
        "7c7f679313303469bb10562aa27b5ec47fa0ad22a28aeee6e925c6aeef" +
        "e9feab202eb131345ab854e2e55c7182c39f387fb1937d61cdd47bd028" +
        "bda06ba7482c697795f0a8906d22c599b6fee245cf4cf9a5eb71075574" +
        "8f86fd5e8a1566fcc5e920fcbd30e0da99882ac650334ccc3b17768b88" +
        "a8b9ce025b39e1d971a53b18b6cf6e9859e1f840b5ddbdd6fa18e1a23d" +
        "f6c1cf4b2ad7698e92402882c0ddb353ab0e0a253520e84ae79767fc52" +
        "36d9644b1bf9a84deb0f8c99c208d4aa4095c8f7e95ecdba0e651562d0" +
        "d80ac6272a0785"

        let u = try srpClientType().calculateUHexValue(clientPublicKeyHexValue: clientPublicKey,
                                                       serverPublicKeyHexValue: serverPublicKey)
        XCTAssertEqual(u, "bf078ed83130247cc16c6e07d646e39dda9362f5b1c6eb4f6368723b55f728e7".uppercased())
    }

    func testCalculateU_3() throws {
        let clientPublicKey =
        "3802deff7a5aedbcb0cdbb1341206df087f37f8a1b3527004f91b06d0595a" +
        "5521581eb977eb530489df2627cc57aff607688667c34758f2859d09aa350" +
        "c472405d25c1ab037284872cbc587d5780cc467fff5c4e05d95d962900741" +
        "e8a466f0640cd6619fe1a0c3f8371e7b5122069791be7ce70b1cb74aca8fb" +
        "b7963809fabc9dadc8f0d4358276b4d9787badaba5cfbc5e141112a4f4a39" +
        "c6e83ea6ed4ea982e62b82500e2975e48f2eacbb2f8e8b3d920a63e8fb5cb" +
        "5478762fe232200b7c9d4e6b8a45e2b11f62e9b096170e5a6d6102a75a40f" +
        "b6c1caa20650746818c8a737170d61dda1e7d76be3684aaa254072f9e3211" +
        "bc30b55f8ea4153896a838ef900541e6ce6e4ad1ae2abeea59de93f9da9d1" +
        "246e15045fbbb621b0a4f99751c9025d2a6ca5ea9c2e82ba1f49ef1370769" +
        "dae44d6cc7b40b657c71bc6c0ddd09d2df68eaf26f8e79b99b7f9f5244832" +
        "1fc7a7fb1cee614ff06d2902cec8199490f65bb6d9a3aaf0070fa9d813e1a" +
        "e0c10407f1f2510ac6058166c414d41664e4"

        let serverPublicKey =
        "ba81f79c4fd94c54e70f5e43d14e60003b96766bdbd2dcbf21168da870028" +
        "70536a8bfc697f9614e74945081535c78c3965ded30fc316a324c64d29306" +
        "8f5f4f10e240203ee9ef531389dd6c0c58290feddfef9dbafbc9dcc257ce1" +
        "aed45ba9a4a8e3691e5994c1867d0f1d0c6fe48b7110ab1cb68f8b816d16c" +
        "019383b0b1cc4f8dde0a4cf654073c3427eba72fd5aa8225b1d4f4a2e2262" +
        "578a34aafbef5c80dcf76271f72242f7227d207a35e9b4cad4d660e6ed302" +
        "18b31949835ee0740fd0f32ff68699661a86672923b0577afb497bef085a5" +
        "643712305eb02b00025d7c9f3c8d9ccd6b5935acbc4e03c83afe0d77f4af4" +
        "28af28519e0006ba263a33a59a5dda2f41728ead5bcb043d11bfd71446450" +
        "b9e577e0e825d1f9965582ebb32b5ab9e436ac561f7df539ec3393caff0f9" +
        "58aeae094b0a92eb5b63063d94dfee5067848d1a12353d5c08fc2e67df8ab" +
        "35aaab2db72fe322cd6d1cdd2eb8e8620726a6781a2890830c1f597c50798" +
        "8525156cbc17f39621a8e1963fa7cb6ac048"

        let u = try srpClientType().calculateUHexValue(clientPublicKeyHexValue: clientPublicKey,
                                                       serverPublicKeyHexValue: serverPublicKey)
        XCTAssertEqual(u, "4aa339a24ed483e6058e9e7afdc001409a4586af2f08ff009e4c3f8d12a0bce4".uppercased())
    }

    //MARK: - Test Shared secret value

    func testCalculateSharedSecret_1() throws {

        let clientPrivateKey =
        "98fba2902c23b5e55de97ae4e9497f0b7dfbb639f1539243029ddabd0ed10c8"

        let clientPublicKey =
        "c4808c3cee673f869923c08c3f42aa4b2a98197f2187ce9af9736a27" +
        "c1689bf7f423cc5a20973ed1b4db7daead68a54467308dd80701adb3" +
        "1756f43286cb88b1d441115e4eddcaa1730ecb3164068db45d0960b8" +
        "1a652798cf018369c5a3f581036cee2b36b4e63839b4d9b313a21b54" +
        "e658dbc2c7aa1b0bb0c73be9d9dcb713462e6630fc748e4d4899b4e1" +
        "db4b579d1a24f9fd7ecdd43ded934a5bde8e90bc488a8f49d6b849f9" +
        "5cac284e17589285d6bbcd1c86d57ccfbbb991dc3cd2b66f56d197fd" +
        "acb9cc2da9f79b582bf2e632266f73cfe2f6ae9373e1438a48aaf7fe" +
        "c6be9bf4f87415c7a500ddf8181c075f2284ab2c2810b03eb211696d" +
        "2d47584c6e9d2810ec17466ea5a2adfc99193746942b5abb48d3957d" +
        "e4ab3249d17af696b18b36d05f6051ba41dd732e23f05c378625459f" +
        "0971cffe702badd6dd4d40e06e012636fb29784f7541caaa6c8c09b9" +
        "465f7d364850228661c1573c446ef5fb859f2ee8eb6cc3642de42b47" +
        "d777b1148c4dede62819458df94a83e526c0cd9f"

        let serverPublicKey =
        "cccd551910a5a4a05af370b8f7340bd4a4cbf2daed273fcfc3c4ec112" +
        "f1424f064635e9ad8337af7a7372212793c057f24570ea2c2e87f1b47" +
        "a9153dfdeb470772f2985dc3e7ffca700a3b826ad4fe559f3d3cbdd5e" +
        "33d02a4008cd6cd1104df09236647c59ea3645beebaffefe34ea5915c" +
        "db974e905ac06e7daf4932327f1bd7c9d8e0778c971996497cecd8b17" +
        "a4e49636024ef1b6c6ba293d06d5cb49684aa8a6c03a51d6e9eb6c612" +
        "e886ad2b553e75918043150f73114f7e455f7559560f7b67f21340c5c" +
        "3dff8b1af71fe3bfa73bd0a7443d197c19ab7927d25ad360589da9ab2" +
        "e20e7fc2278eda238323ac7f1d2bd7dc909c1f96560eff8214ae0026f" +
        "67891fe97ccd49702263ee9ef93888c5797beab21bdeeba688668f1d6" +
        "002809afbd726506e7aa527ad867235aaf34131b2ba2b09e12733ad3f" +
        "cd00ea945c0ca546911d0bf23234852ae507800aa81e2722d0494ae5a" +
        "c735e7ed5c0288fd749835b9a58dd7c340a824191a9f177f12ef82410" +
        "2c3582b92bb608ab090ca34e246"

        let expectedSharedSecret =
        "eaf55a5aab2cacc78e84aea5bf6e01c4d63fc3bc7fb19c3360144e79d" +
        "cc0b2fb1f1b55203d430d396027e64cd5ad4561f7bc4c5395f43ce386" +
        "3055c522ab252cc5ec488e0f2321dcb675d410d19c042a8a3dcb51760" +
        "9dc2ebb3db42a70a91849bd0cd7ca36a2aded7bf137643e0f02da31b9" +
        "b32804bb41e5a877cd72a45a2211c90c71deea91d004baf7258e179af" +
        "d9299d91279c7a268473cfb3255d4750be7ba1da07366c8329a157703" +
        "45243132416c908a89739fd2d3e980ff0a697d628b49966a9683575ae" +
        "f37b5d3f33cc0258fb2c492123c0c01cd703680cbceff1f2c117711da" +
        "53ce9322a74a1ab5355f51e358347adfed8c40d413059a07ba1a1f53c" +
        "8f341560de8f94bff0cf027cc5a6ab556c9d3e60ac2efebc5716454ca" +
        "80e9c50d6ef2561ac23148179e37b7490baba57ff7bd65ddababaa335" +
        "454a4eb4738c42bf5166b7e99acdef377e584e00dcc01cd2e631b77fe" +
        "a29e48efb0f22409e35ab625f4b9bed94fe9af5d9fb4cd1e16a6c4c8f" +
        "3edf54d1f2b24e4afcd40d69888"

        let srpClient = try srpClient(NHexValue: validNHexValue, gHexValue: "2")
        let S = try srpClient.calculateSharedSecret(username: "VEUHc88gProyji7",
                                                    password: "dummy123@",
                                                    saltHexValue: "8bb7dcf905f418bf27b6623aa4d2f58f",
                                                    clientPrivateKeyHexValue: clientPrivateKey,
                                                    clientPublicKeyHexValue: clientPublicKey,
                                                    serverPublicKeyHexValue: serverPublicKey)
        XCTAssertEqual(S, expectedSharedSecret.uppercased())
    }

    func testCalculateSharedSecret_2() throws {
        let clientPrivateKey =
        "45af331e7466a5665668aaca7f9591c9642d296acdf5eb4dfbdabc0e0254265b"

        let clientPublicKey =
        "842c5d2e2e21e76d7f3a7a44f922ced081598ca6025ddf13b9055752" +
        "05d034263e5a63fb5cdce1c95eba4e584747d0c47e3e9316f2d5b834" +
        "589d7015431d1e27d747090891e543653f525737ab14c4885755e095" +
        "fe04a7814f88bfcc28ed8e8eb93ba13ea3a015fed2c09a87c85d3ab1" +
        "476168de3b8d817c3696ab359698beaecdc8c611ea445a73fa1568d0" +
        "34fb9b2d331916ccf34cb3ab1c8580c1a686102062a45c1af7de316e" +
        "122384592a8067ee5cbb004c580745fad7eadaafbec98db202bb3591" +
        "17c7a89adbb1ea57c294daa5516206451faa959fca608b52de76e794" +
        "4a45ce95dad141253b3e6d87494dec7a0b5e0c5faa10da38a3c4fd58" +
        "199e81f6dcc5b569033cff732c58fea5a240dc5b609d83cbcdd5627d" +
        "834db1fd211352ed38ba48bc06dfd3f343effce922cf21a4272e4f6d" +
        "ddd003022465be5903e7046a22d699e1540db31414cceba35c4d873c" +
        "dc622a5ba238813ecd5f5caeeef76985281052e05bffc779945a3da2" +
        "9dab35c0faa907184d76cfe52ea4582fab44be09"

        let serverPublicKey =
        "afa2e18a1c62c9e1e515b08b8bed1417bed6e1988d02d34de218fbb2" +
        "64cffe7c3196670183740b5c27f34efcaca05ab8af50b29951078dbc" +
        "6773e21279ef5589dcd7540ff1b2442825bf7cf091abb60bb56bdcc2" +
        "59a716c95e5d376acd9d56700d3564cd20d50405d96afc6d38993ad7" +
        "2a9ef39f437e151c5fddb138e751e7ebaa4e11918aec8d8acbdb3907" +
        "363c116a143a68c8855a133dda2ab6f722167f4a78e1de3f804bbb3a" +
        "4b19398691bebc9e44afa2c0065aff2ac929f87813a87079d3103d3d" +
        "cbf2d70bf162dad0c2c1da907166249300d0d98c53010c086be24138" +
        "e7a18f59fae791ecf46383ebcc38b11ff3a8b56d2a62f37617905648" +
        "1e2ad898a628fc062951e6467b960f448fd90985cfe548915ffa56be" +
        "b6b1e622c32acd41e2f4c6e510ca401b6295befbaeb3c2a6c9def5da" +
        "9418a39917e49d2533ba787848eb7b1cbf6db6e1532d70b2c61ab1e2" +
        "3858a43a4b03b1e552828a2ab6b5416daa0c5d5568e3ca93fc6b01d1" +
        "c66ffc246c7e81e10a97dd285461f2ebdc395bab"

        let expectedSharedSecret =
        "209172f5139cd673eaa51e7216c53eedf1a65937f128aa9139324f21" +
        "d8b45c2e289c0d327e8a5464e96f84a69427b1e06e5602f8cf231b7d" +
        "d5d52768dc88f238b575b4de97821c8f38ac3bc0f357eb117af1d638" +
        "70492261a007fabe7719672537a240ac49fbce6607aee839cc8d869f" +
        "7df0723fbac8f7dfb4b562c3167edd3daac8a7c8540e4509b0946267" +
        "c76de803b8504e0f1ccb812a3cd74a5f36154f799ea82895e4892a1b" +
        "c36997bcdab48f9a0921613a3d977ddf600ba768ed3beef3a295e1bb" +
        "ff1e7433d856ec219bd22b9554763abd1bb5ffdab446154e1f828bfd" +
        "f035bbf130b6d138b997f1ed76dc12a17fa05f031b9438c2814892e4" +
        "0cebd1713e90c049f183f5aeb8cbbec12323050cc857a3cd5df03fd7" +
        "a002117a491f79388996effa34249cfc72caed9d55374e82cd2afe41" +
        "95ccb6f021e2e2b0c5fdb1b86364b78f81acf77f82cf79ca71c640f7" +
        "4aa12cc83b5cf8ec49199dd646b5f710cf0e5a4a688fae24ab7cf378" +
        "81ec6baefe0b389ee7248a7d58fdf523c1f1ebc3"

        let srpClient = try srpClient(NHexValue: validNHexValue, gHexValue: "2")
        let S = try srpClient.calculateSharedSecret(username: "baTBpG5tZroyji7",
                                                    password: "dummy123@",
                                                    saltHexValue: "d1c1181916afc59efe7eb71674d627c",
                                                    clientPrivateKeyHexValue: clientPrivateKey,
                                                    clientPublicKeyHexValue: clientPublicKey,
                                                    serverPublicKeyHexValue: serverPublicKey)
        XCTAssertEqual(S, expectedSharedSecret.uppercased())
    }

    func testCalculateSharedSecretIllegalParam() throws {

        let clientPrivateKey =
        "98fba2902c23b5e55de97ae4e9497f0b7dfbb639f1539243029ddabd0ed10c8"

        let clientPublicKey =
        "c4808c3cee673f869923c08c3f42aa4b2a98197f2187ce9af9736a27" +
        "c1689bf7f423cc5a20973ed1b4db7daead68a54467308dd80701adb3" +
        "1756f43286cb88b1d441115e4eddcaa1730ecb3164068db45d0960b8" +
        "1a652798cf018369c5a3f581036cee2b36b4e63839b4d9b313a21b54" +
        "e658dbc2c7aa1b0bb0c73be9d9dcb713462e6630fc748e4d4899b4e1" +
        "db4b579d1a24f9fd7ecdd43ded934a5bde8e90bc488a8f49d6b849f9" +
        "5cac284e17589285d6bbcd1c86d57ccfbbb991dc3cd2b66f56d197fd" +
        "acb9cc2da9f79b582bf2e632266f73cfe2f6ae9373e1438a48aaf7fe" +
        "c6be9bf4f87415c7a500ddf8181c075f2284ab2c2810b03eb211696d" +
        "2d47584c6e9d2810ec17466ea5a2adfc99193746942b5abb48d3957d" +
        "e4ab3249d17af696b18b36d05f6051ba41dd732e23f05c378625459f" +
        "0971cffe702badd6dd4d40e06e012636fb29784f7541caaa6c8c09b9" +
        "465f7d364850228661c1573c446ef5fb859f2ee8eb6cc3642de42b47" +
        "d777b1148c4dede62819458df94a83e526c0cd9f"

        let illegalServerPublicKey =
        "cccd551910a5a4a05af370b8f7340bd4a4cbf2daed273fcfc3c4ec11" +
        "2f1424f064635e9ad8337af7a7372212793c057f24570ea2c2e87f1b" +
        "4736d4a9cad3cb7e63c6dd234e225ba7f2f3541d9938fe8637b8741b" +
        "bb7c2210f9faf164bcc90dea1263aeb024e4019411d4fa3b869d0071" +
        "9a733d8bb9506216d4c133347a11ba133f03a9dc1aa1eee084319c8b" +
        "55195422c80a15b9f51c59428f22117fec4d6e5c9fce6d4444fb7978" +
        "8fd28c5d39c7517496085076d2a5b8db220be9d06e84f7a4d33c3b85" +
        "2efa60466f37028f963fdace5e37bfd2cbbd0df5eb8683a412da1d69" +
        "2d5c9fc0ccda937cd86947c020f73191be01c31744d03d16fb054428" +
        "1649b9643162d718e53450d283c332d67db37d969bc8cf97173c9078" +
        "a62dd20c233e76b9160de71941ff37c669b12a3f7d6c4c89aff9d66b" +
        "f0fdcbf1851c405be6e0a2ad1c0db51e108c7596c3ebd3cae2d5a949" +
        "d893d1e8a89f42cfb9ea8e442c5ee3733b49e0368a7a8379b087d99b" +
        "32f45d166996089051236e59ebd0ea01130905e8363997ef1ffa4c57" +
        "7e7814874b2c166c16bc9ee25a4b84466e472343cb087b3fff85cd81" +
        "753562710ac7833858db245901011598bb3726ab1a"

        let srpClient = try srpClient(NHexValue: validNHexValue, gHexValue: "2")
        XCTAssertThrowsError(try srpClient.calculateSharedSecret(
            username: "VEUHc88gProyji7",
            password: "dummy123@",
            saltHexValue: "8bb7dcf905f418bf27b6623aa4d2f58f",
            clientPrivateKeyHexValue: clientPrivateKey,
            clientPublicKeyHexValue: clientPublicKey,
            serverPublicKeyHexValue: illegalServerPublicKey)
        ) { error in
            guard let srpError = error as? SRPError else {
                XCTFail("Should return SRPError")
                return
            }
            XCTAssertEqual(srpError, SRPError.illegalParameter)
        }
    }
}

extension SRPClientTests {

    var validNHexValue: String {
        "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E08" +
        "8A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B" +
        "302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9" +
        "A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE6" +
        "49286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8" +
        "FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D" +
        "670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C" +
        "180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF695581718" +
        "3995497CEA956AE515D2261898FA051015728E5A8AAAC42DAD33170D" +
        "04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575D060C7D" +
        "B3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D226" +
        "1AD2EE6BF12FFA06D98A0864D87602733EC86A64521F2B18177B200C" +
        "BBE117577A615D6C770988C0BAD946E208E24FA074E5AB3143DB5BFC" +
        "E0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF"

    }
}
