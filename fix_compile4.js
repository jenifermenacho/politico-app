const fs = require('fs');

let file = 'c:/apps/flutter/politico_app/lib/main.dart';
let txt = fs.readFileSync(file, 'utf8');

// Remove _buildSecretariosCard call and method entirely since we aren't showing it anymore.
txt = txt.replace(/_buildSecretariosCard\(\),\n/g, '');
txt = txt.replace(/Widget _buildSecretariosCard\(\) \{[\s\S]*?Widget _buildEmendasCard/g, 'Widget _buildEmendasCard');

// Remove _getCorNota method entirely
txt = txt.replace(/Color _getCorNota\(double nota\) \{[\s\S]*?\}\n/g, '');

// Fix unused variable corIndicador
txt = txt.replace(/final corIndicador = Colors\.grey;\n/g, '');

fs.writeFileSync(file, txt);

let pdfFile = 'c:/apps/flutter/politico_app/lib/pdf_generator.dart';
let pdfTxt = fs.readFileSync(pdfFile, 'utf8');
// Fix unused variable secondaryColor
pdfTxt = pdfTxt.replace(/final secondaryColor = const Color\(0xFFF3F4F6\);\n/g, '');
fs.writeFileSync(pdfFile, pdfTxt);

console.log("Cleanup finished.");
