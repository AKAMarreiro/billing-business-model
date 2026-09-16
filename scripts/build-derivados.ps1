# Build de Derivados - Irricontrol ONE Receita
# Reimplementacao do motor em PowerShell (sem Node)
# Saida: dist/derivados.json

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
Write-Output "=== BUILD DERIVADOS ==="

# Carregar dados
$premissas = Get-Content "$Root\dados\premissas.json" -Raw | ConvertFrom-Json
$base = Get-Content "$Root\dados\base-dispositivos.json" -Raw | ConvertFrom-Json
$pricing = Get-Content "$Root\dados\pricing-global.json" -Raw | ConvertFrom-Json

# Funcoes do motor
function calcularEscopoPotencial($premissas, $base) {
    $totalPivos = $base.pivos.efetivos
    $totalIrripump = $base.irripump
    $totalMedidor = $base.medidorNivel
    $totalEscopo = $totalPivos + $totalIrripump + $totalMedidor
    $potencialHistorico = $totalPivos * $premissas.anuidadeRef
    $potencialCompleto = $totalEscopo * $premissas.anuidadeRef
    $receitaRecorrenteHoje = $base.pontosPagantes * $premissas.anuidadeRef * (1 - $premissas.inadimplencia)
    $gapCompleto = $potencialCompleto - $receitaRecorrenteHoje
    $realizacaoHistorico = ($base.pontosPagantes * $premissas.anuidadeRef) / $potencialHistorico
    $realizacaoCompleto = $receitaRecorrenteHoje / $potencialCompleto
    return @{
        totalPivos = $totalPivos; totalIrripump = $totalIrripump
        totalMedidor = $totalMedidor; totalEscopo = $totalEscopo
        potencialHistorico = $potencialHistorico; potencialCompleto = $potencialCompleto
        receitaRecorrenteHoje = $receitaRecorrenteHoje; gapCompleto = $gapCompleto
        realizacaoHistorico = $realizacaoHistorico; realizacaoCompleto = $realizacaoCompleto
        fazendas = $base.fazendas; usuariosAtivos = $base.usuariosAtivos
        pontosPagantes = $base.pontosPagantes; dataCorte = $base.dataCorte
    }
}

function calcularCusto($premissas, $totalPontos, $ano = 1) {
    $custoVarTotal = $premissas.custoVarPontoInfra + $premissas.custoVarPontoSuporte
    $custoVar = $totalPontos * $custoVarTotal
    $custoFixo = $premissas.custoFixoPlataforma
    $custoOperacao = $premissas.custoOperacaoBilling
    return @{ custoFixo = $custoFixo; custoVar = $custoVar; custoOperacao = $custoOperacao; custoTotal = $custoFixo + $custoVar + $custoOperacao }
}

