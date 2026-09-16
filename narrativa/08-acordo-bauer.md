# O Acordo Bauer e a Estrutura Internacional

O Grupo Bauer opera com uma estrutura de billing centralizada na Áustria e times regionais que fecham contratos nos mercados locais. A Irricontrol segue o mesmo modelo: vendas no Brasil, faturamento na Áustria, repasse entre filiais.

A complexidade não está na estrutura em si, está na passagem de informação. Quando um time regional fecha um contrato, o dado precisa chegar ao billing em Áustria com precisão: número de devices, tier de volume, duração do pacote, forma de pagamento, dados fiscais do cliente. Cada campo que chega errado gera uma reemissão de invoice, um ajuste de charge, uma reconciliação manual.

O SAF System, a {{precoSAF}} por device/ano, é um caso extremo dessa complexidade. Cobrado direto pela Irricontrol com repasse a parceiros, o SAF infla o charge_volume sem ser receita própria. Quem olha o dashboard do Stripe e vê {{volumeTotal}} de charge precisa saber que parte desse valor é pass-through — dinheiro que entra e sai sem parar na conta da Irricontrol.

O spread entre cliente direto e dealer — {{spreadDiretoDealer}} a {{spreadDiretoDealerMax}} — mostra o quanto a estrutura de canal distorce a receita. Quem vende via dealer recebe menos por device, mas o dealer absorve o custo de suporte e cobrança. Quem vende direto recebe mais por device, mas assume o custo operacional inteiro.

A decisão de estrutura internacional já foi tomada. O que falta é a execução: processo de passagem de dados, validação automática de invoice, e separação clara entre receita própria e pass-through nos relatórios.
