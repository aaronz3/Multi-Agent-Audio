//
//  AuthenticationViewModel.swift
//  AudioGame
//
//  Created by Aaron Zheng on 2/5/24.
//

import Foundation
import GameKit

class AuthenticationViewModel: ObservableObject {
    
    @Published var userName: String?
    @Published var userData: UserRecord?
    
    private var isContinuationCalled = false
    
    
    // MARK: Get user uuid from game center
    @MainActor
    func authenticateViaGameCenter() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // State to track if continuation has already been called

            GKLocalPlayer.local.authenticateHandler = { viewController, error in
                // Prevent multiple resumes
                guard !self.isContinuationCalled else { return }

                if let error = error {
                    self.isContinuationCalled = true
                    continuation.resume(throwing: error)
                    
                    // If the user has not logged in before present the view controller
                } else if let viewController = viewController,
                          let rootController = UIApplication.shared.windows.first?.rootViewController {
                    self.isContinuationCalled = true
                    rootController.present(viewController, animated: true) {
                        
                        // Check to see if the player id has been set after the presentation. If so set the userID.
                        // TODO: Need to test this code. Firstly is GKLocalPlayer.local.playerID always non nil after successfully completing the presentation. If it is not completed successfully, is the GKLocalPlayer.local.playerID always empty.
                        if GKLocalPlayer.local.playerID != "" {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: AuthenticationError.uuidError)
                        }
                    }
                    
                    // If the user is already authenticated
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.isContinuationCalled = true
                    continuation.resume()
                    
                    // If none of the conditions are met and it hasn't been called yet, consider it an unknown error.
                } else {
                    self.isContinuationCalled = true
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: Get user data from server
    
    @MainActor
    func getUserData() async throws {
        var components = URLComponents(url: loginUrl, resolvingAgainstBaseURL: true)
        
        components?.queryItems = [
            URLQueryItem(name: "uuid", value: GKLocalPlayer.local.playerID)
        ]
        
        guard let url = components?.url else {
            throw AuthenticationError.urlQueryError
        }
        
        let (data, response) = try await getRequest(url: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            try await handleAbnormalGetResponse(data: data, response: response)
            return
        }
                
        do {
            self.userData = try JSONDecoder().decode(UserRecord.self, from: data)
            
        } catch {
            print("DEBUG: Error in decoding user data \(error.localizedDescription)")
            throw AuthenticationError.decodingError
        }
    }
    
    func getRequest(url: URL) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(from: url)
    }
    
    func handleAbnormalGetResponse(data: Data, response: URLResponse) async throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("DEBUG: Unable to convert to http response")
            throw AuthenticationError.httpResponseError
        }
        
        // If the user data is not found, create a new user
        if httpResponse.statusCode == 404 {
            try await handleNewUserOnboarding(data: data)
            // If there is a server error
        } else if httpResponse.statusCode == 500 {
            print("DEBUG: Server error")
            throw AuthenticationError.serverError
        } else {
            print("DEBUG: Unknown error. \(httpResponse.statusCode)")
            throw AuthenticationError.unknownServerError
        }
    }
    
    // MARK: Helper functions to help onboard new user
    
    @MainActor
    func handleNewUserOnboarding(data: Data) async throws {

        let jsonResponse = try JSONDecoder().decode([String: String].self, from: data)
        
        if let message = jsonResponse["message"], message == "User data not found" {
            
            // Set a random username for a user and send it to the server
            let randomName = getRandomUsername()
            try await sendUserData(name: randomName)
            
            // Set default values to userData
            self.userData = UserRecord(userName: randomName, userId: GKLocalPlayer.local.playerID)
            
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
        var data = User(id: GKLocalPlayer.local.playerID, name: name)
        try await postRequest(data: data, endpoint: loginUrl)
    }
    
    func sendUserStatus(status: String) async throws {
        var data = UserStatus(id: GKLocalPlayer.local.playerID, status: status)
        try await postRequest(data: data, endpoint: userStatusUrl)
    }
    
    func postRequest(data: Encodable, endpoint: URL) async throws {
        var request = URLRequest(url: endpoint)
        
        do {
            // Send the block of user data to the server.
            let bodyData = try JSONEncoder().encode(data)
            
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = bodyData
            
        } catch {
            throw AuthenticationError.encodingError
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("DEBUG: HTTP Request failed")
                throw AuthenticationError.httpResponseError
            }
            
        } catch {
            print("DEBUG: Error in postRequest \(error.localizedDescription)")
            throw AuthenticationError.postRequestError
        }
    }
}

enum AuthenticationError : Error {
    case urlQueryError
    case serverError
    case unknownFourZeroFourError
    case unknownServerError
    case uuidError
    case decodingError
    case encodingError
    case postRequestError
    case httpResponseError
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