function calcularReceitaReconhecida($premissas, $config) {
    $baseInicial = $config.baseInicial
    $novosEntrantes = $config.novosEntrantes
    $adocaoMadura = $config.adocaoMadura
    $adocaoNovos = $config.adocaoNovos
    $anosProjecao = if ($config.anosProjecao) { $config.anosProjecao } else { 5 }
    $resultados = @()
    $pontosAtivos = $baseInicial
    $coortes = @()
    for ($ano = 1; $ano -le $anosProjecao; $ano++) {
        $preco = $premissas.anuidadeRef * [Math]::Pow(1 + $premissas.reajusteAno, $ano - 1)
        $madura = [Math]::Round($pontosAtivos * (1 - $premissas.churnAno))
        $maduraPacote = [Math]::Round($madura * $adocaoMadura)
        $maduraRecorrente = $madura - $maduraPacote
        $novos = $novosEntrantes
        $novosPacote = if ($ano -gt 1) { [Math]::Round($novos * $adocaoNovos) } else { 0 }
        $novosRecorrente = $novos - $novosPacote
        $caixaPacote = 0
        if ($ano -eq 1 -and $maduraPacote -gt 0) {
            $caixaPacote = $maduraPacote * $preco * $premissas.anosPacote * (1 - $premissas.descontoPacote)
            $coortes += [PSCustomObject]@{ pts = $maduraPacote; anoIni = $ano; totalContrato = $caixaPacote; precoUnit = $preco; renovada = $false }
        }
        if ($ano -ge 2 -and $novosPacote -gt 0) {
            $caixaNovos = $novosPacote * $preco * $premissas.anosPacote * (1 - $premissas.descontoPacote)
            $caixaPacote += $caixaNovos
            $coortes += [PSCustomObject]@{ pts = $novosPacote; anoIni = $ano; totalContrato = $caixaNovos; precoUnit = $preco; renovada = $false }
        }
        for ($i = 0; $i -lt $coortes.Count; $i++) {
            $c = $coortes[$i]
            if (-not $c.renovada -and $ano -eq ($c.anoIni + $premissas.anosPacote)) {
                $ptsSobreviventes = [Math]::Round($c.pts * [Math]::Pow(1 - $premissas.churnAno, $premissas.anosPacote))
                if ($ptsSobreviventes -gt 0) {
                    $caixaRenov = $ptsSobreviventes * $preco * $premissas.anosPacote * (1 - $premissas.descontoPacote)
                    $coortes += [PSCustomObject]@{ pts = $ptsSobreviventes; anoIni = $ano; totalContrato = $caixaRenov; precoUnit = $preco; renovada = $false }
                    $c.renovada = $true
                }
            }
        }
        $receitaPacote = 0
        foreach ($c in $coortes) {
            $anosDecorridos = $ano - $c.anoIni
            if ($anosDecorridos -ge 0 -and $anosDecorridos -lt $premissas.anosPacote) { $receitaPacote += $c.totalContrato / $premissas.anosPacote }
        }
        $recMadura = $maduraRecorrente * $preco * (1 - $premissas.descontoPacote) * (1 - $premissas.inadimplencia)
        $recNovos = if ($ano -gt 1) { $novosRecorrente * $preco * (1 - $premissas.descontoPacote) * (1 - $premissas.inadimplencia) } else { 0 }
        $receitaRecorrente = $recMadura + $recNovos
        $receitaReconhecida = $receitaRecorrente + $receitaPacote
        $receitaEscondida = $novos * $preco
        $receitaVerdadeira = $receitaReconhecida + $receitaEscondida
        $totalPontos = $madura + $novos
        $custo = calcularCusto $premissas $totalPontos $ano
        $margem = $receitaReconhecida - $custo.custoTotal
        $margemPct = if ($receitaReconhecida -gt 0) { $margem / $receitaReconhecida } else { 0 }
        $margemVerdadeira = $receitaVerdadeira - $custo.custoTotal
        $margemVerdadeiraPct = if ($receitaVerdadeira -gt 0) { $margemVerdadeira / $receitaVerdadeira } else { 0 }
        $resultados += [PSCustomObject]@{
            ano = $premissas.anoBase + $ano - 1; totalPontos = $totalPontos; madura = $madura; maduraPacote = $maduraPacote
            maduraRecorrente = $maduraRecorrente; novos = $novos; novosPacote = $novosPacote; novosRecorrente = $novosRecorrente
            preco = $preco; caixaPacote = $caixaPacote; receitaRecorrente = $receitaRecorrente; receitaPacote = $receitaPacote
            receitaReconhecida = $receitaReconhecida; receitaEscondida = $receitaEscondida; receitaVerdadeira = $receitaVerdadeira
            custoTotal = $custo.custoTotal; margem = $margem; margemPct = $margemPct
            margemVerdadeira = $margemVerdadeira; margemVerdadeiraPct = $margemVerdadeiraPct
        }
        $pontosAtivos = $madura + $novos
    }
    return @{ coortes = $coortes; anos = $resultados }
}

