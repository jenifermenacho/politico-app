const fs = require('fs');

async function testTSEFinance() {
    // try different prestacaodecontas endpoints
    const urls = [
        'https://divulgacandcontas.tse.jus.br/divulga/rest/v1/prestacaodecontas/2040602022/250001651393/consolidacao',
        'https://divulgacandcontas.tse.jus.br/divulga/rest/v1/prestacaodecontas/2040602022/250001651393/receitas',
        'https://divulgacandcontas.tse.jus.br/divulga/rest/v1/prestacaodecontas/2040602022/SP/250001651393/receitas',
        'https://divulgacandcontas.tse.jus.br/divulga/rest/v1/prestacaodecontas/2040602022/SP/250001651393/consolidacao'
    ];
    
    for (const url of urls) {
        try {
            const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
            console.log(`URL: ${url}`);
            console.log("Status:", res.status);
            if(res.ok) {
               const data = await res.json();
               console.log("Data keys:", Object.keys(data));
            }
        } catch(e) {
            console.log("Error:", e.message);
        }
    }
}
testTSEFinance();
