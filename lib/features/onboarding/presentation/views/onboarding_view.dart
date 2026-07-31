import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_footer_widget.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_header_widget.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_page_widget.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_progress_widget.dart';
import 'package:vita_folder_mobile/generated/app_localizations.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingView({super.key, required this.onComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    widget.onComplete();
  }

  void _onNext() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  List<_OnboardingPageData> _pages(AppLocalizations l) => [
        _OnboardingPageData(
          title: l.onboardingTitle1,
          subtitle: l.onboardingSubtitle1,
        ),
        _OnboardingPageData(
          title: l.onboardingTitle2,
          subtitle: l.onboardingSubtitle2,
        ),
        _OnboardingPageData(
          title: l.onboardingTitle3,
          subtitle: l.onboardingSubtitle3,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = _pages(l);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeaderWidget(onSkip: _onSkip),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return OnboardingPageWidget(
                    title: page.title,
                    subtitle: page.subtitle,
                    hero: const _OnboardingHeroWidget(),
                  );
                },
              ),
            ),
            OnboardingProgressWidget(currentPage: _currentPage, pageCount: _pageCount),
            const SizedBox(height: 24),
            OnboardingFooterWidget(
              isLastPage: _currentPage == _pageCount - 1,
              onNext: _onNext,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHeroWidget extends StatelessWidget {
  const _OnboardingHeroWidget();

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 260,
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.family_restroom_rounded,
                    size: 72,
                    color: primary,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 18,
            child: const _OnboardingSmallAvatar(label: 'A'),
          ),
          Positioned(
            right: 14,
            top: 18,
            child: const _OnboardingSmallAvatar(label: 'T'),
          ),
          Positioned(
            right: 32,
            bottom: 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add_alt_1_rounded, size: 18, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.onboardingInviteBadge,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSmallAvatar extends StatelessWidget {
  final String label;

  const _OnboardingSmallAvatar({required this.label});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;

  const _OnboardingPageData({required this.title, required this.subtitle});
}
