/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample.
*/
#include "ShaderTypes.h"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

using namespace raytracing;

constant unsigned int resourcesStride  [[function_constant(0)]];
constant bool useIntersectionFunctions [[function_constant(1)]];

constant unsigned int primes[] = {
    2,   3,  5,  7,
    11, 13, 17, 19,
    23, 29, 31, 37,
    41, 43, 47, 53,
    59, 61, 67, 71,
    73, 79, 83, 89
};

// Returns the i'th element of the Halton sequence using the d'th prime number as a
// base. The Halton sequence is a "low discrepency" sequence: the values appear
// random but are more evenly distributed than a purely random sequence. Each random
// value used to render the image should use a different independent dimension 'd',
// and each sample (frame) should use a different index 'i'. To decorrelate each
// pixel, you can apply a random offset to 'i'.
float halton(unsigned int i, unsigned int d) {
    unsigned int b = primes[d];

    float f = 1.0f;
    float invB = 1.0f / b;

    float r = 0;

    while (i > 0) {
        f = f * invB;
        r = r + f * (i % b);
        i = i / b;
    }

    return r;
}

// Interpolates vertex attribute of an arbitrary type across the surface of a triangle
// given the barycentric coordinates and triangle index in an intersection structure.
template<typename T>
inline T interpolateVertexAttribute(device T *attributes, unsigned int primitiveIndex, float2 uv) {
    // Barycentric coordinates sum to one.
    float3 uvw;
    uvw.xy = uv;
    uvw.z = 1.0f - uvw.x - uvw.y;

    // Look up value for each vertex.
    T T0 = attributes[primitiveIndex * 3 + 0];
    T T1 = attributes[primitiveIndex * 3 + 1];
    T T2 = attributes[primitiveIndex * 3 + 2];

    // Compute sum of vertex attributes weighted by barycentric coordinates.
    return uvw.x * T0 + uvw.y * T1 + uvw.z * T2;
}

// Uses the inversion method to map two uniformly random numbers to a three dimensional
// unit hemisphere, where the probability of a given sample is proportional to the cosine
// of the angle between the sample direction and the "up" direction (0, 1, 0).
inline float3 sampleCosineWeightedHemisphere(float2 u) {
    float phi = 2.0f * M_PI_F * u.x;

    float cos_phi;
    float sin_phi = sincos(phi, cos_phi);

    float cos_theta = sqrt(u.y);
    float sin_theta = sqrt(1.0f - cos_theta * cos_theta);

    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}

// Maps two uniformly random numbers to the surface of a two-dimensional area light
// source and returns the direction to this point, the amount of light which travels
// between the intersection point and the sample point on the light source, as well
// as the distance between these two points.

inline void sampleAreaLight(device AreaLight & light,
                            float2 u,
                            float3 position,
                            thread float3 & lightDirection,
                            thread float3 & lightColor,
                            thread float & lightDistance)
{
    // Map to -1..1
    u = u * 2.0f - 1.0f;

    // Transform into light's coordinate system.
    float3 samplePosition = light.position +
                            light.right * u.x +
                            light.up * u.y;

    // Compute vector from sample point on light source to intersection point.
    lightDirection = samplePosition - position;

    lightDistance = length(lightDirection);

    float inverseLightDistance = 1.0f / max(lightDistance, 1e-3f);

    // Normalize the light direction.
    lightDirection *= inverseLightDistance;

    // Start with the light's color.
    lightColor = light.color;

    // Light falls off with the inverse square of the distance to the intersection point.
    lightColor *= (inverseLightDistance * inverseLightDistance);

    // Light also falls off with the cosine of angle between the intersection point and
    // the light source.
    lightColor *= saturate(dot(-lightDirection, light.forward));
}

// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction.
inline float3 alignHemisphereWithNormal(float3 sample, float3 normal) {
    // Set the "up" vector to the normal
    float3 up = normal;

    // Find an arbitrary direction perpendicular to the normal. This will become the
    // "right" vector.
    float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));

    // Find a third vector perpendicular to the previous two. This will be the
    // "forward" vector.
    float3 forward = cross(right, up);

    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * right + sample.y * up + sample.z * forward;
}

// Return type for a bounding box intersection function.
struct BoundingBoxIntersection {
    bool accept    [[accept_intersection]]; // Whether to accept or reject the intersection.
    float distance [[distance]];            // Distance from the ray origin to the intersection point.
};

// Resources for a piece of triangle geometry.
struct TriangleResources {
    device float3 *vertexNormals;
    device float3 *vertexColors;
};

// Resources for a piece of sphere geometry.
struct SphereResources {
    device Sphere *spheres;
};

