//
//  DatabaseTest.swift
//  AudioTests
//
//  Created by Aaron Zheng on 2/2/24.
//

import XCTest
@testable import AudioGame

final class DatabaseTest: XCTestCase {

//    var currentUserModel: CurrentUserModel! = nil
    var photoSelectorViewModel: PhotoSelectorViewModel! = nil
    
    override func setUp() {
//        let userIDUrl = URL(string: "http://43.203.40.34:3000/user-data")!
        let uploadPhotoUrl = URL(string: "http://43.203.40.34:3000/upload-profile-photo")!
        let downloadPhotoUrl = URL(string: "http://43.203.40.34:3000/download-profile-photo")!

//        currentUserModel = CurrentUserModel(url: userIDUrl)
        photoSelectorViewModel = PhotoSelectorViewModel(uploadPhotoURL: uploadPhotoUrl, downloadPhotoURL: downloadPhotoUrl)
    }
    
    override func tearDown() {
//        currentUserModel = nil
        photoSelectorViewModel = nil
    }
    
    func testUploadImageData() async {
        
        await photoSelectorViewModel.uploadImageData(image: UIImage(systemName: "sun.min")!, userUUID: "1")

    }

    func testDownloadImageData() async {
        
        await photoSelectorViewModel.downloadImageData(fromUsers: ["1"])

    }

}
