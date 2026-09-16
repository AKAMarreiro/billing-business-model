# Stripe = Escala, Operação Manual = Teto

O Stripe bem configurado faz sozinho o que hoje é feito manualmente: emite fatura, cobra cartão, envia lembrete, registra pagamento. Sem intervenção humana. Com a base atual de {{pontosPagantes}} clientes, a operação manual ainda é viável. Com a base projetada de {{projecaoClientes}} em cinco anos, não será.

O teto prático da operação manual é de 10 a 20 clientes internacionais por mês. Além disso, o risco de erro cresce exponencialmente: um input errado no endereço de faturamento, uma configuração de moeda trocada, um CNPJ digitado com dígito errado — e o bloqueio automático dispara para quem já pagou. O cliente liga irritado. O time de suporte gasta horas. O comercial oferece desconto para compensar.

A estrutura internacional acentua o problema. Times regionais fecham contratos no Brasil; o billing é feito na Áustria; o repasse entre filiais requer registro manual no Stripe. Cada passagem manual é um ponto de falha. O SAF System, a {{precoSAF}} por device/ano, cobrado direto pela Irricontrol com repasse a parceiros, infla o charge_volume sem ser receita própria — e confunde qualquer análise rápida.

O spread dealer contra cliente direto de {{spreadDiretoDealer}} a {{spreadDiretoDealerMax}} mostra o quanto a estrutura de canal distorce a receita. Quem vende direto recebe menos que quem vende via dealer, apesar de custar menos para manter.

A pergunta não é se o Stripe escala. É se a operação manual deixa de escalar antes que o Stripe seja necessário.
