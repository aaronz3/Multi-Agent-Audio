//
//  StoreView.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/13/24.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        VStack {
            HStack {
                Button("", systemImage: "chevron.backward") {
                    storeManager.products = []
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            List(storeManager.products, id: \.self) { product in
                VStack(alignment: .leading) {
                    
                    Text(product.localizedTitle + " " + product.displayPrice)
                        .font(.headline)
                    Text(product.localizedDescription)
                        .font(.subheadline)
                    Button {
                        storeManager.purchase(product)
                    } label: {
                        Image("Banana-Gift")
                            .resizable()
                            .frame(width: 200, height: 200)

                    }
                }
            }
            .padding(20)
        }
        .padding(20)
    }
}

#Preview {
    StoreView()
}
