# Đặc Tả Runtime Antigravity CLI — Thông Số Kỹ Thuật & Vận Hành

Tài liệu này cung cấp đặc tả kỹ thuật chi tiết về cơ chế vận hành của Google Antigravity CLI (`agy 1.4.10`), bao gồm các chế độ thực thi, cấu hình suy luận, giao thức truyền thông Stream-JSON, lộ trình chuyển đổi từ Workflows sang Skills và thứ tự nạp tài nguyên.

---

## 1. Tổng quan Runtime & Môi trường thực thi

Google Antigravity CLI (`agy`) là môi trường runtime chuyên dụng để chạy các mô hình AI sinh mã hàng đầu của Google (dòng mô hình Gemini 3.8, Gemini 3.0, Gemini 2.5 Flash và Pro) trực tiếp trên máy trạm của lập trình viên hoặc trong môi trường máy chủ CI/CD.

### 1.1. Cơ chế xác định Workspace Root

Antigravity CLI hoạt động theo nguyên tắc **Project-Centric (Lấy dự án làm trọng tâm)**:
1. Khi khởi chạy lệnh `agy`, runtime sẽ kiểm tra thư mục làm việc hiện tại (`Current Working Directory - CWD`).
2. Nếu không tìm thấy dấu hiệu quản lý phiên bản (chủ yếu là thư mục `.git`), runtime sẽ duyệt ngược (traverse up) từng cấp thư mục cha để tìm kiếm `.git`.
3. Điểm dừng chứa `.git` được xác định là **Workspace Root**.
4. Mọi đường dẫn tương đối tới `.agents/`, `AGENTS.md`, các rules, skills, và subagents đều được phân giải dựa trên Workspace Root này.

> [!IMPORTANT]
> Luôn khởi tạo Git repository (`git init`) trong thư mục dự án trước khi sử dụng Antigravity CLI để runtime có thể định vị chính xác cấu trúc `.agents/`.

---

## 2. Các chế độ thực thi (Execution Modes — `--mode`)

Antigravity CLI cung cấp 3 chế độ thực thi thông qua cờ `--mode`, cho phép lập trình viên kiểm soát mức độ tự chủ của Agent tùy theo tính chất tác vụ và môi trường triển khai:

| Chế độ (`--mode`) | Mức độ tự chủ | Hành vi sửa file | Khi nào nên dùng? |
|---|---|---|---|
| `auto` (Mặc định) | **Cao** | Thực hiện trực tiếp các thay đổi an toàn; chỉ dừng xin phép khi gặp lệnh nguy hiểm hoặc tool nhạy cảm. | Lập trình hàng ngày, phát triển tính năng mới, sửa bug thông thường. |
| `plan` | **Không sửa đổi** | Hoàn toàn Read-Only đối với mã nguồn; chỉ xuất kế hoạch hành động chi tiết. | Khảo sát codebase lớn, thiết kế kiến trúc, đánh giá rủi ro trước khi bắt tay làm. |
| `accept-edits` | **Kiểm duyệt từng bước** | Đề xuất diff và yêu cầu người dùng xác nhận trước khi áp dụng vào disk. | Dự án sản xuất (production), refactor mã nguồn lõi, kiểm soát chất lượng khắt khe. |

### 2.1. Chế độ Mặc định: `--mode auto`
```powershell
agy --mode auto -p "Viết unit test cho AuthService"
```
- Agent tự động đọc các file liên quan, viết code test mới, chạy lệnh test bằng công cụ terminal để xác minh.
- Nếu Agent cần thực hiện thao tác có nguy cơ cao (như cài đặt thư viện toàn cục, chạy lệnh hệ thống chưa được cấp phép trong policy), runtime sẽ dừng lại để xin phép người dùng.

### 2.2. Chế độ Lập kế hoạch: `--mode plan`
```powershell
agy --mode plan -p "Thiết kế kế hoạch chuyển đổi cơ sở dữ liệu từ SQLite sang PostgreSQL"
```
- Runtime vô hiệu hóa toàn bộ các công cụ ghi file (`write_to_file`, `replace_file_content`) hoặc đặt chúng ở chế độ mô phỏng (dry-run).
- Agent chỉ sử dụng các công cụ khảo sát (`view_file`, `find_by_name`, `grep_search`) để tìm hiểu hiện trạng.
- Kết quả đầu ra là một tài liệu kế hoạch hành động hoàn chỉnh (Action Plan / RFC) gồm danh sách file cần sửa, rủi ro tiềm ẩn, thứ tự từng bước và tiêu chuẩn kiểm thử.