function calcularProjecaoCenarios($premissas, $base) {
    $configs = @{
        conservador = @{ nome = 'A - Conservador'; baseInicial = $base.pontosPagantes; novosEntrantes = $premissas.novosEntrantesConservador; adocaoMadura = $premissas.adocaoPacoteBaixa; adocaoNovos = $premissas.adocaoPacoteBaixa }
        baseline = @{ nome = 'B - Base (provavel)'; baseInicial = $base.pontosPagantes; novosEntrantes = $premissas.novosEntrantesAno; adocaoMadura = $premissas.adocaoPacoteMadura; adocaoNovos = $premissas.adocaoPacoteNovos }
        otimista = @{ nome = 'C - Otimista'; baseInicial = $base.pontosPagantes; novosEntrantes = $premissas.novosEntrantesOtimista; adocaoMadura = $premissas.adocaoPacoteMadura; adocaoNovos = $premissas.adocaoPacoteMadura }
    }
    $resultados = @{}
    foreach ($kv in $configs.GetEnumerator()) { $resultados[$kv.Key] = calcularReceitaReconhecida $premissas $kv.Value }
    return $resultados
}

function calcularPricingComparado($premissas, $pricing) {
    $precoUSD = $premissas.anuidadeRef / $premissas.cambioUSDBRL
    $tabelaDireta = $pricing.clienteDireto
    $tierCorrespondente = $null
    foreach ($tier in $tabelaDireta) { if ($precoUSD -ge $tier.ano3ef -and $precoUSD -le $tier.ano1) { $tierCorrespondente = $tier; break } }
    $tabelaDealer = $pricing.dealerRevendedor
    $dealerMin = $tabelaDealer[-1].ano3ef
    $dealerMax = $tabelaDealer[0].ano1
    return @{ precoReais = $premissas.anuidadeRef; precoUSD = $precoUSD; tierCorrespondente = $tierCorrespondente; dealerMin = $dealerMin; dealerMax = $dealerMax; distanciaDealer = $precoUSD - $dealerMax }
}

# Calculos
$escopo = calcularEscopoPotencial $premissas $base
$pricingComp = calcularPricingComparado $premissas $pricing
$cenarios = calcularProjecaoCenarios $premissas $base

# Serie Stripe (CSV)
$csv = Import-Csv "$Root\dados\stripe-mensal.csv" -Header @('mes','charge','invoice') | Select-Object -Skip 1
$stripeAnual = @{}
foreach ($linha in $csv) {
    $ano = ($linha.mes -split '-')[0]
    if (-not $stripeAnual[$ano]) { $stripeAnual[$ano] = @{ charge = 0; invoice = 0 } }
    if ($linha.charge -ne '' -and $linha.charge -ne 'null') { $stripeAnual[$ano].charge += [decimal]$linha.charge }
    if ($linha.invoice -ne '' -and $linha.invoice -ne 'null') { $stripeAnual[$ano].invoice += [decimal]$linha.invoice }
}

