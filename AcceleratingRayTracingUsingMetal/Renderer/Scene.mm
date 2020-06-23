/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of class describing objects in a scene
*/

#import "Scene.h"

#import <vector>

using namespace simd;

MTLResourceOptions getManagedBufferStorageMode() {
#if !TARGET_OS_IPHONE
    return MTLResourceStorageModeManaged;
#else
    return MTLResourceStorageModeShared;
#endif
}

@implementation Geometry

- (instancetype)initWithDevice:(id <MTLDevice>)device
{
    self = [super init];

    if (self) {
        _device = device;
    }

    return self;
}

- (void)uploadToBuffers {
}

- (void)clear {
}

- (MTLAccelerationStructureGeometryDescriptor *)geometryDescriptor {
    return nil;
}

- (NSArray <id <MTLResource>> *)resources {
    return @[];
}

- (NSString *)intersectionFunctionName {
    return nil;
}

@end

float3 getTriangleNormal(float3 v0, float3 v1, float3 v2) {
    float3 e1 = normalize(v1 - v0);
    float3 e2 = normalize(v2 - v0);

    return cross(e1, e2);
}

@implementation TriangleGeometry {
    id <MTLBuffer> _vertexPositionBuffer;
    id <MTLBuffer> _vertexNormalBuffer;
    id <MTLBuffer> _vertexColorBuffer;

    std::vector<vector_float3> _vertices;
    std::vector<vector_float3> _normals;
    std::vector<vector_float3> _colors;
};

- (void)uploadToBuffers {
    MTLResourceOptions options = getManagedBufferStorageMode();

    id <MTLDevice> device = self.device;

    _vertexPositionBuffer = [device newBufferWithLength:_vertices.size() * sizeof(vector_float3) options:options];
    _vertexNormalBuffer = [device newBufferWithLength:_normals.size() * sizeof(vector_float3) options:options];
    _vertexColorBuffer = [device newBufferWithLength:_colors.size() * sizeof(vector_float3) options:options];

    memcpy(_vertexPositionBuffer.contents, &_vertices[0], _vertexPositionBuffer.length);
    memcpy(_vertexNormalBuffer.contents, &_normals[0], _vertexNormalBuffer.length);
    memcpy(_vertexColorBuffer.contents, &_colors[0], _vertexColorBuffer.length);

#if !TARGET_OS_IPHONE
    [_vertexPositionBuffer didModifyRange:NSMakeRange(0, _vertexPositionBuffer.length)];
    [_vertexNormalBuffer didModifyRange:NSMakeRange(0, _vertexNormalBuffer.length)];
    [_vertexColorBuffer didModifyRange:NSMakeRange(0, _vertexColorBuffer.length)];
#endif
}

- (void)clear {
    _vertices.clear();
    _normals.clear();
    _colors.clear();
}

- (void)addCubeFaceWithCubeVertices:(float3 *)cubeVertices
                              color:(float3)color
                                 i0:(unsigned int)i0
                                 i1:(unsigned int)i1
                                 i2:(unsigned int)i2
                                 i3:(unsigned int)i3
                      inwardNormals:(bool)inwardNormals
{
    float3 v0 = cubeVertices[i0];
    float3 v1 = cubeVertices[i1];
    float3 v2 = cubeVertices[i2];
    float3 v3 = cubeVertices[i3];

    float3 n0 = getTriangleNormal(v0, v1, v2);
    float3 n1 = getTriangleNormal(v0, v2, v3);

    if (inwardNormals) {
        n0 = -n0;
        n1 = -n1;
    }

    _vertices.push_back(v0);
    _vertices.push_back(v1);
    _vertices.push_back(v2);
    _vertices.push_back(v0);
    _vertices.push_back(v2);
    _vertices.push_back(v3);

    for (int i = 0; i < 3; i++)
        _normals.push_back(n0);

    for (int i = 0; i < 3; i++)
        _normals.push_back(n1);

    for (int i = 0; i < 6; i++)
        _colors.push_back(color);
}

