# Kiến Trúc AI Agent — Lý Thuyết & Vận Hành Trong Antigravity CLI

Tài liệu này trình bày toàn diện kiến trúc nhận thức, mô hình phối hợp đa đặc vụ (multi-agent), cơ chế phân tầng bộ nhớ và chiến lược quản lý ngân sách ngữ cảnh (token budget) trong Google Antigravity CLI (`agy 1.4.10`).

---

## 1. Tổng quan Kiến trúc AI Pair Programming

Khác với các công cụ gợi ý code thông thường (code completion) chỉ hoạt động dựa trên cửa sổ văn bản xung quanh con trỏ chuột, Antigravity CLI là một **Agentic AI Assistant**. Trợ lý này hoạt động như một kỹ sư lập trình độc lập hoặc cộng sự song hành (pair programmer), có khả năng:
- Tự lập luận về cấu trúc dự án và yêu cầu kỹ thuật.
- Lên kế hoạch thực hiện từng bước (multi-step planning).
- Sử dụng các công cụ (tools) của hệ điều hành để đọc file, viết code, chạy build, kiểm thử và phân tích lỗi.
- Đánh giá kết quả phản hồi từ môi trường (feedback loop) để tự điều chỉnh hành vi cho đến khi hoàn thành mục tiêu.

Để vận hành an toàn và chính xác, kiến trúc của Antigravity được xây dựng dựa trên 4 trụ cột cốt lõi:
1. **Vòng lặp nhận thức ReAct (Reasoning - Acting - Observing)**.
2. **Mô hình phối hợp Đa đặc vụ (Multi-Agent Architecture)**.
3. **Hệ thống phân tầng bộ nhớ (Memory Hierarchy)**.
4. **Quản trị ngân sách ngữ cảnh (Context & Token Budget Management)**.

---

## 2. Vòng lặp nhận thức (Cognitive Loops — ReAct)

### 2.1. Chu trình ReAct: Reason -> Act -> Observe

Antigravity CLI triển khai mô hình nhận thức theo mẫu **ReAct** (Reasoning and Acting). Mỗi lượt xử lý của Agent không phải là một câu trả lời đơn lẻ, mà là một chuỗi các bước tuần hoàn:

```text
       ┌────────────────────────────────────────────────────────┐
       │                                                        │
       ▼                                                        │
┌──────────────┐          ┌──────────────┐          ┌───────────┴──┐
│   REASON     │ ───────► │     ACT      │ ───────► │   OBSERVE    │
│ (Lập luận &  │          │ (Gọi Tools & │          │ (Phân tích   │
│  Lập kế hoạch)│          │  Thay đổi)   │          │  Kết quả)    │
└──────────────┘          └──────────────┘          └──────────────┘
```

1. **Reason (Tư duy & Lập luận)**:
   - Mô hình phân tích trạng thái hiện tại của phiên làm việc, yêu cầu người dùng (`<USER_REQUEST>`), chỉ dẫn từ [`AGENTS.md`](../AGENTS.md) và các quy tắc kích hoạt.
   - Mô hình suy nghĩ (thể hiện qua thinking process / reasoning tokens) về nguyên nhân gốc rễ, đưa ra giả thuyết và quyết định bước tiếp theo.
2. **Act (Hành động)**:
   - Thay vì chỉ xuất văn bản, Agent phát ra một cấu trúc gọi công cụ (tool call), ví dụ: [`view_file`](ANTIGRAVITY_RUNTIME_SPEC.md), [`replace_file_content`](ANTIGRAVITY_RUNTIME_SPEC.md), [`run_command`](ANTIGRAVITY_RUNTIME_SPEC.md).
   - Tool call được runtime Antigravity tiếp nhận, kiểm tra qua hệ thống bảo mật (Rules, Hooks, Permissions) trước khi thực thi trên hệ điều hành.
3. **Observe (Quan sát & Đánh giá)**:
   - Kết quả đầu ra từ công cụ (`tool_result`: nội dung file, stdout, stderr, mã thoát process, exception) được đưa ngược lại vào ngữ cảnh của mô hình.
   - Mô hình phân tích xem hành động vừa thực hiện thành công hay thất bại:
     - Nếu lỗi (linter báo lỗi, unit test tạch, compile thất bại): Mô hình lập luận lại nguyên nhân và chuyển sang vòng lặp kế tiếp để khắc phục.
     - Nếu thành công: Tiếp tục bước tiếp theo trong kế hoạch hoặc chuyển sang bước nghiệm thu.

### 2.2. Cơ chế Reactive Wakeup vs Polling

