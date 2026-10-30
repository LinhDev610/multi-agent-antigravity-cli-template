# Hướng Dẫn Tích Hợp Dự Án & Tạo Prompt Chuẩn Cho AI Agent

Tài liệu này cung cấp cẩm nang thực chiến từng bước để đưa Antigravity Template vào một dự án phần mềm mới hoặc dự án sẵn có (legacy), phương pháp khảo sát mã nguồn và tài liệu mà không làm tràn ngữ cảnh (context preservation), cùng khung cấu trúc **COCV** để tạo các prompt chính xác 100% cho AI Agent thi hành.

---

## 1. Triết lý Tích hợp: Tinh gọn & Khảo sát có định hướng

Khi áp dụng AI Agent vào một dự án phần mềm thực tế, hai sai lầm lớn nhất mà lập trình viên thường mắc phải là:
1. **Bảo AI "Hãy đọc toàn bộ dự án này đi"**:
   - Khiến context window bị lấp đầy bởi hàng chục ngàn dòng mã nguồn không liên quan.
   - Dẫn đến hiện tượng cạn kiệt token, phản hồi chậm chạp và mô hình bị phân tán chú ý (attention degradation), dẫn đến ảo giác (hallucination).
2. **Gửi prompt cụt lủn, thiếu ràng buộc**:
   - Ví dụ: *"Hãy sửa lỗi đăng nhập"* hoặc *"Thêm chức năng giỏ hàng"*.
   - AI sẽ tự suy diễn theo kiến trúc quen thuộc của nó, tự ý cài đặt thêm thư viện lạ, thay đổi style code của dự án hoặc phá vỡ các API có sẵn.

**Mục tiêu của tài liệu này**: Thiết lập một quy trình 4 bước chuẩn hóa để chuyển đổi một codebase bất kỳ thành môi trường thân thiện với AI, và cung cấp khung tạo prompt chuẩn xác giúp Agent luôn đi đúng hướng.

---

## 2. Quy trình 4 Bước Tích Hợp Template vào Dự Án Mới

```text
       ┌────────────────────────────────────────────────────────┐
       │ Bước 1: Khởi tạo Template & Kiểm tra Môi trường        │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ Bước 2: Khảo sát Mã nguồn bằng Skill Onboarding        │
       │         (Không làm tràn Context Window)                │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ Bước 3: Bản địa hóa AGENTS.md & Workspace Rules        │
       └──────────────────────────┬─────────────────────────────┘
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │ Bước 4: Tạo Prompt Chuẩn theo Khung COCV để Thực thi   │
       └────────────────────────────────────────────────────────┘
```

### Bước 1: Khởi tạo Template & Kiểm tra Môi trường

Đi tới thư mục gốc dự án của bạn và sao chép các thành phần nền tảng từ template:

```powershell
# 1. Đảm bảo dự án đã được khởi tạo Git (Antigravity yêu cầu .git để định vị root)
git status
# Nếu chưa có Git: git init

# 2. Sao chép AGENTS.md và thư mục .agents từ template sang dự án của bạn
Copy-Item -Path "path\to\antigravity-project-template\AGENTS.md" -Destination ".\AGENTS.md"
Copy-Item -Path "path\to\antigravity-project-template\.agents" -Destination ".\" -Recurse

# 3. (Khuyến nghị) Sao chép bộ test để kiểm tra tính hợp lệ
Copy-Item -Path "path\to\antigravity-project-template\tests" -Destination ".\" -Recurse

# 4. Chạy script kiểm tra tự động
powershell -ExecutionPolicy Bypass -File .\tests\test_template.ps1
```

### Bước 2: Khảo sát Mã nguồn Thông minh (Context-Efficient Survey)

Thay vì để AI tự động duyệt đệ quy toàn bộ thư mục, hãy kích hoạt Skill [`.agents/skills/project-onboarding/SKILL.md`](../.agents/skills/project-onboarding/SKILL.md). Skill này hướng dẫn Agent thực hiện khảo sát tuần tự theo 4 mức nông-sâu:

1. **Khảo sát Tệp Quản lý Gói (Package Manifest)**:
   - Node.js: `package.json` (xem dependencies, scripts build/test/lint).
   - Python: `pyproject.toml`, `requirements.txt`, `setup.py`.
   - Go: `go.mod`.
   - Java: `pom.xml` hoặc `build.gradle`.
   - .NET: `*.csproj`, `Directory.Build.props`.
