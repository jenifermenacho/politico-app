import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:politico_app/main.dart'; // import Politico class

class PdfGenerator {
  static Future<void> gerarDossie(Politico politico) async {
    final pdf = pw.Document();

    // Define colors
    final primaryColor = PdfColor.fromHex('#4B39EF');
    final dangerColor = PdfColor.fromHex('#E74C3C');
    final successColor = PdfColor.fromHex('#2ECC71');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dossiê Político',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.Text(
                    'Gerado em: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Profile
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    politico.nome,
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${politico.cargo} - ${politico.partido} - ${politico.estado}',
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Stats (Presenças / Gastos)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                                                _buildStatBox('Gastos Cota (2023)', 'R\$ ${(politico.getGastos(2023)/1000).toStringAsFixed(1)}k', dangerColor),
              ],
            ),
            pw.SizedBox(height: 20),

            // Patrimônio
            if (politico.patrimonio != null) ...[
              pw.Text('Patrimônio Declarado (TSE)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Bens declarados em ${politico.patrimonio!.anoAtual}: R\$ ${politico.patrimonio!.valorAtual.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
            ],

            // Votações
            if (politico.votacoes.isNotEmpty) ...[
              pw.Text('Votações Polêmicas', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...politico.votacoes.take(5).map((v) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: pw.Text('- ${v.nome}')),
                    pw.Text(
                      v.votouSim ? 'Sim' : 'Não',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: v.votouSim ? successColor : dangerColor
                      )
                    ),
                  ],
                ),
              )),
              pw.SizedBox(height: 20),
            ],

            // Na Mídia (Notícias)
            if (politico.noticias.isNotEmpty) ...[
              pw.Text('Na Mídia (Últimas Notícias)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...politico.noticias.take(3).map((n) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ${n.titulo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('  Publicado em ${n.data} por ${n.fonte}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ]
                )
              )),
            ],
            
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'Baixe o app Dossiê Político para fiscalizar mais políticos de forma transparente.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center
              ),
            ),
          ];
        },
      ),
    );

    // Share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'dossie_${politico.nome.replaceAll(" ", "_").toLowerCase()}.pdf',
    );
  }

  static pw.Widget _buildStatBox(String title, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
