/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for simple matrix math functions
*/

#ifndef Transforms_h
#define Transforms_h

#import <simd/simd.h>

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz);
matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis);
matrix_float4x4 matrix4x4_scale(float sx, float sy, float sz);

#endif
