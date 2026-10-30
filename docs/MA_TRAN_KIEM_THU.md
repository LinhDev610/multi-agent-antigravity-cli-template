# Ma Trận Kiểm Thử Dự Án Template (Test Matrix)

Tài liệu ghi nhận chi tiết kế hoạch kiểm thử, các trường hợp thử nghiệm và kết quả thực tế trên môi trường Windows 11 với Google Antigravity CLI `agy 1.4.10`.

---

## 1. Tóm tắt kết quả kiểm thử

- **Tổng số ca kiểm thử**: 24
- **PASS**: 23
- **FAIL**: 0
- **NOT TESTED**: 1 (Có giải thích lý do kỹ thuật rõ ràng)

---

## 2. Bảng ma trận kiểm thử chi tiết

| Mã Test | Nhóm | Mục tiêu kiểm thử | Dữ liệu / Điều kiện | Cách thực hiện | Kết quả mong đợi | Kết quả thực tế | Trạng thái | Bằng chứng / Ghi chú |
|---|---|---|---|---|---|---|---|---|
| **STR-01** | Cấu trúc | Đủ file cốt lõi, không có file rỗng | Template workspace | Quét đệ quy kiểm tra kích thước file > 0 byte | Không có file nào 0 byte; đủ `AGENTS.md`, rules, skills, agents, docs suite | Tất cả 16 files đều có nội dung hợp lệ (> 0 bytes) | **PASS** | `test_template.ps1` kiểm tra kích thước file |
| **STR-02** | Cấu trúc | Phân tách rõ ràng giữa Core và Extensions | Thư mục `extensions/` | Kiểm tra cây thư mục | Các mẫu MCP, Hooks, Plugin nằm riêng trong `extensions/`, không lẫn vào `.agents/` | Cấu trúc phân tách đúng chuẩn; `.agents/` chỉ chứa thành phần cốt lõi | **PASS** | Cây thư mục kiểm chứng qua PowerShell |
| **FMT-01** | Frontmatter | `AGENTS.md` ở root không chứa frontmatter | `AGENTS.md` | Kiểm tra 5 dòng đầu không bắt đầu bằng `---` | Không có frontmatter YAML theo chuẩn Google | Dòng 1 bắt đầu bằng tiêu đề Markdown `# Workspace Instructions` | **PASS** | Regex `^---` phủ định trên `AGENTS.md` |
| **FMT-02** | Frontmatter | Quy tắc và Skill có YAML frontmatter hợp lệ | File trong `.agents/rules` và `.agents/skills` | Parse YAML header giữa hai dấu `---` | Parse thành công, không lỗi cú pháp | Cả 2 rules và skill parse YAML thành công | **PASS** | Script tự động parse YAML header |
| **RUL-01** | Rules | Rule `security-and-secrets` dùng `trigger: always_on` | `.agents/rules/security-and-secrets.md` | Đọc trường `trigger` | `trigger == "always_on"` | `trigger: always_on` chính xác | **PASS** | Khớp với tài liệu Google Rules |
| **RUL-02** | Rules | Rule `code-quality` dùng `trigger: glob` kèm `globs` | `.agents/rules/code-quality.md` | Đọc trường `trigger`, `globs`, `description` | Có đủ `trigger: glob`, chuỗi `globs` và `description` | Đầy đủ 3 trường hợp lệ | **PASS** | Pattern glob bao phủ các ngôn ngữ phổ biến |
| **RUL-03** | Rules | Phát hiện và từ chối trigger rule không hợp lệ | Fixture `invalid-rule-trigger.md` | Chạy test validator với trigger giả lập `invalid_trigger` | Báo lỗi không thuộc enum hỗ trợ | Validator bắt lỗi chính xác và cảnh báo | **PASS** | Kiểm chứng qua fixture negative test |
| **SKI-01** | Skills | Skill `project-onboarding` có name và description hợp lệ | `.agents/skills/project-onboarding/SKILL.md` | Kiểm tra trường `name` và `description` | `name` là chữ thường gạch nối; `description` giải thích rõ khi nào dùng | `name: project-onboarding`, description chi tiết | **PASS** | Đúng hướng dẫn Skills của Google |
| **SKI-02** | Skills | Cấu trúc thư mục skill đúng vị trí | Thư mục chứa `SKILL.md` | Tên thư mục phải trùng với trường `name` | Tên thư mục `project-onboarding` khớp với `name` | Khớp 100% | **PASS** | Đường dẫn `.agents/skills/project-onboarding/SKILL.md` |
| **SKI-03** | Skills | Bắt lỗi thiếu metadata bắt buộc trong skill | Fixture `invalid-skill-frontmatter.md` | Chạy validator với skill thiếu `description` | Báo lỗi thiếu trường bắt buộc | Validator phát hiện lỗi thiếu `description` | **PASS** | Fixture kiểm thử âm tính |
| **AGN-01** | Agents | Agent mẫu `code-reviewer` khai báo đúng schema | `.agents/agents/code-reviewer.md` | Đọc `name`, `description`, `model`, `tools` | Có đủ các trường, `model: inherit` | Khai báo chuẩn Google schema | **PASS** | `agy --agent code-reviewer` hợp lệ |
| **AGN-02** | Agents | Phân quyền tối thiểu (Least Privilege) cho agent | `.agents/agents/code-reviewer.md` | Kiểm tra danh sách `tools` | Chỉ chứa `view_file`; không có `run_command`, `edit_file`, `write_file` | Chỉ có 1 tool `view_file` | **PASS** | Ngăn chặn rủi ro sửa code tùy tiện |
| **AGN-03** | Agents | Từ chối model ID cụ thể trong frontmatter | Fixture `invalid-agent-model.md` | Đặt `model: gemini-3.8-flash-high` | CLI từ chối nạp agent (`no custom agents are available`) | Đã kiểm chứng thực nghiệm trên CLI 1.4.10: CLI từ chối agent nếu dùng raw model ID | **PASS** | Kiểm nghiệm thực tế tại bước khảo sát |
| **DOC-01** | Tài liệu | Liên kết nội bộ trên toàn bộ repo nhất quán | Toàn bộ 19 file .md trong workspace | Kiểm tra sự tồn tại của các đường dẫn được tham chiếu | Tất cả các đường dẫn tương đối đều trỏ đến file thực tế | 100% link nội bộ hợp lệ, không broken link | **PASS** | Script tự động quét link markdown toàn bộ repo |
| **JSON-01**| Cấu hình | Toàn bộ file JSON trong template parse hợp lệ | Các file `.json` trong workspace | `ConvertFrom-Json` trên từng file | Không có lỗi cú pháp JSON | Tất cả 3 file JSON parse thành công | **PASS** | Quét đệ quy JSON validator |
| **HOK-01** | Extensions | Lifecycle Hooks dùng matcher `file_change` | `extensions/hooks/hooks.example.json` | Kiểm tra matcher của `PostToolUse` | Dùng matcher `file_change`, không dùng `edit_file` | Khớp chính xác `file_change` | **PASS** | Loại bỏ matcher cũ không tương thích |
| **PLG-01** | Extensions | Manifest Plugin có đầy đủ metadata | `extensions/plugin/example-plugin/plugin.json` | Kiểm tra `name`, `version`, `description`, `license` | Đầy đủ 4 trường cốt lõi theo chuẩn Google Plugin | Đầy đủ 100% các trường | **PASS** | Manifest validator |
| **SEC-01** | Bảo mật | Không chứa secrets, token hoặc credential mẫu | Toàn bộ repository | Quét Regex tìm chuỗi API key (`AIza...`, `ghp_...`, `Bearer...`, Private Keys) | Không tìm thấy bất kỳ secret nào | Quét sạch 100%, không có secret lộ lọt | **PASS** | Regex scan trong test script |
| **SEC-02** | Bảo mật | Không có hướng dẫn hoặc lệnh phá hủy dữ liệu | `AGENTS.md` & Rules | Rà soát các lệnh shell và hướng dẫn | Mọi thao tác nguy hiểm đều bị cấm tường minh | Có quy định cấm rõ ràng trong rule bảo mật | **PASS** | Quy tắc cấm `git reset --hard`, `git push --force`... |
| **RES-01** | Tính tái sử dụng | Sao chép sang workspace mới và kiểm tra lại | Workspace tạm thời mới | Copy template sang thư mục tạm, chạy script kiểm tra | Pass 100% tại workspace mới | Workspace mới độc lập và vượt qua toàn bộ test | **PASS** | Kiểm chứng khả năng portable |
| **CLI-01** | Tích hợp CLI | CLI nhận diện agent mẫu `code-reviewer` | Thư mục chứa template | Gọi `agy --agent invalid-name -p "test"` | CLI hiển thị `available: code-reviewer` | CLI nhận diện đúng `code-reviewer` | **PASS** | Kết quả thực tế từ binary `agy.exe` |
| **CLI-02** | Tích hợp CLI | CLI thực thi session với subagent độc lập | Phiên tương tác non-interactive | Gọi `agy --agent code-reviewer -p "review"` | Agent thực thi một lượt phản hồi theo đúng vai trò | `agy -p` hoàn thành với mã thoát 0 | **PASS** | Kiểm chứng thực tế qua CLI |
| **CLI-03** | Tích hợp CLI | Đa subagent song song tự động kích hoạt trong 1 turn | Runtime CLI non-interactive | Tự động spawn background subagent trong `agy -p` | Mô hình tự động spawn subagent song song | Chưa thực hiện vì `agy -p` non-interactive chỉ chạy 1 turn và không kích hoạt loop background agent nếu không có prompt chuỗi | **NOT TESTED** | Giới hạn kỹ thuật của chế độ non-interactive print mode |
| **CLI-04** | Tích hợp CLI | CLI validate thành công plugin extension | Thư mục `extensions/plugin/example-plugin` | Gọi `agy plugin validate .\extensions\plugin\example-plugin --strict` | CLI báo `Validation passed` | `✔ Validation passed` thành công 100% | **PASS** | Lệnh kiểm tra chính thức của Antigravity CLI |
| **MNT-01** | Khả năng bảo trì | Sửa đổi quy tắc không làm gãy các file khác | Chỉnh sửa nội dung rule | Chạy lại test suite sau mỗi thay đổi | Không có lỗi liên đới | Các module độc lập, thay đổi cục bộ an toàn | **PASS** | Kiểm chứng tính module hóa |

---

## 3. Kết luận nghiệm thu

Template đã vượt qua 23/24 tiêu chí kiểm thử nghiêm ngặt, bao gồm kiểm tra tĩnh cấu trúc, cú pháp JSON/YAML, phân quyền Least Privilege, quét an ninh secrets, và kiểm tra động trên binary `agy 1.4.10` thực tế (gồm cả agent execution và `agy plugin validate --strict`). 1 tiêu chí chưa kiểm chứng (CLI-03) đã được ghi nhận rõ ràng nguyên nhân kỹ thuật do giới hạn của single-turn print mode.
