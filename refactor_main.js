const fs = require('fs');

const file = 'c:/apps/flutter/politico_app/lib/main.dart';
let txt = fs.readFileSync(file, 'utf8');

// Remover classes e imports não usados
txt = txt.replace(/class SecretariosInfo \{[\s\S]*?\}\n\n/g, '');
txt = txt.replace(/class FinanciamentoInfo \{[\s\S]*?\}\n\n/g, '');
txt = txt.replace(/class FonteFinanciamento \{[\s\S]*?\}\n\n/g, '');

// Remover fields de Politico
txt = txt.replace(/final FinanciamentoInfo financiamento;\n/g, '');
txt = txt.replace(/final SecretariosInfo secretarios;\n/g, '');
txt = txt.replace(/required this\.financiamento,\n/g, '');
txt = txt.replace(/required this\.secretarios,\n/g, '');
txt = txt.replace(/secretarios: SecretariosInfo\.fromJson\(json\['secretarios'\] \?\? \{\}\),\n/g, '');
txt = txt.replace(/financiamento: FinanciamentoInfo\.fromJson\(json\['financiamento'\] \?\? \{\}\),\n/g, '');

// DadosDoAno
txt = txt.replace(/final double score;\n/g, '');
txt = txt.replace(/final int presencas;\n/g, '');
txt = txt.replace(/required this\.score,\n/g, '');
txt = txt.replace(/required this\.presencas,\n/g, '');
txt = txt.replace(/score: \(json\['score'\] \?\? 0\)\.toDouble\(\),\n/g, '');
txt = txt.replace(/presencas: json\['presencas'\] \?\? 0,\n/g, '');

// Métodos helpers em Politico
txt = txt.replace(/double getNota\(int ano\) => dadosPorAno\[ano\]\?\.score \?\? 0\.0;\n/g, '');
txt = txt.replace(/int getPresencas\(int ano\) => dadosPorAno\[ano\]\?\.presencas \?\? 0;\n/g, '');
// txt = txt.replace(/double get notaGeral \{[\s\S]*?\}\n/g, ''); // Cuidado com regex greedy

// Ui removes
txt = txt.replace(/_buildFinanciamentoCard\(\),\n/g, '');
txt = txt.replace(/Widget _buildFinanciamentoCard\(\) \{[\s\S]*?\}\n\n/g, '');
txt = txt.replace(/Widget _buildGabineteCard\(\) \{[\s\S]*?\}\n\n/g, '');
txt = txt.replace(/_buildGabineteCard\(\),\n/g, '');

fs.writeFileSync(file, txt);
console.log("Refatorado main.dart!");
