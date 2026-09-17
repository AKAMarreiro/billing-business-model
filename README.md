# Irricontrol ONE Receita

Pipeline de build para analise do modelo de receita de assinatura.

## Estrutura

- `dados/` — Dados brutos: premissas, base de dispositivos, Stripe, pricing global. **Nenhum numero derivado**.
- `motor/` — Funcoes puras de calculo. **Zero I/O**. Consumido por Node e browser (ESM).
- `narrativa/` — Texto em Markdown com placeholders `{{chave}}`. **Nenhum numero hardcoded**.
- `render/` — Builds oficiais: derivados em Node, HTML em Node e XLSX em Python.
- `dist/` — Artefatos gerados (HTML, JSON). **Versionado, nunca editado a mao**.
- `scripts/` — Verificador executável e compatibilidade PowerShell legada.

## Regras

1. Cada numero existe em exatamente um lugar (`dados/`).
2. Nenhum renderizador calcula. Motor calcula; renderizador formata.
3. UTF-8 sem BOM sempre. `LF` para arquivos de texto.
4. Testes vermelhos = build falha = nada e publicado.

## Build

O pipeline oficial usa Node e Python:

```powershell
npm test
npm run verificar
npm run build
```

Durante a transicao, o build PowerShell continua disponivel:

```powershell
& "scripts/build-all.ps1"

```

## Contrato de cada camada

### dados/
- So fato. Zero conta. Potencial nao vai aqui (e pontos x preco).
- `FONTES.md` documenta origem e data de cada valor.

### motor/
- Funcoes puras: entra objeto, sai objeto.
- Exporta para Node e browser. Nada que so exista no Node.
- `calculo.test.js` verifica valores com Node (quando disponivel).
- `scripts/build-derivados.ps1` reimplementa o mesmo motor em PowerShell para build.

### narrativa/
- Markdown com placeholders `{{chave}}`.
- Nenhuma sequencia que pareca moeda, percentual ou milhar e permitida.
- Excecoes: anos (2024), protocolo de 14 dias.

### render/
- `build-derivados.js` le dados, chama o motor e grava `dist/derivados.json`.
- `build-html.js` resolve a narrativa e gera um HTML autonomo com SVG e simulador.
- `build-xlsx.py` gera `dist/modelo.xlsx` sem recalcular indicadores.

### dist/
- Versionado no Git. Mas nunca editado a mao.
- Se precisa mudar: altera a origem e regera.

## Encoding

- `.gitattributes`: `text=auto eol=lf`
- `.editorconfig`: `charset = utf-8`
- Scripts PowerShell: `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`

## Decisao de arquitetura: por que dist/ e versionado

O material precisa ser abrivel por quem clona sem rodar build. Quem recebe o repositorio deve conseguir abrir `dist/index.html` diretamente.
Mas `dist/` nunca e editado a mao — e sempre gerado a partir das tres camadas de origem.

## Status

Em construcao. Siga as etapas do contrato na ordem definida.

## Decisoes vigentes

- Pivos usam anuidade de R$1.200; Irripump e medidor de nivel usam R$800.
- A visao historica considera apenas pivos. A visao prospectiva inclui os tres produtos e seus precos proprios.
- `dist/` e versionado e nunca deve ser editado manualmente.
