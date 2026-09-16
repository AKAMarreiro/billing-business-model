# Build de HTML - Irricontrol ONE Receita
# Resolve placeholders {{chave}} nos arquivos .md de narrativa/
# Saida: dist/index.html

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
Write-Output "=== BUILD HTML ==="

# Carregar derivados
$derivados = Get-Content "$Root\dist\derivados.json" -Raw -Encoding UTF8 | ConvertFrom-Json

# Carregar e concatenar narrativa
$arquivos = Get-ChildItem "$Root\narrativa\*.md" | Sort-Object Name
$mdCompleto = ''
foreach ($arquivo in $arquivos) {
    $bytes = [System.IO.File]::ReadAllBytes($arquivo.FullName)
    $conteudo = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($mdCompleto -ne '') { $mdCompleto += "`n`n---`n`n" }
    $mdCompleto += $conteudo.Trim()
}

# Resolver placeholders
function fmt($valor) {
    if ($valor -is [double] -or $valor -is [decimal] -or $valor -is [int]) { return $valor.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('pt-BR')) }
    return $valor
}

$mdResolvido = $mdCompleto
$placeholders = [regex]::Matches($mdCompleto, '\{\{(\w+)(?:\|(\w+))?\}\}')
$feitos = @{}
foreach ($m in $placeholders) {
    $chave = $m.Groups[1].Value
    if ($feitos.ContainsKey($m.Value)) { continue }
    $valor = $derivados.$chave
    if ($valor -eq $null) {
        Write-Warning "Placeholder nao resolvido: {{$chave}}"
        $valor = "{{$chave}}"
    } else { $valor = fmt($valor) }
    $mdResolvido = $mdResolvido.Replace($m.Value, $valor)
    $feitos[$m.Value] = $true
}

# Converter MD para HTML (simplificado)
$html = ""
$linhas = $mdResolvido -split "`r?`n"
$dentroLista = $false
$dentroParagrafo = $false

foreach ($linha in $linhas) {
    $trim = $linha.Trim()
    if ($trim -eq '---') {
        if ($dentroLista) { $html += "</ul>\n"; $dentroLista = $false }
        if ($dentroParagrafo) { $html += "</p>\n"; $dentroParagrafo = $false }
        $html += "<hr class='secao-divisor'>\n"
        continue
    }
    if ($trim -match '^(#{1,6})\s+(.+)$') {
        if ($dentroLista) { $html += "</ul>\n"; $dentroLista = $false }
        if ($dentroParagrafo) { $html += "</p>\n"; $dentroParagrafo = $false }
        $nivel = $matches[1].Length
        $titulo = $matches[2]
        $html += "<h$nivel>$titulo</h$nivel>\n"
        continue
    }
    if ($trim -match '^\*\*\*(.+?)\*\*\*$') {
        if ($dentroLista) { $html += "</ul>\n"; $dentroLista = $false }
        if ($dentroParagrafo) { $html += "</p>\n"; $dentroParagrafo = $false }
        $html += "<p><strong><em>$($matches[1])</em></strong></p>\n"
        continue
    }
    if ($trim -match '^\*\*(.+?)\*\*$') {
        if ($dentroLista) { $html += "</ul>\n"; $dentroLista = $false }
        if ($dentroParagrafo) { $html += "</p>\n"; $dentroParagrafo = $false }
        $html += "<p><strong>$($matches[1])</strong></p>\n"
        continue
    }
    if ($trim -match '^\*\s+(.+)$') {
        if (-not $dentroParagrafo -and -not $dentroLista) { $html += "<ul>\n"; $dentroLista = $true }
        $item = $matches[1]
        $item = $item -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
        $item = $item -replace '\*(.+?)\*', '<em>$1</em>'
        $html += "  <li>$item</li>\n"
        continue
    }
    if ($trim -eq '') {
        if ($dentroLista) { $html += "</ul>\n"; $dentroLista = $false }
        if ($dentroParagrafo) { $html += "</p>\n"; $dentroParagrafo = $false }
        continue
    }
    if (-not $dentroParagrafo) { $html += "<p>"; $dentroParagrafo = $true } else { $html += " " }
    $texto = $trim -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
    $texto = $texto -replace '\*(.+?)\*', '<em>$1</em>'
    $html += $texto
}
if ($dentroLista) { $html += "</ul>\n" }
if ($dentroParagrafo) { $html += "</p>\n" }

# Montar HTML completo
$css = @'
:root { --bg:#fafafa; --fg:#1a1a1a; --muted:#666; --accent:#2c5282; --border:#ddd; }
@media (prefers-color-scheme: dark) {
  :root { --bg:#1a1a1a; --fg:#e8e8e8; --muted:#999; --accent:#63b3ed; --border:#444; }
}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:var(--bg);color:var(--fg);line-height:1.7;padding:2rem 1rem}
.container{max-width:720px;margin:0 auto}
header{border-bottom:3px solid var(--accent);padding-bottom:1rem;margin-bottom:2rem}
h1{font-size:1.8rem;color:var(--accent);margin-bottom:.3rem}
.subtitle{color:var(--muted);font-size:.95rem}
h2{font-size:1.4rem;color:var(--accent);margin:2rem 0 .8rem;border-bottom:1px solid var(--border);padding-bottom:.3rem}
h3{font-size:1.15rem;color:var(--fg);margin:1.5rem 0 .5rem}
p{margin-bottom:1rem;text-align:justify}
ul{margin:0 0 1rem 1.5rem}
li{margin-bottom:.4rem}
strong{color:var(--accent)}
hr.secao-divisor{border:0;border-top:2px solid var(--accent);margin:2.5rem 0;opacity:.4}
@media print{
  body{background:#fff;color:#000}
  h2{color:#000;border-color:#999}
  .secao-divisor{border-color:#999}
}
'@

$pagina = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Irricontrol ONE - Modelo de Receita</title>
<style>$css</style>
</head>
<body>
<div class="container">
<header>
  <h1>Irricontrol ONE</h1>
  <p class="subtitle">Modelo de Receita &middot; Corte real: $($derivados.dataCorte) &middot; $($derivados.pontosPagantes) pontos pagantes &middot; $($derivados.totalEscopo) dispositivos no escopo</p>
</header>
$html
</div>
</body>
</html>
"@

# Salvar com UTF-8 sem BOM (converter \n escapados em quebras reais)
$paginaFinal = $pagina -replace '\\n', "`r`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$Root\dist\index.html", $paginaFinal, $utf8NoBom)

Write-Output ""
Write-Output "OK dist/index.html gerado."
Write-Output "  Tamanho: $([Math]::Round((Get-Item "$Root\dist\index.html").Length / 1024, 1)) KB"
