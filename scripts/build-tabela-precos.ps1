# Gerar Tabela de Precos Global - Irricontrol ONE
# Esquema de cores da referencia image.png:
#   #55B93C (verde) = cabecalho/cor principal
#   #0092D6 (azul) = cor secundaria
#   #505050 (cinza escuro) = texto
#   #DADADA (cinza claro) = bordas
#   #FFFFFF (branco) = fundo
# Dados reais da tabela Bauer (cliente direto apenas)
# 3 idiomas: PT, EN, ES
# Saida: dados/tabela-precos-{pt,en,es}.jpg

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

Add-Type -AssemblyName System.Drawing

Write-Output "=== GERANDO TABELA DE PRECOS GLOBAL (3 IDIOMAS, cores da referencia) ==="

# Dados reais da tabela Bauer
$clienteDireto = @(
    @{ tier = "1-10"; a1 = 220; a2ef = 195; a3ef = 170; total2 = 390; total3 = 510 }
    @{ tier = "11-20"; a1 = 209; a2ef = 185; a3ef = 162; total2 = 370; total3 = 486 }
    @{ tier = "21-30"; a1 = 196; a2ef = 174; a3ef = 151; total2 = 348; total3 = 453 }
    @{ tier = "31-40"; a1 = 183; a2ef = 162; a3ef = 141; total2 = 324; total3 = 423 }
    @{ tier = "41-50"; a1 = 167; a2ef = 148; a3ef = 129; total2 = 296; total3 = 387 }
)

$precoBase = 220

# CORES DA REFERENCIA image.png
$COLOR_GREEN = [System.Drawing.Color]::FromArgb(0x55, 0xB9, 0x3C)    # #55B93C
$COLOR_BLUE  = [System.Drawing.Color]::FromArgb(0x00, 0x92, 0xD6)   # #0092D6
$COLOR_DKGRAY = [System.Drawing.Color]::FromArgb(0x50, 0x50, 0x50)  # #505050
$COLOR_LTGRAY = [System.Drawing.Color]::FromArgb(0xDA, 0xDA, 0xDA)  # #DADADA
$COLOR_WHITE  = [System.Drawing.Color]::White

function pctDesc($atual, $base) {
    return [Math]::Round((($atual - $base) / $base) * 100, 0)
}

