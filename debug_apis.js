const fs = require('fs');

async function checkCamaraApis() {
  console.log("Testing Camara API for a specific deputy (e.g. 204379 - Acácio Favacho)");
  const depId = 204379;
  
  // Test 1: Lideranças / Profissionais / Gabinete ?
  // Camara API doesn't have an endpoint for 'secretarios' directly. Let's check /deputados/{id}
  let res = await fetch(`https://dadosabertos.camara.leg.br/api/v2/deputados/${depId}`);
  let data = await res.json();
  console.log("Deputado Gabinete:", data.dados.ultimoStatus.gabinete);
  
  // Test 2: Votações (How to get how a deputy voted)
  // Let's search for a votacao by ID. PL 914/2024 (Mover para Mover/Taxa das Blusinhas)
  // First get proposicao ID
  res = await fetch(`https://dadosabertos.camara.leg.br/api/v2/proposicoes?siglaTipo=PL&numero=914&ano=2024`);
  data = await res.json();
  if (data.dados && data.dados.length > 0) {
      const propId = data.dados[0].id;
      console.log("Proposicao 914/2024 ID:", propId);
      // Get votacoes for this proposicao
      res = await fetch(`https://dadosabertos.camara.leg.br/api/v2/proposicoes/${propId}/votacoes`);
      let votacoesData = await res.json();
      console.log("Votacoes for PL:", votacoesData.dados.length > 0 ? votacoesData.dados[0].id : "None");
      if (votacoesData.dados.length > 0) {
          const votId = votacoesData.dados[0].id;
          res = await fetch(`https://dadosabertos.camara.leg.br/api/v2/votacoes/${votId}/votos`);
          let votos = await res.json();
          console.log(`Votos found: ${votos.dados.length}. Example:`, votos.dados[0]);
      }
  }
}

checkCamaraApis();
