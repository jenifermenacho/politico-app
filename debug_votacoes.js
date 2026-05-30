const fs = require('fs');

async function getReformaTributariaVotos() {
  const propId = 2196833; // PEC 45/2019
  const res = await fetch(`https://dadosabertos.camara.leg.br/api/v2/proposicoes/${propId}/votacoes`);
  const data = await res.json();
  
  // Encontra uma votacao com votos nominais
  for (const v of data.dados) {
      if (v.siglaOrgao === 'PLEN' && v.aprovacao !== null) {
          console.log(`Votação: ${v.id} - ${v.descricao}`);
          const vRes = await fetch(`https://dadosabertos.camara.leg.br/api/v2/votacoes/${v.id}/votos`);
          const vData = await vRes.json();
          if (vData.dados && vData.dados.length > 0) {
              console.log(`Votos nominais encontrados: ${vData.dados.length}`);
              console.log(`Exemplo de voto:`, vData.dados[0].deputado.nome, '->', vData.dados[0].tipoVoto);
              break;
          }
      }
  }
}
getReformaTributariaVotos();
