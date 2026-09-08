import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:house_mira/core/auth/auth_service.dart';
import 'package:house_mira/core/widgets/sand/sand_header.dart';
import 'package:house_mira/core/widgets/sand/sand_primary_button.dart';
import 'package:house_mira/core/widgets/sand/sand_text_field.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_cubit.dart';
import 'package:house_mira/features/people/presentation/cubit/invite_people_state.dart';
import 'package:house_mira/generated/app_localizations.dart';
import 'package:house_mira/theme/sand_palette.dart';

class InvitePeopleScreen extends StatefulWidget {
  final String? familyName;

  const InvitePeopleScreen({super.key, this.familyName});

  @override
  State<InvitePeopleScreen> createState() => _InvitePeopleScreenState();
}

class _InvitePeopleScreenState extends State<InvitePeopleScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendInvite(AppLocalizations l) {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.needToBeLoggedIn)));
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    context.read<InvitePeopleCubit>().sendInvite(
      email: email,
      relationship: InviteRelationship.other,
      subject: l.invitePeopleEmailSubject(l.invitePeopleRelationshipOther),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authService = context.read<AuthService>();
    final isLoggedIn = authService.isLoggedIn();
    final familyName = widget.familyName?.trim().isNotEmpty == true
        ? widget.familyName!.trim()
        : null;

    return Scaffold(
      backgroundColor: SandPalette.sand50,
      body: BlocListener<InvitePeopleCubit, InvitePeopleState>(
        listener: (context, state) {
          if (state is InvitePeopleSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l.invitePeopleSent)));
            context.pop();
          }
          if (state is InvitePeopleError) {
            final message = state.code == InvitePeopleErrorCode.sendFailed
                ? l.invitePeopleError
                : state.message ?? '';
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              SandHeader(title: l.invitePeopleTitle),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero icon
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SandPalette.sand100,
                              border: Border.all(color: SandPalette.sand200),
                              boxShadow: [
                                BoxShadow(
                                  color: SandPalette.sand500.withValues(
                                    alpha: 0.10,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: -0.35,
                              child: const Icon(
                                Icons.send_rounded,
                                color: SandPalette.sand600,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title + description
                        Text(
                          l.invitePeopleHeroTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: SandPalette.sand700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (familyName != null)
                          Text.rich(
                            textAlign: TextAlign.center,
                            TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 14,
                                height: 1.5,
                                color: SandPalette.sand400,
                              ),
                              children: [
                                TextSpan(
                                  text: l.invitePeopleHeroDescriptionPrefix,
                                ),
                                TextSpan(
                                  text: familyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: SandPalette.sand600,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          )
                        else
                          Text(
                            l.invitePeopleHeroDescriptionGeneric,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 14,
                              height: 1.5,
                              color: SandPalette.sand400,
                            ),
                          ),
                        const SizedBox(height: 32),

                        // Email field
                        SandLabeledField(
                          controller: _emailController,
                          label: l.invitePeopleEmailAddressLabel.toUpperCase(),
                          hint: l.invitePeopleEmailPlaceholder,
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          enabled: isLoggedIn,
                          validator: (value) {
                            final email = (value ?? '').trim();
                            if (!_emailPattern.hasMatch(email)) {
                              return l.signUpEmailInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),

                        // Avatar cluster (decorative preview)
                        const Center(
                          child: SizedBox(
                            width: _AvatarCluster.totalWidth,
                            height: _AvatarCluster.totalHeight,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: _AvatarBubble(
                                    size: 56,
                                    backgroundColor: Color(0xFFDBEAFE),
                                    textColor: Color(0xFF3B82F6),
                                    label: 'JS',
                                  ),
                                ),
                                Positioned(
                                  left: 44,
                                  top: 6,
                                  child: _DashedPlusBubble(),
                                ),
                                Positioned(
                                  left: 76,
                                  top: 4,
                                  child: _AvatarBubble(
                                    size: 48,
                                    backgroundColor: Color(0xFFFEF3C7),
                                    textColor: Color(0xFFF59E0B),
                                    label: 'MS',
                                    fontSize: 12,
                                  ),
                                ),
                                Positioned(
                                  left: 112,
                                  top: 0,
                                  child: _AvatarBubble(
                                    size: 56,
                                    backgroundColor: Color(0xFFFCE7F3),
                                    textColor: Color(0xFFFB7185),
                                    label: 'LS',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SandPalette.sand50.withValues(alpha: 0),
                      SandPalette.sand50,
                      SandPalette.sand50,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: BlocBuilder<InvitePeopleCubit, InvitePeopleState>(
                    builder: (context, state) {
                      final isLoading = state is InvitePeopleLoading;
                      return SandPrimaryButton(
                        label: l.invitePeopleSend,
                        icon: Icons.send_rounded,
                        isLoading: isLoading,
                        onPressed: isLoading || !isLoggedIn
                            ? null
                            : () => _handleSendInvite(l),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed geometry for the decorative avatar cluster (12px overlap).
abstract final class _AvatarCluster {
  static const double totalWidth = 168;
  static const double totalHeight = 56;
}

class _AvatarBubble extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final String label;
  final double fontSize;

  const _AvatarBubble({
    required this.size,
    required this.backgroundColor,
    required this.textColor,
    required this.label,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: textColor,
        ),
      ),
    );
  }
}

class _DashedPlusBubble extends StatelessWidget {
  const _DashedPlusBubble();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(color: SandPalette.sand300),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: SandPalette.sand50,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add_rounded,
          size: 14,
          color: SandPalette.sand400,
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final radius = size.width / 2;
    const dashLength = 4.0;
    const gapLength = 4.0;
    final circumference = 2 * math.pi * radius;
    double distance = 0;
    while (distance < circumference) {
      final startAngle = distance / radius;
      final sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - 1),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