/*
 Custom sphere intersection function. The [[intersection]] keyword marks this as an intersection
 function. The [[bounding_box]] keyword means that this intersection function handles intersecting rays
 with bounding box primitives. To create sphere primitives, the sample creates bounding boxes that
 enclose the sphere primitives.

 The [[triangle_data]] and [[instancing]] keywords indicate that the intersector that calls this
 intersection function returns barycentric coordinates for triangle intersections and traverses
 an instance acceleration structure. These keywords must match between the intersection functions,
 intersection function table, intersector, and intersection result to ensure that Metal propagates
 data correctly between stages. Using fewer tags when possible may result in better performance,
 as Metal may need to store less data and pass less data between stages. For example, if you do not
 need barycentric coordinates, omitting [[triangle_data]] means Metal can avoid computing and storing
 them.

 The arguments to the intersection function contain information about the ray, primitive to be
 tested, and so on. The ray intersector provides this datas when it calls the intersection function.
 Metal provides other built-in arguments but this sample doesn't use them.
 */
[[intersection(bounding_box, triangle_data, instancing)]]
BoundingBoxIntersection sphereIntersectionFunction(// Ray parameters passed to the ray intersector below
                                                   float3 origin               [[origin]],
                                                   float3 direction            [[direction]],
                                                   float minDistance           [[min_distance]],
                                                   float maxDistance           [[max_distance]],
                                                   // Information about the primitive.
                                                   unsigned int primitiveIndex [[primitive_id]],
                                                   unsigned int geometryIndex  [[geometry_intersection_function_table_offset]],
                                                   // Custom resources bound to the intersection function table.
                                                   device void *resources      [[buffer(0)]])
{
    // Look up the resources for this piece of sphere geometry.
    device SphereResources & sphereResources = *(device SphereResources *)((device char *)resources + resourcesStride * geometryIndex);

    // Get the actual sphere enclosed in this bounding box.
    device Sphere & sphere = sphereResources.spheres[primitiveIndex];

    // Check for intersection between the ray and sphere mathematically.
    float3 oc = origin - sphere.origin;

    float a = dot(direction, direction);
    float b = 2 * dot(oc, direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;

    float disc = b * b - 4 * a * c;

    BoundingBoxIntersection ret;

    if (disc <= 0.0f) {
        // If the ray missed the sphere, return false.
        ret.accept = false;
    }
    else {
        // Otherwise, compute the intersection distance.
        ret.distance = (-b - sqrt(disc)) / (2 * a);

        // The intersection function must also check whether the intersection distance is
        // within the acceptable range. Intersection functions do not run in any particular order,
        // so the maximum distance may be different from the one passed into the ray intersector.
        ret.accept = ret.distance >= minDistance && ret.distance <= maxDistance;
    }

    return ret;
}

__attribute__((always_inline))
float3 transformPoint(float3 p, float4x4 transform) {
    return (transform * float4(p.x, p.y, p.z, 1.0f)).xyz;
}

__attribute__((always_inline))
float3 transformDirection(float3 p, float4x4 transform) {
    return (transform * float4(p.x, p.y, p.z, 0.0f)).xyz;
}

// Main ray tracing kernel.
kernel void raytracingKernel(uint2 tid [[thread_position_in_grid]],
                             constant Uniforms & uniforms,
                             texture2d<unsigned int> randomTex,
                             texture2d<float> prevTex,
                             texture2d<float, access::write> dstTex,
                             device void *resources,
                             device MTLAccelerationStructureInstanceDescriptor *instances,
                             device AreaLight *areaLights,
                             instance_acceleration_structure accelerationStructure,
                             intersection_function_table<triangle_data, instancing> intersectionFunctionTable)
{
    // The sample aligns the thread count to the threadgroup size. which means the thread count
    // may be different than the bounds of the texture. Test to make sure this thread
    // is referencing a pixel within the bounds of the texture.
    if (tid.x < uniforms.width && tid.y < uniforms.height) {
        // The ray to cast.
        ray ray;

        // Pixel coordinates for this thread.
        float2 pixel = (float2)tid;

        // Apply a random offset to the random number index to decorrelate pixels.
        unsigned int offset = randomTex.read(tid).x;

        // Add a random offset to the pixel coordinates for antialiasing.
        float2 r = float2(halton(offset + uniforms.frameIndex, 0),
                          halton(offset + uniforms.frameIndex, 1));

        pixel += r;

        // Map pixel coordinates to -1..1.
        float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
        uv = uv * 2.0f - 1.0f;

        constant Camera & camera = uniforms.camera;

        // Rays start at the camera position.
        ray.origin = camera.position;

        // Map normalized pixel coordinates into camera's coordinate system.
        ray.direction = normalize(uv.x * camera.right +
                                  uv.y * camera.up +
                                  camera.forward);

        // Don't limit intersection distance.
        ray.max_distance = INFINITY;

        // Start with a fully white color. The kernel scales the light each time the
        // ray bounces off of a surface, based on how much of each light component
        // the surface absorbs.

        float3 color = float3(1.0f, 1.0f, 1.0f);

        float3 accumulatedColor = float3(0.0f, 0.0f, 0.0f);

        // Create an intersector to test for intersection between the ray and the geometry in the scene.
        intersector<triangle_data, instancing> i;

        // If the sample isn't using intersection functions, provide some hints to Metal for
        // better performance
        if (!useIntersectionFunctions) {
            i.assume_geometry_type(geometry_type::triangle);
            i.force_opacity(forced_opacity::opaque);
        }

        typename intersector<triangle_data, instancing>::result_type intersection;

        // Simulate up to 3 ray bounces. Each bounce will propagate light backwards along the
        // ray's path towards the camera.
        for (int bounce = 0; bounce < 3; bounce++) {
            // Get the closest intersection, not the first intersection. This is the default, but
            // the sample adjusts this property below when it casts shadow rays.
            i.accept_any_intersection(false);

            // Check for intersection between the ray and the acceleration structure. If the sample
            // isn't using intersection functions, it doesn't need to include one.
            if (useIntersectionFunctions)
                intersection = i.intersect(ray, accelerationStructure, bounce == 0 ? RAY_MASK_PRIMARY : RAY_MASK_SECONDARY, intersectionFunctionTable);
            else
                intersection = i.intersect(ray, accelerationStructure, bounce == 0 ? RAY_MASK_PRIMARY : RAY_MASK_SECONDARY);

            // Stop if the ray didn't hit anything and has bounced out of the scene.
            if (intersection.type == intersection_type::none)
                break;

            unsigned int instanceIndex = intersection.instance_id;

            // Look up the mask for this instance, which indicates what type of geometry the ray hit.
            unsigned int mask = instances[instanceIndex].mask;

            // If the ray hit a light source, set the color to white and stop immediately.
            if (mask == GEOMETRY_MASK_LIGHT) {
                accumulatedColor = float3(1.0f, 1.0f, 1.0f);
                break;
            }

            // The ray hit something. Look up the transformation matrix for this instance.
            float4x4 objectToWorldSpaceTransform(1.0f);

            for (int column = 0; column < 4; column++)
                for (int row = 0; row < 3; row++)
                    objectToWorldSpaceTransform[column][row] = instances[instanceIndex].transformationMatrix[column][row];

            // Compute intersection point in world space.
            float3 worldSpaceIntersectionPoint = ray.origin + ray.direction * intersection.distance;

            unsigned primitiveIndex = intersection.primitive_id;
            unsigned int geometryIndex = instances[instanceIndex].accelerationStructureIndex;
            float2 barycentric_coords = intersection.triangle_barycentric_coord;

            float3 worldSpaceSurfaceNormal = 0.0f;
            float3 surfaceColor = 0.0f;

            if (mask & GEOMETRY_MASK_TRIANGLE) {
                // The ray hit a triangle. Look up the corresponding geometry's normal and UV buffers.
                device TriangleResources & triangleResources = *(device TriangleResources *)((device char *)resources + resourcesStride * geometryIndex);

                // Interpolate the vertex normal at the intersection point.
                float3 objectSpaceSurfaceNormal = interpolateVertexAttribute(triangleResources.vertexNormals, primitiveIndex, barycentric_coords);

                // Transform the normal from object to world space.
                worldSpaceSurfaceNormal = normalize(transformDirection(objectSpaceSurfaceNormal, objectToWorldSpaceTransform));

                // Interpolate the vertex color at the intersection point.
                surfaceColor = interpolateVertexAttribute(triangleResources.vertexColors, primitiveIndex, barycentric_coords);
            }
            else if (mask & GEOMETRY_MASK_SPHERE) {
                // The ray hit a sphere. Look up the corresponding sphere buffer.
                device SphereResources & sphereResources = *(device SphereResources *)((device char *)resources +resourcesStride * geometryIndex);

                device Sphere & sphere = sphereResources.spheres[primitiveIndex];

                // Transform the sphere's origin from object space to world space.
                float3 worldSpaceOrigin = transformPoint(sphere.origin, objectToWorldSpaceTransform);

                // Compute the surface normal directly in world space.
                worldSpaceSurfaceNormal = normalize(worldSpaceIntersectionPoint - worldSpaceOrigin);

                // The sphere is a uniform color so no need to interpolate the color across the surface.
                surfaceColor = sphere.color;
            }

            // Choose a random light source to sample.
            float lightSample = halton(offset + uniforms.frameIndex, 2 + bounce * 5 + 0);
            unsigned int lightIndex = min((unsigned int)(lightSample * uniforms.lightCount), uniforms.lightCount - 1);

            // Choose a random point to sample on the light source.
            float2 r = float2(halton(offset + uniforms.frameIndex, 2 + bounce * 5 + 1),
                              halton(offset + uniforms.frameIndex, 2 + bounce * 5 + 2));

            float3 worldSpaceLightDirection;
            float3 lightColor;
            float lightDistance;

            // Sample the lighting between the intersection point and the point on the area light.
            sampleAreaLight(areaLights[lightIndex], r, worldSpaceIntersectionPoint, worldSpaceLightDirection,
                            lightColor, lightDistance);

            // Scale the light color by the cosine of the angle between the light direction and
            // surface normal.
            lightColor *= saturate(dot(worldSpaceSurfaceNormal, worldSpaceLightDirection));

            // Scale the light color by the number of lights to compensate for the fact that
            // the sample only samples one light source at random.
            lightColor *= uniforms.lightCount;

            // Scale the ray color by the color of the surface. This simulates light being absorbed into
            // the surface.
            color *= surfaceColor;

            // Compute the shadow ray. The shadow ray checks if the sample position on the
            // light source is visible from the current intersection point.
            // If it is, the lighting contribution is added to the output image.
            struct ray shadowRay;

            // Add a small offset to the intersection point to avoid intersecting the same
            // triangle again.
            shadowRay.origin = worldSpaceIntersectionPoint + worldSpaceSurfaceNormal * 1e-3f;

            // Travel towards the light source.
            shadowRay.direction = worldSpaceLightDirection;

            // Don't overshoot the light source.
            shadowRay.max_distance = lightDistance - 1e-3f;

            // Shadow rays check only whether there is an object between the intersection point
            // and the light source. Tell Metal to return after finding any intersection.
            i.accept_any_intersection(true);

            if (useIntersectionFunctions)
                intersection = i.intersect(shadowRay, accelerationStructure, RAY_MASK_SHADOW, intersectionFunctionTable);
            else
                intersection = i.intersect(shadowRay, accelerationStructure, RAY_MASK_SHADOW);

            // If there was no intersection, then the light source is visible from the original
            // intersection  point. Add the light's contribution to the image.
            if (intersection.type == intersection_type::none)
                accumulatedColor += lightColor * color;

            // Next choose a random direction to continue the path of the ray. This will
            // cause light to bounce between surfaces. The sample could apply a fair bit of math
            // to compute the fraction of light reflected by the current intersection point to the
            // previous point from the next point. However, by choosing a random direction with
            // probability proportional to the cosine (dot product) of the angle between the
            // sample direction and surface normal, the math entirely cancels out except for
            // multiplying by the surface color. This sampling strategy also reduces the amount
            // of noise in the output image.
            r = float2(halton(offset + uniforms.frameIndex, 2 + bounce * 5 + 3),
                       halton(offset + uniforms.frameIndex, 2 + bounce * 5 + 4));

            float3 worldSpaceSampleDirection = sampleCosineWeightedHemisphere(r);
            worldSpaceSampleDirection = alignHemisphereWithNormal(worldSpaceSampleDirection, worldSpaceSurfaceNormal);

            ray.origin = worldSpaceIntersectionPoint + worldSpaceSurfaceNormal * 1e-3f;
            ray.direction = worldSpaceSampleDirection;
        }

        // Average this frame's sample with all of the previous frames.
        if (uniforms.frameIndex > 0) {
            float3 prevColor = prevTex.read(tid).xyz;
            prevColor *= uniforms.frameIndex;

            accumulatedColor += prevColor;
            accumulatedColor /= (uniforms.frameIndex + 1);
        }

        dstTex.write(float4(accumulatedColor, 1.0f), tid);
    }
}

// Screen filling quad in normalized device coordinates.
constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct CopyVertexOut {
    float4 position [[position]];
    float2 uv;
};

// Simple vertex shader which passes through NDC quad positions.
vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]]) {
    float2 position = quadVertices[vid];

    CopyVertexOut out;

    out.position = float4(position, 0, 1);
    out.uv = position * 0.5f + 0.5f;

    return out;
}

// Simple fragment shader which copies a texture and applies a simple tonemapping function.
fragment float4 copyFragment(CopyVertexOut in [[stage_in]],
                             texture2d<float> tex)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);

    float3 color = tex.sample(sam, in.uv).xyz;

    // Apply a very simple tonemapping function to reduce the dynamic range of the
    // input image into a range which the screen can display.
    color = color / (1.0f + color);

    return float4(color, 1.0f);
}
