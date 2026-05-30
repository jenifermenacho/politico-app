const fs = require('fs');

async function testApi() {
  // Test Camara frentes
  const id = 204358; // Beto Pereira
  const camaraFrentesUrl = `https://dadosabertos.camara.leg.br/api/v2/deputados/${id}/frentes`;
  console.log("Fetching: " + camaraFrentesUrl);
  const camaraRes = await fetch(camaraFrentesUrl);
  const camaraData = await camaraRes.json();
  console.log("Frentes Parlamentares:", JSON.stringify(camaraData.dados.slice(0, 3), null, 2));

  // Test TSE DivulgaCand
  // 2022 election, MS, Deputado Federal (6)
  const uf = "MS";
  const tseListUrl = `https://divulgacandcontas.tse.jus.br/divulga/rest/v1/candidatura/listar/2022/${uf}/2040602022/6/candidatos`;
  console.log("Fetching TSE candidates list: " + tseListUrl);
  try {
    const tseRes = await fetch(tseListUrl);
    if (!tseRes.ok) {
      console.error("TSE list failed with status:", tseRes.status);
      return;
    }
    const tseData = await tseRes.json();
    console.log("TSE list length: " + tseData.candidatos.length);
    // Find Beto Pereira
    const cand = tseData.candidatos.find(c => c.nomeUrna.toUpperCase().includes("BETO PEREIRA") || c.nomeCompleto.toUpperCase().includes("BETO PEREIRA"));
    if (cand) {
      console.log("Found in TSE:", cand.nomeUrna, cand.id);
      
      const idCand = cand.id;
      const finUrl = `https://divulgacandcontas.tse.jus.br/divulga/rest/v1/candidatura/buscar/2022/${uf}/2040602022/candidato/${idCand}`;
      console.log("Fetching Fin: " + finUrl);
      const finRes = await fetch(finUrl, {
        headers: {
            "Accept": "application/json, text/plain, */*",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        }
      });
      const text = await finRes.text();
      try {
        const finData = JSON.parse(text);
        console.log("Total Receitas: ", finData?.resumo?.receitas?.totalReceitas);
      } catch(e) {
        console.log("TSE HTML text:", text.substring(0, 500));
      }
      console.log("Receitas por Origem: ", JSON.stringify(finData?.resumo?.receitas?.receitasOrigem, null, 2));
    }
  } catch (e) {
    console.error("TSE error:", e);
  }
}
testApi();
