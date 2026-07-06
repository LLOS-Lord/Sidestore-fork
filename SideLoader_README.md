# SideLoader - Ứng dụng Sideload iOS Tối ưu

Ứng dụng này được thiết kế để thay thế SideStore/AltStore với logic tối ưu hơn, hỗ trợ Anisette-v3 và fix lỗi AFC triệt để.

## Các thành phần chính (Logic thật):

1.  **AppleDeveloperAPI.swift**: 
    - Tích hợp **Anisette-v3** (mặc định qua `anisette.sidestore.io`).
    - Giao tiếp trực tiếp với Apple Developer API để quản lý chứng chỉ mà không cần AltServer.
2.  **DeviceMuxer.swift**:
    - Xử lý giao tiếp usbmuxd cục bộ.
    - **Fix lỗi AFC**: Nạp lại Pairing Record (`pairing.plist`) và thực hiện handshake với Lockdown service.
3.  **LocalVPNManager.swift**:
    - Tạo một **VPN Tunnel (WireGuard/Loopback)** cục bộ.
    - Cho phép ứng dụng tự kết nối với các dịch vụ hệ thống của chính nó để thực hiện cài đặt IPA.
4.  **GitHub Actions**:
    - Tự động build và đóng gói IPA không cần ký (Unsigned).
    - Hỗ trợ quét scheme và app tự động.

## Cách tích hợp thư viện mã nguồn mở:

Để mã nguồn này hoạt động hoàn chỉnh, bạn cần thêm các thư viện sau vào Xcode project (qua Swift Package Manager hoặc Git Submodules):

-   **minimuxer**: Dùng để giao tiếp usbmuxd (viết bằng Rust/C).
-   **AltSign**: Dùng để ký IPA và quản lý Provisioning Profiles.
-   **WireGuardKit**: Dùng cho module VPN cục bộ.

## Khắc phục lỗi AFC:
Nếu gặp lỗi "AFC was unable to manage file", hãy nhấn nút **"Sửa lỗi AFC"** trong ứng dụng. SideLoader sẽ:
1. Kiểm tra kết nối VPN cục bộ.
2. Nạp lại Pairing Record từ thư mục Library.
3. Khởi động lại dịch vụ `com.apple.afc` trên thiết bị.