### 2.3. Chế độ Kiểm duyệt từng sửa đổi: `--mode accept-edits`
```powershell
agy --mode accept-edits -p "Refactor toàn bộ layer truy cập cơ sở dữ liệu"
```
- Khi Agent chuẩn bị thay đổi nội dung một file, runtime sẽ hiển thị bản so sánh chi tiết (Git diff) trên giao diện terminal.
- Người dùng có thể nhấn `[y]` để chấp nhận, `[n]` để từ chối, hoặc nhập thêm phản hồi để Agent điều chỉnh lại diff.

---

## 3. Cấu hình Mức độ Suy luận (Reasoning Effort — `--effort`)

Các mô hình Gemini thế hệ mới sở hữu khả năng suy luận mở rộng (Thinking Process). Lượng token dành cho suy luận được kiểm soát linh hoạt qua cờ `--effort`:

```powershell
agy --model gemini-3.8-flash-high --effort high
```

### 3.1. Phân loại các mức Effort

Antigravity CLI 1.4.10 hỗ trợ 5 mức suy luận:

| Mức Effort | Ngân sách suy luận | Độ trễ phản hồi | Mục đích sử dụng |
|---|---|---|---|
| `--effort low` | Tối thiểu (~1k–2k thinking tokens) | Nhanh nhất (< 2s) | Tra cứu nhanh cú pháp, giải thích hàm ngắn, đổi tên biến, sửa lỗi chính tả. |
| `--effort medium` (Mặc định) | Tiêu chuẩn (~4k–8k thinking tokens) | Trung bình (3s–8s) | Viết hàm nghiệp vụ mới, viết unit test, sửa bug đã rõ nguyên nhân. |
| `--effort high` | Sâu (~16k–32k thinking tokens) | Kỹ lưỡng (10s–30s) | Gỡ lỗi race condition phức tạp, tối ưu thuật toán, kiến trúc hệ thống phân tán, kiểm định an ninh bảo mật. |
| `--effort xhigh` | Rất sâu (~32k–64k thinking tokens) | Chuyên sâu (30s–60s) | Tái cấu trúc toàn diện module lớn, giải quyết mâu thuẫn phụ thuộc chéo, suy luận chuỗi dài. |
| `--effort max` | Tối đa ngân sách của mô hình | Lâu nhất | Chứng minh hình thức, audit bảo mật cấp độ cao nhất, giải quyết bài toán thuật toán cực khó. |

### 3.2. Phân định rạch ròi giữa Model ID, Effort và Subagent Tier

Đây là một trong những điểm hay gây nhầm lẫn nhất khi cấu hình Antigravity:

```text
Cấu hình cấp CLI (Session level):
   agy --model gemini-3.8-flash-high --effort high
        │                            │
        │                            └── Mức độ suy luận (low | medium | high | xhigh | max)
        └─────────────────────────────── Model ID cụ thể của Google

Cấu hình cấp Subagent (.agents/agents/<name>.md):
   ---
   name: code-reviewer
   model: inherit   <── Chỉ nhận tier: inherit | flash | pro | flash_lite
   ---
   (TUYỆT ĐỐI KHÔNG ghi model ID hoặc effort vào frontmatter)
```

- **`--model` (Cờ CLI)**: Nhận ID mô hình cụ thể của Google (ví dụ `gemini-3.8-flash-high`, `gemini-3.8-flash-medium`, `gemini-3.8-flash-low`, `gpt-oss-120b-medium`).
- **`--effort` (Cờ CLI)**: Thiết lập ngân sách suy luận cho phiên làm việc (`low`, `medium`, `high`, `xhigh`, `max`).
- **`model` (YAML frontmatter)**: Chỉ định phân tầng trừu tượng (Tier: `inherit`, `flash`, `pro`, `flash_lite`). Subagent nên để `inherit` để kế thừa model và effort do người dùng truyền vào từ CLI.

---

## 4. Giao thức Truyền thông Stream-JSON & CLI Automation Flags

Antigravity CLI hỗ trợ hai giao diện vận hành chính:
1. **Interactive TUI (Terminal User Interface)**: Giao diện tương tác trực tiếp với người dùng, hiển thị thanh tiến trình, cây suy luận có thể đóng/mở và màu sắc trực quan.
2. **Non-Interactive Print Mode (`agy -p "..."`)**: Chế độ chạy một lượt (single-turn) thích hợp cho kịch bản tự động hóa, hook shell hoặc CI/CD pipeline.