2. **Khảo sát Tài liệu Hiện Hữu**:
   - Đọc lướt `README.md`, `CONTRIBUTING.md`, `ARCHITECTURE.md` (nếu có).
3. **Lập Bản đồ Cây Thư mục Nông (Depth 1-2)**:
   - Chỉ liệt kê các thư mục cấp cao nhất (ví dụ: `src/`, `tests/`, `docs/`, `config/`).
   - Phân loại kiến trúc tổng quan: Monorepo vs Single repo, Clean Architecture, MVC hay Microservices.
4. **Xác minh Bộ Công Cụ (Tooling Verification)**:
   - Kiểm tra xem máy đã cài các công cụ cần thiết chưa: Node, Python, Docker, Go, v.v.

### Bước 3: Bản địa hóa `AGENTS.md` & Workspace Rules

Sau khi khảo sát, hãy cập nhật các thông tin đặc thù của dự án vào 2 file sau:

#### A. Cập nhật `AGENTS.md`:
Điền các lệnh build, test, lint thực tế của dự án vào **Mục 3 (Quy trình làm việc chuẩn)**:
```markdown
## 3. Quy trình làm việc chuẩn (Standard Workflow)
...
- Lệnh kiểm tra cú pháp & lint: `npm run lint` (hoặc `ruff check .`, `golangci-lint run`)
- Lệnh kiểm thử tự động: `npm test` (hoặc `pytest`, `go test ./...`)
- Lệnh biên dịch dự án: `npm run build` (hoặc `mvn compile`, `dotnet build`)
```

#### B. Cập nhật `.agents/rules/code-quality.md`:
Điều chỉnh trường `globs` trong frontmatter để khớp chính xác với ngôn ngữ dự án:
```markdown
---
trigger: glob
globs: "*.ts, *.tsx, *.json"
description: "Quy chuẩn mã nguồn TypeScript và JSON cho dự án Web"
---
```
Đồng thời ghi thêm các quy ước quan trọng của nhóm (ví dụ: *"Ưu tiên dùng functional components và React hooks"*, *"Mọi API call phải xử lý lỗi qua Result pattern"*).

---

## 3. Kỹ thuật Đọc Hiểu Codebase Lớn Không Làm Tràn Context

Khi làm việc với các codebase lớn (hàng trăm file mã nguồn), Agent cần áp dụng 4 kỹ thuật tiết kiệm ngữ cảnh:

### 3.1. Tìm kiếm theo tọa độ (Targeted Search)
- **Không**: `list_dir` toàn bộ thư mục `src/` có 2000 file.
- **Nên**:
  - Dùng `find_by_name` với đuôi file hoặc tên cụ thể: `Pattern: "*AuthService*"`
  - Dùng `grep_search` với từ khóa chính xác: `Query: "export class AuthService"` hoặc `Query: "router.post('/login'"`

### 3.2. Đọc Phân Đoạn (Slice Reading)
- **Không**: `view_file` toàn bộ file 1500 dòng khi chỉ cần xem 1 hàm xử lý token.
- **Nên**: Xác định số dòng trước qua grep, sau đó gọi `view_file` với `StartLine: 40` và `EndLine: 95`.

### 3.3. Khảo sát Schema & Interface trước (Schema-First)
- Trước khi đọc logic thực thi phức tạp (implementation), hãy đọc các file định nghĩa kiểu dữ liệu:
  - TypeScript: `*.types.ts`, `*.d.ts`, `interface.ts`
  - Database: `schema.sql`, `migrations/*.sql`, `schema.prisma`
  - Protobuf: `*.proto`
- Việc này giúp Agent hiểu toàn bộ cấu trúc dữ liệu và quan hệ thực thể chỉ với vài trăm token.

### 3.4. Neo theo Lịch sử Git (Git Anchoring)
- Chạy lệnh `git log -n 5 --oneline` để xem các commit gần nhất.
- Đọc git diff của commit sửa lỗi tương tự để học phong cách viết code và cấu trúc test của nhóm.

---

## 4. Phương Pháp Trích Xuất Quy Ước (Conventions), Kiến Trúc (Architecture) & Ràng Buộc Nghiệp Vụ (Business Constraints)

