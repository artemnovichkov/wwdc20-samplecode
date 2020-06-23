/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension for updating SCNNode geometry and materials after loading.
*/

import Foundation
import SceneKit
import os.log

// helpers for updating geometry and materials after loading
extension SCNNode {
    
    func fixMaterials() {
        // walk down the scenegraph and update all children
        fixNormalMaps()
    
        // establish paint colors
        copyGeometryForPaintColors()
        setPaintColors()
    }
    
    private func fixNormalMap(_ geometry: SCNGeometry) {
        for material in geometry.materials {
            let prop = material.normal
            // astc needs gggr and .ag to compress to L+A,
            //   but will compress rg01 to RGB single plane (less quality)
            // bc/eac/explicit/no compression use rg01 and .rg
            //   rg01 is easier to see and edit in texture editors
            
            // set the normal to RED | GREEN (rg01 compression)
            // uses single plane on ASTC, dual on BC5/EAC_RG11/Explicit
            prop.textureComponents = [.red, .green]
            
            // set the normal to ALPHA | GREEN (gggr compression)
            // uses dual plane for ASTC, BC3nm
            // prop.textureComponents = [.alpha, .green]
        }
    }

    // fix the normal map reconstruction on scn files for compressed textures
    func fixNormalMaps() {
        if let geometry = geometry {
            fixNormalMap(geometry)
    
            // these will often just have the same material applied
            if let lods = geometry.levelsOfDetail {
                for lod in lods {
                    if let geometry = lod.geometry {
                        fixNormalMap(geometry)
                    }
                }
            }
        }
        
        for child in childNodes {
            child.fixNormalMaps()
        }
    }
    
    // must copy geometry and materials to set unique data on both
    // here we only want
    static func copyGeometryAndMaterials(_ geometry: SCNGeometry) -> SCNGeometry {
        if let geometryCopy = geometry.copy() as? SCNGeometry {
            var materialsCopy = [SCNMaterial]()
            for material in geometryCopy.materials {
                if let materialCopy = material.copy() as? SCNMaterial {
                    materialsCopy.append(materialCopy)
                }
            }
            geometryCopy.materials = materialsCopy
            return geometryCopy
        }
        return geometry
    }
    
    func copyGeometryAndMaterials() {
        // this copies the material, but not the lod
        if let geometry = self.geometry {
            self.geometry = SCNNode.copyGeometryAndMaterials(geometry)
            
            if let lods = geometry.levelsOfDetail {
                var lodsNew = [SCNLevelOfDetail]()
                for lod in lods {
                    if let lodGeometry = lod.geometry {
                        let lodGeometryCopy = SCNNode.copyGeometryAndMaterials(lodGeometry)
                        
                        lodsNew.append(SCNLevelOfDetail(geometry: lodGeometryCopy, screenSpaceRadius: lod.screenSpaceRadius))
                    }
                }
                geometry.levelsOfDetail = lodsNew
            }
        }
        
        for child in childNodes {
            child.copyGeometryAndMaterials()
        }
    }
    
    // for lod, set the radius based on a percentage of the screen size
    static func computeScreenSpaceRadius(screenSpacePercent: Float) -> Float {
        // Needs adjusted for screen size, and original bounds of shape
        // eventually also look at physical size of device
        let screenSize = UIScreen.main.nativeBounds // main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let minDimension = Float(min(screenWidth, screenHeight))
        
        // work in percentages of screen area for low/high-res devices
        // 10% of screen size
        let screenSpaceDiameter = screenSpacePercent * minDimension
        return screenSpaceDiameter * 0.5
    }
    
    func fixLevelsOfDetail(screenSpaceRadius: Float, showLOD: Bool) {
        // find the boundingRadius of the node, and scale to that
        if let geometry = geometry, let lods = geometry.levelsOfDetail {
            var lodsNew = [SCNLevelOfDetail]()
            for lod in lods {
                if let lodGeometry = lod.geometry {
                    if showLOD {
                        // visualize the lod
                        let lodGeometryCopy = SCNNode.copyGeometryAndMaterials(lodGeometry)
                        
                        // override the emission
                        // this is not removed currently
                        for material in lodGeometryCopy.materials {
                            material.emission.contents = UIColor.red
                        }
                        
                        lodsNew.append(SCNLevelOfDetail(geometry: lodGeometryCopy, screenSpaceRadius: CGFloat(screenSpaceRadius)))
                    } else {
                        lodsNew.append(SCNLevelOfDetail(geometry: lodGeometry, screenSpaceRadius: CGFloat(screenSpaceRadius)))
                    }
                }
            }
            geometry.levelsOfDetail = lodsNew
        }
        
        for child in childNodes {
            child.fixLevelsOfDetail(screenSpaceRadius: screenSpaceRadius, showLOD: showLOD)
        }
    }
    
    // We load all nodes as references which means they share the same
    // geometry and materials.  For team colors, we need to set geometry overrides
    // and so need unique geometry with shadable overrides for each node created.