# Montar derivados
$derivados = @{
    totalPivos = $escopo.totalPivos; totalIrripump = $escopo.totalIrripump; totalMedidor = $escopo.totalMedidor
    totalEscopo = $escopo.totalEscopo; fazendas = $escopo.fazendas; usuariosAtivos = $escopo.usuariosAtivos
    pontosPagantes = $escopo.pontosPagantes; dataCorte = $escopo.dataCorte
    potencialHistorico = $escopo.potencialHistorico; potencialCompleto = $escopo.potencialCompleto
    receitaRecorrenteHoje = $escopo.receitaRecorrenteHoje; gapCompleto = $escopo.gapCompleto
    realizacaoHistorico = [Math]::Round($escopo.realizacaoHistorico * 100, 2)
    realizacaoCompleto = [Math]::Round($escopo.realizacaoCompleto * 100, 2)
    chargeAbr2024 = $stripeAnual['2024'].charge; invoiceAbr2024 = $stripeAnual['2024'].invoice
    invoiceOut2024 = $stripeAnual['2024'].invoice; chargeOut2024 = $stripeAnual['2024'].charge
    charge2025 = $stripeAnual['2025'].charge; invoice2025 = $stripeAnual['2025'].invoice
    charge2026 = $stripeAnual['2026'].charge; invoice2026 = $stripeAnual['2026'].invoice
    receita2025 = $stripeAnual['2025'].invoice
    realizacao2025 = [Math]::Round(($stripeAnual['2025'].charge / $escopo.potencialCompleto) * 100, 2)
    anuidadeRef = $premissas.anuidadeRef; precoTabelaSaaS = $premissas.precoTabelaSaaS
    precoAlvoSaaS = $premissas.precoAlvoSaaS; cambioUSDBRL = $premissas.cambioUSDBRL
    precoUSD = [Math]::Round($pricingComp.precoUSD, 2)
    tierCorrespondente = if ($pricingComp.tierCorrespondente) { $pricingComp.tierCorrespondente.tier } else { 'N/A' }
    tierMin = if ($pricingComp.tierCorrespondente) { $pricingComp.tierCorrespondente.ano3ef } else { 0 }
    tierMax = if ($pricingComp.tierCorrespondente) { $pricingComp.tierCorrespondente.ano1 } else { 0 }
    descontoMax = 40; descontoPacote = $premissas.descontoPacote
    precoEfetivo = [Math]::Round($premissas.anuidadeRef * (1 - $premissas.descontoPacote), 2)
    dealerMin = [Math]::Round($pricingComp.dealerMin * $premissas.cambioUSDBRL, 0)
    dealerMax = [Math]::Round($pricingComp.dealerMax * $premissas.cambioUSDBRL, 0)
    spreadDiretoDealer = [Math]::Round(($pricingComp.tierCorrespondente.ano1 - $pricingComp.dealerMax), 2)
    spreadDiretoDealerMax = [Math]::Round(($pricingComp.tierCorrespondente.ano3ef - $pricingComp.dealerMin), 2)
    spreadBrasil = [Math]::Round($premissas.anuidadeRef - ($premissas.anuidadeRef * (1 - $premissas.descontoPacote)), 2)
    projecaoClientes = [Math]::Round($base.pontosPagantes * [Math]::Pow(1.05, 5), 0)
    precoSAF = $pricing.safSystem.preco
    volumeTotal = [Math]::Round($stripeAnual['2025'].charge + $stripeAnual['2026'].charge, 0)
    novosEntrantesConservador = $premissas.novosEntrantesConservador; novosEntrantesAno = $premissas.novosEntrantesAno
    novosEntrantesOtimista = $premissas.novosEntrantesOtimista; adocaoPacoteMadura = $premissas.adocaoPacoteMadura
    adocaoPacoteBaixa = $premissas.adocaoPacoteBaixa; churnAno = $premissas.churnAno; inadimplencia = $premissas.inadimplencia
    receitaA2030 = [Math]::Round($cenarios.conservador.anos[4].receitaReconhecida, 0)
    margemA2030 = [Math]::Round($cenarios.conservador.anos[4].margem, 0)
    receitaB2030 = [Math]::Round($cenarios.baseline.anos[4].receitaReconhecida, 0)
    margemB2030 = [Math]::Round($cenarios.baseline.anos[4].margem, 0)
    receitaC2030 = [Math]::Round($cenarios.otimista.anos[4].receitaReconhecida, 0)
    margemC2030 = [Math]::Round($cenarios.otimista.anos[4].margem, 0)
    receitaEscondidaAnoBase = [Math]::Round($cenarios.baseline.anos[0].receitaEscondida, 0)
    precoNovoProduto = $premissas.precoNovoProduto; adocaoNovoProduto = $premissas.adocaoNovoProduto
    arpuAtual = [Math]::Round($premissas.anuidadeRef * (1 - $premissas.descontoPacote), 0)
    arpuNovo = [Math]::Round($premissas.anuidadeRef * (1 - $premissas.descontoPacote) + ($premissas.precoNovoProduto * $premissas.adocaoNovoProduto * 2), 0)
    arrAtual = [Math]::Round($base.pontosPagantes * $premissas.anuidadeRef * (1 - $premissas.descontoPacote), 0)
    arrNovo = [Math]::Round($base.pontosPagantes * ($premissas.anuidadeRef * (1 - $premissas.descontoPacote) + ($premissas.precoNovoProduto * $premissas.adocaoNovoProduto * 2)), 0)
    receitaPropria = [Math]::Round($stripeAnual['2025'].charge * 0.7, 0)
    passThrough = [Math]::Round($stripeAnual['2025'].charge * 0.3, 0)
    arpuFazenda = [Math]::Round($base.pontosPagantes * $premissas.anuidadeRef / $base.fazendas, 0)
}

