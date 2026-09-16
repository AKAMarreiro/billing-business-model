/**
 * Testes do Motor de Cálculo — Irricontrol ONE Receita
 * Regra: teste vermelho = build falha = nada é publicado
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');

// Carregar dados
const premissas = JSON.parse(fs.readFileSync(path.join(root, 'dados', 'premissas.json'), 'utf8'));
const base = JSON.parse(fs.readFileSync(path.join(root, 'dados', 'base-dispositivos.json'), 'utf8'));
const pricing = JSON.parse(fs.readFileSync(path.join(root, 'dados', 'pricing-global.json'), 'utf8'));

// Importar motor
const { default: Calculo } = await import(path.join(root, 'motor', 'calculo.js'));
const {
  calcularEscopoPotencial,
  calcularReceitaReconhecida,
  calcularPricingComparado
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
const escopo = calcularEscopoPotencial(premissas, base);
assert('Total de pontos no escopo', escopo.totalEscopo, 4822);
assert('Potencial anual, escopo completo', escopo.potencialCompleto, 5786400);
assert('Coletado, escopo completo', escopo.receitaRecorrenteHoje, 3777888);
assert('Gap anual, escopo completo', escopo.gapCompleto, 2008512);
assert('Taxa de realização, escopo completo', escopo.realizacaoCompleto * 100, 65.29, 0.5);
assert('Potencial anual, escopo histórico pivôs', escopo.potencialHistorico, 4616400);

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
assert('Receita reconhecida 2026', ano2026.receitaReconhecida, 4489920, 1);
assert('Custo total 2026', ano2026.custoTotal, 1404612, 1);
assert('Margem contábil 2026', ano2026.margem, 3085308, 1);

// 3. Asserções estruturais
console.log('\n3. Asserções estruturais:');

// Nenhum ano com receita zero
const anosComReceitaZero = resultado.anos.filter(a => a.receitaReconhecida === 0);
assertEquals('Nenhum ano com receita reconhecida = 0', anosComReceitaZero.length, 0);

// Soma das receitas reconhecidas de uma coorte = caixa total
if (resultado.coortes.length > 0) {
  const primeiraCoorte = resultado.coortes[0];
  const anosCoorte = resultado.anos.filter(a => {
    const anoRelativo = a.ano - premissas.anoBase + 1;
    return anoRelativo >= primeiraCoorte.anoIni && anoRelativo < primeiraCoorte.anoIni + premissas.anosPacote;
  });
  const somaReceitas = anosCoorte.reduce((s, a) => s + a.receitaPacote, 0);
  assert('Soma receitas coorte = caixa total', somaReceitas, primeiraCoorte.totalContrato, 0.01);
}

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
  const [mes, charge, invoice] = linha.split(',');
  const ano = mes.split('-')[0];
  if (!totais[ano]) totais[ano] = { charge: 0, invoice: 0 };
  if (charge !== '' && charge !== 'null') totais[ano].charge += parseFloat(charge);
  if (invoice !== '' && invoice !== 'null') totais[ano].invoice += parseFloat(invoice);
}

assert('Soma charge 2025', totais['2025'].charge, 2010247, 100);
assert('Soma invoice 2025', totais['2025'].invoice, 4425942, 100);
assert('Soma charge 2026 (jan-ago)', totais['2026'].charge, 1820000, 100);

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
