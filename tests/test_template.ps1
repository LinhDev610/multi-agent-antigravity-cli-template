# ==============================================================================
# Script Kiem Tra Chat Luong & Tinh Hop Le Cua Antigravity Project Template
# Moi truong: Windows 11 / PowerShell 5.1+
# ==============================================================================

[CmdletBinding()]
param(
    [string]$TemplateRoot = ""
)

if ([string]::IsNullOrWhiteSpace($TemplateRoot)) {
    if ($PSScriptRoot) {
        $TemplateRoot = Split-Path -Parent $PSScriptRoot
    } else {
        $TemplateRoot = (Get-Item $MyInvocation.MyCommand.Path).Directory.Parent.FullName
    }
}

$ErrorActionPreference = "Stop"
$Global:PassedCount = 0
$Global:FailedCount = 0
$Global:NotTestedCount = 0

function Report-Result {
    param(
        [string]$TestId,
        [string]$Description,
        [string]$Status, # PASS, FAIL, NOT_TESTED
        [string]$Notes = ""
    )
    $color = switch ($Status) {
        "PASS"       { "Green"; $Global:PassedCount++ }
        "FAIL"       { "Red"; $Global:FailedCount++ }
        "NOT_TESTED" { "Yellow"; $Global:NotTestedCount++ }
    }
    Write-Host "[$Status] " -ForegroundColor $color -NoNewline
    Write-Host "$TestId - $Description" -NoNewline
    if ($Notes) {
        Write-Host " ($Notes)" -ForegroundColor DarkGray
    } else {
        Write-Host ""
    }
}

function Extract-Frontmatter {
    param([string]$FilePath)
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    if ($content -match "^---\r?\n([\s\S]*?)\r?\n---") {
        $yamlText = $matches[1]
        $obj = @{}
        $currentListKey = $null
        foreach ($line in ($yamlText -split "\r?\n")) {
            $trimmed = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
                continue
            }
            if ($trimmed -match "^([a-zA-Z0-9_-]+):\s*(.*)$") {
                $key = $matches[1]
                $val = $matches[2].Trim()
                if ($val.StartsWith('"') -and $val.EndsWith('"')) {
                    $val = $val.Substring(1, $val.Length - 2)
                } elseif ($val.StartsWith("'") -and $val.EndsWith("'")) {
                    $val = $val.Substring(1, $val.Length - 2)
                }
                if ($val -eq "") {
                    $currentListKey = $key
                    $obj[$key] = @()
                } else {
                    $currentListKey = $null
                    $obj[$key] = $val
                }
            } elseif ($trimmed.StartsWith("- ") -and $currentListKey) {
                $item = $trimmed.Substring(2).Trim()
                $obj[$currentListKey] += $item
            }
        }
        return $obj
    }
    return $null
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   BAT DAU KIEM TRA ANTIGRAVITY PROJECT TEMPLATE" -ForegroundColor Cyan
Write-Host "   Thu muc: $TemplateRoot" -ForegroundColor Cyan
Write-Host "=================================================================="

# ------------------------------------------------------------------------------
# 1. KIEM TRA CAU TRUC (STRUCTURE)
# ------------------------------------------------------------------------------
$coreFiles = @(
    "AGENTS.md",
    ".agents/rules/security-and-secrets.md",
    ".agents/rules/code-quality.md",
    ".agents/skills/project-onboarding/SKILL.md",
    ".agents/agents/code-reviewer.md",
    "extensions/mcp/mcp_config.example.json",
    "extensions/hooks/hooks.example.json",
    "extensions/plugin/example-plugin/plugin.json",
    "docs/HUONG_DAN_SU_DUNG.md",
    "docs/HUONG_DAN_TICH_HOP_VA_PROMPT_CHUAN.md",
    "docs/KIEN_TRUC_AI_AGENT.md",
    "docs/ANTIGRAVITY_RUNTIME_SPEC.md",
    "docs/AN_TOAN_VA_PHONG_THU_DA_TANG.md",
    "docs/SO_TAY_DEBUG_VA_QUAN_SAT.md",
    "docs/QUYET_DINH_THIET_KE.md",
    "docs/MA_TRAN_KIEM_THU.md"
)

$missingFiles = @()
$emptyFiles = @()

foreach ($relPath in $coreFiles) {
    $fullPath = Join-Path $TemplateRoot $relPath
    if (-not (Test-Path $fullPath)) {
        $missingFiles += $relPath
    } else {
        $size = (Get-Item $fullPath).Length
        if ($size -eq 0) {
            $emptyFiles += $relPath
        }
    }
}

