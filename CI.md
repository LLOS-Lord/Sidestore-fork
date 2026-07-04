# Cấu hình CI (GitHub Actions)

File workflow: `.github/workflows/build-ipa.yml`

## Việc cần làm 1 lần trên GitHub

1. Trong repo fork của bạn: **Settings → Secrets and variables → Actions → New repository secret**
2. Tạo secret tên `CODE_SIGNING_XCCONFIG`, giá trị là **toàn bộ nội dung** file
   `CodeSigning.xcconfig` bạn đã điền ở bước cài đặt local (Team ID, bundle id
   prefix, App Group ID...). Dán nguyên văn nội dung file vào ô value, không mã hoá thêm.
3. (Tuỳ chọn) Nếu bạn dùng Fastlane Match hoặc chứng chỉ riêng để build bản release
   thật thay vì fakesign, thêm các secret tương ứng (`MATCH_PASSWORD`,
   `APPSTORE_KEY_ID`...) và sửa bước build trong workflow cho phù hợp.

## Khi nào workflow chạy

| Sự kiện | Việc workflow làm |
|---|---|
| Push / Pull Request vào `main` | Build thử, kiểm tra code compile được, ipa lưu làm artifact 14 ngày |
| Bấm "Run workflow" thủ công | Giống trên |
| Publish một GitHub Release | Build xong, tự đính file `.ipa` vào đúng Release đó |

## Vì sao build ra ipa "fakesign" thay vì ký thật trong CI

Dự án dạng SideStore/AltStore không phân phối bản ký sẵn bằng một chứng chỉ Apple
Developer cố định — mỗi người dùng cuối cài bằng **chứng chỉ cá nhân của chính họ**
(qua AltServer/SideStore/iloader). Vì vậy CI chỉ cần đóng gói + ký tạm (fakesign)
để tạo ra một file `.ipa` hợp lệ về cấu trúc; bước ký thật xảy ra ngay lúc người
dùng cài đặt, không nằm trong CI. Đây cũng là lý do bạn **không cần tài khoản
Apple Developer trả phí** chỉ để chạy pipeline này.

## Nếu build lỗi trên CI nhưng chạy được trên máy bạn

Thường do:
- Phiên bản Xcode trên runner khác máy bạn → thử ghim cứng `xcode-version` trong
  workflow thay vì `latest-stable`, chọn đúng bản bạn đang dùng local.
- Thiếu submodule → kiểm tra lại `.gitmodules` đã được commit đầy đủ trong fork của bạn.
- CocoaPods cache cũ → xoá cache trong tab Actions → Caches trên GitHub rồi chạy lại.