Để AI Agent không phạm sai lầm khi tạo code mới, bạn cần biết chính xác cách tìm và trích xuất 3 trụ cột tri thức cốt lõi từ codebase và tài liệu dự án:

### 4.1. Trích xuất Quy ước Lập trình (Code Conventions & Style)

Quy ước code giúp Agent sinh mã hòa nhập liền mạch với phần còn lại của dự án thay vì mang phong cách ngoại lai:

| Thành tố quy ước | Nơi tìm kiếm trong dự án | Hành động trích xuất của Agent |
|---|---|---|
| **Linter & Formatter** | `eslint.config.*`, `.prettierrc`, `ruff.toml`, `.flake8`, `golangci.yml`, `checkstyle.xml`, `.editorconfig` | Đọc cấu hình để biết: indent (tabs vs 2/4 spaces), quotes (single vs double), trailing commas, semi-colons. |
| **Quy chuẩn đặt tên (Naming)** | Tên file trong `src/`, tên function, class và interface | Quan sát: `kebab-case` cho tên file (`auth-service.ts`) vs `camelCase`, `I`-prefix cho interfaces (`IUserRepository`) hay không. |
| **Cấu trúc hàm & Xử lý lỗi** | Các file service hiện có | Xem dự án ném Exception trực tiếp (`throw new NotFoundException()`) hay dùng Result pattern (`return Result.err(Error)`). |

### 4.2. Trích xuất Kiến trúc Dự án (Architecture Style & Dependency Flow)

Hiểu ranh giới kiến trúc ngăn Agent phá vỡ các nguyên lý thiết kế của hệ thống:

```text
Các mô hình kiến trúc phổ biến và ranh giới bất biến:
1. Clean / Hexagonal: Domain (Entity/ValueObject) ◄── Application (UseCase) ◄── Infrastructure (DB/API)
   ► Ràng buộc: Domain TUYỆT ĐỐI KHÔNG import thư viện ngoài hoặc framework DB.
2. Layered MVC: Controller ──► Service ──► Repository ──► Database
   ► Ràng buộc: Controller không gọi DB trực tiếp; Repository không chứa nghiệp vụ.
3. Feature-Sliced (FSD): app ──► pages ──► widgets ──► features ──► entities ──► shared
   ► Ràng buộc: Slice chỉ được import các module ở layer thấp hơn nó.
```

- **Cách trích xuất nhanh**:
  - Dùng `find_by_name` ở thư mục `src/` với `MaxDepth: 2` để xem cấu trúc phân chia thư mục (theo technical layer hay theo business feature).
  - Đọc 1 file Controller hoặc Service mẫu để kiểm tra cơ chế Dependency Injection (NestJS `@Injectable()`, Spring `@Service`, Go constructor `NewAuthService(repo)`).
  - Xác định thư viện truy cập dữ liệu (ORM như Prisma, TypeORM, SQLAlchemy vs Query Builder hay Raw SQL).

### 4.3. Trích xuất Tài liệu Dự án & Ràng buộc Nghiệp vụ (Business Constraints & Domain Invariants)

Ràng buộc nghiệp vụ là những điều luật kinh doanh bắt buộc mà máy tính không thể tự suy đoán nếu không được cung cấp:

| Loại ràng buộc | Nơi trích xuất từ codebase & tài liệu | Ví dụ thực tế cần đưa vào Prompt |
|---|---|---|
| **Tài liệu & Đặc tả API** | `docs/`, `wiki/`, `openapi.yaml`, `swagger.json`, `schema.graphql` | Cấu trúc payload request/response bắt buộc, HTTP Status Codes, error envelope. |
| **Bất biến Dữ liệu (Invariants)** | Validation DTOs (`class-validator`, `zod`, `pydantic`), Database Constraints | *"Số dư tài khoản không được âm"*, *"Đơn hàng đã hủy không được cập nhật trạng thái khác"*. |
| **Phân quyền & Bảo mật** | Auth Guards, Decorators (`@Roles`, `@RequirePermission`), Middleware | *"Chỉ Admin hoặc chủ sở hữu tài nguyên mới có quyền sửa"*, *"Mọi API public phải rate-limit"*. |
| **Giao dịch (Transactions)** | File repository hoặc service xử lý thanh toán/đơn hàng | *"Các thao tác trừ tồn kho và ghi log thanh toán bắt buộc nằm trong cùng một Database Transaction"*. |

