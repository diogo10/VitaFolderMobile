// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VitaFolder';

  @override
  String get navHome => 'Home';

  @override
  String get navPeople => 'People';

  @override
  String get navReminders => 'Reminders';

  @override
  String get navAccount => 'Account';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get homeError => 'Something went wrong.';

  @override
  String get homeToday => 'Today';

  @override
  String get homeTasks => 'Tasks';

  @override
  String get homeCompleted => 'Completed';

  @override
  String get homePending => 'Pending';

  @override
  String get homeEmptyHeaderTitle => 'Welcome to FamilyAdmin';

  @override
  String get homeEmptyHeaderSubtitle => 'Let\'s get started';

  @override
  String get homeEmptyHeaderDescription =>
      'Your family hub is ready. Set it up in a few easy steps.';

  @override
  String get homeEmptyAddPeopleTitle => 'Add people to your Circle';

  @override
  String get homeEmptyAddPeopleSubtitle =>
      'Invite parents, kids or caregivers to your family.';

  @override
  String get homeEmptyAddPeopleButton => 'Add';

  @override
  String get homeEmptyReminderTitle => 'Set up a Reminder';

  @override
  String get homeEmptyReminderSubtitle =>
      'Schedule tasks, events and never miss a thing.';

  @override
  String get homeEmptyReminderButton => 'Set up';

  @override
  String get homeEmptyAccountTitle => 'Complete your Account';

  @override
  String get homeEmptyAccountSubtitle =>
      'Add your name, photo and contact details.';

  @override
  String get homeEmptyAccountButton => 'Go';

  @override
  String get homeEmptyFooterCircleTitle => 'The Circle';

  @override
  String get homeEmptyFooterAddPeopleLink => 'Add people';

  @override
  String get homeEmptyFooterNoMembersTitle => 'No members yet';

  @override
  String get homeEmptyFooterNoMembersDescription =>
      'Add family members to start collaborating and tracking together.';

  @override
  String get homeEmptyFooterAddMemberButton => 'Add Member';

  @override
  String get homeEmptyInviteInviteParentTitle => 'Invite a Parent';

  @override
  String get homeEmptyInviteInviteParentSubtitle =>
      'Collaborate in your family hub';

  @override
  String get homeEmptyInviteShareButton => 'Share';

  @override
  String get homeEmptyRemindersSectionTitle => 'Upcoming Reminders';

  @override
  String get homeEmptyRemindersEmptyTitle => 'No reminders yet';

  @override
  String get homeEmptyRemindersEmptyDescription =>
      'Create your first reminder to keep the family on track.';

  @override
  String get homeEmptyRemindersCreateButton => 'Create Reminder';

  @override
  String get peopleViewTryAgain => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get peopleViewCreateFamily => 'Create Family';

  @override
  String get peopleViewFamilyNameHint => 'Enter family name';

  @override
  String get peopleEmptyTitle => 'No family members yet';

  @override
  String get peopleEmptyDescription =>
      'Add your first family member to get started.';

  @override
  String get peopleLoadedTheCircle => 'The Circle';

  @override
  String peopleLoadedMembersCount(int count, Object family) {
    return '$count members · $family';
  }

  @override
  String get peopleLoadedInviteCodeCopied => 'Invite code copied';

  @override
  String get peopleLoadedInviteLinkCopied => 'Invite link copied';

  @override
  String get peopleLoadedInviteCodeRefreshed => 'Invite code refreshed';

  @override
  String get peopleLoadedPendingInviteSent => '2 days ago';

  @override
  String get peopleLoadedInvitationSentAgain => 'Invitation sent again';

  @override
  String get peopleLoadedMembersTitle => 'Members';

  @override
  String get peopleLoadedAddMemberButton => 'Add Member';

  @override
  String get peopleLoadedNotificationMessage => 'No new notifications';

  @override
  String get peopleLoadedProfileMessage => 'Profile selected';

  @override
  String get peopleLoadedAddMemberSelected => 'Add member selected';

  @override
  String peopleLoadedMemberSelected(String name) {
    return '$name selected';
  }

  @override
  String get peopleLoadedAddFamilyMemberSelected =>
      'Add family member selected';

  @override
  String get peopleLoadedRolePermissionsSelected => 'Role permissions selected';

  @override
  String get peopleWidgetsFamilyHeaderNotificationsTooltip => 'Notifications';

  @override
  String get peopleWidgetsFamilyHeaderProfileSemantics => 'Open profile';

  @override
  String get peopleWidgetsFamilyMemberRoleAdmin => 'Admin';

  @override
  String get peopleWidgetsFamilyMemberRoleParent => 'Parent';

  @override
  String get peopleWidgetsFamilyMemberRoleChild => 'Child';

  @override
  String get peopleWidgetsFamilyMemberRoleMember => 'Member';

  @override
  String get peopleWidgetsAddFamilyMemberTitle => 'Add Family Member';

  @override
  String get peopleWidgetsAddFamilyMemberSubtitle => 'Invite via code or email';

  @override
  String get peopleWidgetsInviteCodeCardLabel => 'Family Invite Code';

  @override
  String get peopleWidgetsInviteCodeCopyTooltip => 'Copy invite code';

  @override
  String get peopleWidgetsInviteCodeShareButton => 'Share Link';

  @override
  String get peopleWidgetsInviteCodeRefreshButton => 'Refresh Code';

  @override
  String get peopleWidgetsInviteCodeExpiresPrefix => 'Code expires in ';

  @override
  String peopleWidgetsInviteCodeExpiresDays(int count) {
    return '$count days';
  }

  @override
  String get peopleWidgetsInviteCodeExpiresSuffix =>
      'Share with trusted family members only';

  @override
  String get peopleWidgetsPendingInviteCardTitle => '1 Pending Invite';

  @override
  String get peopleWidgetsPendingInviteResendButton => 'Resend';

  @override
  String get peopleWidgetsRolePermissionsTitle => 'Roles';

  @override
  String get peopleWidgetsRolePermissionsDescription =>
      'Admins can manage all members. Parents can add tasks. Children have view-only access.';

  @override
  String get peopleWidgetsRolePermissionsLearnMore => 'Learn more →';

  @override
  String get accountHeaderCurrentPlan => 'Current Plan';

  @override
  String get accountHeaderPlanName => 'Family Pro';

  @override
  String get accountHeaderPlanDescription =>
      'Up to 8 members · Unlimited reminders';

  @override
  String get accountHeaderStatusActive => 'Active';

  @override
  String get accountSettingsAccountSection => 'ACCOUNT';

  @override
  String get accountSettingsEditProfile => 'Edit Profile';

  @override
  String get accountSettingsEditProfileSubtitle => 'Name, photo, contact info';

  @override
  String get accountSettingsPasswordSecurity => 'Password & Security';

  @override
  String get accountSettingsPasswordSecuritySubtitle => 'Change password, 2FA';

  @override
  String get accountSettingsNotifications => 'Notifications';

  @override
  String get accountSettingsNotificationsSubtitle => 'Push, email preferences';

  @override
  String get accountSettingsFamilySection => 'FAMILY';

  @override
  String get accountSettingsFamilySettings => 'Family Settings';

  @override
  String get accountSettingsFamilySettingsSubtitle =>
      'Family name, preferences';

  @override
  String get accountSettingsRolesPermissions => 'Roles & Permissions';

  @override
  String get accountSettingsRolesPermissionsSubtitle => 'Manage admin access';

  @override
  String get accountSettingsInviteMembers => 'Invite Members';

  @override
  String get accountSettingsInviteMembersSubtitle => 'Share invite code';

  @override
  String get accountSettingsSupportSection => 'SUPPORT';

  @override
  String get accountSettingsHelpFaq => 'Help & FAQ';

  @override
  String get accountSettingsHelpFaqSubtitle => 'Get answers, contact support';

  @override
  String get accountSettingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get accountSettingsPrivacyPolicySubtitle => 'How we handle your data';

  @override
  String get accountSettingsSignOut => 'Sign Out';

  @override
  String get accountSettingsSignOutSubtitle => 'Log out of this device';

  @override
  String get manageProfileTitle => 'Edit Profile';

  @override
  String get manageProfileNameLabel => 'Name';

  @override
  String get manageProfileSaveButton => 'Save';

  @override
  String get manageProfileNameRequired => 'Please enter your name';

  @override
  String get manageProfileSuccessMessage => 'Profile updated successfully';

  @override
  String get remindersHeaderTitle => 'Reminders';

  @override
  String get remindersHeaderSubtitle => 'Nothing scheduled yet';

  @override
  String get remindersHeaderAll => 'All';

  @override
  String get remindersHeaderChores => 'Chores';

  @override
  String get remindersHeaderAppointments => 'Appointments';

  @override
  String get remindersHeaderBirthdays => 'Birthdays';

  @override
  String get remindersErrorTitle => 'Something went wrong';

  @override
  String get remindersErrorDescription => 'Could not load reminders';

  @override
  String get remindersErrorRetry => 'Try again';

  @override
  String get remindersEmptyTitle => 'No reminders yet';

  @override
  String get remindersEmptyDescription =>
      'Keep your family on track — create your first reminder for chores, appointments or birthdays.';

  @override
  String get remindersEmptyCreateButton => 'Create First Reminder';

  @override
  String get remindersEmptySuggestionsTitle => 'What can you track ?';

  @override
  String get remindersSuggestionsChoresTitle => 'Chores';

  @override
  String get remindersSuggestionsChoresSubtitle =>
      'Assign recurring tasks to family members';

  @override
  String get remindersSuggestionsAppointmentsTitle => 'Appointments';

  @override
  String get remindersSuggestionsAppointmentsSubtitle =>
      'Doctor, school events and one-off plans';

  @override
  String get remindersSuggestionsBirthdaysTitle => 'Birthdays';

  @override
  String get remindersSuggestionsBirthdaysSubtitle =>
      'Never miss a special day for your family';

  @override
  String get remindersSuggestionsAddButton => 'Add';
}
