# Sổ Tay Debug & Khả Năng Quan Sát (Observability & Troubleshooting)

Tài liệu này hướng dẫn kỹ thuật gỡ lỗi chuyên sâu, phân tích telemetry, giải mã cấu trúc thư mục brain (`~/.gemini/antigravity-cli/brain/`), trích xuất dữ liệu từ `transcript.jsonl` và xử lý triệt để hiện tượng vòng lặp vô hạn (infinite tool loops) trong Google Antigravity CLI (`agy 1.4.10`).

---

## 1. Tầm quan trọng của Khả năng Quan sát (Observability)

Khác với việc gỡ lỗi một chương trình phần mềm truyền thống (vốn có luồng thực thi tất định và stack trace rõ ràng), việc gỡ lỗi một AI Agent phức tạp hơn vì:
- **Tính chất xác suất (Non-deterministic)**: Cùng một câu hỏi nhưng mô hình có thể lựa chọn các chuỗi suy luận và công cụ khác nhau tùy thuộc vào ngữ cảnh.
- **Vòng lặp ReAct nhiều bước**: Một lỗi nhỏ ở bước 1 có thể bị khuếch đại qua các bước 2, 3 và dẫn tới kết quả sai lệch hoàn toàn ở bước cuối.
- **Tiến trình chạy ngầm bất đồng bộ**: Các subagents và background tasks hoạt động độc lập, tạo ra nhiều luồng log song song.

Để kiểm soát và khắc phục sự cố, Antigravity CLI cung cấp hệ thống đo lường từ xa (telemetry) và lưu trữ trạng thái toàn diện trong thư mục **Brain**.

---

## 2. Cấu trúc Thư mục Bộ Não (Brain Folder Anatomy)

Mỗi phiên làm việc của Antigravity CLI (kể cả phiên tương tác TUI hay phiên chạy print mode) đều được cấp một mã định danh duy nhất (`session_id`, định dạng UUID). Toàn bộ dữ liệu của phiên được lưu trữ tại:

```text
Windows:  C:\Users\<username>\.gemini\antigravity-cli\brain\<session_id>\
Linux:    ~/.gemini/antigravity-cli/brain/<session_id>/
macOS:    ~/.gemini/antigravity-cli/brain/<session_id>/
```

### 2.1. Giải phẫu chi tiết thư mục session

```text
brain/<session_id>/
├── transcript.jsonl                 # [Tối quan trọng] Nhật ký tuần tự mọi sự kiện của phiên
├── state.json                       # Trạng thái hiện tại của phiên và cấu hình model
├── metadata.json                    # Metadata: thời gian bắt đầu, user, thông số token
└── .system_generated/
    └── tasks/                       # Thư mục lưu log các background processes
        ├── task-1.log               # Nhật ký xuất chuẩn của tiến trình chạy ngầm 1
        ├── task-2.log               # Nhật ký xuất chuẩn của tiến trình chạy ngầm 2
        └── ...
```

- **`transcript.jsonl`**: Bản ghi "hộp đen" của phiên làm việc. Từng câu nói của user, chuỗi suy nghĩ (thinking tokens), lệnh gọi công cụ, tham số và kết quả trả về từ terminal đều được ghi nối tiếp vào đây theo thời gian thực (NDJSON).
- **`.system_generated/tasks/task-<id>.log`**: Khi Agent khởi chạy một lệnh tốn thời gian (biên dịch, test suite, server chạy ngầm) qua `run_command`, toàn bộ `stdout` và `stderr` thô của tiến trình được ghi thẳng vào file log này.

---

## 3. Kỹ thuật Phân tích `transcript.jsonl`

File `transcript.jsonl` được ghi theo chuẩn Newline-Delimited JSON (mỗi dòng là một object JSON hoàn chỉnh).

### 3.1. Cấu trúc một bản ghi sự kiện tiêu chuẩn

```json
{
  "timestamp": "2026-10-30T02:05:12.450Z",
  "turn_id": 4,
  "type": "tool_call",
  "sender": "model",
  "payload": {
    "tool_name": "replace_file_content",
    "parameters": {
      "TargetFile": "D:/Project/src/auth.ts",
      "StartLine": 45,
      "EndLine": 52,
      "TargetContent": "function login() { ... }",
      "ReplacementContent": "function login(credentials: AuthInput) { ... }"
    }
  }
}
```

### 3.2. Kịch bản phân tích bằng PowerShell (Cho Windows 11)

Lập trình viên có thể dùng các lệnh PowerShell một dòng (one-liners) sau để điều tra sự cố:

#### A. Tìm danh sách tất cả các công cụ mà Agent đã gọi trong phiên:
```powershell
$sessionId = "6363c93a-bce4-4ce9-9975-058080bd54c1"
$logPath = "$env:USERPROFILE\.gemini\antigravity-cli\brain\$sessionId\transcript.jsonl"

Get-Content $logPath | ForEach-Object {
    $row = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($row.type -eq "tool_call") {
        [PSCustomObject]@{
            Time = $row.timestamp
            Tool = $row.payload.tool_name
        }
    }
} | Format-Table -AutoSize
```

#### B. Tìm tất cả các lệnh shell mà Agent đã thực thi:
```powershell
Get-Content $logPath | ForEach-Object {
    $row = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($row.type -eq "tool_call" -and $row.payload.tool_name -eq "run_command") {
        $row.payload.parameters.CommandLine
    }
}
```

#### C. Lọc các lỗi (Errors / Exceptions) mà công cụ trả về:
```powershell
Get-Content $logPath | ForEach-Object {
    $row = $_ | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($row.type -eq "tool_result" -and $row.payload.output -match "(error|fail|exception|fatal)") {
        $row.payload.output
    }
}
```

