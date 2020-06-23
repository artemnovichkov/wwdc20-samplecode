/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Details about a character, including a name, health level, avatar, and other properties.
*/
import Foundation

struct CharacterDetail: Hashable, Codable, Identifiable {
    let name: String
    let avatar: String
    let healthLevel: Double
    let heroType: String
    let healthRecoveryRatePerHour: Double
    let url: URL
    let level: Int
    let exp: Int
    let bio: String
    
    var id: String {
        name
    }

    static let panda = CharacterDetail(
                name: "Power Panda",
                avatar: "🐼",
                healthLevel: 0.14,
                heroType: "Forest Dweller",
                healthRecoveryRatePerHour: 0.25,
                url: URL(string: "game:///panda")!,
                level: 3,
                exp: 600,
                bio: "Power panda loves eating bamboo shoots and leaves.")
    
    static let egghead = CharacterDetail(
                name: "Egghead",
                avatar: "🦄",
                healthLevel: 0.67,
                heroType: "Free Ranger",
                healthRecoveryRatePerHour: 0.22,
                url: URL(string: "game:///egghead")!,
                level: 5,
                exp: 1000,
                bio: "Egghead comes from the magical land of Eggopolis and flies through the air with their magnificent mane billowing.")

    static let spouty = CharacterDetail(
                name: "Spouty",
                avatar: "🐳",
                healthLevel: 0.83,
                heroType: "Deep Sea Goer",
                healthRecoveryRatePerHour: 0.29,
                url: URL(string: "game:///spouty")!,
                level: 50,
                exp: 20_000,
                bio: "Spouty rises from the depths to bring joy and laugther to everyone. They are best friends with Octo.")

    static let availableCharacters = [panda, egghead, spouty]

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var fullHealthDate: Date {
        let healthNeeded = min(1 - healthLevel, 1)
        let hoursUntilFullHealth = healthNeeded / healthRecoveryRatePerHour
        let minutesUntilFullHealth = (hoursUntilFullHealth * 60)
        let date = Calendar.current.date(byAdding: .minute, value: Int(minutesUntilFullHealth), to: Date())
        
        return date ?? Date()
    }
    
    static func characterFromName(name: String?) -> CharacterDetail {
        return (availableCharacters + remoteCharacters).first(where: { (character) -> Bool in
            return character.name == name
        }) ?? .panda
    }
    
    static func characterFromURL(url: URL) -> CharacterDetail? {
        return (availableCharacters + remoteCharacters).first(where: { (character) -> Bool in
            return character.url == url
        })
    }
    
    static let session = ImageURLProtocol.urlSession()
    
    static func loadLeaderboardData(completion:@escaping ([CharacterDetail]?, Error?) -> Void) {
        // save a faux API to the temporary directory and fetch it
        // in your app you'll fetch it from a real API
        do {
            let responseURL = FileManager.default.temporaryDirectory.appendingPathComponent("userData.json")
            
            try fauxResponse.data(using: .utf8)?.write(to: responseURL)
            session.dataTask(with: responseURL) { (data, response, error) in
                if let playerData = data {
                    do {
                        let characters = try JSONDecoder().decode([CharacterDetail].self, from: playerData)
                                .sorted { $0.healthLevel > $1.healthLevel }
                        completion(characters, error)
                    } catch {
                        completion(nil, error)
                    }
                } else {
                    completion(nil, error)
                }
            }.resume()
        } catch {
            completion(nil, error)
        }
        
    }
}

let fauxResponse =
"""
[
    {
        "name": "Power Panda",
        "avatar": "🐼",
        "healthLevel": 0.99,
        "heroType": "Forest Dweller",
        "healthRecoveryRatePerHour": 0.25
    },
    {
        "name": "Egghead",
        "avatar": "🦄",
        "healthLevel": 0.84,
        "heroType": "Free Ranger",
        "healthRecoveryRatePerHour": 0.22
    },
    {
        "name": "Spouty",
        "avatar": "🐳",
        "healthLevel": 0.72,
        "heroType": "Deep Sea Goer",
        "healthRecoveryRatePerHour": 0.29
    }
]
"""

extension CharacterDetail {
    static let spook = CharacterDetail(
                name: "Mr Spook",
                avatar: "💀",
                healthLevel: 0.14,
                heroType: "Calcium Lover",
                healthRecoveryRatePerHour: 0.25,
                url: URL(string: "game:///spook")!,
                level: 13,
                exp: 2640,
                bio: "Loves dancing, spooking, and playing their trumpet 🎺.")

    static let cake = CharacterDetail(
                name: "Cake",
                avatar: "🎂",
                healthLevel: 0.67,
                heroType: "Literally Cake",
                healthRecoveryRatePerHour: 0.22,
                url: URL(string: "game:///cake")!,
                level: 15,
                exp: 3121,
                bio: """
        • 1 cake mix
        • 2 butter
        • 120 choc. chips
        • 4 large eggs
        • 1 cup semi-sweet chocolate chips
        """)

    static let octo = CharacterDetail(
                name: "Octo",
                avatar: "🐙",
                healthLevel: 0.83,
                heroType: "Etyomology afficianado",
                healthRecoveryRatePerHour: 0.29,
                url: URL(string: "game:///octo")!,
                level: 43,
                exp: 86_463,
                bio: "Can give 8 hugs simultaniously. They are best friends with Spouty.")

    static let remoteCharacters = [spook, cake, octo]
}
