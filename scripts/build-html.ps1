# Build de HTML com Graficos e Simulador - Irricontrol ONE Receita
# Resolve placeholders + adiciona charts + simulador interativo

param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = 'Stop'
Write-Output "=== BUILD HTML COM GRAFICOS ==="

# Carregar derivados
$derivados = Get-Content "$Root\dist\derivados.json" -Raw | ConvertFrom-Json

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
$placeholders = [regex]::Matches($mdCompleto, '\{\{(\w+)(?:\|\w+)?\}\}')
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

# Converter MD para HTML
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

# Extrair dados para graficos
$serieStripe = $derivados.serieStripe | ConvertTo-Json -Depth 10
$cenariosDet = $derivados.cenariosDetalhado | ConvertTo-Json -Depth 10
$premissasJson = Get-Content "$Root\dados\premissas.json" -Raw

$css = @'
:root { --bg:#fafafa; --fg:#1a1a1a; --muted:#666; --accent:#2c5282; --border:#ddd; --chart1:#2c5282; --chart2:#ed8936; --chart3:#48bb78; }
@media (prefers-color-scheme: dark) {
  :root { --bg:#1a1a1a; --fg:#e8e8e8; --muted:#999; --accent:#63b3ed; --border:#444; --chart1:#63b3ed; --chart2:#f6ad55; --chart3:#68d391; }
}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:var(--bg);color:var(--fg);line-height:1.7;padding:2rem 1rem}
.container{max-width:900px;margin:0 auto}
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

.chart-container{position:relative;height:300px;margin:1.5rem 0;background:var(--bg);border:1px solid var(--border);border-radius:6px;padding:1rem}
.chart-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1rem;margin:1.5rem 0}
.chart-box{border:1px solid var(--border);border-radius:6px;padding:1rem;background:var(--bg)}
.chart-box h4{color:var(--accent);font-size:1rem;margin-bottom:.5rem}

.simulador{background:var(--bg);border:2px solid var(--accent);border-radius:8px;padding:1.5rem;margin:2rem 0}
.simulador h3{margin-top:0}
.sim-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:1rem;margin:1rem 0}
.sim-grid label{display:block;font-size:.85rem;color:var(--muted);margin-bottom:.25rem}
.sim-grid input{width:100%;padding:.5rem;border:1px solid var(--border);border-radius:4px;background:var(--bg);color:var(--fg);font-size:.95rem}
.sim-grid input:focus{outline:none;border-color:var(--accent)}
.sim-result{background:rgba(44,82,130,.05);border-radius:6px;padding:1rem;margin-top:1rem}
.sim-result table{width:100%;border-collapse:collapse;font-size:.9rem}
.sim-result th,.sim-result td{padding:.5rem;text-align:left;border-bottom:1px solid var(--border)}
.sim-result th{color:var(--accent);font-weight:600}
.sim-result .num{font-family:monospace;text-align:right}

.valor-destaque{background:rgba(237,137,54,.1);color:var(--fg);padding:.1rem .4rem;border-radius:3px;font-weight:600}

