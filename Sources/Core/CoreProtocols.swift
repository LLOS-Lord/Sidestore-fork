import Foundation

// MARK: - Ranh giới giữa UI đơn giản và engine AltStoreCore thật
//
// Mỗi protocol dưới đây tương ứng với một nhóm chức năng đã có sẵn trong
// AltStoreCore/minimuxer/AltSign. Sau khi `import AltStoreCore` vào target,
// bạn viết một struct/class "Adapter" implement protocol tương ứng, bên trong
// gọi thẳng API thật — xem chú thích ngay trong từng protocol.
//
// KHÔNG viết logic ký lại ipa, giao tiếp AFC, hay auth Apple ID lại từ đầu ở đây.
// Các Placeholder* ở cuối file chỉ để project build/preview được trên máy
// không có thiết bị thật cắm vào.

/// Bọc thao tác liên quan tới VPN loopback (StosVPN) + minimuxer.
///
/// Nối với: `MinimuxerManager` / `ServerManager` trong AltStoreCore,
/// và trạng thái NEVPNStatus của cấu hình StosVPN.
protocol DeviceConnecting {
    func currentVPNStatus() async -> VPNStatus
}

/// Bọc thao tác ký lại ipa bằng chứng chỉ + provisioning profile.
///
/// Nối với: `AppManager.sign(_:)` hoặc trực tiếp `AltSign` (ALTSigner) trong AltStoreCore.
/// Phần đăng nhập Apple ID + xin certificate cũng nằm trong nhóm này
/// (AltStoreCore đã có sẵn luồng GrandSlam/anisette, không cần viết lại).
protocol AppSigning {
    func signIn(email: String, password: String) async throws
    func resign(app: SideloadedApp) async throws -> SideloadedApp
}

/// Bọc thao tác cài đặt / gỡ / liệt kê app qua AFC + installation_proxy.
///
/// Nối với: `AppManager.install(_:)`, `AppManager.fetchInstalledApps()` trong AltStoreCore.
protocol AppInstalling {
    func fetchInstalledApps() async throws -> [SideloadedApp]
    func install(ipaURL: URL) async throws -> SideloadedApp
    func uninstall(app: SideloadedApp) async throws
}

/// Bọc thao tác quản lý pairing file (nguồn gốc phổ biến nhất của lỗi AFC).
///
/// Nối với: API pairing trong AltStoreCore/minimuxer tương đương idevice_pair.
protocol PairingFileManaging {
    func resetPairingFile() async throws
    func requestFreshPairingFile() async throws
}

// MARK: - Placeholder implementations (chỉ để project build/preview tạm)

struct PlaceholderDeviceConnection: DeviceConnecting {
    func currentVPNStatus() async -> VPNStatus { .unknown }
}

enum NotWiredUpError: LocalizedError {
    case adapterNotImplemented(String)
    var errorDescription: String? {
        switch self {
        case .adapterNotImplemented(let name):
            return "\(name) chưa được nối với AltStoreCore thật. Xem README.md mục 4."
        }
    }
}

struct PlaceholderAppSigning: AppSigning {
    func signIn(email: String, password: String) async throws {
        throw NotWiredUpError.adapterNotImplemented("AppSigning")
    }
    func resign(app: SideloadedApp) async throws -> SideloadedApp {
        throw NotWiredUpError.adapterNotImplemented("AppSigning")
    }
}

struct PlaceholderAppInstalling: AppInstalling {
    func fetchInstalledApps() async throws -> [SideloadedApp] { [] }
    func install(ipaURL: URL) async throws -> SideloadedApp {
        throw NotWiredUpError.adapterNotImplemented("AppInstalling")
    }
    func uninstall(app: SideloadedApp) async throws {
        throw NotWiredUpError.adapterNotImplemented("AppInstalling")
    }
}

struct PlaceholderPairingFileManaging: PairingFileManaging {
    func resetPairingFile() async throws {
        throw NotWiredUpError.adapterNotImplemented("PairingFileManaging")
    }
    func requestFreshPairingFile() async throws {
        throw NotWiredUpError.adapterNotImplemented("PairingFileManaging")
    }
}
