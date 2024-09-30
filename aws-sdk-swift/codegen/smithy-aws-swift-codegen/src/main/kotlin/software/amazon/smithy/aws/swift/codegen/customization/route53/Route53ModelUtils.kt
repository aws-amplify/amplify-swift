package software.amazon.smithy.aws.swift.codegen.customization.route53

import software.amazon.smithy.aws.swift.codegen.sdkId
import software.amazon.smithy.model.shapes.ServiceShape

val ServiceShape.isRoute53: Boolean
    get() = sdkId.lowercase() == "route 53"
