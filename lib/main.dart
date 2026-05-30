import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:politico_app/pdf_generator.dart';
import 'package:url_launcher/url_launcher.dart';

final ValueNotifier<Set<int>> favoriteNotifier = ValueNotifier<Set<int>>({});
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);
final ValueNotifier<int> currentTabNotifier = ValueNotifier<int>(0);
final ValueNotifier<List<Politico>> comparacaoNotifier =
    ValueNotifier<List<Politico>>([]);

Future<void> loadFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('favoritos') ?? [];
  favoriteNotifier.value = list.map((e) => int.parse(e)).toSet();
  final themeStr = prefs.getString('theme') ?? 'system';
  if (themeStr == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (themeStr == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }
}

Future<void> toggleTheme() async {
  final prefs = await SharedPreferences.getInstance();
  // Basic toggle logic: if it's currently light, make it dark, else light.
  final isDark =
      themeNotifier.value == ThemeMode.dark ||
      (themeNotifier.value == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);
  themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  await prefs.setString('theme', isDark ? 'light' : 'dark');
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark =
            mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark);
        return IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: toggleTheme,
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );
    _pulse = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl.forward().then((_) => _textCtrl.forward());
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00BFA5), Color(0xFF00695C)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: CustomPaint(
                          painter: _BalanceScalePainter(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    const Text(
                      'Fiscaliza',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'P O L Í T I C O',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 52),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Carregando dados...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceScalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Pole
    canvas.drawLine(Offset(w * .50, h * .06), Offset(w * .50, h * .84), stroke);
    // Base
    canvas.drawLine(Offset(w * .18, h * .84), Offset(w * .82, h * .84), stroke);
    // Beam
    canvas.drawLine(Offset(w * .06, h * .28), Offset(w * .94, h * .28), stroke);

    // Left chain
    canvas.drawLine(Offset(w * .14, h * .28), Offset(w * .06, h * .50), stroke);
    canvas.drawLine(Offset(w * .06, h * .28), Offset(w * .14, h * .50), stroke);
    // Right chain
    canvas.drawLine(Offset(w * .86, h * .28), Offset(w * .94, h * .50), stroke);
    canvas.drawLine(Offset(w * .94, h * .28), Offset(w * .86, h * .50), stroke);

    // Left pan (bowl)
    final leftBowl = Path()
      ..moveTo(w * .02, h * .50)
      ..quadraticBezierTo(w * .10, h * .66, w * .18, h * .50);
    canvas.drawPath(leftBowl, stroke);
    canvas.drawLine(Offset(w * .02, h * .50), Offset(w * .18, h * .50), stroke);

    // Right pan (bowl)
    final rightBowl = Path()
      ..moveTo(w * .82, h * .50)
      ..quadraticBezierTo(w * .90, h * .66, w * .98, h * .50);
    canvas.drawPath(rightBowl, stroke);
    canvas.drawLine(Offset(w * .82, h * .50), Offset(w * .98, h * .50), stroke);

    // Pivot circles
    canvas.drawCircle(Offset(w * .50, h * .06), 3.5, fill);
    canvas.drawCircle(Offset(w * .50, h * .28), 2.8, fill);
    // Beam end dots
    canvas.drawCircle(Offset(w * .06, h * .28), 2.2, fill);
    canvas.drawCircle(Offset(w * .94, h * .28), 2.2, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> toggleFavorite(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final current = Set<int>.from(favoriteNotifier.value);
  if (current.contains(id)) {
    current.remove(id);
  } else {
    current.add(id);
  }
  await prefs.setStringList(
    'favoritos',
    current.map((e) => e.toString()).toList(),
  );
  favoriteNotifier.value = current;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadFavorites();
  runApp(const MyApp());
}

void _mostrarLegenda(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Entenda o Ranking',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cores da Nota:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Verde: Nota >= 8.0'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Laranja: Nota >= 5.0 e < 8.0'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(width: 16, height: 16, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Vermelho: Nota < 5.0'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Como a nota é calculada?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('A nota final (0 a 10) é a soma de duas métricas:'),
            const SizedBox(height: 4),
            const Text(
              '1. Assiduidade (Até 5 pts): Proporção de presenças nas sessões do plenário.',
            ),
            const SizedBox(height: 4),
            const Text(
              '2. Economia (Até 5 pts): Bônus dado a deputados que economizaram mais a Cota Parlamentar no ano.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ENTENDI'),
        ),
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Fiscaliza Político',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00BFA5),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF00BFA5),
              foregroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.grey.shade100,
            brightness: Brightness.light,
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4DD0E1),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E2E),
              foregroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            brightness: Brightness.dark,
            cardColor: const Color(0xFF1E1E2E),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E2E),
              selectedItemColor: Color(0xFF4DD0E1),
              unselectedItemColor: Colors.grey,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          themeMode: currentThemeMode,
          home: const TelaPrincipal(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class DespesaCategoria {
  final String nome;
  final double valor;
  DespesaCategoria({required this.nome, required this.valor});
  factory DespesaCategoria.fromJson(Map<String, dynamic> json) {
    return DespesaCategoria(
      nome: json['nome'],
      valor: (json['valor'] ?? 0).toDouble(),
    );
  }
}

class Votacao {
  final String nome;
  final bool votouSim;
  Votacao({required this.nome, required this.votouSim});
  factory Votacao.fromJson(Map<String, dynamic> json) {
    return Votacao(nome: json['nome'], votouSim: json['votouSim'] ?? false);
  }
}

class Proposicao {
  final String siglaTipo;
  final int numero;
  final int ano;
  final String ementa;
  Proposicao({
    required this.siglaTipo,
    required this.numero,
    required this.ano,
    required this.ementa,
  });
  factory Proposicao.fromJson(Map<String, dynamic> json) {
    return Proposicao(
      siglaTipo: json['siglaTipo'] ?? '',
      numero: json['numero'] ?? 0,
      ano: json['ano'] ?? 0,
      ementa: json['ementa'] ?? '',
    );
  }
}

class DadosAno {
  final double gastos;
  final int sessoesPresente;
  final int ausencias;
  final List<DespesaCategoria> despesas;

  DadosAno({
    required this.gastos,
    required this.sessoesPresente,
    required this.ausencias,
    required this.despesas,
  });

  factory DadosAno.fromJson(Map<String, dynamic> json) {
    return DadosAno(
      gastos: (json['gastos'] ?? 0).toDouble(),
      sessoesPresente: (json['presencas'] ?? 0).toInt(),
      ausencias: (json['ausencias'] ?? 0).toInt(),
      despesas: (json['despesas'] as List? ?? [])
          .map((i) => DespesaCategoria.fromJson(i))
          .toList(),
    );
  }
}

class EmendaArea {
  final String nome;
  final int porcentagem;

  EmendaArea({required this.nome, required this.porcentagem});

  factory EmendaArea.fromJson(Map<String, dynamic> json) {
    return EmendaArea(
      nome: json['nome'] ?? '',
      porcentagem: json['porcentagem'] ?? 0,
    );
  }
}

class EmendasInfo {
  final double totalDestinado;
  final List<EmendaArea> areas;

  EmendasInfo({required this.totalDestinado, required this.areas});

  factory EmendasInfo.fromJson(Map<String, dynamic> json) {
    var areasJson = json['areas'] as List? ?? [];
    return EmendasInfo(
      totalDestinado: (json['totalDestinado'] ?? 0).toDouble(),
      areas: areasJson.map((i) => EmendaArea.fromJson(i)).toList(),
    );
  }
}

class Noticia {
  final String titulo;
  final String url;
  final String data;
  final String fonte;

  Noticia({
    required this.titulo,
    required this.url,
    required this.data,
    required this.fonte,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    return Noticia(
      titulo: json['titulo'] ?? '',
      url: json['url'] ?? '',
      data: json['data'] ?? '',
      fonte: json['fonte'] ?? '',
    );
  }
}

class PatrimonioInfo {
  final int anoAtual;
  final double valorAtual;

  PatrimonioInfo({
    required this.anoAtual,
    required this.valorAtual,
  });

  factory PatrimonioInfo.fromJson(Map<String, dynamic> json) {
    return PatrimonioInfo(
      anoAtual: json['anoAtual'] ?? 0,
      valorAtual: (json['valorAtual'] ?? 0).toDouble(),
    );
  }
}


class SecretariosInfo {
  final int totalGasto = 0;
}

class Politico {

  double getNota(int ano) => 0.0;
  int getPresencas(int ano) => dadosPorAno[ano]?.sessoesPresente ?? 0;
  SecretariosInfo? get secretarios => null;

  final int id;
  final String nome;
  final String cargo;
  final String partido;
  final String estado;
  final String condicao;
  final String? fotoUrl;
  final Map<int, DadosAno> dadosPorAno;
    final List<Votacao> votacoes;
  final List<Proposicao> proposicoes;
  final List<String> frentesParlamentares;
    final PatrimonioInfo? patrimonio;
  final List<Noticia> noticias;

  Politico({
    required this.id,
    required this.nome,
    required this.cargo,
    required this.partido,
    required this.estado,
    required this.condicao,
    this.fotoUrl,
    required this.dadosPorAno,
        required this.votacoes,
    required this.proposicoes,
    required this.frentesParlamentares,
        this.patrimonio,
    required this.noticias,
  });

  factory Politico.fromJson(Map<String, dynamic> json) {
    Map<int, DadosAno> mapAnos = {};
    if (json['dadosPorAno'] != null) {
      (json['dadosPorAno'] as Map<String, dynamic>).forEach((key, value) {
        mapAnos[int.parse(key)] = DadosAno.fromJson(value);
      });
    }

    return Politico(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? 'Desconhecido',
      cargo: json['cargo'] ?? 'Deputado Federal',
      partido: json['partido'] ?? 'S/P',
      estado: json['estado'] ?? 'BR',
      condicao: json['condicao'] ?? 'Titular',
      fotoUrl: json['foto'] != null
          ? 'https://wsrv.nl/?url=${Uri.encodeComponent(json['foto'])}'
          : null,
      dadosPorAno: mapAnos,
      frentesParlamentares: List<String>.from(
        json['frentesParlamentares'] ?? [],
      ),
      patrimonio: json['patrimonio'] != null
          ? PatrimonioInfo.fromJson(json['patrimonio'])
          : null,
      noticias: (json['noticias'] as List? ?? [])
          .map((i) => Noticia.fromJson(i))
          .toList(),
      votacoes: (json['votacoes'] as List? ?? [])
          .map((i) => Votacao.fromJson(i))
          .toList(),
      proposicoes: (json['proposicoes'] as List? ?? [])
          .map((i) => Proposicao.fromJson(i))
          .toList(),
    );
  }

    double getGastos(int ano) => dadosPorAno[ano]?.gastos ?? 0.0;
    int getAusencias(int ano) => dadosPorAno[ano]?.ausencias ?? 0;
  List<DespesaCategoria> getDespesas(int ano) =>
      dadosPorAno[ano]?.despesas ?? [];

  double get getNotaMediaMandato {
    final anosMandato = dadosPorAno.entries.where((e) => e.key >= 2023);
    if (anosMandato.isEmpty) return 0.0;
    return anosMandato.fold(0.0, (sum, e) => sum + 0) /
        anosMandato.length;
  }

  double get getGastosMandato => dadosPorAno.entries
      .where((e) => e.key >= 2023)
      .fold(0.0, (sum, e) => sum + e.value.gastos);
  int get getPresencasMandato => dadosPorAno.entries
      .where((e) => e.key >= 2023)
      .fold(0, (sum, e) => sum + e.value.sessoesPresente);
  int get getAusenciasMandato => dadosPorAno.entries
      .where((e) => e.key >= 2023)
      .fold(0, (sum, e) => sum + e.value.ausencias);
}

class PoliticoCard extends StatelessWidget {
  final Politico politico;
  final int ano;

  const PoliticoCard({super.key, required this.politico, required this.ano});

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  
  @override
  Widget build(BuildContext context) {
    final presencas = politico.getPresencas(ano);
    final ausencias = politico.getAusencias(ano);
    final totalSessoes = presencas + ausencias;
    final pctPresencas = totalSessoes > 0
        ? (presencas / totalSessoes * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TelaDetalhes(
                politico: politico,
                corBase: Colors.grey,
                ano: ano,
              ),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: Colors.grey),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'avatar_${politico.id}',
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: politico.fotoUrl != null
                                  ? Image.network(
                                      politico.fotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey.shade400,
                                          ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey.shade400,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'nome_${politico.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      politico.nome,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${politico.cargo} • ${politico.partido} - ${politico.estado}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (politico.condicao.toLowerCase() ==
                                    'suplente')
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Suplente',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  politico.getNota(ano).toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ValueListenableBuilder<Set<int>>(
                                valueListenable: favoriteNotifier,
                                builder: (context, favorites, _) {
                                  final isFav = favorites.contains(politico.id);
                                  return InkWell(
                                    onTap: () => toggleFavorite(politico.id),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav ? Colors.red : Colors.grey,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              ValueListenableBuilder<List<Politico>>(
                                valueListenable: comparacaoNotifier,
                                builder: (context, comparacao, _) {
                                  final isSelected = comparacao.any(
                                    (p) => p.id == politico.id,
                                  );
                                  return InkWell(
                                    onTap: () {
                                      if (isSelected) {
                                        comparacaoNotifier.value = comparacao
                                            .where((p) => p.id != politico.id)
                                            .toList();
                                      } else {
                                        final novaLista = List<Politico>.from(
                                          comparacao,
                                        )..add(politico);
                                        if (novaLista.length == 2) {
                                          comparacaoNotifier.value = novaLista;
                                          currentTabNotifier.value =
                                              4; // Muda para a aba Fiscaliza
                                        } else if (novaLista.length > 2) {
                                          comparacaoNotifier.value = [
                                            novaLista.last,
                                          ];
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Nova comparação iniciada.',
                                              ),
                                            ),
                                          );
                                        } else {
                                          comparacaoNotifier.value = novaLista;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Adicionado para comparação (1/2)',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      color: isSelected
                                          ? Colors.indigo
                                          : Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Builder(
                            builder: (context) => _buildEstatistica(
                              icon: Icons.calendar_today,
                              label: 'Presenças',
                              value: '$presencas ($pctPresencas%)',
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                            ),
                          ),
                          Builder(
                            builder: (context) => _buildEstatistica(
                              icon: Icons.receipt_long,
                              label: 'Gastos',
                              value: _formatarMoeda(politico.getGastos(ano)),
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.red.shade300
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (politico.frentesParlamentares.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...politico.frentesParlamentares.map(
                              (frente) => Chip(
                                label: Text(frente),
                                labelStyle: const TextStyle(fontSize: 12),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstatistica({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Builder(
      builder: (context) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class TelaDetalhes extends StatelessWidget {
  final Politico politico;
  final Color corBase;
  final int ano;

  const TelaDetalhes({
    super.key,
    required this.politico,
    required this.corBase,
    required this.ano,
  });

  @override
  Widget build(BuildContext context) {
    final presencas = politico.getPresencas(ano);
    final ausencias = politico.getAusencias(ano);
    final totalSessoes = presencas + ausencias;
    final pctPresencas = totalSessoes > 0
        ? (presencas / totalSessoes * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Político'),
        backgroundColor: corBase,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Gerar Dossiê PDF',
            onPressed: () async {
              await PdfGenerator.gerarDossie(politico);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: corBase.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  Hero(
                    tag: 'avatar_${politico.id}',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: politico.fotoUrl != null
                          ? Image.network(
                              politico.fotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                            )
                          : Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'nome_${politico.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        politico.nome,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${politico.cargo} • ${politico.partido} - ${politico.estado}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (politico.condicao.toLowerCase() == 'suplente')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Suplente',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frentes Parlamentares',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (politico.frentesParlamentares.isEmpty)
                    const Text('Nenhuma frente parlamentar registrada.'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...politico.frentesParlamentares.map(
                        (f) => Chip(
                          label: Text(f),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Estatísticas do Mandato',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Nota Final',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                politico.getNota(ano).toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: corBase,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Presenças',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '$presencas ($pctPresencas%)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Gastos',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                'R\$ ${politico.getGastos(ano).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDespesasCard(),
                                    const SizedBox(height: 24),
                  _buildPatrimonioCard(context),
                  const SizedBox(height: 24),
                  _buildVotacoesCard(context),
                  const SizedBox(height: 24),
                  _buildProjetosLeiCard(),
                  const SizedBox(height: 24),
                                    const SizedBox(height: 24),
                  _buildNoticiasCard(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjetosLeiCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos Projetos de Lei',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (politico.proposicoes.isEmpty)
          const Text('Nenhum projeto de lei recente encontrado.'),
        ...politico.proposicoes.map(
          (p) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.siglaTipo} ${p.numero}/${p.ano}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.ementa, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  
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
                        Expanded(child: Text(d.nome, overflow: TextOverflow.ellipsis)),
                        Text('R\$ ${d.valor.toStringAsFixed(2).replaceAll(".", ",")}'),
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
                    subtitle: Text('${n.fonte} • ${n.data}'),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () {
                       launchUrl(Uri.parse(n.url));
                    },
                  )),
          ],
        ),
      ),
    );
  }



  Widget _buildPatrimonioCard(BuildContext context) {
    if (politico.patrimonio == null) return const SizedBox.shrink();
    
    final pat = politico.patrimonio!;
    
    String formatarValor(double valor) {
      if (valor >= 1000000) {
        return 'R\$ ${(valor / 1000000).toStringAsFixed(2).replaceAll('.', ',')} Mi';
      } else if (valor >= 1000) {
        return 'R\$ ${(valor / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
      }
      return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patrimônio Declarado (TSE 2022)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.account_balance, size: 36, color: Colors.blueGrey),
                const SizedBox(height: 8),
                const Text(
                  'Bens Declarados',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  formatarValor(pat.valorAtual),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Eleição ${pat.anoAtual}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVotacoesCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Votações Polêmicas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...politico.votacoes.map(
          (v) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: ListTile(
              title: Text(
                v.nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: Chip(
                label: Text(
                  v.votouSim ? 'SIM' : 'NÃO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: v.votouSim ? Colors.green : Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  List<Politico> _todosPoliticos = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      String jsonString;
      try {
        const url =
            'https://raw.githubusercontent.com/jenifermenacho/politico-app/master/assets/ranking.json';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          jsonString = utf8.decode(response.bodyBytes);
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('GitHub indisponível, usando dados locais: $e');
        jsonString = await rootBundle.loadString('assets/ranking.json');
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _todosPoliticos = jsonList
            .map((json) => Politico.fromJson(json))
            .toList();
      });
    } catch (e) {
      debugPrint('Erro fatal ao carregar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_todosPoliticos.isEmpty) {
      return const SplashScreen();
    }

    final tabs = [
      const TelaInicioTab(),
      TelaDeputadosTab(
        key: const ValueKey('deputados'),
        politicos: _todosPoliticos.where((p) => p.cargo != 'Senador').toList(),
        titulo: 'Ranking dos Deputados',
        textoVazio: 'Nenhum deputado encontrado.',
      ),
      TelaDeputadosTab(
        key: const ValueKey('senadores'),
        politicos: _todosPoliticos.where((p) => p.cargo == 'Senador').toList(),
        titulo: 'Ranking dos Senadores',
        textoVazio: 'Nenhum senador encontrado.',
      ),
      TelaRankingPartidosTab(politicos: _todosPoliticos),
      TelaFavoritosTab(todosPoliticos: _todosPoliticos),
      TelaComparadorTab(politicos: _todosPoliticos),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: currentTabNotifier,
      builder: (context, currentIndex, _) {
        return Scaffold(
          body: tabs[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => currentTabNotifier.value = index,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Deputados',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance),
                label: 'Senadores',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag),
                label: 'Partidos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favoritos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.compare_arrows),
                label: 'Fiscaliza',
              ),
            ],
          ),
        );
      },
    );
  }
}

class TelaFavoritosTab extends StatelessWidget {
  final List<Politico> todosPoliticos;

  const TelaFavoritosTab({super.key, required this.todosPoliticos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Políticos Favoritos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: const [ThemeToggleButton()],
      ),
      body: ValueListenableBuilder<Set<int>>(
        valueListenable: favoriteNotifier,
        builder: (context, favorites, _) {
          final politicosFavoritos = todosPoliticos
              .where((p) => favorites.contains(p.id))
              .toList();
          if (politicosFavoritos.isEmpty) {
            return const Center(
              child: Text('Você ainda não favoritou nenhum político.'),
            );
          }
          return ListView.builder(
            itemCount: politicosFavoritos.length,
            itemBuilder: (context, index) {
              return PoliticoCard(
                politico: politicosFavoritos[index],
                ano: 2023,
              );
            },
          );
        },
      ),
    );
  }
}

class TelaInicioTab extends StatelessWidget {
  const TelaInicioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sobre o Fiscaliza Político',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: Builder(
        builder: (context) {
          final primaryColor = Theme.of(context).colorScheme.primary;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O Objetivo do Projeto',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A política afeta diretamente a nossa rotina, mas fiscalizar o trabalho dos nossos representantes costuma exigir paciência para navegar em sites governamentais lentos, planilhas pesadas e termos técnicos indecifráveis. O cidadão comum acaba afastado do processo de cobrança simplesmente pela falta de clareza das informações.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Este aplicativo nasceu para resolver esse problema. Nosso objetivo é democratizar a transparência, entregando os dados públicos do Congresso Nacional de uma forma que qualquer pessoa consiga entender em poucos segundos.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Como nós simplificamos a política:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                _buildFeatureItem(
                  Icons.traffic,
                  'O Semáforo da Produtividade',
                  'Em vez de dezenas de métricas confusas, consolidamos o desempenho do parlamentar em um sistema de cores. É fácil bater o olho e ver quem está no verde (trabalhando) e quem está no vermelho (acumulando faltas).',
                ),
                _buildFeatureItem(
                  Icons.warning,
                  'Tolerância Zero com o Absenteísmo',
                  'Expomos claramente os "parlamentares de 90 dias", penalizando no ranking aqueles que acumulam faltas não justificadas e não comparecem às sessões.',
                ),
                _buildFeatureItem(
                  Icons.attach_money,
                  'Siga o Dinheiro e os Interesses',
                  'Acreditamos que é fundamental saber para quem o político está trabalhando. Por isso, mapeamos as frentes parlamentares (bancadas) que eles integram e a origem do dinheiro que financiou suas campanhas. Assim, você mesmo pode avaliar se a atuação do parlamentar reflete as necessidades da população geral ou atende a interesses restritos.',
                ),
                _buildFeatureItem(
                  Icons.balance,
                  'Zero Viés Ideológico',
                  'Nosso robô não avalia opiniões políticas, nem se o projeto de lei é de direita ou de esquerda. Avaliamos a presença, o gasto da cota parlamentar e o esforço técnico. O julgamento do mérito fica 100% nas suas mãos.',
                ),

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Acreditamos que a verdadeira cidadania começa quando a informação deixa de ser um privilégio de especialistas e passa a ser uma ferramenta de bolso para todos.',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => currentTabNotifier.value = 1,
                    icon: const Icon(Icons.people),
                    label: const Text(
                      'Explorar Ranking',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Builder(
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TelaDeputadosTab extends StatefulWidget {
  final List<Politico> politicos;
  final String titulo;
  final String textoVazio;
  const TelaDeputadosTab({
    super.key,
    required this.politicos,
    this.titulo = 'Ranking Parlamentar',
    this.textoVazio = 'Nenhum político encontrado.',
  });

  @override
  State<TelaDeputadosTab> createState() => _TelaDeputadosTabState();
}

class _TelaDeputadosTabState extends State<TelaDeputadosTab> {
  List<Politico> _politicosFiltrados = [];
  String _busca = '';
  String _filtroAtual = 'Maior Nota';
  int? _anoSelecionado;
  String? _estadoSelecionado;

  @override
  void initState() {
    super.initState();
    _aplicarFiltros();
  }

  @override
  void didUpdateWidget(TelaDeputadosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.politicos != widget.politicos) {
      _aplicarFiltros();
    }
  }

  void _aplicarFiltros() {
    List<Politico> filtrados = List.from(widget.politicos);

    if (_busca.isNotEmpty) {
      filtrados = filtrados
          .where(
            (p) =>
                p.nome.toLowerCase().contains(_busca.toLowerCase()) ||
                p.partido.toLowerCase().contains(_busca.toLowerCase()),
          )
          .toList();
    }

    // Filtro destrutivo de ano removido, o select de ano agora serve para recalcular a nota, presenças e gastos.

    if (_estadoSelecionado != null) {
      filtrados = filtrados
          .where((p) => p.estado == _estadoSelecionado)
          .toList();
    }

    if (_filtroAtual == 'Maior Nota') {
      filtrados.sort(
        (a, b) => b
            .getNota(_anoSelecionado ?? 2023)
            .compareTo(a.getNota(_anoSelecionado ?? 2023)),
      );
    } else if (_filtroAtual == 'Mais Presenças') {
      filtrados.sort(
        (a, b) => b
            .getPresencas(_anoSelecionado ?? 2023)
            .compareTo(a.getPresencas(_anoSelecionado ?? 2023)),
      );
    } else if (_filtroAtual == 'Menos Gastos') {
      filtrados.sort(
        (a, b) => a
            .getGastos(_anoSelecionado ?? 2023)
            .compareTo(b.getGastos(_anoSelecionado ?? 2023)),
      );
    }

    setState(() {
      _politicosFiltrados = filtrados;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        centerTitle: true,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _mostrarLegenda(context),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      _busca = value;
                      _aplicarFiltros();
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou partido...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _estadoSelecionado,
                      hint: const Text('UF'),
                      items:
                          [
                            null,
                            'AC',
                            'AL',
                            'AM',
                            'AP',
                            'BA',
                            'CE',
                            'DF',
                            'ES',
                            'GO',
                            'MA',
                            'MG',
                            'MS',
                            'MT',
                            'PA',
                            'PB',
                            'PE',
                            'PI',
                            'PR',
                            'RJ',
                            'RN',
                            'RO',
                            'RR',
                            'RS',
                            'SC',
                            'SE',
                            'SP',
                            'TO',
                          ].map((uf) {
                            return DropdownMenuItem<String?>(
                              value: uf,
                              child: Text(uf ?? 'BR'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _estadoSelecionado = value;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _anoSelecionado,
                      hint: const Text('Ano'),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      items: [null, 2022, 2023, 2024, 2025, 2026].map((ano) {
                        return DropdownMenuItem<int?>(
                          value: ano,
                          child: Text(ano == null ? 'Todos' : ano.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _anoSelecionado = value;
                          _aplicarFiltros();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Maior Nota', 'Mais Presenças', 'Menos Gastos'].map((
                  filtro,
                ) {
                  final isSelected = _filtroAtual == filtro;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filtro),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _filtroAtual = filtro;
                            _aplicarFiltros();
                          });
                        }
                      },
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _politicosFiltrados.isEmpty
                ? Center(child: Text(widget.textoVazio))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _politicosFiltrados.length,
                    itemBuilder: (context, index) {
                      return PoliticoCard(
                        politico: _politicosFiltrados[index],
                        ano: _anoSelecionado ?? 2023,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class TelaRankingPartidosTab extends StatelessWidget {
  final List<Politico> politicos;
  const TelaRankingPartidosTab({super.key, required this.politicos});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Politico>> porPartido = {};
    for (var p in politicos) {
      if (!porPartido.containsKey(p.partido)) {
        porPartido[p.partido] = [];
      }
      porPartido[p.partido]!.add(p);
    }

    final todosPartidos = porPartido.entries.map((entry) {
      final nome = entry.key;
      final lista = entry.value;
      final avgNota =
          lista.fold<double>(0, (sum, p) => sum + p.getNota(2023)) /
          lista.length;
      final totalGasto = lista.fold<double>(
        0,
        (sum, p) => sum + p.getGastos(2023),
      );
      return {
        'partido': nome,
        'nota': avgNota,
        'gastos': totalGasto,
        'tamanho': lista.length,
      };
    }).toList();

    // Dividir em categorias
    final grandes = todosPartidos
        .where((p) => (p['tamanho'] as int) >= 30)
        .toList();
    final medios = todosPartidos
        .where((p) => (p['tamanho'] as int) >= 10 && (p['tamanho'] as int) < 30)
        .toList();
    final pequenos = todosPartidos
        .where((p) => (p['tamanho'] as int) < 10)
        .toList();

    // Ordenar cada grupo
    grandes.sort(
      (a, b) => (b['nota'] as double).compareTo(a['nota'] as double),
    );
    medios.sort((a, b) => (b['nota'] as double).compareTo(a['nota'] as double));
    pequenos.sort(
      (a, b) => (b['nota'] as double).compareTo(a['nota'] as double),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Partidos'),
        centerTitle: true,
        elevation: 0,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _mostrarLegenda(context),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (grandes.isNotEmpty) ...[
            _buildSectionTitle(
              context,
              'Partidos Grandes',
              '30 ou mais parlamentares',
            ),
            ...grandes.asMap().entries.map(
              (e) => _buildPartidoCard(e.key, e.value, context),
            ),
            const SizedBox(height: 24),
          ],
          if (medios.isNotEmpty) ...[
            _buildSectionTitle(
              context,
              'Partidos Médios',
              'De 10 a 29 parlamentares',
            ),
            ...medios.asMap().entries.map(
              (e) => _buildPartidoCard(e.key, e.value, context),
            ),
            const SizedBox(height: 24),
          ],
          if (pequenos.isNotEmpty) ...[
            _buildSectionTitle(
              context,
              'Partidos Pequenos',
              'Menos de 10 parlamentares',
            ),
            ...pequenos.asMap().entries.map(
              (e) => _buildPartidoCard(e.key, e.value, context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartidoCard(
    int index,
    Map<String, dynamic> p,
    BuildContext context,
  ) {
    final nota = p['nota'] as double;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          child: Text(
            '#${index + 1}',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          p['partido'] as String,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          '${p['tamanho']} parlamentares • R\$ ${(p['gastos'] as double).toStringAsFixed(2)} gastos',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        trailing: Text(
          nota.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class TelaComparadorTab extends StatefulWidget {
  final List<Politico> politicos;
  const TelaComparadorTab({super.key, required this.politicos});

  @override
  State<TelaComparadorTab> createState() => _TelaComparadorTabState();
}

class _TelaComparadorTabState extends State<TelaComparadorTab> {
  Politico? _politicoA;
  Politico? _politicoB;
  int _ano = 2024;

  static const _anos = [2023, 2024, 2025, 2026];

  @override
  void initState() {
    super.initState();
    if (comparacaoNotifier.value.isNotEmpty) {
      _politicoA = comparacaoNotifier.value[0];
      if (comparacaoNotifier.value.length > 1) {
        _politicoB = comparacaoNotifier.value[1];
      }
    }
  }

  String _moeda(double v) => 'R\$ ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  // ---------- Autocomplete field ----------
  Widget _autocompleteField(String label, Politico? current, ValueChanged<Politico> onPick) {
    return Autocomplete<Politico>(
      displayStringForOption: (p) => p.nome,
      optionsBuilder: (tv) {
        if (tv.text.isEmpty) return const [];
        final q = tv.text.toLowerCase();
        return widget.politicos.where((p) => p.nome.toLowerCase().contains(q));
      },
      onSelected: onPick,
      fieldViewBuilder: (ctx, ctrl, focus, _) {
        if (current != null && ctrl.text != current.nome) ctrl.text = current.nome;
        return TextField(
          controller: ctrl,
          focusNode: focus,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person_search),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            isDense: true,
          ),
        );
      },
    );
  }

  // ---------- Avatar + name ----------
  Widget _perfil(Politico p) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => TelaDetalhes(politico: p, corBase: const Color(0xFF00BFA5), ano: _ano),
          )),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00BFA5), width: 2.5),
                ),
                child: ClipOval(
                  child: p.fotoUrl != null
                      ? Image.network(p.fotoUrl!, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Icon(Icons.person, size: 36))
                      : const Icon(Icons.person, size: 36),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFF00BFA5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_new, size: 12, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(p.nome,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('${p.cargo}\n${p.partido} • ${p.estado}',
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ---------- Metric row with bar ----------
  Widget _metrica({
    required IconData icone,
    required String titulo,
    required double valA,
    required double valB,
    required String strA,
    required String strB,
    bool inverteMelhor = false,
  }) {
    final empate = valA == valB;
    final aVence = !empate && (inverteMelhor ? valA < valB : valA > valB);
    final bVence = !empate && (inverteMelhor ? valB < valA : valB > valA);
    final corA = empate ? Colors.grey : (aVence ? Colors.green.shade600 : Colors.red.shade400);
    final corB = empate ? Colors.grey : (bVence ? Colors.green.shade600 : Colors.red.shade400);
    final total = valA + valB;
    final barA = total > 0 ? valA / total : 0.5;
    final barB = total > 0 ? valB / total : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icone, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 5),
            Text(titulo,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lado A
              Expanded(
                child: Column(children: [
                  if (aVence) _melhorBadge(),
                  Text(strA,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: corA)),
                ]),
              ),
              Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
              // Lado B
              Expanded(
                child: Column(children: [
                  if (bVence) _melhorBadge(),
                  Text(strB,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: corB)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barras visuais
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                child: LinearProgressIndicator(
                  value: barA, minHeight: 6,
                  color: corA, backgroundColor: corA.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                child: LinearProgressIndicator(
                  value: barB, minHeight: 6,
                  color: corB, backgroundColor: corB.withValues(alpha: 0.12),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _melhorBadge() => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.green.shade600,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text('Melhor', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
  );

  Widget _secaoTitulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Row(children: [
      Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.4))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(texto,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1,
                color: Theme.of(context).textTheme.bodySmall?.color)),
      ),
      Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.4))),
    ]),
  );

  // ---------- Votações lado a lado ----------
  Widget _votacoes() {
    final votosA = {for (var v in _politicoA!.votacoes) v.nome: v.votouSim};
    final votosB = {for (var v in _politicoB!.votacoes) v.nome: v.votouSim};
    final nomes = {...votosA.keys, ...votosB.keys};
    if (nomes.isEmpty) return const SizedBox.shrink();

    int concordam = 0, discordam = 0;
    for (final nome in nomes) {
      if (votosA[nome] != null && votosB[nome] != null) {
        votosA[nome] == votosB[nome] ? concordam++ : discordam++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secaoTitulo('VOTAÇÕES EM PLENÁRIO'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _votoResumo('Concordam', concordam, Colors.green.shade600),
            const SizedBox(width: 16),
            _votoResumo('Discordam', discordam, Colors.red.shade400),
          ],
        ),
        const SizedBox(height: 12),
        ...nomes.map((nome) {
          final simA = votosA[nome];
          final simB = votosB[nome];
          final concordou = simA != null && simB != null && simA == simB;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _votoBadge(simA),
                const SizedBox(width: 8),
                Expanded(child: Text(nome, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                _votoBadge(simB),
                const SizedBox(width: 4),
                Icon(concordou ? Icons.handshake : Icons.close,
                    size: 16, color: concordou ? Colors.green.shade600 : Colors.red.shade400),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _votoResumo(String label, int count, Color cor) => Column(
    children: [
      Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
      Text(label, style: TextStyle(fontSize: 11, color: cor)),
    ],
  );

  Widget _votoBadge(bool? sim) {
    if (sim == null) return const SizedBox(width: 46);
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: sim ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: sim ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Text(sim ? 'SIM' : 'NÃO',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: sim ? Colors.green.shade700 : Colors.red.shade700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _politicoA;
    final b = _politicoB;
    final ambos = a != null && b != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparador',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [ThemeToggleButton()],
      ),
      body: Column(
        children: [
          // Seletores de políticos
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(children: [
              Expanded(child: _autocompleteField('Político A', _politicoA, (p) => setState(() => _politicoA = p))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16,
                    color: Theme.of(context).primaryColor)),
              ),
              Expanded(child: _autocompleteField('Político B', _politicoB, (p) => setState(() => _politicoB = p))),
            ]),
          ),

          // Seletor de ano (visível apenas com dois políticos)
          if (ambos)
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
              child: Row(
                children: _anos.map((ano) {
                  final sel = ano == _ano;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('$ano'),
                      selected: sel,
                      selectedColor: const Color(0xFF00BFA5),
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : null),
                      onSelected: (_) => setState(() => _ano = ano),
                    ),
                  );
                }).toList(),
              ),
            ),

          if (!ambos)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compare_arrows, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Selecione dois políticos para comparar.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                  ],
                ),
              ),
            ),

          if (ambos)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    // Cabeçalho com avatares
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _perfil(a)),
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text('VS',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context).primaryColor)),
                            ),
                            Expanded(child: _perfil(b)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Métricas do ano selecionado
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _secaoTitulo('ANO $_ano'),
                            _metrica(
                              icone: Icons.attach_money,
                              titulo: 'Gastos CEAP',
                              valA: a.getGastos(_ano), valB: b.getGastos(_ano),
                              strA: _moeda(a.getGastos(_ano)), strB: _moeda(b.getGastos(_ano)),
                              inverteMelhor: true,
                            ),
                            _metrica(
                              icone: Icons.how_to_vote,
                              titulo: 'Presenças em Sessões',
                              valA: a.dadosPorAno[_ano]?.sessoesPresente.toDouble() ?? 0,
                              valB: b.dadosPorAno[_ano]?.sessoesPresente.toDouble() ?? 0,
                              strA: '${a.dadosPorAno[_ano]?.sessoesPresente ?? 0}',
                              strB: '${b.dadosPorAno[_ano]?.sessoesPresente ?? 0}',
                            ),
                            _metrica(
                              icone: Icons.event_busy,
                              titulo: 'Faltas Não Justificadas',
                              valA: a.getAusencias(_ano).toDouble(),
                              valB: b.getAusencias(_ano).toDouble(),
                              strA: '${a.getAusencias(_ano)}',
                              strB: '${b.getAusencias(_ano)}',
                              inverteMelhor: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Métricas acumuladas do mandato
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _secaoTitulo('MANDATO COMPLETO (2023 – ATUAL)'),
                            _metrica(
                              icone: Icons.account_balance_wallet,
                              titulo: 'Total Gastos CEAP',
                              valA: a.getGastosMandato, valB: b.getGastosMandato,
                              strA: _moeda(a.getGastosMandato), strB: _moeda(b.getGastosMandato),
                              inverteMelhor: true,
                            ),
                            _metrica(
                              icone: Icons.check_circle_outline,
                              titulo: 'Total de Presenças',
                              valA: a.getPresencasMandato.toDouble(),
                              valB: b.getPresencasMandato.toDouble(),
                              strA: '${a.getPresencasMandato}', strB: '${b.getPresencasMandato}',
                            ),
                            _metrica(
                              icone: Icons.cancel_outlined,
                              titulo: 'Total de Faltas',
                              valA: a.getAusenciasMandato.toDouble(),
                              valB: b.getAusenciasMandato.toDouble(),
                              strA: '${a.getAusenciasMandato}', strB: '${b.getAusenciasMandato}',
                              inverteMelhor: true,
                            ),
                            if (a.patrimonio != null || b.patrimonio != null)
                              _metrica(
                                icone: Icons.real_estate_agent,
                                titulo: 'Patrimônio Declarado (TSE 2022)',
                                valA: a.patrimonio?.valorAtual ?? 0,
                                valB: b.patrimonio?.valorAtual ?? 0,
                                strA: a.patrimonio != null ? _moeda(a.patrimonio!.valorAtual) : 'N/D',
                                strB: b.patrimonio != null ? _moeda(b.patrimonio!.valorAtual) : 'N/D',
                              ),
                            _metrica(
                              icone: Icons.description_outlined,
                              titulo: 'Projetos de Lei Apresentados',
                              valA: a.proposicoes.length.toDouble(),
                              valB: b.proposicoes.length.toDouble(),
                              strA: '${a.proposicoes.length}', strB: '${b.proposicoes.length}',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Votações
                    if (a.votacoes.isNotEmpty || b.votacoes.isNotEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _votacoes(),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
