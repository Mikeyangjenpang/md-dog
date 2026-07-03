//
//  DonationView.swift
//  md dog
//
//  A sponsorship page presented from the Share menu. The app is free —
//  this screen offers an optional in-app purchase as a way to support it.
//

import SwiftUI
import StoreKit

struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = DonationStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image("DonationDog")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)

                    VStack(spacing: 10) {
                        Text("支持 md dog")
                            .font(.title2.weight(.bold))

                        Text("這個 App 完全免費使用，沒有廣告、也沒有任何功能限制。如果它對你有幫助，歡迎透過下方的贊助，請小狗吃一頓飯，支持開發者持續維護與改進。你的每一份心意都是最溫暖的鼓勵。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)

                    donationButton

                    Text("贊助為自願性質，並不會解鎖任何額外功能。")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("贊助支持")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .task { await store.loadProduct() }
            .alert("感謝你的支持！", isPresented: thanksBinding) {
                Button("不客氣") { store.purchaseState = .idle }
            } message: {
                Text("你的贊助已完成，這對 md dog 意義重大。🐶")
            }
            .alert("購買未完成", isPresented: failedBinding) {
                Button("好", role: .cancel) { store.purchaseState = .idle }
            } message: {
                Text(purchaseErrorMessage)
            }
        }
        .frame(minWidth: 360, minHeight: 480)
    }

    @ViewBuilder
    private var donationButton: some View {
        switch store.loadState {
        case .loading:
            ProgressView()
                .frame(height: 50)
        case .loaded(let product):
            Button {
                Task { await store.purchase(product) }
            } label: {
                HStack(spacing: 8) {
                    if store.purchaseState == .purchasing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "heart.fill")
                    }
                    Text("贊助 \(product.displayPrice)")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 22)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.purchaseState == .purchasing)
        case .failed:
            VStack(spacing: 10) {
                Text("目前無法載入贊助項目，請稍後再試。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("重新載入") {
                    Task { await store.loadProduct() }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var thanksBinding: Binding<Bool> {
        Binding(
            get: { store.purchaseState == .thanks },
            set: { if !$0 { store.purchaseState = .idle } }
        )
    }

    private var failedBinding: Binding<Bool> {
        Binding(
            get: { if case .failed = store.purchaseState { true } else { false } },
            set: { if !$0 { store.purchaseState = .idle } }
        )
    }

    private var purchaseErrorMessage: String {
        if case .failed(let message) = store.purchaseState {
            return message
        }
        return String(localized: "請稍後再試一次。")
    }
}

#Preview {
    DonationView()
}