### 4.1. Các Cờ Lệnh CLI Cho Tự Động Hóa & Tích Hợp Hệ Thống

| Cờ Lệnh (CLI Flag) | Giá trị hỗ trợ | Mô tả chức năng |
|---|---|---|
| `--output-format` | `text` (mặc định), `json`, `stream-json` | Định dạng dữ liệu xuất ra stdout. Dùng `stream-json` để nhận luồng NDJSON thời gian thực. |
| `--input-format` | `text` (mặc định), `stream-json` | Định dạng dữ liệu nhận từ stdin. Yêu cầu `--output-format stream-json` khi dùng `stream-json`. |
| `--json-schema` | Đường dẫn file hoặc chuỗi schema | Ép buộc cấu trúc JSON đầu ra cuối cùng phải tuân thủ schema quy định. |
| `--dangerously-skip-permissions` | Cờ bật/tắt (boolean flag) | Tự động phê duyệt mọi yêu cầu quyền truy cập tool (chỉ dùng trong môi trường CI/CD sandbox an toàn). |
| `--print-timeout` | Thời lượng (ví dụ `120s`, `5m`) | Giới hạn thời gian chạy cho print mode; giá trị `0` (mặc định) chờ cho đến khi hoàn thành turn. |
| `--mode` | `auto`, `plan`, `accept-edits` | Xác định mức độ tự chủ can thiệp file mã nguồn của agent trong phiên. |

### 4.2. Giao thức Stream-JSON (NDJSON / SSE)

Khi được gọi với cờ `--output-format stream-json`, runtime giao tiếp qua các dòng JSON độc lập (Newline-Delimited JSON - NDJSON). Mỗi dòng đại diện cho một sự kiện trong vòng đời nhận thức của Agent:

```json
{"event": "session_init", "session_id": "6363c93a-bce4-4ce9-9975-058080bd54c1", "timestamp": "2026-10-30T02:00:00Z"}
{"event": "turn_start", "turn_id": 1, "sender": "user"}
{"event": "model_thought", "content": "Phân tích yêu cầu... Cần kiểm tra cấu trúc thư mục trước."}
{"event": "tool_call", "tool": "find_by_name", "arguments": {"SearchDirectory": "D:/Project", "Pattern": "*.json"}}
{"event": "tool_result", "tool": "find_by_name", "output": ["package.json", "tsconfig.json"]}
{"event": "model_message", "content": "Đã tìm thấy các file cấu hình dự án."}
{"event": "turn_complete", "turn_id": 1, "tokens_used": {"prompt": 1250, "completion": 340}}
```

### 4.3. Kịch Bản Tích Hợp CI/CD Headless Thực Chiến

#### Ví dụ A: Chạy Code Review Tự động và Xuất JSON Trong CI Pipeline
```powershell
# Chạy đánh giá và nhận output dạng Stream-JSON
agy --agent code-reviewer -p "Đánh giá các file đã sửa trong pull request" --output-format stream-json --dangerously-skip-permissions --print-timeout 180s
```

#### Ví dụ B: Bắt buộc Đầu ra Tuân theo Schema Cấu Trúc Báo Cáo
```powershell
agy -p "Phân tích rủi ro bảo mật của repo" --output-format json --json-schema ./schemas/security-audit-schema.json --dangerously-skip-permissions
```

---

## 5. Chuyển đổi từ Workflows sang Skills (Workflows Deprecation)

### 5.1. Bối cảnh lịch sử và Lý do loại bỏ Workflows

Ở các phiên bản CLI ban đầu, Antigravity từng hỗ trợ thư mục `.agents/workflows/`. Tuy nhiên, cấu trúc này đã chính thức bị **Deprecate (Khai tử)** để chuyển hoàn toàn sang chuẩn **Skills** (`.agents/skills/`) vì các hạn chế sau:
- **Tính cứng nhắc của Workflow**: Workflows cũ quy định danh sách các bước tuần tự cố định bằng YAML, biến Agent thành một script thực thi máy móc và làm triệt tiêu khả năng suy luận thích ứng (adaptive reasoning) của LLM.
- **Lãng phí Context**: Toàn bộ nội dung của mọi workflow đều bị nạp vào context ngay khi bắt đầu phiên, gây lãng phí nghiêm trọng ngân sách token.
- **Thiếu khả năng mở rộng**: Workflow không hỗ trợ cấu trúc phân cấp chứa mã nguồn tiện ích (`scripts/`), tài liệu tham chiếu (`references/`) hoặc tài sản kiểm thử (`examples/`).

