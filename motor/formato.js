/**
 * Formatação — motor/formato.js
 * Funções puras de formatação, usadas por renderizadores.
 * Não calculam nada, só formatam.
 */

function fmt(n) {
  return new Intl.NumberFormat('pt-BR').format(n);
}

function fmtCur(n) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(n);
}

function fmtPct(n) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'percent',
    minimumFractionDigits: 1,
    maximumFractionDigits: 1
  }).format(n / 100);
}

function fmtUSD(n) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(n);
}

const Formato = { fmt, fmtCur, fmtPct, fmtUSD };

if (typeof module !== 'undefined' && module.exports) {
  module.exports = Formato;
}
if (typeof window !== 'undefined') {
  window.Formato = Formato;
}

export default Formato;
export { fmt, fmtCur, fmtPct, fmtUSD };
