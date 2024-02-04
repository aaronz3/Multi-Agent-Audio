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
    
    @Published var userImageURL: URL?
    
    let uploadPhotoURL: URL
    let downloadPhotoURL: URL
    
    init(uploadPhotoURL: URL, downloadPhotoURL: URL) {
        self.uploadPhotoURL = uploadPhotoURL
        self.downloadPhotoURL = downloadPhotoURL
    }
    
    func loadImageToUIImage(image: PhotosPickerItem) async -> UIImage? {
        
        guard let loadedImageAsData = try? await image.loadTransferable(type: Data.self) else {
            print("DEBUG: Method could not initialize the image from the specified data.")
            return nil
        }
        
        return UIImage(data: loadedImageAsData)
    }
    
    // Sets userImageURL to the url obtained from getObjectUrl
    func downloadImageData(fromUsers: [String]) async {
        var components = URLComponents(url: downloadPhotoURL, resolvingAgainstBaseURL: false)
     
        // Join the user IDs into a comma-separated string
        let userIDsString = fromUsers.joined(separator: ",")
        
        // Add query item for the user IDs
        components?.queryItems = [
            URLQueryItem(name: "User-UUIDs", value: userIDsString)
        ]
        
        // Convert the URLComponents
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
                        
            DispatchQueue.main.async {
                self.userImageURL = getImageDataUrl
            }
            
        } catch {
            print("DEBUG: \(error.localizedDescription)")
        }
    }
    
    func uploadImageData(image: UIImage, userUUID: String) async {
        var request = URLRequest(url: uploadPhotoURL)
        let resizedImage = image.scalePreservingAspectRatio(targetSize: CGSize(width: 200, height: 200))
        
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
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageAsJPEGData)
        body.append("\r\n".data(using: .utf8)!)

        // Append additional text field (e.g., User-UUID)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"User-UUID\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userUUID)\r\n".data(using: .utf8)!)

        // End of the multipart/form-data body
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            print("SUCCESS: Sent the image data \(body). Status code:", (response as? HTTPURLResponse)?.statusCode ?? "Nil response")
        
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
