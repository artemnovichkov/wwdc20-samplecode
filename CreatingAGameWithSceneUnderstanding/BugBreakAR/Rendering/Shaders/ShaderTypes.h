/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Shader Types
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef enum BufferIndices {
    kBufferIndexMeshPositions    = 0,
    kBufferIndexMeshGenerics     = 1,
    kBufferIndexInstanceUniforms = 2,
    kBufferIndexSharedUniforms   = 3,
    kBufferIndexDebug            = 4,
    kBufferIndexVBO              = 5
} BufferIndices;

typedef enum VertexAttributes {
    kVertexAttributePosition  = 0,
    kVertexAttributeTexcoord  = 1,
    kVertexAttributeNormal    = 2,
    kVertexAttributeTangent = 3,
    kVertexAttributeBitangent = 4
} VertexAttributes;

typedef struct {
    // Camera Uniforms
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 deviceMatrix;   // device in space
    
    float pointSize;
    float progress; // 0 for pre-intro, 1 for intro Complete

} SharedUniforms;

typedef struct {
    matrix_float4x4 modelMatrix;
    simd_float4 color;
    int fadeType;
} InstanceUniforms;

#endif /* ShaderTypes_h */
