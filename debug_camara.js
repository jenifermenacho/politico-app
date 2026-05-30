const fs = require('fs');

async function checkCamaraApi() {
  const url = `https://dadosabertos.camara.leg.br/api/v2/deputados/204554/despesas`;
  
  try {
    const response = await fetch(url);
    const data = await response.json();
    console.log('Despesas:', JSON.stringify(data).slice(0, 500));
  } catch (e) {
    console.error('Error fetching Camara API:', e.message);
  }
}

checkCamaraApi();
