# Hướng Dẫn Sử Dụng Project Template Chuẩn — Antigravity CLI

Tài liệu hướng dẫn triển khai, sử dụng và tùy biến template dự án cho Google Antigravity CLI (`agy 1.4.10`).

---

## 1. Mục đích và Phạm vi sử dụng

- **Mục đích**: Cung cấp bộ khung cấu hình nền tảng, độc lập công nghệ, tuân thủ tài liệu chính thức của Google cho Antigravity CLI, giúp nhà phát triển dễ dàng tích hợp AI pair programmer vào bất kỳ dự án phần mềm nào (Node.js, Python, Go, Java, .NET, Rust,...).
- **Phạm vi**: Cấu hình cấp workspace/repository. Không can thiệp vào cấu hình người dùng (`~/.gemini/config/`), không yêu cầu dịch vụ bên ngoài, không phụ thuộc vào Claude Code hoặc các dịch vụ trả phí.

---

## 2. Cấu trúc thư mục Template

```text
antigravity-project-template/
├── AGENTS.md                                   # [Bắt buộc] Hướng dẫn chung toàn workspace
├── .agents/                                    # Thư mục cấu hình Antigravity của workspace
│   ├── rules/                                  # Quy tắc kiểm soát hành vi theo context
│   │   ├── security-and-secrets.md             # Rule bảo mật (always_on)
│   │   └── code-quality.md                     # Rule chất lượng code (glob)
│   ├── skills/                                 # Quy trình, runbook chuyên biệt (progressive)
│   │   └── project-onboarding/
│   │       └── SKILL.md                        # Skill khảo sát và tiếp nhận dự án
│   └── agents/                                 # Custom subagents
│       └── code-reviewer.md                    # Agent thẩm định mã nguồn (read-only)
├── extensions/                                 # [Tùy chọn] Mở rộng khi dự án cần
│   ├── mcp/                                    # Mẫu cấu hình MCP server
│   ├── hooks/                                  # Mẫu cấu hình Lifecycle Hooks
│   └── plugin/                                 # Mẫu đóng gói Plugin chia sẻ nội bộ
├── docs/                                       # Tài liệu hướng dẫn & kiến trúc
│   ├── HUONG_DAN_SU_DUNG.md                    # Hướng dẫn này
│   ├── HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md   # Cẩm nang tích hợp dự án & khung tạo prompt COCV
│   ├── KIEN_TRUC_AI_AGENT.md                   # Kiến trúc nhận thức ReAct, Multi-Agent & Token budget
│   ├── ANTIGRAVITY_RUNTIME_SPEC.md             # Đặc tả runtime, modes, effort, Stream-JSON
│   ├── AN_TOAN_VA_PHONG_THU_DA_TANG.md         # Kiến trúc an toàn & phòng thủ 4 lớp
│   ├── SO_TAY_DEBUG_VA_QUAN_SAT.md             # Sổ tay gỡ lỗi, telemetry, transcript analysis
│   ├── QUYET_DINH_THIET_KE.md                  # Ghi nhận quyết định thiết kế (ADR)
│   └── MA_TRAN_KIEM_THU.md                     # Ma trận kiểm thử & kết quả thực tế
└── tests/                                      # Bộ script kiểm tra tính hợp lệ tự động
    ├── test_template.ps1                       # Script kiểm tra cấu trúc & schema
    └── fixtures/                               # Dữ liệu kiểm thử âm tính (negative tests)
```

---

## 3. Ý nghĩa từng file & Phân loại thành phần

