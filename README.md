# Irricontrol ONE Receita

Pipeline de build para analise do modelo de receita de assinatura.

## Estrutura

- `dados/` — Dados brutos: premissas, base de dispositivos, Stripe, pricing global. **Nenhum numero derivado**.
- `motor/` — Funcoes puras de calculo. **Zero I/O**. Consumido por Node e browser (ESM).
- `narrativa/` — Texto em Markdown com placeholders `{{chave}}`. **Nenhum numero hardcoded**.
- `render/` — Scripts de build (reservado para futuro).
- `dist/` — Artefatos gerados (HTML, JSON). **Versionado, nunca editado a mao**.
- `scripts/` — Build scripts em PowerShell + verificadores.

## Regras

1. Cada numero existe em exatamente um lugar (`dados/`).
2. Nenhum renderizador calcula. Motor calcula; renderizador formata.
3. UTF-8 sem BOM sempre. `LF` para arquivos de texto.
4. Testes vermelhos = build falha = nada e publicado.

## Build

Como nao ha Node/Python instalado, o build usa PowerShell puro:

```powershell
# Build completo (derivados + HTML)
& "scripts/build-all.ps1"

# Ou passo a passo:
& "scripts/build-derivados.ps1"   # dados + motor PowerShell -> dist/derivados.json
& "scripts/build-html.ps1"         # derivados + narrativa -> dist/index.html
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
- Reservado para futuro (XLSX, visualizacao interativa).

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
