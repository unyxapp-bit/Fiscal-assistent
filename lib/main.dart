import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Services
import 'data/services/notification_service.dart';

// Data Sources
import 'data/datasources/remote/supabase_client.dart';
import 'data/datasources/remote/fiscal_remote_datasource.dart';
import 'data/datasources/remote/colaborador_remote_datasource.dart';
import 'data/datasources/remote/caixa_remote_datasource.dart';
import 'data/datasources/remote/alocacao_remote_datasource.dart';
import 'data/datasources/remote/registro_ponto_remote_datasource.dart';

// Repositories
import 'data/repositories/fiscal_repository.dart';
import 'data/repositories/colaborador_repository.dart';
import 'data/repositories/caixa_repository.dart';
import 'data/repositories/alocacao_repository.dart';
import 'data/repositories/registro_ponto_repository.dart';
import 'data/datasources/remote/pacote_plantao_remote_datasource.dart';
import 'data/repositories/pacote_plantao_repository.dart';
import 'data/datasources/remote/outro_setor_remote_datasource.dart';
import 'data/repositories/outro_setor_repository.dart';

// Use Cases - Fiscal
import 'domain/usecases/fiscal/get_fiscal_profile.dart';
import 'domain/usecases/fiscal/update_fiscal_profile.dart';

// Use Cases - Colaborador
import 'domain/usecases/colaborador/get_colaboradores.dart';
import 'domain/usecases/colaborador/create_colaborador.dart';
import 'domain/usecases/colaborador/update_colaborador.dart';

// Use Cases - Registro Ponto
import 'domain/usecases/registro_ponto/get_registros_ponto.dart';

// Use Cases - Caixa
import 'domain/usecases/caixa/get_caixas.dart';
import 'domain/usecases/caixa/toggle_caixa_status.dart';
import 'domain/usecases/caixa/toggle_caixa_manutencao.dart';

// Use Cases - Alocacao
import 'domain/usecases/alocar_colaborador.dart';
import 'domain/usecases/liberar_alocacao.dart';
import 'domain/usecases/get_alocacoes_ativas.dart';

// Providers
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/fiscal_provider.dart';
import 'presentation/providers/colaborador_provider.dart';
import 'presentation/providers/caixa_provider.dart';
import 'presentation/providers/alocacao_provider.dart';
import 'presentation/providers/notificacao_provider.dart';
import 'presentation/providers/entrega_provider.dart';
import 'presentation/providers/procedimento_provider.dart';
import 'presentation/providers/nota_provider.dart';
import 'presentation/providers/formulario_provider.dart';
import 'presentation/providers/cafe_provider.dart';
import 'presentation/providers/escala_provider.dart';
import 'presentation/providers/registro_ponto_provider.dart';
import 'presentation/providers/pacote_plantao_provider.dart';
import 'presentation/providers/outro_setor_provider.dart';
import 'presentation/providers/ocorrencia_provider.dart';
import 'presentation/providers/checklist_provider.dart';
import 'presentation/providers/passagem_turno_provider.dart';
import 'presentation/providers/guia_rapido_provider.dart';
import 'presentation/providers/evento_turno_provider.dart';

