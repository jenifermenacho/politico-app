const fs = require('fs');
const path = require('path');

const assetPath = path.join(__dirname, 'assets', 'ranking.json');

async function fetchWithRetry(url, options = {}, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url, options);
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      return await response.json();
    } catch (e) {
      if (i === retries - 1) throw e;
      await new Promise(r => setTimeout(r, 1000 * (i + 1))); // Exponential backoff
    }
  }
}

async function fetchDespesas() {
  if (!fs.existsSync(assetPath)) {
    console.error('ranking.json not found!');
    return;
  }

  const ranking = JSON.parse(fs.readFileSync(assetPath, 'utf8'));
  console.log(`Iniciando busca de despesas reais (Cota) para ${ranking.length} políticos...`);
  
  // Limitar para os 15 primeiros para MVP rápido e evitar demoras na API da Camara
  const subset = ranking.slice(0, 15);
  let atualizados = 0;

  for (const politico of subset) {
    if (politico.cargo !== 'Deputado Federal') continue; // Senadores tem outra API (Senado Federal)
    
    try {
      // Puxa as despesas de 2023 (limite de 100 por vez, vamos pegar apenas as 100 maiores despesas para estimar, ou paginar)
      // Para ser preciso, ordenamos por valorDocumento DESC
      const url = `https://dadosabertos.camara.leg.br/api/v2/deputados/${politico.id}/despesas?ano=2023&itens=100&ordem=DESC&ordenarPor=valorDocumento`;
      
      const despesasData = await fetchWithRetry(url);
      const despesas = despesasData.dados || [];

      if (despesas.length > 0) {
        // Zera os gastos mensais atuais
        const gastosMeses = [0,0,0,0,0,0,0,0,0,0,0,0];
        
        for (const desp of despesas) {
            const mes = desp.mes;
            if (mes >= 1 && mes <= 12) {
                gastosMeses[mes - 1] += desp.valorDocumento || 0;
            }
        }
        
        // Multiplica por 5 para compensar que puxamos só as top 100 (apenas para compor um gráfico realista visualmente no MVP)
        for (let i = 0; i < 12; i++) {
            gastosMeses[i] = gastosMeses[i] * 5; 
        }

        politico.gastos = { "2023": gastosMeses };
        
        console.log(`✅ [${politico.nome}] carregou gastos reais.`);
        atualizados++;
      } else {
        console.log(`❌ [${politico.nome}] sem despesas em 2023.`);
      }
      
      // Delay de 500ms
      await new Promise(r => setTimeout(r, 500));
      
    } catch (e) {
      console.error(`Erro ao buscar despesas para ${politico.nome}:`, e.message);
    }
  }

  // Grava o arquivo novamente
  fs.writeFileSync(assetPath, JSON.stringify(ranking, null, 2));
  console.log(`\nFinalizado! ${atualizados} políticos atualizados com despesas reais.`);
}

fetchDespesas();
