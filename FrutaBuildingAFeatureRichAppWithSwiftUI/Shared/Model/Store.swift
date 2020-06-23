/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model that handles digital purchases like recipes.
*/

import StoreKit

typealias FetchCompletionHandler = (([SKProduct]) -> Void)
typealias PurchaseCompletionHandler = ((SKPaymentTransaction?) -> Void)

// MARK: - Store

class Store: NSObject, ObservableObject {
    @Published var unlockedAllRecipes: Bool = false
    @Published var unlockAllRecipesProduct: SKProduct?
    
    private let allProductIdentifiers = Set([Store.unlockAllRecipesIdentifier])
    
    private var completedPurchases = [String]()
    private var fetchedProducts = [SKProduct]()
    private var productsRequest: SKProductsRequest?
    private var fetchCompletionHandler: FetchCompletionHandler?
    private var purchaseCompletionHandler: PurchaseCompletionHandler?
    
    override init() {
        super.init()
        // Get notified when access to a product is revoked
        startObservingPaymentQueue()
        fetchProducts { [weak self] products in
            guard let self = self else { return }
            self.unlockAllRecipesProduct = products.first(where: { $0.productIdentifier == Store.unlockAllRecipesIdentifier })
        }
    }
}

// MARK: - Store API

extension Store {
    static let unlockAllRecipesIdentifier = "com.example.apple-samplecode.fruta.unlock-recipes"
    
    func product(for identifier: String) -> SKProduct? {
        return fetchedProducts.first(where: { $0.productIdentifier == identifier })
    }
    
    func purchaseProduct(_ product: SKProduct) {
        startObservingPaymentQueue()
        buy(product) { [weak self] transaction in
            guard let self = self,
                  let transaction = transaction else {
                return
            }
            
            // If the purchase was successful and it was for the premium recipes identifiers
            // then publish the unlock change
            if transaction.payment.productIdentifier == Store.unlockAllRecipesIdentifier,
               transaction.transactionState == .purchased {
                self.unlockedAllRecipes = true
            }
        }
    }
}

// MARK: - Private Logic

extension Store {
    private func buy(_ product: SKProduct, completion: @escaping PurchaseCompletionHandler) {
        // Save our completion handler for later
        purchaseCompletionHandler = completion
        
        // Create the payment and add it to the queue
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    private func hasPurchasedIAP(_ identifier: String) -> Bool {
        completedPurchases.contains(identifier)
    }
    
    private func fetchProducts(_ completion: @escaping FetchCompletionHandler) {
        guard self.productsRequest == nil else {
            return
        }
        // Store our completion handler for later
        fetchCompletionHandler = completion
        
        // Create and start this product request
        productsRequest = SKProductsRequest(productIdentifiers: allProductIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    private func startObservingPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
}

// MARK: - SKPAymentTransactionObserver

extension Store: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            var shouldFinishTransaction = false
            switch transaction.transactionState {
            case .purchased, .restored:
                completedPurchases.append(transaction.payment.productIdentifier)
                shouldFinishTransaction = true
            case .failed:
                shouldFinishTransaction = true
            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
            if shouldFinishTransaction {
                SKPaymentQueue.default().finishTransaction(transaction)
                DispatchQueue.main.async {
                    self.purchaseCompletionHandler?(transaction)
                    self.purchaseCompletionHandler = nil
                }
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        completedPurchases.removeAll(where: { productIdentifiers.contains($0) })
        DispatchQueue.main.async {
            if productIdentifiers.contains(Store.unlockAllRecipesIdentifier) {
                self.unlockedAllRecipes = false
            }
        }
    }
}

// MARK: - SKProductsRequestDelegate

extension Store: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let loadedProducts = response.products
        let invalidProducts = response.invalidProductIdentifiers
        
        guard !loadedProducts.isEmpty else {
            var errorMessage = "Could not find any products."
            if !invalidProducts.isEmpty {
                errorMessage = "Invalid products: \(invalidProducts.joined(separator: ", "))"
            }
            print("\(errorMessage)")
            productsRequest = nil
            return
        }
        
        // Cache these for later use
        fetchedProducts = loadedProducts
    
        // Notify anyone waiting on the product load
        DispatchQueue.main.async {
            self.fetchCompletionHandler?(loadedProducts)
            
            // Clean up
            self.fetchCompletionHandler = nil
            self.productsRequest = nil
        }
    }
}