Một đột phá trong kiến trúc runtime của Antigravity là cơ chế **Reactive Wakeup (Đánh thức phản hồi sự kiện)**:
- **Không dùng Polling**: Agent tuyệt đối không dùng vòng lặp shell như `while true; do sleep 5; done` hoặc liên tục gọi lệnh kiểm tra trạng thái của tiến trình nền. Việc này gây lãng phí nghiêm trọng token và làm cạn kiệt tài nguyên CPU.
- **Tự động kích hoạt khi có sự kiện**: Khi Agent khởi chạy một lệnh bất đồng bộ (ví dụ biên dịch dự án lớn, chạy dev server, hoặc khởi tạo task con qua `run_command` với `WaitMsBeforeAsync`), runtime sẽ chuyển tiến trình thành background task. Agent ngay lập tức kết thúc lượt (turn) và chuyển sang trạng thái chờ (idle).
- Khi tiến trình hoàn thành hoặc có thông điệp mới từ subagent / user, hệ thống Antigravity sẽ tự động kích hoạt (wake up) phiên làm việc của Agent và nạp kết quả vào ngữ cảnh để tiếp tục xử lý.

### 2.3. Hiện tượng Trôi dạt Nhận thức (Cognitive Drift) & Cách phòng ngừa

Trong các tác vụ phức tạp kéo dài qua hàng chục lượt tool call, Agent có xu hướng gặp hiện tượng **Cognitive Drift (Trôi dạt nhận thức)**:
- Agent quên mất mục tiêu cốt lõi ban đầu của người dùng và sa đà vào việc sửa các vấn đề phụ phát sinh trong quá trình thực thi.
- Agent tự ý refactor những đoạn code không liên quan hoặc thay đổi hành vi đã được thỏa thuận.
- **Giải pháp phòng ngừa trong Antigravity Template**:
  - Gắn chặt định danh tác vụ gốc: Giữ vững nhiệm vụ trong khối `<original_task>` xuyên suốt toàn bộ vòng đời phiên.
  - Tuyên ngôn nguyên tắc tập trung diff: Quy định trong [`AGENTS.md`](../AGENTS.md) và [`.agents/rules/code-quality.md`](../.agents/rules/code-quality.md) rằng mọi thay đổi phải tập trung, không refactor lan man.

---

## 3. Mô hình Đa đặc vụ (Multi-Agent Patterns)

Khi đối mặt với các bài toán phần mềm quy mô lớn, một Agent đơn lẻ (Monolithic Agent) dễ bị quá tải ngữ cảnh và tăng nguy cơ gây lỗi liên đới. Antigravity hỗ trợ kiến trúc Multi-Agent thông qua hệ thống Subagents.

### 3.1. Phân loại các mô hình điều phối

```text
Mô hình Orchestrator-Workers:
                  ┌──────────────────────┐
                  │  Orchestrator Agent  │
                  │   (Main Coordinator) │
                  └──────────┬───────────┘
                             │
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
     ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
     │ Worker A    │  │ Worker B    │  │ Worker C    │
     │ Code Review │  │ Test Runner │  │ DB Migrate  │
     └─────────────┘  └─────────────┘  └─────────────┘
```

1. **Orchestrator-Workers (Chỉ huy - Công nhân)**:
   - **Orchestrator (Agent chính)**: Tiếp nhận yêu cầu người dùng, phân tích phạm vi công việc, chia nhỏ thành các mục tiêu con độc lập, sau đó phân công (dispatch) cho các Subagent chuyên trách.
   - **Workers (Subagents chuyên biệt)**: Mỗi worker sở hữu bộ công cụ hạn chế và một system prompt chuyên biệt (ví dụ: `code-reviewer` chỉ đọc code; `test-worker` chỉ chạy và phân tích test).
   - Orchestrator thu thập báo cáo từ các worker, tổng hợp thành quả và đưa ra quyết định cuối cùng.
2. **Specialist Delegation (Ủy nhiệm chuyên biệt)**:
   - Agent chính tạm dừng luồng suy nghĩ để chuyển giao quyền kiểm soát tạm thời cho một specialist subagent khi gặp tác vụ đặc thù (như kiểm định bảo mật, rà soát lỗ hổng, hoặc kiểm tra tính tương thích hạ tầng).
   - Specialist hoàn thành nhiệm vụ và trả lại quyền điều khiển cùng bản tóm tắt gọn gàng, giúp bảo toàn context cho Agent chính.

### 3.2. Vòng đời của Subagent (Subagent Lifecycle)

Vòng đời của một Subagent trong Antigravity trải qua 5 giai đoạn:

