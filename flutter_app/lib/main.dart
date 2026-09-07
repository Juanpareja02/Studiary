import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'focus_session.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'brand.dart';
import 'dialogs.dart';
import 'models.dart';
import 'notifications.dart';
import 'schedule_widget.dart';
import 'services.dart';
import 'supabase_config.dart';
import 'subject_pages.dart';
import 'theme.dart';
import 'tutorial.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  Intl.defaultLocale = 'es_ES';
  if (SupabaseConfig.isConfigured) {
    await supabase.Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    try {
      await AuthService.initializeGoogle();
    } catch (error) {
      debugPrint(
        'Google Sign-In todavía necesita configuración nativa: $error',
      );
    }
  } else {
    debugPrint(
      'Supabase no está configurado. Usa SUPABASE_URL y '
      'SUPABASE_PUBLISHABLE_KEY al compilar.',
    );
  }
  runApp(const StudiaryRoot());
}

class StudiaryRoot extends StatefulWidget {
  const StudiaryRoot({super.key});

  @override
  State<StudiaryRoot> createState() => _StudiaryRootState();
}

class _StudiaryRootState extends State<StudiaryRoot>
    with WidgetsBindingObserver {
  AppState? state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (SupabaseConfig.isConfigured) state = AppState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await NotificationService.initialize();
        await NotificationService.syncEvents(state?.events ?? []);
      } catch (_) {
        debugPrint('Recordatorios no disponibles');
      }
      try {
        await MonetizationService.initialize();
      } catch (_) {
        debugPrint('Consentimiento de anuncios pendiente');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      unawaited(state?.synchronize());
    } else {
      unawaited(state?.saveLocally().catchError((Object _) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = state;
    if (appState == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Studiary',
        theme: buildTheme(dark: false),
        darkTheme: buildTheme(dark: true),
        themeMode: ThemeMode.system,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SupabaseSetupScreen(),
      );
    }
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Studiary',
          theme: buildTheme(
            dark: false,
            backgroundHex: appState.backgroundColor,
            primaryHex: appState.primaryColor,
            textHex: appState.textColor,
            surfaceHex: appState.surfaceColor,
          ),
          darkTheme: buildTheme(
            dark: true,
            backgroundHex: appState.backgroundColor,
            primaryHex: appState.primaryColor,
            textHex: appState.textColor,
            surfaceHex: appState.surfaceColor,
          ),
          themeMode: appState.themeMode,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: _homeForState(appState),
        );
      },
    );
  }

  Widget _homeForState(AppState appState) {
    if (appState.loading && appState.user != null) {
      return const LoadingScreen();
    }
    if (appState.user == null) return AuthScreen(state: appState);
    return MainShell(state: appState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state?.dispose();
    super.dispose();
  }
}

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StudiaryLogo(width: 260, height: 92),
              const SizedBox(height: 18),
              Text(
                'Falta configurar la nube',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Compila la app con SUPABASE_URL y '
                'SUPABASE_PUBLISHABLE_KEY para activar las cuentas y la '
                'sincronización.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StudiaryMascot(size: 92, pose: MascotPose.focus),
            const SizedBox(height: 18),
            Text(
              'Preparando tu espacio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});

  final AppState state;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  bool busy = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: Theme.of(context).brightness == Brightness.dark
                      ? .04
                      : .18,
                  child: Image.asset(BrandAssets.pattern, fit: BoxFit.cover),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: StudiaryLogo(width: 280, height: 96)),
                      const SizedBox(height: 22),
                      Text(
                        isLogin
                            ? 'Tu semana empieza aquí.'
                            : 'Crea tu espacio de estudio.',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.04,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isLogin
                            ? 'Organiza tus clases, tareas y objetivos en un solo lugar.'
                            : 'Tus planes se guardarán y estarán disponibles en todos tus dispositivos.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isLogin ? 'Entrar' : 'Crear cuenta'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: scheme.outlineVariant),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('o'),
                          ),
                          Expanded(
                            child: Divider(color: scheme.outlineVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : _google,
                          icon: const Icon(Icons.account_circle_outlined),
                          label: const Text('Continuar con Google'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  isLogin = !isLogin;
                                  error = null;
                                }),
                          child: Text(
                            isLogin
                                ? '¿No tienes cuenta? Regístrate'
                                : '¿Ya tienes cuenta? Entra',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          'Tus datos se sincronizan de forma privada con tu cuenta.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (!email.contains('@') || password.length < 6) {
      setState(
        () => error =
            'Usa un correo válido y una contraseña de al menos 6 caracteres.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (isLogin) {
        await AuthService.signInWithEmail(email, password);
      } else {
        await AuthService.createWithEmail(email, password);
      }
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = _authMessage(exception);
      });
    }
  }

  Future<void> _google() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AuthService.signInWithGoogle();
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error = _authMessage(exception);
      });
    }
  }

  String _authMessage(Object exception) {
    if (exception is GoogleSignInException) {
      switch (exception.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Acceso con Google cancelado.';
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google no está configurado para esta versión de la app.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'No se pudo abrir el acceso con Google.';
        default:
          return 'Google no pudo completar el acceso. Inténtalo de nuevo.';
      }
    }
    if (exception is supabase.AuthException) {
      switch (exception.code) {
        case 'invalid-credential':
        case 'invalid_credentials':
        case 'wrong-password':
          return 'El correo o la contraseña no son correctos.';
        case 'email-already-in-use':
        case 'email_exists':
          return 'Ese correo ya tiene una cuenta.';
        case 'email-not-confirmed':
          return exception.message;
        case 'network-request-failed':
          return 'No hay conexión. Comprueba tu red e inténtalo de nuevo.';
      }
    }
    return 'No se pudo completar el acceso. Inténtalo de nuevo.';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.state});

  final AppState state;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  Future<void> _showTutorialIfNeeded() async {
    if (!mounted ||
        widget.state.user == null ||
        widget.state.tutorialCompleted) {
      return;
    }
    await showStudiaryTutorial(context, widget.state);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        state: widget.state,
        onAddEvent: () => showEventEditor(context, widget.state),
        onOpenSubjects: () => setState(() => index = 2),
        onStartStudy: () => setState(() => index = 3),
      ),
      AgendaPage(state: widget.state),
      SubjectsPage(state: widget.state),
      StudyPage(state: widget.state),
      ProgressPage(state: widget.state),
      ProfilePage(state: widget.state),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: index,
                children: [
                  for (var page = 0; page < pages.length; page++)
                    TickerMode(enabled: index == page, child: pages[page]),
                ],
              ),
            ),
            AdBanner(visible: !widget.state.premium),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Materias',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: 'Estudio',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.state,
    required this.onAddEvent,
    required this.onOpenSubjects,
    required this.onStartStudy,
  });

  final AppState state;
  final VoidCallback onAddEvent;
  final VoidCallback onOpenSubjects;
  final VoidCallback onStartStudy;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayEvents = state.eventsOn(today);
    final nextExam =
        state.events
            .where(
              (event) =>
                  event.type == EventType.examen &&
                  event.startDate.isAfter(today),
            )
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final name = state.user?.displayName?.split(' ').first ?? 'estudiante';
    final completion = state.totalObjectives == 0
        ? 0.0
        : state.completedObjectives / state.totalObjectives;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  const StudiaryMascot(size: 52, pose: MascotPose.reminder),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $name',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM', 'es_ES').format(today),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: state.user?.photoURL == null
                        ? null
                        : NetworkImage(state.user!.photoURL!),
                    child: state.user?.photoURL == null
                        ? Text(
                            name.characters.first.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _FocusCard(state: state),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${todayEvents.length}',
                      label: 'planes hoy',
                      icon: Icons.event_available_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      value: nextExam.isEmpty
                          ? 'Sin dato'
                          : '${nextExam.first.startDate.difference(today).inDays} d',
                      label: 'para el próximo examen',
                      icon: Icons.flag_outlined,
                      tint: coralDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SectionHeading(
                title: 'Tu día',
                action: 'Añadir',
                onAction: onAddEvent,
              ),
              if (todayEvents.isEmpty)
                EmptyState(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Un día despejado',
                  message:
                      'Añade una clase, entrega o sesión de estudio para empezar.',
                  action: 'Crear evento',
                  onAction: onAddEvent,
                )
              else
                SoftCard(
                  child: Column(
                    children: todayEvents
                        .take(5)
                        .map(
                          (event) => EventRow(
                            event: event,
                            onTap: () =>
                                showEventDetails(context, state, event),
                            subjectName: _subjectName(state, event.subjectId),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 22),
              const SectionHeading(title: 'Acciones rápidas'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _QuickAction(
                    icon: Icons.add_rounded,
                    label: 'Nuevo evento',
                    onTap: onAddEvent,
                  ),
                  _QuickAction(
                    icon: Icons.menu_book_outlined,
                    label: 'Asignaturas',
                    onTap: onOpenSubjects,
                  ),
                  _QuickAction(
                    icon: Icons.note_alt_outlined,
                    label: 'Nueva nota',
                    onTap: () => showNoteEditor(context, state),
                  ),
                  _QuickAction(
                    icon: Icons.timer_outlined,
                    label: 'Empezar a estudiar',
                    onTap: onStartStudy,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SectionHeading(
                title: 'Objetivos',
                action: '${(completion * 100).round()}%',
              ),
              SoftCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: completion,
                            strokeWidth: 7,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          Text(
                            '${(completion * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.totalObjectives == 0
                                ? 'Define tu primer objetivo'
                                : '${state.completedObjectives} de ${state.totalObjectives} completados',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Pequeños avances, una semana más clara.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const StudiaryMascot(size: 72, pose: MascotPose.focus),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Momento de enfocarte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  state.focusMinutes == 0
                      ? 'Una sesión corta puede cambiar tu tarde.'
                      : '${state.focusMinutes} minutos de estudio acumulados.',
                  style: TextStyle(
                    color: scheme.onInverseSurface.withValues(alpha: .78),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showStudyMessage(context),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agenda',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Todo lo importante, a la vista.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showEventEditor(context, state),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Mes'),
              Tab(text: 'Semana'),
              Tab(text: 'Año'),
              Tab(text: 'Horarios'),
              Tab(text: 'Notas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                MonthlyAgenda(state: state),
                WeeklyAgenda(state: state),
                AnnualAgenda(state: state),
                ScheduleAgenda(state: state),
                NotesAgenda(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyAgenda extends StatefulWidget {
  const MonthlyAgenda({super.key, required this.state});

  final AppState state;

  @override
  State<MonthlyAgenda> createState() => _MonthlyAgendaState();
}

class _MonthlyAgendaState extends State<MonthlyAgenda> {
  DateTime selected = DateTime.now();
  DateTime visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final events = widget.state.eventsOn(selected);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _MonthCalendar(
          month: visibleMonth,
          selected: selected,
          events: widget.state.events,
          onDaySelected: (date) => setState(() => selected = date),
          onMonthChanged: _moveMonth,
        ),
        const SizedBox(height: 18),
        SectionHeading(
          title: DateFormat('d MMMM', 'es_ES').format(selected),
          action: '${events.length} planes',
        ),
        if (events.isEmpty)
          EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Sin planes para este día',
            message: 'Elige otra fecha o crea un nuevo evento.',
            action: 'Añadir evento',
            onAction: () =>
                showEventEditor(context, widget.state, initialDate: selected),
          )
        else
          SoftCard(
            child: Column(
              children: events
                  .map(
                    (event) => EventRow(
                      event: event,
                      onTap: () =>
                          showEventDetails(context, widget.state, event),
                      subjectName: _subjectName(widget.state, event.subjectId),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _moveMonth(int offset) {
    final next = DateTime(visibleMonth.year, visibleMonth.month + offset);
    if (next.year < 2000 || next.year > 2100) return;
    final daysInMonth = DateTime(next.year, next.month + 1, 0).day;
    final day = selected.day > daysInMonth ? daysInMonth : selected.day;
    setState(() {
      visibleMonth = next;
      selected = DateTime(next.year, next.month, day);
    });
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.selected,
    required this.events,
    required this.onDaySelected,
    required this.onMonthChanged,
  });

  final DateTime month;
  final DateTime selected;
  final List<PlannerEvent> events;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingDays = DateTime(month.year, month.month).weekday - 1;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final canGoPrevious = month.year > 2000 || month.month > 1;
    final canGoNext = month.year < 2100 || month.month < 12;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'es_ES').format(month),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: canGoPrevious ? () => onMonthChanged(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: canGoNext ? () => onMonthChanged(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: 48,
            ),
            itemBuilder: (context, index) {
              if (index < leadingDays || index >= leadingDays + daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(
                month.year,
                month.month,
                index - leadingDays + 1,
              );
              final dayEvents = events
                  .where((event) => plannerEventOccursOn(event, date))
                  .toList();
              final active = DateUtils.isSameDay(date, selected);
              final today = DateUtils.isSameDay(date, DateTime.now());
              final dayColor = active ? scheme.onPrimary : scheme.onSurface;
              return InkWell(
                onTap: () => onDaySelected(date),
                borderRadius: BorderRadius.circular(13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: active ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: today && !active
                          ? scheme.primary
                          : scheme.outlineVariant.withValues(alpha: .55),
                      width: today && !active ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: dayColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 7,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final event in dayEvents.take(3))
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? scheme.onPrimary
                                      : eventTypeColor(event.type),
                                ),
                              ),
                            if (dayEvents.length > 3)
                              Text(
                                '+${dayEvents.length - 3}',
                                style: TextStyle(
                                  color: active
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class WeeklyAgenda extends StatefulWidget {
  const WeeklyAgenda({super.key, required this.state});

  final AppState state;

  @override
  State<WeeklyAgenda> createState() => _WeeklyAgendaState();
}

enum _AgendaWeekMode { list, calendar }

class _WeeklyAgendaState extends State<WeeklyAgenda> {
  DateTime selected = DateTime.now();
  _AgendaWeekMode mode = _AgendaWeekMode.calendar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monday = DateTime(
      selected.year,
      selected.month,
      selected.day - selected.weekday + 1,
    );
    final days = List.generate(
      7,
      (index) => DateTime(monday.year, monday.month, monday.day + index),
    );
    final events = widget.state.eventsOn(selected);
    final weekEvents = widget.state.events.where((event) {
      return days.any((day) => plannerEventOccursOn(event, day));
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        WeeklyPaperHeader(
          title: 'Agenda semanal',
          subtitle:
              '${DateFormat('d MMM', 'es_ES').format(days.first)} - ${DateFormat('d MMM', 'es_ES').format(days.last)}',
        ),
        const SizedBox(height: 12),
        _AgendaModeSwitcher(
          mode: mode,
          onChanged: (value) => setState(() => mode = value),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final active = DateUtils.isSameDay(day, selected);
              final count = widget.state.eventsOn(day).length;
              return InkWell(
                onTap: () => setState(() => selected = day),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('EEE', 'es_ES').format(day).substring(0, 2),
                        style: TextStyle(
                          color: active
                              ? scheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: active ? scheme.onPrimary : null,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      if (count > 0)
                        Text(
                          '$count',
                          style: TextStyle(
                            color: active
                                ? scheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (mode == _AgendaWeekMode.calendar) ...[
          WeeklyAgendaGrid(
            weekStart: monday,
            events: weekEvents,
            selectedDay: selected,
            onSelectDay: (day) => setState(() => selected = day),
            onEventTap: (event) =>
                showEventDetails(context, widget.state, event),
            onSlotTap: (day) =>
                showEventEditor(context, widget.state, initialDate: day),
          ),
          const SizedBox(height: 18),
          SectionHeading(
            title: DateFormat('EEEE, d MMMM', 'es_ES').format(selected),
            action: '${events.length} planes',
          ),
          if (events.isEmpty)
            EmptyState(
              icon: Icons.wb_sunny_outlined,
              title: 'Nada programado',
              message: 'Este espacio está listo para tu próximo plan.',
              action: 'Añadir evento',
              onAction: () =>
                  showEventEditor(context, widget.state, initialDate: selected),
            )
          else
            SoftCard(
              child: Column(
                children: events
                    .map(
                      (event) => EventRow(
                        event: event,
                        onTap: () =>
                            showEventDetails(context, widget.state, event),
                        subjectName: _subjectName(
                          widget.state,
                          event.subjectId,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ] else
          _WeeklyAgendaList(
            days: days,
            events: weekEvents,
            state: widget.state,
            onEventTap: (event) =>
                showEventDetails(context, widget.state, event),
            onAdd: () => showEventEditor(context, widget.state),
          ),
      ],
    );
  }
}

class _AgendaModeSwitcher extends StatelessWidget {
  const _AgendaModeSwitcher({required this.mode, required this.onChanged});

  final _AgendaWeekMode mode;
  final ValueChanged<_AgendaWeekMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final control = SegmentedButton<_AgendaWeekMode>(
      segments: const [
        ButtonSegment(
          value: _AgendaWeekMode.list,
          icon: Icon(Icons.view_list_rounded),
          label: Text('Lista'),
        ),
        ButtonSegment(
          value: _AgendaWeekMode.calendar,
          icon: Icon(Icons.calendar_view_month_rounded),
          label: Text('Calendario'),
        ),
      ],
      selected: {mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) onChanged(selection.first);
      },
    );
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: weeklyPaperTint(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Text(
            'Vista semanal',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          );
          if (constraints.maxWidth < 430) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: control),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              control,
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyAgendaList extends StatelessWidget {
  const _WeeklyAgendaList({
    required this.days,
    required this.events,
    required this.state,
    required this.onEventTap,
    required this.onAdd,
  });

  final List<DateTime> days;
  final List<PlannerEvent> events;
  final AppState state;
  final ValueChanged<PlannerEvent> onEventTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    for (final day in days) {
      final dayEvents =
          events.where((event) => plannerEventOccursOn(event, day)).toList()
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
      if (dayEvents.isEmpty) continue;
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMMM', 'es_ES').format(day),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dayEvents.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14),
                ...dayEvents.map(
                  (event) => EventRow(
                    event: event,
                    onTap: () => onEventTap(event),
                    subjectName: _subjectName(state, event.subjectId),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (sections.isEmpty) {
      return EmptyState(
        icon: Icons.event_note_outlined,
        title: 'Semana libre',
        message: 'Añade un evento para organizar tu próxima semana.',
        action: 'Añadir evento',
        onAction: onAdd,
      );
    }
    return Column(children: sections);
  }
}

class AnnualAgenda extends StatelessWidget {
  const AnnualAgenda({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          sliver: SliverToBoxAdapter(
            child: SectionHeading(
              title: 'Plan anual $year',
              action: 'Añadir',
              onAction: () => showEventEditor(context, state),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final month = index + 1;
              return _YearMonthCard(
                year: year,
                month: month,
                events: state.events,
                onDayTap: (date, events) =>
                    _showAnnualDayEvents(context, state, date, events),
              );
            }, childCount: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 244,
            ),
          ),
        ),
      ],
    );
  }
}

class _YearMonthCard extends StatelessWidget {
  const _YearMonthCard({
    required this.year,
    required this.month,
    required this.events,
    required this.onDayTap,
  });

  final int year;
  final int month;
  final List<PlannerEvent> events;
  final void Function(DateTime date, List<PlannerEvent> events) onDayTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstDay = DateTime(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingDays = firstDay.weekday - 1;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final monthStart = DateTime(year, month);
    final monthEnd = DateTime(year, month, daysInMonth, 23, 59, 59, 999);
    final monthEvents = events.where((event) {
      final eventEnd = event.endDate ?? event.startDate;
      return !eventEnd.isBefore(monthStart) &&
          !event.startDate.isAfter(monthEnd);
    }).toList();

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM', 'es_ES').format(firstDay).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: .3,
                  ),
                ),
              ),
              Text(
                '${monthEvents.length}',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                if (index < leadingDays || index >= leadingDays + daysInMonth) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(year, month, index - leadingDays + 1);
                final dayEvents = events
                    .where((event) => plannerEventOccursOn(event, date))
                    .toList();
                final hasEvents = dayEvents.isNotEmpty;
                final eventColor = hasEvents
                    ? eventTypeColor(dayEvents.first.type)
                    : scheme.primary;
                final today = DateUtils.isSameDay(date, DateTime.now());
                return InkWell(
                  onTap: () => onDayTap(date, dayEvents),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: today
                          ? scheme.primary
                          : hasEvents
                          ? eventColor.withValues(alpha: .16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: today ? scheme.onPrimary : scheme.onSurface,
                            fontSize: 11,
                            fontWeight: hasEvents || today
                                ? FontWeight.w900
                                : FontWeight.w600,
                          ),
                        ),
                        if (hasEvents)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: today ? scheme.onPrimary : eventColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              monthEvents.isEmpty
                  ? 'Toca un día para añadir'
                  : monthEvents.length == 1
                  ? '1 plan guardado'
                  : '${monthEvents.length} planes guardados',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAnnualDayEvents(
  BuildContext pageContext,
  AppState state,
  DateTime date,
  List<PlannerEvent> events,
) async {
  if (events.isEmpty) {
    await showEventEditor(pageContext, state, initialDate: date);
    return;
  }
  await showDialog<void>(
    context: pageContext,
    builder: (dialogContext) => AlertDialog(
      title: Text(DateFormat('EEEE, d MMMM', 'es_ES').format(date)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: events
                .map(
                  (event) => EventRow(
                    event: event,
                    subjectName: _subjectName(state, event.subjectId),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      showEventDetails(pageContext, state, event);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            showEventEditor(pageContext, state, initialDate: date);
          },
          child: const Text('Añadir aquí'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class ScheduleAgenda extends StatefulWidget {
  const ScheduleAgenda({super.key, required this.state});

  final AppState state;

  @override
  State<ScheduleAgenda> createState() => _ScheduleAgendaState();
}

class _ScheduleAgendaState extends State<ScheduleAgenda> {
  String selectedProfileId = 'default';

  @override
  Widget build(BuildContext context) {
    final profiles = widget.state.profiles;
    if (profiles.isEmpty) return const SizedBox.shrink();
    final activeProfileId =
        profiles.any((profile) => profile.id == selectedProfileId)
        ? selectedProfileId
        : profiles.first.id;
    final activeProfile = profiles.firstWhere(
      (profile) => profile.id == activeProfileId,
    );
    final canDeleteProfile =
        activeProfile.id != 'default' && profiles.length > 1;
    final entries =
        widget.state.schedule
            .where((entry) => entry.profileId == activeProfileId)
            .toList()
          ..sort(
            (a, b) => a.dayOfWeek != b.dayOfWeek
                ? a.dayOfWeek.compareTo(b.dayOfWeek)
                : a.startTime.compareTo(b.startTime),
          );
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    final weekEvents =
        widget.state.events
            .where(
              (event) => List.generate(
                7,
                (index) => plannerEventOccursOn(
                  event,
                  monday.add(Duration(days: index)),
                ),
              ).contains(true),
            )
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SchoolScheduleHeader(
          subtitle: entries.isEmpty
              ? 'Organiza tus clases de lunes a sábado.'
              : '${entries.length} ${entries.length == 1 ? 'clase programada' : 'clases programadas'}',
        ),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_view_week_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: activeProfileId,
                    items: profiles
                        .map(
                          (profile) => DropdownMenuItem(
                            value: profile.id,
                            child: Text(profile.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedProfileId = value);
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Nuevo horario',
                onPressed: _addProfile,
                icon: const Icon(Icons.add_rounded),
              ),
              if (canDeleteProfile)
                IconButton(
                  tooltip: 'Eliminar horario actual',
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () =>
                      _deleteProfile(activeProfile, entries.length),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WeeklyScheduleBoard(
          showHeader: false,
          entries: entries,
          subjects: widget.state.subjects,
          onAdd: (day, hour) => showScheduleEditor(
            context,
            widget.state,
            profileId: activeProfileId,
            initialDay: day,
            initialStart: TimeOfDay(hour: hour, minute: 0),
            initialEnd: TimeOfDay(hour: (hour + 1).clamp(0, 23), minute: 0),
          ),
          onEdit: (entry) =>
              showScheduleEditor(context, widget.state, entry: entry),
          onDelete: widget.state.deleteScheduleEntry,
        ),
        const SizedBox(height: 22),
        SectionHeading(
          title: 'Planes de la semana',
          action: 'Añadir',
          onAction: () => showEventEditor(context, widget.state),
        ),
        if (weekEvents.isEmpty)
          EmptyState(
            icon: Icons.event_note_outlined,
            title: 'Aún no hay planes',
            message:
                'Aquí verás clases, prácticas, exámenes y eventos personales.',
            action: 'Crear evento',
            onAction: () => showEventEditor(context, widget.state),
          )
        else
          SoftCard(
            child: Column(
              children: weekEvents
                  .map(
                    (event) => EventRow(
                      event: event,
                      onTap: () =>
                          showEventDetails(context, widget.state, event),
                      subjectName: _subjectName(widget.state, event.subjectId),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _addProfile() async {
    if (!widget.state.premium && widget.state.profiles.isNotEmpty) {
      await showPremiumUpsell(
        context,
        feature: 'Varios horarios para distintos cursos o semestres',
      );
      return;
    }
    final name = await showScheduleProfileEditor(context);
    if (!mounted || name == null || name.trim().isEmpty) return;
    widget.state.addScheduleProfile(name.trim());
    setState(() => selectedProfileId = widget.state.profiles.last.id);
  }

  Future<void> _deleteProfile(ScheduleProfile profile, int classCount) async {
    final confirmed = await confirmDeleteScheduleProfile(
      context,
      profileName: profile.name,
      classCount: classCount,
    );
    if (!mounted || !confirmed) return;
    if (!widget.state.deleteScheduleProfile(profile.id)) return;
    setState(() => selectedProfileId = widget.state.profiles.first.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Se ha eliminado «${profile.name}»')),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  const _TimetableCard({
    required this.entries,
    required this.subjects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  static const _firstHour = 7;
  static const _lastHour = 22;
  static const _timeWidth = 62.0;
  static const _dayWidth = 116.0;
  static const _rowHeight = 72.0;
  static const _dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _dayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ScheduleEntry>>{};
    for (final entry in entries) {
      final hour = _hour(entry.startTime);
      if (entry.dayOfWeek >= 1 &&
          entry.dayOfWeek <= 7 &&
          hour >= _firstHour &&
          hour < _lastHour) {
        grouped.putIfAbsent('${entry.dayOfWeek}-$hour', () => []).add(entry);
      }
    }
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _timeWidth + _dayWidth * 7,
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: _timeWidth, height: 46),
                  for (var day = 1; day <= 7; day++)
                    Container(
                      width: _dayWidth,
                      height: 46,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Semantics(
                        label: _dayNames[day - 1],
                        child: Text(
                          _dayLetters[day - 1],
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
              for (var hour = _firstHour; hour < _lastHour; hour++)
                Row(
                  children: [
                    SizedBox(
                      width: _timeWidth,
                      height: _rowHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    for (var day = 1; day <= 7; day++)
                      _TimetableCell(
                        day: day,
                        hour: hour,
                        entries: grouped['$day-$hour'] ?? const [],
                        subjects: subjects,
                        onAdd: onAdd,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static int _hour(String value) {
    final hour = int.tryParse(value.split(':').first) ?? _firstHour;
    return hour.clamp(0, 23);
  }
}

class _TimetableCell extends StatelessWidget {
  const _TimetableCell({
    required this.day,
    required this.hour,
    required this.entries,
    required this.subjects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final int hour;
  final List<ScheduleEntry> entries;
  final List<Subject> subjects;
  final void Function(int day, int hour) onAdd;
  final ValueChanged<ScheduleEntry> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      width: _TimetableCard._dayWidth,
      height: _TimetableCard._rowHeight,
      margin: const EdgeInsets.only(right: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
        border: Border.all(color: border.withValues(alpha: .68)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: entries.isEmpty
          ? InkWell(
              onTap: () => onAdd(day, hour),
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            )
          : Column(
              children: entries
                  .map(
                    (entry) => Expanded(
                      child: _ScheduleEntryTile(
                        entry: entry,
                        subject: subjects
                            .where((subject) => subject.id == entry.subjectId)
                            .firstOrNull,
                        onTap: () => onEdit(entry),
                        onDelete: () => onDelete(entry.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ScheduleEntryTile extends StatelessWidget {
  const _ScheduleEntryTile({
    required this.entry,
    required this.subject,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleEntry entry;
  final Subject? subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = subject == null
        ? Theme.of(context).colorScheme.primary
        : colorFromHex(subject!.color);
    return Material(
      color: color.withValues(alpha: .24),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 7, 23, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject?.name ?? 'Asignatura',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${entry.startTime} - ${entry.endTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: PopupMenuButton<String>(
                tooltip: 'Opciones de ${subject?.name ?? 'clase'}',
                iconSize: 18,
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                  if (value == 'edit') onTap();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesAgenda extends StatelessWidget {
  const NotesAgenda({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final activeNotes = state.notes.where((note) => !note.archived).toList();
    final archivedNotes = state.notes.where((note) => note.archived).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeading(
          title: 'Notas',
          action: 'Nueva',
          onAction: () => showNoteEditor(context, state),
        ),
        if (activeNotes.isEmpty && archivedNotes.isEmpty)
          EmptyState(
            icon: Icons.note_alt_outlined,
            title: 'Tu biblioteca está vacía',
            message:
                'Guarda apuntes breves para volver a ellos cuando los necesites.',
            action: 'Crear nota',
            onAction: () => showNoteEditor(context, state),
          )
        else
          ...activeNotes.map((note) => _noteCard(context, note)),
        if (archivedNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeading(title: 'Archivados'),
          ...archivedNotes.map((note) => _noteCard(context, note)),
        ],
      ],
    );
  }

  Widget _noteCard(BuildContext context, PlannerNote note) {
    final subtitle = switch (note.type) {
      NoteType.text || NoteType.link => note.content,
      NoteType.pdf || NoteType.file => note.fileName ?? 'Documento',
      NoteType.image => note.fileName ?? 'Imagen',
      NoteType.video => note.fileName ?? 'Vídeo',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(switch (note.type) {
            NoteType.pdf || NoteType.file => Icons.description_outlined,
            NoteType.image => Icons.image_outlined,
            NoteType.video => Icons.video_library_outlined,
            NoteType.link => Icons.link_rounded,
            NoteType.text => Icons.notes_rounded,
          }),
          title: Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Wrap(
            spacing: 0,
            children: [
              if ((note.type == NoteType.text ||
                  note.type == NoteType.link ||
                  note.fileUrl != null ||
                  note.fileDataUri != null))
                IconButton(
                  tooltip: 'Abrir',
                  onPressed: () => showNotePreview(context, note, state: state),
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              IconButton(
                tooltip: note.archived ? 'Restaurar' : 'Archivar',
                onPressed: () => state.setNoteArchived(note.id, !note.archived),
                icon: Icon(
                  note.archived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: () => state.deleteNote(note.id),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudyPage extends StatefulWidget {
  const StudyPage({super.key, required this.state});

  final AppState state;

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  Timer? timer;
  FocusSession? session;
  int selectedMinutes = 25;
  String? selectedSubjectId;
  SharedPreferences? prefs;
  String? sessionUserId;
  bool restoring = true;
  bool finishing = false;
  Future<void> sessionWrites = Future.value();
  bool get running => session?.running ?? false;
  int get seconds => session?.remaining(DateTime.now()) ?? selectedMinutes * 60;
  String get sessionKey => 'studiary-focus-$sessionUserId';

  @override
  void initState() {
    super.initState();
    sessionUserId = widget.state.user?.id;
    selectedSubjectId = widget.state.subjects.firstOrNull?.id;
    unawaited(_restoreSession());
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || session == null || finishing) return;
      if (running && seconds == 0) {
        unawaited(_finish());
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _restoreSession() async {
    prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = prefs!.getString(sessionKey);
    try {
      if (raw != null) {
        session = FocusSession.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        selectedSubjectId = session!.subjectId;
        selectedMinutes = session!.totalSeconds ~/ 60;
      }
    } on FormatException {
      await prefs!.remove(sessionKey);
    } on TypeError {
      await prefs!.remove(sessionKey);
    }
    if (mounted) setState(() => restoring = false);
  }

  Future<void> _persistSession() {
    final encoded = session == null ? null : jsonEncode(session!.toMap());
    sessionWrites = sessionWrites.catchError((Object _) {}).then((_) async {
      if (encoded == null) {
        await prefs?.remove(sessionKey);
      } else {
        await prefs?.setString(sessionKey, encoded);
      }
    });
    return sessionWrites;
  }

  @override
  void didUpdateWidget(covariant StudyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (session == null &&
        !widget.state.subjects.any((s) => s.id == selectedSubjectId)) {
      selectedSubjectId = widget.state.subjects.firstOrNull?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          'Modo estudio',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Una sesión enfocada vale más que una tarde dispersa.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SoftCard(
          color: scheme.inverseSurface,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            children: [
              Text(
                restoring
                    ? 'Recuperando sesión…'
                    : running
                    ? 'En curso'
                    : session != null
                    ? 'Sesión en pausa'
                    : 'Listo para empezar',
                style: TextStyle(
                  color: scheme.onInverseSurface.withValues(alpha: .78),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$minutes:$remainder',
                style: TextStyle(
                  color: scheme.onInverseSurface,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onInverseSurface,
                      side: BorderSide(
                        color: scheme.onInverseSurface.withValues(alpha: .42),
                      ),
                    ),
                    child: const Text('Terminar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: restoring || finishing ? null : _toggleTimer,
                    icon: Icon(
                      running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      running
                          ? 'Pausar'
                          : session == null
                          ? 'Empezar'
                          : 'Continuar',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SoftCard(
          color: scheme.primaryContainer.withValues(alpha: .48),
          child: Row(
            children: [
              Icon(Icons.menu_book_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: widget.state.subjects.isEmpty
                    ? const Text(
                        'Añade una asignatura para registrar el tiempo.',
                      )
                    : DropdownButtonFormField<String>(
                        initialValue:
                            widget.state.subjects.any(
                              (subject) => subject.id == selectedSubjectId,
                            )
                            ? selectedSubjectId
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: '¿Qué vas a estudiar?',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: widget.state.subjects
                            .map(
                              (subject) => DropdownMenuItem(
                                value: subject.id,
                                child: Text(subject.name),
                              ),
                            )
                            .toList(),
                        onChanged: session != null || restoring
                            ? null
                            : (value) =>
                                  setState(() => selectedSubjectId = value),
                      ),
              ),
              if (widget.state.subjects.isEmpty)
                IconButton(
                  tooltip: 'Crear asignatura',
                  onPressed: () => showSubjectManager(context, widget.state),
                  icon: const Icon(Icons.add_rounded),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeading(title: 'Duración'),
        Wrap(
          spacing: 8,
          children: [15, 25, 45, 60]
              .map(
                (value) => ChoiceChip(
                  label: Text('$value min'),
                  selected: selectedMinutes == value,
                  onSelected: (_) {
                    if (value == 60 && !widget.state.premium) {
                      showPremiumUpsell(
                        context,
                        feature: 'Las sesiones de 60 minutos',
                      );
                      return;
                    }
                    if (session == null && !restoring) {
                      setState(() {
                        selectedMinutes = value;
                      });
                    }
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '${widget.state.focusMinutes}',
                label: 'minutos acumulados',
                icon: Icons.hourglass_bottom_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: '${widget.state.focusDays.length}',
                label: 'días con foco',
                icon: Icons.local_fire_department_outlined,
                tint: coralDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SoftCard(
          child: Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Deja el móvil lejos y elige un único objetivo para esta sesión.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleTimer() async {
    if (restoring || finishing) return;
    if (running) {
      setState(() => session!.pause(DateTime.now()));
    } else {
      if (session == null &&
          !widget.state.subjects.any((s) => s.id == selectedSubjectId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Elige una asignatura antes de empezar.'),
          ),
        );
        return;
      }
      setState(() {
        session ??= FocusSession.start(
          selectedSubjectId!,
          selectedMinutes,
          DateTime.now(),
        );
        session!.resume(DateTime.now());
      });
    }
    await _persistSession();
  }

  Future<void> _finish() async {
    if (finishing ||
        session == null ||
        widget.state.user?.id != sessionUserId) {
      return;
    }
    finishing = true;
    final finished = session!;
    finished.pause(DateTime.now());
    await _persistSession();
    final minutes = finished.studiedMinutes(DateTime.now());
    try {
      widget.state.completeFocusSession(
        minutes,
        subjectId: finished.subjectId,
        startedAt: finished.startedAt,
        sessionId: finished.id,
      );
      // Keep the persisted timer until its idempotent history entry is durable.
      await widget.state.saveLocally();
      session = null;
      await _persistSession();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              minutes > 0
                  ? '$minutes minutos guardados. ¡Buen trabajo!'
                  : 'Sesión finalizada. No se ha completado un minuto.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Tu sesión sigue disponible.'),
          ),
        );
      }
    } finally {
      finishing = false;
    }
  }

  Future<void> _reset() async {
    if (session == null || restoring || finishing) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminar sesión'),
        content: const Text(
          'Puedes guardar los minutos estudiados o descartar esta sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Guardar tiempo'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _finish();
    }
    if (result == 'discard') {
      session = null;
      await _persistSession();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final graded = state.events.where((event) => event.grade != null).toList();
    final progress = state.totalObjectives == 0
        ? 0.0
        : state.completedObjectives / state.totalObjectives;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          'Tu progreso',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Señales sencillas para saber cómo vas.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: state.averageGrade == 0
                    ? 'Sin dato'
                    : state.averageGrade.toStringAsFixed(1),
                label: 'media académica',
                icon: Icons.school_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: '${state.focusMinutes} min',
                label: 'tiempo de foco',
                icon: Icons.timer_outlined,
                tint: coralDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: '${state.events.length}',
                label: 'planes creados',
                icon: Icons.event_note_outlined,
                tint: const Color(0xFF4C72C8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: '${state.focusDays.length}',
                label: 'días activos',
                icon: Icons.calendar_today_outlined,
                tint: const Color(0xFF2D806A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Objetivos de asignaturas'),
        SoftCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${state.completedObjectives} de ${state.totalObjectives} completados',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Ritmo de estudio'),
        if (state.premium)
          _AdvancedInsights(state: state)
        else
          SoftCard(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Premium añade un resumen de tus días de estudio para ayudarte a crear un hábito.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        SectionHeading(
          title: 'Calificaciones',
          action: graded.isEmpty ? null : '${graded.length} exámenes',
        ),
        if (graded.isEmpty)
          const EmptyState(
            icon: Icons.grade_outlined,
            title: 'Aún no hay calificaciones',
            message: 'Añade la nota de un examen para ver tu media aquí.',
          )
        else
          SoftCard(
            child: Column(
              children: graded
                  .take(8)
                  .map(
                    (event) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'd MMMM yyyy',
                          'es_ES',
                        ).format(event.startDate),
                      ),
                      trailing: Text(
                        event.grade!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: event.grade! >= 5
                              ? const Color(0xFF2D806A)
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _AdvancedInsights extends StatelessWidget {
  const _AdvancedInsights({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - 6 + index),
    );
    final active = days
        .map((day) => state.focusDays.contains(_dateKey(day)))
        .toList();
    final activeCount = active.where((value) => value).length;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded),
              const SizedBox(width: 10),
              Text(
                '$activeCount de 7 días con foco',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var index = 0; index < days.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: active[index]
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            active[index]
                                ? Icons.check_rounded
                                : Icons.remove_rounded,
                            color: active[index]
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.outline,
                            size: 19,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'E',
                            'es_ES',
                          ).format(days[index]).substring(0, 1).toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${state.focusMinutes} minutos acumulados en total',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    final name =
        user?.displayName ?? user?.email?.split('@').first ?? 'Estudiante';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          'Perfil',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 22),
        SoftCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: user?.photoURL == null
                    ? null
                    : NetworkImage(user!.photoURL!),
                child: user?.photoURL == null
                    ? Text(
                        name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _PremiumCard(state: state),
        const SizedBox(height: 20),
        const SectionHeading(title: 'Tu espacio'),
        SoftCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Asignaturas'),
                subtitle: Text('${state.subjects.length} configuradas'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showSubjectManager(context, state),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('Ver tutorial de Studi'),
                subtitle: const Text('Repasa cómo funciona la app'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showStudiaryTutorial(context, state),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Tema de la app'),
                subtitle: Text(_appearanceLabel(state.appearanceMode)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.appearanceMode,
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('Sistema')),
                      DropdownMenuItem(value: 'light', child: Text('Claro')),
                      DropdownMenuItem(value: 'dark', child: Text('Oscuro')),
                    ],
                    onChanged: (value) {
                      if (value != null) state.setAppearanceMode(value);
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.color_lens_outlined),
                title: const Text('Colores y estilo'),
                subtitle: const Text('Personaliza el fondo, botones y texto'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showThemeCustomizer(context, state),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.cloud_done_outlined,
                  color: state.syncError != null
                      ? Theme.of(context).colorScheme.error
                      : state.syncing
                      ? coralDeep
                      : const Color(0xFF2D806A),
                ),
                title: const Text('Sincronización'),
                onTap: () => state.synchronize(),
                subtitle: Text(
                  state.syncError ??
                      (state.syncing
                          ? 'Guardando tus cambios...'
                          : state.hasPendingChanges
                          ? 'Cambios guardados en este dispositivo'
                          : 'Tus datos están sincronizados · toca para actualizar'),
                ),
                trailing: state.syncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        state.syncError != null
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacidad de anuncios'),
                subtitle: const Text(
                  'Gestiona tus preferencias de consentimiento',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await MonetizationService.showPrivacyOptions();
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Política de privacidad'),
                subtitle: const Text('Tus datos, archivos y compras'),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () async {
                  try {
                    final opened = await launchUrl(
                      Uri.parse('https://studiary-app-2026.web.app/privacy'),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened) throw StateError('Browser unavailable');
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No se pudo abrir. Escríbenos a pacuan2417@gmail.com.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthService.signOut();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Eliminar cuenta'),
                content: const Text(
                  'Se eliminarán tu cuenta, tus datos sincronizados y tus adjuntos. '
                  'Esta acción no se puede deshacer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Eliminar cuenta'),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            try {
              await state.deleteAccount();
            } on supabase.AuthException catch (error) {
              if (!context.mounted) return;
              final message = error.code == 'requires-recent-login'
                  ? 'Vuelve a iniciar sesión y repite la eliminación.'
                  : 'No se pudo eliminar la cuenta: ${error.message}';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No se pudo eliminar la cuenta: $error'),
                ),
              );
            }
          },
          child: const Text('Eliminar mi cuenta'),
        ),
      ],
    );
  }
}

class _PremiumCard extends StatefulWidget {
  const _PremiumCard({required this.state});

  final AppState state;

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard> {
  bool loading = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    widget.state.premiumService.addListener(_premiumChanged);
    unawaited(_loadProducts());
  }

  void _premiumChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.state.premiumService.removeListener(_premiumChanged);
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      await widget.state.premiumService.loadProducts();
      if (mounted) setState(() => loadError = null);
    } catch (error) {
      debugPrint('No se pudieron cargar los planes Premium: $error');
      if (mounted) {
        setState(
          () => loadError = 'Los planes no están disponibles ahora mismo.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.state.premium) {
      return SoftCard(
        color: scheme.secondaryContainer,
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: scheme.onSecondaryContainer,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Studiary Premium',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Sin anuncios y con todas las funciones.',
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SoftCard(
      color: scheme.inverseSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: scheme.inversePrimary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estudia con menos ruido',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Premium elimina los anuncios y desbloquea estadísticas avanzadas, sesiones largas y varios horarios. Un único pago, sin suscripción. El precio final se muestra en Google Play.',
            style: TextStyle(
              color: scheme.onInverseSurface.withValues(alpha: .78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.state.premiumService.products.isEmpty)
            Text(
              loadError ??
                  'Los planes aparecerán cuando estén activos en Google Play.',
              style: TextStyle(
                color: scheme.onInverseSurface.withValues(alpha: .68),
                fontSize: 12,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.state.premiumService.products
                  .map(
                    (product) => FilledButton(
                      onPressed:
                          loading ||
                              widget.state.premiumService.pending ||
                              !widget.state.premiumService.verificationReady
                          ? null
                          : () => _buy(product),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: Text('${product.price} · para siempre'),
                    ),
                  )
                  .toList(),
            ),
          if (widget.state.premiumService.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                widget.state.premiumService.message!,
                style: TextStyle(color: scheme.onInverseSurface),
              ),
            ),
          TextButton(
            onPressed: loading || widget.state.premiumService.loading
                ? null
                : _loadProducts,
            style: TextButton.styleFrom(
              foregroundColor: scheme.onInverseSurface,
            ),
            child: const Text('Comprobar disponibilidad'),
          ),
          TextButton(
            onPressed: loading ? null : _restore,
            style: TextButton.styleFrom(
              foregroundColor: scheme.onInverseSurface,
            ),
            child: const Text('Restaurar compras'),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() => loading = true);
    try {
      await widget.state.premiumService.buy(product);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la compra.')),
        );
      }
      debugPrint('No se pudo iniciar la compra Premium: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => loading = true);
    try {
      await widget.state.premiumService.restore();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron restaurar las compras.'),
          ),
        );
      }
      debugPrint('No se pudieron restaurar las compras Premium: $error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

String? _subjectName(AppState state, String? id) {
  if (id == null) return null;
  return state.subjects.where((subject) => subject.id == id).firstOrNull?.name;
}

String _appearanceLabel(String mode) => switch (mode) {
  'light' => 'Claro',
  'dark' => 'Oscuro',
  _ => 'Sigue el tema del sistema',
};

void showStudyMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Abre la pestaña Estudio para empezar tu sesión.'),
    ),
  );
}
