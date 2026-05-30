const fs = require('fs');
const file = 'c:/apps/flutter/politico_app/lib/main.dart';
let txt = fs.readFileSync(file, 'utf8');

// Fix: Too many positional arguments: 0 expected, but 1 found - lib\main.dart:1031:38
// Probably _buildDespesasCard() is being called with an argument in build()
// e.g., _buildDespesasCard(_anoSelecionado)
txt = txt.replace(/_buildDespesasCard\(.*?\)/g, '_buildDespesasCard()');
txt = txt.replace(/_buildNoticiasCard\(.*?\)/g, '_buildNoticiasCard()');

// Fix: The getter 'categoria' isn't defined for the type 'DespesaCategoria'
// It's `tipo` in the model:
txt = txt.replace(/d\.categoria/g, 'd.tipo');

// Fix: Expected an identifier
// Text('R$ ${d.valor.toStringAsFixed(2).replaceAll('.', ',')}'),
// Dart doesn't like '.' inside string interpolation when surrounded by single quotes without proper escaping, but wait, the string is inside `${}`. 
// Ah, `replaceAll('.', ',')` uses single quotes inside a single-quoted string `Text('R$ ... ')`!
// I'll change the outer to double quotes.
txt = txt.replace(/'R\$ \$\\\{d\.valor\.toStringAsFixed\(2\)\.replaceAll\('.', ','\)\}'/g, '"R$ \\${d.valor.toStringAsFixed(2).replaceAll(\'.\', \',\')}"');

// Also remove `corIndicador` unused variable on 2092
txt = txt.replace(/final corIndicador = Colors\.grey;\n/g, '');

fs.writeFileSync(file, txt);
console.log("Fixed last errors");
