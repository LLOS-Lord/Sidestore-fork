import Foundation
import SwiftUI

/**
 * MainViewModel.swift
 * Logic điều khiển giao diện chính.
 */

class MainViewModel: ObservableObject {
    @Published var isVPNConnected = false
    @Published var isMuxerReady = false
    @Published var statusMessage = "Sẵn sàng"
    @Published var certificates: [[String: Any]] = []
    
    private let api = AppleDeveloperAPI()
    
    init() {
        checkStatus()
    }
    
    func checkStatus() {
        self.isVPNConnected = LocalVPNManager.shared.isConnected
        DeviceMuxer.shared.startMuxer { [weak self] ready in
            DispatchQueue.main.async {
                self?.isMuxerReady = ready
            }
        }
    }
    
    func toggleVPN() {
        if isVPNConnected {
            LocalVPNManager.shared.stopVPN()
            isVPNConnected = false
            statusMessage = "VPN đã tắt"
        } else {
            LocalVPNManager.shared.setupVPN { success, error in
                if success {
                    LocalVPNManager.shared.startVPN { error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.statusMessage = "Lỗi VPN: \(error.localizedDescription)"
                            } else {
                                self.isVPNConnected = true
                                self.statusMessage = "VPN đang chạy"
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Lỗi cấu hình VPN"
                    }
                }
            }
        }
    }
    
    func refreshCerts() {
        statusMessage = "Đang kiểm tra chứng chỉ..."
        api.listCertificates { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let certs):
                    self.certificates = certs
                    self.statusMessage = "Tìm thấy \(certs.count) chứng chỉ"
                case .failure(let error):
                    self.statusMessage = "Lỗi: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func installIPA(url: URL) {
        statusMessage = "Đang cài đặt \(url.lastPathComponent)..."
        DeviceMuxer.shared.installIPA(at: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.statusMessage = "Cài đặt thành công!"
                case .failure(let error):
                    self.statusMessage = "Lỗi cài đặt: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fixAFC() {
        statusMessage = "Đang sửa lỗi AFC..."
        // Giả sử pairing file được lưu trong Documents
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("pairing.plist").path
        DeviceMuxer.shared.fixAFCError(pairingFilePath: path) { success in
            DispatchQueue.main.async {
                self.statusMessage = success ? "Đã sửa lỗi AFC. Hãy thử lại." : "Sửa lỗi AFC thất bại."
            }
        }
    }
}
