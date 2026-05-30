const fs = require('fs');
const path = require('path');

const assetPath = path.join(__dirname, 'assets', 'ranking.json');

async function fetchVotacoes() {
    if (!fs.existsSync(assetPath)) {
        console.error('ranking.json not found!');
        return;
    }

    const ranking = JSON.parse(fs.readFileSync(assetPath, 'utf8'));
    console.log(`Iniciando busca de Votações Polêmicas reais na Câmara...`);

    // Votações Históricas de Grande Repercussão
    const polemicas = [
        {
            id: '2196833-373', // PEC 45/2019
            nome: 'Reforma Tributária (PEC 45)'
        },
        {
            id: '2358873-125', // Arcabouço Fiscal
            nome: 'Novo Arcabouço Fiscal'
        },
        {
            id: '345311-209', // PL 490/2007 Marco Temporal
            nome: 'Marco Temporal (Terras Indígenas)'
        }
    ];

    // Limpar os mocks antigos de todos
    for (const p of ranking) {
        p.votacoes = [];
    }

    let atualizados = 0;

    for (const pol of polemicas) {
        try {
            console.log(`Buscando votos da ${pol.nome}...`);
            const res = await fetch(`https://dadosabertos.camara.leg.br/api/v2/votacoes/${pol.id}/votos`);
            if (res.ok) {
                const vData = await res.json();
                for (const voto of vData.dados) {
                    // Trata a estrutura (deputado_)
                    const deputado = voto.deputado_ || voto.parlamentar;
                    if (!deputado) continue;
                    
                    const nomeNorm = deputado.nome.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase();
                    
                    // Acha na nossa base
                    const match = ranking.find(p => p.nome.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase() === nomeNorm || p.nome.toUpperCase().includes(nomeNorm));
                    
                    if (match) {
                        const votouSim = voto.tipoVoto.trim().toLowerCase() === 'sim';
                        match.votacoes.push({
                            nome: pol.nome,
                            votouSim: votouSim
                        });
                        atualizados++;
                    }
                }
            }
            await new Promise(r => setTimeout(r, 1000));
        } catch(e) {
            console.error(`Erro na votacao ${pol.id}:`, e.message);
        }
    }

    fs.writeFileSync(assetPath, JSON.stringify(ranking, null, 2));
    console.log(`\nFinalizado! Registrados ${atualizados} votos reais cruzados com os políticos da base.`);
}

fetchVotacoes();
