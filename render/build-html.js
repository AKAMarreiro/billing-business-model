import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const derivados = JSON.parse(fs.readFileSync(path.join(root, 'dist/derivados.json'), 'utf8'));
const motor = fs.readFileSync(path.join(root, 'motor/calculo.js'), 'utf8')
  .replace(/export default Calculo;\s*/g, '')
  .replace(/export \{[\s\S]*?\};\s*/g, '');
const premissas = JSON.parse(fs.readFileSync(path.join(root, 'dados/premissas.json'), 'utf8'));

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[char]));
}
function format(value) {
  if (typeof value !== 'number') return escapeHtml(value);
  return new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 2 }).format(value);
}
function renderMarkdown(markdown) {
  return markdown
    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
    .replace(/^\*\*([^\n]+)\*\*$/gm, '<p class="lead"><strong>$1</strong></p>')
    .replace(/^\*\*([^*]+)\*\*/gm, '<strong>$1</strong>')
    .replace(/\n\n/g, '</p><p>')
    .split(/---/).map((section) => `<section class="narrative"><p>${section.trim()}</p></section>`).join('<hr>');
}
const narrative = fs.readdirSync(path.join(root, 'narrativa')).sort().map((file) => fs.readFileSync(path.join(root, 'narrativa', file), 'utf8')).join('\n\n---\n\n')
  .replace(/\{\{(\w+)(?:\|\w+)?\}\}/g, (_, key) => derivados[key] === undefined ? `{{${key}}}` : format(derivados[key]));
const scenarios = JSON.stringify(derivados.cenariosDetalhado);
const stripe = JSON.stringify(derivados.serieStripe);
const motorJson = JSON.stringify(motor);
const premissasJson = JSON.stringify(premissas);

