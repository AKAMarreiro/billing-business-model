# Build de XLSX - Irricontrol ONE Receita
# Gera dist/modelo.xlsx com multiplas abas

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
Write-Output "=== BUILD XLSX ==="

# Carregar dados
$premissas = Get-Content "$Root\dados\premissas.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$base = Get-Content "$Root\dados\base-dispositivos.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$pricing = Get-Content "$Root\dados\pricing-global.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$derivados = Get-Content "$Root\dist\derivados.json" -Raw -Encoding UTF8 | ConvertFrom-Json

# Carregar serie Stripe
$csv = Import-Csv "$Root\dados\stripe-mensal.csv" -Header @('mes','charge','invoice') | Select-Object -Skip 1
$stripeMensal = @()
foreach ($linha in $csv) {
    $stripeMensal += [PSCustomObject]@{
        Mes = $linha.mes
        Charge = if ($linha.charge -ne '' -and $linha.charge -ne 'null') { [decimal]$linha.charge } else { $null }
        Invoice = if ($linha.invoice -ne '' -and $linha.invoice -ne 'null') { [decimal]$linha.invoice } else { $null }
    }
}

# Carregar motor PowerShell (reaproveitar funcoes de build-derivados)
. "$Root\scripts\build-derivados.ps1"
$cenarios = calcularProjecaoCenarios $premissas $base

# Criar Excel
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()

function add-sheet($nome, $dados) {
    $ws = $wb.Sheets.Add()
    $ws.Name = $nome
    $row = 1
    foreach ($item in $dados) {
        $col = 1
        foreach ($prop in $item.PSObject.Properties) {
            if ($row -eq 1) { $ws.Cells.Item($row, $col) = $prop.Name }
            $val = $prop.Value
            if ($val -is [double] -or $val -is [decimal]) {
                $ws.Cells.Item($row + 1, $col) = [double]$val
                if ($prop.Name -match '(receita|margem|custo|preco|valor|charge|invoice|volume|arr|arpu)') {
                    $ws.Cells.Item($row + 1, $col).NumberFormat = '#,##0'
                }
            } elseif ($val -is [int]) {
                $ws.Cells.Item($row + 1, $col) = [int]$val
                $ws.Cells.Item($row + 1, $col).NumberFormat = '#,##0'
            } elseif ($val -is [bool]) {
                $ws.Cells.Item($row + 1, $col) = if ($val) { 'Sim' } else { 'Nao' }
            } else {
                $ws.Cells.Item($row + 1, $col) = [string]$val
            }
            $col++
        }
        $row++
    }
    # Estilo header
    $headerRange = $ws.Range($ws.Cells.Item(1, 1), $ws.Cells.Item(1, $col - 1))
    $headerRange.Font.Bold = $true
    $headerRange.Interior.ColorIndex = 23
    $headerRange.Font.ColorIndex = 2
    $headerRange.HorizontalAlignment = -4108
    $ws.Columns.AutoFit()
}

# 1. Resumo
$resumo = @(
    [PSCustomObject]@{ Metrica = 'Data do corte'; Valor = $base.dataCorte }
    [PSCustomObject]@{ Metrica = 'Dispositivos no escopo'; Valor = $derivados.totalEscopo }
    [PSCustomObject]@{ Metrica = 'Pontos pagantes'; Valor = $derivados.pontosPagantes }
    [PSCustomObject]@{ Metrica = 'Fazendas'; Valor = $derivados.fazendas }
    [PSCustomObject]@{ Metrica = 'Potencial anual'; Valor = $derivados.potencialCompleto }
    [PSCustomObject]@{ Metrica = 'Receita recorrente hoje'; Valor = $derivados.receitaRecorrenteHoje }
    [PSCustomObject]@{ Metrica = 'Gap anual'; Valor = $derivados.gapCompleto }
    [PSCustomObject]@{ Metrica = 'Taxa de realizacao'; Valor = "$($derivados.realizacaoCompleto)%" }
    [PSCustomObject]@{ Metrica = 'Receita 2025 (Stripe)'; Valor = $derivados.receita2025 }
    [PSCustomObject]@{ Metrica = 'Receita escondida (ano base)'; Valor = $derivados.receitaEscondidaAnoBase }
    [PSCustomObject]@{ Metrica = 'Receita escondida (acumulada 5 anos)'; Valor = $derivados.receitaEscondidaAcumuladaBase }
    [PSCustomObject]@{ Metrica = 'Anuidade de referencia'; Valor = $premissas.anuidadeRef }
    [PSCustomObject]@{ Metrica = 'Preco de tabela SaaS'; Valor = $premissas.precoTabelaSaaS }
    [PSCustomObject]@{ Metrica = 'Preco alvo SaaS (cartao)'; Valor = $premissas.precoAlvoSaaS }
    [PSCustomObject]@{ Metrica = 'Custo fixo plataforma/ano'; Valor = $premissas.custoFixoPlataforma }
    [PSCustomObject]@{ Metrica = 'Custo variavel/ponto'; Valor = ($premissas.custoVarPontoInfra + $premissas.custoVarPontoSuporte) }
    [PSCustomObject]@{ Metrica = 'ARR atual'; Valor = $derivados.arrAtual }
    [PSCustomObject]@{ Metrica = 'ARR com novos produtos'; Valor = $derivados.arrNovo }
    [PSCustomObject]@{ Metrica = 'Receita A 2030 (conservador)'; Valor = $derivados.receitaA2030 }
    [PSCustomObject]@{ Metrica = 'Receita B 2030 (base)'; Valor = $derivados.receitaB2030 }
    [PSCustomObject]@{ Metrica = 'Receita C 2030 (otimista)'; Valor = $derivados.receitaC2030 }
)
add-sheet 'Resumo' $resumo

