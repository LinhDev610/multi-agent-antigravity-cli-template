# Workspace Instructions — Antigravity Template

> Template nền tảng cho Google Antigravity CLI (`agy 1.4.10`).
> Độc lập với ngôn ngữ lập trình, framework và nghiệp vụ dự án.

---

## 1. Nguyên tắc hoạt động cốt lõi

1. **Least Privilege & Safe Execution**:
   - Chỉ yêu cầu và sử dụng các công cụ cần thiết cho tác vụ hiện tại.
   - Tuyệt đối KHÔNG tự động thực thi các lệnh Git mang tính phá hủy (`git reset --hard`, `git push --force`, `git clean -fdx`).
   - Tuyệt đối KHÔNG ghi đè, làm lộ hoặc commit thông tin bí mật (API keys, token, mật khẩu, file `.env`).
2. **Context-Aware & Súc tích**:
   - Trả lời ngắn gọn, trực diện, giải thích lý do trước khi đưa ra thay đổi lớn.
   - Ưu tiên đọc context cục bộ và tuân thủ các quy tắc trong `.agents/rules/`.
   - Khi cần quy trình phức tạp, kích hoạt Skill phù hợp trong `.agents/skills/`.
3. **Chất lượng mã nguồn**:
   - Mọi thay đổi code phải giữ nguyên tính toàn vẹn của comment, docstring hiện có.
   - Luôn kiểm tra cú pháp, build hoặc chạy unit test liên quan trước khi kết thúc tác vụ.

---

## 2. Bản đồ cấu trúc & Điều hướng chỉ dẫn

Workspace sử dụng cơ chế nạp chỉ dẫn phân tầng của Google Antigravity:

| Thành phần | Vị trí | Mục đích & Thời điểm nạp |
|---|---|---|
| **Chỉ dẫn chung** | `AGENTS.md` | Tài liệu này — Luôn nạp cho toàn bộ workspace. |
| **Quy tắc an toàn** | `.agents/rules/security-and-secrets.md` | `trigger: always_on` — Bảo vệ bảo mật và dữ liệu. |
| **Quy chuẩn code** | `.agents/rules/code-quality.md` | `trigger: glob` — Tự động nạp khi sửa file mã nguồn. |
| **Khảo sát dự án** | `.agents/skills/project-onboarding/` | Skill kích hoạt khi tiếp nhận repo hoặc kiểm tra môi trường. |
| **Đánh giá code** | `.agents/agents/code-reviewer.md` | Subagent chuyên biệt chỉ đọc (`view_file`), không sửa code. |
| **Mở rộng tùy chọn**| `extensions/` | MCP, Lifecycle Hooks, Plugin mẫu (chỉ dùng khi dự án cần). |
| **Tài liệu hướng dẫn**| `docs/` | Bộ tài liệu kiến trúc, runtime, an toàn, debug và prompt chuẩn. |

---

## 3. Quy trình làm việc chuẩn (Standard Workflow)

1. **Khảo sát (Survey)**: Đọc kỹ yêu cầu người dùng, kiểm tra cấu trúc repo liên quan, không tự ý giả định nghiệp vụ.
2. **Thiết kế & Lập kế hoạch (Plan)**: Đối với thay đổi lớn (> 3 file hoặc ảnh hưởng kiến trúc), trình bày kế hoạch trước khi chỉnh sửa.
3. **Thực thi (Execute)**: Thực hiện từng bước nhỏ, có thể kiểm chứng.
4. **Xác minh (Verify)**: Chạy test, linter hoặc lệnh kiểm tra tương ứng với ngôn ngữ của dự án.
5. **Báo cáo (Report)**: Tóm tắt file đã sửa, kết quả test và các lưu ý (nếu có).

---

## 4. Ranh giới & Giới hạn môi trường

- **Môi trường khuyến nghị**: Antigravity CLI `agy 1.4.10` trên Windows 11 / Linux / macOS.
- **Model & Effort**:
  - Model ID được quản lý qua cờ CLI: `agy --model gemini-3.8-flash-high` (hoặc `-medium`, `-low`).
  - Mức effort được cấu hình qua cờ CLI: `agy --effort high` (hoặc `low`, `medium`, `high`, `xhigh`, `max`).
  - Trong frontmatter của subagent, trường `model` chỉ chấp nhận tier: `inherit`, `flash`, `pro`, `flash_lite`.
- **Tùy biến theo dự án**: Người dùng sao chép template này vào repo mới, sau đó bổ sung lệnh build/test đặc thù của dự án vào mục 3.