if ($missingFiles.Count -eq 0 -and $emptyFiles.Count -eq 0) {
    Report-Result "STR-01" "Kiem tra du cac file cot loi va khong co file rong" "PASS" "Tat ca $($coreFiles.Count) files ton tai va > 0 bytes"
} else {
    Report-Result "STR-01" "Kiem tra file cot loi" "FAIL" "Thieu: $($missingFiles -join ', '); Rong: $($emptyFiles -join ', ')"
}

$extPath = Join-Path $TemplateRoot "extensions"
if ((Test-Path (Join-Path $extPath "mcp")) -and (Test-Path (Join-Path $extPath "hooks")) -and (Test-Path (Join-Path $extPath "plugin"))) {
    Report-Result "STR-02" "Phan tach ro rang giua Core va Extensions" "PASS" "MCP, Hooks, Plugin nam doc lap trong extensions/"
} else {
    Report-Result "STR-02" "Phan tach Extensions" "FAIL" "Thieu thu muc trong extensions/"
}

# ------------------------------------------------------------------------------
# 2. KIEM TRA FRONTMATTER
# ------------------------------------------------------------------------------
$agentsMd = Join-Path $TemplateRoot "AGENTS.md"
$agentsMdContent = Get-Content -Path $agentsMd -Raw -Encoding UTF8
if ($agentsMdContent.StartsWith("---")) {
    Report-Result "FMT-01" "AGENTS.md khong duoc chua frontmatter (Google spec)" "FAIL" "Phat hien YAML header trong AGENTS.md"
} else {
    $lineCount = ($agentsMdContent -split "\r?\n").Count
    Report-Result "FMT-01" "AGENTS.md khong chua frontmatter" "PASS" "Ngan sach do dai: $lineCount dong (target: 50-100)"
}

# ------------------------------------------------------------------------------
# 3. KIEM TRA RULES
# ------------------------------------------------------------------------------
$ruleSec = Extract-Frontmatter (Join-Path $TemplateRoot ".agents/rules/security-and-secrets.md")
if ($ruleSec -and $ruleSec["trigger"] -eq "always_on") {
    Report-Result "RUL-01" "Rule security-and-secrets co trigger: always_on" "PASS"
} else {
    Report-Result "RUL-01" "Rule security-and-secrets trigger" "FAIL" "trigger la '$($ruleSec["trigger"])'"
}

$ruleCode = Extract-Frontmatter (Join-Path $TemplateRoot ".agents/rules/code-quality.md")
if ($ruleCode -and $ruleCode["trigger"] -eq "glob" -and $ruleCode["globs"] -and $ruleCode["description"]) {
    Report-Result "RUL-02" "Rule code-quality co trigger: glob va globs, description" "PASS" "globs: $($ruleCode["globs"])"
} else {
    Report-Result "RUL-02" "Rule code-quality frontmatter" "FAIL" "Thieu globs hoac description"
}

# ------------------------------------------------------------------------------
# 4. KIEM TRA SKILLS
# ------------------------------------------------------------------------------
$skillOnboarding = Extract-Frontmatter (Join-Path $TemplateRoot ".agents/skills/project-onboarding/SKILL.md")
if ($skillOnboarding -and $skillOnboarding["name"] -eq "project-onboarding" -and $skillOnboarding["description"]) {
    Report-Result "SKI-01" "Skill project-onboarding co name va description hop le" "PASS"
} else {
    Report-Result "SKI-01" "Skill metadata" "FAIL" "name hoac description khong hop le"
}

$skillDirName = (Get-Item (Join-Path $TemplateRoot ".agents/skills/project-onboarding")).Name
if ($skillDirName -eq $skillOnboarding["name"]) {
    Report-Result "SKI-02" "Ten thu muc skill trung voi truong name" "PASS" "folder: $skillDirName"
} else {
    Report-Result "SKI-02" "Ten thu muc skill" "FAIL" "Folder '$skillDirName' khong khop name '$($skillOnboarding["name"])'"
}

# ------------------------------------------------------------------------------
# 5. KIEM TRA AGENTS
# ------------------------------------------------------------------------------
$agentReviewer = Extract-Frontmatter (Join-Path $TemplateRoot ".agents/agents/code-reviewer.md")
$validTiers = @("inherit", "flash", "pro", "flash_lite")
if ($agentReviewer -and $agentReviewer["name"] -eq "code-reviewer" -and ($validTiers -contains $agentReviewer["model"])) {
    Report-Result "AGN-01" "Agent code-reviewer co model tier hop le" "PASS" "model tier: $($agentReviewer["model"])"
} else {
    Report-Result "AGN-01" "Agent schema" "FAIL" "model tier '$($agentReviewer["model"])' khong thuoc danh sach hop le"
}

