# Lifecycle Hooks Guide (`hooks.json`)

Thư mục này cung cấp mẫu cấu hình Lifecycle Hooks cho Antigravity.

---

## 1. Khi nào dự án cần Lifecycle Hooks?

Lifecycle Hooks cho phép bạn tự động thực thi script shell tại các điểm mốc trong vòng đời agent:
- Chặn lệnh nguy hiểm trước khi chạy (`PreToolUse`).
- Tự động chạy linter hoặc format code sau khi sửa file (`PostToolUse`).
- Bơm thông báo chào mừng hoặc nhắc nhở trước phiên (`SessionStart`, `PreInvocation`).
- Kiểm tra điều kiện hoàn thành trước khi agent kết thúc (`Stop`).

Nếu dự án không có nhu cầu can thiệp tự động vào vòng lặp thực thi của agent, **KHÔNG CẦN** cấu hình Hooks.

---

## 2. Cách tích hợp vào dự án

1. Sao chép file cấu hình vào thư mục `.agents/`:
   ```powershell
   Copy-Item extensions/hooks/hooks.example.json .agents/hooks.json
   ```
2. Tạo script xử lý tương ứng (ví dụ: `scripts/safety-check.ps1` trên Windows hoặc `.sh` trên Linux).
3. Script nhận payload JSON qua `stdin` và trả về kết quả JSON qua `stdout`.
4. Nếu tạm thời muốn tắt một hook, chuyển `"enabled": false`.

---

## 3. Schema tóm tắt

- Các sự kiện được hỗ trợ: `SessionStart`, `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, `Stop`.
- Đối với `PreToolUse` / `PostToolUse`, handler phải nằm trong object chứa `matcher` (ví dụ: `"matcher": "run_command"` hoặc `"matcher": "file_change"`).
- Chỉ hỗ trợ `type: "command"`.