### 4.4. Cầu Nối: Ma Trận Chuyển Đổi Từ Khảo Sát Sang Prompt Chuẩn COCV

Toàn bộ thông tin trích xuất được ở trên được phân bổ vào template và prompt theo sơ đồ chuẩn:

```text
Codebase & Docs Dự Án
        │
        ├──► Lệnh build, test, lint   ──────────► AGENTS.md (Mục 3) ────► [VERIFICATION CRITERIA]
        │
        ├──► Quy chuẩn linter, style  ──────────► .agents/rules/ ───────► [CONSTRAINTS]
        │
        ├──► Ranh giới kiến trúc      ──────────► .agents/rules/ ───────► [CONSTRAINTS]
        │
        ├──► Invariants & nghiệp vụ   ──────────► Prompt Context ───────► [CONSTRAINTS]
        │
        └──► Tọa độ file, interfaces  ──────────► Targeted Search ──────► [CONTEXT]
```

---

## 5. Khung Cấu Trúc Prompt Chuẩn 4 Thành Tố (Khung COCV)

Để loại bỏ hoàn toàn sự mơ hồ và đảm bảo AI Agent thực thi chính xác 100%, mọi prompt giao việc đều nên tuân thủ khung cấu trúc **COCV**:

```text
       ┌────────────────────────────────────────────────────────┐
       │ C - Context (Bối cảnh & Tọa độ file chính xác)        │
       ├────────────────────────────────────────────────────────┤
       │ O - Objective (Mục tiêu cốt lõi & Kết quả mong đợi)    │
       ├────────────────────────────────────────────────────────┤
       │ C - Constraints (Ràng buộc kỹ thuật & Giới hạn an toàn)│
       ├────────────────────────────────────────────────────────┤
       │ V - Verification Criteria (Tiêu chí nghiệm thu & Test) │
       └────────────────────────────────────────────────────────┘
```

### Chi tiết 4 thành tố:

| Thành tố | Ý nghĩa | Câu hỏi cần trả lời |
|---|---|---|
| **C — Context** | Bối cảnh | Task này thuộc module nào? File nào cần đọc/sửa? Link ticket hoặc tài liệu tham khảo là gì? |
| **O — Objective** | Mục tiêu | Kết quả đầu ra cụ thể là gì? Thêm hàm nào? Sửa hành vi gì? Định dạng trả về ra sao? |
| **C — Constraints** | Ràng buộc | Những gì CẤM làm? (Không cài thêm thư viện, giữ nguyên API public, không sửa database schema, tương thích ngược)? |
| **V — Verification** | Nghiệm thu | Chạy lệnh test nào để chứng minh thành công? Input/Output mẫu là gì? Cần bao phủ edge case nào? |

---

## 6. Thư Viện Mẫu Prompt Thực Chiến (Prompt Templates)

Dưới đây là 5 mẫu prompt chuẩn hóa sẵn sàng sao chép và điền thông tin để giao việc cho AI Agent:

---

### Mẫu 1: Thêm Tính Năng Mới (Feature Implementation)

```text
[CONTEXT]
Tôi cần phát triển tính năng xác thực hai yếu tố (2FA) qua mã TOTP cho hệ thống.
- Module liên quan: `src/modules/auth/`
- Các file cần tham khảo: `src/modules/auth/auth.service.ts` và `src/modules/users/user.entity.ts`.
- Đã có sẵn thư viện `otplib` trong `package.json`.

[OBJECTIVE]
1. Tạo method `generate2FASecret(userId: string)` trong `auth.service.ts` để sinh mã QR URL và secret.
2. Tạo method `verify2FACode(userId: string, code: string): boolean` để xác thực mã 6 số người dùng nhập.
3. Cập nhật endpoint `/api/auth/verify-2fa` trong `auth.controller.ts`.

[CONSTRAINTS]
- Không cài đặt thêm bất kỳ thư viện ngoài nào khác; chỉ sử dụng `otplib` đã có.
- Giữ nguyên cấu trúc trả về hiện tại của các API đăng nhập cũ (backward compatible).
- Secret TOTP lưu trong database phải được mã hóa AES-256 trước khi lưu (sử dụng `src/utils/crypto.ts`).
- Tuân thủ quy chuẩn xử lý lỗi tại `.agents/rules/code-quality.md`.

[VERIFICATION CRITERIA]
- Viết unit test mới trong `src/modules/auth/auth.service.spec.ts` bao phủ:
  + Test thành công khi mã TOTP hợp lệ.
  + Test thất bại khi mã TOTP sai hoặc hết hạn.
  + Test trường hợp secret trống hoặc user không tồn tại.
- Chạy lệnh: `npm test -- src/modules/auth/auth.service.spec.ts` và toàn bộ test phải PASS 100%.
- Chạy `npm run lint` không có bất kỳ warning hoặc error nào.
```

