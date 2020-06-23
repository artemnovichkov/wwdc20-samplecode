/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of a user-generated dynamic library.
*/

#include "AAPLUserDylib.h"

using namespace metal;

float4 AAPLUserDylib::getFullScreenColor(float4 inColor)
{
    return float4(inColor.r, inColor.g, inColor.b, 0);
}
