const fs = require('fs');
const path = require('path');
const Parser = require('rss-parser');
const parser = new Parser();

const assetPath = path.join(__dirname, 'assets', 'ranking.json');

async function fetchNews() {
  if (!fs.existsSync(assetPath)) {
    console.error('ranking.json not found!');
    return;
  }

  const ranking = JSON.parse(fs.readFileSync(assetPath, 'utf8'));
  console.log(`Iniciando busca de notícias reais no Google News para ${ranking.length} políticos...`);
  
  // Processando todos com um delay para evitar block
  let atualizados = 0;

  for (const politico of ranking) {
    try {
      // Remover acentos e formatar query
      const nomeQuery = encodeURIComponent(`"${politico.nome}"`);
      const termo = politico.cargo === 'Senador' ? 'Senador' : 'Deputado';
      // Busca no Google News Brasil os últimos 7 dias
      const url = `https://news.google.com/rss/search?q=${termo}+${nomeQuery}+when:30d&hl=pt-BR&gl=BR&ceid=BR:pt-419`;
      
      const feed = await parser.parseURL(url);
      
      const noticiasReais = feed.items.slice(0, 3).map(item => {
        return {
          titulo: item.title.split(' - ')[0], // Tira o nome do jornal do título
          url: item.link,
          data: new Date(item.pubDate).toISOString().split('T')[0],
          fonte: item.source || item.title.split(' - ').pop() || 'Google News'
        };
      });

      if (noticiasReais.length > 0) {
        politico.noticias = noticiasReais;
        console.log(`✅ [${politico.nome}] encontrou ${noticiasReais.length} notícias.`);
        atualizados++;
      } else {
        console.log(`❌ [${politico.nome}] sem notícias recentes.`);
      }
      
      // Delay de 1.5s para evitar rate limit do Google
      await new Promise(r => setTimeout(r, 1500));
      
    } catch (e) {
      console.error(`Erro ao buscar notícias para ${politico.nome}:`, e.message);
    }
  }

  // Grava o arquivo novamente
  fs.writeFileSync(assetPath, JSON.stringify(ranking, null, 2));
  console.log(`\nFinalizado! ${atualizados} políticos atualizados com notícias reais.`);
}

fetchNews();
