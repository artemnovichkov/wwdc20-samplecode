/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Creature Entity Video Material
*/

import RealityKit

extension CreatureEntity {

    func installVideoMaterial() {
        videoMaterialWrapper = VideoMaterialWrapper("AnimatedCircuits", withExtension: ".mp4")
        guard let videoMaterialWrapper = self.videoMaterialWrapper,
        let material = videoMaterialWrapper.material else { return }
        installMaterial(material)
    }

    func resetVideoMaterial() {
        videoMaterialWrapper?.reset()
    }

    private func installMaterial(_ material: Material, on entity: Entity?, materialIndex: Int) -> Int {
        guard let entity = entity else { return 0 }
        let (success, _) = entity.installMaterial(material, modelEntityName: "skinJoints_grp",
                                                  materialIndex: materialIndex)
        return success ? 1 : 0
    }

    public func installMaterial(_ material: Material) {
        var materialUpdatedCount = 0
        materialUpdatedCount += installMaterial(material, on: entranceAnim, materialIndex: 0)
        materialUpdatedCount += installMaterial(material, on: walkAnim, materialIndex: 0)
        materialUpdatedCount += installMaterial(material, on: idleAnim, materialIndex: 0)
        materialUpdatedCount += installMaterial(material, on: calmIdleAnim, materialIndex: 0)
        materialUpdatedCount += installMaterial(material, on: flutterAnim, materialIndex: 0)

        log.debug("%d materials replaced", materialUpdatedCount)
    }

}
