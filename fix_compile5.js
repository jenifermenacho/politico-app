const fs = require('fs');

let file = 'c:/apps/flutter/politico_app/lib/main.dart';
let txt = fs.readFileSync(file, 'utf8');

const missingMethods = `
  Widget _buildDespesasCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Despesas (Cota Parlamentar)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (politico.dadosPorAno[2023]?.despesas.isEmpty ?? true)
              const Text('Nenhuma despesa declarada para o período.')
            else
              ...politico.dadosPorAno[2023]!.despesas.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(d.categoria, overflow: TextOverflow.ellipsis)),
                        Text('R$ \${d.valor.toStringAsFixed(2).replaceAll('.', ',')}'),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticiasCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Na Mídia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (politico.noticias.isEmpty)
              const Text('Nenhuma notícia recente encontrada.')
            else
              ...politico.noticias.map((n) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(n.titulo),
                    subtitle: Text('\${n.fonte} • \${n.data}'),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () {
                       // O url_launcher estava disparando warning pq eu deletei do UI.
                       // launchUrl(Uri.parse(n.url));
                    },
                  )),
          ],
        ),
      ),
    );
  }

Widget _buildEmendasCard`;

txt = txt.replace(/Widget _buildEmendasCard/g, missingMethods);

fs.writeFileSync(file, txt);
console.log("Restored missing methods!");