### 5.2. Sự vượt trội của hệ thống Skills (`.agents/skills/`)

Chuẩn **Skills** của Google mang lại 3 ưu thế vượt bậc:
1. **Kích hoạt dựa trên Ngữ nghĩa (Semantic Activation)**: LLM tự quyết định khi nào cần kích hoạt Skill dựa vào trường `description` trong YAML frontmatter mà không cần người dùng phải gọi tên lệnh một cách máy móc.
2. **Cơ chế Progressive Disclosure**: Ban đầu runtime chỉ nạp metadata của Skill. Nội dung chi tiết trong `SKILL.md` và các script con chỉ được nạp vào context khi Agent thực sự cần dùng.
3. **Tính độc lập & Tái sử dụng**: Thư mục Skill đóng gói trọn vẹn cả hướng dẫn, mã lệnh chạy tự động và mẫu tham chiếu, cho phép dễ dàng sao chép giữa các dự án hoặc đóng gói vào Plugin.

### 5.3. Bảng đối chiếu chuyển đổi (Migration Matrix)

| Thành phần cũ (Workflows - Bị loại bỏ) | Thành phần chuẩn mới (Skills - Google Spec) |
|---|---|
| Đường dẫn `.agents/workflows/<name>.yaml` | Thư mục `.agents/skills/<name>/` |
| File định nghĩa duy nhất `.yaml` | File chính `SKILL.md` có YAML frontmatter |
| Kích hoạt máy móc theo tên lệnh | Kích hoạt tự động qua `description` ngữ nghĩa |
| Script nhúng chuỗi thô trong YAML | Thư mục chuyên dụng `scripts/` độc lập |
| Tài liệu nhồi nhét vào system prompt | Thư mục `references/` nạp dần theo nhu cầu |

---

## 6. Thứ tự Nạp Cấu hình & Mức độ Ưu tiên (Discovery & Precedence)

Khi khởi động phiên làm việc, Antigravity CLI nạp các chỉ dẫn và quy tắc theo thứ tự ưu tiên từ thấp đến cao (càng ở sau càng có quyền ghi đè):

```text
       ┌────────────────────────────────────────────────────────┐
       │ 1. Cấu hình Toàn cục (Global): ~/.gemini/config/       │ (Thấp nhất)
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ 2. Workspace Plugins: .agents/plugins/<name>/          │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ 3. Chỉ dẫn Workspace Root: AGENTS.md                   │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ 4. Quy tắc Bất biến: .agents/rules/ (always_on)        │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ 5. Quy tắc Động: .agents/rules/ (glob, model_decision) │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ 6. Năng lực Theo nhu cầu: .agents/skills/              │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ 7. Custom Subagents: .agents/agents/<name>.md          │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ 8. Yêu cầu Người dùng Hiện tại: <USER_REQUEST>         │ (Cao nhất)
       └────────────────────────────────────────────────────────┘
```

Quy luật ưu tiên:
- `USER_REQUEST` có thẩm quyền chỉ đạo cao nhất cho bài toán nghiệp vụ hiện tại, nhưng **không thể** ép Agent vi phạm các quy tắc bảo mật bất biến trong [`security-and-secrets.md`](../.agents/rules/security-and-secrets.md).
- Quy tắc trong workspace dự án luôn ghi đè quy tắc cấu hình toàn cục trên máy phát triển cá nhân.

---

## 7. Liên kết tham chiếu trong bộ tài liệu

- Xem lý thuyết nhận thức và kiến trúc đa đặc vụ: [`KIEN_TRUC_AI_AGENT.md`](KIEN_TRUC_AI_AGENT.md)
- Xem kiến trúc phòng thủ đa tầng: [`AN_TOAN_VA_PHONG_THU_DA_TANG.md`](AN_TOAN_VA_PHONG_THU_DA_TANG.md)
- Xem hướng dẫn gỡ lỗi và telemetry: [`SO_TAY_DEBUG_VA_QUAN_SAT.md`](SO_TAY_DEBUG_VA_QUAN_SAT.md)
- Xem quy trình tích hợp và khung tạo prompt chuẩn: [`HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md`](HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md)
