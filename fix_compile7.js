const fs = require('fs');

let file = 'c:/apps/flutter/politico_app/lib/main.dart';
let txt = fs.readFileSync(file, 'utf8');

// Fix the DespesaCategoria getter to use 'nome' instead of 'tipo' or 'categoria'
txt = txt.replace(/d\.tipo/g, 'd.nome');
txt = txt.replace(/d\.categoria/g, 'd.nome');

// Fix the Text widget formatting error. It currently looks like:
// Text("R$ \${d.valor.toStringAsFixed(2).replaceAll('.', ',')}"),
// Let's replace the whole Text line to be safe.
const badTextRegex = /Text\("R\$ \\?\$\{d\.valor\.toStringAsFixed\(2\)\.replaceAll\('.*?', '.*?'\)\}"\),/g;
txt = txt.replace(badTextRegex, "Text('R\\$ ${d.valor.toStringAsFixed(2).replaceAll(\"\\.\", \",\")}'),");
// In case the Regex didn't catch it:
txt = txt.replace(/Text\('R\$ \$\{d\.valor\.toStringAsFixed\(2\)\.replaceAll\(.*?\)\]/g, "Text('R\\$ ${d.valor.toStringAsFixed(2).replaceAll('.', ',')}'),");
// actually let's just do a manual replace of line 1108
let lines = txt.split('\n');
for (let i = 0; i < lines.length; i++) {
   if (lines[i].includes('d.valor.toStringAsFixed')) {
      lines[i] = "                        Text('R\\$ ${d.valor.toStringAsFixed(2).replaceAll(\".\", \",\")}'),";
   }
}
txt = lines.join('\n');

fs.writeFileSync(file, txt);
console.log("Fixed main.dart lines");
