# O que Precisa Mudar: Três Decisões antes do Lançamento

Antes de lançar qualquer produto novo, três decisões de estrutura precisam ser tomadas.

**Primeira: desacoplar a anuidade dos novos produtos com piso não negociável.** Monitoramento e manejo de pivôs são software puro. Se entram no pacote com desconto, o cliente não desenvolve percepção de valor. O piso é o preço de tabela — {{precoTabelaSaaS}} no boleto, {{precoAlvoSaaS}} no cartão com cobrança automática. Nenhum desconto comercial pode reduzir esse piso. Se o comercial precisa de margem para fechar, o desconto vem do hardware, não do software.

**Segunda: estruturar plurianuais como subscription automática no Stripe.** O pacote de três anos deve ser um plano de subscription com cobrança automática anual, não um invoice único pago à vista. O desconto é política — {{descontoPacote}} para quem se compromete com recorrência automática — e não concessão de emergência no momento da renovação. Quando o cliente vence o pacote, a subscription continua no preço cheio, com opt-out explícito.

**Terceira: separar receita própria de pass-through nos relatórios.** O SAF System, repasses a parceiros, e qualquer outro fluxo de pass-through precisam estar em linha própria. Quem olha o dashboard do Stripe precisa ver {{receitaPropria}} separada de {{passThrough}}. Sem essa separação, a análise de saúde financeira está sempre distorcida.

Essas três decisões são de estrutura, não de execução. Não dependem de contratar mais gente, de desenvolver funcionalidade nova, ou de esperar aprovação de board. Dependem apenas de definição clara e comunicação ao time comercial.
