import 'package:flutter/material.dart';

import 'app_state.dart';
import 'brand.dart';
import 'widgets.dart';

/// Contenido de la guía breve que aparece la primera vez que una cuenta entra.
/// Se mantiene fuera del widget para poder comprobarlo sin abrir un diálogo.
class StudiaryTutorialStep {
  const StudiaryTutorialStep({
    required this.title,
    required this.message,
    required this.detail,
    required this.pose,
  });

  final String title;
  final String message;
  final String detail;
  final MascotPose pose;
}

const studiaryTutorialSteps = <StudiaryTutorialStep>[
  StudiaryTutorialStep(
    title: 'Te acompaño',
    message: 'Soy Studi. Vamos a dejar tu semana más clara en un minuto.',
    detail: 'Planifica. Estudia. Avanza.',
    pose: MascotPose.encourage,
  ),
  StudiaryTutorialStep(
    title: 'Empieza en Hoy',
    message:
        'Aquí tienes a mano lo que toca: eventos, objetivos y acciones rápidas.',
    detail: 'Pulsa «Añadir» para crear una clase, entrega o sesión.',
    pose: MascotPose.reminder,
  ),
  StudiaryTutorialStep(
    title: 'Mira tu semana',
    message:
        'Agenda cambia entre mes, semana y año para que encuentres cada plan.',
    detail: 'En Horarios puedes guardar tus clases por día y hora.',
    pose: MascotPose.reminder,
  ),
  StudiaryTutorialStep(
    title: 'Entra en foco',
    message:
        'Estudio convierte tu próximo bloque en una sesión de concentración.',
    detail: 'Al terminar, tus minutos se suman automáticamente a tu progreso.',
    pose: MascotPose.focus,
  ),
  StudiaryTutorialStep(
    title: 'Guarda lo importante',
    message: 'Notas reúne apuntes y archivos; Progreso te enseña cómo avanzas.',
    detail: 'Marca objetivos y celebra los pequeños pasos completados.',
    pose: MascotPose.celebrate,
  ),
  StudiaryTutorialStep(
    title: 'Tu cuenta, siempre contigo',
    message:
        'Perfil guarda tus preferencias y sincroniza tus datos con tu cuenta.',
    detail:
        'También puedes activar Premium para quitar anuncios y desbloquear más opciones.',
    pose: MascotPose.encourage,
  ),
];

Future<void> showStudiaryTutorial(BuildContext context, AppState state) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _StudiaryTutorialDialog(),
  );
  if (!state.tutorialCompleted) state.completeTutorial();
}

class _StudiaryTutorialDialog extends StatefulWidget {
  const _StudiaryTutorialDialog();

  @override
  State<_StudiaryTutorialDialog> createState() =>
      _StudiaryTutorialDialogState();
}

class _StudiaryTutorialDialogState extends State<_StudiaryTutorialDialog> {
  int index = 0;

  bool get isLast => index == studiaryTutorialSteps.length - 1;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final step = studiaryTutorialSteps[index];
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudiaryBrand.modalRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: screenHeight * .88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Guía rápida',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Saltar tutorial',
                    onPressed: _finish,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (index + 1) / studiaryTutorialSteps.length,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _TutorialStepBody(key: ValueKey(index), step: step),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var dot = 0; dot < studiaryTutorialSteps.length; dot++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: dot == index ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: dot == index
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(onPressed: _finish, child: const Text('Saltar')),
                  const Spacer(),
                  if (index > 0)
                    TextButton(
                      onPressed: () => setState(() => index--),
                      child: const Text('Atrás'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isLast ? _finish : () => setState(() => index++),
                    icon: Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(isLast ? 'Empezar' : 'Siguiente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finish() => Navigator.of(context).pop();
}

class _TutorialStepBody extends StatelessWidget {
  const _TutorialStepBody({super.key, required this.step});

  final StudiaryTutorialStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 154,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: StudiaryMascot(size: 148, pose: step.pose, animate: false),
          ),
          const SizedBox(height: 18),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            step.message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(StudiaryBrand.controlRadius),
            ),
            child: Text(
              step.detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
