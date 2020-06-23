/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Container for scene-level physics sync data.
*/

import Foundation
import simd
import SceneKit
import os.log

protocol PhysicsSyncSceneDataDelegate: class {
    func hasNetworkDelayStatusChanged(hasNetworkDelay: Bool)
    func spawnProjectile(objectIndex: Int) -> Projectile
    func despawnProjectile(_ projectile: Projectile)
    
    func playPhysicsSound(objectIndex: Int, soundEvent: CollisionAudioSampler.CollisionEvent)
}

/// - Tag: PhysicsSyncSceneData
class PhysicsSyncSceneData {
    private let lock = NSLock() // need thread protection because add used in main thread, while pack used in render update thread

    // Non-projectile sync
    private var objectList = [GameObject]()
    private var nodeDataList = [PhysicsNodeData]()
    
    // Projectile sync
    private var projectileList = [Projectile]()
    private var projectileDataList = [PhysicsNodeData]()
    
    // Sound sync
    private var soundDataList = [CollisionSoundData]()

    // Put data into queue to help with stutters caused by data packet delays
    private var packetQueue = [PhysicsSyncData]()

    private let maxPacketCount = 8
    private let packetCountToSlowDataUsage = 4
    private var shouldRefillPackets = true
    private var justUpdatedHalfway = false
    private var packetReceived = 0
    
    weak var delegate: PhysicsSyncSceneDataDelegate?
    var isInitialized: Bool { return delegate != nil }
    
    // Network Delay
    private(set) var hasNetworkDelay = false
    private var lastNetworkDelay = TimeInterval(0.0)
    private let networkDelayStatusLifetime = 3.0
    
    // Put up a packet number to make sure that packets are in order
    private var lastPacketNumberRead = 0

    func addObject(_ object: GameObject) {
        guard let data = object.generatePhysicsData() else { return }
        lock.lock() ; defer { lock.unlock() }
        objectList.append(object)
        nodeDataList.append(data)
    }

    func generateData() -> PhysicsSyncData {
        lock.lock() ; defer { lock.unlock() }
        // Update Data of normal nodes
        for index in 0..<objectList.count {
            if let data = objectList[index].generatePhysicsData() {
                nodeDataList[index] = data
            }
        }

        // Update Data of projectiles in the pool
        for (index, projectile) in projectileList.enumerated() {
            if let data = projectile.generatePhysicsData() {
                projectileDataList[index] = data
            }
        }

        // Packet number is used to determined the order of sync data.
        // Because Multipeer Connectivity does not guarantee the order of packet delivery,
        // we use the packet number to discard out of order packets.
        let packetNumber = GameTime.frameCount % PhysicsSyncData.maxPacketNumber
        let packet = PhysicsSyncData(packetNumber: packetNumber, nodeData: nodeDataList,
                                     projectileData: projectileDataList, soundData: soundDataList)
        
        // Clear sound data since it only needs to be played once
        soundDataList.removeAll()
        
        return packet
    }
    
    func updateFromReceivedData() {
        lock.lock() ; defer { lock.unlock() }
        discardOutOfOrderData()
        
        if shouldRefillPackets {
            if packetQueue.count >= maxPacketCount {
                shouldRefillPackets = false
            }
            return
        }
        
        if let oldestData = packetQueue.first {
            // Case when running out of data: Use one packet for two frames
            if justUpdatedHalfway {
                updateObjectsFromData(isHalfway: false)
                justUpdatedHalfway = false
            } else if packetQueue.count <= packetCountToSlowDataUsage {
                if !justUpdatedHalfway {
                    apply(packet: oldestData)
                    packetQueue.removeFirst()

                    updateObjectsFromData(isHalfway: true)
                    justUpdatedHalfway = true
                }
                
            // Case when enough data: Use one packet per frame as usual
            } else {
                apply(packet: oldestData)
                packetQueue.removeFirst()
            }
            
        } else {
            shouldRefillPackets = true
            os_log(.info, "out of packets")
            
            // Update network delay status used to display in sceneViewController
            if !hasNetworkDelay {
                delegate?.hasNetworkDelayStatusChanged(hasNetworkDelay: true)
            }
            hasNetworkDelay = true
            lastNetworkDelay = GameTime.time
        }
        
        while packetQueue.count > maxPacketCount {
            packetQueue.removeFirst()
        }
        
        // Remove networkDelay status after time passsed without a delay
        if hasNetworkDelay && GameTime.time - lastNetworkDelay > networkDelayStatusLifetime {
            delegate?.hasNetworkDelayStatusChanged(hasNetworkDelay: false)
            hasNetworkDelay = false
        }
    }

