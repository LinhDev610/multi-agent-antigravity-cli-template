---
name: project-onboarding
description: "Use this skill when onboarding to a new codebase, discovering project structure, verifying environment prerequisites, or mapping available tooling."
---

# Project Onboarding & Discovery Skill

Quy trình chuẩn hóa giúp agent khảo sát nhanh một repository mới, nhận diện công nghệ, kiểm tra tính sẵn sàng của môi trường và thiết lập bức tranh toàn cảnh trước khi tiến hành viết code.

---

## 1. Đầu vào cần thu thập (Inputs)

- Đường dẫn gốc của repository.
- Mục tiêu cần tìm hiểu: Cấu trúc thư mục, công nghệ sử dụng, cách build, test và run.

---

## 2. Các bước thực hiện (Workflow Steps)

### Bước 1: Khảo sát cấu trúc cấp cao
- Liệt kê các thư mục và file ở thư mục gốc:
  - Nhận diện file cấu hình dự án: `package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, `Cargo.toml`, `Makefile`, `Dockerfile`.
  - Đọc file `README.md` (hoặc `CONTRIBUTING.md`) để nắm mục đích tổng quan.

### Bước 2: Nhận diện stack công nghệ và công cụ
- Xác định ngôn ngữ lập trình chính và framework.
- Xác định công cụ quản lý package (`npm`, `pnpm`, `pip`, `poetry`, `uv`, `go`, `cargo`).
- Xác định công cụ kiểm thử (`jest`, `pytest`, `go test`, `cargo test`, `junit`).

### Bước 3: Kiểm tra tính sẵn sàng của môi trường
- Chạy lệnh kiểm tra phiên bản công cụ tương ứng:
  - Node: `node --version`, `npm --version`
  - Python: `python --version`
  - Git status: `git status -s`
- Xác nhận các file cấu hình môi trường mẫu (`.env.example`) và ghi chú nếu thiếu biến môi trường cần thiết.

### Bước 4: Tổng hợp bản đồ dự án
- Tóm tắt kết quả theo định dạng chuẩn bên dưới.

---

## 3. Đầu ra chuẩn hóa (Standard Output Format)

Khi hoàn thành quy trình khảo sát, xuất báo cáo tóm tắt:

```markdown
### PROJECT ONBOARDING SUMMARY
- **Ngôn ngữ & Framework:** [Tên ngôn ngữ, Framework chính]
- **Package Manager:** [Công cụ quản lý thư viện]
- **Lệnh Build / Test:** [Lệnh biên dịch và chạy test]
- **Trạng thái môi trường:** [OK | THIẾU DEPENDENCY | CẦN CẤU HÌNH ENV]
- **Lưu ý kiến trúc:** [Điểm đặc thù trong cấu trúc code nếu có]
```

---

## 4. Tiêu chí nghiệm thu (Verification)

- [ ] Đã đọc và hiểu mục tiêu dự án từ `README.md`.
- [ ] Đã xác định được lệnh test chính xác.
- [ ] Không làm thay đổi bất kỳ file mã nguồn nào trong quá trình khảo sát.
