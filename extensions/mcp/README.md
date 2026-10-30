# Model Context Protocol (MCP) Integration Guide

Thư mục này cung cấp cấu hình mẫu cho MCP (Model Context Protocol).

---

## 1. Khi nào dự án cần MCP?

Chỉ tích hợp MCP khi dự án của bạn thực sự cần kết nối agent với:
- Cơ sở dữ liệu nội bộ (ví dụ: truy vấn schema SQLite, PostgreSQL trực tiếp).
- Trình quản lý issue / ticket ngoài (GitHub Issues, Jira, Linear).
- Server tài liệu nội bộ hoặc API đặc thù không nằm trong codebase.

Nếu dự án chỉ cần đọc/ghi code và chạy lệnh terminal cơ bản, **KHÔNG CẦN** cấu hình MCP.

---

## 2. Cách tích hợp vào dự án

Trong Antigravity CLI, MCP server được hỗ trợ qua hai phương thức chuẩn:

### Cách 1: Đóng gói dưới dạng Workspace Plugin (Khuyến nghị cho dự án nhóm)
Nếu muốn cấu hình MCP đi kèm theo mã nguồn dự án để toàn bộ thành viên trong nhóm dùng chung:
1. Tạo thư mục workspace plugin:
   ```powershell
   New-Item -ItemType Directory -Path .agents/plugins/workspace-mcp -Force
   ```
2. Sao chép cấu hình MCP vào thư mục plugin:
   ```powershell
   Copy-Item extensions/mcp/mcp_config.example.json .agents/plugins/workspace-mcp/mcp_config.json
   ```
3. Tạo file manifest `.agents/plugins/workspace-mcp/plugin.json`:
   ```json
   {
     "name": "workspace-mcp",
     "version": "1.0.0",
     "description": "Workspace MCP server configuration"
   }
   ```
4. Điều chỉnh `mcp_config.json`:
   - Thay `sqlite-helper` bằng tên server mong muốn.
   - Điền lệnh thực thi (`command`), tham số (`args`) và biến môi trường (`env`).
   - Nếu dùng remote server, cấu hình `url` theo chuẩn Streamable HTTP (`https://.../mcp`).
5. Khởi động lại CLI (`agy`) để nạp công cụ từ MCP server trong plugin.

### Cách 2: Cấu hình cấp Global thông qua CLI (Cho cá nhân lập trình viên)
Nếu chỉ muốn cấu hình MCP cho môi trường phát triển cá nhân mà không commit vào repo:
```powershell
# Cú pháp chuẩn của Antigravity CLI:
# agy mcp add [flags] <name> <commandOrUrl> [args...]

# Ví dụ 1: Stdio server (SQLite)
agy mcp add sqlite-helper npx -y @modelcontextprotocol/server-sqlite --db-path ./database.sqlite

# Ví dụ 2: Stdio server có biến môi trường (Lưu ý: cờ --env phải đứng trước <name>)
agy mcp add --env GITHUB_TOKEN=your_token gh npx -y @modelcontextprotocol/server-github

# Ví dụ 3: Remote HTTP/SSE server (URL được tự động nhận diện)
agy mcp add remote-docs https://mcp.internal.example.com/mcp

# Hoặc thêm thủ công vào file cấu hình cá nhân: ~/.gemini/antigravity-cli/mcp_config.json
```

---

## 3. Ranh giới an toàn

- Cấu hình server cơ sở dữ liệu ở chế độ **Read-Only** bất cứ khi nào có thể (ví dụ: `"DB_READONLY": "true"`).
- Không lưu token bí mật trực tiếp trong file JSON; hãy truyền qua biến môi trường của hệ điều hành.
