const fs = require('fs');

async function debugEmendasAutor() {
  const nome = 'ACÁCIO FAVACHO'.toUpperCase(); // Upper e com acento? Ou sem acento?
  const nomeSemAcento = 'ACACIO FAVACHO';
  
  const options = {
    headers: {
      'chave-api-dados': process.env.PORTAL_TRANSPARENCIA_API_KEY || ''
    }
  };
  
  try {
    let res = await fetch(`https://api.portaldatransparencia.gov.br/api-de-dados/emendas?ano=2023&autor=${encodeURIComponent(nome)}&pagina=1`, options);
    let data = await res.json();
    console.log(`Teste ${nome}:`, data.length, data.length > 0 ? data[0].nomeAutor : '');

    res = await fetch(`https://api.portaldatransparencia.gov.br/api-de-dados/emendas?ano=2023&autor=${encodeURIComponent(nomeSemAcento)}&pagina=1`, options);
    data = await res.json();
    console.log(`Teste ${nomeSemAcento}:`, data.length, data.length > 0 ? data[0].nomeAutor : '');
    
  } catch (e) {
    console.error('Error fetching Portal da Transparencia API:', e.message);
  }
}

debugEmendasAutor();
