# An Toàn & Phòng Thủ Đa Tầng Cho AI Agent (Defense-in-Depth)

Tài liệu này đặc tả kiến trúc bảo mật 4 lớp được thiết kế để bảo vệ mã nguồn, dữ liệu và hệ điều hành khi sử dụng AI Pair Programming với Google Antigravity CLI (`agy 1.4.10`).

---

## 1. Triết lý Phòng thủ Đa tầng trong Agentic AI

### 1.1. Các mối đe dọa an toàn đặc thù của AI Agent

Khi trao quyền cho một AI Agent thực thi lệnh trên hệ điều hành và sửa đổi file trong workspace, hệ thống đối mặt với những rủi ro an ninh mới mà các công cụ phần mềm truyền thống không gặp phải:
1. **Prompt Injection gián tiếp (Indirect Prompt Injection)**: Kẻ tấn công chèn các câu lệnh độc hại vào mã nguồn mở bên ngoài, comment trong code, file README hoặc log hệ thống. Khi Agent đọc file này, nó có thể bị thao túng và thực hiện các hành vi nguy hiểm.
2. **Ảo giác dẫn đến hành vi phá hủy (Hallucination-Induced Destruction)**: Agent suy đoán sai trạng thái và tự ý chạy các lệnh định dạng lại git (`git reset --hard`), xóa thư mục đệ quy (`rm -rf`) hoặc drop bảng cơ sở dữ liệu.
3. **Rò rỉ Bí mật (Secret Exfiltration)**: Agent vô tình đọc nội dung file cấu hình chứa token (`.env`, `credentials.json`) và in ra màn hình console, đẩy vào log hoặc commit vào git history.

### 1.2. Nguyên tắc Bất biến: Không tin cậy tuyệt đối vào LLM

> [!CAUTION]
> **Không bao giờ chỉ dựa vào lời dặn trong prompt để bảo đảm an toàn.**
> Mô hình ngôn ngữ lớn (LLM) là một hệ thống xác suất, có thể bị vượt rào (jailbreak) hoặc nhầm lẫn ngữ cảnh. Một kiến trúc an toàn bắt buộc phải kết hợp **Prompt Directives** với các **rào chắn lập trình tất định (Deterministic Gates)** ở cấp độ runtime và hệ điều hành.

Mô hình phòng thủ 4 lớp trong Antigravity Template được thiết kế theo nguyên lý **Defense-in-Depth (Phòng thủ theo chiều sâu)**: Nếu một lớp phòng thủ bị vượt qua, các lớp phía sau vẫn kiên quyết ngăn chặn hành vi độc hại.

```text
       ┌────────────────────────────────────────────────────────┐
       │ Lớp 1: Prompt Rules & Instructions (AGENTS.md, Rules)  │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ Lớp 2: Lifecycle Hooks (PreToolUse, PostToolUse, Stop) │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ Lớp 3: Permissions & Access Policies (Least Privilege) │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ Lớp 4: OS Sandboxing & Environment Isolation           │
       └────────────────────────────────────────────────────────┘
```

---

## 2. Lớp 1: Prompt Rules & Chỉ dẫn Cốt lõi (Instruction Layer)

Lớp bảo vệ đầu tiên định hình nhận thức và thiết lập ranh giới đạo đức cho Agent ngay tại gốc suy luận:

### 2.1. Hiến pháp Workspace: `AGENTS.md`
- Nằm trực tiếp tại gốc workspace và được tự động nạp cho toàn bộ các lượt trò chuyện của mọi agent.
- Thiết lập nguyên tắc bất biến:
  - Cấm tuyệt đối các lệnh Git mang tính phá hủy (`git reset --hard`, `git push --force`, `git clean -fdx`).
  - Cấm ghi đè hoặc commit thông tin bí mật.
  - Tuân thủ nguyên tắc thay đổi tập trung (Focused Diff).

### 2.2. Quy tắc Bất biến `trigger: always_on`
- Nằm trong file [`.agents/rules/security-and-secrets.md`](../.agents/rules/security-and-secrets.md).
- Luôn luôn hiện diện trong mọi turn, chia sẻ trong ngân sách 24 KB / 20,000 token của Google.
- Quy định chi tiết các mẫu secret cấm xuất hiện (Private Keys, API Keys, DB Passwords) và danh sách đen các lệnh OS nguy hiểm (`DROP DATABASE`, format ổ đĩa, xóa thư mục gốc).

