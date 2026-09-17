# Gerar Tabela de Precos Global - Irricontrol ONE
# Dados reais da tabela Bauer (cliente direto apenas)
# Preco referencia: 1 ano = USD 220, 2 anos = USD 390 total (195/ano ef), 3 anos = USD 510 total (170/ano ef)
# 3 idiomas: PT, EN, ES
# Saida: dados/tabela-precos-{pt,en,es}.jpg

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

Add-Type -AssemblyName System.Drawing

Write-Output "=== GERANDO TABELA DE PRECOS GLOBAL (3 IDIOMAS) ==="

# Dados reais da tabela Bauer (cliente direto)
# a1 = preco 1 ano (referencia)
# a2ef = preco efetivo/ano em pacote 2 anos
# a3ef = preco efetivo/ano em pacote 3 anos
# total2 = a2ef * 2 (total do pacote)
# total3 = a3ef * 3 (total do pacote)
$clienteDireto = @(
    @{ tier = "1-10"; a1 = 220; a2ef = 195; a3ef = 170; total2 = 390; total3 = 510 }
    @{ tier = "11-20"; a1 = 209; a2ef = 185; a3ef = 162; total2 = 370; total3 = 486 }
    @{ tier = "21-30"; a1 = 196; a2ef = 174; a3ef = 151; total2 = 348; total3 = 453 }
    @{ tier = "31-40"; a1 = 183; a2ef = 162; a3ef = 141; total2 = 324; total3 = 423 }
    @{ tier = "41-50"; a1 = 167; a2ef = 148; a3ef = 129; total2 = 296; total3 = 387 }
)

$precoBase = 220

function pctDesc($atual, $base) {
    return [Math]::Round((($atual - $base) / $base) * 100, 0)
}

function gerarTabela($titulo, $subtitulo, $colHeaders, $labels, $notas, $fileName) {
    $width = 1000
    $height = 720
    $headerHeight = 55
    $rowHeight = 78
    $colWidths = @(180, 220, 220, 220)
    
    $bgColor = [System.Drawing.Color]::White
    $headerColor = [System.Drawing.Color]::FromArgb(30, 58, 95)
    $headerTextColor = [System.Drawing.Color]::White
    $rowColor1 = [System.Drawing.Color]::FromArgb(248, 250, 252)
    $rowColor2 = [System.Drawing.Color]::White
    $textColor = [System.Drawing.Color]::FromArgb(26, 26, 26)
    $accentColor = [System.Drawing.Color]::FromArgb(200, 80, 30)
    $greenColor = [System.Drawing.Color]::FromArgb(40, 130, 80)
    $borderColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $refColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $totalColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
    
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    
    $g.FillRectangle([System.Drawing.SolidBrush]::new($bgColor), 0, 0, $width, $height)
    
    $fontTitle = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 11)
    $fontHeader = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $fontCell = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $fontDesc = New-Object System.Drawing.Font("Segoe UI", 9)
    $fontTotal = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $fontNote = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    
    $g.FillRectangle([System.Drawing.SolidBrush]::new($headerColor), 0, 0, $width, 6)
    
    $titleSize = $g.MeasureString($titulo, $fontTitle)
    $titleX = ($width - $titleSize.Width) / 2
    $g.DrawString($titulo, $fontTitle, [System.Drawing.SolidBrush]::new($headerColor), $titleX, 22)
    
    $subSize = $g.MeasureString($subtitulo, $fontSubtitle)
    $subX = ($width - $subSize.Width) / 2
    $g.DrawString($subtitulo, $fontSubtitle, [System.Drawing.SolidBrush]::new($refColor), $subX, 52)
    
    $tableTop = 88
    $tableLeft = ($width - ($colWidths | Measure-Object -Sum).Sum) / 2
    $totalTableWidth = ($colWidths | Measure-Object -Sum).Sum
    
    # Cabecalho
    $colX = $tableLeft
    for ($i = 0; $i -lt $colHeaders.Count; $i++) {
        $rect = [System.Drawing.RectangleF]::new($colX, $tableTop, $colWidths[$i], $headerHeight)
        $g.FillRectangle([System.Drawing.SolidBrush]::new($headerColor), $rect)
        $g.DrawString($colHeaders[$i], $fontHeader, [System.Drawing.SolidBrush]::new($headerTextColor), $rect.X + 12, $rect.Y + 18)
        $colX += $colWidths[$i]
    }
    
    # Linhas
    for ($row = 0; $row -lt $clienteDireto.Count; $row++) {
        $data = $clienteDireto[$row]
        $rowY = $tableTop + $headerHeight + ($row * $rowHeight)
        $bg = if ($row % 2 -eq 0) { $rowColor1 } else { $rowColor2 }
        
        $g.FillRectangle([System.Drawing.SolidBrush]::new($bg), $tableLeft, $rowY, $totalTableWidth, $rowHeight)
        $g.DrawLine([System.Drawing.Pen]::new($borderColor, 1), $tableLeft, $rowY + $rowHeight, $tableLeft + $totalTableWidth, $rowY + $rowHeight)
        
        # Volume
        $colX = $tableLeft + 14
        $g.DrawString($data.tier + " " + $labels.devices, $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 12)
        
        # 1 Ano
        $colX = $tableLeft + $colWidths[0] + 14
        $g.DrawString("USD " + $data.a1, $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 8)
        if ($row -eq 0) {
            $g.DrawString($labels.ref, $fontDesc, [System.Drawing.SolidBrush]::new($refColor), $colX, $rowY + 36)
        } else {
            $d = pctDesc $data.a1 $precoBase
            $g.DrawString("(" + $d + "%)", $fontDesc, [System.Drawing.SolidBrush]::new($accentColor), $colX, $rowY + 36)
        }
        $g.DrawString("(" + $labels.perYear + ")", $fontDesc, [System.Drawing.SolidBrush]::new($totalColor), $colX, $rowY + 52)
        
        # 2 Anos (ef)
        $colX = $tableLeft + $colWidths[0] + $colWidths[1] + 14
        $g.DrawString("USD " + $data.a2ef + "/" + $labels.year, $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 8)
        $d2 = pctDesc $data.a2ef $precoBase
        $g.DrawString("(" + $d2 + "%)", $fontDesc, [System.Drawing.SolidBrush]::new($accentColor), $colX, $rowY + 36)
        $g.DrawString("(" + $labels.total + ": USD " + $data.total2 + ")", $fontTotal, [System.Drawing.SolidBrush]::new($totalColor), $colX, $rowY + 52)
        
        # 3 Anos (ef)
        $colX = $tableLeft + $colWidths[0] + $colWidths[1] + $colWidths[2] + 14
        $g.DrawString("USD " + $data.a3ef + "/" + $labels.year, $fontCell, [System.Drawing.SolidBrush]::new($textColor), $colX, $rowY + 8)
        $d3 = pctDesc $data.a3ef $precoBase
        $g.DrawString("(" + $d3 + "%)", $fontDesc, [System.Drawing.SolidBrush]::new($greenColor), $colX, $rowY + 36)
        $g.DrawString("(" + $labels.total + ": USD " + $data.total3 + ")", $fontTotal, [System.Drawing.SolidBrush]::new($totalColor), $colX, $rowY + 52)
    }
    
    # Rodape
    $noteY = $tableTop + $headerHeight + ($clienteDireto.Count * $rowHeight) + 22
    $g.DrawLine([System.Drawing.Pen]::new($borderColor, 1), $tableLeft, $noteY - 10, $tableLeft + $totalTableWidth, $noteY - 10)
    
    for ($i = 0; $i -lt $notas.Count; $i++) {
        $g.DrawString($notas[$i], $fontNote, [System.Drawing.SolidBrush]::new($refColor), $tableLeft, $noteY + ($i * 17))
    }
    
    $path = "$Root\dados\$fileName"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    
    $g.Dispose(); $bmp.Dispose()
    $fontTitle.Dispose(); $fontSubtitle.Dispose(); $fontHeader.Dispose(); $fontCell.Dispose(); $fontDesc.Dispose(); $fontTotal.Dispose(); $fontNote.Dispose()
    
    Write-Output "  OK: dados/$fileName"
}

