# Hồ Sơ Quyết Định Thiết Kế (Architectural Decision Records — ADR)

Tài liệu này ghi nhận toàn bộ các quyết định thiết kế kiến trúc cho Project Template của Google Antigravity CLI (`agy 1.4.10`).

---

## 1. Phân loại căn cứ thiết kế

Mọi quyết định trong template này được phân định nghiêm ngặt theo 3 nhóm căn cứ:

| Nhóm | Định nghĩa | Ví dụ trong template |
|---|---|---|
| **Google hỗ trợ / Documented** | Được tài liệu chính thức hoặc mã nguồn CLI công bố rõ ràng. | Vị trí `.agents/`, cấu trúc `SKILL.md`, trigger (`always_on`, `glob`, `model_decision`), enum tier model (`inherit`, `flash`, `pro`). |
| **Khuyến nghị kỹ thuật** | Các thực hành kỹ thuật tốt do tác giả đề xuất để đảm bảo tối ưu context, bảo mật và khả năng bảo trì. | Ngân sách `AGENTS.md` ~50-100 dòng, phân tách thư mục `extensions/`, nguyên tắc Least Privilege cho subagent. |
| **Chưa xác minh / Cần kiểm chứng thêm** | Các tính năng chưa đủ căn cứ thực nghiệm hoặc hành vi khác biệt giữa các phiên bản CLI. | Cơ chế nạp đa subagent song song tự động trong chế độ non-interactive print mode (`agy -p`). |

---

## 2. Các quyết định thiết kế cốt lõi

