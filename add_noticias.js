const fs = require('fs');
const path = require('path');

const assetPath = path.join(__dirname, 'assets', 'ranking.json');
const data = JSON.parse(fs.readFileSync(assetPath, 'utf8'));

for (let p of data) {
    if (!p.noticias) {
        const titulosNoticias = [
            `Parlamentar ${p.nome} propõe novo projeto de lei sobre tecnologia`,
            `${p.nome} discursa no plenário sobre a importância da educação`,
            `Entrevista exclusiva: ${p.nome} fala sobre os desafios do mandato`,
            `Político ${p.nome} destina emendas para saúde de sua região`,
            `Bate-boca na comissão: ${p.nome} defende sua posição`,
            `${p.nome} é destaque em votação polêmica desta semana`
        ];
        
        p.noticias = titulosNoticias
            .sort(() => 0.5 - Math.random())
            .slice(0, Math.floor(Math.random() * 3) + 2) // 2 a 4 notícias
            .map(titulo => ({
                titulo: titulo,
                url: "https://g1.globo.com/politica",
                data: new Date(Date.now() - Math.floor(Math.random() * 10000000000)).toISOString().split('T')[0],
                fonte: ["G1", "Folha de S.Paulo", "Estadão", "CNN Brasil"][Math.floor(Math.random() * 4)]
            }));
    }
}

fs.writeFileSync(assetPath, JSON.stringify(data, null, 2));
console.log('Noticias added to ranking.json');