- (void)addCubeWithFaces:(unsigned int)faceMask
                   color:(vector_float3)color
               transform:(matrix_float4x4)transform
           inwardNormals:(bool)inwardNormals
{
    float3 cubeVertices[] = {
        vector3(-0.5f, -0.5f, -0.5f),
        vector3( 0.5f, -0.5f, -0.5f),
        vector3(-0.5f,  0.5f, -0.5f),
        vector3( 0.5f,  0.5f, -0.5f),
        vector3(-0.5f, -0.5f,  0.5f),
        vector3( 0.5f, -0.5f,  0.5f),
        vector3(-0.5f,  0.5f,  0.5f),
        vector3( 0.5f,  0.5f,  0.5f),
    };

    for (int i = 0; i < 8; i++) {
        float3 vertex = cubeVertices[i];

        float4 transformedVertex = vector4(vertex.x, vertex.y, vertex.z, 1.0f);
        transformedVertex = transform * transformedVertex;

        cubeVertices[i] = transformedVertex.xyz;
    }

    unsigned int cubeIndices[][4] = {
        { 0, 4, 6, 2 },
        { 1, 3, 7, 5 },
        { 0, 1, 5, 4 },
        { 2, 6, 7, 3 },
        { 0, 2, 3, 1 },
        { 4, 5, 7, 6 }
    };

    for (unsigned face = 0; face < 6; face++) {
        if (faceMask & (1 << face)) {
            [self addCubeFaceWithCubeVertices:cubeVertices
                                        color:color
                                           i0:cubeIndices[face][0]
                                           i1:cubeIndices[face][1]
                                           i2:cubeIndices[face][2]
                                           i3:cubeIndices[face][3]
                                inwardNormals:inwardNormals];
        }
    }
}

- (MTLAccelerationStructureGeometryDescriptor *)geometryDescriptor {
    // Metal represents each piece of piece of geometry in an acceleration structure using
    // a geometry descriptor. The sample uses a triangle geometry descriptor to represent
    // triangle geometry. Each triangle geometry descriptor can have its own
    // vertex buffer, index buffer, and triangle count. The sample use a single geometry
    // descriptor since it already packed all of the vertex data into a single buffer.
    MTLAccelerationStructureTriangleGeometryDescriptor *descriptor = [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];

    descriptor.vertexBuffer = _vertexPositionBuffer;
    descriptor.vertexStride = sizeof(float3);
    descriptor.triangleCount = _vertices.size() / 3;

    return descriptor;
}

- (NSArray <id <MTLResource>> *)resources {
    // The colors and normals for the vertices.
    return @[ _vertexNormalBuffer, _vertexColorBuffer ];
}

@end

@implementation SphereGeometry {
    id <MTLBuffer> _sphereBuffer;
    id <MTLBuffer> _boundingBoxBuffer;

    std::vector<Sphere> _spheres;
};

- (void)uploadToBuffers {
    MTLResourceOptions options = getManagedBufferStorageMode();

    id <MTLDevice> device = self.device;

    _sphereBuffer = [device newBufferWithLength:_spheres.size() * sizeof(Sphere) options:options];
    _boundingBoxBuffer = [device newBufferWithLength:_spheres.size() * sizeof(BoundingBox) options:options];

    std::vector<BoundingBox> boundingBoxes;

    // Geometry types that use custom intersection functions provide bounding boxes that enclose
    // each primitive. Metal invokes the intersection function whenever a ray potentially intersects
    // one of these bounding boxes.
    for (Sphere & sphere : _spheres) {
        BoundingBox bounds;

        bounds.min.x = sphere.origin.x - sphere.radius;
        bounds.min.y = sphere.origin.y - sphere.radius;
        bounds.min.z = sphere.origin.z - sphere.radius;

        bounds.max.x = sphere.origin.x + sphere.radius;
        bounds.max.y = sphere.origin.y + sphere.radius;
        bounds.max.z = sphere.origin.z + sphere.radius;

        boundingBoxes.push_back(bounds);
    }

    memcpy(_sphereBuffer.contents, &_spheres[0], _sphereBuffer.length);
    memcpy(_boundingBoxBuffer.contents, &boundingBoxes[0], _boundingBoxBuffer.length);

#if !TARGET_OS_IPHONE
    [_sphereBuffer didModifyRange:NSMakeRange(0, _sphereBuffer.length)];
    [_boundingBoxBuffer didModifyRange:NSMakeRange(0, _boundingBoxBuffer.length)];
#endif
}

- (void)clear {
    _spheres.clear();
}

