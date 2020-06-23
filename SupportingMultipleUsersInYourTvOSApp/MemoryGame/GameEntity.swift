/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A set of utilities for manipulating GameEntity objects.
*/

import CoreData

extension GameEntity: Identifiable {
    static func currentGamesFetchRequest() -> NSFetchRequest<GameEntity> {
        let request = GameEntity.fetchRequest() as NSFetchRequest<GameEntity>

        request.predicate = NSPredicate(format: "SUBQUERY(tiles, $t, $t.flipped != YES).@count > 0")

        request.sortDescriptors = [
            NSSortDescriptor(key: "createdDate", ascending: false)
        ]

        return request
    }

    static func bestGamesFetchRequest() -> NSFetchRequest<GameEntity> {
        let request = GameEntity.fetchRequest() as NSFetchRequest<GameEntity>

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "duration > 0"),
            NSPredicate(format: "SUBQUERY(tiles, $t, $t.flipped != YES).@count == 0")
        ])

        request.sortDescriptors = [
            NSSortDescriptor(key: "duration", ascending: true)
        ]

        return request
    }

    static func deleteCurrentGamesRequest() -> NSBatchDeleteRequest {
        NSBatchDeleteRequest(
            fetchRequest: unsafeDowncast(currentGamesFetchRequest(), to: NSFetchRequest.self)
        )
    }

    public override func willSave() {
        if isDeleted {
            return
        }

        if createdDate == nil {
            createdDate = Date()
        }
    }

    func touch() {
        if let createdDate = createdDate {
            duration = Date().timeIntervalSince(createdDate)
        } else {
            setValue(nil, forKey: "duration")
        }
    }
}
