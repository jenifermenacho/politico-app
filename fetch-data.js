const fs = require('fs');
const path = require('path');

// Busca presenças e ausências reais diretamente do site da Câmara.
// A API pública (dadosabertos) não expõe frequência por deputado — os dados
// existem apenas na página HTML de cada parlamentar.
// URL: https://www.camara.leg.br/deputados/{id}?ano={ano}
// Extrai: "Presenças na Câmara X dias" e "Ausências não justificadas X dias"
async function fetchPresencasDeputado(id, ano) {
  try {
    const url = `https://www.camara.leg.br/deputados/${id}?ano=${ano}`;
    const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
    if (!res.ok) return { presencas: 0, ausencias: 0 };
    const html = await res.text();
    const idx = html.indexOf('presencas__section-heading');
    if (idx === -1) return { presencas: 0, ausencias: 0 };
    const section = html.slice(idx, html.indexOf('</section>', idx));
    const text = section.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
    const presencas = parseInt((text.match(/Presen[çc]as na C[âa]mara\s+(\d+)/i) || [])[1] || '0');
    const ausencias = parseInt((text.match(/Aus[êe]ncias n[ãa]o justificadas\s+(\d+)/i) || [])[1] || '0');
    return { presencas, ausencias };
  } catch (e) {
    return { presencas: 0, ausencias: 0 };
  }
}