- (void)addSphereWithOrigin:(vector_float3)origin
                     radius:(float)radius
                      color:(vector_float3)color
{
    Sphere sphere;

    sphere.origin = origin;
    sphere.radius = radius;
    sphere.color = color;

    _spheres.push_back(sphere);
}

- (MTLAccelerationStructureGeometryDescriptor *)geometryDescriptor {
    // Metal represents each piece of geometry in an acceleration structure using
    // a geometry descriptor. The sample uses a bounding box geometry descriptor to
    // represent a custom primitive type

    MTLAccelerationStructureBoundingBoxGeometryDescriptor *descriptor = [MTLAccelerationStructureBoundingBoxGeometryDescriptor descriptor];

    descriptor.boundingBoxBuffer = _boundingBoxBuffer;
    descriptor.boundingBoxCount = _spheres.size();

    return descriptor;
}

- (NSArray <id <MTLResource>> *)resources {
    // The sphere intersection function uses the sphere origins and radii to check for
    // intersection with rays
    return @[ _sphereBuffer ];
}

- (NSString *)intersectionFunctionName {
    return @"sphereIntersectionFunction";
}

@end

@implementation GeometryInstance

- (instancetype)initWithGeometry:(Geometry *)geometry
                       transform:(matrix_float4x4)transform
                            mask:(unsigned int)mask
{
    self = [super init];

    if (self) {
        _geometry = geometry;
        _transform = transform;
        _mask = mask;
    }

    return self;
}

@end

@implementation Scene {
    NSMutableArray <Geometry *> *_geometries;
    NSMutableArray <GeometryInstance *> *_instances;

    std::vector<AreaLight> _lights;
}

- (NSArray <Geometry *> *)geometries {
    return _geometries;
}

- (NSUInteger)lightCount {
    return (NSUInteger)_lights.size();
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    self = [super init];

    if (self) {
        _device = device;

        _geometries = [[NSMutableArray alloc] init];
        _instances = [[NSMutableArray alloc] init];

        _cameraPosition = vector3(0.0f, 0.0f, -1.0f);
        _cameraTarget = vector3(0.0f, 0.0f, 0.0f);
        _cameraUp = vector3(0.0f, 1.0f, 0.0f);
    }

    return self;
}

- (void)clear {
    [_geometries removeAllObjects];
    [_instances removeAllObjects];

    _lights.clear();
}

- (void)addGeometry:(Geometry *)mesh {
    [_geometries addObject:mesh];
}

- (void)addInstance:(GeometryInstance *)instance {
    [_instances addObject:instance];
}

- (void)addLight:(AreaLight)light {
    _lights.push_back(light);
}

- (void)uploadToBuffers {
    for (Geometry *geometry in _geometries)
        [geometry uploadToBuffers];

    MTLResourceOptions options = getManagedBufferStorageMode();

    _lightBuffer = [_device newBufferWithLength:_lights.size() * sizeof(AreaLight) options:options];

    memcpy(_lightBuffer.contents, &_lights[0], _lightBuffer.length);

#if !TARGET_OS_IPHONE
    [_lightBuffer didModifyRange:NSMakeRange(0, _lightBuffer.length)];
#endif
}

