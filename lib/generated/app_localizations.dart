import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VitaFolder'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get navPeople;

  /// No description provided for @navReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @homeError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get homeError;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get homeTasks;

  /// No description provided for @homeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeCompleted;

  /// No description provided for @homePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get homePending;

  /// No description provided for @homeEmptyHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FamilyAdmin'**
  String get homeEmptyHeaderTitle;

  /// No description provided for @homeEmptyHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get homeEmptyHeaderSubtitle;

  /// No description provided for @homeEmptyHeaderDescription.
  ///
  /// In en, this message translates to:
  /// **'Your family hub is ready. Set it up in a few easy steps.'**
  String get homeEmptyHeaderDescription;

  /// No description provided for @homeEmptyAddPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add people to your Circle'**
  String get homeEmptyAddPeopleTitle;

  /// No description provided for @homeEmptyAddPeopleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite parents, kids or caregivers to your family.'**
  String get homeEmptyAddPeopleSubtitle;

  /// No description provided for @homeEmptyAddPeopleButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeEmptyAddPeopleButton;

  /// No description provided for @homeEmptyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a Reminder'**
  String get homeEmptyReminderTitle;

  /// No description provided for @homeEmptyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule tasks, events and never miss a thing.'**
  String get homeEmptyReminderSubtitle;

  /// No description provided for @homeEmptyReminderButton.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get homeEmptyReminderButton;

  /// No description provided for @homeEmptyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your Account'**
  String get homeEmptyAccountTitle;

  /// No description provided for @homeEmptyAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your name, photo and contact details.'**
  String get homeEmptyAccountSubtitle;

  /// No description provided for @homeEmptyAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get homeEmptyAccountButton;

  /// No description provided for @homeEmptyFooterCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'The Circle'**
  String get homeEmptyFooterCircleTitle;

  /// No description provided for @homeEmptyFooterAddPeopleLink.
  ///
  /// In en, this message translates to:
  /// **'Add people'**
  String get homeEmptyFooterAddPeopleLink;

  /// No description provided for @homeEmptyFooterNoMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get homeEmptyFooterNoMembersTitle;

  /// No description provided for @homeEmptyFooterNoMembersDescription.
  ///
  /// In en, this message translates to:
  /// **'Add family members to start collaborating and tracking together.'**
  String get homeEmptyFooterNoMembersDescription;

  /// No description provided for @homeEmptyFooterAddMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get homeEmptyFooterAddMemberButton;

  /// No description provided for @homeEmptyInviteInviteParentTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a Parent'**
  String get homeEmptyInviteInviteParentTitle;

  /// No description provided for @homeEmptyInviteInviteParentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collaborate in your family hub'**
  String get homeEmptyInviteInviteParentSubtitle;

  /// No description provided for @homeEmptyInviteShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get homeEmptyInviteShareButton;

  /// No description provided for @homeEmptyRemindersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reminders'**
  String get homeEmptyRemindersSectionTitle;

  /// No description provided for @homeEmptyRemindersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get homeEmptyRemindersEmptyTitle;

  /// No description provided for @homeEmptyRemindersEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first reminder to keep the family on track.'**
  String get homeEmptyRemindersEmptyDescription;

  /// No description provided for @homeEmptyRemindersCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Reminder'**
  String get homeEmptyRemindersCreateButton;

  /// No description provided for @peopleViewTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get peopleViewTryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @peopleViewCreateFamily.
  ///
  /// In en, this message translates to:
  /// **'Create Family'**
  String get peopleViewCreateFamily;

  /// No description provided for @peopleViewFamilyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter family name'**
  String get peopleViewFamilyNameHint;

  /// No description provided for @peopleEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No family members yet'**
  String get peopleEmptyTitle;

  /// No description provided for @peopleEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first family member to get started.'**
  String get peopleEmptyDescription;

  /// No description provided for @peopleLoadedTheCircle.
  ///
  /// In en, this message translates to:
  /// **'The Circle'**
  String get peopleLoadedTheCircle;

  /// No description provided for @peopleLoadedMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members · {family}'**
  String peopleLoadedMembersCount(int count, Object family);

  /// No description provided for @peopleLoadedInviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get peopleLoadedInviteCodeCopied;

  /// No description provided for @peopleLoadedInviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get peopleLoadedInviteLinkCopied;

  /// No description provided for @peopleLoadedInviteCodeRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Invite code refreshed'**
  String get peopleLoadedInviteCodeRefreshed;

  /// No description provided for @peopleLoadedPendingInviteSent.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get peopleLoadedPendingInviteSent;

  /// No description provided for @peopleLoadedInvitationSentAgain.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent again'**
  String get peopleLoadedInvitationSentAgain;

  /// No description provided for @peopleLoadedMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get peopleLoadedMembersTitle;

  /// No description provided for @peopleLoadedAddMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get peopleLoadedAddMemberButton;

  /// No description provided for @peopleLoadedNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get peopleLoadedNotificationMessage;

  /// No description provided for @peopleLoadedProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile selected'**
  String get peopleLoadedProfileMessage;

  /// No description provided for @peopleLoadedAddMemberSelected.
  ///
  /// In en, this message translates to:
  /// **'Add member selected'**
  String get peopleLoadedAddMemberSelected;

  /// No description provided for @peopleLoadedMemberSelected.
  ///
  /// In en, this message translates to:
  /// **'{name} selected'**
  String peopleLoadedMemberSelected(String name);

  /// No description provided for @peopleLoadedAddFamilyMemberSelected.
  ///
  /// In en, this message translates to:
  /// **'Add family member selected'**
  String get peopleLoadedAddFamilyMemberSelected;

  /// No description provided for @peopleLoadedRolePermissionsSelected.
  ///
  /// In en, this message translates to:
  /// **'Role permissions selected'**
  String get peopleLoadedRolePermissionsSelected;

  /// No description provided for @peopleWidgetsFamilyHeaderNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get peopleWidgetsFamilyHeaderNotificationsTooltip;

  /// No description provided for @peopleWidgetsFamilyHeaderProfileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get peopleWidgetsFamilyHeaderProfileSemantics;

  /// No description provided for @peopleWidgetsFamilyMemberRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get peopleWidgetsFamilyMemberRoleAdmin;

  /// No description provided for @peopleWidgetsFamilyMemberRoleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get peopleWidgetsFamilyMemberRoleParent;

  /// No description provided for @peopleWidgetsFamilyMemberRoleChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get peopleWidgetsFamilyMemberRoleChild;

  /// No description provided for @peopleWidgetsFamilyMemberRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get peopleWidgetsFamilyMemberRoleMember;

  /// No description provided for @peopleWidgetsAddFamilyMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get peopleWidgetsAddFamilyMemberTitle;

  /// No description provided for @peopleWidgetsAddFamilyMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite via code or email'**
  String get peopleWidgetsAddFamilyMemberSubtitle;

  /// No description provided for @peopleWidgetsInviteCodeCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Invite Code'**
  String get peopleWidgetsInviteCodeCardLabel;

  /// No description provided for @peopleWidgetsInviteCodeCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get peopleWidgetsInviteCodeCopyTooltip;

  /// No description provided for @peopleWidgetsInviteCodeShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get peopleWidgetsInviteCodeShareButton;

  /// No description provided for @peopleWidgetsInviteCodeRefreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh Code'**
  String get peopleWidgetsInviteCodeRefreshButton;

  /// No description provided for @peopleWidgetsInviteCodeExpiresPrefix.
  ///
  /// In en, this message translates to:
  /// **'Code expires in '**
  String get peopleWidgetsInviteCodeExpiresPrefix;

  /// No description provided for @peopleWidgetsInviteCodeExpiresDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String peopleWidgetsInviteCodeExpiresDays(int count);

  /// No description provided for @peopleWidgetsInviteCodeExpiresSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Share with trusted family\nmembers only'**
  String get peopleWidgetsInviteCodeExpiresSuffix;

  /// No description provided for @peopleWidgetsPendingInviteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'1 Pending Invite'**
  String get peopleWidgetsPendingInviteCardTitle;

  /// No description provided for @peopleWidgetsPendingInviteResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get peopleWidgetsPendingInviteResendButton;

  /// No description provided for @peopleWidgetsRolePermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Role Permissions'**
  String get peopleWidgetsRolePermissionsTitle;

  /// No description provided for @peopleWidgetsRolePermissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Admins can manage all members. Parents can add tasks. Children have view-only access.'**
  String get peopleWidgetsRolePermissionsDescription;

  /// No description provided for @peopleWidgetsRolePermissionsLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more →'**
  String get peopleWidgetsRolePermissionsLearnMore;

  /// No description provided for @accountHeaderCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get accountHeaderCurrentPlan;

  /// No description provided for @accountHeaderPlanName.
  ///
  /// In en, this message translates to:
  /// **'Family Pro'**
  String get accountHeaderPlanName;

  /// No description provided for @accountHeaderPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Up to 8 members · Unlimited reminders'**
  String get accountHeaderPlanDescription;

  /// No description provided for @accountHeaderStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountHeaderStatusActive;

  /// No description provided for @accountSettingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSettingsAccountSection;

  /// No description provided for @accountSettingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get accountSettingsEditProfile;

  /// No description provided for @accountSettingsEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, photo, contact info'**
  String get accountSettingsEditProfileSubtitle;

  /// No description provided for @accountSettingsPasswordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password & Security'**
  String get accountSettingsPasswordSecurity;

  /// No description provided for @accountSettingsPasswordSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change password, 2FA'**
  String get accountSettingsPasswordSecuritySubtitle;

  /// No description provided for @accountSettingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get accountSettingsNotifications;

  /// No description provided for @accountSettingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push, email preferences'**
  String get accountSettingsNotificationsSubtitle;

  /// No description provided for @accountSettingsFamilySection.
  ///
  /// In en, this message translates to:
  /// **'FAMILY'**
  String get accountSettingsFamilySection;

  /// No description provided for @accountSettingsFamilySettings.
  ///
  /// In en, this message translates to:
  /// **'Family Settings'**
  String get accountSettingsFamilySettings;

  /// No description provided for @accountSettingsFamilySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Family name, preferences'**
  String get accountSettingsFamilySettingsSubtitle;

  /// No description provided for @accountSettingsRolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get accountSettingsRolesPermissions;

  /// No description provided for @accountSettingsRolesPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage admin access'**
  String get accountSettingsRolesPermissionsSubtitle;

  /// No description provided for @accountSettingsInviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get accountSettingsInviteMembers;

  /// No description provided for @accountSettingsInviteMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share invite code'**
  String get accountSettingsInviteMembersSubtitle;

  /// No description provided for @accountSettingsSupportSection.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get accountSettingsSupportSection;

  /// No description provided for @accountSettingsHelpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get accountSettingsHelpFaq;

  /// No description provided for @accountSettingsHelpFaqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get answers, contact support'**
  String get accountSettingsHelpFaqSubtitle;

  /// No description provided for @accountSettingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get accountSettingsPrivacyPolicy;

  /// No description provided for @accountSettingsPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get accountSettingsPrivacyPolicySubtitle;

  /// No description provided for @accountSettingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get accountSettingsSignOut;

  /// No description provided for @accountSettingsSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of this device'**
  String get accountSettingsSignOutSubtitle;

  /// No description provided for @remindersHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersHeaderTitle;

  /// No description provided for @remindersHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled yet'**
  String get remindersHeaderSubtitle;

  /// No description provided for @remindersHeaderAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get remindersHeaderAll;

  /// No description provided for @remindersHeaderChores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get remindersHeaderChores;

  /// No description provided for @remindersHeaderAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get remindersHeaderAppointments;

  /// No description provided for @remindersHeaderBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get remindersHeaderBirthdays;

  /// No description provided for @remindersErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get remindersErrorTitle;

  /// No description provided for @remindersErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Could not load reminders'**
  String get remindersErrorDescription;

  /// No description provided for @remindersErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get remindersErrorRetry;

  /// No description provided for @remindersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get remindersEmptyTitle;

  /// No description provided for @remindersEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep your family on track — create your first reminder for chores, appointments or birthdays.'**
  String get remindersEmptyDescription;

  /// No description provided for @remindersEmptyCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create First Reminder'**
  String get remindersEmptyCreateButton;

  /// No description provided for @remindersEmptySuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'What can you track ?'**
  String get remindersEmptySuggestionsTitle;

  /// No description provided for @remindersSuggestionsChoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get remindersSuggestionsChoresTitle;

  /// No description provided for @remindersSuggestionsChoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign recurring tasks to family members'**
  String get remindersSuggestionsChoresSubtitle;

  /// No description provided for @remindersSuggestionsAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get remindersSuggestionsAppointmentsTitle;

  /// No description provided for @remindersSuggestionsAppointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor, school events and one-off plans'**
  String get remindersSuggestionsAppointmentsSubtitle;

  /// No description provided for @remindersSuggestionsBirthdaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get remindersSuggestionsBirthdaysTitle;

  /// No description provided for @remindersSuggestionsBirthdaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a special day for your family'**
  String get remindersSuggestionsBirthdaysSubtitle;

  /// No description provided for @remindersSuggestionsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get remindersSuggestionsAddButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