async function fetchData() {
  try {
    const url = 'https://dadosabertos.camara.leg.br/api/v2/deputados';
    const response = await fetch(url);
    const data = await response.json();
    const deputados = data.dados;

    const ranking = [];
    const chunkSize = 20;

    // Nomes de Votações Polêmicas simuladas
    const votacoesNomes = ["Fim da Escala 6x1", "Reforma Tributária", "Marco Temporal", "Privatização da Eletrobras"];

    for (let i = 0; i < deputados.length; i += chunkSize) {
      const chunk = deputados.slice(i, i + chunkSize);
      const chunkResults = await Promise.all(chunk.map(async deputado => {
        let frentesParlamentaresReais = [];
        let condicaoEleitoral = "Titular";
        try {
          const depRes = await fetch(`https://dadosabertos.camara.leg.br/api/v2/deputados/${deputado.id}`);
          const depData = await depRes.json();
          if (depData && depData.dados && depData.dados.ultimoStatus) {
              condicaoEleitoral = depData.dados.ultimoStatus.condicaoEleitoral || "Titular";
          }
        } catch(e) {}
        
        try {
          const frentesRes = await fetch(`https://dadosabertos.camara.leg.br/api/v2/deputados/${deputado.id}/frentes`);
          const frentesData = await frentesRes.json();
          if (frentesData && frentesData.dados) {
              frentesParlamentaresReais = frentesData.dados.slice(0, 3).map(f => {
                return f.titulo.replace(/Frente Parlamentar (Mista )?(em prol da |em Defesa da |de |do |da )?/g, '').trim();
              });
          }
        } catch (e) {}

        let proposicoesReais = [];
        try {
          const propRes = await fetch(`https://dadosabertos.camara.leg.br/api/v2/proposicoes?idDeputadoAutor=${deputado.id}&ordem=DESC&ordenarPor=id`);
          const propData = await propRes.json();
          if (propData && propData.dados) {
              proposicoesReais = propData.dados.slice(0, 3).map(p => ({
                 siglaTipo: p.siglaTipo,
                 numero: p.numero,
                 ano: p.ano,
                 ementa: p.ementa
              }));
          }
        } catch (e) {}

        // DADOS REAIS: Despesas por ano
        let despesasPorAno = {};
        const anos = [2023, 2024, 2025, 2026];

        for (const anoIter of anos) {
            let despesasCategorias = {};
            let gastosTotal = 0;
            try {
              let pagina = 1;
              let temMaisPaginas = true;
              while (temMaisPaginas && pagina <= 10) { // Limit pages per year
                const despesasRes = await fetch(`https://dadosabertos.camara.leg.br/api/v2/deputados/${deputado.id}/despesas?ano=${anoIter}&itens=100&pagina=${pagina}`);
                const despesasData = await despesasRes.json();
                if (despesasData && despesasData.dados && despesasData.dados.length > 0) {
                    despesasData.dados.forEach(d => {
                        const tipo = d.tipoDespesa;
                        const valor = d.valorLiquido;
                        gastosTotal += valor;
                        despesasCategorias[tipo] = (despesasCategorias[tipo] || 0) + valor;
                    });
                    pagina++;
                } else {
                    temMaisPaginas = false;
                }
              }
            } catch (e) {}
            
            const maioresDespesas = Object.entries(despesasCategorias)
                .map(([nome, valor]) => ({ nome, valor }))
                .sort((a, b) => b.valor - a.valor)
                .slice(0, 5);
            
                // DADOS REAIS: Presenças e Ausências via site da Câmara
            const { presencas, ausencias } = await fetchPresencasDeputado(deputado.id, anoIter);

            despesasPorAno[anoIter] = {
                gastos: parseFloat(gastosTotal.toFixed(2)),
                despesas: maioresDespesas,
                presencas: presencas,
                ausencias: ausencias,
            };
        }

        // MOCK: Siga o Dinheiro (Financiamento)
        const totalCampanha = (Math.random() * 2000000 + 100000).toFixed(2);
        const p1 = Math.floor(Math.random() * 60) + 20;
        const p2 = Math.floor(Math.random() * (100 - p1));
        const p3 = 100 - p1 - p2;
        const fontesFinanciamento = [
          { nome: "Fundo Eleitoral", porcentagem: p1 },
          { nome: "Doações Pessoas Físicas", porcentagem: p2 },
          { nome: "Autofinanciamento", porcentagem: p3 },
        ].sort((a, b) => b.porcentagem - a.porcentagem);

        // MOCK: Votações
        const votacoes = votacoesNomes.map(v => ({
            nome: v,
            votouSim: Math.random() > 0.5
        }));

        const temasPrincipais = ["Isenção Fiscal", "Privatização", "Meio Ambiente", "Segurança Pública", "Direitos Humanos"]
            .sort(() => 0.5 - Math.random()).slice(0, 3);

        // MOCK: Secretários Parlamentares (Deputados: limite de 25)
        const qtdSecretarios = Math.floor(Math.random() * (25 - 10 + 1)) + 10;
        const gastoSecretarios = (Math.random() * (120000 - 80000) + 80000).toFixed(2);

        // MOCK: Evolução Patrimonial (2018 e 2022)
        const patrimonio2018 = Math.random() * 500000 + 100000;
        const crescimento = 1 + (Math.random() * 0.5 - 0.1); // Crescimento de -10% a +40%
        const patrimonio2022 = patrimonio2018 * crescimento;

        // MOCK: Emendas Parlamentares
        const totalEmendas = (Math.random() * 20000000 + 5000000).toFixed(2); // 5M a 25M
        const emendasAreas = ["Saúde", "Infraestrutura", "Educação", "Segurança", "Cultura", "Esporte", "Assistência Social"]
            .sort(() => 0.5 - Math.random())
            .slice(0, 3);
        let emendasPercentuais = [Math.floor(Math.random() * 30 + 40)]; // 40-70%
        emendasPercentuais.push(Math.floor(Math.random() * (90 - emendasPercentuais[0]) + 10));
        emendasPercentuais.push(100 - emendasPercentuais[0] - emendasPercentuais[1]);
        
        const emendas = {
            totalDestinado: parseFloat(totalEmendas),
            areas: emendasAreas.map((area, idx) => ({
                nome: area,
                porcentagem: emendasPercentuais[idx]
            }))
        };

        // MOCK: Na Mídia (Notícias)
        const titulosNoticias = [
            `Parlamentar ${deputado.nome} propõe novo projeto de lei sobre tecnologia`,
            `${deputado.nome} discursa no plenário sobre a importância da educação`,
            `Entrevista exclusiva: ${deputado.nome} fala sobre os desafios do mandato`,
            `Deputado ${deputado.nome} destina emendas para saúde de sua região`,
            `Bate-boca na comissão: ${deputado.nome} defende sua posição`,
            `${deputado.nome} é destaque em votação polêmica desta semana`
        ];
        const noticias = titulosNoticias
            .sort(() => 0.5 - Math.random())
            .slice(0, Math.floor(Math.random() * 3) + 2) // 2 a 4 notícias
            .map(titulo => ({
                titulo: titulo,
                url: "https://g1.globo.com/politica",
                data: new Date(Date.now() - Math.floor(Math.random() * 10000000000)).toISOString().split('T')[0], // data recente aleatória
                fonte: ["G1", "Folha de S.Paulo", "Estadão", "CNN Brasil"][Math.floor(Math.random() * 4)]
            }));

        return {
          id: deputado.id,
          nome: deputado.nome,
          partido: deputado.siglaPartido,
          estado: deputado.siglaUf,
          cargo: 'Deputado Federal',
          condicao: condicaoEleitoral,
          foto: deputado.urlFoto,
          dadosPorAno: despesasPorAno,
          patrimonio: {
              anoAnterior: 2018,
              valorAnterior: patrimonio2018,
              anoAtual: 2022,
              valorAtual: patrimonio2022
          },
          financiamento: {
              totalGasto: parseFloat(totalCampanha),
              fontes: fontesFinanciamento
          },
          emendas: emendas,
          noticias: noticias,
          secretarios: {
              quantidade: qtdSecretarios,
              gastoMensal: parseFloat(gastoSecretarios)
          },
          votacoes: votacoes,
          frentesParlamentares: frentesParlamentaresReais,
          proposicoes: proposicoesReais,
          temasPrincipais: temasPrincipais
        };
      }));
      ranking.push(...chunkResults);
      console.log(`Processados ${ranking.length} deputados...`);
    }

    const assetPath = path.join(__dirname, 'assets', 'ranking.json');
    fs.writeFileSync(assetPath, JSON.stringify(ranking, null, 2));
    console.log('Arquivo assets/ranking.json gerado com sucesso!');
  } catch (error) {
    console.error('Erro ao buscar dados:', error);
    process.exit(1);
  }
}

fetchData();
