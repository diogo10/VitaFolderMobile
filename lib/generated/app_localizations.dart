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
  /// **'HouseMira'**
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

  /// No description provided for @onboardingNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get onboardingNextStep;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your Family,\nIn One Place'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Bring everyone together in a private, secure circle. Stay connected with real-time status and instant updates.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Smart Family\nReminders'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Set tasks and appointments for anyone. Get notified together and never miss a family milestone.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Secure & Private\nBy Design'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Only your family circle can see your data. Manage admin roles and keep your home safe and organized.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingAtHome.
  ///
  /// In en, this message translates to:
  /// **'At Home'**
  String get onboardingAtHome;

  /// No description provided for @onboardingAtWork.
  ///
  /// In en, this message translates to:
  /// **'At Work'**
  String get onboardingAtWork;

  /// No description provided for @onboardingEndToEndEncryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption'**
  String get onboardingEndToEndEncryption;

  /// No description provided for @onboardingReminderMedicineTitle.
  ///
  /// In en, this message translates to:
  /// **'Lily\'s Medicine'**
  String get onboardingReminderMedicineTitle;

  /// No description provided for @onboardingReminderMedicineTime.
  ///
  /// In en, this message translates to:
  /// **'Today · 8:30 AM'**
  String get onboardingReminderMedicineTime;

  /// No description provided for @onboardingReminderGroceryTitle.
  ///
  /// In en, this message translates to:
  /// **'Grocery Run'**
  String get onboardingReminderGroceryTitle;

  /// No description provided for @onboardingReminderGroceryTime.
  ///
  /// In en, this message translates to:
  /// **'Today · 5:00 PM'**
  String get onboardingReminderGroceryTime;

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

  /// No description provided for @homeEmptyInviteShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join my family circle on HouseMira.'**
  String get homeEmptyInviteShareMessage;

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

  /// No description provided for @homeSuccessGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get homeSuccessGreetingMorning;

  /// No description provided for @homeSuccessGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get homeSuccessGreetingAfternoon;

  /// No description provided for @homeSuccessGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get homeSuccessGreetingEvening;

  /// No description provided for @homeSuccessActiveMembers.
  ///
  /// In en, this message translates to:
  /// **'{members} members active today · {pending} reminders pending'**
  String homeSuccessActiveMembers(int members, int pending);

  /// No description provided for @homeSuccessAddTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get homeSuccessAddTaskTitle;

  /// No description provided for @homeSuccessAddTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quickly schedule a task or event'**
  String get homeSuccessAddTaskSubtitle;

  /// No description provided for @homeSuccessAddTaskButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeSuccessAddTaskButton;

  /// No description provided for @homeSuccessManageActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Activity'**
  String get homeSuccessManageActivityTitle;

  /// No description provided for @homeSuccessManageActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review everything scheduled'**
  String get homeSuccessManageActivitySubtitle;

  /// No description provided for @homeSuccessManageActivityButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeSuccessManageActivityButton;

  /// No description provided for @homeSuccessRemindersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get homeSuccessRemindersAdd;

  /// No description provided for @homeSuccessRemindersToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeSuccessRemindersToday;

  /// No description provided for @homeSuccessRemindersTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeSuccessRemindersTomorrow;

  /// No description provided for @homeSuccessRemindersNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get homeSuccessRemindersNoDate;

  /// No description provided for @homeSuccessCircleManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get homeSuccessCircleManage;

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
  /// **'Share with trusted family members only'**
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
  /// **'Roles'**
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

  /// No description provided for @accountSettingsInviteMembersSubtitleWithCode.
  ///
  /// In en, this message translates to:
  /// **'{familyCode} - {subtitle}'**
  String accountSettingsInviteMembersSubtitleWithCode(
    String familyCode,
    String subtitle,
  );

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

  /// No description provided for @accountSettingsDangerSection.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get accountSettingsDangerSection;

  /// No description provided for @accountSettingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountSettingsDeleteAccount;

  /// No description provided for @accountSettingsDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get accountSettingsDeleteAccountSubtitle;

  /// No description provided for @accountDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountDeleteDialogTitle;

  /// No description provided for @accountDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Your profile, family memberships and login will be permanently removed. Your family\'s shared data stays with the other members.'**
  String get accountDeleteDialogMessage;

  /// No description provided for @accountDeleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountDeleteDialogConfirm;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeletedSuccess;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not delete your account. Please try again.'**
  String get accountDeleteFailed;

  /// No description provided for @accountDeleteSoleOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the last owner of your family circle. Transfer ownership or delete the circle in Family Settings first.'**
  String get accountDeleteSoleOwner;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationSettingsSection;

  /// No description provided for @notificationSettingsEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationSettingsEnableNotifications;

  /// No description provided for @notificationSettingsEnableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified about reminders and family updates'**
  String get notificationSettingsEnableNotificationsSubtitle;

  /// No description provided for @notificationSettingsEmailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Email updates'**
  String get notificationSettingsEmailUpdates;

  /// No description provided for @notificationSettingsEmailUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive a summary by email'**
  String get notificationSettingsEmailUpdatesSubtitle;

  /// No description provided for @notificationSettingsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications permission was denied. You can enable it in system settings.'**
  String get notificationSettingsPermissionDenied;

  /// No description provided for @notificationSettingsPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications permission is permanently denied. Please enable it in system settings.'**
  String get notificationSettingsPermissionPermanentlyDenied;

  /// No description provided for @notificationSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading your settings.'**
  String get notificationSettingsError;

  /// No description provided for @manageProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get manageProfileTitle;

  /// No description provided for @manageProfileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get manageProfileNameLabel;

  /// No description provided for @manageProfileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get manageProfileSaveButton;

  /// No description provided for @manageProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get manageProfileNameRequired;

  /// No description provided for @manageProfileSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get manageProfileSuccessMessage;

  /// No description provided for @accountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out.'**
  String get accountSignedOut;

  /// No description provided for @accountLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get accountLoginFailed;

  /// No description provided for @accountPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a link to your email to reset your password.'**
  String get accountPasswordResetSent;

  /// No description provided for @accountPasswordResetEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get accountPasswordResetEnterEmail;

  /// No description provided for @accountPasswordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not send the reset link. Please try again.'**
  String get accountPasswordResetFailed;

  /// No description provided for @accountNoAccountContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get accountNoAccountContinueGoogle;

  /// No description provided for @accountNoAccountContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get accountNoAccountContinueApple;

  /// No description provided for @accountNoAccountOrEmail.
  ///
  /// In en, this message translates to:
  /// **'or sign in with email'**
  String get accountNoAccountOrEmail;

  /// No description provided for @accountNoAccountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get accountNoAccountEmailLabel;

  /// No description provided for @accountNoAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountNoAccountPasswordLabel;

  /// No description provided for @accountNoAccountForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get accountNoAccountForgotPassword;

  /// No description provided for @accountNoAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get accountNoAccountSignIn;

  /// No description provided for @accountNoAccountNewToApp.
  ///
  /// In en, this message translates to:
  /// **'New to FamilyAdmin?'**
  String get accountNoAccountNewToApp;

  /// No description provided for @accountNoAccountCreateFreeAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get accountNoAccountCreateFreeAccount;

  /// No description provided for @accountNoAccountSecurePrivate.
  ///
  /// In en, this message translates to:
  /// **'Secure & private'**
  String get accountNoAccountSecurePrivate;

  /// No description provided for @accountNoAccountFreeToStart.
  ///
  /// In en, this message translates to:
  /// **'Free to start'**
  String get accountNoAccountFreeToStart;

  /// No description provided for @accountNoAccountFamilyPlan.
  ///
  /// In en, this message translates to:
  /// **'Family plan'**
  String get accountNoAccountFamilyPlan;

  /// No description provided for @appBrandName.
  ///
  /// In en, this message translates to:
  /// **'HouseMira'**
  String get appBrandName;

  /// No description provided for @accountNoAccountTitleTop.
  ///
  /// In en, this message translates to:
  /// **'Your family,'**
  String get accountNoAccountTitleTop;

  /// No description provided for @accountNoAccountTitleBottom.
  ///
  /// In en, this message translates to:
  /// **'organised together'**
  String get accountNoAccountTitleBottom;

  /// No description provided for @accountNoAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your circle, set reminders and collaborate as a family — all in one place.'**
  String get accountNoAccountSubtitle;

  /// No description provided for @accountNoAccountChipChores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get accountNoAccountChipChores;

  /// No description provided for @accountNoAccountChipAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get accountNoAccountChipAppointments;

  /// No description provided for @accountNoAccountChipFamilyCircle.
  ///
  /// In en, this message translates to:
  /// **'Family Circle'**
  String get accountNoAccountChipFamilyCircle;

  /// No description provided for @accountNoAccountEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get accountNoAccountEmailPlaceholder;

  /// No description provided for @accountNoAccountPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get accountNoAccountPasswordPlaceholder;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpTitle;

  /// No description provided for @signUpTitleTop.
  ///
  /// In en, this message translates to:
  /// **'Join the circle,'**
  String get signUpTitleTop;

  /// No description provided for @signUpTitleBottom.
  ///
  /// In en, this message translates to:
  /// **'start organizing.'**
  String get signUpTitleBottom;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account and invite your family members to start collaborating today.'**
  String get signUpSubtitle;

  /// No description provided for @signUpContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpContinueGoogle;

  /// No description provided for @signUpOrEmail.
  ///
  /// In en, this message translates to:
  /// **'or email'**
  String get signUpOrEmail;

  /// No description provided for @signUpNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signUpNameLabel;

  /// No description provided for @signUpNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get signUpNamePlaceholder;

  /// No description provided for @signUpEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get signUpEmailLabel;

  /// No description provided for @signUpEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get signUpEmailPlaceholder;

  /// No description provided for @signUpPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signUpPasswordLabel;

  /// No description provided for @signUpPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get signUpPasswordPlaceholder;

  /// No description provided for @signUpPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters long with a mix of letters and numbers.'**
  String get signUpPasswordHint;

  /// No description provided for @signUpCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpCreateAccount;

  /// No description provided for @signUpAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signUpAlreadyHaveAccount;

  /// No description provided for @signUpSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signUpSignInLink;

  /// No description provided for @signUpAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'By creating an account, you agree to our '**
  String get signUpAgreePrefix;

  /// No description provided for @signUpTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get signUpTermsOfService;

  /// No description provided for @signUpAgreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signUpAgreeAnd;

  /// No description provided for @signUpPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get signUpPrivacyPolicy;

  /// No description provided for @signUpAgreeSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get signUpAgreeSuffix;

  /// No description provided for @signUpSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Thanks, You have finished the the registration.'**
  String get signUpSuccessMessage;

  /// No description provided for @signUpNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get signUpNameRequired;

  /// No description provided for @signUpEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email'**
  String get signUpEmailRequired;

  /// No description provided for @signUpEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get signUpEmailInvalid;

  /// No description provided for @signUpPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get signUpPasswordRequired;

  /// No description provided for @signUpPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get signUpPasswordTooShort;

  /// No description provided for @signUpUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get signUpUnexpectedError;

  /// No description provided for @peopleInvalidFamilyCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid family code. Please try again.'**
  String get peopleInvalidFamilyCode;

  /// No description provided for @invitePeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite People'**
  String get invitePeopleTitle;

  /// No description provided for @invitePeopleHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Grow your circle'**
  String get invitePeopleHeroTitle;

  /// No description provided for @invitePeopleHeroDescriptionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Enter your family member\'s email address below to send them an invitation to join '**
  String get invitePeopleHeroDescriptionPrefix;

  /// No description provided for @invitePeopleHeroDescriptionGeneric.
  ///
  /// In en, this message translates to:
  /// **'Enter your family member\'s email address below to send them an invitation to join your family.'**
  String get invitePeopleHeroDescriptionGeneric;

  /// No description provided for @invitePeopleEmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get invitePeopleEmailAddressLabel;

  /// No description provided for @invitePeopleEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'family@example.com'**
  String get invitePeopleEmailPlaceholder;

  /// No description provided for @invitePeopleSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent!'**
  String get invitePeopleSent;

  /// No description provided for @invitePeopleSend.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get invitePeopleSend;

  /// No description provided for @invitePeopleEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get invitePeopleEmailLabel;

  /// No description provided for @invitePeopleRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get invitePeopleRelationshipLabel;

  /// No description provided for @invitePeopleRelationshipSelf.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get invitePeopleRelationshipSelf;

  /// No description provided for @invitePeopleRelationshipSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get invitePeopleRelationshipSpouse;

  /// No description provided for @invitePeopleRelationshipChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get invitePeopleRelationshipChild;

  /// No description provided for @invitePeopleRelationshipParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get invitePeopleRelationshipParent;

  /// No description provided for @invitePeopleRelationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get invitePeopleRelationshipOther;

  /// No description provided for @invitePeopleError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invite email.'**
  String get invitePeopleError;

  /// No description provided for @invitePeopleEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'You have been invited as a {relationship} for HouseMira'**
  String invitePeopleEmailSubject(String relationship);

  /// No description provided for @peopleEmptyCreateFamily.
  ///
  /// In en, this message translates to:
  /// **'+ Create Family'**
  String get peopleEmptyCreateFamily;

  /// No description provided for @peopleEmptyEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Invite Code'**
  String get peopleEmptyEnterCode;

  /// No description provided for @peopleEmptyJoinFamily.
  ///
  /// In en, this message translates to:
  /// **'Join Family'**
  String get peopleEmptyJoinFamily;

  /// No description provided for @peopleEmptyAskAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ask your family admin for the invite code'**
  String get peopleEmptyAskAdmin;

  /// No description provided for @peopleEmptyEmailInvite.
  ///
  /// In en, this message translates to:
  /// **'Email Invite'**
  String get peopleEmptyEmailInvite;

  /// No description provided for @peopleEmptyEmailInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email for an invitation link'**
  String get peopleEmptyEmailInviteSubtitle;

  /// No description provided for @peopleEmptyPrivateSecure.
  ///
  /// In en, this message translates to:
  /// **'Private & Secure'**
  String get peopleEmptyPrivateSecure;

  /// No description provided for @peopleEmptyPrivateSecureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only people with the code or a direct invite can join.'**
  String get peopleEmptyPrivateSecureSubtitle;

  /// No description provided for @remindersHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersHeaderTitle;

  /// No description provided for @remindersHeaderAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get remindersHeaderAll;

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

  /// No description provided for @createReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get createReminderTitle;

  /// No description provided for @createReminderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get createReminderTitleLabel;

  /// No description provided for @createReminderTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get createReminderTitleRequired;

  /// No description provided for @createReminderBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get createReminderBodyLabel;

  /// No description provided for @createReminderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get createReminderTypeLabel;

  /// No description provided for @createReminderDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get createReminderDueDateLabel;

  /// No description provided for @createReminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get createReminderTimeLabel;

  /// No description provided for @createReminderRepeatRuleLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get createReminderRepeatRuleLabel;

  /// No description provided for @createReminderRepeatNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get createReminderRepeatNever;

  /// No description provided for @createReminderRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get createReminderRepeatDaily;

  /// No description provided for @createReminderRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get createReminderRepeatWeekly;

  /// No description provided for @createReminderRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get createReminderRepeatMonthly;

  /// No description provided for @createReminderNotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get createReminderNotifyTitle;

  /// No description provided for @createReminderNotifyToggle.
  ///
  /// In en, this message translates to:
  /// **'Notify me on this device'**
  String get createReminderNotifyToggle;

  /// No description provided for @createReminderNotifyNoDateHint.
  ///
  /// In en, this message translates to:
  /// **'Set a date to enable notifications'**
  String get createReminderNotifyNoDateHint;

  /// No description provided for @createReminderNotifyAtTime.
  ///
  /// In en, this message translates to:
  /// **'At time'**
  String get createReminderNotifyAtTime;

  /// No description provided for @createReminderNotify15Min.
  ///
  /// In en, this message translates to:
  /// **'15 min before'**
  String get createReminderNotify15Min;

  /// No description provided for @createReminderNotify1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get createReminderNotify1Hour;

  /// No description provided for @createReminderNotify1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get createReminderNotify1Day;

  /// No description provided for @createReminderNotifyDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Enable them to receive reminders.'**
  String get createReminderNotifyDisabledMessage;

  /// No description provided for @createReminderNotifySavedWithoutPermission.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved, but notifications are disabled.'**
  String get createReminderNotifySavedWithoutPermission;

  /// No description provided for @createReminderNotifyUpdatedWithoutPermission.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated, but notifications are disabled.'**
  String get createReminderNotifyUpdatedWithoutPermission;

  /// No description provided for @createReminderNotifyOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get createReminderNotifyOpenSettings;

  /// No description provided for @createReminderNotifyExactAlarmMessage.
  ///
  /// In en, this message translates to:
  /// **'For on-time alerts, allow exact alarms in Settings.'**
  String get createReminderNotifyExactAlarmMessage;

  /// No description provided for @createReminderSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Create Reminder'**
  String get createReminderSaveButton;

  /// No description provided for @createReminderSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder created successfully'**
  String get createReminderSuccessMessage;

  /// No description provided for @createReminderUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated successfully'**
  String get createReminderUpdatedMessage;

  /// No description provided for @createReminderTypeRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renewal'**
  String get createReminderTypeRenewal;

  /// No description provided for @createReminderTypeAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get createReminderTypeAppointment;

  /// No description provided for @createReminderTypeVaccine.
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get createReminderTypeVaccine;

  /// No description provided for @createReminderTypeReimbursement.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement'**
  String get createReminderTypeReimbursement;

  /// No description provided for @createReminderTypeBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get createReminderTypeBirthday;

  /// No description provided for @createReminderTypeChores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get createReminderTypeChores;

  /// No description provided for @createReminderTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get createReminderTypeCustom;

  /// No description provided for @reminderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reminderStatusPending;

  /// No description provided for @reminderStatusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get reminderStatusSent;

  /// No description provided for @reminderStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderStatusDone;

  /// No description provided for @reminderStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get reminderStatusDismissed;

  /// No description provided for @reminderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reminderStatusCancelled;

  /// No description provided for @remindersLoadedSectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get remindersLoadedSectionToday;

  /// No description provided for @remindersLoadedSectionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get remindersLoadedSectionTomorrow;

  /// No description provided for @remindersLoadedSectionNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get remindersLoadedSectionNoDate;

  /// No description provided for @remindersLoadedSectionAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get remindersLoadedSectionAllDay;

  /// No description provided for @reminderDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get reminderDeleteDialogTitle;

  /// No description provided for @reminderDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{title}\"?'**
  String reminderDeleteDialogMessage(String title);

  /// No description provided for @reminderDeleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get reminderDeleteDialogConfirm;

  /// No description provided for @remindersCalendarViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View as calendar'**
  String get remindersCalendarViewCalendar;

  /// No description provided for @remindersCalendarViewList.
  ///
  /// In en, this message translates to:
  /// **'View as list'**
  String get remindersCalendarViewList;

  /// No description provided for @remindersCalendarEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No reminders for this day'**
  String get remindersCalendarEmptyDay;

  /// No description provided for @createReminderTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get createReminderTitleEdit;

  /// No description provided for @createReminderSaveButtonEdit.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get createReminderSaveButtonEdit;

  /// No description provided for @remindersFilterChores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get remindersFilterChores;

  /// No description provided for @remindersFilterAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get remindersFilterAppointments;

  /// No description provided for @remindersFilterBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get remindersFilterBirthdays;

  /// No description provided for @remindersFilterRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renewal'**
  String get remindersFilterRenewal;

  /// No description provided for @remindersFilterVaccine.
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get remindersFilterVaccine;

  /// No description provided for @remindersFilterReimbursement.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement'**
  String get remindersFilterReimbursement;

  /// No description provided for @remindersFilterCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get remindersFilterCustom;

  /// No description provided for @remindersFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Reminders'**
  String get remindersFilterTitle;

  /// No description provided for @remindersFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get remindersFilterApply;

  /// No description provided for @needToBeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You need to be logged in to perform this action'**
  String get needToBeLoggedIn;

  /// No description provided for @familySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Settings'**
  String get familySettingsTitle;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get familyNameLabel;

  /// No description provided for @familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter family name'**
  String get familyNameHint;

  /// No description provided for @manageMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Members'**
  String get manageMembersTitle;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Total'**
  String memberCount(int count);

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @roleChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get roleChild;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @youBadge.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get youBadge;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from {familyName}?'**
  String removeMemberConfirm(String name, String familyName);

  /// No description provided for @dangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZoneTitle;

  /// No description provided for @deleteFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Family Circle'**
  String get deleteFamilyTitle;

  /// No description provided for @deleteFamilyDescription.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All data, tasks, and members will be permanently removed.'**
  String get deleteFamilyDescription;

  /// No description provided for @deleteFamilyButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Circle'**
  String get deleteFamilyButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @savedButton.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedButton;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Family settings saved successfully'**
  String get saveSuccess;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Family circle deleted'**
  String get deleteSuccess;

  /// No description provided for @onlyAdminCanAccess.
  ///
  /// In en, this message translates to:
  /// **'Only family admins can access family settings.'**
  String get onlyAdminCanAccess;

  /// No description provided for @createReminderTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekly Grocery Run'**
  String get createReminderTitleHint;

  /// No description provided for @createReminderBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Add some notes about this reminder...'**
  String get createReminderBodyHint;

  /// No description provided for @createReminderOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get createReminderOptional;

  /// No description provided for @remindersAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up 🎉'**
  String get remindersAllCaughtUp;

  /// No description provided for @peopleWidgetsPendingInviteSent.
  ///
  /// In en, this message translates to:
  /// **'{email} · sent {sentAt}'**
  String peopleWidgetsPendingInviteSent(String email, String sentAt);

  /// No description provided for @createReminderErrorNoFamily.
  ///
  /// In en, this message translates to:
  /// **'No family found'**
  String get createReminderErrorNoFamily;

  /// No description provided for @createReminderErrorAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get createReminderErrorAuthRequired;

  /// No description provided for @familySettingsErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Family not found'**
  String get familySettingsErrorNotFound;
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
