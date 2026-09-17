import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import Calculo from '../motor/calculo.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const readJson = (file) => JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
const premissas = readJson('dados/premissas.json');
const base = readJson('dados/base-dispositivos.json');
const pricing = readJson('dados/pricing-global.json');

function parseCsv(file) {
  const lines = fs.readFileSync(path.join(root, file), 'utf8').trim().split(/\r?\n/);
  const headers = lines.shift().split(',');
  return lines.filter(Boolean).map((line) => {
    const values = line.split(',');
    return Object.fromEntries(headers.map((header, index) => [header, values[index] ?? null]));
  });
}

function number(value) {
  return value === '' || value === null || value === 'null' ? null : Number(value);
}

const stripe = parseCsv('dados/stripe-mensal.csv').map((row) => ({
  mes: row.month ?? row.mes,
  currency: row.currency ?? 'brl',
  charge: number(row.charge),
  invoice: number(row.invoice)
}));
const stripeAnual = {};
for (const row of stripe) {
  const year = row.mes.slice(0, 4);
  stripeAnual[year] ??= { charge: 0, invoice: 0 };
  if (row.charge !== null) stripeAnual[year].charge += row.charge;
  if (row.invoice !== null) stripeAnual[year].invoice += row.invoice;
}
const byMonth = Object.fromEntries(stripe.map((row) => [row.mes, row]));

const escopo = Calculo.calcularEscopoPotencial(premissas, base);
const cenarios = Calculo.calcularProjecaoCenarios(premissas, base);
const pricingComp = Calculo.calcularPricingComparado(premissas, pricing);
const directDiscounts = pricing.clienteDireto.map((tier) => 1 - tier.ano3ef / tier.ano1);
const maxDiscount = Math.max(...directDiscounts);
const baseline = cenarios.baseline.anos;
const round = (value) => Math.round(value);
const sum = (values) => values.reduce((total, value) => total + (value ?? 0), 0);
const charge2025 = stripeAnual['2025'].charge;
const invoice2025 = stripeAnual['2025'].invoice;
const potentialNewProducts = base.pontosPagantes * (premissas.precoNovoProduto * premissas.adocaoNovoProduto * 2);

