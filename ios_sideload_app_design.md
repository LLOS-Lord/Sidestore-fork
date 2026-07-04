# Thiết kế kiến trúc ứng dụng iOS cho SideLoader

## 1. Mục tiêu

Xây dựng một ứng dụng iOS (SideLoader) mã nguồn mở, đơn giản, thân thiện với người dùng, có khả năng:

*   Làm mới chứng chỉ nhà phát triển (refresh certificate) miễn phí.
*   Cài đặt tệp IPA lên thiết bị iOS.
*   Sử dụng Local Dev VPN để duy trì kết nối và khắc phục lỗi AFC.
*   Tối ưu hóa và tương thích mạnh mẽ hơn so với các giải pháp hiện có như AltStore/SideStore.

## 2. Kiến trúc tổng thể

Ứng dụng sẽ được phát triển bằng Swift và Xcode, tuân thủ kiến trúc MVVM (Model-View-ViewModel) để đảm bảo tính module hóa, dễ bảo trì và mở rộng. Các thành phần chính bao gồm:

*   **UI Layer (View & ViewModel)**: Giao diện người dùng và logic trình bày.
*   **Core Logic Layer (Model)**: Chứa các module xử lý nghiệp vụ chính như xác thực Apple ID, quản lý chứng chỉ, ký IPA.
*   **Device Communication Layer**: Giao tiếp với thiết bị iOS thông qua USB và VPN.
*   **Persistence Layer**: Lưu trữ dữ liệu an toàn.

```mermaid
graph TD
    A[UI Layer (SwiftUI/UIKit)] --> B(Core Logic Layer)
    B --> C(Device Communication Layer)
    B --> D(Persistence Layer)
    C --> E[Local Dev VPN Framework]
    C --> F[Minimuxer/libimobiledevice]
    B --> G[AltSign/Apple Developer API]
    G --> H[Apple Servers]
    C --> I[AFC Service on iOS Device]
```

## 3. Các Module chính và Chức năng

### 3.1. Core Logic Layer

Module này sẽ là trái tim của ứng dụng, chịu trách nhiệm về các tác vụ chính:

*   **Authentication Manager**: Quản lý quá trình xác thực Apple ID. Dựa trên `apple_auth.py` đã phân tích, nó sẽ xử lý đăng nhập, 2FA, và lấy `dsid`, `session_token`.
*   **Certificate Manager**: Quản lý chứng chỉ nhà phát triển miễn phí. Dựa trên `developer_api.py` và `refresh_certificate.py`, module này sẽ:
    *   Liệt kê các chứng chỉ hiện có.
    *   Thu hồi (revoke) chứng chỉ cũ (đặc biệt là các chứng chỉ do công cụ này tạo ra).
    *   Tạo chứng chỉ mới (sử dụng CSR và RSA private key).
    *   Kiểm tra thời hạn chứng chỉ và tự động làm mới khi cần.
*   **Provisioning Profile Manager**: Quản lý các Provisioning Profile. Sẽ có chức năng liệt kê và tải về các profile cần thiết cho việc cài đặt IPA.
*   **IPA Signer**: Ký lại tệp IPA với chứng chỉ và provisioning profile của người dùng. Module này sẽ tích hợp thư viện `AltSign` (hoặc một giải pháp tương tự) để thực hiện việc này.

### 3.2. Device Communication Layer

Module này sẽ xử lý việc giao tiếp cấp thấp với thiết bị iOS:

*   **USB Device Manager**: Phát hiện và quản lý kết nối với thiết bị iOS qua USB. Sẽ sử dụng `minimuxer` làm nền tảng để thiết lập kênh giao tiếp.
*   **AFC File Manager**: Quản lý tệp trên thiết bị iOS thông qua dịch vụ AFC (Apple File Conduit). Đây là nơi sẽ triển khai giải pháp khắc phục lỗi 
AFC (`AFC was unable to manage file on the device`) bằng cách đảm bảo quản lý tệp ghép nối (pairing file) hợp lệ và sử dụng VPN cục bộ.
*   **Local Dev VPN Manager**: Quản lý kết nối VPN cục bộ trên thiết bị iOS. VPN này sẽ được sử dụng để duy trì kết nối ổn định với thiết bị và có thể đóng vai trò quan trọng trong việc giải quyết các vấn đề liên quan đến AFC, tương tự cách SideStore sử dụng WireGuard VPN để khắc phục lỗi [1].

