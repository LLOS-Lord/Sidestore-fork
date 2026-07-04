# SimplerSideStoreUI

Bộ khung UI + xử lý lỗi cho một bản **SideStore rút gọn, thân thiện hơn**.

> **Chiến lược:** không viết lại minimuxer / VPN loopback / AltSign (Apple Developer
> Services API) từ đầu — đó là phần đã được cộng đồng SideStore kiểm thử trong nhiều
> năm và cực kỳ dễ vỡ nếu viết lại. Ta **giữ nguyên phần "engine"**, chỉ thay thế
> tầng giao diện + luồng thao tác bằng bản đơn giản hơn ở đây, và thêm một lớp
> "friendly error" dịch các lỗi kỹ thuật (kể cả lỗi AFC) thành hướng dẫn sửa rõ ràng.

## 1. Vì sao đi theo hướng fork thay vì viết mới hoàn toàn

SideStore gồm nhiều module tách biệt trong cùng repo (kiểm tra tại
`github.com/SideStore/SideStore`, nhánh `develop`):

| Thư mục / submodule | Vai trò | Bạn có nên viết lại? |
|---|---|---|
| `AltStoreCore` | Model dữ liệu, gọi Apple Developer Services API, ký lại ipa, điều phối cài đặt/refresh | **Không** — giữ nguyên |
| `Dependencies/minimuxer` | Giả lập usbmuxd trong sandbox để nói chuyện AFC/installation_proxy qua tunnel | **Không** — giữ nguyên, có binary dựng sẵn |
| `StosVPN` (repo riêng) | App VPN loopback, đã được Apple cấp entitlement NetworkExtension | **Không** — dùng lại nguyên bản |
| `Roxas` | Tiện ích Objective-C nội bộ | Giữ nguyên |
| `AltStore` (app target) | Giao diện + điều phối luồng thao tác | **Đây là phần bạn viết lại** — chỗ các file trong `Sources/` bên dưới sẽ thay thế |

Vì `AltStoreCore` expose các API rõ ràng (đăng nhập Apple ID, cài app, refresh app,
lấy danh sách app đã cài, ngày hết hạn provisioning profile...), bạn chỉ cần import
module đó vào target UI mới và gọi vào, không phải đụng tới phần khó.

## 2. Giấy phép — đọc trước khi phát hành

SideStore (và AltStoreCore) được phát hành theo **AGPL-3.0**. Nếu bạn fork, sửa,
rồi **phân phối** app (kể cả cho người dùng qua sideloading, không chỉ App Store),
AGPL yêu cầu bạn phải công khai **toàn bộ mã nguồn** bản sửa đổi của mình, kèm cách
lấy mã nguồn ngay trong app nếu app có tương tác qua mạng. Đây không phải lời khuyên
pháp lý — hãy đọc kỹ file `LICENSE` của từng repo (`SideStore/SideStore`,
`SideStore/minimuxer`, `SideStore/AltSign`, `SideStore/StosVPN`) trước khi quyết định
mô hình phát hành.

## 3. Các bước fork & build thật (theo CONTRIBUTING.md hiện tại của repo)

Yêu cầu: máy Mac, Xcode 15+, iOS 14+ trên thiết bị test.

```bash
# 1. Fork SideStore/SideStore trên GitHub, sau đó clone bản fork của bạn
git clone https://github.com/<username-cua-ban>/SideStore.git --recurse-submodules
cd SideStore

# 2. Cấu hình chữ ký code
cp CodeSigning.xcconfig.sample CodeSigning.xcconfig
# Mở file này lên, điền Apple Developer Team ID, bundle id prefix, App Group ID... của bạn

# 3. (Chỉ khi chạy qua Xcode để dev) đặt UDID thiết bị test vào Info.plist, key ALTDeviceID
# (Khi build ipa production, SideServer/Makefile tự nhúng UDID lúc cài, không cần làm tay)

# 4. Cài CocoaPods rồi pod install
brew install cocoapods
pod install

# 5. Mở AltStore.xcodeproj bằng Xcode (KHÔNG mở .xcodeproj cũ nếu đã có .xcworkspace sau bước 4 — mở .xcworkspace)
open AltStore.xcworkspace
```

minimuxer/em_proxy được tải sẵn dạng binary qua `SideStore/fetch-prebuilt.sh`
(Xcode tự chạy trước mỗi lần build) — bạn **không cần cài Rust** trừ khi muốn sửa
chính minimuxer.

Build ipa để cài thử qua dòng lệnh:

```bash
export BUILD_CONFIG=Debug
export BUNDLE_ID_SUFFIX=TenRieng123   # đổi bundle id để không đụng SideStore gốc
make build fakesign ipa
```

Bạn cũng cần cài **StosVPN** (repo `SideStore/StosVPN`, đã có sẵn entitlement
NetworkExtension) lên máy — app của bạn tự phát hiện và dùng chung tunnel loopback
đó, không cần tự xin entitlement riêng ở giai đoạn thử nghiệm.

## 4. Cách ráp bộ UI trong `Sources/` vào project

1. Trong Xcode, thêm mới một **Group/Target** (ví dụ đặt tên `SimplerUI`) hoặc thay
   trực tiếp các View hiện có trong target `AltStore` bằng các file trong
   `Sources/Features/*`.
2. Thêm `import AltStoreCore` ở đầu các file cần gọi engine thật.
3. Trong `Sources/Core/CoreProtocols.swift`, mỗi protocol có comment chỉ rõ cần nối
   với type nào bên `AltStoreCore` (ví dụ `AppManager`, `ALTDeviceManager`,
   `OperationError`). Bạn viết một struct/class "Adapter" implement các protocol đó
   bằng cách gọi thẳng API thật của `AltStoreCore` — vài chục dòng glue code, không
   phải viết lại logic.
4. `Sources/Models/FriendlyError.swift` đã map sẵn các mã lỗi SideStore hay gặp
   (kể cả lỗi AFC/minimuxer #4, #27) sang thông điệp + hành động sửa cụ thể — bạn
   chỉ cần feed `OperationError` thật từ AltStoreCore vào hàm `FriendlyError(from:)`.

## 5. Vì sao thiết kế này giúp đỡ hẳn lỗi AFC

Lỗi *"AFC was unable to manage files on the device"* gần như luôn do **pairing
record của minimuxer bị hỏng/không khớp**, không phải lỗi logic cài đặt. Thay vì để
người dùng tự mò trong Settings như SideStore gốc, `SettingsView` +
`PairingTroubleshootView` ở đây gộp toàn bộ quy trình sửa đã biết là hiệu quả thành
**một nút bấm duy nhất**:

1. Xoá pairing record cũ khỏi Keychain
2. Yêu cầu tạo pairing record mới (qua `AltStoreCore`'s device-pairing flow, tương
   đương idevice_pair/jitterbug pair)
3. Kiểm tra StosVPN đang connected + đúng dải IP (mặc định `10.7.0.1`)
4. Nếu vẫn lỗi, tự động gợi ý đổi anisette server

Đây chính là điểm "đơn giản hơn, thân thiện hơn" bạn muốn — gộp một quy trình 8 bước
thủ công thành 1 luồng có UI dẫn dắt.
