//
//  DonationStore.swift
//  md dog
//
//  Manages the optional "sponsor / tip" in-app purchase.
//  The app is fully free — this purchase is a voluntary donation only.
//

import Foundation
import StoreKit

/// The consumable product identifier used for the sponsorship tip.
/// Configure a matching consumable in App Store Connect (and in `Donation.storekit`).
enum DonationProduct {
    static let tip = "md_dog.tip"
}

/// Loads the donation product and drives the purchase flow using StoreKit 2.
@MainActor
@Observable
final class DonationStore {
    /// The loadable state of the donation product.
    enum LoadState {
        case loading
        case loaded(Product)
        case failed
    }

    /// The result of the most recent purchase attempt.
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case thanks
        case failed(String)
    }

    private(set) var loadState: LoadState = .loading
    var purchaseState: PurchaseState = .idle

    /// Loads the donation product from the App Store.
    func loadProduct() async {
        loadState = .loading
        do {
            let products = try await Product.products(for: [DonationProduct.tip])
            if let product = products.first {
                loadState = .loaded(product)
            } else {
                loadState = .failed
            }
        } catch {
            loadState = .failed
        }
    }

    /// Starts the purchase flow for the given product.
    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .thanks
                case .unverified:
                    purchaseState = .failed(String(localized: "無法驗證這筆交易，請稍後再試。"))
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }
}
