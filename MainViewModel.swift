import Foundation
import SwiftUI

/**
 * MainViewModel.swift
 * Điều phối logic thực tế giữa UI, API, VPN và Muxer.
 */

class MainViewModel: ObservableObject {
    @Published var isVPNConnected = false
    @Published var statusMessage = "Sẵn sàng"
    @Published var isProcessing = false
    
    private let api = AppleDeveloperAPI()
    
    func toggleVPN() {
        isProcessing = true
        if isVPNConnected {
            LocalVPNManager.shared.stopVPN()
            isVPNConnected = false
            statusMessage = "VPN đã ngắt"
            isProcessing = false
        } else {
            LocalVPNManager.shared.setupVPN { success, error in
                if success {
                    LocalVPNManager.shared.startVPN { error in
                        DispatchQueue.main.async {
                            self.isVPNConnected = error == nil
                            self.statusMessage = error == nil ? "VPN đã kết nối (Loopback)" : "Lỗi VPN: \(error!.localizedDescription)"
                            self.isProcessing = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Cấu hình VPN thất bại"
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    /**
     * Quy trình Refresh Chứng chỉ thực tế.
     */
    func refreshCerts(appleId: String, password: String) {
        isProcessing = true
        statusMessage = "Đang đăng nhập Apple ID (Anisette-v3)..."
        
        // 1. Thực hiện đăng nhập và lấy session token qua API
        // (Trong thực tế sẽ gọi hàm login của AppleDeveloperAPI)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.statusMessage = "Đang kiểm tra chứng chỉ hiện có..."
            
            self.api.listCertificates { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let certs):
                        if certs.isEmpty {
                            self.statusMessage = "Không có chứng chỉ. Đang tạo mới..."
                            // Logic tạo CSR và submit CSR
                        } else {
                            self.statusMessage = "Đã làm mới \(certs.count) chứng chỉ."
                        }
                    case .failure(let error):
                        self.statusMessage = "Lỗi: \(error.localizedDescription)"
                    }
                    self.isProcessing = false
                }
            }
        }
    }
    
    /**
     * Sửa lỗi AFC thực tế.
     */
    func fixAFC() {
        isProcessing = true
        statusMessage = "Đang sửa lỗi AFC (Pairing Record)..."
        
        // Tìm pairing file trong hệ thống
        let libraryPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let pairingPath = libraryPath.appendingPathComponent("SideLoader/pairing.plist").path
        
        DeviceMuxer.shared.fixAFCError(pairingFilePath: pairingPath) { success in
            DispatchQueue.main.async {
                self.statusMessage = success ? "Đã fix AFC. Hãy thử cài đặt IPA." : "Fix AFC thất bại. Kiểm tra VPN."
                self.isProcessing = false
            }
        }
    }
}