### 2.3. Phân quyền Tối thiểu (Least Privilege) cho Subagents
- Trong cấu hình YAML frontmatter của custom subagent, trường `tools` chỉ được khai báo đúng những công cụ cần thiết cho vai trò đó.
- **Ví dụ điển hình**: Agent [`.agents/agents/code-reviewer.md`](../.agents/agents/code-reviewer.md) chỉ sở hữu duy nhất quyền `view_file`. Agent này hoàn toàn bất lực nếu muốn sửa file hoặc chạy lệnh terminal, loại bỏ 100% rủi ro tự ý can thiệp mã nguồn khi làm nhiệm vụ đánh giá.

---

## 3. Lớp 2: Lifecycle Hooks (Runtime Inspection Layer)

Lifecycle Hooks là các cổng chặn tự động thực thi script shell bên ngoài mà **không phụ thuộc vào suy luận của LLM**. Cấu hình mẫu được cung cấp tại [`extensions/hooks/hooks.example.json`](../extensions/hooks/hooks.example.json).

```text
 Agent dự định gọi Tool ──► [PreToolUse Hook] ──► Chấp thuận? ──► Thực thi Tool
                                  │
                                  ▼ (Nếu từ chối)
                          Dừng lệnh & Báo lỗi
```

### 3.1. Cổng chặn tiền kiểm tra: `PreToolUse`
- Kích hoạt ngay trước khi Antigravity CLI gửi lệnh xuống hệ điều hành.
- **Ứng dụng an toàn (`matcher: run_command`)**:
  - Script tiền kiểm tra (như `safety-check.ps1` hoặc `safety-check.sh`) phân tích chuỗi lệnh shell được Agent yêu cầu.
  - Nếu phát hiện các pattern nguy hiểm như `rm -rf`, `DROP TABLE`, `git reset`, script trả về exit code khác 0 kèm thông báo từ chối. Lệnh bị hủy bỏ ngay lập tức trước khi kịp gây hại cho hệ thống.

### 3.2. Cổng hậu kiểm tra: `PostToolUse`
- Kích hoạt ngay sau khi một công cụ hoàn tất hành động.
- **Ứng dụng kiểm soát chất lượng & bảo mật (`matcher: file_change`)**:
  - Tự động chạy linter hoặc secret scanner ngay sau khi Agent tạo hoặc sửa file mã nguồn.
  - Nếu phát hiện vô tình chèn API Key vào code, hook có thể tự động rollback hoặc cảnh báo ngay lập tức.

### 3.3. Cổng chốt chặn hoàn tất: `Stop`
- Kích hoạt khi Agent định kết thúc phiên làm việc.
- Kiểm tra xem toàn bộ unit test có pass hay không, hoặc kiểm tra xem còn file rác chưa được dọn dẹp hay không trước khi trả quyền điều khiển lại cho lập trình viên.

---

## 4. Lớp 3: Chính sách Phân quyền & Quản trị Quyền truy cập (Permissions Policies)

Lớp thứ ba kiểm soát quyền gọi công cụ và cơ chế tương tác với người dùng tại runtime:

### 4.1. Cơ chế Cửa kiểm duyệt Quyền hạn (`ask_permission`)
- Khi một tác vụ yêu cầu hành động nằm ngoài danh mục được phê duyệt tự động (ví dụ: truy cập thư mục bên ngoài workspace, thực thi binary lạ, hoặc kết nối mạng ra domain chưa cấp phép), Antigravity sẽ kích hoạt cổng `ask_permission`.
- Lập trình viên nhận được thông báo rõ ràng về:
  - Hành động cụ thể (Action: `run_command`, `write_file`, `unsandboxed`...).
  - Mục tiêu (Target: đường dẫn file hoặc tiền tố lệnh).
  - Lý do (Reason) mà Agent yêu cầu quyền này.
- Chỉ khi người dùng bấm chấp thuận, lệnh mới được giải phóng.