| File / Thư mục | Phân loại | Mục đích sử dụng | Khi nào có thể bỏ? |
|---|---|---|---|
| `AGENTS.md` | **Cốt lõi (Bắt buộc)** | Chỉ dẫn nền tảng, router điều hướng, ranh giới an toàn chung. | Không nên bỏ. |
| `.agents/rules/security-and-secrets.md` | **Cốt lõi** | Ngăn rò rỉ secret, chặn lệnh git/hệ thống phá hủy (`always_on`). | Khi có sandbox cứng thay thế. |
| `.agents/rules/code-quality.md` | **Cốt lõi** | Quy chuẩn chất lượng mã nguồn khi sửa code (`glob`). | Khi CI/CD đã có linter bắt buộc. |
| `.agents/skills/project-onboarding/` | **Cốt lõi mẫu** | Runbook từng bước giúp agent tự khảo sát repository mới. | Khi repo đã hoàn thiện cấu hình. |
| `.agents/agents/code-reviewer.md` | **Cốt lõi mẫu** | Subagent đọc và đánh giá code (chỉ cấp `view_file`). | Khi dự án chỉ dùng single agent. |
| `docs/HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md` | **Tài liệu cốt lõi** | Quy trình 4 bước tích hợp dự án mới & thư viện mẫu prompt COCV. | Giữ làm tài liệu tham chiếu. |
| `docs/KIEN_TRUC_AI_AGENT.md` | **Tài liệu kiến trúc** | Lý thuyết ReAct, Multi-Agent patterns, Memory Hierarchy. | Giữ làm tài liệu tham chiếu. |
| `docs/ANTIGRAVITY_RUNTIME_SPEC.md` | **Tài liệu kỹ thuật** | Đặc tả runtime: modes (`auto`/`plan`/`accept-edits`), `--effort`. | Giữ làm tài liệu tham chiếu. |
| `docs/AN_TOAN_VA_PHONG_THU_DA_TANG.md` | **Tài liệu bảo mật** | Kiến trúc an toàn 4 lớp: Prompt, Hooks, Permissions, Sandbox. | Giữ làm tài liệu tham chiếu. |
| `docs/SO_TAY_DEBUG_VA_QUAN_SAT.md` | **Tài liệu vận hành** | Hướng dẫn debug, phân tích `transcript.jsonl`, trị loop vô hạn. | Giữ làm tài liệu tham chiếu. |
| `extensions/mcp/` | **Mở rộng tùy chọn** | Kết nối agent với DB, Jira, GitHub hoặc service ngoài. | Khi dự án không dùng server MCP. |
| `extensions/hooks/` | **Mở rộng tùy chọn** | Can thiệp tự động vào vòng lặp agent (`PreToolUse`, `Stop`...). | Khi không cần hook tự động. |
| `extensions/plugin/` | **Mở rộng tùy chọn** | Đóng gói bộ công cụ dùng chung cho nhiều repo. | Khi chỉ dùng cho 1 repo đơn lẻ. |
| `tests/` | **Kiểm thử** | Xác minh tính hợp lệ của template trước khi release/commit. | Có thể giữ lại để chạy định kỳ. |

---

## 4. Cách sao chép Template vào Dự án mới

Thực hiện theo các bước sau trong PowerShell:

```powershell
# 1. Đi đến thư mục dự án mới của bạn
cd D:\Project\my-new-project

# 2. Khởi tạo Git nếu dự án chưa có (Antigravity dùng .git để định vị root)
git init

# 3. Sao chép các thành phần cốt lõi từ template
Copy-Item -Path "path\to\antigravity-project-template\AGENTS.md" -Destination ".\AGENTS.md"
Copy-Item -Path "path\to\antigravity-project-template\.agents" -Destination ".\" -Recurse

# 4. (Tùy chọn) Sao chép bộ kiểm tra chất lượng
Copy-Item -Path "path\to\antigravity-project-template\tests" -Destination ".\" -Recurse

# 5. Chạy kiểm tra tính hợp lệ
powershell -ExecutionPolicy Bypass -File .\tests\test_template.ps1
```

---

## 5. Hướng dẫn tùy chỉnh theo đặc thù dự án

### 5.1. Tùy chỉnh `AGENTS.md`
- Cập nhật mục **3. Quy trình làm việc chuẩn** để bổ sung các lệnh chạy build, test đặc thù:
  - Dự án Node.js: `npm test`, `npm run build`
  - Dự án Python: `pytest`, `ruff check .`
  - Dự án Go: `go test ./...`, `golangci-lint run`