# PT
$labelsPT = @{ devices = "devices"; year = "ano"; total = "total"; ref = "(referencia)"; perYear = "por ano" }
$notasPT = @(
    "* Preco de referencia global: USD $precoBase/device/ano (tabela Bauer, proposta Helton 2024)",
    "* 2 anos: preco efetivo por ano em pacote de 2 anos (total indicado)",
    "* 3 anos: preco efetivo por ano em pacote de 3 anos (total indicado)",
    "* Cliente direto apenas. Dealer nao participa do modelo de receita."
)
gerarTabela "Irricontrol ONE" "Tabela de Precos Global (Cliente Direto)" @("Volume", "1 Ano", "2 Anos (ef)", "3 Anos (ef)") $labelsPT $notasPT "tabela-precos-pt.jpg"

# EN
$labelsEN = @{ devices = "devices"; year = "yr"; total = "total"; ref = "(reference)"; perYear = "per year" }
$notasEN = @(
    "* Global reference price: USD $precoBase/device/year (Bauer table, Helton 2024 proposal)",
    "* 2 years: effective price per year in 2-year package (total shown)",
    "* 3 years: effective price per year in 3-year package (total shown)",
    "* Direct client only. Dealer does not participate in the revenue model."
)
gerarTabela "Irricontrol ONE" "Global Pricing Table (Direct Client)" @("Volume", "1 Year", "2 Years (ef)", "3 Years (ef)") $labelsEN $notasEN "tabela-precos-en.jpg"

# ES
$labelsES = @{ devices = "dispositivos"; year = "ano"; total = "total"; ref = "(referencia)"; perYear = "por ano" }
$notasES = @(
    "* Precio de referencia global: USD $precoBase/dispositivo/ano (tabla Bauer, propuesta Helton 2024)",
    "* 2 anos: precio efectivo por ano en paquete de 2 anos (total indicado)",
    "* 3 anos: precio efectivo por ano en paquete de 3 anos (total indicado)",
    "* Cliente directo unicamente. Dealer no participa en el modelo de ingresos."
)
gerarTabela "Irricontrol ONE" "Tabla de Precios Global (Cliente Directo)" @("Volumen", "1 Ano", "2 Anos (ef)", "3 Anos (ef)") $labelsES $notasES "tabela-precos-es.jpg"

Write-Output ""
Write-Output "Todas as 3 tabelas geradas em dados/"
