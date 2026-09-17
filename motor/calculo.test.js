/**
 * Testes do Motor de Cálculo — Irricontrol ONE Receita
 * Regra: teste vermelho = build falha = nada é publicado
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { pathToFileURL } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');

// Carregar dados
const premissas = JSON.parse(fs.readFileSync(path.join(root, 'dados', 'premissas.json'), 'utf8'));
const base = JSON.parse(fs.readFileSync(path.join(root, 'dados', 'base-dispositivos.json'), 'utf8'));
const pricing = JSON.parse(fs.readFileSync(path.join(root, 'dados', 'pricing-global.json'), 'utf8'));

// Importar motor
const { default: Calculo } = await import(pathToFileURL(path.join(root, 'motor', 'calculo.js')).href);
const {
  calcularEscopoPotencial,
  calcularReceitaReconhecida,
  calcularPricingComparado,
  calcularProjecaoCenarios
} = Calculo;

let pass = 0;
let fail = 0;

function assert(name, actual, expected, tolerance = 0.01) {
  const ok = Math.abs(actual - expected) <= tolerance;
  if (ok) {
    pass++;
    console.log(`  PASS: ${name} = ${actual} (esperado: ${expected})`);
  } else {
    fail++;
    console.error(`  FAIL: ${name} = ${actual} (esperado: ${expected})`);
  }
  return ok;
}

function assertEquals(name, actual, expected) {
  const ok = actual === expected;
  if (ok) {
    pass++;
    console.log(`  PASS: ${name}`);
  } else {
    fail++;
    console.error(`  FAIL: ${name} = "${actual}" (esperado: "${expected}")`);
  }
  return ok;
}

console.log('=== TESTES DO MOTOR ===\n');

// 1. Escopo e Potencial
console.log('1. Escopo e Potencial:');
const baseComStripe = { ...base, charge2025: 2008247.07 };
const escopo = calcularEscopoPotencial(premissas, baseComStripe);
assert('Total de pontos no escopo', escopo.totalEscopo, 4822);
assert('Potencial anual, escopo completo', escopo.potencialCompleto, 5396400);
assert('Coletado, escopo completo', escopo.receitaRecorrenteHoje, 3777888);
assert('Gap anual, escopo completo', escopo.gapCompleto, 1618512);
assert('Taxa de realização, escopo completo', escopo.realizacaoCompleto * 100, 70.00, 0.5);
assert('Potencial anual, escopo histórico pivôs', escopo.potencialHistorico, 4616400);
assert('Taxa de realização 2025, escopo histórico', escopo.realizacaoHistorico * 100, 43.50, 0.5);
assertEquals('Escopo histórico nomeado', escopo.escopoHistoricoPivos.totalPontos, 3847);
assertEquals('Escopo completo nomeado', escopo.escopoCompleto.totalPontos, 4822);

// 2. Receita Reconhecida
console.log('\n2. Receita Reconhecida (adoção 100%/100%):');
const resultado = calcularReceitaReconhecida(premissas, {
  baseInicial: base.pontosPagantes,
  novosEntrantes: premissas.novosEntrantesAno,
  adocaoMadura: premissas.adocaoPacoteMadura,
  adocaoNovos: premissas.adocaoPacoteNovos,
  anosProjecao: 5
});

const ano2026 = resultado.anos[0];
assert('Receita reconhecida 2026', ano2026.receitaReconhecida, 3186240, 1);
assert('Custo total 2026', ano2026.custoTotal, 1192764, 1);
assert('Margem contábil 2026', ano2026.margem, 1993476, 1);
assert('Custo total 2027 com inflação', resultado.anos[1].custoTotal, 1275825.6, 1);

// 3. Asserções estruturais
console.log('\n3. Asserções estruturais:');

// Primeiro ano grátis: novos entrantes do ano 1 não geram receita reconhecida
const primeiroAno = resultado.anos[0];
assertEquals('Primeiro ano: novos entrantes não geram receita reconhecida', primeiroAno.receitaRecorrente === primeiroAno.maduraRecorrente * primeiroAno.preco * (1 - premissas.descontoPacote) * (1 - premissas.inadimplencia), true);
assert('Primeiro ano: receita escondida = novos * preco', primeiroAno.receitaEscondida, primeiroAno.novos * primeiroAno.preco, 0.01);
assert('Primeiro ano: receita verdadeira = reconhecida + escondida', primeiroAno.receitaVerdadeira, primeiroAno.receitaReconhecida + primeiroAno.receitaEscondida, 0.01);
assertEquals('Primeiro ano: margem verdadeira > margem reconhecida', primeiroAno.margemVerdadeira > primeiroAno.margem, true);

// Nenhum ano com receita zero (exceto se primeiroAnoGratis=true e baseInicial=0 — não é o caso)
const anosComReceitaZero = resultado.anos.filter(a => a.receitaReconhecida === 0);
assertEquals('Nenhum ano com receita reconhecida = 0', anosComReceitaZero.length, 0);

// Soma das receitas reconhecidas de uma coorte = caixa total
if (resultado.coortes.length > 0) {
  const primeiraCoorte = resultado.coortes[0];
  const anosCoorte = Math.min(premissas.anosPacote, resultado.anos.length - primeiraCoorte.anoIni + 1);
  const somaReceitas = anosCoorte * primeiraCoorte.totalContrato / premissas.anosPacote;
  assert('Soma receitas coorte = caixa total', somaReceitas, primeiraCoorte.totalContrato, 0.01);
}

// 3.5. Projeção de cenários (nomes atualizados)
console.log('\n3.5. Projeção de cenários:');
const cenarios = calcularProjecaoCenarios(premissas, base);
assertEquals('Cenário conservador existe', !!cenarios.conservador, true);
assertEquals('Cenário baseline existe', !!cenarios.baseline, true);
assertEquals('Cenário otimista existe', !!cenarios.otimista, true);
assertEquals('Conservador < baseline (receita 2030)', cenarios.conservador.anos[4].receitaReconhecida < cenarios.baseline.anos[4].receitaReconhecida, true);
assertEquals('Baseline < otimista (receita 2030)', cenarios.baseline.anos[4].receitaReconhecida < cenarios.otimista.anos[4].receitaReconhecida, true);

// 4. Pricing Comparado
console.log('\n4. Pricing Comparado:');
const pricingComp = calcularPricingComparado(premissas, pricing);
assert('R$1.200 convertido a USD', pricingComp.precoUSD, 210.53, 0.01);
assertEquals('Tier correspondente', pricingComp.tierCorrespondente ? pricingComp.tierCorrespondente.tier : null, '11-20');

// 5. Série Stripe (soma por ano)
console.log('\n5. Série Stripe:');
const csv = fs.readFileSync(path.join(root, 'dados', 'stripe-mensal.csv'), 'utf8');
const linhas = csv.trim().split('\n').slice(1);
const totais = {};
for (const linha of linhas) {
  const [mes, currency, charge, invoice] = linha.split(',');
  const ano = mes.split('-')[0];
  if (!totais[ano]) totais[ano] = { charge: 0, invoice: 0 };
  if (charge !== '' && charge !== 'null') totais[ano].charge += parseFloat(charge);
  if (invoice !== '' && invoice !== 'null') totais[ano].invoice += parseFloat(invoice);
}

assert('Soma charge 2025', totais['2025'].charge, 2008247.07, 0.01);
assert('Soma invoice 2025', totais['2025'].invoice, 4426942.48, 0.01);
assert('Soma charge 2026 (jan-ago)', totais['2026'].charge, 1227998.31, 0.01);

// Resumo
console.log('\n=== RESUMO ===');
console.log(`PASS: ${pass}`);
console.log(`FAIL: ${fail}`);

if (fail > 0) {
  console.error('\nBUILD FALHOU. Corrija os testes antes de prosseguir.');
  process.exit(1);
} else {
  console.log('\nTodos os testes passaram.');
  process.exit(0);
}
