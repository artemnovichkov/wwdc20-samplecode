/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header that contains types and enumeration constants shared between Metal shaders and C/Objective-C source.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef enum AAPLBufferIndex
{
    AAPLBufferIndexMeshPositions    = 0,
    AAPLBufferIndexMeshGenerics     = 1,
    AAPLBufferIndexFrameData        = 2,
} AAPLBufferIndex;

typedef enum AAPLVertexAttribute
{
    AAPLVertexAttributePosition  = 0,
    AAPLVertexAttributeTexcoord  = 1,
} AAPLVertexAttribute;

typedef enum AAPLTextureIndex
{
    AAPLTextureIndexColorMap = 0,
    AAPLTextureIndexComputeIn = 1,
    AAPLTextureIndexComputeOut = 2,
} AAPLTextureIndex;

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
} AAPLPerFrameData;

#endif /* ShaderTypes_h */
