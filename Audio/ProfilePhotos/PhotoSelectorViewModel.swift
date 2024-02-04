//
//  PhotoSelectorViewModel.swift
//  Audio
//
//  Created by Aaron Zheng on 2/3/24.
//

import Foundation
import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
class PhotoSelectorViewModel: ObservableObject {
    
    var loadedPhotoData: Data?
    @Published var avatarImage: Image?
    @Published var userImageURL: URL?
    
    let uploadPhotoURL: URL
    let downloadPhotoURL: URL
    
    init(uploadPhotoURL: URL, downloadPhotoURL: URL) {
        self.uploadPhotoURL = uploadPhotoURL
        self.downloadPhotoURL = downloadPhotoURL
    }
    
    func convertPhotoDataToImage() {
        guard let loadedPhotoData else {
            print("DEBUG: No photo data")
            return
        }
        
        guard let uiimage = UIImage(data: loadedPhotoData) else {
            print("DEBUG: Method could not initialize the image from the specified data.")
            return
        }
        DispatchQueue.main.async {
            self.avatarImage = Image(uiImage: uiimage)
        }
    }

    func loadImageToData(image: PhotosPickerItem) async -> Data? {
        
        guard let loadedImageAsData = try? await image.loadTransferable(type: Data.self) else {
            print("DEBUG: Method could not initialize the image from the specified data.")
            return nil
        }
        
        return loadedImageAsData
    }
    
    func setLoadedPhotoData(image: PhotosPickerItem) async {
        loadedPhotoData = await loadImageToData(image: image)
    }
    
    func downloadImageData(fromUsers: [String]) async {
        var components = URLComponents(url: downloadPhotoURL, resolvingAgainstBaseURL: false)
     
        // Join the user IDs into a comma-separated string
        let userIDsString = fromUsers.joined(separator: ",")
        
        // Add query item for the user IDs
        components?.queryItems = [
            URLQueryItem(name: "User-UUIDs", value: userIDsString)
        ]
        
        // Convert the URLComponents to a URL
        guard let getImageRequestUrl = components?.url else {
            print("DEBUG: Invalid URL")
            return
        }
                
        do {
            let (imageURLdata, _) = try await URLSession.shared.data(from: getImageRequestUrl)
            
            let photoURLs = try JSONDecoder().decode([String].self, from: imageURLdata)
            
            // TODO: Expand this code to receive multiple photo urls

            guard let getImageDataUrl = URL(string: photoURLs[0]) else {
                print("DEBUG: Invalid url")
                return
            }
            
            print("NOTE: Download image data url is \(getImageDataUrl)")
            
            DispatchQueue.main.async {
                self.userImageURL = getImageDataUrl
            }
            
//            let (imageData, _) = try await URLSession.shared.data(from: url)
//            self.loadedPhotoData = imageData
//            self.convertPhotoDataToImage()
            
        } catch {
            print("DEBUG: \(error.localizedDescription)")
        }
    }
    
    func uploadImageData(image: UIImage, userUUID: String) async {
        var request = URLRequest(url: uploadPhotoURL)
        let resizedImage = image.scalePreservingAspectRatio(targetSize: CGSize(width: 100, height: 100))
        
        guard let imageAsJPEGData = resizedImage.jpegData(compressionQuality: 1) else {
            print("DEBUG: Some process in uploading image failed")
            return
        }
        
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Append image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageAsJPEGData)
        body.append("\r\n".data(using: .utf8)!)

        // Append additional text field (e.g., User-UUID)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"User-UUID\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userUUID)\r\n".data(using: .utf8)!) // Assuming "1" is the UUID value

        // End of the multipart/form-data body
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            print("SUCCESS: Sent the image data. Status code:", (response as? HTTPURLResponse)?.statusCode ?? "Nil response")
        
        } catch {
            print("DEBUG: \(error.localizedDescription)")
        }
    }
}

extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}