@media print{
  body{background:#fff;color:#000}
  h2{color:#000;border-color:#999}
  .secao-divisor{border-color:#999}
  .simulador,.chart-container,.chart-box{display:none}
}
'@

$chartScript = @"
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script>
const serieStripe = $serieStripe;
const cenariosDet = $cenariosDet;

function initCharts() {
  // 1. Stripe Mensal: Charge vs Invoice
  const meses = serieStripe.map(d => d.mes);
  const charges = serieStripe.map(d => d.charge);
  const invoices = serieStripe.map(d => d.invoice);
  new Chart(document.getElementById('chart-stripe'), {
    type: 'line',
    data: {
      labels: meses,
      datasets: [
        { label: 'Charge', data: charges, borderColor: 'var(--chart1)', backgroundColor: 'var(--chart1)', tension: 0.3, pointRadius: 2 },
        { label: 'Invoice', data: invoices, borderColor: 'var(--chart2)', backgroundColor: 'var(--chart2)', tension: 0.3, pointRadius: 2 }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false, interaction: { mode: 'index', intersect: false }, plugins: { legend: { position: 'top' } }, scales: { y: { beginAtZero: true, ticks: { callback: v => 'R$ ' + (v/1000).toFixed(0) + 'k' } } } }
  });

  // 2. Cenarios 5 anos: Receita Reconhecida
  const anos = cenariosDet.baseline.map(d => d.ano);
  new Chart(document.getElementById('chart-cenarios-receita'), {
    type: 'bar',
    data: {
      labels: anos,
      datasets: [
        { label: 'Conservador', data: cenariosDet.conservador.map(d => d.receitaReconhecida), backgroundColor: 'var(--chart1)' },
        { label: 'Base', data: cenariosDet.baseline.map(d => d.receitaReconhecida), backgroundColor: 'var(--chart2)' },
        { label: 'Otimista', data: cenariosDet.otimista.map(d => d.receitaReconhecida), backgroundColor: 'var(--chart3)' }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' } }, scales: { y: { ticks: { callback: v => 'R$ ' + (v/1000000).toFixed(1) + 'M' } } } }
  });

  // 3. Receita Escondida vs Reconhecida (baseline)
  new Chart(document.getElementById('chart-escondida'), {
    type: 'bar',
    data: {
      labels: anos,
      datasets: [
        { label: 'Receita Reconhecida', data: cenariosDet.baseline.map(d => d.receitaReconhecida), backgroundColor: 'var(--chart1)' },
        { label: 'Receita Escondida', data: cenariosDet.baseline.map(d => d.receitaEscondida), backgroundColor: 'var(--chart2)' },
        { label: 'Receita Verdadeira', data: cenariosDet.baseline.map(d => d.receitaVerdadeira), backgroundColor: 'var(--chart3)', hidden: true }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' } }, scales: { y: { stacked: true, ticks: { callback: v => 'R$ ' + (v/1000000).toFixed(1) + 'M' } } } }
  });

  // 4. Margem: Reconhecida vs Verdadeira
  new Chart(document.getElementById('chart-margem'), {
    type: 'line',
    data: {
      labels: anos,
      datasets: [
        { label: 'Margem Reconhecida', data: cenariosDet.baseline.map(d => d.margem), borderColor: 'var(--chart1)', backgroundColor: 'var(--chart1)', tension: 0.3 },
        { label: 'Margem Verdadeira', data: cenariosDet.baseline.map(d => d.margemVerdadeira), borderColor: 'var(--chart3)', backgroundColor: 'var(--chart3)', tension: 0.3 }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'top' } }, scales: { y: { ticks: { callback: v => 'R$ ' + (v/1000000).toFixed(1) + 'M' } } } }
  });
}

document.addEventListener('DOMContentLoaded', initCharts);
</script>
"@

$simuladorHtml = @'
<section class="simulador" id="simulador">
<h3>Simulador Interativo</h3>
<p>Mude as premissas e veja o impacto em tempo real na receita e margem.</p>
<div class="sim-grid">
  <div><label for="sim-anuidade">Anuidade (R$)</label><input type="number" id="sim-anuidade" value="1200" step="50"></div>
  <div><label for="sim-novos">Novos entrantes/ano</label><input type="number" id="sim-novos" value="250" step="25"></div>
  <div><label for="sim-churn">Churn anual (%)</label><input type="number" id="sim-churn" value="3" step="0.5" min="0" max="50"></div>
  <div><label for="sim-desconto">Desconto pacote (%)</label><input type="number" id="sim-desconto" value="20" step="5" min="0" max="100"></div>
  <div><label for="sim-inadimplencia">Inadimplencia (%)</label><input type="number" id="sim-inadimplencia" value="8" step="1" min="0" max="100"></div>
  <div><label for="sim-anos">Anos de projecao</label><input type="number" id="sim-anos" value="5" step="1" min="1" max="10"></div>
</div>
<div class="sim-result">
  <table id="sim-tabela">
    <thead><tr><th>Ano</th><th class="num">Pontos</th><th class="num">Receita Rec.</th><th class="num">Receita Esc.</th><th class="num">Receita Verd.</th><th class="num">Margem Rec.</th><th class="num">Margem Verd.</th></tr></thead>
    <tbody></tbody>
  </table>
</div>
</section>
'@

$simuladorScript = @'
<script>
// Motor de calculo inline (copia pura)
function simular(p) {
  const resultados = [];
  let pontosAtivos = 3422;
  const coortes = [];
  for (let ano = 1; ano <= p.anos; ano++) {
    const preco = p.anuidade * Math.pow(1.05, ano - 1);
    const madura = Math.round(pontosAtivos * (1 - p.churn));
    const maduraPacote = Math.round(madura * p.adocao);
    const maduraRecorrente = madura - maduraPacote;
    const novos = p.novos;
    const novosPacote = (ano > 1) ? Math.round(novos * p.adocao) : 0;
    const novosRecorrente = novos - novosPacote;
    let caixaPacote = 0;
    if (ano === 1 && maduraPacote > 0) {
      caixaPacote = maduraPacote * preco * 3 * (1 - p.desconto);
      coortes.push({ pts: maduraPacote, anoIni: ano, totalContrato: caixaPacote, precoUnit: preco });
    }
    if (ano >= 2 && novosPacote > 0) {
      const caixaNovos = novosPacote * preco * 3 * (1 - p.desconto);
      caixaPacote += caixaNovos;
      coortes.push({ pts: novosPacote, anoIni: ano, totalContrato: caixaNovos, precoUnit: preco });
    }
    let receitaPacote = 0;
    for (const c of coortes) {
      const anosDecorridos = ano - c.anoIni;
      if (anosDecorridos >= 0 && anosDecorridos < 3) { receitaPacote += c.totalContrato / 3; }
    }
    const recMadura = maduraRecorrente * preco * (1 - p.desconto) * (1 - p.inadimplencia);
    const recNovos = (ano > 1) ? novosRecorrente * preco * (1 - p.desconto) * (1 - p.inadimplencia) : 0;
    const receitaRecorrente = recMadura + recNovos;
    const receitaReconhecida = receitaRecorrente + receitaPacote;
    const receitaEscondida = novos * preco;
    const receitaVerdadeira = receitaReconhecida + receitaEscondida;
    const custoVarTotal = 96 + 60;
    const custoVar = (madura + novos) * custoVarTotal;
    const custoTotal = 600000 + custoVar + 36000;
    const margem = receitaReconhecida - custoTotal;
    const margemVerdadeira = receitaVerdadeira - custoTotal;
    resultados.push({ ano: 2026 + ano - 1, totalPontos: madura + novos, receitaReconhecida, receitaEscondida, receitaVerdadeira, margem, margemVerdadeira });
    pontosAtivos = madura + novos;
  }
  return resultados;
}

function fmt(v) { return v.toLocaleString('pt-BR', { maximumFractionDigits: 0 }); }

function atualizarSimulador() {
  const p = {
    anuidade: parseFloat(document.getElementById('sim-anuidade').value),
    novos: parseInt(document.getElementById('sim-novos').value),
    churn: parseFloat(document.getElementById('sim-churn').value) / 100,
    desconto: parseFloat(document.getElementById('sim-desconto').value) / 100,
    inadimplencia: parseFloat(document.getElementById('sim-inadimplencia').value) / 100,
    adocao: 1.0,
    anos: parseInt(document.getElementById('sim-anos').value)
  };
  const resultados = simular(p);
  const tbody = document.querySelector('#sim-tabela tbody');
  tbody.innerHTML = resultados.map(r => 
    '<tr><td>' + r.ano + '</td><td class="num">' + fmt(r.totalPontos) + '</td><td class="num">R$ ' + fmt(r.receitaReconhecida) + '</td><td class="num">R$ ' + fmt(r.receitaEscondida) + '</td><td class="num">R$ ' + fmt(r.receitaVerdadeira) + '</td><td class="num">R$ ' + fmt(r.margem) + '</td><td class="num">R$ ' + fmt(r.margemVerdadeira) + '</td></tr>'
  ).join('');
}

document.querySelectorAll('.sim-grid input').forEach(input => {
  input.addEventListener('input', atualizarSimulador);
});
atualizarSimulador();
</script>
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

<section id="dashboard">
<h2>Dashboard Visual</h2>
<div class="chart-grid">
  <div class="chart-box">
    <h4>Stripe Mensal: Charge vs Invoice</h4>
    <div class="chart-container"><canvas id="chart-stripe"></canvas></div>
  </div>
  <div class="chart-box">
    <h4>Cenarios 5 Anos: Receita Reconhecida</h4>
    <div class="chart-container"><canvas id="chart-cenarios-receita"></canvas></div>
  </div>
  <div class="chart-box">
    <h4>Receita Escondida vs Reconhecida (Base)</h4>
    <div class="chart-container"><canvas id="chart-escondida"></canvas></div>
  </div>
  <div class="chart-box">
    <h4>Margem: Reconhecida vs Verdadeira</h4>
    <div class="chart-container"><canvas id="chart-margem"></canvas></div>
  </div>
</div>
</section>

$simuladorHtml

$html

</div>
$chartScript
$simuladorScript
</body>
</html>
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$Root\dist\index.html", $pagina, $utf8NoBom)

Write-Output ""
Write-Output "OK dist/index.html gerado com graficos e simulador."
Write-Output "  Tamanho: $([Math]::Round((Get-Item "$Root\dist\index.html").Length / 1024, 1)) KB"
