/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model representing all of the data the app needs to display in its interface.
*/

import AuthenticationServices

// MARK: - FrutaModel

class FrutaModel: ObservableObject {
    @Published private(set) var order: Order?
    @Published private(set) var account: Account?
    @Published private(set) var favoriteSmoothieIDs = Set<Smoothie.ID>()
    @Published private(set) var selectedSmoothieID: Smoothie.ID?
    @Published var applePayAllowed = true
    
    var hasAccount: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return userCredential != nil && account != nil
        #endif
    }
    
    let defaults = UserDefaults(suiteName: "group.example.fruta")
    
    private var userCredential: String? {
        get { defaults?.string(forKey: "UserCredential") }
        set { defaults?.setValue(newValue, forKey: "UserCredential") }
    }
    
    init() {
        guard let user = userCredential else { return }
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: user) { state, error in
            if state == .authorized || state == .transferred {
                DispatchQueue.main.async {
                    self.createAccount()
                }
            }
        }
    }
}

// MARK: - FrutaModel API

extension FrutaModel {
    func orderSmoothie(_ smoothie: Smoothie) {
        order = Order(smoothie: smoothie, points: 1, isReady: false)
        addOrderToAccount()
    }
    
    func redeemSmoothie(_ smoothie: Smoothie) {
        guard var account = account, account.canRedeemFreeSmoothie else { return }
        account.pointsSpent += 10
        self.account = account
        orderSmoothie(smoothie)
    }
    
    func orderReadyForPickup() {
        order?.isReady = true
    }
    
    func selectSmoothie(_ smoothie: Smoothie) {
        selectSmoothie(id: smoothie.id)
    }
    
    func selectSmoothie(id: Smoothie.ID) {
        selectedSmoothieID = id
    }
    
    func toggleFavorite(smoothie: Smoothie) {
        if favoriteSmoothieIDs.contains(smoothie.id) {
            favoriteSmoothieIDs.remove(smoothie.id)
        } else {
            favoriteSmoothieIDs.insert(smoothie.id)
        }
    }
    
    func isFavorite(smoothie: Smoothie) -> Bool {
        favoriteSmoothieIDs.contains(smoothie.id)
    }
    
    func createAccount() {
        guard account == nil else { return }
        account = Account()
        addOrderToAccount()
    }
    
    func addOrderToAccount() {
        guard let order = order else { return }
        account?.appendOrder(order)
    }
    
    func clearUnstampedPoints() {
        account?.clearUnstampedPoints()
    }
    
    func authorizeUser(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result, let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            if case .failure(let error) = result {
                print("Authentication error: \(error.localizedDescription)")
            }
            return
        }
        DispatchQueue.main.async {
            self.userCredential = credential.user
            self.createAccount()
        }
    }
}