# 2. Premissas
$premList = @()
$premissas.PSObject.Properties | ForEach-Object {
    $premList += [PSCustomObject]@{ Chave = $_.Name; Valor = $_.Value }
}
add-sheet 'Premissas' $premList

# 3. Escopo
$escopoList = @()
$base.PSObject.Properties | ForEach-Object {
    $escopoList += [PSCustomObject]@{ Chave = $_.Name; Valor = if ($_.Value -is [PSCustomObject]) { ($_.Value | ConvertTo-Json -Compress) } else { $_.Value } }
}
add-sheet 'Escopo' $escopoList

# 4. Stripe Mensal
add-sheet 'Stripe Mensal' $stripeMensal

# 5. Pricing Global
$pricingList = @()
foreach ($tier in $pricing.clienteDireto) {
    $pricingList += [PSCustomObject]@{ Tipo = 'Cliente Direto'; Tier = $tier.tier; Ano1 = $tier.ano1; Ano2ef = $tier.ano2ef; Ano3ef = $tier.ano3ef }
}
foreach ($tier in $pricing.dealerRevendedor) {
    $pricingList += [PSCustomObject]@{ Tipo = 'Dealer'; Tier = $tier.tier; Ano1 = $tier.ano1; Ano2ef = $tier.ano2ef; Ano3ef = $tier.ano3ef }
}
add-sheet 'Pricing Global' $pricingList

# 6. Cenarios 5 Anos
$cenarioList = @()
foreach ($nome in @('conservador','baseline','otimista')) {
    $cen = $cenarios[$nome]
    foreach ($ano in $cen.anos) {
        $cenData = [PSCustomObject]@{
            Cenario = $nome.ToUpper()
            Ano = $ano.ano
            TotalPontos = $ano.totalPontos
            NovosEntrantes = $ano.novos
            ReceitaReconhecida = [Math]::Round($ano.receitaReconhecida, 0)
            ReceitaEscondida = [Math]::Round($ano.receitaEscondida, 0)
            ReceitaVerdadeira = [Math]::Round($ano.receitaVerdadeira, 0)
            CustoTotal = [Math]::Round($ano.custoTotal, 0)
            Margem = [Math]::Round($ano.margem, 0)
            MargemPct = [Math]::Round($ano.margemPct * 100, 1)
            MargemVerdadeira = [Math]::Round($ano.margemVerdadeira, 0)
            MargemVerdadeiraPct = [Math]::Round($ano.margemVerdadeiraPct * 100, 1)
        }
        $cenData | Add-Member -NotePropertyName 'PrecoUnit' -NotePropertyValue ([Math]::Round($ano.preco, 0)) -Force
        $cenData | Add-Member -NotePropertyName 'CaixaPacote' -NotePropertyValue ([Math]::Round($ano.caixaPacote, 0)) -Force
        $cenData | Add-Member -NotePropertyName 'ReceitaPacote' -NotePropertyValue ([Math]::Round($ano.receitaPacote, 0)) -Force
        $cenData | Add-Member -NotePropertyName 'ReceitaRecorrente' -NotePropertyValue ([Math]::Round($ano.receitaRecorrente, 0)) -Force
        $cenarioList += $cenData
    }
}
add-sheet 'Cenarios 5 Anos' $cenarioList

# 7. Receita Escondida Detalhada
$escondidaList = @()
foreach ($ano in $cenarios.baseline.anos) {
    $escondidaList += [PSCustomObject]@{
        Ano = $ano.ano
        NovosEntrantes = $ano.novos
        PrecoUnit = [Math]::Round($ano.preco, 0)
        ReceitaEscondida = [Math]::Round($ano.receitaEscondida, 0)
        ReceitaReconhecida = [Math]::Round($ano.receitaReconhecida, 0)
        ReceitaVerdadeira = [Math]::Round($ano.receitaVerdadeira, 0)
        MargemReconhecida = [Math]::Round($ano.margem, 0)
        MargemVerdadeira = [Math]::Round($ano.margemVerdadeira, 0)
        DiferencaMargem = [Math]::Round($ano.margemVerdadeira - $ano.margem, 0)
    }
}
add-sheet 'Receita Escondida' $escondidaList

# Salvar
$path = "$Root\dist\modelo.xlsx"
if (Test-Path $path) { Remove-Item $path }
$wb.SaveAs($path, 51)  # 51 = xlOpenXMLWorkbook
$wb.Close()
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

Write-Output ""
Write-Output "OK dist/modelo.xlsx gerado."
Write-Output "  Abas: Resumo, Premissas, Escopo, Stripe Mensal, Pricing Global, Cenarios 5 Anos, Receita Escondida"
