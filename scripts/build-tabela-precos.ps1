# Gerar Tabela de Precos - Irricontrol ONE
# Tabela de descontos por numero de equipamentos e anos de contrato
# Preco de referencia: USD 200/device/ano (tabela global Bauer)
# Saida: dist/tabela-precos.jpg

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

Add-Type -AssemblyName System.Drawing

Write-Output "=== GERANDO TABELA DE PRECOS (USD) ==="

# Configuracoes da imagem
$width = 900
$height = 650
$padding = 40
$headerHeight = 60
$rowHeight = 70
$colWidths = @(200, 200, 200, 200)

# Cores
$bgColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
$headerColor = [System.Drawing.Color]::FromArgb(44, 82, 130)
$headerTextColor = [System.Drawing.Color]::White
$rowColor1 = [System.Drawing.Color]::FromArgb(255, 255, 255)
$rowColor2 = [System.Drawing.Color]::FromArgb(245, 248, 252)
$textColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
$accentColor = [System.Drawing.Color]::FromArgb(237, 137, 54)
$borderColor = [System.Drawing.Color]::FromArgb(221, 221, 221)
$highlightColor = [System.Drawing.Color]::FromArgb(72, 187, 120)

# Preco de referencia em USD
$precoBase = 200

# Dados da tabela (precos em USD)
$tierData = @(
    @{ Tier = "1-10 devices"; Ano1 = 200; Ano2 = 180; Ano3 = 160; Desc1 = ""; Desc2 = "-10%"; Desc3 = "-20%" }
    @{ Tier = "11-20 devices"; Ano1 = 190; Ano2 = 171; Ano3 = 152; Desc1 = "-5%"; Desc2 = "-15%"; Desc3 = "-24%" }
    @{ Tier = "21-30 devices"; Ano1 = 180; Ano2 = 162; Ano3 = 144; Desc1 = "-10%"; Desc2 = "-19%"; Desc3 = "-28%" }
    @{ Tier = "31-40 devices"; Ano1 = 170; Ano2 = 153; Ano3 = 136; Desc1 = "-15%"; Desc2 = "-24%"; Desc3 = "-32%" }
    @{ Tier = "41-50 devices"; Ano1 = 160; Ano2 = 144; Ano3 = 128; Desc1 = "-20%"; Desc2 = "-28%"; Desc3 = "-36%" }
)

# Criar bitmap
$bmp = New-Object System.Drawing.Bitmap($width, $height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

# Fundo
$g.FillRectangle([System.Drawing.SolidBrush]::new($bgColor), 0, 0, $width, $height)

# Fontes
$fontTitle = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$fontHeader = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$fontCell = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$fontDesc = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$fontNote = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

# Titulo
$titleText = "Irricontrol ONE - Tabela de Precos Global"
$titleSize = $g.MeasureString($titleText, $fontTitle)
$titleX = ($width - $titleSize.Width) / 2
$g.DrawString($titleText, $fontTitle, [System.Drawing.SolidBrush]::new($headerColor), $titleX, 20)

# Subtitulo
$subText = "Anuidade por device em USD | Preco de referencia: USD $precoBase/ano"
$subSize = $g.MeasureString($subText, $fontSubtitle)
$subX = ($width - $subSize.Width) / 2
$g.DrawString($subText, $fontSubtitle, [System.Drawing.SolidBrush]::new($textColor), $subX, 50)

# Posicoes da tabela
$tableTop = 100
$tableLeft = ($width - ($colWidths | Measure-Object -Sum).Sum) / 2

# Cabecalho
$colX = $tableLeft
$headers = @("Volume", "1 Ano", "2 Anos", "3 Anos")
for ($i = 0; $i -lt $headers.Count; $i++) {
    $rect = [System.Drawing.RectangleF]::new($colX, $tableTop, $colWidths[$i], $headerHeight)
    $g.FillRectangle([System.Drawing.SolidBrush]::new($headerColor), $rect)
    $g.DrawString($headers[$i], $fontHeader, [System.Drawing.SolidBrush]::new($headerTextColor), $rect.X + 15, $rect.Y + 18)
    $colX += $colWidths[$i]
}

# Linhas
for ($row = 0; $row -lt $tierData.Count; $row++) {
    $data = $tierData[$row]
    $rowY = $tableTop + $headerHeight + ($row * $rowHeight)
    $bg = if ($row % 2 -eq 0) { $rowColor1 } else { $rowColor2 }
    
    $g.FillRectangle([System.Drawing.SolidBrush]::new($bg), $tableLeft, $rowY, ($colWidths | Measure-Object -Sum).Sum, $rowHeight)
    $g.DrawLine([System.Drawing.Pen]::new($borderColor), $tableLeft, $rowY + $rowHeight, $tableLeft + ($colWidths | Measure-Object -Sum).Sum, $rowY + $rowHeight)
    
    # Volume
    $colX = $tableLeft + 15
    $g.DrawString($data.Tier, $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 12)
    $g.DrawString($data.Desc1, $fontDesc, [System.Drawing.SolidBrush]::new($accentColor), $colX, $rowY + 38)
    
    # 1 Ano
    $colX = $tableLeft + $colWidths[0] + 15
    $g.DrawString("USD $($data.Ano1)", $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 12)
    $g.DrawString($data.Desc1, $fontDesc, [System.Drawing.SolidBrush]::new($accentColor), $colX, $rowY + 38)
    
    # 2 Anos
    $colX = $tableLeft + $colWidths[0] + $colWidths[1] + 15
    $g.DrawString("USD $($data.Ano2)", $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 12)
    $g.DrawString($data.Desc2, $fontDesc, [System.Drawing.SolidBrush]::new($highlightColor), $colX, $rowY + 38)
    
    # 3 Anos
    $colX = $tableLeft + $colWidths[0] + $colWidths[1] + $colWidths[2] + 15
    $g.DrawString("USD $($data.Ano3)", $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 12)
    $g.DrawString($data.Desc3, $fontDesc, [System.Drawing.SolidBrush]::new($highlightColor), $colX, $rowY + 38)
}

# Nota de rodape
$noteY = $tableTop + $headerHeight + ($tierData.Count * $rowHeight) + 20
$notes = @(
    "* Preco de referencia global: USD $precoBase/device/ano (tabela Bauer, proposta Helton 2024)",
    "* Desconto por volume: aplica-se automaticamente conforme numero total de devices no contrato",
    "* Desconto por duracao: 2 anos = -10% | 3 anos = -20% (sobre o preco ja descontado por volume)",
    "* Conversao para BRL: USD $precoBase x cambio (ex: R$ 5,70) = R$ $([Math]::Round($precoBase * 5.7,0))/ano"
)
for ($i = 0; $i -lt $notes.Count; $i++) {
    $g.DrawString($notes[$i], $fontNote, [System.Drawing.SolidBrush]::new($textColor), $tableLeft, $noteY + ($i * 18))
}

# Salvar
$path = "$Root\dist\tabela-precos.jpg"
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Jpeg)

# Liberar recursos
$g.Dispose()
$bmp.Dispose()
$fontTitle.Dispose(); $fontSubtitle.Dispose(); $fontHeader.Dispose(); $fontCell.Dispose(); $fontDesc.Dispose(); $fontNote.Dispose()

Write-Output ""
Write-Output "OK dist/tabela-precos.jpg gerado (USD)."
Write-Output "  Tamanho: $([Math]::Round((Get-Item $path).Length / 1024, 1)) KB"
Write-Output "  Dimensao: ${width}x${height}"
