# SideLoader iOS

SideLoader là một ứng dụng iOS mã nguồn mở giúp cài đặt tệp IPA và làm mới chứng chỉ nhà phát triển (refresh certificate) một cách đơn giản, hiệu quả và mạnh mẽ.

## ✨ Tính năng nổi bật

*   **Refresh Certificate**: Tự động hoặc thủ công làm mới chứng chỉ nhà phát triển Apple miễn phí (7 ngày).
*   **IPA Sideloading**: Cài đặt tệp IPA trực tiếp trên thiết bị iOS mà không cần máy tính sau lần cài đặt đầu tiên.
*   **Local Dev VPN**: Tích hợp VPN cục bộ để duy trì kết nối ổn định và khắc phục các hạn chế của hệ thống.
*   **AFC Fix**: Giải quyết triệt để lỗi `AFC was unable to manage file on the device` bằng cách tối ưu hóa việc quản lý tệp ghép nối (pairing file) và kết nối VPN.
*   **Tối ưu & Tương thích**: Được xây dựng trên nền tảng Swift hiện đại, tích hợp `minimuxer` và `AltSign` tối ưu.

## 🛠 Công nghệ sử dụng

*   **Swift & SwiftUI**: Giao diện hiện đại, mượt mà.
*   **Minimuxer**: Lockdown muxer hiệu năng cao để giao tiếp với thiết bị.
*   **AltSign**: Thư viện ký IPA mạnh mẽ.
*   **Network Extension**: Tạo VPN cục bộ an toàn.

## 🚀 Hướng dẫn cài đặt

1.  Tải xuống tệp IPA từ [Releases](https://github.com/yourusername/SideLoader/releases).
2.  Cài đặt lần đầu qua AltStore hoặc Sideloadly (yêu cầu máy tính).
3.  Mở ứng dụng, đăng nhập Apple ID và bật VPN.
4.  Bắt đầu sideload ứng dụng yêu thích của bạn!

## 📦 Cấu trúc dự án

*   `Core/`: Chứa logic Apple Developer API, Certificate Manager, và Device Communication.
*   `VPN/`: Chứa cấu hình và provider cho Local Dev VPN.
*   `UI/`: Giao diện người dùng SwiftUI.
*   `.github/workflows/`: Cấu hình CI/CD tự động build IPA.

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Hãy tạo Pull Request hoặc Issue nếu bạn có ý tưởng cải tiến hoặc phát hiện lỗi.

## ⚖️ Giấy phép

Dự án này được phát hành dưới giấy phép AGPL-3.0.