1. **Discovery (Khám phá)**: Runtime quét thư mục `.agents/agents/*.md` khi phiên làm việc khởi động và phân tích cú pháp YAML frontmatter để đăng ký danh sách agent có sẵn.
2. **Spawning / Instantiation (Khởi tạo)**: Khi được gọi thông qua CLI (`agy --agent <name>`) hoặc qua lệnh phân công từ Agent chính, Antigravity tạo một phiên thực thi mới (isolated child session) với:
   - System prompt riêng biệt được định nghĩa trong file Markdown của subagent.
   - Model tier được chỉ định (`inherit`, `flash`, `pro`).
   - Danh sách công cụ được giới hạn nghiêm ngặt theo trường `tools`.
3. **Execution & Context Isolation (Thực thi & Cô lập)**:
   - Subagent chạy trong context window độc lập của riêng mình. Các tool call, log trung gian và suy nghĩ nháp của subagent **không** làm ô nhiễm context của Agent chính.
4. **Inter-Agent Messaging (Giao tiếp qua thông điệp)**:
   - Giao tiếp giữa các agent được thực hiện thông qua kênh thông điệp có cấu trúc (`send_message`), kèm định danh người nhận (`Recipient`) và mức độ ưu tiên.
5. **Termination & Reporting (Kết thúc & Báo cáo)**:
   - Subagent kết thúc phiên làm việc bằng một báo cáo hoàn thành tiêu chuẩn (Final Completion Report), nêu rõ những gì đã làm, bằng chứng kiểm chứng và các rủi ro còn tồn tại.

---

## 4. Phân cấp Bộ nhớ (Memory Hierarchy)

Để xử lý thông tin hiệu quả mà không làm cạn kiệt tài nguyên, Antigravity áp dụng mô hình phân cấp bộ nhớ 4 tầng:

| Tầng bộ nhớ | Vị trí lưu trữ | Tốc độ truy cập | Dung lượng | Tính bền vững | Mục đích sử dụng |
|---|---|---|---|---|---|
| **Tầng 1: Working Memory** | Context Window (In-Session) | Tức thời (0ms) | Hạn chế (token window) | Mất khi đóng session | Lịch sử chat, reasoning nháp, kết quả tool call gần nhất |
| **Tầng 2: Persistent Storage** | Git Workspace & Docs | Nhanh (vài ms qua file tool) | Rất lớn (GB) | Bền vững vĩnh viễn | Toàn bộ mã nguồn, `AGENTS.md`, `.agents/rules/`, tài liệu dự án |
| **Tầng 3: Progressive Skills** | `.agents/skills/<name>/` | Theo nhu cầu (On-demand) | Không giới hạn | Bền vững | Quy trình chuyên môn hóa, runbooks, scripts tiện ích |
| **Tầng 4: System Telemetry** | `~/.gemini/antigravity-cli/brain/` | Đọc khi debug | Hàng GB log | Lưu theo session ID | `transcript.jsonl`, task log, trace của hệ thống |

### 4.1. Tầng 1: In-Session Working Memory (Context Window)
Bộ nhớ làm việc trực tiếp của LLM. Mỗi từ ngữ trong prompt, hướng dẫn hệ thống, lịch sử chat và output của tool đều chiếm token trong working memory. Vì dung lượng có hạn và chi phí tính toán tăng tỉ lệ thuận với độ dài context, working memory phải được giữ càng tinh gọn càng tốt.

### 4.2. Tầng 2: Persistent Storage (Workspace Repository)
Mọi tri thức quan trọng, quyết định kỹ thuật và trạng thái bàn giao phải được viết xuống file trong repository (commit vào Git). Điều này đảm bảo rằng ngay cả khi một phiên làm việc bị ngắt hoặc bắt đầu phiên mới hoàn toàn, Agent mới vẫn có thể phục hồi đầy đủ bức tranh dự án bằng cách đọc file.

### 4.3. Tầng 3: Progressive Disclosure via Skills
Thay vì nạp toàn bộ hàng trăm trang hướng dẫn kỹ thuật vào working memory ngay từ đầu, kiến trúc **Progressive Disclosure (Mở lộ tri thức dần dần)** chỉ nạp metadata tối thiểu của Skill (`name` và `description` trong YAML frontmatter):
- Kích thước metadata cực nhỏ (~50-100 token cho mỗi skill).
- LLM chỉ đọc lướt danh sách skill để biết hệ thống "biết làm những gì".
- Khi và chỉ khi gặp tác vụ tương ứng, LLM mới chủ động gọi công cụ để đọc nội dung chi tiết của `SKILL.md` và các file phụ trợ trong `scripts/` hoặc `references/`.

