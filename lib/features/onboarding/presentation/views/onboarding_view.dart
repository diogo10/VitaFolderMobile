import 'package:flutter/material.dart';
import 'package:vita_folder_mobile/theme/sand_palette.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_footer_widget.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_header_widget.dart';
import 'package:vita_folder_mobile/features/onboarding/presentation/views/onboarding_hero_widget.dart';
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
    if (_currentPage == _pageCount - 1) return;
    _pageController.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
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
      hero: const OnboardingFamilyHeroWidget(),
    ),
    _OnboardingPageData(
      title: l.onboardingTitle2,
      subtitle: l.onboardingSubtitle2,
      hero: const OnboardingRemindersHeroWidget(),
    ),
    _OnboardingPageData(
      title: l.onboardingTitle3,
      subtitle: l.onboardingSubtitle3,
      hero: const OnboardingSecurityHeroWidget(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = _pages(l);
    return Scaffold(
      backgroundColor: SandPalette.sand50,
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
                    hero: page.hero,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  OnboardingProgressWidget(
                    currentPage: _currentPage,
                    pageCount: _pageCount,
                  ),
                  const Spacer(),
                  OnboardingFooterWidget(
                    isLastPage: _currentPage == _pageCount - 1,
                    onNext: _onNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final Widget hero;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.hero,
  });
}
