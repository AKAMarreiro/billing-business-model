# Viabilidade: Cinco Anos com Dados Reais

A projeção de cinco anos parte do dado real de {{receita2025}} em 2025, com realização de {{realizacao2025}}. Sobre essa base, três cenários de novos entrantes e adoção de pacote:

**Cenário A: conservador — {{novosEntrantesConservador}} novos entrantes/ano, {{adocaoPacoteBaixa}} de adoção de pacote.** Novos dispositivos entram na base, mas a maioria não fecha pacote no primeiro ano — permanece em cobrança avulsa ou com primeiro ano de cortesia. A receita reconhecida em 2030 é {{receitaA2030}}; a margem contábil, {{margemA2030}}.

**Cenário B: base (provável) — {{novosEntrantesAno}} novos entrantes/ano, {{adocaoPacoteMadura}} de adoção.** A base atual cresce com novos entrantes que, no segundo ano, migram para pacote de três anos com recorrência automática. O primeiro ano de cortesia é gratuito — não gera receita no ano de entrada, mas cria a base para receita reconhecida nos anos seguintes. Se esse período fosse faturado como serviço, entraria na receita. A receita em 2030 é {{receitaB2030}}; a margem, {{margemB2030}}.

**Cenário C: otimista — {{novosEntrantesOtimista}} novos entrantes/ano, alta penetração de pacote.** O crescimento acelerado pressupõe que a estrutura de cobrança automatizada (Stripe) e a separação clara de preço de hardware vs. software estejam operacionais. Sem essas condições, o volume não se traduz em receita. A receita em 2030 é {{receitaC2030}}; a margem, {{margemC2030}}.

**A receita escondida.** Em cada cenário, os novos entrantes do primeiro ano não aparecem na receita reconhecida — estão embutidos no preço do hardware. No cenário base, são {{novosEntrantesAno}} novos entrantes por ano. A {{anuidadeRef}} por device, isso representa {{receitaEscondidaAnoBase}} que deveria constar em nota de serviço, mas consta em nota de produto. Sem essa separação, o primeiro ano é realmente grátis: o cliente recebe software sem fatura de serviço correspondente. Em cinco anos, o acúmulo de receita escondida é de {{receitaEscondidaAcumuladaBase}}. O modelo contábil atual subfatura o valor do software e distorce a margem real da operação.

O efeito mais potente não está nos cenários de volume, está nos novos produtos. Monitoramento e manejo de pivôs, a {{precoNovoProduto}} por device/ano cada, adotados por {{adocaoNovoProduto}} da base, elevam o ARPU de {{arpuAtual}} para {{arpuNovo}}. O ARR potencial sobe de {{arrAtual}} para {{arrNovo}} — sem adicionar um pivô.

A pergunta estratégica não é se sobrevivemos. É por que capturamos só parte do potencial. Com {{pontosPagantes}} pontos pagantes hoje e {{totalEscopo}} no escopo, o gap de {{gapCompleto}} não é de mercado — é de mecanismo.
