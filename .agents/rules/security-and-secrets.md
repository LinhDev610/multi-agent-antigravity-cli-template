---
trigger: always_on
description: "Universal security rules to prevent secret exposure, data destruction, and unauthorized destructive actions."
---

# Universal Security & Secrets Safeguards

Quy tắc bảo mật bất biến áp dụng cho mọi tương tác trong workspace.

## 1. Bảo vệ bí mật (Secrets Protection)

- **Tuyệt đối KHÔNG** in ra màn hình, ghi vào log, lưu vào file cấu hình hoặc commit bất kỳ giá trị nào sau đây:
  - API Keys, Bearer Tokens, Private Keys (RSA, SSH, PGP).
  - Mật khẩu cơ sở dữ liệu, chuỗi kết nối (Connection Strings) có chứa thông tin xác thực.
  - Nội dung của các file nhạy cảm như `.env`, `.env.local`, `credentials.json`, `id_rsa`.
- Khi cần cấu hình tham số bảo mật, sử dụng biến môi trường hoặc file mẫu `.env.example` với giá trị giả định (placeholder).

## 2. Kiểm soát lệnh phá hủy (Destructive Commands Ban)

- **Cấm tự ý thực thi** các lệnh có nguy cơ mất mát dữ liệu hoặc làm hỏng lịch sử mã nguồn mà không có sự xác nhận rõ ràng của người dùng:
  - Git: `git reset --hard`, `git push --force`, `git clean -fdx`, `git checkout .`.
  - Hệ điều hành: Xóa đệ quy thư mục gốc (`rm -rf /`, `Remove-Item -Recurse C:\`), format ổ đĩa, sửa registry hệ thống.
  - Cơ sở dữ liệu: `DROP DATABASE`, `DROP TABLE`, `TRUNCATE TABLE`, `DELETE FROM` không có mệnh đề `WHERE`.

## 3. Quản lý phụ thuộc an toàn (Safe Dependencies)

- Không tự động cài đặt các package từ nguồn không đáng tin cậy.
- Kiểm tra tính tương thích và phiên bản ổn định trước khi cập nhật dependency của dự án.