const derivados = {
  anoBase: premissas.anoBase,
  dataCorte: base.dataCorte,
  totalPivos: escopo.totalPivos,
  totalIrripump: escopo.totalIrripump,
  totalMedidor: escopo.totalMedidor,
  totalEscopo: escopo.totalEscopo,
  usuariosAtivos: base.usuariosAtivos,
  fazendas: base.fazendas,
  pontosPagantes: base.pontosPagantes,
  anuidadeRef: premissas.anuidadeRef,
  anuidadeIrripump: premissas.anuidadeIrripump,
  anuidadeMedidorNivel: premissas.anuidadeMedidorNivel,
  precoTabelaSaaS: premissas.precoTabelaSaaS,
  precoAlvoSaaS: premissas.precoAlvoSaaS,
  potencialHistorico: escopo.potencialHistorico,
  potencialIrripump: escopo.potencialIrripump,
  potencialMedidor: escopo.potencialMedidor,
  potencialCompleto: escopo.potencialCompleto,
  precoMedioEscopo: escopo.precoMedioEscopo,
  receitaRecorrenteHoje: escopo.receitaRecorrenteHoje,
  gapHistorico: escopo.gapHistorico,
  gapCompleto: escopo.gapCompleto,
  realizacaoHistorico: round(escopo.realizacaoHistorico * 100),
  realizacaoCompleto: round(escopo.realizacaoCompleto * 100),
  charge2025,
  invoice2025,
  charge2026: stripeAnual['2026'].charge,
  invoice2026: stripeAnual['2026'].invoice,
  receita2025: charge2025,
  realizacao2025: round(charge2025 / escopo.potencialHistorico * 100),
  chargeAbr2024: byMonth['2024-04']?.charge,
  invoiceAbr2024: byMonth['2024-04']?.invoice,
  chargeMai2024: byMonth['2024-05']?.charge,
  invoiceMai2024: byMonth['2024-05']?.invoice,
  chargeOut2024: byMonth['2024-10']?.charge,
  invoiceOut2024: byMonth['2024-10']?.invoice,
  invoiceAgo2023: byMonth['2023-08']?.invoice,
  chargeQ12024: sum(['2024-01', '2024-02', '2024-03'].map((month) => byMonth[month]?.charge)),
  gapOut2024: (byMonth['2024-10']?.invoice ?? 0) - (byMonth['2024-10']?.charge ?? 0),
  diferenca2025: invoice2025 - charge2025,
  cambioUSDBRL: premissas.cambioUSDBRL,
  precoUSD: pricingComp.precoUSD,
  tierCorrespondente: pricingComp.tierCorrespondente?.tier ?? 'N/A',
  tierMin: pricingComp.tierCorrespondente?.ano3ef ?? 0,
  tierMax: pricingComp.tierCorrespondente?.ano1 ?? 0,
  dealerMin: pricingComp.dealerMin,
  dealerMax: pricingComp.dealerMax,
  descontoMax: maxDiscount,
  descontoPacote: premissas.descontoPacote,
  precoEfetivo: premissas.anuidadeRef * (1 - premissas.descontoPacote),
  spreadDiretoDealer: pricingComp.tierCorrespondente ? pricingComp.tierCorrespondente.ano1 - pricingComp.dealerMax : 0,
  spreadDiretoDealerMax: pricingComp.tierCorrespondente ? pricingComp.tierCorrespondente.ano3ef - pricingComp.dealerMin : 0,
  spreadBrasil: premissas.anuidadeRef * premissas.descontoPacote,
  precoSAF: pricing.safSystem.preco,
  volumeTotal: round(charge2025 + stripeAnual['2026'].charge),
  novosEntrantesAno: premissas.novosEntrantesAno,
  novosEntrantesConservador: premissas.novosEntrantesConservador,
  novosEntrantesOtimista: premissas.novosEntrantesOtimista,
  adocaoPacoteMadura: premissas.adocaoPacoteMadura,
  adocaoPacoteBaixa: premissas.adocaoPacoteBaixa,
  churnAno: premissas.churnAno,
  inadimplencia: premissas.inadimplencia,
  receitaA2030: round(cenarios.conservador.anos.at(-1).receitaReconhecida),
  margemA2030: round(cenarios.conservador.anos.at(-1).margem),
  receitaB2030: round(cenarios.baseline.anos.at(-1).receitaReconhecida),
  margemB2030: round(cenarios.baseline.anos.at(-1).margem),
  receitaC2030: round(cenarios.otimista.anos.at(-1).receitaReconhecida),
  margemC2030: round(cenarios.otimista.anos.at(-1).margem),
  receitaEscondidaAnoBase: round(baseline[0].receitaEscondida),
  receitaEscondidaAcumuladaBase: round(sum(baseline.map((year) => year.receitaEscondida))),
  precoNovoProduto: premissas.precoNovoProduto,
  adocaoNovoProduto: premissas.adocaoNovoProduto,
  arpuAtual: premissas.anuidadeRef,
  arpuNovo: premissas.anuidadeRef + premissas.precoNovoProduto * premissas.adocaoNovoProduto * 2,
  arrAtual: base.pontosPagantes * premissas.anuidadeRef,
  arrNovo: base.pontosPagantes * premissas.anuidadeRef + potentialNewProducts,
  arpuFazenda: base.pontosPagantes * premissas.anuidadeRef / base.fazendas,
  projecaoClientes: round(base.pontosPagantes * Math.pow(1.05, 5)),
  receitaPropria: round(charge2025 * 0.7),
  passThrough: round(charge2025 * 0.3),
  serieStripe: stripe,
  cenariosDetalhado: Object.fromEntries(Object.entries(cenarios).map(([name, scenario]) => [name, scenario.anos.map((year) => ({
    ano: year.ano,
    receitaReconhecida: round(year.receitaReconhecida),
    receitaEscondida: round(year.receitaEscondida),
    receitaVerdadeira: round(year.receitaVerdadeira),
    margem: round(year.margem),
    margemVerdadeira: round(year.margemVerdadeira),
    totalPontos: year.totalPontos,
    novos: year.novos
  }))]))
};

fs.mkdirSync(path.join(root, 'dist'), { recursive: true });
fs.writeFileSync(path.join(root, 'dist', 'derivados.json'), `${JSON.stringify(derivados, null, 2)}\n`, 'utf8');
console.log(`OK: ${Object.keys(derivados).length} chaves derivadas`);
