/**
 * Motor de Cálculo — Irricontrol ONE Receita
 * Funções puras. Zero I/O. Entra objeto, sai objeto.
 * Exporta para Node (ESM) e browser (global).
 */

// ============================================
// ESCOPO E POTENCIAL
// ============================================

function calcularEscopoPotencial(premissas, base) {
  const totalPivos = base.pivos.efetivos;
  const totalIrripump = base.irripump;
  const totalMedidor = base.medidorNivel;
  const totalEscopo = totalPivos + totalIrripump + totalMedidor;

  const potencialHistorico = totalPivos * premissas.anuidadeRef;
  const potencialCompleto = totalEscopo * premissas.anuidadeRef;

  const receitaRecorrenteHoje = base.pontosPagantes * premissas.anuidadeRef * (1 - premissas.inadimplencia);

  const gapHistorico = potencialHistorico - (totalPivos * premissas.anuidadeRef * (base.pontosPagantes / totalPivos));
  const gapCompleto = potencialCompleto - receitaRecorrenteHoje;

  const realizacaoHistorico = (base.pontosPagantes * premissas.anuidadeRef) / potencialHistorico;
  const realizacaoCompleto = receitaRecorrenteHoje / potencialCompleto;

  return {
    totalPivos,
    totalIrripump,
    totalMedidor,
    totalEscopo,
    potencialHistorico,
    potencialCompleto,
    receitaRecorrenteHoje,
    gapHistorico,
    gapCompleto,
    realizacaoHistorico,
    realizacaoCompleto
  };
}

// ============================================
// CUSTOS
// ============================================

function calcularCusto(premissas, totalPontos, ano = 1) {
  const custoVarTotal = premissas.custoVarPontoInfra + premissas.custoVarPontoSuporte;
  const custoVar = totalPontos * custoVarTotal;
  const custoFixo = premissas.custoFixoPlataforma;
  const custoOperacao = premissas.custoOperacaoBilling;
  const custoTotal = custoFixo + custoVar + custoOperacao;
  return {
    custoFixo,
    custoVar,
    custoOperacao,
    custoTotal
  };
}

// ============================================
// RECONHECIMENTO DE RECEITA (DEFERRED REVENUE)
// ============================================

function calcularReceitaReconhecida(premissas, config) {
  const {
    baseInicial,
    novosEntrantes,
    adocaoMadura,
    adocaoNovos,
    anosProjecao = 5
  } = config;

  const resultados = [];
  let pontosAtivos = baseInicial;
  const coortes = [];

  for (let ano = 1; ano <= anosProjecao; ano++) {
    const preco = premissas.anuidadeRef * Math.pow(1 + premissas.reajusteAno, ano - 1);

    // Carteira madura com churn
    const madura = Math.round(pontosAtivos * (1 - premissas.churnAno));
    const maduraPacote = Math.round(madura * adocaoMadura);
    const maduraRecorrente = madura - maduraPacote;

    // Novos entrantes
    const novos = novosEntrantes;
    const novosPacote = (ano > 1) ? Math.round(novos * adocaoNovos) : 0;
    const novosRecorrente = novos - novosPacote;

    // Caixa de pacotes (recebido à vista)
    let caixaPacote = 0;
    if (ano === 1 && maduraPacote > 0) {
      caixaPacote = maduraPacote * preco * premissas.anosPacote * (1 - premissas.descontoPacote);
      coortes.push({
        pts: maduraPacote,
        anoIni: ano,
        totalContrato: caixaPacote,
        precoUnit: preco,
        renovada: false
      });
    }
    if (ano >= 2 && novosPacote > 0) {
      const caixaNovos = novosPacote * preco * premissas.anosPacote * (1 - premissas.descontoPacote);
      caixaPacote += caixaNovos;
      coortes.push({
        pts: novosPacote,
        anoIni: ano,
        totalContrato: caixaNovos,
        precoUnit: preco,
        renovada: false
      });
    }

    // Renovação de coortes que expiraram
    for (const c of coortes) {
      if (!c.renovada && ano === c.anoIni + premissas.anosPacote) {
        const ptsSobreviventes = Math.round(c.pts * Math.pow(1 - premissas.churnAno, premissas.anosPacote));
        if (ptsSobreviventes > 0) {
          const caixaRenov = ptsSobreviventes * preco * premissas.anosPacote * (1 - premissas.descontoPacote);
          coortes.push({
            pts: ptsSobreviventes,
            anoIni: ano,
            totalContrato: caixaRenov,
            precoUnit: preco,
            renovada: false
          });
          c.renovada = true;
        }
      }
    }

    // Receita ratificável de pacotes
    let receitaPacote = 0;
    for (const c of coortes) {
      const anosDecorridos = ano - c.anoIni;
      if (anosDecorridos >= 0 && anosDecorridos < premissas.anosPacote) {
        receitaPacote += c.totalContrato / premissas.anosPacote;
      }
    }

    // Receita recorrente avulsa
    const recMadura = maduraRecorrente * preco * (1 - premissas.descontoPacote) * (1 - premissas.inadimplencia);
    const recNovos = (ano > 1) ? novosRecorrente * preco * (1 - premissas.descontoPacote) * (1 - premissas.inadimplencia) : 0;
    const receitaRecorrente = recMadura + recNovos;

    const receitaReconhecida = receitaRecorrente + receitaPacote;

    // Custos
    const totalPontos = madura + novos;
    const custo = calcularCusto(premissas, totalPontos, ano);

    const margem = receitaReconhecida - custo.custoTotal;
    const margemPct = receitaReconhecida > 0 ? (margem / receitaReconhecida) : 0;

    resultados.push({
      ano: premissas.anoBase + ano - 1,
      totalPontos,
      madura,
      maduraPacote,
      maduraRecorrente,
      novos,
      novosPacote,
      novosRecorrente,
      preco,
      caixaPacote,
      receitaRecorrente,
      receitaPacote,
      receitaReconhecida,
      custoTotal: custo.custoTotal,
      margem,
      margemPct
    });

    pontosAtivos = madura + novos;
  }

  return {
    coortes,
    anos: resultados
  };
}

