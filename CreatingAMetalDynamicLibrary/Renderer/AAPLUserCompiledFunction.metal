/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of a user function compiled
as an override for a dynamic library.
*/

#include <metal_stdlib>

using namespace metal;

// This function gets compiled and built
// into a dynamic library when the user
// presses the `Compile` button in the sample
namespace AAPLUserDylib
{
    float4 getFullScreenColor(float4 inColor)
    {
        const float3 kRec709Luma =
            float3(0.2126, 0.7152, 0.0722);
        half grey =
            (half)dot(inColor.rgb, kRec709Luma);
        return float4(grey, grey, grey, 1.0);
    }
}
