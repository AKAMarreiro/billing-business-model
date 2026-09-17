import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];
const fail = (message) => failures.push(message);
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8').replace(/^\ufeff/, '');
const files = [];
function collect(folder) {
  for (const entry of fs.readdirSync(path.join(root, folder), { withFileTypes: true })) {
    const relative = path.join(folder, entry.name);
    if (entry.isDirectory()) collect(relative);
    else files.push(relative);
  }
}
collect('dados'); collect('motor'); collect('narrativa'); collect('render'); collect('scripts');
for (const file of ['README.md', 'package.json', '.gitattributes', '.editorconfig']) files.push(file);
const textFiles = files.filter((file) => /\.(md|json|csv|js|html|css|py|txt|ps1)$/.test(file));

for (const file of textFiles) {
  const buffer = fs.readFileSync(path.join(root, file));
  if (buffer.includes(0xef) && buffer[0] === 0xef && buffer[1] === 0xbb && buffer[2] === 0xbf) fail(`BOM: ${file}`);
  const text = buffer.toString('utf8');
  if (text.includes('\ufffd')) fail(`U+FFFD: ${file}`);
  if (/[ÃÂ][\x80-\xbf]/.test(text)) fail(`mojibake: ${file}`);
  if (text.includes('\r\n')) fail(`CRLF: ${file}`);
}

const narrativeFiles = fs.readdirSync(path.join(root, 'narrativa')).filter((file) => file.endsWith('.md'));
const narrative = narrativeFiles.map((file) => read(path.join('narrativa', file))).join('\n');
const placeholders = [...narrative.matchAll(/\{\{(\w+)(?:\|\w+)?\}\}/g)].map((match) => match[1]);
const derived = JSON.parse(read('dist/derivados.json'));
for (const key of [...new Set(placeholders)]) if (!(key in derived)) fail(`placeholder sem derivado: ${key}`);
const hardcodedNumber = /R\$\s*\d|\b\d{1,3}(?:\.\d{3})+\b|\b\d+(?:,\d+)?%/;
for (const file of narrativeFiles) {
  const lines = read(path.join('narrativa', file)).split(/\r?\n/);
  lines.forEach((line, index) => {
    const withoutYears = line.replace(/\b(?:19|20)\d{2}\b/g, '').replace(/\b14 dias\b/g, '');
    if (hardcodedNumber.test(withoutYears)) fail(`numero hardcoded em ${file}:${index + 1}`);
  });
}

for (const required of [
  'dados/premissas.json', 'dados/base-dispositivos.json', 'dados/stripe-mensal.csv',
  'dados/pricing-global.json', 'dados/FONTES.md', 'motor/calculo.js',
  'motor/calculo.test.js', 'motor/formato.js', 'render/build-derivados.js',
  'render/build-html.js', 'render/build-xlsx.py', 'scripts/verificar.js',
  'dist/derivados.json', 'dist/index.html'
]) if (!fs.existsSync(path.join(root, required))) fail(`arquivo ausente: ${required}`);

const csv = read('dados/stripe-mensal.csv').trim().split(/\r?\n/).slice(1).map((line) => {
  const [month, currency, charge, invoice] = line.split(',');
  return { month, currency, charge: Number(charge), invoice: Number(invoice) };
});
const totals = {};
for (const row of csv) {
  const year = row.month.slice(0, 4);
  totals[year] ??= { charge: 0, invoice: 0 };
  totals[year].charge += row.charge || 0;
  totals[year].invoice += row.invoice || 0;
}
const expected = { '2025': { charge: 2008247.07, invoice: 4426942.48 }, '2026': { charge: 1227998.31, invoice: 3841611.48 } };
for (const [year, values] of Object.entries(expected)) {
  for (const field of ['charge', 'invoice']) if (Math.abs(totals[year][field] - values[field]) > 0.01) fail(`Stripe ${field} ${year}: ${totals[year][field]} != ${values[field]}`);
}

const test = spawnSync(process.execPath, ['motor/calculo.test.js'], { cwd: root, encoding: 'utf8' });
if (test.status !== 0) fail(`testes do motor falharam:\n${test.stdout}\n${test.stderr}`);

if (failures.length) {
  console.error('VERIFICACAO FALHOU');
  failures.forEach((failure) => console.error(`- ${failure}`));
  process.exit(1);
}
console.log('VERIFICACAO OK');
console.log(`- ${placeholders.length} placeholders resolvidos`);
console.log('- encoding e line endings validos');
console.log('- totais Stripe conferidos');
console.log('- testes do motor passaram');