---

### Mẫu 2: Sửa Lỗi / Gỡ Bug (Bug Fixing & RCA)

```text
[CONTEXT]
Hệ thống gặp lỗi crash khi xử lý đơn hàng có mã giảm giá 100%.
- Bug ID: #BUG-412
- File nghi vấn: `src/services/checkout.service.ts`, hàm `calculateFinalAmount()`.
- Lỗi ghi nhận trong log: `ZeroDivisionError: division by zero` hoặc `NaN` được ghi vào bảng `orders`.

[OBJECTIVE]
1. Điều tra nguyên nhân gốc rễ (Root Cause Analysis - RCA) tại sao mã giảm giá 100% gây lỗi tính toán hoặc lỗi cổng thanh toán.
2. Sửa logic tính toán để đơn hàng 0 VNĐ được xử lý hợp lệ mà không gọi cổng thanh toán thẻ.
3. Đảm bảo trạng thái đơn hàng chuyển đúng thành `PAID_PROMOTIONAL`.

[CONSTRAINTS]
- Tập trung diff: Chỉ sửa đổi logic tính toán trong `checkout.service.ts`, không tái cấu trúc các service khác.
- Không thay đổi kiểu dữ liệu cột trong database.
- Giữ nguyên toàn bộ comment và docstring hiện có.

[VERIFICATION CRITERIA]
- Tạo regression test trong `tests/checkout.test.ts` tái hiện đúng kịch bản giảm giá 100%.
- Chạy lệnh: `npm test -- tests/checkout.test.ts`.
- Đảm bảo các test case cũ của đơn hàng bình thường vẫn tiếp tục PASS.
```

---

### Mẫu 3: Tái Cấu Trúc Mã Nguồn (Refactoring)

```text
[CONTEXT]
File `src/controllers/order.controller.ts` hiện tại có kích thước hơn 800 dòng và chứa quá nhiều logic nghiệp vụ (Fat Controller).
- Kiến trúc dự án: Layered Architecture (Controller -> Service -> Repository).

[OBJECTIVE]
1. Tách toàn bộ logic nghiệp vụ (tính phí ship, trừ tồn kho, gửi email thông báo) ra một service mới: `src/services/order-fulfillment.service.ts`.
2. Controller chỉ giữ vai trò nhận request, validate DTO đầu vào và gọi service.

[CONSTRAINTS]
- Bảo toàn 100% hành vi bên ngoài (Zero Behavior Change): Toàn bộ HTTP routes, response status codes, payload JSON trả về cho frontend KHÔNG ĐƯỢC PHÉP thay đổi dù chỉ 1 trường.
- Áp dụng Dependency Injection theo chuẩn hiện có của dự án.
- Không xóa hay bỏ qua bất kỳ unit test nào có sẵn để đối phó.

[VERIFICATION CRITERIA]
- Chạy toàn bộ test suite của module order: `npm test -- tests/order/`.
- Toàn bộ các end-to-end (E2E) integration tests phải PASS mà không cần sửa test suite.
```

---

### Mẫu 4: Đánh Giá Mã Nguồn & Thẩm Định Bảo Mật (Code Review)

