const fs = require('fs');
const path = require('path');

async function fetchSenadores() {
  try {
    const url = 'https://legis.senado.leg.br/dadosabertos/senador/lista/atual.json';
    const response = await fetch(url);
    const data = await response.json();
    
    // Senado API returns data in: ListaParlamentarEmExercicio.Parlamentares.Parlamentar
    let senadoresApi = data?.ListaParlamentarEmExercicio?.Parlamentares?.Parlamentar;
    if (!senadoresApi) {
        throw new Error('Formato da API do Senado mudou.');
    }

    // Nomes de Votações Polêmicas simuladas (PEC 6x1 ainda não foi pro Senado)
    const votacoesNomes = ["PEC das Drogas", "Reforma Tributária", "Marco Temporal", "Arcabouço Fiscal"];

    const senadoresGerados = senadoresApi.map(senadorWrapper => {
        const p = senadorWrapper.IdentificacaoParlamentar;
        const mandato = senadorWrapper.Mandato || {};
        
        let despesasPorAno = {};
        const anos = [2023, 2024, 2025, 2026];
        
        for (const anoIter of anos) {
            // Mock de Despesas para Senadores (geralmente gastam mais que deputados, vamos usar valores parecidos)
            let gastosTotal = Math.random() * 300000 + 50000; 
            
            const despesasCategorias = {
                "Passagens aéreas": gastosTotal * 0.4,
                "Divulgação da atividade parlamentar": gastosTotal * 0.3,
                "Manutenção de escritório": gastosTotal * 0.2,
                "Combustíveis": gastosTotal * 0.1
            };
            
            const maioresDespesas = Object.entries(despesasCategorias)
                .map(([nome, valor]) => ({ nome, valor }))
                .sort((a, b) => b.valor - a.valor)
                .slice(0, 5);
            
            // Mock Presenças e notas
            const presencas = Math.floor(Math.random() * (100 - 50 + 1) + 50); 
            const ausencias = Math.floor(Math.random() * 20); 
            const assiduidadeScore = (presencas / (presencas + ausencias)) * 5;
            const economiaScore = Math.max(0, (1 - (gastosTotal / 500000)) * 5);
            const score = parseFloat((assiduidadeScore + economiaScore).toFixed(1));

            despesasPorAno[anoIter] = {
                gastos: parseFloat(gastosTotal.toFixed(2)),
                despesas: maioresDespesas,
                presencas: presencas,
                ausencias: ausencias,
                score: score
            };
        }

        // MOCK: Siga o Dinheiro (Financiamento - Senado tem campanhas mais caras)
        const totalCampanha = (Math.random() * 5000000 + 1000000).toFixed(2);
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

        const temasPossiveis = ["Economia", "Educação", "Meio Ambiente", "Segurança Pública", "Direitos Humanos", "Saúde", "Infraestrutura"];
        const temasPrincipais = temasPossiveis.sort(() => 0.5 - Math.random()).slice(0, 3);
        
        const frentesPossiveis = ["Agropecuária", "Empreendedorismo", "Defesa do Consumidor", "Educação", "Segurança"];
        const frentesParlamentaresReais = frentesPossiveis.sort(() => 0.5 - Math.random()).slice(0, 2);
        
        const proposicoesReais = [
            { siglaTipo: "PLS", numero: Math.floor(Math.random() * 500) + 1, ano: 2023, ementa: "Altera a legislação vigente." },
            { siglaTipo: "PEC", numero: Math.floor(Math.random() * 100) + 1, ano: 2024, ementa: "Propõe emenda à constituição." }
        ];

        // MOCK: Secretários Parlamentares (Senadores: limite elástico, simularemos entre 20 e 55)
        const qtdSecretarios = Math.floor(Math.random() * (55 - 20 + 1)) + 20;
        const gastoSecretarios = (Math.random() * (250000 - 100000) + 100000).toFixed(2);

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

        // MOCK: Ficha Limpa e Processos
        // 85% de chance de ser ficha limpa
        const isFichaLimpa = Math.random() > 0.15;
        const processosLista = ["Improbidade Administrativa", "Corrupção Passiva", "Crimes Eleitorais", "Lavagem de Dinheiro", "Abuso de Poder Político"];
        const processos = isFichaLimpa ? [] : processosLista.sort(() => 0.5 - Math.random()).slice(0, Math.floor(Math.random() * 3) + 1);

        // MOCK: Na Mídia (Notícias)
        const titulosNoticias = [
            `Senador ${p.NomeParlamentar} propõe novo projeto de lei sobre tecnologia`,
            `${p.NomeParlamentar} discursa no plenário sobre a importância da educação`,
            `Entrevista exclusiva: ${p.NomeParlamentar} fala sobre os desafios do mandato`,
            `Senador ${p.NomeParlamentar} destina emendas para saúde de sua região`,
            `Bate-boca na comissão: ${p.NomeParlamentar} defende sua posição`,
            `${p.NomeParlamentar} é destaque em votação polêmica desta semana`
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
          id: parseInt(p.CodigoParlamentar, 10),
          nome: p.NomeParlamentar,
          cargo: 'Senador', // Importante para o app Flutter
          partido: p.SiglaPartidoParlamentar,
          estado: p.UfParlamentar,
          condicao: mandato.DescricaoParticipacao || 'Titular',
          foto: p.UrlFotoParlamentar,
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
    });

    console.log(`Processados ${senadoresGerados.length} senadores.`);

    const assetPath = path.join(__dirname, 'assets', 'ranking.json');
    let rankingExistente = [];
    
    if (fs.existsSync(assetPath)) {
        const arquivoTxt = fs.readFileSync(assetPath, 'utf8');
        rankingExistente = JSON.parse(arquivoTxt);
        // Remove senadores antigos se existirem, mantém apenas deputados e outros
        rankingExistente = rankingExistente.filter(pol => pol.cargo !== 'Senador');
    }

    const rankingAtualizado = [...rankingExistente, ...senadoresGerados];
    fs.writeFileSync(assetPath, JSON.stringify(rankingAtualizado, null, 2));
    
    console.log('Arquivo assets/ranking.json atualizado com os senadores com sucesso!');
  } catch (error) {
    console.error('Erro ao buscar senadores:', error);
    process.exit(1);
  }
}

fetchSenadores();
