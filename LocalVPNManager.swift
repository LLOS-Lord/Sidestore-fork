import Foundation
import NetworkExtension

/**
 * LocalVPNManager.swift
 * Triển khai logic VPN cục bộ để SideLoader có thể "tự kết nối" với chính nó.
 * Cơ chế này giống SideStore, đánh lừa hệ thống rằng có một máy tính đang kết nối qua WiFi.
 */

class LocalVPNManager {
    static let shared = LocalVPNManager()
    private let manager = NETunnelProviderManager()
    
    private init() {}
    
    func setupVPN(completion: @escaping (Bool, Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            let vpnManager = managers?.first ?? NETunnelProviderManager()
            
            let protocolConfiguration = NETunnelProviderProtocol()
            protocolConfiguration.providerBundleIdentifier = "com.yourdomain.SideLoader.VPNProvider"
            protocolConfiguration.serverAddress = "SideLoader-Internal"
            
            // Cấu hình WireGuard cục bộ (thường là file .conf được nhúng)
            // SideStore sử dụng WireGuard để tạo tunnel tới usbmuxd
            protocolConfiguration.providerConfiguration = [
                "endpoint": "127.0.0.1:51820",
                "public_key": "YOUR_PUBLIC_KEY",
                "mtu": "1280"
            ]
            
            vpnManager.protocolConfiguration = protocolConfiguration
            vpnManager.localizedDescription = "SideLoader Loopback"
            vpnManager.isEnabled = true
            
            vpnManager.saveToPreferences { error in
                completion(error == nil, error)
            }
        }
    }
    
    func startVPN(completion: @escaping (Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            guard let vpnManager = managers?.first else {
                completion(NSError(domain: "VPN", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chưa cấu hình VPN"]))
                return
            }
            
            do {
                try vpnManager.connection.startVPNTunnel()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    func stopVPN() {
        manager.connection.stopVPNTunnel()
    }
    
    var isConnected: Bool {
        return manager.connection.status == .connected
    }
}