# Adicionar campo calculado apos hashtable
$acumEscondida = 0
foreach ($a in $cenarios.baseline.anos) { $acumEscondida += $a.receitaEscondida }
$derivados['receitaEscondidaAcumuladaBase'] = [Math]::Round($acumEscondida, 0)

# Dados para graficos no HTML
$serieStripe = @()
foreach ($linha in $csv) {
    $serieStripe += [PSCustomObject]@{ mes = $linha.mes; charge = [decimal]$linha.charge; invoice = [decimal]$linha.invoice }
}
$derivados['serieStripe'] = $serieStripe

$cenariosJson = @{
    conservador = $cenarios.conservador.anos | ForEach-Object {
        [PSCustomObject]@{
            ano = $_.ano; receitaReconhecida = [Math]::Round($_.receitaReconhecida,0)
            receitaEscondida = [Math]::Round($_.receitaEscondida,0); receitaVerdadeira = [Math]::Round($_.receitaVerdadeira,0)
            margem = [Math]::Round($_.margem,0); margemVerdadeira = [Math]::Round($_.margemVerdadeira,0)
            totalPontos = $_.totalPontos; novos = $_.novos
        }
    }
    baseline = $cenarios.baseline.anos | ForEach-Object {
        [PSCustomObject]@{
            ano = $_.ano; receitaReconhecida = [Math]::Round($_.receitaReconhecida,0)
            receitaEscondida = [Math]::Round($_.receitaEscondida,0); receitaVerdadeira = [Math]::Round($_.receitaVerdadeira,0)
            margem = [Math]::Round($_.margem,0); margemVerdadeira = [Math]::Round($_.margemVerdadeira,0)
            totalPontos = $_.totalPontos; novos = $_.novos
        }
    }
    otimista = $cenarios.otimista.anos | ForEach-Object {
        [PSCustomObject]@{
            ano = $_.ano; receitaReconhecida = [Math]::Round($_.receitaReconhecida,0)
            receitaEscondida = [Math]::Round($_.receitaEscondida,0); receitaVerdadeira = [Math]::Round($_.receitaVerdadeira,0)
            margem = [Math]::Round($_.margem,0); margemVerdadeira = [Math]::Round($_.margemVerdadeira,0)
            totalPontos = $_.totalPontos; novos = $_.novos
        }
    }
}
$derivados['cenariosDetalhado'] = $cenariosJson

# Salvar
if (-not (Test-Path "$Root\dist")) { New-Item -ItemType Directory -Path "$Root\dist" | Out-Null }
$derivados | ConvertTo-Json -Depth 10 | Set-Content "$Root\dist\derivados.json" -Encoding UTF8

Write-Output ""
Write-Output "OK dist/derivados.json gerado com $($derivados.Count) chaves."
Write-Output "Next: scripts/build-html.ps1"
