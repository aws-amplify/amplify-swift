/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */
package software.amazon.smithy.aws.swift.codegen.customization.s3

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.customtraits.PaginationTruncationMember
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.expectShape

private val TRUNCATION_MEMBER_IDS = setOf(
    "com.amazonaws.s3#ListPartsOutput\$IsTruncated",
)

/**
 * Applies the [PaginationTruncationMember] annotation to a manually-curated list of operations and members to handle
 * non-standard pagination termination conditions.
 */
class TruncatablePaginationIntegration : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean =
        model.expectShape<ServiceShape>(settings.service).isS3

    override fun preprocessModel(model: Model, settings: SwiftSettings): Model = ModelTransformer
        .create()
        .mapShapes(model) { shape ->
            when {
                shape.id.toString() in TRUNCATION_MEMBER_IDS -> {
                    check(shape is MemberShape) { "Cannot apply PaginationTruncationMember to non-member shape" }
                    shape.toBuilder().addTrait(PaginationTruncationMember()).build()
                }
                else -> shape
            }
        }
}
