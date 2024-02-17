//
//  AuthenticationViewModel.swift
//  AudioGame
//
//  Created by Aaron Zheng on 2/5/24.
//

import Foundation
import GameKit

class AuthenticationViewModel: ObservableObject {
    
    @Published var userID: String?
    @Published var userName: String?
    
    @Published var userData: UserRecord?
    
    let localPlayer = GKLocalPlayer.local
    
    // MARK: Get user uuid from game center
    
    @MainActor
    func authenticateViaGameCenter() async throws {
        try await withCheckedThrowingContinuation { continuation in
            localPlayer.authenticateHandler = { viewController, error in
                if let viewController = viewController,
                   let rootController = UIApplication.shared.windows.first?.rootViewController {
                    // If there's a viewController, present it to complete authentication
                    rootController.present(viewController, animated: true) {
                        self.setUserIDViaGameCenter(localPlayer: self.localPlayer)
                        continuation.resume()
                        
                    }
                } else if self.localPlayer.isAuthenticated {
                    
                    self.setUserIDViaGameCenter(localPlayer: self.localPlayer)
                    continuation.resume()
                    
                } else if let error {
                    // Handle authentication error
                    print("DEBUG: Error in authenticateViaGameCenter. \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func setUserIDViaGameCenter(localPlayer: GKLocalPlayer) {
        print("NOTE: Playerid using game center login is \(localPlayer.playerID)")
        self.userID = localPlayer.playerID
    }
    
    // MARK: Get user data from server
    
    @MainActor
    func getUserData() async throws {
        var components = URLComponents(url: loginUrl, resolvingAgainstBaseURL: true)
        
        guard let uuid = self.userID else {
            throw AuthenticationError.uuidError
        }
        
        components?.queryItems = [
            URLQueryItem(name: "uuid", value: uuid)
        ]
        
        guard let url = components?.url else { 
            throw AuthenticationError.urlQueryError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                try await handleAbnormalGetResponse(data: data, response: response)
                return
            }
            
            let userRecord = try JSONDecoder().decode(UserRecord.self, from: data)
            self.userData = userRecord
            
        } catch {
            print("DEBUG: Error in getUserData \(error.localizedDescription)")
            throw AuthenticationError.getUserDataError
        }
    }
    
    func handleAbnormalGetResponse(data: Data, response: URLResponse) async throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("DEBUG: Unable to convert to http response")
            throw AuthenticationError.httpResponseError
        }
        
        // If the user data is not found
        if httpResponse.statusCode == 404 {
            try await handleNewUserOnboarding(data: data)
        // If there is a server error
        } else if httpResponse.statusCode == 500 {
            print("DEBUG: Server error")
            throw AuthenticationError.serverError
        } else {
            print("DEBUG: Unknown error")
            throw AuthenticationError.unknownServerError
        }
    }
    
    // MARK: Helper functions to help onboard new user

    func handleNewUserOnboarding(data: Data) async throws {
        guard let uuid = self.userID else {
            throw AuthenticationError.uuidError
        }
        
        let jsonResponse = try? JSONDecoder().decode([String: String].self, from: data)
        if let message = jsonResponse?["message"], message == "User data not found" {
            
            // Send default values to server
            let randomName = getRandomUsername()
            try await sendUserData(name: randomName)
            
            // Set default values to userData
            self.userData = UserRecord(userName: randomName, userId: uuid)
            
        } else {
            throw AuthenticationError.unknownFourZeroFourError
        }
    }
    
    func getRandomUsername() -> String {
        let randomIndex = Int.random(in: 0..<usernames.count)
        return usernames[randomIndex]
    }
    
    // MARK: Send user data to server
    
    func sendUserData(name: String) async throws {
        guard let uuid = self.userID else {
            throw AuthenticationError.uuidError
        }
        
        var request = URLRequest(url: loginUrl)

        do {
            // Send the block of user data to the server.
            let body = User(id: uuid, name: name)
            let bodyData = try JSONEncoder().encode(body)
            
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = bodyData
            
        } catch {
            throw AuthenticationError.encodingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("DEBUG: HTTP Request failed")
                throw AuthenticationError.httpResponseError
            }
            
        } catch {
            print("DEBUG: Error in sendUserData \(error.localizedDescription)")
            throw AuthenticationError.postRequestError
        }
    }
    
    enum AuthenticationError : Error {
        case urlQueryError
        case getUserDataError
        case serverError
        case unknownFourZeroFourError
        case unknownServerError
        case uuidError
        case encodingError
        case postRequestError
        case httpResponseError
    }
}

fileprivate let usernames = [
    "YoungestGerm",
    "TowerBomber",
    "LazyPenguin",
    "NinjaSnail",
    "DancingPotato",
    "SneakyCheese",
    "HyperLlama",
    "RocketTurtle",
    "SillyGoose",
    "WackyBanana",
    "FlyingPancake",
    "CrazyNoodle",
    "BouncingFrog",
    "TwirlingAvocado",
    "RapidRabbit",
    "MysticPizza",
    "GigglingDuck",
    "JollyBroccoli",
    "SneezingCarrot",
    "WanderingCloud",
    "ChattyParrot",
    "BubblyDolphin",
    "GlitteryButterfly",
    "ZippyZebra",
    "SnoringCat",
    "WhistlingMoose",
    "DancingDonut",
    "ChewingGumMonster",
    "BubbleBathSinger",
    "GlowingFirefly",
    "JumpingJellybean",
    "TicklishTomato",
    "RollingPea",
    "SkippingStone",
    "HoppingHedgehog",
    "SprintingSpider",
    "MarchingMuffin",
    "LeapingLobster",
    "SwimmingSausage",
    "DriftingDandelion",
    "TwinklingTwix",
    "ScreamingBagel",
    "GallopingGrape",
    "ZoomingZucchini",
    "VibratingViolet",
    "TumblingTeacup",
    "SwirlingStrawberry",
    "SpinningSparrow",
    "RacingRaisin",
    "PouncingPumpkin",
    "NappingNugget",
    "MarvelousMango",
    "LaughingLemon",
    "KickingKiwi",
    "JugglingJalapeno",
    "HidingHazelnut",
    "GleamingGarlic",
    "FlickeringFennel",
    "EnergeticEggplant",
    "DivingDorito",
    "CrunchingCracker",
    "BoundingBacon",
    "BoomingBean",
    "BlazingBaguette",
    "AstonishingApple",
    "ArtisticArtichoke",
    "ArguingAlmond",
    "ApplaudingApricot",
    "AnnoyingAvocado",
    "AmusingAcai",
    "AlertAcorn",
    "AgileAnt",
    "AffectionateAsparagus",
    "AdventurousAardvark",
    "ActiveAnchor",
    "AccurateArrow",
    "BreezyBread",
    "BraveBanoffee",
    "BrightBlueberry",
    "BroadBean",
    "BumpyBiscuit",
    "BustlingBerry",
    "BusyBeetle",
    "ButteryBirch",
    "BuzzingBee",
    "CalmCucumber",
    "CandidCantaloupe",
    "CapableCactus",
    "CarefulCake",
    "CaringCabbage",
    "CharmingCherry",
    "CheerfulCheese",
    "ChilledChili",
    "ChubbyChickpea"
]
