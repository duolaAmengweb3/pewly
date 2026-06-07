import Foundation
import StoreKit

/// StoreKit 2 — Pewly Pro is a one-time non-consumable buyout (no subscription). Source of truth for `isPro`.
@MainActor
final class ProStore: ObservableObject {
    static let productID = "com.duolaameng.pewly.pro"
    @Published var product: Product?
    @Published var isPro = false
    @Published var purchasing = false

    var priceText: String { product?.displayPrice ?? "$9.99" }

    func load() async {
        if let p = try? await Product.products(for: [Self.productID]).first { product = p }
        await refreshEntitlement()
        // listen for external transactions (restores on other devices, Ask to Buy, etc.)
        Task.detached { for await update in Transaction.updates { if let t = try? update.payloadValue { await t.finish(); await self.refreshEntitlement() } } }
    }

    func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID, t.revocationDate == nil { isPro = true; return }
        }
        isPro = false
    }

    @discardableResult
    func purchase() async -> Bool {
        guard let product else { return false }
        purchasing = true; defer { purchasing = false }
        do {
            let result = try await product.purchase()
            if case .success(let v) = result, case .verified(let t) = v { await t.finish(); await refreshEntitlement(); return isPro }
        } catch { }
        return false
    }

    func restore() async { try? await AppStore.sync(); await refreshEntitlement() }
}
