# Build Completo - Irricontrol ONE Receita
# Executa build-derivados.ps1 + build-html.ps1 em sequencia

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

Write-Output '========================================'
Write-Output '  BUILD COMPLETO - Irricontrol ONE'
Write-Output '========================================'
Write-Output ''

# Executar build de derivados
& "$Root\scripts\build-derivados.ps1" -Root $Root
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output ''

# Executar build de HTML
& "$Root\scripts\build-html.ps1" -Root $Root
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Output ''
Write-Output '========================================'
Write-Output '  BUILD FINALIZADO'
Write-Output '========================================'
Write-Output '  dist/derivados.json - valores calculados'
Write-Output '  dist/index.html     - documento gerado'
Write-Output ''
