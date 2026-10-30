---
trigger: glob
globs: "*.ts, *.tsx, *.js, *.jsx, *.py, *.go, *.java, *.cs, *.cpp, *.rs"
description: "Code quality and maintainability standards for all source code files."
---

# Code Quality & Maintainability Standards

Quy tắc kỹ thuật áp dụng khi tạo, đọc hoặc sửa đổi các file mã nguồn.

## 1. Tính toàn vẹn của mã nguồn (Code Integrity)

- **Bảo toàn comment & docstring**: Giữ nguyên tài liệu nội bộ, comment giải thích logic phức tạp không liên quan trực tiếp đến phạm vi sửa đổi.
- **Tối thiểu hóa thay đổi (Atomic Changes)**: Chỉ sửa đổi đúng vùng code liên quan đến yêu cầu; tránh định dạng lại toàn bộ file dẫn đến diff lớn gây khó khăn cho code review.
- **Xử lý lỗi rõ ràng**: Bắt buộc bắt và xử lý ngoại lệ tường minh (explicit error handling), không bỏ qua lỗi âm thầm (no silent swallow).

## 2. Quy chuẩn đặt tên & Phong cách (Naming & Style)

- Tuân thủ quy ước đặt tên chuẩn của từng ngôn ngữ (ví dụ: `camelCase` cho JavaScript/TypeScript, `snake_case` cho Python, `PascalCase` cho Go/C#).
- Tên biến, hàm, class phải có ý nghĩa đại diện cho hành vi hoặc dữ liệu; tránh đặt tên viết tắt tối nghĩa (`tmp`, `data1`, `process`).

## 3. Kiểm thử đi kèm (Testing Verification)

- Mỗi hàm hoặc module mới tạo phải đi kèm phương án kiểm thử (unit test hoặc integration test tương ứng).
- Trước khi hoàn thành tác vụ, chạy lệnh kiểm tra cú pháp hoặc unit test liên quan để đảm bảo không tạo ra regression bug.