- Giữ file trong ngân sách độ dài khuyến nghị (~50–100 dòng). Không dán toàn bộ tài liệu kỹ thuật vào đây; hãy dùng Skill hoặc file tham chiếu ngoài.

### 5.2. Thêm Rule mới đúng chuẩn
- Tạo file `.agents/rules/<tên-rule>.md`.
- Chọn đúng kiểu `trigger`:
  - `trigger: always_on`: Chỉ dùng cho các quy tắc bất biến, tối quan trọng (chia sẻ ngân sách 20,000 token).
  - `trigger: glob`: Dùng cho quy tắc theo loại file (`globs: "*.sql"`, `globs: "*.tsx"`).
  - `trigger: model_decision`: Dùng cho quy tắc kích hoạt theo ngữ cảnh (bắt buộc có trường `description:`).
  - `trigger: manual`: Chỉ nạp khi người dùng gõ `@<tên-rule>`.

### 5.3. Thêm Skill mới đúng chuẩn
- Tạo thư mục `.agents/skills/<ten-skill-chu-thuong-gach-noi>/`.
- Tạo file `SKILL.md` với frontmatter:
  ```markdown
  ---
  name: database-migration-runner
  description: "Use this skill when creating, verifying, or rolling back database schema migrations."
  ---
  # Database Migration Runner
  ...
  ```
- Tuân thủ nguyên tắc Progressive Disclosure: Phần hướng dẫn chi tiết, script phức tạp đặt vào thư mục con `scripts/` hoặc `references/` và dẫn link trong `SKILL.md`.

### 5.4. Thêm Custom Subagent mới
- Tạo file `.agents/agents/<tên-agent>.md`.
- Khai báo frontmatter hợp lệ:
  ```markdown
  ---
  name: security-auditor
  description: "Audits dependency tree and static source code for known security vulnerabilities."
  model: inherit
  tools:
    - view_file
    - run_command
  ---
  ```
- **Lưu ý then chốt**:
  - `model`: Chỉ sử dụng các giá trị tier được hỗ trợ (`inherit`, `flash`, `pro`, `flash_lite`). **Không** điền ID cụ thể như `gemini-3.8-flash-high`.
  - **Không** khai báo trường `effort` trong frontmatter (effort được truyền qua cờ CLI `--effort`).
  - `tools`: Chỉ cấp các công cụ tối thiểu cần thiết theo nguyên tắc Least Privilege.

### 5.5. Cấu hình Mở rộng Tùy chọn (Hooks & MCP)

- **Lifecycle Hooks (`extensions/hooks/`)**:
  - Khi dự án cần tự động chạy kiểm tra bảo mật hoặc format code trước/sau khi gọi tool, sao chép file mẫu vào `.agents/hooks.json`.
  - Trong `hooks.json`, các sự kiện hỗ trợ bao gồm: `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`.
  - Chú ý sử dụng đúng `matcher`: `"matcher": "run_command"` cho lệnh terminal hoặc `"matcher": "file_change"` khi chỉnh sửa file. Chi tiết xem tại [`extensions/hooks/README.md`](../extensions/hooks/README.md).
- **Model Context Protocol (`extensions/mcp/`)**:
  - Không đặt file cấu hình MCP rời rạc ở gốc `.agents/`.
  - Để chia sẻ server MCP cho cả nhóm trong workspace, hãy đóng gói dưới dạng Workspace Plugin tại `.agents/plugins/<name>/mcp_config.json` kèm `plugin.json`.
  - Hoặc cấu hình cấp cá nhân thông qua lệnh CLI: `agy mcp add [flags] <tên> <commandOrUrl> [args...]` (ví dụ: `agy mcp add sqlite npx -y @modelcontextprotocol/server-sqlite --db-path ./data.db`). Chi tiết xem tại [`extensions/mcp/README.md`](../extensions/mcp/README.md).

---

## 6. Cách chạy kiểm tra & Xác minh

