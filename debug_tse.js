const fs = require('fs');

async function testTSEList() {
    const url = 'https://divulgacandcontas.tse.jus.br/divulga/rest/v1/candidatura/listar/2022/SP/2040602022/6/candidatos';
    try {
        const res = await fetch(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0'
            }
        });
        console.log("TSE List Status:", res.status);
        if(res.ok) {
           const data = await res.json();
           console.log("TSE SP Deputados Federais:", data.candidatos.length);
           console.log("Exemplo:", data.candidatos[0].nomeUrna, "ID:", data.candidatos[0].idCandidato);
        } else {
           console.log(await res.text());
        }
    } catch(e) {
        console.log("TSE Error:", e.message);
    }
}
testTSEList();