// App Config
import 'core/constants/colors.dart';
import 'core/constants/text_styles.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar formatação de datas em português
    await initializeDateFormatting('pt_BR', null);

    // Carregar .env
    await dotenv.load(fileName: '.env');

    // Inicializar Supabase
    await SupabaseClientManager.initialize();

    // Inicializar notificações locais
    await NotificationService.instance.initialize();

    // ==================== FISCAL ====================
    final fiscalRemoteDataSource = FiscalRemoteDataSource();
    final fiscalRepository = FiscalRepository(
      remoteDataSource: fiscalRemoteDataSource,
    );
    final getFiscalProfile = GetFiscalProfile(fiscalRepository);
    final updateFiscalProfile = UpdateFiscalProfile(fiscalRepository);

    // ==================== COLABORADOR ====================
    final colaboradorRemoteDataSource = ColaboradorRemoteDataSource();
    final colaboradorRepository = ColaboradorRepository(
      remoteDataSource: colaboradorRemoteDataSource,
    );
    final getColaboradores = GetColaboradores(colaboradorRepository);
    final createColaborador = CreateColaborador(colaboradorRepository);
    final updateColaborador = UpdateColaborador(colaboradorRepository);

    // ==================== REGISTRO PONTO ====================
    final registroPontoRemoteDataSource = RegistroPontoRemoteDataSource();
    final registroPontoRepository = RegistroPontoRepository(
      remoteDataSource: registroPontoRemoteDataSource,
    );
    final getRegistrosPonto = GetRegistrosPonto(registroPontoRepository);

    // ==================== CAIXA ====================
    final caixaRemoteDataSource = CaixaRemoteDataSource();
    final caixaRepository = CaixaRepository(
      remoteDataSource: caixaRemoteDataSource,
    );
    final getCaixas = GetCaixas(caixaRepository);
    final toggleCaixaStatus = ToggleCaixaStatus(caixaRepository);
    final toggleCaixaManutencao = ToggleCaixaManutencao(caixaRepository);

    // ==================== PACOTE PLANTAO ====================
    final pacotePlantaoRemoteDataSource = PacotePlantaoRemoteDataSource();
    final pacotePlantaoRepository = PacotePlantaoRepository(
      remoteDataSource: pacotePlantaoRemoteDataSource,
    );

    // ==================== OUTRO SETOR ====================
    final outroSetorRemoteDataSource = OutroSetorRemoteDataSource();
    final outroSetorRepository = OutroSetorRepository(
      remoteDataSource: outroSetorRemoteDataSource,
    );

    // ==================== ALOCACAO ====================
    final alocacaoRemoteDataSource = AlocacaoRemoteDataSource();
    final alocacaoRepository = AlocacaoRepository(
      remoteDataSource: alocacaoRemoteDataSource,
    );
    final alocarColaborador = AlocarColaborador(
      alocacaoRepository: alocacaoRepository,
      colaboradorRepository: colaboradorRepository,
      caixaRepository: caixaRepository,
    );
    final liberarAlocacao = LiberarAlocacao(
      alocacaoRepository: alocacaoRepository,
    );
    final getAlocacoesAativas = GetAlocacoesAtivas(
      alocacaoRepository: alocacaoRepository,
    );

    runApp(
      MultiProvider(
        providers: [
          // CaixaRemoteDataSource (para SeedDataService no Dashboard)
          Provider<CaixaRemoteDataSource>.value(value: caixaRemoteDataSource),

          // Auth Provider
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),
          ),

          // Fiscal Provider
          ChangeNotifierProvider(
            create: (_) => FiscalProvider(
              getFiscalProfile: getFiscalProfile,
              updateFiscalProfile: updateFiscalProfile,
            ),
          ),

          // Colaborador Provider
          ChangeNotifierProvider(
            create: (_) => ColaboradorProvider(
              getColaboradores: getColaboradores,
              createColaborador: createColaborador,
              updateColaborador: updateColaborador,
              repository: colaboradorRepository,
            ),
          ),

          // Caixa Provider
          ChangeNotifierProvider(
            create: (_) => CaixaProvider(
              getCaixas: getCaixas,
              toggleStatus: toggleCaixaStatus,
              toggleManutencao: toggleCaixaManutencao,
              caixaRepository: caixaRepository,
            ),
          ),

          // Escala Semanal
          ChangeNotifierProvider(
            create: (_) => EscalaProvider(),
          ),

          // Alocacao Provider
          ChangeNotifierProxyProvider<EscalaProvider, AlocacaoProvider>(
            create: (_) => AlocacaoProvider(
              alocarColaboradorUseCase: alocarColaborador,
              liberarAlocacaoUseCase: liberarAlocacao,
              getAlocacoesAtivasUseCase: getAlocacoesAativas,
              repository: alocacaoRepository,
            ),
            update: (_, escala, alocacao) {
              alocacao?.vincularEscala(escala);
              return alocacao!;
            },
          ),

          // Module 13 - Notificações
          ChangeNotifierProvider(
            create: (_) => NotificacaoProvider(),
          ),

          // Module 16 - Entregas
          ChangeNotifierProvider(
            create: (_) => EntregaProvider(),
          ),

          // Module 17 - Procedimentos
          ChangeNotifierProvider(
            create: (_) => ProcedimentoProvider(),
          ),

          // Module 18 - Anotações
          ChangeNotifierProvider(
            create: (_) => NotaProvider(),
          ),

          // Module 19 - Formulários
          ChangeNotifierProvider(
            create: (_) => FormularioProvider(),
          ),

          // Module 8 - Café / Intervalos
          ChangeNotifierProvider(
            create: (_) => CafeProvider(),
          ),

          // Registro de Ponto
          ChangeNotifierProvider(
            create: (_) => RegistroPontoProvider(
              getRegistrosPonto: getRegistrosPonto,
              repository: registroPontoRepository,
            ),
          ),

          // Pacote Plantão
          ChangeNotifierProvider(
            create: (_) => PacotePlantaoProvider(
              repository: pacotePlantaoRepository,
            ),
          ),

          // Outro Setor
          ChangeNotifierProvider(
            create: (_) => OutroSetorProvider(
              repository: outroSetorRepository,
            ),
          ),

          // Ocorrências
          ChangeNotifierProvider(
            create: (_) => OcorrenciaProvider(),
          ),

          // Checklist de Turno
          ChangeNotifierProvider(
            create: (_) => ChecklistProvider(),
          ),

          // Passagem de Turno
          ChangeNotifierProvider(
            create: (_) => PassagemTurnoProvider(),
          ),

          // Guia Rápido
          ChangeNotifierProvider(
            create: (_) => GuiaRapidoProvider(),
          ),

          // Eventos de Turno + Relatórios
          ChangeNotifierProvider(
            create: (_) => EventoTurnoProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erro ao inicializar: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fiscal Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.textOnColor,
          secondary: AppColors.statusInfo,
          onSecondary: AppColors.textOnColor,
          error: AppColors.danger,
          onError: AppColors.textOnColor,
          surface: AppColors.cardBackground,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.h1,
          displayMedium: AppTextStyles.h2,
          titleLarge: AppTextStyles.h3,
          titleMedium: AppTextStyles.h4,
          bodyLarge: AppTextStyles.body,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
          labelLarge: AppTextStyles.button,
          labelMedium: AppTextStyles.label,
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: AppTextStyles.h3,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          margin: const EdgeInsets.all(0),
        ),
        dividerColor: AppColors.divider,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.inactive),
          labelStyle: AppTextStyles.label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
            backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
            foregroundColor:
                const WidgetStatePropertyAll(AppColors.textOnColor),
            elevation: const WidgetStatePropertyAll(0),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            textStyle: const WidgetStatePropertyAll(AppTextStyles.button),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
            foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
            side: const WidgetStatePropertyAll(
              BorderSide(color: AppColors.cardBorder),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            textStyle: const WidgetStatePropertyAll(AppTextStyles.button),
          ),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(AppColors.primary),
            textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.backgroundSection,
          disabledColor: AppColors.backgroundSection,
          selectedColor: AppColors.secondary,
          secondarySelectedColor: AppColors.secondary,
          side: const BorderSide(color: AppColors.cardBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          labelStyle: AppTextStyles.caption,
          secondaryLabelStyle: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
          ),
          brightness: Brightness.light,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.textSecondary,
          textColor: AppColors.textPrimary,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnColor,
          elevation: 1,
          shape: StadiumBorder(),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.cardBackground.withValues(alpha: 0.94),
          indicatorColor: AppColors.secondary,
          iconTheme: const WidgetStatePropertyAll(
            IconThemeData(color: AppColors.textSecondary),
          ),
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          dividerColor: AppColors.cardBorder,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Se ainda está inicializando
          if (authProvider.status == AuthStatus.initial) {
            return const SplashScreen();
          }

          // Se está autenticado, vai para Dashboard
          if (authProvider.isAuthenticated) {
            return const _AppHome();
          }

          // Se não está autenticado
          return const LoginScreen();
        },
      ),
    );
  }
}

/// Widget que inicializa todos os providers após autenticação.
class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _initProviders();
    }
  }

  Future<void> _initProviders() async {
    final ctx = context;
    final userId = ctx.read<AuthProvider>().user?.id ?? '';
    // Fire-and-forget: load all Supabase-backed providers in parallel
    await Future.wait([
      ctx.read<EntregaProvider>().load(),
      ctx.read<NotaProvider>().load(),
      ctx.read<FormularioProvider>().load(),
      ctx.read<ProcedimentoProvider>().load(),
      ctx.read<CafeProvider>().load(),
      ctx.read<EscalaProvider>().load(),
      ctx.read<OcorrenciaProvider>().load(),
      ctx.read<ChecklistProvider>().load(),
      ctx.read<PassagemTurnoProvider>().load(),
      ctx.read<GuiaRapidoProvider>().load(),
      if (userId.isNotEmpty) ctx.read<PacotePlantaoProvider>().load(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) => const DashboardScreen();
}
