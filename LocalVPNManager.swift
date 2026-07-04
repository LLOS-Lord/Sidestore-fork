import Foundation
import NetworkExtension

/**
 * LocalVPNManager.swift
 * Quản lý kết nối VPN cục bộ để duy trì giao tiếp với thiết bị và fix lỗi AFC.
 */

class LocalVPNManager {
    static let shared = LocalVPNManager()
    private let manager = NETunnelProviderManager()
    
    private init() {}
    
    /**
     * Cấu hình VPN cục bộ (sử dụng giao thức Tunnel).
     */
    func setupVPN(completion: @escaping (Bool, Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            let vpnManager = managers?.first ?? self.manager
            
            let protocolConfiguration = NETunnelProviderProtocol()
            protocolConfiguration.providerBundleIdentifier = "com.yourdomain.SideLoader.VPNProvider"
            protocolConfiguration.serverAddress = "127.0.0.1" // VPN cục bộ
            
            vpnManager.protocolConfiguration = protocolConfiguration
            vpnManager.localizedDescription = "SideLoader Local VPN"
            vpnManager.isEnabled = true
            
            vpnManager.saveToPreferences { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    /**
     * Bật VPN.
     */
    func startVPN(completion: @escaping (Error?) -> Void) {
        do {
            try manager.connection.startVPNTunnel()
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    /**
     * Tắt VPN.
     */
    func stopVPN() {
        manager.connection.stopVPNTunnel()
    }
    
    /**
     * Kiểm tra trạng thái VPN.
     */
    var isConnected: Bool {
        return manager.connection.status == .connected
    }
}