---

## 4. Xử lý Hiện tượng Vòng Lặp Công Cụ Vô Hạn (Infinite Tool Loops)

### 4.1. Bản chất và Nguyên nhân

**Vòng lặp công cụ vô hạn (Tool Loop / Ping-Pong Fix)** xảy ra khi:
1. Agent chạy test và phát hiện lỗi cú pháp A.
2. Agent sửa lỗi A nhưng việc sửa này làm phát sinh lỗi B ở file khác.
3. Agent sửa lỗi B nhưng việc sửa lại làm lỗi A quay trở lại.
4. Agent tiếp tục vòng luẩn quẩn này hàng chục lần mà không nhận ra kiến trúc tổng thể có vấn đề, dẫn đến:
   - Cạn kiệt ngân sách token của người dùng.
   - Thời gian chờ đợi kéo dài vô ích.
   - Nguy cơ làm hỏng thêm nhiều file mã nguồn khác.

### 4.2. Dấu hiệu nhận diện từ sớm

- CLI liên tục gọi `replace_file_content` hoặc `run_command` trên cùng một nhóm file hơn 3 lượt liên tiếp.
- Mô hình liên tục đưa ra lời biện minh giống nhau: *"Đã sửa xong lỗi, bây giờ chạy lại test để kiểm tra..."*.
- Kích thước context tăng vọt bất thường.

### 4.3. Chiến lược Khắc phục & Ngăn chặn

#### Chiến lược 1: Quy tắc 3 Lần Thử (The 3-Strike Rule)
Đưa quy tắc này vào system prompt hoặc [`AGENTS.md`](../AGENTS.md):
> *"Nếu một giải pháp sửa lỗi không vượt qua được kiểm thử sau 3 lần thử liên tiếp, Agent KHÔNG ĐƯỢC PHÉP tiếp tục thử mò. Agent phải dừng lại ngay lập tức, phân tích nguyên nhân tại sao các giả thuyết trước đó sai và yêu cầu người dùng định hướng."*

#### Chiến lược 2: Cài đặt Lifecycle Hook chặn số lần gọi lệnh
Sử dụng `extensions/hooks/` để đếm số lần gọi một tool trong phiên. Nếu vượt quá ngưỡng (ví dụ 15 lần `run_command` cho cùng một test), hook sẽ trả về lỗi cưỡng chế dừng lại.

#### Chiến lược 3: Prompt Can thiệp Ngắt nhịp (Circuit Breaker Prompt)
Nếu phát hiện Agent đang bị kẹt trong vòng lặp khi đang tương tác, người dùng hãy gửi ngay thông điệp sau:
```text
DỪNG LẠI NGAY LẬP TỨC. Không gọi thêm bất kỳ công cụ chỉnh sửa hay chạy test nào nữa.
1. Hãy tóm tắt nguyên nhân cốt lõi khiến 3 lần sửa vừa qua đều thất bại.
2. Liệt kê các giả định bạn đang đưa ra mà có thể đã bị sai.
3. Đề xuất một phương án tiếp cận hoàn toàn mới để tôi xem xét trước khi thực hiện.
```

---

## 5. Khôi phục Phiên Làm Việc Gặp Sự Cố (Crash & Recovery)

Trong quá trình phát triển, phiên làm việc có thể bị gián đoạn đột ngột (mất kết nối mạng, tắt nhầm terminal, crash process hoặc hết pin).

### 5.1. Các bước khôi phục trạng thái

1. **Tìm kiếm Session ID gần nhất**:
   ```powershell
   Get-ChildItem -Path "$env:USERPROFILE\.gemini\antigravity-cli\brain" |
       Sort-Object LastWriteTime -Descending |
       Select-Object -First 3 Name, LastWriteTime
   ```
2. **Kiểm tra trạng thái Git trong dự án**:
   ```powershell
   git status
   git diff
   ```
   Xem xét các thay đổi mà Agent đã thực hiện dở dang trên đĩa. Nếu các thay đổi chưa hoàn chỉnh, có thể hoàn tác an toàn bằng `git restore .`.
3. **Đọc log tác vụ dang dở**:
   Kiểm tra thư mục `.system_generated/tasks/` của session đó để biết lệnh cuối cùng mà Agent thực thi có hoàn tất thành công hay bị ngắt giữa chừng.
4. **Dọn dẹp tiến trình mồ côi (Orphaned Processes)**:
   Nếu Agent từng chạy server hoặc lệnh ngầm (ví dụ `npm run dev` hoặc `docker run`), kiểm tra và tắt các tiến trình này nếu chúng vẫn đang chiếm dụng port:
   ```powershell
   Get-Process -Name node, python, go -ErrorAction SilentlyContinue
   ```

---

## 6. Liên kết tham chiếu trong bộ tài liệu

- Xem lý thuyết nhận thức và cơ chế ReAct: [`KIEN_TRUC_AI_AGENT.md`](KIEN_TRUC_AI_AGENT.md)
- Xem thông số kỹ thuật runtime Antigravity: [`ANTIGRAVITY_RUNTIME_SPEC.md`](ANTIGRAVITY_RUNTIME_SPEC.md)
- Xem hệ thống an toàn và phòng thủ đa tầng: [`AN_TOAN_VA_PHONG_THU_DA_TANG.md`](AN_TOAN_VA_PHONG_THU_DA_TANG.md)
- Xem hướng dẫn tích hợp và tạo prompt chuẩn: [`HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md`](HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md)
