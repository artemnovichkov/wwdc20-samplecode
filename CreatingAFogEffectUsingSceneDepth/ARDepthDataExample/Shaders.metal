/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's shaders.
*/

#include <metal_stdlib>
#include <simd/simd.h>

// Include header shared between this Metal shader code and C code executing Metal API commands. 
#import "ShaderTypes.h"

using namespace metal;

typedef struct {
    float2 position [[attribute(kVertexAttributePosition)]];
    float2 texCoord [[attribute(kVertexAttributeTexcoord)]];
} ImageVertex;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ImageColorInOut;

// Convert from YCbCr to rgb.
float4 ycbcrToRGBTransform(float4 y, float4 CbCr) {
    const float4x4 ycbcrToRGBTransform = float4x4(
      float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
      float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
      float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
      float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );

    float4 ycbcr = float4(y.r, CbCr.rg, 1.0);
    return ycbcrToRGBTransform * ycbcr;
}

typedef struct {
    float2 position;
    float2 texCoord;
} FogVertex;

typedef struct {
    float4 position [[position]];
    float2 texCoordCamera;
    float2 texCoordScene;
} FogColorInOut;

// Fog the image vertex function.
vertex FogColorInOut fogVertexTransform(const device FogVertex* cameraVertices [[ buffer(0) ]],
                                                         const device FogVertex* sceneVertices [[ buffer(1) ]],
                                                         unsigned int vid [[ vertex_id ]]) {
    FogColorInOut out;

    const device FogVertex& cv = cameraVertices[vid];
    const device FogVertex& sv = sceneVertices[vid];

    out.position = float4(cv.position, 0.0, 1.0);
    out.texCoordCamera = cv.texCoord;
    out.texCoordScene = sv.texCoord;

    return out;
}

// Fog fragment function.
fragment half4 fogFragmentShader(FogColorInOut in [[ stage_in ]],
texture2d<float, access::sample> cameraImageTextureY [[ texture(0) ]],
texture2d<float, access::sample> cameraImageTextureCbCr [[ texture(1) ]],
depth2d<float, access::sample> arDepthTexture [[ texture(2) ]],
texture2d<uint> arDepthConfidence [[ texture(3) ]])
{
    // Whether to show the confidence debug visualization.
    // - Tag: ConfidenceVisualization
    // Set to `true` to visualize confidence.
    bool confidenceDebugVisualizationEnabled = false;
    
    // Set the maximum fog saturation to 4.0 meters. Device maximum is 5.0 meters.
    const float fogMax = 4.0;
    
    // Fog is fully opaque, middle grey
    const half4 fogColor = half4(0.5, 0.5, 0.5, 1.0);
    
    // Confidence debug visualization is red.
    const half4 confidenceColor = half4(1.0, 0.0, 0.0, 1.0);
    
    // Maximum confidence is `ARConfidenceLevelHigh` = 2.
    const uint maxConfidence = 2;
    
    // Create an object to sample textures.
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    // Sample this pixel's camera image color.
    float4 rgb = ycbcrToRGBTransform(
        cameraImageTextureY.sample(s, in.texCoordCamera),
        cameraImageTextureCbCr.sample(s, in.texCoordCamera)
    );
    half4 cameraColor = half4(rgb);

    // Sample this pixel's depth value.
    float depth = arDepthTexture.sample(s, in.texCoordCamera);
    
    // Ignore depth values greater than the maximum fog distance.
    depth = clamp(depth, 0.0, fogMax);
    
    // Determine this fragment's percentage of fog.
    float fogPercentage = depth / fogMax;
    
    // Mix the camera and fog colors based on the fog percentage.
    half4 foggedColor = mix(cameraColor, fogColor, fogPercentage);
    
    // Just return the fogged color if confidence visualization is disabled.
    if(!confidenceDebugVisualizationEnabled) {
        return foggedColor;
    } else {
        // Sample the depth confidence.
        uint confidence = arDepthConfidence.sample(s, in.texCoordCamera).x;
        
        // Assign a color percentage based on confidence.
        float confidencePercentage = (float)confidence / (float)maxConfidence;

        // Return the mixed confidence and foggedColor.
        return mix(confidenceColor, foggedColor, confidencePercentage);
    }
}

