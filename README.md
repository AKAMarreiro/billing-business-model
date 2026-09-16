# Irricontrol ONE Receita

Pipeline de build para análise do modelo de receita de assinatura.

## Estrutura

- `dados/` — Dados brutos: premissas, base de dispositivos, Stripe, pricing global. **Nenhum número derivado**.
- `motor/` — Funções puras de cálculo. **Zero I/O**. Consumido por Node e browser.
- `narrativa/` — Texto em Markdown com placeholders `{{chave}}`. **Nenhum número hardcoded**.
- `render/` — Scripts de build que leem dados + motor + narrativa e escrevem em `dist/`.
- `dist/` — Artefatos gerados (HTML, XLSX, JSON). **Versionado, nunca editado à mão**.
- `scripts/` — Verificadores de encoding, testes e integridade.

## Regras

1. Cada número existe em exatamente um lugar (`dados/`).
2. Nenhum renderizador calcula. Motor calcula; renderizador formata.
3. UTF-8 sem BOM sempre. `LF` para arquivos de texto.
4. Testes vermelhos = build falha = nada é publicado.

## Build

```bash
npm install
node scripts/verificar.js   # testes + encoding + narrativa
node render/build-derivados.js
node render/build-html.js
python render/build-xlsx.py
```

## Contrato de cada camada

### dados/
- Só fato. Zero conta. Potencial não vai aqui (é pontos × preço).
- `FONTES.md` documenta origem e data de cada valor.

### motor/
- Funções puras: entra objeto, sai objeto.
- Exporta para Node e browser. Nada que só exista no Node.

### narrativa/
- Markdown com placeholders `{{chave}}`.
- Nenhuma sequência que pareça moeda, percentual ou milhar é permitida.
- Exceções: anos (2024), protocolo de 14 dias.

### render/
- `build-derivados.js`: motor sobre dados → `dist/derivados.json`.
- `build-html.js`: derivados + narrativa → `dist/index.html`.
- `build-xlsx.py`: derivados → `dist/modelo.xlsx`.

### dist/
- Versionado no Git. Mas nunca editado à mão.
- Se precisa mudar: altera a origem e regera.

## Encoding

- `.gitattributes`: `text=auto eol=lf`
- `.editorconfig`: `charset = utf-8`
- Scripts PowerShell: `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
- `scripts/verificar.js` falha se encontrar `U+FFFD` ou mojibake.

## Decisão de arquitetura: por que dist/ é versionado

O material precisa ser abrível por quem clona sem rodar build. Quem recebe o repositório deve conseguir abrir `dist/index.html` diretamente.
Mas `dist/` nunca é editado à mão — é sempre gerado a partir das três camadas de origem.

## Status

Em construção. Siga as etapas do contrato na ordem definida.
