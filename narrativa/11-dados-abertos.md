# Dados Abertos

Este documento é construído sobre os dados que existem hoje. O que falta levantar, em ordem de prioridade:

**Split cortesia contra pagante.** Quantos dos {{pontosPagantes}} pontos pagantes estão em algum tipo de bonificação? Por quanto tempo? Com que data de término? Sem esse split, o gap de {{gapCompleto}} não pode ser decomposto com precisão.

**Breakdown dos contratos plurianuais.** Quantos pacotes no prazo padrão existem? Quando vencem? Qual a distribuição por cliente? O impacto no caixa dos anos seguintes depende dessas datas.

**Custo operacional real do comercial.** Quantos FTEs dedicados a retenção? Qual o custo total de salário, comissão e estrutura? Sem isso, não é possível calcular se a retenção manual se paga.

**Volume de pass-through.** Quanto do charge_volume do Stripe é SAF System, repasse a parceiros, ou outro fluxo que não é receita própria? Esse número precisa ser subtraído de qualquer análise de saúde financeira.

**Clientes internacionais por canal.** Quantos clientes diretos? Quantos via dealer? Qual o ARPU médio de cada canal? A decisão de estrutura de canal depende dessa comparação.

**ARPU por fazenda.** O total de {{fazendas}} fazendas com {{pontosPagantes}} pontos pagantes dá uma média de {{arpuFazenda}} por fazenda. Mas a distribuição não é uniforme: quantas fazendas estão nas faixas pequenas e quantas concentram muitos pivôs? A decisão de tier de preço depende dessa distribuição.

**Distribuição de tamanho de fazenda.** Área média por fazenda, irrigada e não-irrigada. Isso afeta o potencial do produto de manejo hídrico.

**Churn real por safra.** O churn de {{churnAno}} é anual. Mas quando no ano o cliente cancela? No início da safra (depois da instalação) ou no final (quando o pagamento vence)? O momento do churn afeta a estratégia de retenção.

**CAC da equipe comercial.** Custo de aquisição de um novo cliente: salário do vendedor, comissão, viagem, tempo de ciclo. Sem CAC, não é possível comparar o custo de aquisição com o lifetime value.

**Sequência de reuniões para fechamento.** Denise (produto) → Luiz (comercial) → Áustria (board). Cada etapa da sequência precisa de documento de decisão, não apenas de entendimento verbal. O preço de SaaS puro, a estrutura de tiers, e a política de desconto precisam sair dessas reuniões como decisão aprovada, não como intenção registrada.

Sem esses dados, o modelo é ilustrativo. Com esses dados, é um instrumento de decisão.