const page = `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Irricontrol ONE | Modelo de Receita</title>
<style>
:root{--verde:#55B93C;--azul:#0092D6;--cinza:#505050;--branco:#fff;--fundo:#f3f6f4;--texto:#24302b;--borda:#d6dfda;--vermelho:#b43b3b}
[data-theme="dark"]{--fundo:#17201c;--texto:#eef5f0;--cinza:#b4c2ba;--branco:#202b25;--borda:#3b4a41}
*{box-sizing:border-box}body{margin:0;background:var(--fundo);color:var(--texto);font:16px/1.65 Georgia,serif}main{max-width:1040px;margin:auto;padding:28px 20px 80px}header{border-bottom:4px solid var(--verde);padding:20px 0 18px;display:flex;justify-content:space-between;gap:20px;align-items:end}h1,h2,h3{font-family:"Trebuchet MS",sans-serif;line-height:1.15}h1{color:var(--azul);font-size:clamp(2rem,5vw,3.6rem);margin:0}h2{color:var(--azul);border-bottom:1px solid var(--borda);padding-bottom:8px;margin-top:40px}h3{color:var(--cinza)}p{max-width:82ch}.controls{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.controls button,.controls select{border:1px solid var(--borda);background:var(--branco);color:var(--texto);padding:8px 10px;border-radius:4px}.hero{display:grid;grid-template-columns:1.3fr .7fr;gap:20px;align-items:stretch}.hero-panel,.tool{background:var(--branco);border:1px solid var(--borda);padding:20px;border-radius:6px}.metric{font-family:"Trebuchet MS",sans-serif;font-size:1.8rem;color:var(--verde);font-weight:700}.metric-label{color:var(--cinza);font-size:.9rem}.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}.chart{width:100%;height:210px;background:var(--branco);border:1px solid var(--borda);border-radius:6px}.chart text{font:12px "Trebuchet MS",sans-serif;fill:var(--texto)}.chart .bar{fill:var(--azul)}.chart .bar.secondary{fill:var(--verde)}.timeline{border-left:3px solid var(--verde);padding-left:20px}.timeline p{margin:14px 0}.narrative{max-width:900px}.narrative p{margin:0 0 1em}.lead{font-size:1.15rem}.sim-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:10px}.sim-grid label{font:13px "Trebuchet MS",sans-serif;color:var(--cinza)}.sim-grid input{display:block;width:100%;padding:8px;background:var(--fundo);border:1px solid var(--borda);color:var(--texto)}table{width:100%;border-collapse:collapse;font-family:"Trebuchet MS",sans-serif;font-size:.9rem}th,td{text-align:right;padding:8px;border-bottom:1px solid var(--borda)}th:first-child,td:first-child{text-align:left}@media(max-width:720px){header,.hero{display:block}.grid{grid-template-columns:repeat(2,1fr)}.sim-grid{grid-template-columns:repeat(2,1fr)}}
</style>
</head>
<body>
<main>
<header><div><div class="metric-label" data-i18n="eyebrow">MODELO DE DADOS | CORTE ${escapeHtml(derivados.dataCorte)}</div><h1>Irricontrol ONE</h1><div class="metric-label" data-i18n="subtitle">Receita de assinatura, mecanismo comercial e tese SaaS</div></div><div class="controls"><select id="language" aria-label="Idioma"><option value="pt">PT</option><option value="en">EN</option><option value="es">ES</option><option value="de">DE</option></select><button id="theme" type="button" data-i18n="theme">Tema</button></div></header>
<section class="hero"><div class="hero-panel"><h2 data-i18n="starting">Ponto de partida</h2><p data-i18n="scope">O escopo completo combina pivôs, Irripumps e medidores com preço próprio por produto. A tese histórica permanece separada da tese prospectiva.</p><div class="grid"><div><div class="metric">${format(derivados.potencialHistorico)}</div><div class="metric-label">Potencial histórico</div></div><div><div class="metric">${format(derivados.potencialCompleto)}</div><div class="metric-label">Potencial prospectivo</div></div><div><div class="metric">${format(derivados.receita2025)}</div><div class="metric-label">Charge 2025</div></div><div><div class="metric">${format(derivados.realizacao2025)}%</div><div class="metric-label">Realização histórica</div></div></div></div><div class="hero-panel"><h2 data-i18n="decision">Decisão protegida</h2><p data-i18n="decisionText">SaaS é produto de receita própria. Hardware, retenção e novos módulos não podem transformar a anuidade em moeda de negociação.</p><div class="metric">${format(derivados.gapCompleto)}</div><div class="metric-label">Gap prospectivo</div></div></section>
<section><h2 data-i18n="charts">Leitura executiva</h2><div class="grid"><svg class="chart" viewBox="0 0 400 210" role="img" aria-label="Potencial por produto"><text x="16" y="24">Potencial por produto</text><rect class="bar" x="20" y="50" width="260" height="28"/><text x="290" y="70">Pivôs ${format(derivados.potencialHistorico)}</text><rect class="bar secondary" x="20" y="94" width="36" height="28"/><text x="65" y="114">Irripump ${format(derivados.potencialIrripump)}</text><rect class="bar secondary" x="20" y="138" width="36" height="28"/><text x="65" y="158">Medidor ${format(derivados.potencialMedidor)}</text></svg><svg class="chart" viewBox="0 0 400 210" role="img" aria-label="Receita reconhecida"><text x="16" y="24">Receita reconhecida</text>${derivados.cenariosDetalhado.baseline.map((row, index) => `<text x="18" y="${55 + index * 28}">${row.ano}</text><rect class="bar" x="60" y="${42 + index * 28}" width="${Math.max(8, Math.min(290, row.receitaReconhecida / 20000))}" height="18"/><text x="${70 + Math.max(8, Math.min(290, row.receitaReconhecida / 20000))}" y="${56 + index * 28}">${format(row.receitaReconhecida)}</text>`).join('')}</svg></div></section>
<section><h2 data-i18n="timelineTitle">Timeline da tese</h2><div class="timeline"><p><strong>2023–2024</strong> | Ativação, primeiros invoices e inflexão operacional.</p><p><strong>2024–2025</strong> | Pacotes plurianuais expõem a diferença entre invoice, charge e receita reconhecida.</p><p><strong>2026</strong> | A janela de lançamento exige preço próprio para SaaS, monitoramento e manejo.</p></div></section>
<section class="tool"><h2 data-i18n="simulator">Simulador com o mesmo motor</h2><div class="sim-grid"><label>Base inicial<input id="base" type="number" value="${derivados.pontosPagantes}"></label><label>Entrantes/ano<input id="new" type="number" value="${premissas.novosEntrantesAno}"></label><label>Adoção pacote<input id="adoption" type="number" value="100" min="0" max="100"></label><label>Anos<input id="years" type="number" value="5" min="1" max="10"></label></div><table><thead><tr><th>Ano</th><th>Receita com pacote</th><th>Receita sem pacote</th><th>Margem</th></tr></thead><tbody id="sim-output"></tbody></table></section>
<section><h2 data-i18n="narrative">Narrativa</h2>${renderMarkdown(narrative)}</section>
</main>
<script>
const MOTOR_SOURCE=${motorJson};
eval(MOTOR_SOURCE);
const PREMISSAS=${premissasJson};
const STRIPE=${stripe};
const SCENARIOS=${scenarios};
const labels={pt:{eyebrow:'MODELO DE DADOS',subtitle:'Receita de assinatura, mecanismo comercial e tese SaaS',starting:'Ponto de partida',scope:'O escopo completo combina pivôs, Irripumps e medidores com preço próprio por produto. A tese histórica permanece separada da tese prospectiva.',decision:'Decisão protegida',decisionText:'SaaS é produto de receita própria. Hardware, retenção e novos módulos não podem transformar a anuidade em moeda de negociação.',charts:'Leitura executiva',timelineTitle:'Timeline da tese',simulator:'Simulador com o mesmo motor',narrative:'Narrativa',theme:'Tema'},en:{eyebrow:'DATA MODEL',subtitle:'Subscription revenue, commercial mechanism and SaaS thesis',starting:'Starting point',scope:'The full scope combines pivots, Irripumps and level meters, each with its own price.',decision:'Protected decision',decisionText:'SaaS is a revenue product. Hardware and retention cannot turn the subscription into a bargaining chip.',charts:'Executive reading',timelineTitle:'Thesis timeline',simulator:'Simulator using the same engine',narrative:'Narrative',theme:'Theme'},es:{eyebrow:'MODELO DE DATOS',subtitle:'Ingresos de suscripcion, mecanismo comercial y tesis SaaS',starting:'Punto de partida',scope:'El alcance completo combina pivotes, Irripumps y medidores con precio propio.',decision:'Decision protegida',decisionText:'SaaS es un producto de ingresos y no una moneda de negociacion.',charts:'Lectura ejecutiva',timelineTitle:'Linea de tiempo',simulator:'Simulador con el mismo motor',narrative:'Narrativa',theme:'Tema'},de:{eyebrow:'DATENMODELL',subtitle:'Subscription-Umsatz, Vertriebsmechanismus und SaaS-These',starting:'Ausgangspunkt',scope:'Der vollstaendige Umfang kombiniert Pivot, Irripump und Pegelmesser mit eigenen Preisen.',decision:'Geschuetzte Entscheidung',decisionText:'SaaS ist ein eigenes Umsatzprodukt und darf nicht als Verhandlungswaehrung dienen.',charts:'Managementsicht',timelineTitle:'Zeitlinie',simulator:'Simulator mit derselben Engine',narrative:'Narrative',theme:'Thema'}};
function updateLanguage(){const lang=labels[document.querySelector('#language').value];document.querySelectorAll('[data-i18n]').forEach(el=>{if(lang[el.dataset.i18n])el.textContent=lang[el.dataset.i18n]});localStorage.setItem('irricontrol-language',document.querySelector('#language').value)}
function updateSimulator(){const params={baseInicial:Number(document.querySelector('#base').value),novosEntrantes:Number(document.querySelector('#new').value),adocaoMadura:Number(document.querySelector('#adoption').value)/100,adocaoNovos:Number(document.querySelector('#adoption').value)/100,anosProjecao:Number(document.querySelector('#years').value)};const result=Calculo.simular(PREMISSAS,params);document.querySelector('#sim-output').innerHTML=result.comPacote.anos.map((row,index)=>'<tr><td>'+row.ano+'</td><td>'+Math.round(row.receitaReconhecida).toLocaleString('pt-BR')+'</td><td>'+Math.round(result.semPacote.anos[index].receitaReconhecida).toLocaleString('pt-BR')+'</td><td>'+Math.round(row.margem).toLocaleString('pt-BR')+'</td></tr>').join('')}
const storedLanguage=localStorage.getItem('irricontrol-language');if(storedLanguage)document.querySelector('#language').value=storedLanguage;document.querySelector('#language').addEventListener('change',updateLanguage);document.querySelector('#theme').addEventListener('click',()=>{document.documentElement.dataset.theme=document.documentElement.dataset.theme==='dark'?'light':'dark';localStorage.setItem('irricontrol-theme',document.documentElement.dataset.theme)});const storedTheme=localStorage.getItem('irricontrol-theme');if(storedTheme)document.documentElement.dataset.theme=storedTheme;document.querySelectorAll('input').forEach(input=>input.addEventListener('input',updateSimulator));updateLanguage();updateSimulator();
</script>
</body></html>`;
fs.writeFileSync(path.join(root, 'dist/index.html'), page, 'utf8');
console.log('OK: dist/index.html gerado');
