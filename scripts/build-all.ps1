# Build Completo - Irricontrol ONE Receita
# Executa build-derivados.ps1 + build-html.ps1 + build-xlsx.ps1 em sequencia

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

Write-Output '========================================'
Write-Output '  BUILD COMPLETO - Irricontrol ONE'
Write-Output '========================================'
Write-Output ''

# 1. Derivados
Write-Output '--- 1/3 Derivados ---'
& "$Root\scripts\build-derivados.ps1" -Root $Root
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) { exit $LASTEXITCODE }

Write-Output ''

# 2. HTML
Write-Output '--- 2/3 HTML ---'
& "$Root\scripts\build-html.ps1" -Root $Root
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) { exit $LASTEXITCODE }

Write-Output ''

# 3. XLSX
Write-Output '--- 3/3 XLSX ---'
& "$Root\scripts\build-xlsx.ps1" -Root $Root
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) { exit $LASTEXITCODE }

Write-Output ''
Write-Output '========================================'
Write-Output '  BUILD FINALIZADO'
Write-Output '========================================'
Write-Output '  dist/derivados.json  - valores calculados'
Write-Output '  dist/index.html      - documento gerado'
Write-Output '  dist/modelo.xlsx     - planilha com 7 abas'
Write-Output ''
