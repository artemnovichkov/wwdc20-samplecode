/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal CoreImage kernel code for highlighting pixels in the extended dynamic range with rolling stripes
*/

#include <metal_stdlib>
#include <CoreImage/CoreImage.h> // includes CIKernelMetalLib.h
using namespace metal;

extern "C" float4 HDRHighlight(coreimage::sample_t s, float time, coreimage::destination dest) 
{
    float diagLine = dest.coord().x + dest.coord().y;
    float patternWidth = 40;
    float zebra = fract(diagLine/patternWidth + time*2.0);
    
    if ((zebra > 0.5) && (s.r > 1 || s.g > 1 || s.b > 1))
        return float4(2.0, 0.0, 0.0, 1.0);
    else
        return s;
}