Chạy script kiểm tra tự động đi kèm template:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\test_template.ps1
```

Script sẽ thực hiện các bước kiểm tra:
1. Tính đầy đủ của cấu trúc thư mục.
2. Không có file rỗng hoặc file rác giữ chỗ.
3. Cú pháp YAML frontmatter và các trường bắt buộc của Rules, Skills, Agents.
4. Schema giá trị `model` và `trigger`.
5. Quét phát hiện vô tình commit secrets hoặc API keys.
6. Chạy các trường hợp kiểm thử âm tính với fixtures.

---

## 7. Các điểm lưu ý kỹ thuật (Technical Notes & Limitations)

1. **Lệnh `agy agents`**: Lệnh `agy agents` in danh sách các custom agents có sẵn trong workspace (`.agents/agents/`) ra màn hình console. Để giao việc cho subagent cụ thể, hãy gọi qua cờ `--agent <tên>` (ví dụ: `agy --agent code-reviewer -p "Hãy đánh giá PR này"`).
2. **Model tier mapping & CLI Effort**: Cờ CLI `--model` nhận model ID cụ thể (ví dụ `gemini-3.8-flash-high`), trong khi frontmatter của custom agent chỉ nhận model tier (`inherit`, `flash`, `pro`, `flash_lite`). Cờ CLI `--effort` nhận các mức: `low`, `medium`, `high`, `xhigh`, `max`. Không khai báo model ID hoặc effort trong frontmatter agent.
3. **Phát hiện root repository**: Antigravity yêu cầu thư mục gốc phải có dấu hiệu quản lý phiên bản (như thư mục `.git`) để tự động duyệt ngược từ thư mục hiện hành lên root tìm kiếm `.agents/`.

---

## 8. Tài liệu Tham Chiếu Chuyên Sâu & Liên Kết

### 8.1. Bộ tài liệu kiến trúc & thực chiến đi kèm Template
- **Cẩm nang tích hợp & Mẫu Prompt chuẩn COCV**: [`HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md`](HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md)
- **Kiến trúc nhận thức ReAct, Multi-Agent & Token budget**: [`KIEN_TRUC_AI_AGENT.md`](KIEN_TRUC_AI_AGENT.md)
- **Đặc tả runtime Antigravity, modes & Stream-JSON**: [`ANTIGRAVITY_RUNTIME_SPEC.md`](ANTIGRAVITY_RUNTIME_SPEC.md)
- **Kiến trúc an toàn & Phòng thủ đa tầng 4 lớp**: [`AN_TOAN_VA_PHONG_THU_DA_TANG.md`](AN_TOAN_VA_PHONG_THU_DA_TANG.md)
- **Sổ tay Debug, Telemetry & Trị vòng lặp vô hạn**: [`SO_TAY_DEBUG_VA_QUAN_SAT.md`](SO_TAY_DEBUG_VA_QUAN_SAT.md)
- **Hồ sơ quyết định thiết kế (ADR)**: [`QUYET_DINH_THIET_KE.md`](QUYET_DINH_THIET_KE.md)
- **Ma trận kiểm thử thực tế**: [`MA_TRAN_KIEM_THU.md`](MA_TRAN_KIEM_THU.md)

### 8.2. Nguồn tài liệu chính thức của Google
- **Custom subagents**: [https://antigravity.google/docs/subagents?tab=cli](https://antigravity.google/docs/subagents?tab=cli)
- **Workspace Rules**: [https://antigravity.google/docs/rules/](https://antigravity.google/docs/rules/)
- **Skills System**: [https://antigravity.google/docs/skills](https://antigravity.google/docs/skills)
- **Model Context Protocol (MCP)**: [https://antigravity.google/docs/mcp](https://antigravity.google/docs/mcp)
- **Lifecycle Hooks**: [https://antigravity.google/docs/hooks](https://antigravity.google/docs/hooks)
- **Plugin Architecture**: [https://antigravity.google/docs/plugins?tab=cli](https://antigravity.google/docs/plugins?tab=cli)
- **CLI Best Practices**: [https://antigravity.google/docs/cli/best-practices/](https://antigravity.google/docs/cli/best-practices/)