    func copyGeometryForPaintColors() {
        
        // neutral blocks also need to be tinted
        
        if let geometry = geometry, let name = name {

            // does this copy the LOD as well ?
            if let geometryCopy = geometry.copy() as? SCNGeometry {
                setupPaintColorMask(geometryCopy, name: name)
            
                // this may already done by the copy() above, but just be safe
                if let lods = geometry.levelsOfDetail {
                    var lodsNew = [SCNLevelOfDetail]()
                    for lod in lods {
                        if let geometry = lod.geometry {
                            if lod.screenSpaceRadius > 0 {
                                if let lodGeometryCopy = geometry.copy() as? SCNGeometry {
                                    setupPaintColorMask(lodGeometryCopy, name: name)
                                    lodsNew.append(SCNLevelOfDetail(
                                        geometry: lodGeometryCopy,
                                        screenSpaceRadius: lod.screenSpaceRadius))
                                }
                            } else {
                                if let lodGeometryCopy = geometry.copy() as? SCNGeometry {
                                    setupPaintColorMask(lodGeometryCopy, name: name)
                                    lodsNew.append(SCNLevelOfDetail(
                                        geometry: lodGeometryCopy,
                                        worldSpaceDistance: lod.worldSpaceDistance))
                                }
                            }
                        }
                    }
                    geometryCopy.levelsOfDetail = lodsNew
                }
                
                // set the new geometry and LOD
                self.geometry = geometryCopy
            }
        }
        
        for child in childNodes {
            child.copyGeometryForPaintColors()
        }
    }
    
    static let paintMaskColorKey = "paintMaskColor"
    
    // recursively set team color into any nodes that use it
    func setPaintColors() {
        if let geometry = geometry {
            // paintColor can be UIColor or SCNVector4
            let paintColor = team.color
            
            if geometry.hasUniform(SCNNode.paintMaskColorKey) {
                geometry.setColor(SCNNode.paintMaskColorKey, paintColor)
            }
            
            if let lods = geometry.levelsOfDetail {
                for lod in lods {
                    if let lodGeometry = lod.geometry, lodGeometry.hasUniform(SCNNode.paintMaskColorKey) {
                        lodGeometry.setColor(SCNNode.paintMaskColorKey, paintColor)
                    }
                }
            }
        }
        
        for child in childNodes {
            child.setPaintColors()
        }
    }
    
    func setPaintColors(team: Team) {
        if let geometry = geometry {
            // paintColor can be UIColor or SCNVector4
            let paintColor = team.color
            
            if geometry.hasUniform(SCNNode.paintMaskColorKey) {
                geometry.setColor(SCNNode.paintMaskColorKey, paintColor)
            }
            
            if let lods = geometry.levelsOfDetail {
                for lod in lods {
                    if let lodGeometry = lod.geometry, lodGeometry.hasUniform(SCNNode.paintMaskColorKey) {
                        lodGeometry.setColor(SCNNode.paintMaskColorKey, paintColor)
                    }
                }
            }
        }
        
        for child in childNodes {
            child.setPaintColors(team: team)
        }
    }
    
    // until pipeline is ready, use a map of material name to paintMask texture
    static let paintColorMaskTextures = [
        "geom_block_boxB": "block_boxBMaterial_PaintMask",
        "geom_block_cylinderC": "block_cylinderCMaterial_Paintmask",
        "geom_block_halfCylinderA": "block_halfCylinderAMaterial_Paintmask",
        "flag_flagA": "flag_flagAMaterial_PaintMask",
        "catapultBase": "catapultBase_PaintMask",
        "catapultProngs": "catapultBase_PaintMask",
        "catapultStrap": "catapultSling_PaintMask",
        "catapultStrapInactive": "catapultSling_PaintMask",

        "V": "letters_lettersMaterial_PaintMask",
        "I": "letters_lettersMaterial_PaintMask",
        "C": "letters_lettersMaterial_PaintMask",
        "T": "letters_lettersMaterial_PaintMask",
        "O": "letters_lettersMaterial_PaintMask",
        "R": "letters_lettersMaterial_PaintMask",
        "Y": "letters_lettersMaterial_PaintMask",
        "ExclamationPoint": "letters_lettersMaterial_PaintMask"
    ]
    
    func setupPaintColorMask(_ geometry: SCNGeometry, name: String) {
        // if we've already set it up, don't do it again
        if geometry.value(forKey: SCNNode.paintMaskColorKey) != nil {
            return
        }
        
        guard let paintMask = SCNNode.paintColorMaskTextures[name] else { return }
        
        // all textures are absolute paths from the app folder
        let texturePath = "gameassets.scnassets/textures/\(paintMask).ktx"
        
        if name.contains("catapult") {
            os_log(.debug, "visited %s for texture", name)
        }
        
        let surfaceScript = """
            #pragma arguments

            texture2d<float> paintMaskTexture;
            //sampler paintMaskSampler;
            float4 paintMaskColor;

            #pragma body

            // 0 is use diffuse texture.rgb, 1 is use paintMaskColor.rgb
            float paintMaskSelector = paintMaskTexture.sample(
                sampler(filter::linear), // paintMaskSampler,
                _surface.diffuseTexcoord.xy).r;

            _surface.diffuse.rgb = mix(_surface.diffuse.rgb, paintMaskColor.rgb, paintMaskSelector);
            """
        
        geometry.shaderModifiers = [.surface: surfaceScript]
        
        // mask prop
        let prop = SCNMaterialProperty(contents: texturePath)
        prop.minificationFilter = .linear
        prop.magnificationFilter = .nearest
        prop.mipFilter = .nearest
        prop.maxAnisotropy = 1
        
        // set the uniforms, these will be overridden in the runtime
        geometry.setTexture("paintMaskTexture", prop)
        geometry.setSIMD4Float(SCNNode.paintMaskColorKey, SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
    }
}