### 4.2. Nguyên tắc Phạm vi Hẹp nhất (Narrowest Scope Principle)
- Khi xin cấp quyền hoặc cấu hình chính sách, không bao giờ dùng ký tự đại diện toàn cục (`*`) hoặc cấp quyền cho toàn bộ ổ đĩa (`C:\` hay `/`).
- Luôn giới hạn quyền trong một thư mục con cụ thể của dự án (ví dụ `write_file` chỉ trong `src/modules/auth/`).

---

## 5. Lớp 4: OS Sandboxing & Cô lập Môi trường (Environment Isolation)

Lớp phòng vệ cuối cùng bảo vệ hệ điều hành của máy trạm khỏi bất kỳ sự cố ngoài ý muốn nào:

### 5.1. Terminal Sandbox của Antigravity CLI
- Mọi lệnh thực thi qua công cụ terminal mặc định đều chạy bên trong một session shell cô lập với thời gian chờ (timeout) kiểm soát chặt chẽ.
- Thay đổi biến môi trường (environment variables) hoặc thư mục làm việc (`cd`) trong một lệnh không tự ý làm ô nhiễm shell chính của hệ điều hành.

### 5.2. Phân định giữa Sandboxed và Unsandboxed Execution
- Các lệnh thông thường (chạy compiler, test suite, format) chạy an toàn trong sandbox.
- Các lệnh đòi hỏi quyền can thiệp sâu vào hệ thống (`unsandboxed`) bắt buộc phải được người dùng xem xét và phê duyệt riêng biệt.

### 5.3. Cô lập Hệ thống Tệp (Filesystem Path Confinement)
- Runtime kiểm tra và ngăn chặn các kỹ thuật tấn công Path Traversal (như `../../../../Windows/System32/`).
- Mọi thao tác chỉnh sửa mã nguồn được neo (anchored) chặt chẽ vào Workspace Root của repository hiện hành.

---

## 6. Sổ tay Ứng phó Sự cố An toàn (Incident Response Playbook)

Ngay cả với hệ thống phòng thủ tốt nhất, lập trình viên vẫn cần nắm rõ quy trình xử lý khi phát hiện bất thường:

### 6.1. Sự cố 1: Phát hiện vô tình rò rỉ Secret / API Key
1. **Thu hồi lập tức (Revoke Immediately)**: Truy cập trang quản trị của nhà cung cấp dịch vụ (Google Cloud Console, GitHub, AWS, Stripe) và vô hiệu hóa ngay API key hoặc token vừa bị lộ.
2. **Loại bỏ khỏi lịch sử Git**:
   - Nếu commit chưa bị đẩy lên remote: Dùng `git commit --amend` hoặc `git reset HEAD~1` để xóa bỏ.
   - Nếu commit đã được push: Sử dụng công cụ chuyên dụng như `git-filter-repo` hoặc BFG Repo-Cleaner để làm sạch hoàn toàn lịch sử commit.
3. **Kiểm tra Session Log**: Xem file `transcript.jsonl` trong thư mục `brain/` để xác định chính xác secret đã bị phơi bày ở những turn nào.

### 6.2. Sự cố 2: Agent sửa code gây hỏng logic diện rộng (Regression)
1. **Kiểm tra trạng thái Git**:
   ```powershell
   git status
   git diff
   ```
2. **Khôi phục về trạng thái sạch gần nhất**:
   ```powershell
   # Khôi phục các file chưa commit về trạng thái ban đầu an toàn
   git restore .
   ```
3. **Phân tích nguyên nhân trong `transcript.jsonl`**: Kiểm tra lại prompt ban đầu xem có thiếu tiêu chí nghiệm thu (Verification Criteria) hoặc thiếu ràng buộc (Constraints) hay không.

---

## 7. Liên kết tham chiếu trong bộ tài liệu

- Xem lý thuyết nhận thức và cơ chế ReAct: [`KIEN_TRUC_AI_AGENT.md`](KIEN_TRUC_AI_AGENT.md)
- Xem thông số kỹ thuật runtime Antigravity: [`ANTIGRAVITY_RUNTIME_SPEC.md`](ANTIGRAVITY_RUNTIME_SPEC.md)
- Xem hướng dẫn gỡ lỗi và phân tích transcript: [`SO_TAY_DEBUG_VA_QUAN_SAT.md`](SO_TAY_DEBUG_VA_QUAN_SAT.md)
- Xem hướng dẫn tích hợp và tạo prompt chuẩn: [`HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md`](HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md)
