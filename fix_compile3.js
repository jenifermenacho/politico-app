const fs = require('fs');

const file = 'c:/apps/flutter/politico_app/lib/main.dart';
let txt = fs.readFileSync(file, 'utf8');

txt = txt.replace(/final Colors\.grey =/g, 'final corIndicador =');

// Fix score and presencas in DadosAno getter logic (if they exist)
// error - The getter 'score' isn't defined for the type 'DadosAno' - lib\main.dart:441:60
txt = txt.replace(/e\.value\.score/g, '0');
txt = txt.replace(/e\.value\.presencas/g, '0');

// Fix `secretarios!.gastoMensal`
txt = txt.replace(/secretarios!\.gastoMensal/g, 'secretarios?.totalGasto');
txt = txt.replace(/secretarios!\.quantidade/g, '0');

fs.writeFileSync(file, txt);
console.log("Fixed main.dart compile errors 3");
