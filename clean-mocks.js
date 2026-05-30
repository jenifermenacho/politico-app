const fs = require('fs');
const path = require('path');

const assetPath = path.join(__dirname, 'assets', 'ranking.json');
const data = JSON.parse(fs.readFileSync(assetPath, 'utf8'));

console.log(`Limpando dados mocados de ${data.length} políticos...`);

let cleaned = {
  emendas: 0,
  temasPrincipais: 0,
  score: 0,
  patrimonioAnterior: 0,
  presencasSenador: 0,
};

for (const p of data) {
  // 1. Remover emendas (100% mock)
  if (p.emendas) {
    delete p.emendas;
    cleaned.emendas++;
  }

  // 2. Remover temasPrincipais (100% mock)
  if (p.temasPrincipais) {
    delete p.temasPrincipais;
    cleaned.temasPrincipais++;
  }

  // 3. Corrigir patrimonio: remover valorAnterior/anoAnterior mockados
  if (p.patrimonio) {
    delete p.patrimonio.valorAnterior;
    delete p.patrimonio.anoAnterior;
    cleaned.patrimonioAnterior++;
  }

  // 4. Remover score e presencas/ausencias mocados dos dadosPorAno
  if (p.dadosPorAno) {
    for (const ano of Object.keys(p.dadosPorAno)) {
      const d = p.dadosPorAno[ano];

      // Score é sempre mock (gerado aleatoriamente)
      if (d.score !== undefined) {
        delete d.score;
        cleaned.score++;
      }

      // Para SENADORES: presencas e ausencias são mock
      if (p.cargo === 'Senador') {
        delete d.presencas;
        delete d.ausencias;
        cleaned.presencasSenador++;
      }
    }
  }

  // 5. Remover campos root-level residuais que já foram nullificados
  if (p.presencas !== undefined) delete p.presencas;
  if (p.score !== undefined) delete p.score;
}

fs.writeFileSync(assetPath, JSON.stringify(data, null, 2));

console.log('\n=== RELATÓRIO DE LIMPEZA ===');
console.log(`Emendas removidas: ${cleaned.emendas}`);
console.log(`TemasPrincipais removidos: ${cleaned.temasPrincipais}`);
console.log(`Patrimonio.valorAnterior removidos: ${cleaned.patrimonioAnterior}`);
console.log(`Score removidos: ${cleaned.score}`);
console.log(`Presencas/Ausencias de senadores removidos: ${cleaned.presencasSenador}`);
console.log('\nLimpeza concluída!');
