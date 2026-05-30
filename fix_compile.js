const fs = require('fs');

const mainFile = 'c:/apps/flutter/politico_app/lib/main.dart';
let txt = fs.readFileSync(mainFile, 'utf8');

// Remover erro linha 261 (presencas, score na criacao de DadosAno mockado em fetch_test ou similar)
txt = txt.replace(/presencas: \d+,/g, '');
txt = txt.replace(/score: \d+\.\d+,/g, '');

// Remover getters que causaram erro ou injetar getters validos temporarios para não quebrar a ordem?
// Vamos remover o UI que dependia deles em main.dart
txt = txt.replace(/final presencas = politico\.getPresencas\(ano\);\n/g, '');
txt = txt.replace(/final corIndicador = _getCorNota\(politico\.getNota\(ano\)\);\n/g, '');
// Para o Ranking (lista.fold)
txt = txt.replace(/lista\.fold<double>\(0, \(sum, p\) => sum \+ p\.getNota\(2023\)\) \/ lista\.length/g, '0.0');

// E injetar os métodos de volta na classe Politico (mas retornando nulo ou 0) 
// para evitar refatorar 50 linhas de ranking UI (que será apenas removida do layout).
const metodoInjetar = `
  double getNota(int ano) => 0.0;
  int getPresencas(int ano) => 0;
  SecretariosInfo? get secretarios => null;
`;

// A classe SecretariosInfo foi deletada, entao vamos voltar com ela vazia so pra tipagem
const fakeClasses = `
class SecretariosInfo {
  final int totalGasto = 0;
}
`;

txt = txt.replace(/class Politico \{/, fakeClasses + '\nclass Politico {\n' + metodoInjetar);

fs.writeFileSync(mainFile, txt);

// Em pdf_generator.dart, vamos apagar as estatísticas de nota e presenca
const pdfFile = 'c:/apps/flutter/politico_app/lib/pdf_generator.dart';
let pdfTxt = fs.readFileSync(pdfFile, 'utf8');
pdfTxt = pdfTxt.replace(/_buildStatBox\('Nota Geral.*?,\n/g, '');
pdfTxt = pdfTxt.replace(/_buildStatBox\('Presenças.*?,\n/g, '');
fs.writeFileSync(pdfFile, pdfTxt);

console.log("Refatoração de limpeza UI aplicada.");
