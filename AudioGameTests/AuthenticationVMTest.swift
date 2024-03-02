//
//  AuthenticationVMTest.swift
//  AudioGameTests
//
//  Created by Aaron Zheng on 2/17/24.
//

import XCTest
@testable import AudioGame

// MARK: Internet connection is required to run this test suite

final class AuthenticationVMTest: XCTestCase {
    
    var authVM: AuthenticationViewModel! = nil
    
    override func setUp() async throws {
        authVM = AuthenticationViewModel()
    }
    
    // Test setting user data in database for new user
//    func testSetUserDataForNewUser() async throws {
//        let userID = "randomTestUserName:" + UUID().uuidString
//        
//        try await authVM.getUserData()
//        
//        XCTAssertNotNil(authVM.userData?.userName)
//        XCTAssertTrue(authVM.userData?.userId == userID)
//    }
    
    // Test setting database for new user
//    func testGettingUserDataForExistingUser() async throws {
//        let userID = "randomUser:C@*JAbh10(AK"
//        let userName = "RN1"
//                
//        try await authVM.getUserData()
//        
//        XCTAssertTrue(authVM.userData?.userName == userName)
//        XCTAssertTrue(authVM.userData?.userId == userID)
//    }
    
//    func testServerDown() async throws {
//        let userID = "randomUser:C@*JAbh10(AK"
//        
//        authVM.userID = userID
//        
//        do {
//            try await authVM.getUserData()
//        } catch AuthenticationError.serverError {
//            
//        } catch {
//            // Handle all other errors
//            print("DEBUG:", error.localizedDescription)
//        }
//        
//    }
    
    

}