    func receive(packet: PhysicsSyncData) {
        lock.lock(); defer { lock.unlock() }
        packetQueue.append(packet)
        packetReceived += 1
    }

    private func apply(packet: PhysicsSyncData) {
        lastPacketNumberRead = packet.packetNumber
        nodeDataList = packet.nodeData
        projectileDataList = packet.projectileData
        soundDataList = packet.soundData
        
        // Play sound right away and clear the list
        guard let delegate = delegate else { fatalError("No Delegate") }
        for soundData in soundDataList {
            delegate.playPhysicsSound(objectIndex: soundData.gameObjectIndex, soundEvent: soundData.soundEvent)
        }
        soundDataList.removeAll()

        updateObjectsFromData(isHalfway: false)
    }

    private func updateObjectsFromData(isHalfway: Bool) {
        // Update Nodes
        let objectCount = min(objectList.count, nodeDataList.count)
        for index in 0..<objectCount where nodeDataList[index].isAlive {
            objectList[index].apply(physicsData: nodeDataList[index], isHalfway: isHalfway)
        }
        
        guard let delegate = delegate else { fatalError("No delegate") }
        
        for arrayIndex in 0..<projectileList.count {
            var projectile = projectileList[arrayIndex]
            let nodeData = projectileDataList[arrayIndex]

            // If the projectile must be spawned, spawn it.
            if nodeData.isAlive {
                // Spawn the projectile if it is exists on the other side, but not here
                if !projectile.isAlive {
                    projectile = delegate.spawnProjectile(objectIndex: projectile.index)
                    projectile.team = nodeData.team
                    projectileList[arrayIndex] = projectile
                }

                projectile.apply(physicsData: nodeData, isHalfway: isHalfway)
            } else {
                // Despawn the projectile if it was despawned on the other side
                if projectile.isAlive {
                    delegate.despawnProjectile(projectile)
                }
            }
        }
        
    }

    private func discardOutOfOrderData() {
        // Discard data that are out of order
        while let oldestData = packetQueue.first {
            let packetNumber = oldestData.packetNumber
            // If packet number of more than last packet number, then it is in order.
            // For the edge case where packet number resets to 0 again, we test if the difference is more than half the max packet number.
            if packetNumber > lastPacketNumberRead ||
                ((lastPacketNumberRead - packetNumber) > PhysicsSyncData.halfMaxPacketNumber) {
                break
            } else {
                os_log(.error, "Packet out of order")
                packetQueue.removeFirst()
            }
        }
    }

    // MARK: - Projectile Sync
    
    func addProjectile(_ projectile: Projectile) {
        guard let data = projectile.generatePhysicsData() else { return }
        lock.lock() ; defer { lock.unlock() }
        projectileList.append(projectile)
        projectileDataList.append(data)
    }

    func replaceProjectile(_ projectile: Projectile) {
        lock.lock() ; defer { lock.unlock() }
        for (arrayIndex, oldProjectile) in projectileList.enumerated() where oldProjectile.index == projectile.index {
            projectileList[arrayIndex] = projectile
            return
        }
        fatalError("Cannot find the projectile to replace \(projectile.index)")
    }
    
    // MARK: - Sound Sync
    
    func addSound(gameObjectIndex: Int, soundEvent: CollisionAudioSampler.CollisionEvent) {
        soundDataList.append(CollisionSoundData(gameObjectIndex: gameObjectIndex, soundEvent: soundEvent))
    }
    
}
