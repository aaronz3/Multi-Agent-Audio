//
//  PhotoSelector.swift
//  Audio
//
//  Created by Aaron Zheng on 2/2/24.
//

import SwiftUI
import PhotosUI
import SDWebImageSwiftUI

@available(iOS 16.0, *)
struct PhotoSelector: View {
    
    @StateObject var photoSelectorViewModel = PhotoSelectorViewModel(uploadPhotoURL: uploadPhotoUrl, downloadPhotoURL: downloadPhotoUrl)
    @State var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        VStack {
            PhotosPicker("Select a photo", selection: $selectedPhoto)
            
            AnimatedImage(url: photoSelectorViewModel.userImageURL)
                .onFailure { error in
                    // Error
                }
                .customLoopCount(1) // Custom loop count
                .playbackRate(2.0)
                .resizable() // Resizable like SwiftUI.Image, you must use this modifier or the view will use the image bitmap size
                .indicator(SDWebImageActivityIndicator.medium) // Activity Indicator
                .transition(.fade) // Fade Transition
                .scaledToFit()
                .frame(width: 50, height: 50, alignment: .center)
            
        }
        .onChange(of: selectedPhoto) { newImage in
            print("changed")
            Task {
                await photoSelectorViewModel.setLoadedPhotoData(image: newImage!)
                guard let imageAsData = await photoSelectorViewModel.loadImageToData(image: newImage!) else {
                    return
                }
                // within some model
                //                await photoSelectorViewModel.uploadImageData(image: imageAsData, userUUID: <#String#>)
            }
        }
        .task {
            await photoSelectorViewModel.downloadImageData(fromUsers: ["1"])
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    PhotoSelector()
}