// ============================================
// PROJEÇÃO 5 ANOS — TRÊS CENÁRIOS
// ============================================

function calcularProjecaoCenarios(premissas, base) {
  const configs = {
    conservador: {
      nome: 'A — Conservador',
      baseInicial: base.pontosPagantes,
      novosEntrantes: premissas.novosEntrantesConservador,
      adocaoMadura: premissas.adocaoPacoteBaixa,
      adocaoNovos: premissas.adocaoPacoteBaixa
    },
    baseline: {
      nome: 'B — Base (provável)',
      baseInicial: base.pontosPagantes,
      novosEntrantes: premissas.novosEntrantesAno,
      adocaoMadura: premissas.adocaoPacoteMadura,
      adocaoNovos: premissas.adocaoPacoteNovos
    },
    otimista: {
      nome: 'C — Otimista',
      baseInicial: base.pontosPagantes,
      novosEntrantes: premissas.novosEntrantesOtimista,
      adocaoMadura: premissas.adocaoPacoteMadura,
      adocaoNovos: premissas.adocaoPacoteMadura
    }
  };

  const resultados = {};
  for (const [chave, config] of Object.entries(configs)) {
    resultados[chave] = calcularReceitaReconhecida(premissas, config);
  }

  return resultados;
}

// ============================================
// PRICING COMPARADO
// ============================================

function calcularPricingComparado(premissas, pricing) {
  const precoUSD = premissas.anuidadeRef / premissas.cambioUSDBRL;

  // Encontrar tier correspondente na tabela direta
  let tierCorrespondente = null;
  const tabelaDireta = pricing.clienteDireto;
  for (const tier of tabelaDireta) {
    if (precoUSD >= tier.ano3ef && precoUSD <= tier.ano1) {
      tierCorrespondente = tier;
      break;
    }
  }

  // Distância até faixa de dealer
  const tabelaDealer = pricing.dealerRevendedor;
  const dealerMin = tabelaDealer[tabelaDealer.length - 1].ano3ef;
  const dealerMax = tabelaDealer[0].ano1;

  return {
    precoReais: premissas.anuidadeRef,
    precoUSD,
    tierCorrespondente,
    dealerMin,
    dealerMax,
    distanciaDealer: precoUSD - dealerMax
  };
}

// ============================================
// SIMULADOR INTERATIVO (PARÂMETROS VARIÁVEIS)
// ============================================

function simular(premissas, params) {
  const config = {
    baseInicial: params.baseInicial || premissas.baseInicial || 4822,
    novosEntrantes: params.novosEntrantes || premissas.novosEntrantesAno,
    adocaoMadura: params.adocaoMadura !== undefined ? params.adocaoMadura : premissas.adocaoPacoteMadura,
    adocaoNovos: params.adocaoNovos !== undefined ? params.adocaoNovos : premissas.adocaoPacoteNovos,
    anosProjecao: params.anosProjecao || 5
  };

  // Configuração contrafactual (ninguém fecha pacote)
  const configContrafactual = {
    ...config,
    adocaoMadura: 0,
    adocaoNovos: 0
  };

  return {
    comPacote: calcularReceitaReconhecida(premissas, config),
    semPacote: calcularReceitaReconhecida(premissas, configContrafactual)
  };
}

// ============================================
// EXPORTS
// ============================================

const Calculo = {
  calcularEscopoPotencial,
  calcularCusto,
  calcularReceitaReconhecida,
  calcularProjecaoCenarios,
  calcularPricingComparado,
  simular
};

// Node (ESM)
if (typeof module !== 'undefined' && module.exports) {
  module.exports = Calculo;
}

// Browser (global)
if (typeof window !== 'undefined') {
  window.Calculo = Calculo;
}

// Para import ESM
export default Calculo;
export {
  calcularEscopoPotencial,
  calcularCusto,
  calcularReceitaReconhecida,
  calcularProjecaoCenarios,
  calcularPricingComparado,
  simular
};