+ (Scene *)newInstancedCornellBoxSceneWithDevice:(id <MTLDevice>)device
                        useIntersectionFunctions:(BOOL)useIntersectionFunctions
{
    Scene *scene = [[Scene alloc] initWithDevice:device];

    // Set up the camera.
    scene.cameraPosition = vector3(0.0f, 1.0f, 10.0f);
    scene.cameraTarget = vector3(0.0f, 1.0f, 0.0f);
    scene.cameraUp = vector3(0.0f, 1.0f, 0.0f);

    // Create a piece of triangle geometry for the light source.
    TriangleGeometry *lightMesh = [[TriangleGeometry alloc] initWithDevice:device];

    [scene addGeometry:lightMesh];

    matrix_float4x4 transform = matrix4x4_translation(0.0f, 1.0f, 0.0f) * matrix4x4_scale(0.5f, 1.98f, 0.5f);

    // Add the light source.
    [lightMesh addCubeWithFaces:FACE_MASK_POSITIVE_Y
                          color:vector3(1.0f, 1.0f, 1.0f)
                      transform:transform
                  inwardNormals:true];

    // Create a piece of triangle geometry for the Cornell Box.
    TriangleGeometry *geometryMesh = [[TriangleGeometry alloc] initWithDevice:device];

    [scene addGeometry:geometryMesh];

    transform = matrix4x4_translation(0.0f, 1.0f, 0.0f) * matrix4x4_scale(2.0f, 2.0f, 2.0f);

    // Add the top, bottom, and back walls.
    [geometryMesh addCubeWithFaces:FACE_MASK_NEGATIVE_Y | FACE_MASK_POSITIVE_Y | FACE_MASK_NEGATIVE_Z
                             color:vector3(0.725f, 0.71f, 0.68f)
                         transform:transform
                     inwardNormals:true];

    // Add the left wall.
    [geometryMesh addCubeWithFaces:FACE_MASK_NEGATIVE_X
                             color:vector3(0.63f, 0.065f, 0.05f)
                         transform:transform
                     inwardNormals:true];

    // Add the right wall.
    [geometryMesh addCubeWithFaces:FACE_MASK_POSITIVE_X
                             color:vector3(0.14f, 0.45f, 0.091f)
                         transform:transform
                     inwardNormals:true];

    transform = matrix4x4_translation(-0.335f, 0.6f, -0.29f) *
                matrix4x4_rotation(0.3f, vector3(0.0f, 1.0f, 0.0f)) *
                matrix4x4_scale(0.6f, 1.2f, 0.6f);

    // Add the tall box.
    [geometryMesh addCubeWithFaces:FACE_MASK_ALL
                             color:vector3(0.725f, 0.71f, 0.68f)
                         transform:transform
                     inwardNormals:false];

    SphereGeometry *sphereGeometry = nil;

    if (!useIntersectionFunctions) {
        transform = matrix4x4_translation(0.3275f, 0.3f, 0.3725f) *
                    matrix4x4_rotation(-0.3f, vector3(0.0f, 1.0f, 0.0f)) *
                    matrix4x4_scale(0.6f, 0.6f, 0.6f);

        // If the sample isn't using intersection functions, add the short box.
        [geometryMesh addCubeWithFaces:FACE_MASK_ALL
                                 color:vector3(0.725f, 0.71f, 0.68f)
                             transform:transform
                         inwardNormals:false];
    }
    else {
        // Otherwise, create a piece of sphere geometry.
        sphereGeometry = [[SphereGeometry alloc] initWithDevice:device];

        [scene addGeometry:sphereGeometry];

        [sphereGeometry addSphereWithOrigin:vector3(0.3275f, 0.3f, 0.3725f)
                                     radius:0.3f
                                      color:vector3(0.725f, 0.71f, 0.68f)];
    }

    // Create nine instances of the scene.
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            matrix_float4x4 transform = matrix4x4_translation(x * 2.5f, y * 2.5f, 0.0f);

            // Create an instance of the light.
            GeometryInstance *lightMeshInstance = [[GeometryInstance alloc] initWithGeometry:lightMesh
                                                                                   transform:transform
                                                                                        mask:GEOMETRY_MASK_LIGHT];

            [scene addInstance:lightMeshInstance];

            // Create an instance of the Cornell Box.
            GeometryInstance *geometryMeshInstance = [[GeometryInstance alloc] initWithGeometry:geometryMesh
                                                                                      transform:transform
                                                                                           mask:GEOMETRY_MASK_TRIANGLE];

            [scene addInstance:geometryMeshInstance];

            // Create an instance of the sphere.
            if (useIntersectionFunctions) {
                GeometryInstance *sphereGeometryInstance = [[GeometryInstance alloc] initWithGeometry:sphereGeometry
                                                                                            transform:transform
                                                                                                 mask:GEOMETRY_MASK_SPHERE];

                [scene addInstance:sphereGeometryInstance];
            }

            // Add a light for each box.
            AreaLight light;

            light.position = vector3(x * 2.5f, y * 2.5f + 1.98f, 0.0f);
            light.forward = vector3(0.0f, -1.0f, 0.0f);
            light.right = vector3(0.25f, 0.0f, 0.0f);
            light.up = vector3(0.0f, 0.0f, 0.25f);

            float r = (float)rand() / (float)RAND_MAX;
            float g = (float)rand() / (float)RAND_MAX;
            float b = (float)rand() / (float)RAND_MAX;

            light.color = vector3(r * 4.0f, g * 4.0f, b * 4.0f);

            [scene addLight:light];
        }
    }

    return scene;
}

@end