function gerarTabela($titulo, $subtitulo, $colHeaders, $labels, $notas, $fileName) {
    $width = 1000
    $height = 720
    $headerHeight = 55
    $rowHeight = 78
    $colWidths = @(180, 220, 220, 220)
    
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    
    # Fundo branco
    $g.FillRectangle([System.Drawing.SolidBrush]::new($COLOR_WHITE), 0, 0, $width, $height)
    
    # Fontes
    $fontTitle = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 11)
    $fontHeader = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $fontCell = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $fontDesc = New-Object System.Drawing.Font("Segoe UI", 9)
    $fontTotal = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $fontNote = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    
    # Barra verde no topo (referencia)
    $g.FillRectangle([System.Drawing.SolidBrush]::new($COLOR_GREEN), 0, 0, $width, 8)
    
    # Titulo em verde
    $titleSize = $g.MeasureString($titulo, $fontTitle)
    $titleX = ($width - $titleSize.Width) / 2
    $g.DrawString($titulo, $fontTitle, [System.Drawing.SolidBrush]::new($COLOR_GREEN), $titleX, 24)
    
    # Subtitulo em cinza escuro
    $subSize = $g.MeasureString($subtitulo, $fontSubtitle)
    $subX = ($width - $subSize.Width) / 2
    $g.DrawString($subtitulo, $fontSubtitle, [System.Drawing.SolidBrush]::new($COLOR_DKGRAY), $subX, 54)
    
    # Tabela
    $tableTop = 90
    $tableLeft = ($width - ($colWidths | Measure-Object -Sum).Sum) / 2
    $totalTableWidth = ($colWidths | Measure-Object -Sum).Sum
    
    # Cabecalho: verde
    $colX = $tableLeft
    for ($i = 0; $i -lt $colHeaders.Count; $i++) {
        $rect = [System.Drawing.RectangleF]::new($colX, $tableTop, $colWidths[$i], $headerHeight)
        $g.FillRectangle([System.Drawing.SolidBrush]::new($COLOR_GREEN), $rect)
        $g.DrawString($colHeaders[$i], $fontHeader, [System.Drawing.SolidBrush]::new($COLOR_WHITE), $rect.X + 12, $rect.Y + 18)
        $colX += $colWidths[$i]
    }
    
    # Linhas: alternancia branco/cinza muito claro
    for ($row = 0; $row -lt $clienteDireto.Count; $row++) {
        $data = $clienteDireto[$row]
        $rowY = $tableTop + $headerHeight + ($row * $rowHeight)
        # Fundo alternado
        $bg = if ($row % 2 -eq 0) { $COLOR_WHITE } else { [System.Drawing.Color]::FromArgb(0xF5, 0xF5, 0xF5) }
        $g.FillRectangle([System.Drawing.SolidBrush]::new($bg), $tableLeft, $rowY, $totalTableWidth, $rowHeight)
        # Borda inferior cinza claro
        $g.DrawLine([System.Drawing.Pen]::new($COLOR_LTGRAY, 1), $tableLeft, $rowY + $rowHeight, $tableLeft + $totalTableWidth, $rowY + $rowHeight)
        
        # Volume
        $colX = $tableLeft + 14
        $g.DrawString($data.tier + " " + $labels.devices, $fontCell, [System.Drawing.SolidBrush]::new($COLOR_DKGRAY), $colX, $rowY + 12)
        
        # 1 Ano
        $colX = $tableLeft + $colWidths[0] + 14
        $g.DrawString("USD " + $data.a1, $fontCell, [System.Drawing.SolidBrush]::new($COLOR_DKGRAY), $colX, $rowY + 8)
        if ($row -eq 0) {
            $g.DrawString($labels.ref, $fontDesc, [System.Drawing.SolidBrush]::new($COLOR_DKGRAY), $colX, $rowY + 36)
        } else {
            $d = pctDesc $data.a1 $precoBase
            $g.DrawString("(" + $d + "%)", $fontDesc, [System.Drawing.SolidBrush]::new($COLOR_BLUE), $colX, $rowY + 36)
        }
        $g.DrawString("(" + $labels.perYear + ")", $fontDesc, [System.Drawing.SolidBrush]::new($COLOR_LTGRAY), $colX, $rowY + 52)
        
        # 2 Anos (ef) - azul
        $colX = $tableLeft + $colWidths[0] + $colWidths[1] + 14
        $g.DrawString("USD " + $data.a2ef + "/" + $labels.year, $fontCell, [System.Drawing.SolidBrush]::new($COLOR_BLUE), $colX, $rowY + 8)
        $d2 = pctDesc $data.a2ef $precoBase
        $g.DrawString("(" + $d2 + "%)", $fontDesc, [System.Drawing.SolidBrush]::new($COLOR_BLUE), $colX, $rowY + 36)
        $g.DrawString("(" + $labels.total + ": USD " + $data.total2 + ")", $fontTotal, [System.Drawing.SolidBrush]::new($COLOR_LTGRAY), $colX, $rowY + 52)
        
        # 3 Anos (ef) - verde
        $colX = $tableLeft + $colWidths[0] + $colWidths[1] + $colWidths[2] + 14
        $g.DrawString("USD " + $data.a3ef + "/" + $labels.year, $fontCell, [System.Drawing.SolidBrush]::new($COLOR_GREEN), $colX, $rowY + 8)
        $d3 = pctDesc $data.a3ef $precoBase
        $g.DrawString("(" + $d3 + "%)", $fontDesc, [System.Drawing.SolidBrush]::new($COLOR_GREEN), $colX, $rowY + 36)
        $g.DrawString("(" + $labels.total + ": USD " + $data.total3 + ")", $fontTotal, [System.Drawing.SolidBrush]::new($COLOR_LTGRAY), $colX, $rowY + 52)
    }
    
    # Rodape
    $noteY = $tableTop + $headerHeight + ($clienteDireto.Count * $rowHeight) + 22
    $g.DrawLine([System.Drawing.Pen]::new($COLOR_LTGRAY, 1), $tableLeft, $noteY - 10, $tableLeft + $totalTableWidth, $noteY - 10)
    
    for ($i = 0; $i -lt $notas.Count; $i++) {
        $g.DrawString($notas[$i], $fontNote, [System.Drawing.SolidBrush]::new($COLOR_DKGRAY), $tableLeft, $noteY + ($i * 17))
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
Write-Output "Todas as 3 tabelas geradas com esquema de cores da referencia."
