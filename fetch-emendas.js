const fs = require('fs');
const path = require('path');

const assetPath = path.join(__dirname, 'assets', 'ranking.json');

async function fetchEmendas() {
  if (!fs.existsSync(assetPath)) {
    console.error('ranking.json not found!');
    return;
  }

  const ranking = JSON.parse(fs.readFileSync(assetPath, 'utf8'));
  console.log(`Iniciando integração de Emendas Parlamentares Reais via Portal da Transparência...`);
  
  const options = {
    headers: { 'chave-api-dados': '9426f3d6dffe1d6718afa8f3d771036a' }
  };
  
  // Vamos puxar as primeiras 20 páginas (300 emendas) para cruzar com nossa base
  let todasEmendas = [];
  for (let i = 1; i <= 20; i++) {
     try {
       const res = await fetch(`https://api.portaldatransparencia.gov.br/api-de-dados/emendas?ano=2023&pagina=${i}`, options);
       const data = await res.json();
       todasEmendas = todasEmendas.concat(data);
       await new Promise(r => setTimeout(r, 200)); // Rate limit safety
     } catch(e) {
       console.error(`Erro na página ${i}:`, e.message);
     }
  }

  console.log(`Baixadas ${todasEmendas.length} emendas recentes.`);

  // Agrupar por autor
  const emendasPorAutor = {};
  for (const e of todasEmendas) {
      if (!e.autor) continue;
      const autorNorm = e.autor.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase();
      if (!emendasPorAutor[autorNorm]) {
          emendasPorAutor[autorNorm] = {
              totalDestinado: 0,
              areasObj: {}
          };
      }
      
      const valor = parseFloat(e.valorEmpenhado.replace(/\./g, '').replace(',', '.')) || 0;
      emendasPorAutor[autorNorm].totalDestinado += valor;
      
      const funcao = e.funcao || 'Outros';
      if (!emendasPorAutor[autorNorm].areasObj[funcao]) emendasPorAutor[autorNorm].areasObj[funcao] = 0;
      emendasPorAutor[autorNorm].areasObj[funcao] += valor;
  }

  let atualizados = 0;
  // Cruzar com o ranking
  for (const politico of ranking) {
      const nomeNorm = politico.nome.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase();
      
      // Tenta achar match exato ou que contenha o nome
      const autorMatch = Object.keys(emendasPorAutor).find(a => a.includes(nomeNorm) || nomeNorm.includes(a));
      
      if (autorMatch) {
          const e = emendasPorAutor[autorMatch];
          
          // Converter areasObj em array com porcentagens
          const areas = [];
          for (const k in e.areasObj) {
              const perc = Math.round((e.areasObj[k] / e.totalDestinado) * 100);
              if (perc > 0) {
                 areas.push({ nome: k, porcentagem: perc });
              }
          }
          
          // Ordena por porcentagem
          areas.sort((a,b) => b.porcentagem - a.porcentagem);

          politico.emendas = {
              totalDestinado: e.totalDestinado,
              areas: areas
          };
          console.log(`✅ [${politico.nome}] recebeu R$ ${(e.totalDestinado/1000000).toFixed(2)} milhões em emendas reais.`);
          atualizados++;
      }
  }

  // Grava o arquivo novamente
  fs.writeFileSync(assetPath, JSON.stringify(ranking, null, 2));
  console.log(`\nFinalizado! ${atualizados} políticos atualizados com emendas reais.`);
}

fetchEmendas();
