# Fontes dos Dados

Este documento registra a origem e data de cada valor em `dados/`.

## premissas.json

| Chave | Valor | Origem | Data |
|-------|-------|--------|------|
| `anoBase` | 2026 | Decisão comercial: exercício de transição para SaaS puro | Set/2026 |
| `anuidadeRef` | R$ 1.200 | Modelo financeiro oficial, validado com board do Grupo Bauer | Ago/2026 |
| `precoTabelaSaaS` | R$ 1.800 | Preço de tabela no boleto, sem desconto | Ago/2026 |
| `precoAlvoSaaS` | R$ 1.200 | Preço condicionado a cartão com cobrança automática Stripe | Ago/2026 |
| `novosEntrantesAno` | 250 | Projeção comercial baseada em média histórica de vendas | Ago/2026 |
| `churnAno` | 3% | Base histórica do portfolio (média 2023-2025) | Ago/2026 |
| `reajusteAno` | 5% | Índice de reajuste do modelo financeiro oficial | Ago/2026 |
| `inadimplencia` | 8% | Taxa média observada no Stripe (2024-2025) | Ago/2026 |
| `descontoPacote` | 20% | Desconto médio praticado em pacotes plurianuais | Ago/2026 |
| `anosPacote` | 3 | Duração padrão do pacote plurianual | Ago/2026 |
| `adocaoPacoteMadura` | 100% | Decisão comercial vigente: toda base em pacote | Set/2026 |
| `adocaoPacoteNovos` | 100% | Decisão comercial vigente: todos novos em pacote | Set/2026 |
| `adocaoPacoteBaixa` | 60% | Cenário conservador: parte dos novos entrantes não fecha pacote no primeiro ano | Set/2026 |
| `primeiroAnoGratis` | true | Novos entrantes não geram receita no ano de entrada (cortesia/piloto) | Set/2026 |
| `novosEntrantesConservador` | 150 | Cenário conservador: poucos novos entrantes por ano | Set/2026 |
| `novosEntrantesOtimista` | 400 | Cenário otimista: mais novos entrantes por ano, pressupõe estrutura automatizada | Set/2026 |
| `precoNovoProduto` | R$ 600/device/ano | Preço referência para monitoramento e manejo de pivôs | Set/2026 |
| `adocaoNovoProduto` | 30% | Taxa esperada de adoção de novos produtos pela base existente | Set/2026 |
| `custoFixoPlataforma` | R$ 600.000/ano | Modelo financeiro oficial (infraestrutura cloud + time técnico) | Ago/2026 |
| `custoVarPontoInfra` | R$ 96/ano/ponto | Custo de nuvem AWS + conectividade por dispositivo | Ago/2026 |
| `custoVarPontoSuporte` | R$ 60/ano/ponto | Custo de atendimento N1/N2 por dispositivo | Ago/2026 |
| `custoOperacaoBilling` | R$ 36.000/ano | Custo da operação de cobrança e reconciliação Stripe | Ago/2026 |
| `cambioUSDBRL` | 5.70 | Taxa de câmbio de referência para comparação global | Set/2026 |

## base-dispositivos.json

| Chave | Valor | Origem | Data |
|-------|-------|--------|------|
| `dataCorte` | 2026-08-31 | Corte do banco de dados de produção | 31/08/2026 |
| `pivos.total` | 3.926 | Banco de dados real (Nexus + SmartConnect) | 31/08/2026 |
| `pivos.testeDemo` | 79 | Dispositivos em ambiente de teste/demo | 31/08/2026 |
| `pivos.efetivos` | 3.847 | Total - testeDemo | 31/08/2026 |
| `irripump` | 803 | Banco de dados real | 31/08/2026 |
| `medidorNivel` | 172 | Banco de dados real | 31/08/2026 |
| `fazendas` | 963 | Banco de dados real | 31/08/2026 |
| `usuariosAtivos` | 4.512 | Banco de dados real | 31/08/2026 |
| `pontosPagantes` | 3.422 | Banco de dados real (clientes com cobrança ativa) | 31/08/2026 |

## stripe-mensal.csv

| Período | Origem | Observação |
|---------|--------|------------|
| 2023 (abr–dez) | Stripe Dashboard | Primeiros meses com volume zero (ativação) |
| 2024 (jan–ago) | Stripe Dashboard | Atividade mínima antes da inflexão |
| 2024 (set–dez) | Stripe Dashboard | Out/2024: evento de pacotes multianuais (R$901k invoice) |
| 2025 (ano completo) | Stripe Dashboard | Ano de estabilização |
| 2026 (jan–ago) | Stripe Dashboard | Parcial até agosto/2026 |

## pricing-global.json

| Origem | Data |
|--------|------|
| Tabela global Bauer, proposta Helton 2024 | 2024 |

## tabela-precos-{pt,en,es}.jpg

| Arquivo | Conteudo | Origem | Data |
|---------|----------|--------|------|
| `tabela-precos-pt.jpg` | Tabela de precos em portugues (5 tiers, 3 duracoes) | Gerado a partir de pricing-global.json (cliente direto) | Set/2026 |
| `tabela-precos-en.jpg` | Global pricing table in english (5 tiers, 3 durations) | Gerado a partir de pricing-global.json (cliente direto) | Set/2026 |
| `tabela-precos-es.jpg` | Tabla de precios en espanol (5 tiers, 3 duraciones) | Gerado a partir de pricing-global.json (cliente directo) | Set/2026 |

**Preco de referencia:** USD 220/device/ano (1 ano). Pacotes plurianuais: 2 anos = USD 390 total (USD 195/ano efetivo), 3 anos = USD 510 total (USD 170/ano efetivo).
**Cliente direto apenas.** Dealer nao participa do modelo de receita (removido da apresentacao).

## Notas

- **O preço de tabela (R$1.800) e o preço-alvo (R$1.200) não são desconto comercial negociável.** Os 33% de diferença são o incentivo estrutural para migração ao pagamento automático via cartão Stripe. Quem paga com boleto não tem desconto.
- **Os 3.422 pontos pagantes não são derivados.** Vêm do banco de dados real, não da conta `pivos.efetivos - testeDemo`. Pode haver pivôs de demo que pagam ou pivôs efetivos que não pagam.
- **Os totais consolidados da série Stripe servem como asserção:** a soma da série mensal por ano deve bater com os totais conhecidos. Se houver divergência, a série mensal precisa ser corrigida.
- **Receita escondida:** O primeiro ano de novos entrantes está embutido no preço do hardware. O cliente recebe o software (anuidade) sem nota fiscal de serviço correspondente. O motor calcula `receitaEscondida = novos * preco` em cada ano, representando o valor que deveria ser reconhecido como serviço mas não aparece nas demonstrações. Em nota de produto, o valor está lá; em nota de serviço, não está.