### 4.4. Tầng 4: System Telemetry & Brain Cache
Thư mục `~/.gemini/antigravity-cli/brain/<session_id>/` lưu giữ toàn bộ dữ liệu thô của phiên làm việc. Đây là nguồn dữ liệu quan trọng phục vụ cho việc kiểm toán an toàn, gỡ lỗi khi agent gặp sự cố, hoặc phân tích hành vi của các subagent chạy ngầm.

---

## 5. Quản trị Ngân sách Context & Token (Context & Token Budget)

### 5.1. Giới hạn Context Window và Hiện tượng Suy giảm Nhận thức (Token Degradation)

Mặc dù các mô hình Gemini hiện đại hỗ trợ cửa sổ ngữ cảnh rất lớn (hơn 1 triệu token), nhưng việc nạp quá nhiều thông tin rác vào context sẽ gây ra hai vấn đề nghiêm trọng:
1. **Lost in the Middle**: Khả năng chú ý (attention mechanism) của mô hình bị phân tán, khiến mô hình dễ bỏ sót các chỉ dẫn bảo mật cốt lõi nằm ở giữa context.
2. **Tăng độ trễ & Chi phí**: Thời gian sinh câu trả lời (Time-to-first-token và thời gian xử lý) tăng đáng kể, đồng thời chi phí tính toán tăng vọt.

### 5.2. Ngân sách Rules: Giới hạn 24 KB / 20,000 Token của Google

Theo chuẩn kỹ thuật của Google Antigravity, tổng dung lượng của các quy tắc có cấu hình `trigger: always_on` được kiểm soát nghiêm ngặt trong ngân sách **24 KB (tương đương khoảng 20,000 token)**. Nếu vượt quá ngưỡng này:
- Runtime có thể tự động cắt xén (truncate) hoặc từ chối nạp quy tắc.
- Nguy cơ vi phạm quy chuẩn an toàn tăng cao.

### 5.3. Chiến lược Tối ưu Hóa Ngân sách trong Template

Template áp dụng 4 nguyên tắc phân tầng để bảo toàn ngân sách ngữ cảnh:

```text
Toàn bộ dự án
  ├── 1. AGENTS.md (~50-100 dòng): Router tổng quát, quy tắc an toàn bất biến
  ├── 2. Rules always_on: Chỉ chứa điều luật bảo vệ secret & cấm lệnh phá hủy
  ├── 3. Rules glob: Chỉ nạp khi mở file code tương ứng (*.ts, *.py, *.go)
  ├── 4. Rules model_decision: Chỉ nạp khi ngữ cảnh thực sự cần
  └── 5. Skills on-demand: Chỉ nạp hướng dẫn chi tiết khi thực thi quy trình
```

1. **`AGENTS.md` tinh gọn (50–100 dòng)**: Đóng vai trò là router định hướng và hiến pháp tối cao; không nhồi nhét hướng dẫn chi tiết của từng framework vào file này.
2. **Phân phối Rule theo `trigger: glob`**: Quy chuẩn code JavaScript/TypeScript chỉ được nạp khi Agent thao tác với file `.ts`/`.js`. Khi Agent đang sửa tài liệu Markdown, rule này hoàn toàn không chiếm dụng dù chỉ 1 token context.
3. **Sử dụng Tìm kiếm có chủ đích (Targeted Search)**:
   - Ưu tiên sử dụng `find_by_name` hoặc `grep_search` với từ khóa chính xác.
   - Tuyệt đối tránh các lệnh liệt kê toàn bộ cây thư mục lớn hoặc đọc hàng chục file cùng lúc khi chưa biết rõ file nào cần sửa.
4. **Đọc file có phân đoạn (Chunked / Slice Reading)**:
   - Với các file mã nguồn dài (> 500 dòng), sử dụng tham số `StartLine` và `EndLine` trong công cụ đọc file để chỉ nạp đúng phân đoạn logic cần kiểm tra.

---

## 6. Liên kết tham chiếu trong bộ tài liệu

- Xem chi tiết thông số runtime và các cờ CLI: [`ANTIGRAVITY_RUNTIME_SPEC.md`](ANTIGRAVITY_RUNTIME_SPEC.md)
- Xem kiến trúc bảo mật 4 lớp: [`AN_TOAN_VA_PHONG_THU_DA_TANG.md`](AN_TOAN_VA_PHONG_THU_DA_TANG.md)
- Xem hướng dẫn gỡ lỗi và phân tích transcript: [`SO_TAY_DEBUG_VA_QUAN_SAT.md`](SO_TAY_DEBUG_VA_QUAN_SAT.md)
- Xem hướng dẫn tích hợp vào dự án mới & tạo prompt chuẩn: [`HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md`](HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md)
