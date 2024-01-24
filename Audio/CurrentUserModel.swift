//
//  CurrentUserModel.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import Foundation


class CurrentUserModel {
    
    static func setAndReturnUsername() -> String {
        let username = UUID().uuidString
        UserDefaults.standard.set(username, forKey: "username")
        return username
    }
    
    static func loadUsername() -> String {
        // Load the saved username from UserDefaults
        if let savedUsername = UserDefaults.standard.string(forKey: "username") {
            return savedUsername
        } else {
            return setAndReturnUsername()
        }
    }
}