### ADR-01: Phân tầng tối thiểu (Minimal Core) và Mở rộng tùy chọn (Optional Extensions)
- **Căn cứ**: Khuyến nghị kỹ thuật (dựa trên nguyên tắc YAGNI - You Aren't Gonna Need It).
- **Vấn đề**: Nhiều dự án tạo sẵn MCP config, hàng loạt file hooks và nhiều subagent phức tạp khiến repository nặng nề, làm agent bị nhiễu context và tăng nguy cơ lỗi parsing.
- **Quyết định**:
  - **Phần Cốt lõi (Core)** chỉ bao gồm: [`AGENTS.md`](../AGENTS.md), 2 rules cơ bản ([`security-and-secrets.md`](../.agents/rules/security-and-secrets.md), [`code-quality.md`](../.agents/rules/code-quality.md)), 1 skill mẫu ([`project-onboarding`](../.agents/skills/project-onboarding/SKILL.md)), 1 subagent mẫu ([`code-reviewer.md`](../.agents/agents/code-reviewer.md)).
  - **Phần Mở rộng (Extensions)** đặt trong thư mục riêng biệt [`extensions/`](../extensions/) (gồm `mcp/`, `hooks/`, `plugin/`), có tài liệu hướng dẫn kèm theo. Khi dự án có nhu cầu:
    - Kích hoạt Lifecycle Hooks bằng cách sao chép cấu hình vào `.agents/hooks.json`.
    - Tích hợp MCP thông qua Workspace Plugin (`.agents/plugins/<name>/mcp_config.json`) hoặc qua lệnh CLI global `agy mcp add [flags] <name> <commandOrUrl> [args...]`.
    - Đóng gói tùy biến dùng chung qua Plugin Extension (`extensions/plugin/`).
- **Hệ quả**: Template cực kỳ nhẹ, không có file rác, người mới tiếp cận dễ hiểu ngay.

---

### ADR-02: Giới hạn ngân sách độ dài `AGENTS.md` (~50–100 dòng)
- **Căn cứ**: Khuyến nghị kỹ thuật (kết hợp với giới hạn 24 KB / 20,000 token rules budget của Google).
- **Vấn đề**: Khi `AGENTS.md` quá dài, mô hình tiêu tốn nhiều token vô ích ở mỗi lượt hội thoại và dễ bỏ sót các chỉ dẫn quan trọng.
- **Quyết định**:
  - `AGENTS.md` đóng vai trò là "router" và "tuyên ngôn nguyên tắc", thiết lập ranh giới an toàn chung và điều hướng agent đến đúng vị trí tài liệu chi tiết.
  - Các quy tắc cụ thể theo loại file được chuyển sang `.agents/rules/` (`trigger: glob`).
  - Các quy trình phức tạp nhiều bước được chuyển sang `.agents/skills/`.
- **Hệ quả**: Tiết kiệm context window, tăng độ tuân thủ của mô hình.

---

### ADR-03: Phân biệt rõ Model ID, Model Tier và CLI Effort
- **Căn cứ**: Google hỗ trợ & Kiểm chứng thực tế trên `agy 1.4.10`.
- **Vấn đề**: Dễ xảy ra nhầm lẫn giữa tên model hiển thị (`Gemini 3.8 Flash (High)`), model ID (`gemini-3.8-flash-high`), model tier (`flash`, `inherit`) và mức reasoning effort (`high`). Nếu đưa sai vào frontmatter, CLI sẽ âm thầm từ chối nhận diện agent (`no custom agents are available`).
- **Quyết định**:
  - Trong frontmatter của subagent: Chỉ dùng các tier được Google hỗ trợ: `model: inherit` (khuyến nghị mặc định), `flash`, `pro`, `flash_lite`.
  - Tuyệt đối **KHÔNG** đưa model ID như `gemini-3.8-flash-high` vào frontmatter.
  - Tuyệt đối **KHÔNG** đưa trường `effort` vào frontmatter của agent (vì schema không hỗ trợ).
  - Model ID và Effort được thiết lập ở cấp phiên làm việc thông qua các cờ lệnh CLI (`--effort` hỗ trợ 5 mức: `low`, `medium`, `high`, `xhigh`, `max`):
    ```powershell
    agy --model gemini-3.8-flash-high --effort high
    ```
- **Hệ quả**: Ngăn chặn 100% lỗi schema rejection của CLI.

---

### ADR-04: Áp dụng nguyên tắc Least Privilege cho Agent Mẫu
- **Căn cứ**: Google hỗ trợ & Khuyến nghị kỹ thuật.
- **Vấn đề**: Cấp toàn bộ công cụ (`run_command`, `edit_file`, `write_file`) cho subagent đánh giá code tạo ra rủi ro agent tự ý sửa file hoặc thực thi lệnh ngoài tầm kiểm soát.
- **Quyết định**:
  - Agent mẫu `code-reviewer` chỉ được cấp duy nhất công cụ `view_file`.
  - Agent này hoàn toàn là Read-Only, chỉ đưa ra báo cáo nhận xét và khuyến nghị để lập trình viên hoặc agent chính thực hiện.
- **Hệ quả**: Đảm bảo an toàn tuyệt đối, minh họa đúng tư duy phân quyền trong hệ thống multi-agent.

---

### ADR-05: Ranh giới độc lập giữa Workspace, Global và Plugin
- **Căn cứ**: Google hỗ trợ.
- **Vấn đề**: Cấu hình mẫu vô tình sửa đổi hoặc phụ thuộc vào thư mục global `~/.gemini/config/` sẽ gây xung đột với các dự án khác trên máy lập trình viên.
- **Quyết định**:
  - Toàn bộ cấu hình template được cô lập bên trong thư mục dự án.
  - Không tạo hoặc sửa đổi bất kỳ file nào trong `~/.gemini/antigravity-cli/settings.json` hay `~/.gemini/config/`.
  - Cung cấp extension Plugin riêng biệt kèm hướng dẫn cách đóng gói khi muốn chia sẻ.
- **Hệ quả**: Đảm bảo tính di động (portable) và an toàn cho môi trường máy chủ/máy phát triển của người dùng.

---

### ADR-06: Kiến trúc Nhận thức ReAct & Phân cấp Bộ nhớ 4 Tầng
- **Căn cứ**: Google hỗ trợ & Khuyến nghị kỹ thuật AI Agent.
- **Vấn đề**: Agent hoạt động nguyên khối dễ bị trôi dạt nhận thức (cognitive drift) và lãng phí token khi phải lưu trữ toàn bộ trạng thái trong working memory.
- **Quyết định**:
  - Chuẩn hóa vòng lặp nhận thức theo mô hình ReAct (Reason -> Act -> Observe) kết hợp cơ chế Reactive Wakeup (không dùng shell polling).
  - Phân cấp bộ nhớ thành 4 tầng: Working Memory (In-Session Context), Persistent Storage (Git Workspace & Docs), Progressive Skills (On-demand execution), và System Telemetry (`~/.gemini/antigravity-cli/brain/`).
  - Tài liệu hóa toàn diện tại [`docs/KIEN_TRUC_AI_AGENT.md`](KIEN_TRUC_AI_AGENT.md).
- **Hệ quả**: Tối ưu hóa chu trình suy luận của Agent, ngăn chặn cạn kiệt context và rò rỉ trạng thái.

---

### ADR-07: Kiến trúc An toàn & Phòng thủ Đa tầng (Defense-in-Depth)
- **Căn cứ**: Google hỗ trợ & Tiêu chuẩn bảo mật phần mềm.
- **Vấn đề**: Dựa dẫm duy nhất vào lời dặn trong prompt (soft constraints) rất dễ bị qua mặt bởi kỹ thuật Prompt Injection hoặc lỗi ảo giác của LLM.
- **Quyết định**:
  - Thiết lập mô hình phòng vệ 4 lớp độc lập: Lớp 1 - Prompt Rules (`AGENTS.md`, `always_on`); Lớp 2 - Lifecycle Hooks tiền/hậu kiểm tra (`PreToolUse`, `PostToolUse`); Lớp 3 - Chính sách Phân quyền & Công cụ (Least Privilege, `ask_permission`); Lớp 4 - OS Sandboxing & Terminal Confinement.
  - Cập nhật matcher chuẩn cho file modification hook thành `file_change`.
  - Tài liệu hóa toàn diện tại [`docs/AN_TOAN_VA_PHONG_THU_DA_TANG.md`](AN_TOAN_VA_PHONG_THU_DA_TANG.md).
- **Hệ quả**: Đảm bảo an toàn cấp hệ thống ngay cả khi mô hình bị thao túng bởi prompt độc hại.

---

### ADR-08: Chuẩn hóa Runtime Antigravity & Chuyển đổi Workflows sang Skills
- **Căn cứ**: Google Antigravity CLI Spec `1.4.10`.
- **Vấn đề**: Cấu trúc cũ sử dụng Workflows (`.agents/workflows/`) thiếu tính thích ứng, gây lãng phí context và đã chính thức bị Google loại bỏ. Ngoài ra người dùng thiếu tài liệu về các cờ `--mode` (`auto`, `plan`, `accept-edits`) và giao thức Stream-JSON.
- **Quyết định**:
  - Khai tử hoàn toàn Workflows; chuẩn hóa 100% sang chuẩn Skills (`.agents/skills/<name>/SKILL.md`) với kích hoạt ngữ nghĩa và Progressive Disclosure.
  - Tài liệu hóa đặc tả runtime, các chế độ thực thi, cơ chế phân giải root `.git` và giao thức Stream-JSON tại [`docs/ANTIGRAVITY_RUNTIME_SPEC.md`](ANTIGRAVITY_RUNTIME_SPEC.md).
- **Hệ quả**: Dự án luôn tương thích với các phiên bản hiện tại và tương lai của Antigravity CLI.

---

### ADR-09: Khung Tạo Prompt Chuẩn COCV & Chiến lược Khảo sát Dự án
- **Căn cứ**: Khuyến nghị kỹ thuật thực chiến.
- **Vấn đề**: Người dùng khi áp dụng template vào dự án mới thường đưa ra prompt mơ hồ hoặc yêu cầu AI đọc toàn bộ source code, dẫn đến lỗi hallucination, phá vỡ kiến trúc cũ hoặc cạn kiệt token.
- **Quyết định**:
  - Chuẩn hóa quy trình 4 bước tích hợp: Setup -> Context-Efficient Survey (dùng Skill `project-onboarding`) -> Localization (`AGENTS.md` & Rules) -> Prompting.
  - Thiết lập khung cấu trúc Prompt chuẩn **COCV** (Context - Objective - Constraints - Verification Criteria) kèm 5 mẫu prompt thực chiến (Feature, Bug Fix, Refactor, Code Review, Migration).
  - Tài liệu hóa chi tiết tại [`docs/HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md`](HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md).
- **Hệ quả**: Nâng cao độ chính xác khi giao việc cho AI Agent lên mức tối đa, loại bỏ sửa đổi ngoài ý muốn và kiểm chứng được bằng máy.
