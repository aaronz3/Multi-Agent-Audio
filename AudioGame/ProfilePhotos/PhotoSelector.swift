//
//  PhotoSelector.swift
//  Audio
//
//  Created by Aaron Zheng on 2/2/24.
//

import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct PhotoSelector: View {
    
    @StateObject var photoSelectorViewModel = PhotoSelectorViewModel(uploadPhotoURL: uploadPhotoUrl, downloadPhotoURL: downloadPhotoUrl)
    @State var selectedPhoto: PhotosPickerItem?
    @State var showPhoto: Bool = false
    
    var body: some View {
        VStack {
            PhotosPicker("Select a photo", selection: $selectedPhoto)
            
            Button("Refresh & show photo") {
                Task {
                    await photoSelectorViewModel.downloadImageData(fromUsers: ["2"])
                    showPhoto = true
                }
            }
            
            if showPhoto {
                AsyncImage(url: photoSelectorViewModel.userImageURL, content: { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300, alignment: .center)
                }, placeholder: {
                    ProgressView()
                })
            }
            
        }
        .onChange(of: selectedPhoto) { newImage in
            Task {
                guard let imageAsUIImage = await photoSelectorViewModel.loadImageToUIImage(image: newImage!) else {
                    return
                }
                
                await photoSelectorViewModel.uploadImageData(image: imageAsUIImage, userUUID: "2")
            }
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    PhotoSelector()
}
