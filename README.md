# Google Antigravity CLI — Standard Project Template

Template nền tảng chuẩn hóa dành cho **Google Antigravity CLI (`agy 1.4.10`)**, được thiết kế để tái sử dụng cho mọi dự án phần mềm độc lập với ngôn ngữ lập trình và framework.

---

## 1. Cấu trúc nhanh

```text
antigravity-project-template/
├── AGENTS.md                                   # Chỉ dẫn chung toàn workspace (~57 dòng)
├── .agents/                                    # Cấu hình Antigravity của workspace
│   ├── rules/                                  # Rules theo ngữ cảnh
│   │   ├── security-and-secrets.md             # Rule bảo mật (always_on)
│   │   └── code-quality.md                     # Rule chất lượng code (glob)
│   ├── skills/                                 # Quy trình & runbook (progressive disclosure)
│   │   └── project-onboarding/
│   │       └── SKILL.md                        # Skill tiếp nhận & khảo sát dự án
│   └── agents/                                 # Custom subagents
│       └── code-reviewer.md                    # Agent thẩm định mã nguồn (read-only)
├── extensions/                                 # Mở rộng tùy chọn (chỉ dùng khi cần)
│   ├── mcp/                                    # Cấu hình Model Context Protocol
│   ├── hooks/                                  # Cấu hình Lifecycle Hooks
│   └── plugin/                                 # Cấu hình đóng gói Plugin
├── docs/                                       # Tài liệu hướng dẫn & thiết kế
│   ├── HUONG_DAN_SU_DUNG.md                    # Hướng dẫn chi tiết cách sao chép và tùy biến
│   ├── HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md   # Cẩm nang tích hợp dự án & khung prompt COCV
│   ├── KIEN_TRUC_AI_AGENT.md                   # Kiến trúc nhận thức ReAct, Multi-Agent & Token budget
│   ├── ANTIGRAVITY_RUNTIME_SPEC.md             # Đặc tả runtime, modes, effort, Stream-JSON
│   ├── AN_TOAN_VA_PHONG_THU_DA_TANG.md         # Kiến trúc an toàn & phòng thủ 4 lớp
│   ├── SO_TAY_DEBUG_VA_QUAN_SAT.md             # Sổ tay gỡ lỗi, telemetry, transcript analysis
│   ├── QUYET_DINH_THIET_KE.md                  # Hồ sơ quyết định thiết kế kiến trúc (ADR)
│   └── MA_TRAN_KIEM_THU.md                     # Ma trận kiểm thử & kết quả kiểm chứng thực tế
└── tests/                                      # Bộ kiểm tra chất lượng & schema tự động
    ├── test_template.ps1                       # Script PowerShell kiểm tra tự động
    └── fixtures/                               # Dữ liệu kiểm thử âm tính (negative test cases)
```

---

## 2. Bắt đầu nhanh (Quick Start)

Sao chép template vào thư mục dự án mới của bạn:

```powershell
# Tạo hoặc đi đến repository dự án
cd D:\Project\my-project
git init

# Sao chép các thành phần cốt lõi
Copy-Item -Path "path\to\antigravity-project-template\AGENTS.md" -Destination ".\"
Copy-Item -Path "path\to\antigravity-project-template\.agents" -Destination ".\" -Recurse

# Chạy kiểm tra tính hợp lệ
powershell -ExecutionPolicy Bypass -File path\to\antigravity-project-template\tests\test_template.ps1 -TemplateRoot .
```

---

## 3. Bộ tài liệu chuyên sâu

- **Cẩm nang tích hợp & Mẫu Prompt chuẩn COCV**: [docs/HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md](docs/HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md)
- **Hướng dẫn sử dụng & tùy biến**: [docs/HUONG_DAN_SU_DUNG.md](docs/HUONG_DAN_SU_DUNG.md)
- **Kiến trúc nhận thức ReAct, Multi-Agent & Token budget**: [docs/KIEN_TRUC_AI_AGENT.md](docs/KIEN_TRUC_AI_AGENT.md)
- **Đặc tả runtime Antigravity & Stream-JSON**: [docs/ANTIGRAVITY_RUNTIME_SPEC.md](docs/ANTIGRAVITY_RUNTIME_SPEC.md)
- **Kiến trúc an toàn & Phòng thủ đa tầng 4 lớp**: [docs/AN_TOAN_VA_PHONG_THU_DA_TANG.md](docs/AN_TOAN_VA_PHONG_THU_DA_TANG.md)
- **Sổ tay Debug, Telemetry & Trị loop vô hạn**: [docs/SO_TAY_DEBUG_VA_QUAN_SAT.md](docs/SO_TAY_DEBUG_VA_QUAN_SAT.md)
- **Hồ sơ quyết định thiết kế (ADR)**: [docs/QUYET_DINH_THIET_KE.md](docs/QUYET_DINH_THIET_KE.md)
- **Ma trận kiểm thử thực tế**: [docs/MA_TRAN_KIEM_THU.md](docs/MA_TRAN_KIEM_THU.md)
