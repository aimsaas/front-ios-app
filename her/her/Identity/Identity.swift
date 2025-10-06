//
//  Identity.swift
//  Her
//
//  Created by dev on 2025/10/2.
//

import SwiftUI
import SwiftData

// MARK: - 身份状态枚举（包含私钥和 userId）
enum IdentityState: Equatable {
    case none                  // 还没有创建身份或已注销
    case active(privateKey: String, userId: String) // 已有身份
}

struct Identity: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [UserInfo]

    @State private var showExportAlert = false
    @State private var showImportSheet = false
    @State private var importKey = ""
    @State private var showKeyErrorAlert = false
    @State private var identityState: IdentityState = .none

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello Identity")
                .font(.largeTitle)
                .padding()
            
            // 显示当前用户 ID
            if case .active(_, let userId) = identityState {
                Text("User ID: \(userId)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // 创建身份按钮
            Button("创建身份") {
                createIdentity()
            }
            .buttonStyle(.borderedProminent)
            .disabled(identityState != .none) // 有身份时不可再创建

            // 注销身份按钮
            Button("注销身份") {
                logoutIdentity()
            }
            .buttonStyle(.bordered)
            .disabled(identityState == .none) // 无身份时灰色

            Divider()

            // 导出私钥按钮
            Button("导出私钥") {
                exportPrivateKey()
            }
            .buttonStyle(.bordered)
            .disabled(identityState == .none) // 无身份时灰色

            // 从私钥恢复按钮
            Button("从私钥恢复") {
                showImportSheet = true
            }

        }
        // 导出私钥弹窗
        .alert("导出私钥", isPresented: $showExportAlert) {
            switch identityState {
            case .none:
                Button("关闭", role: .cancel) {}
            case .active(let key, _):
                Button("复制") {
                    UIPasteboard.general.string = key
                }
                Button("关闭", role: .cancel) {}
            }
        } message: {
            switch identityState {
            case .none:
                Text("当前没有可导出的身份，请先创建或恢复。")
            case .active(let key, _):
                Text("请妥善保存此私钥（不要截图或泄漏）:\n\n\(key)")
            }
        }

        // 恢复账号输入界面
        .sheet(isPresented: $showImportSheet) {
            VStack {
                Text("请输入私钥 Base64")
                    .font(.headline)
                TextEditor(text: $importKey)
                    .border(.gray)
                    .frame(height: 150)
                Button("恢复账号") {
                    recoverFromPrivateKey()
                }
                .padding()
            }
            .padding()
        }

        // 密钥错误提示
        .alert("密钥错误", isPresented: $showKeyErrorAlert) {
            Button("关闭", role: .cancel) {}
        } message: {
            Text("输入的密钥无效或格式错误。")
        }
    }

    // MARK: - 创建身份
    private func createIdentity() {
        do {
            let pair = try RecoveryKeyManager.generateAndStore()
            let newUser = UserInfo(
                userId: pair.userId,
                token: "token_string",
                avatarUrl: "avatar/2025/9/\(pair.userId).png",
                certificated: true,
                certification: "走哪啦团队",
                level: "diamond",
                nickName: "功夫小猫",
                uid: UUID().uuidString,
                updateTime: Int64(Date().timeIntervalSince1970 * 1000)
            )
            context.insert(newUser)
            try? context.save()
            
            // 安全获取私钥并更新身份状态（包含 userId）
            if let keyData = RecoveryKeyManager.loadPrivateKeyDataFromKeychain() {
                let keyBase64 = keyData.base64EncodedString()
                DispatchQueue.main.async {
                    identityState = .active(privateKey: keyBase64, userId: pair.userId)
                }
            } else {
                identityState = .none
            }

            print("✅ 已创建身份并生成私钥，userId = \(pair.userId)")
        } catch {
            print("❌ 生成私钥失败: \(error)")
        }
    }

    // MARK: - 注销身份
    private func logoutIdentity() {
        if let user = users.first {
            // 删除用户信息
            clearUser(user: user)
            
            // 销毁私钥
            RecoveryKeyManager.deletePrivateKey()
            
            // 更新身份状态
            identityState = .none
            
            print("🗑️ 已注销身份并销毁私钥")
        }
    }

    // MARK: - 导出私钥
    private func exportPrivateKey() {
        if case .active(_, _) = identityState {
            showExportAlert = true
        } else {
            // 尝试同步加载私钥
            if let data = RecoveryKeyManager.loadPrivateKeyDataFromKeychain(),
               let user = users.first {
                let keyBase64 = data.base64EncodedString()
                identityState = .active(privateKey: keyBase64, userId: user.userId)
            } else {
                identityState = .none
            }
            showExportAlert = true
        }
    }

    // MARK: - 从私钥恢复
    private func recoverFromPrivateKey() {
        do {
            guard let data = Data(base64Encoded: importKey) else {
                showKeyErrorAlert = true
                showImportSheet = false
                return
            }
            let _ = try RecoveryKeyManager.importPrivateKey(base64: importKey)
            let recoveredUser = try AccountRecovery.recoverFromPrivateKeyData(data, context: context)
            showImportSheet = false
            
            // 更新身份状态
            if let keyData = RecoveryKeyManager.loadPrivateKeyDataFromKeychain() {
                let keyBase64 = keyData.base64EncodedString()
                identityState = .active(privateKey: keyBase64, userId: recoveredUser.userId)
            } else {
                identityState = .none
            }
        } catch {
            print("恢复失败:", error)
            showKeyErrorAlert = true
            showImportSheet = false
        }
    }

    // MARK: - 删除用户
    private func clearUser(user: UserInfo) {
        context.delete(user)
        try? context.save()
    }
}
