//
//  StoreManager.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/13/24.
//

import Foundation
import StoreKit

class StoreManager: NSObject, ObservableObject {
    
    @Published var products: [SKProduct] = []
    private var productsRequest: SKProductsRequest?

    var canMakePurchases: Bool {
        SKPaymentQueue.canMakePayments()
    }

    func loadProducts() {
        let productIdentifiers: Set = ["BananaGift"]
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }

    func purchase(_ product: SKProduct) {
        // Add self (which conforms to SKPaymentTransactionObserver) to the payment queue
        SKPaymentQueue.default().add(self)
        
        // Add a payment to the payment queue
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
}

extension StoreManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
}

extension StoreManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing: print("Purchasing"); break
            // Don’t block the UI. Allow the user to continue using the app.
            case .deferred: print("Deferred")
            // The purchase was successful.
            case .purchased: deliverProduct(transaction: transaction)
            // The transaction failed.
            case .failed: handleFailedTransaction(transaction: transaction)
            // There are restored products.
            case .restored: restorePurchasedProduct(transaction: transaction)
            @unknown default: print("Unknown payment transaction")
            }
        }
    }

    func deliverProduct(transaction: SKPaymentTransaction) {
        // Implement product delivery logic here
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    func handleFailedTransaction(transaction: SKPaymentTransaction) {
        // Handle failed transaction, possibly by showing an error message to the user.
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    func restorePurchasedProduct(transaction: SKPaymentTransaction) {
        // Implement restore logic here
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

extension SKProduct {
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? ""
    }
}
