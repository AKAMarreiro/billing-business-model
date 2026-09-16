# Verificador de Integridade - Irricontrol ONE Receita
# Executa validacoes antes de build/deploy
# Falha = build nao passa

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Continue'
$exitCode = 0

function fail($msg) {
    Write-Output "  FALHA: $msg"
    $script:exitCode = 1
}

function ok($msg) {
    Write-Output "  OK: $msg"
}

Write-Output "========================================"
Write-Output "  VERIFICADOR DE INTEGRIDADE"
Write-Output "========================================"
Write-Output ""

# 1. Encoding UTF-8 sem BOM
Write-Output "--- 1/5 Encoding UTF-8 sem BOM ---"
$textFiles = Get-ChildItem "$Root" -Recurse -File | Where-Object {
    $_.Extension -match '\.(md|json|csv|js|html|css|txt|ps1)$' -and
    $_.FullName -notmatch '\\dist\\'
}
$encodingErrors = 0
$replacementChar = [char]0xFFFD
foreach ($f in $textFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($bytes.Count -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        fail "BOM encontrado: $($f.FullName)"
        $encodingErrors++
    }
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($content.IndexOf($replacementChar) -ge 0) {
        fail "U+FFFD encontrado: $($f.FullName)"
        $encodingErrors++
    }
}
if ($encodingErrors -eq 0) { ok "Todos os arquivos estao UTF-8 sem BOM e sem U+FFFD" }
Write-Output ""

# 2. Line endings LF
Write-Output "--- 2/5 Line Endings LF ---"
$crlfErrors = 0
foreach ($f in $textFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($content.Contains("`r`n")) {
        fail "CRLF encontrado: $($f.FullName)"
        $crlfErrors++
    }
}
if ($crlfErrors -eq 0) { ok "Todos os arquivos usam LF" }
Write-Output ""

# 3. Placeholders vs Derivados
Write-Output "--- 3/5 Placeholders vs Derivados ---"
$placeholders = @()
$files = Get-ChildItem "$Root\narrativa\*.md"
foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    $matches = [regex]::Matches($content, '\{\{(\w+)(?:\|\w+)?\}\}')
    foreach ($m in $matches) { $placeholders += $m.Groups[1].Value }
}
$unique = $placeholders | Sort-Object -Unique
$derivados = Get-Content "$Root\dist\derivados.json" -Raw | ConvertFrom-Json
$derivKeys = $derivados.PSObject.Properties.Name
$missing = $unique | Where-Object { $derivKeys -notcontains $_ }
if ($missing.Count -gt 0) {
    foreach ($m in $missing) { fail "Placeholder sem chave em derivados.json: $m" }
} else {
    ok "Todos os $($unique.Count) placeholders tem correspondencia em derivados.json"
}
Write-Output ""

# 4. dist/ atualizado
Write-Output "--- 4/5 dist/ atualizado ---"
$distFiles = Get-ChildItem "$Root\dist\*"
if ($distFiles.Count -eq 0) {
    fail "dist/ esta vazio"
} else {
    $latestDist = ($distFiles | Sort-Object LastWriteTime -Descending)[0].LastWriteTime
    $sourceFiles = Get-ChildItem "$Root\dados\*", "$Root\narrativa\*", "$Root\motor\*" | Sort-Object LastWriteTime -Descending
    $latestSource = $sourceFiles[0].LastWriteTime
    if ($latestSource -gt $latestDist) {
        fail "dist/ desatualizado. Fonte mais recente: $($sourceFiles[0].FullName) ($latestSource) vs dist/ ($latestDist)"
    } else {
        ok "dist/ esta atualizado em relacao as fontes"
    }
}
Write-Output ""

# 5. Estrutura obrigatoria
Write-Output "--- 5/5 Estrutura obrigatoria ---"
$required = @(
    'dados/premissas.json',
    'dados/base-dispositivos.json',
    'dados/stripe-mensal.csv',
    'dados/pricing-global.json',
    'dados/FONTES.md',
    'motor/calculo.js',
    'motor/formato.js',
    'motor/calculo.test.js',
    'narrativa/01-ponto-de-partida.md',
    'narrativa/11-dados-abertos.md',
    'dist/derivados.json',
    'dist/index.html'
)
$missingFiles = @()
foreach ($f in $required) {
    if (-not (Test-Path "$Root\$f")) { $missingFiles += $f }
}
if ($missingFiles.Count -gt 0) {
    foreach ($m in $missingFiles) { fail "Arquivo obrigatorio ausente: $m" }
} else {
    ok "Todos os $($required.Count) arquivos obrigatorios presentes"
}
Write-Output ""

# RESUMO
Write-Output "========================================"
if ($exitCode -eq 0) {
    Write-Output "  TODAS AS VERIFICACOES PASSARAM"
    Write-Output "  Build autorizado."
} else {
    Write-Output "  VERIFICACOES COM FALHA"
    Write-Output "  Build NAO AUTORIZADO. Corrija antes de prosseguir."
}
Write-Output "========================================"
Write-Output ""

exit $exitCode
