package software.amazon.smithy.aws.swift.codegen.customizations

import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.swift.codegen.customization.BoxServices
import software.amazon.smithy.aws.swift.codegen.newTestContext
import software.amazon.smithy.aws.swift.codegen.protocols.awsjson.AWSJSON1_0ProtocolGenerator
import software.amazon.smithy.aws.swift.codegen.toSmithyModel
import software.amazon.smithy.model.knowledge.NullableIndex
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.expectShape

class BoxServicesTest {
    @Test
    fun testPrimitiveShapesAreBoxed() {
        val smithy = """
            namespace com.test
            service Example { 
                version: "1.0.0",
                operations: [Foo]
            }
            
            operation Foo {
                input: Primitives
            }
            
            structure Primitives {
                int: PrimitiveInteger,
                bool: PrimitiveBoolean,
                long: PrimitiveLong,
                double: PrimitiveDouble,
                boxedAlready: BoxedField,
                notPrimitive: NotPrimitiveField,
                other: Other
            }
            
            @box
            integer BoxedField
            
            structure Other {}
            
            integer NotPrimitiveField
        """
        val model = smithy.toSmithyModel()
        val ctx = model.newTestContext("com.test#Example", AWSJSON1_0ProtocolGenerator()).ctx
        val operationTransform = AddOperationShapes.execute(model, ctx.service, ctx.settings.moduleName)
        val transformed = BoxServices().preprocessModel(operationTransform, ctx.settings)

        // get the synthetic input which is the one that will be transformed
        val struct = transformed.expectShape<StructureShape>("smithy.swift.synthetic#FooInput")
        val intMember = struct.getMember("int").get() as MemberShape
        val boolMember = struct.getMember("bool").get() as MemberShape
        val longMember = struct.getMember("long").get() as MemberShape
        val notPrimitiveMember = struct.getMember("notPrimitive").get() as MemberShape
        val nullableIndex = NullableIndex.of(transformed)

        assertTrue(nullableIndex.isMemberNullable(intMember, NullableIndex.CheckMode.CLIENT_ZERO_VALUE_V1))
        assertTrue(nullableIndex.isMemberNullable(boolMember, NullableIndex.CheckMode.CLIENT_ZERO_VALUE_V1))
        assertTrue(nullableIndex.isMemberNullable(longMember, NullableIndex.CheckMode.CLIENT_ZERO_VALUE_V1))
        assertTrue(nullableIndex.isMemberNullable(notPrimitiveMember, NullableIndex.CheckMode.CLIENT_ZERO_VALUE_V1))
    }
}
