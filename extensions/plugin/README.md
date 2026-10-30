# Plugin Extension Guide

Thư mục này hướng dẫn cách đóng gói và phân phối các tùy biến Antigravity dưới dạng Plugin.

---

## 1. Khi nào nên dùng Plugin?

- Khi bạn muốn chia sẻ một bộ công cụ, rules, skills hoặc MCP chung cho nhiều thành viên trong nhóm hoặc nhiều repository khác nhau mà không cần sao chép thủ công từng file.
- Khi bạn muốn cài đặt/gỡ bỏ các năng lực agent theo dạng module thông qua lệnh:
  ```powershell
  agy plugin install <path-or-repo>
  agy plugin list
  agy plugin enable <name>
  agy plugin disable <name>
  ```

---

## 2. Cấu trúc một Plugin chuẩn

Một thư mục plugin hợp lệ có cấu trúc:

```text
my-plugin/
├── plugin.json       # Bắt buộc: Khai báo manifest của plugin
├── rules/            # Tùy chọn: Rules nạp khi plugin kích hoạt (khuyên dùng AGENTS.md)
│   └── AGENTS.md
├── skills/           # Tùy chọn: Các skill do plugin cung cấp
│   └── <skill-name>/
│       └── SKILL.md
├── hooks.json        # Tùy chọn: Lifecycle hooks do plugin quản lý
└── mcp_config.json   # Tùy chọn: MCP server cấu hình riêng cho plugin
```

---

## 3. Quản lý trạng thái Plugin

- Plugin được phát hiện tự động nếu đặt trong `.agents/plugins/<name>/` (phạm vi workspace) hoặc `~/.gemini/config/plugins/<name>/` (phạm vi global).
- Mặc định plugin được kích hoạt (`enabled`). Bạn có thể tắt tạm thời bằng cờ `"disabled": true` trong `plugin.json` hoặc dùng lệnh CLI `agy plugin disable <name>`.