### 3.3. UI Layer

*   **Main View**: Giao diện chính để hiển thị trạng thái thiết bị, danh sách các ứng dụng đã cài, và các tùy chọn chính.
*   **IPA Installation View**: Giao diện để chọn tệp IPA và bắt đầu quá trình cài đặt.
*   **Certificate Management View**: Giao diện để xem trạng thái chứng chỉ, thực hiện làm mới thủ công hoặc cấu hình làm mới tự động.
*   **Settings View**: Cấu hình Apple ID, tùy chọn VPN, và các cài đặt khác.

### 3.4. Persistence Layer

*   **Keychain Manager**: Lưu trữ an toàn các thông tin nhạy cảm như mật khẩu Apple ID, session token, private key của chứng chỉ.
*   **UserDefaults/CoreData**: Lưu trữ các cài đặt ứng dụng, trạng thái chứng chỉ, danh sách ứng dụng đã cài, v.v.

## 4. Khắc phục lỗi "AFC was unable to manage file on the device"

Lỗi này thường xảy ra do tệp ghép nối (pairing file) không hợp lệ hoặc bị hỏng, hoặc do vấn đề kết nối giữa thiết bị và máy chủ. Để khắc phục, ứng dụng sẽ thực hiện các bước sau:

1.  **Quản lý Pairing File**: Đảm bảo rằng ứng dụng tạo và quản lý tệp ghép nối một cách chính xác. Sẽ có tùy chọn để người dùng reset hoặc tạo lại pairing file nếu cần, tương tự như cách SideStore và AltStore xử lý [2].
2.  **Sử dụng Local Dev VPN**: Kích hoạt VPN cục bộ sẽ giúp duy trì một kênh giao tiếp ổn định và đáng tin cậy giữa ứng dụng và các dịch vụ trên thiết bị, giảm thiểu khả năng xảy ra lỗi AFC do mất kết nối hoặc bị chặn bởi hệ thống [1].
3.  **Tích hợp `minimuxer`**: `minimuxer` cung cấp một lớp trừu tượng đáng tin cậy để giao tiếp với thiết bị iOS, giúp xử lý các vấn đề kết nối cấp thấp một cách hiệu quả hơn.

## 5. Công nghệ sử dụng

*   **Ngôn ngữ**: Swift
*   **Framework UI**: SwiftUI (ưu tiên cho giao diện hiện đại và dễ phát triển)
*   **Quản lý thiết bị**: `minimuxer` (thông qua Swift/C bindings)
*   **Ký IPA**: `AltSign` (hoặc triển khai lại logic tương tự dựa trên phân tích `ios_sideload_tool.zip`)
*   **VPN**: Network Extension Framework của Apple để tạo Local Dev VPN.
*   **Xác thực Apple ID**: Dựa trên logic từ `apple_auth.py` và `developer_api.py`.

## 6. Kế hoạch phát triển

1.  **Giai đoạn 1: Core Logic & Device Communication**: Tập trung vào việc tích hợp `minimuxer`, triển khai Local Dev VPN, và các module quản lý chứng chỉ/API Apple Developer.
2.  **Giai đoạn 2: IPA Signing & Installation**: Triển khai logic ký IPA và cài đặt lên thiết bị.
3.  **Giai đoạn 3: UI Development**: Xây dựng giao diện người dùng thân thiện và dễ sử dụng.
4.  **Giai đoạn 4: Tối ưu hóa & Fix lỗi**: Tối ưu hiệu suất, kiểm tra và khắc phục các lỗi còn tồn đọng, đặc biệt là lỗi AFC.
5.  **Giai đoạn 5: GitHub Actions CI/CD**: Thiết lập quy trình build và deploy tự động.

## 7. Tham khảo

1.  [GitHub - SideStore/SideStore/issues/156](https://github.com/SideStore/SideStore/issues/156) - Thảo luận về lỗi AFC và giải pháp WireGuard VPN.
2.  [SideStore Docs - Error Codes](https://docs.sidestore.io/docs/troubleshooting/error-codes) - Hướng dẫn khắc phục lỗi AFC liên quan đến pairing file.