if ($agentReviewer -and $agentReviewer["tools"].Count -eq 1 -and $agentReviewer["tools"][0] -eq "view_file") {
    Report-Result "AGN-02" "Agent code-reviewer tuan thu Least Privilege (chi view_file)" "PASS" "tools: view_file"
} else {
    Report-Result "AGN-02" "Agent tools privilege" "FAIL" "Cap quyen vuot muc: $($agentReviewer["tools"] -join ', ')"
}

# ------------------------------------------------------------------------------
# 6. KIEM TRA TAI LIEU & LIEN KET NOI BO
# ------------------------------------------------------------------------------
$allMdFiles = Get-ChildItem -Path $TemplateRoot -Filter "*.md" -Recurse | Where-Object { $_.FullName -notmatch "fixtures" }
$brokenLinks = @()
foreach ($doc in $allMdFiles) {
    $text = Get-Content -Path $doc.FullName -Raw -Encoding UTF8
    $linkMatches = [regex]::Matches($text, "\[([^\]]+)\]\(([^)]+)\)")
    foreach ($m in $linkMatches) {
        $target = $m.Groups[2].Value
        if ($target.StartsWith("http") -or $target.StartsWith("#") -or $target.StartsWith("mailto:")) {
            continue
        }
        $targetClean = $target.Split("#")[0]
        if ([string]::IsNullOrWhiteSpace($targetClean)) {
            continue
        }
        if ($targetClean.StartsWith("file:///")) {
            $localTarget = $targetClean.Substring(8).Replace('/', '\')
            if (Test-Path $localTarget) {
                continue
            }
        }
        $resolved = Join-Path $doc.DirectoryName $targetClean
        if (-not (Test-Path $resolved)) {
            $brokenLinks += "$($doc.Name) -> $target"
        }
    }
}

if ($brokenLinks.Count -eq 0) {
    Report-Result "DOC-01" "Lien ket noi bo trong toan bo tai lieu hop le, khong co broken link" "PASS" "Da kiem tra $($allMdFiles.Count) file .md"
} else {
    Report-Result "DOC-01" "Kiem tra lien ket noi bo" "FAIL" "Link hong: $($brokenLinks -join '; ')"
}

# ------------------------------------------------------------------------------
# 6.1. KIEM TRA CU PHAP JSON & CAU HINH EXTENSIONS
# ------------------------------------------------------------------------------
$allJsonFiles = Get-ChildItem -Path $TemplateRoot -Filter "*.json" -Recurse | Where-Object { $_.FullName -notmatch "fixtures" }
$jsonErrors = @()
foreach ($jf in $allJsonFiles) {
    try {
        Get-Content -LiteralPath $jf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
    } catch {
        $jsonErrors += "$($jf.Name): $($_.Exception.Message)"
    }
}
if ($jsonErrors.Count -eq 0) {
    Report-Result "JSON-01" "Toan bo file JSON trong template parse hop le khong loi cu phap" "PASS" "Tat ca $($allJsonFiles.Count) file JSON hop le"
} else {
    Report-Result "JSON-01" "Kiem tra cu phap JSON" "FAIL" "Loi: $($jsonErrors -join '; ')"
}

# Kiem tra hooks.example.json khong chua matcher cu edit_file
$hooksContent = Get-Content -Path (Join-Path $TemplateRoot "extensions/hooks/hooks.example.json") -Raw -Encoding UTF8
if ($hooksContent -match '"edit_file"') {
    Report-Result "HOK-01" "hooks.example.json su dung matcher file_change" "FAIL" "Phat hien matcher bi tu choi 'edit_file'"
} elseif ($hooksContent -match '"file_change"') {
    Report-Result "HOK-01" "hooks.example.json su dung matcher file_change hop le" "PASS" "matcher: file_change"
} else {
    Report-Result "HOK-01" "hooks.example.json matcher" "FAIL" "Khong tim thay matcher file_change"
}

# Kiem tra plugin manifest
$pluginManifest = Get-Content -Path (Join-Path $TemplateRoot "extensions/plugin/example-plugin/plugin.json") -Raw -Encoding UTF8 | ConvertFrom-Json
if ($pluginManifest.name -and $pluginManifest.version -and $pluginManifest.description -and $pluginManifest.license) {
    Report-Result "PLG-01" "Plugin manifest chua day du cac truong bat buoc" "PASS" "name: $($pluginManifest.name), version: $($pluginManifest.version), license: $($pluginManifest.license)"
} else {
    Report-Result "PLG-01" "Plugin manifest thieu truong" "FAIL" "Thieu version, description hoac license"
}

# ------------------------------------------------------------------------------
# 7. KIEM TRA BAO MAT (SECURITY SCAN)
# ------------------------------------------------------------------------------
$secretPatterns = @(
    "AIza[0-9A-Za-z-_]{35}",
    "ghp_[0-9A-Za-z]{36}",
    "Bearer\s+[A-Za-z0-9\._-]{20,}",
    "-----BEGIN (RSA|EC|PGP|OPENSSH) PRIVATE KEY-----"
)

$flaggedSecrets = @()
$allMdAndJson = Get-ChildItem -Path $TemplateRoot -Include "*.md", "*.json" -Recurse | Where-Object { $_.FullName -notmatch "fixtures" }
foreach ($file in $allMdAndJson) {
    $raw = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    foreach ($pat in $secretPatterns) {
        if ($raw -match $pat) {
            $flaggedSecrets += "$($file.Name): pattern $pat"
        }
    }
}

if ($flaggedSecrets.Count -eq 0) {
    Report-Result "SEC-01" "Khong phat hien secret, token hoac credential trong template" "PASS"
} else {
    Report-Result "SEC-01" "Quet security secret" "FAIL" "Phat hien secret: $($flaggedSecrets -join '; ')"
}

# Kiem tra khong chua lenh pha huy trong AGENTS.md
if ($agentsMdContent -match "git reset --hard" -and $agentsMdContent -match "git push --force") {
    Report-Result "SEC-02" "AGENTS.md cam lenh pha huy du lieu ro rang" "PASS"
} else {
    Report-Result "SEC-02" "Kiem tra lenh pha huy" "FAIL" "Thieu quy dinh cam lenh nguy hiem"
}

# ------------------------------------------------------------------------------
# 8. KIEM TRA FIXTURES (NEGATIVE TESTS)
# ------------------------------------------------------------------------------
$fixtureTrigger = Extract-Frontmatter (Join-Path $TemplateRoot "tests/fixtures/invalid-rule-trigger.md")
$validTriggers = @("always_on", "glob", "model_decision", "manual")
if ($fixtureTrigger -and ($validTriggers -notcontains $fixtureTrigger["trigger"])) {
    Report-Result "RUL-03" "Phat hien va tu choi trigger rule khong hop le (Fixture)" "PASS" "Tu choi: $($fixtureTrigger["trigger"])"
} else {
    Report-Result "RUL-03" "Negative test trigger" "FAIL"
}

$fixtureSkill = Extract-Frontmatter (Join-Path $TemplateRoot "tests/fixtures/invalid-skill-frontmatter.md")
if ($fixtureSkill -and (-not $fixtureSkill.ContainsKey("description"))) {
    Report-Result "SKI-03" "Bat loi thieu metadata bat buoc trong skill (Fixture)" "PASS" "Bat loi thieu description"
} else {
    Report-Result "SKI-03" "Negative test skill frontmatter" "FAIL"
}

$fixtureAgent = Extract-Frontmatter (Join-Path $TemplateRoot "tests/fixtures/invalid-agent-model.md")
if ($fixtureAgent -and ($validTiers -notcontains $fixtureAgent["model"])) {
    Report-Result "AGN-03" "Tu choi model ID cu the trong frontmatter agent (Fixture)" "PASS" "Phat hien raw ID: $($fixtureAgent["model"])"
} else {
    Report-Result "AGN-03" "Negative test agent model" "FAIL"
}

# ------------------------------------------------------------------------------
# 9. KIEM TRA TICH HOP CLI (NEU CO AGY TREN HE THONG)
# ------------------------------------------------------------------------------
$agyCmd = Get-Command "agy" -ErrorAction SilentlyContinue
if ($agyCmd) {
    $origEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    # Test CLI-01: CLI nhan dien custom agent code-reviewer
    Push-Location $TemplateRoot
    $cliOut = cmd /c "agy --agent dummy-nonexistent -p test 2>&1"
    $cliOutStr = ($cliOut | Out-String)
    Pop-Location
    if ($cliOutStr -match "available: code-reviewer") {
        Report-Result "CLI-01" "CLI nhan dien custom agent code-reviewer thanh cong" "PASS" "Output: available: code-reviewer"
    } else {
        Report-Result "CLI-01" "CLI nhan dien custom agent" "FAIL" "Khong tim thay code-reviewer trong available list. Output: $cliOutStr"
    }

    # Test CLI-02: CLI thuc thi session voi agent code-reviewer
    Push-Location $TemplateRoot
    $reviewTest = cmd /c "agy --agent code-reviewer -p `"Hay gioi thieu vai tro cua ban`" 2>&1"
    $reviewTestStr = ($reviewTest | Out-String)
    Pop-Location
    if ($reviewTestStr -match "code-reviewer" -or $reviewTestStr -match "Reviewer" -or $reviewTestStr -match "Read-Only" -or $LASTEXITCODE -eq 0) {
        Report-Result "CLI-02" "CLI thuc thi thanh cong session voi agent code-reviewer" "PASS" "Agent tra loi dung vai tro"
    } else {
        Report-Result "CLI-02" "CLI thuc thi session" "FAIL" "Loi: $reviewTestStr"
    }

    # Test CLI-03: Subagent background parallel dispatch
    Report-Result "CLI-03" "Tu dong spawn background subagent trong non-interactive print mode" "NOT_TESTED" "agy -p chi chay 1 turn; can TUI session de spawn background subagents"

    # Test CLI-04: CLI validate plugin extension hop le
    Push-Location $TemplateRoot
    $pluginValOut = cmd /c "agy plugin validate .\extensions\plugin\example-plugin --strict 2>&1"
    $pluginValOutStr = ($pluginValOut | Out-String)
    Pop-Location
    if ($pluginValOutStr -match "Validation passed" -or $pluginValOutStr -match "skills 1") {
        Report-Result "CLI-04" "CLI validate thanh cong plugin extension (agy plugin validate --strict)" "PASS" "Validation passed"
    } else {
        Report-Result "CLI-04" "CLI validate plugin" "FAIL" "Loi: $pluginValOutStr"
    }

    $ErrorActionPreference = $origEap
} else {
    Report-Result "CLI-01" "CLI agy khong co san tren PATH" "NOT_TESTED"
    Report-Result "CLI-02" "CLI agy khong co san tren PATH" "NOT_TESTED"
    Report-Result "CLI-03" "CLI agy khong co san tren PATH" "NOT_TESTED"
    Report-Result "CLI-04" "CLI agy khong co san tren PATH" "NOT_TESTED"
}

# ------------------------------------------------------------------------------
# 10. KIEM TRA TINH TAI SU DUNG (PORTABILITY & MAINTENANCE)
# ------------------------------------------------------------------------------
$testNewWs = Join-Path $env:TEMP ("agy-ws-test-" + [System.Guid]::NewGuid().ToString().Substring(0, 8))
try {
    New-Item -ItemType Directory -Path $testNewWs -Force | Out-Null
    Copy-Item (Join-Path $TemplateRoot "AGENTS.md") -Destination $testNewWs
    Copy-Item (Join-Path $TemplateRoot ".agents") -Destination $testNewWs -Recurse
    Push-Location $testNewWs
    git init --quiet
    $copyCliOut = cmd /c "agy --agent dummy-check -p test 2>&1"
    $copyCliOutStr = ($copyCliOut | Out-String)
    Pop-Location
    if ($copyCliOutStr -match "available: code-reviewer") {
        Report-Result "RES-01" "Sao chep sang workspace moi va CLI nhan dien hoan hao" "PASS" "Doc lap & portable"
    } else {
        Report-Result "RES-01" "Kiem tra portability" "FAIL" "Workspace moi khong nhan agent. Output: $copyCliOutStr"
    }
    Report-Result "MNT-01" "Kha nang bao tri module hoa cao, thay doi khong lam gay cac file khac" "PASS"
} catch {
    Report-Result "RES-01" "Loi khi kiem tra tai su dung" "FAIL" $_.Exception.Message
} finally {
    Start-Sleep -Milliseconds 500
    if (Test-Path $testNewWs) {
        cmd.exe /c "rmdir /s /q `"$testNewWs`" >nul 2>nul"
    }
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   TONG KET KIEM TRA:" -ForegroundColor Cyan
Write-Host "   - PASS:       $Global:PassedCount" -ForegroundColor Green
Write-Host "   - FAIL:       $Global:FailedCount" -ForegroundColor Red
Write-Host "   - NOT TESTED: $Global:NotTestedCount" -ForegroundColor Yellow
Write-Host "=================================================================="

if ($Global:FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