```powershell
# Chạy đánh giá bằng custom subagent code-reviewer (chỉ có quyền view_file)
agy --agent code-reviewer -p @"
[CONTEXT]
Đánh giá các thay đổi trong Pull Request vừa hoàn thiện tại module thanh toán: `src/modules/payment/`.

[OBJECTIVE]
Thực hiện đánh giá mã nguồn (Read-Only Code Review) tập trung vào:
1. Lỗ hổng bảo mật: SQL Injection, rò rỉ secret, thiếu kiểm tra quyền sở hữu tài nguyên (IDOR).
2. Xử lý lỗi & Edge cases: Null pointer, timeout, mất kết nối cơ sở dữ liệu khi thanh toán dở dang.
3. Tuân thủ quy chuẩn: Kiểm tra đối chiếu với `.agents/rules/code-quality.md`.

[CONSTRAINTS]
- Bạn là Read-Only reviewer; TUYỆT ĐỐI KHÔNG sửa file hay đề xuất viết code mới trực tiếp lên disk.
- Mỗi phát hiện phải kèm theo đường dẫn file chính xác và số dòng (ví dụ `payment.service.ts:114`).

[VERIFICATION CRITERIA]
Xuất báo cáo theo cấu trúc chuẩn:
- Tóm tắt tổng quan: Sẵn sàng merge hay cần chỉnh sửa?
- Danh sách vi phạm (nếu có) phân loại theo mức độ: [Nghiêm trọng / Trung bình / Khuyến nghị].
"@
```

---

### Mẫu 5: Nâng Cấp / Migration Thư Viện (Library Migration)

```text
[CONTEXT]
Dự án cần nâng cấp thư viện ORM từ TypeORM `0.2.x` lên `0.3.x`.
- File manifest: `package.json`
- Các file repository bị ảnh hưởng: `src/repositories/*.ts`

[OBJECTIVE]
1. Cập nhật các khai báo custom repository từ cú pháp `@EntityRepository()` cũ sang cú pháp `dataSource.getRepository()` mới của TypeORM 0.3.
2. Cập nhật file cấu hình kết nối database trong `src/config/database.ts`.

[CONSTRAINTS]
- Không sửa schema cơ sở dữ liệu.
- Giữ nguyên tên các phương thức nghiệp vụ để không làm gãy tầng Service.

[VERIFICATION CRITERIA]
- Dự án phải biên dịch thành công: `npm run build`.
- Chạy toàn bộ bộ test tích hợp database: `npm run test:db`.
- Không còn bất kỳ cảnh báo deprecation nào từ thư viện ORM khi khởi động ứng dụng.
```

---

## 7. Bảng Đối Chiếu: Prompt Kém vs Prompt Chuẩn

| Yếu tố | Prompt Kém (Dễ gây ảo giác & bug) | Prompt Chuẩn COCV (Chính xác 100%) |
|---|---|---|
| **Độ rõ ràng** | *"Xem code đăng nhập rồi sửa lỗi giúp tôi"* | Chỉ rõ file `auth.service.ts`, hàm `verifyToken`, mã lỗi JWT `TokenExpiredError`. |
| **Công cụ & Thư viện** | *"Làm cách nào tạo ảnh thumbnail nhanh nhất"* | *"Dùng thư viện `sharp` đã có sẵn trong dự án; cấm cài thêm package mới"*. |
| **Phạm vi sửa đổi** | *"Dọn dẹp code cho đẹp hơn"* | *"Chỉ refactor hàm `parseCSV`, không sửa các hàm khác, giữ nguyên signature"*. |
| **Xác minh** | *"Sửa xong nhớ kiểm tra lại nhé"* | *"Chạy `npm test -- tests/csv.spec.ts` và đảm bảo pass 12/12 test cases"*. |

---

## 8. Liên kết tham chiếu trong bộ tài liệu

- Xem lý thuyết nhận thức và cơ chế ReAct: [`KIEN_TRUC_AI_AGENT.md`](KIEN_TRUC_AI_AGENT.md)
- Xem thông số kỹ thuật runtime Antigravity: [`ANTIGRAVITY_RUNTIME_SPEC.md`](ANTIGRAVITY_RUNTIME_SPEC.md)
- Xem hệ thống an toàn và phòng thủ đa tầng: [`AN_TOAN_VA_PHONG_THU_DA_TANG.md`](AN_TOAN_VA_PHONG_THU_DA_TANG.md)
- Xem hướng dẫn gỡ lỗi và telemetry: [`SO_TAY_DEBUG_VA_QUAN_SAT.md`](SO_TAY_DEBUG_VA_QUAN_SAT.md)
- Xem hướng dẫn sử dụng tổng quát: [`HUONG_DAN_SU_DUNG.md`](HUONG_DAN_SU_DUNG.md)
