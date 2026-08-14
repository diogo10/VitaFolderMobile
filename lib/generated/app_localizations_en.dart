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
  String get onboardingTitle1 => 'Bring your whole family together';

  @override
  String get onboardingSubtitle1 =>
      'Invite parents, children, and caregivers to join your private family circle and collaborate in real time.';

  @override
  String get onboardingTitle2 => 'Stay on top of every task';

  @override
  String get onboardingSubtitle2 =>
      'Share chores, appointments, and reminders with your circle so nothing gets overlooked.';

  @override
  String get onboardingTitle3 => 'Celebrate every moment as a family';

  @override
  String get onboardingSubtitle3 =>
      'Keep everyone connected with simple reminders, shared plans, and family timelines.';

  @override
  String get onboardingFamilyCircleLabel => 'Family Circle';

  @override
  String get onboardingInviteBadge => '+ Invite';

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
  String get homeEmptyInviteShareMessage =>
      'Join my family circle on VitaFolder.';

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
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get notificationSettingsSection => 'NOTIFICATIONS';

  @override
  String get notificationSettingsEnableNotifications => 'Enable notifications';

  @override
  String get notificationSettingsEnableNotificationsSubtitle =>
      'Get notified about reminders and family updates';

  @override
  String get notificationSettingsEmailUpdates => 'Email updates';

  @override
  String get notificationSettingsEmailUpdatesSubtitle =>
      'Receive a summary by email';

  @override
  String get notificationSettingsPermissionDenied =>
      'Notifications permission was denied. You can enable it in system settings.';

  @override
  String get notificationSettingsPermissionPermanentlyDenied =>
      'Notifications permission is permanently denied. Please enable it in system settings.';

  @override
  String get notificationSettingsError =>
      'Something went wrong loading your settings.';

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
  String get accountSignedOut => 'You have been signed out.';

  @override
  String get accountLoginFailed => 'Login failed. Please try again.';

  @override
  String get accountPasswordResetSent =>
      'We\'ve sent a link to your email to reset your password.';

  @override
  String get accountPasswordResetEnterEmail =>
      'Please enter your email address.';

  @override
  String get accountPasswordResetFailed =>
      'We could not send the reset link. Please try again.';

  @override
  String get accountNoAccountContinueGoogle => 'Continue with Google';

  @override
  String get accountNoAccountContinueApple => 'Continue with Apple';

  @override
  String get accountNoAccountOrEmail => 'or sign in with email';

  @override
  String get accountNoAccountEmailLabel => 'Email address';

  @override
  String get accountNoAccountPasswordLabel => 'Password';

  @override
  String get accountNoAccountForgotPassword => 'Forgot password?';

  @override
  String get accountNoAccountSignIn => 'Sign In';

  @override
  String get accountNoAccountNewToApp => 'New to FamilyAdmin?';

  @override
  String get accountNoAccountCreateFreeAccount => 'Create a free account';

  @override
  String get accountNoAccountSecurePrivate => 'Secure & private';

  @override
  String get accountNoAccountFreeToStart => 'Free to start';

  @override
  String get accountNoAccountFamilyPlan => 'Family plan';

  @override
  String get accountNoAccountTitle => 'Your family, organised together';

  @override
  String get accountNoAccountSubtitle =>
      'Manage your circle, set reminders and collaborate as a family — all in one place.';

  @override
  String get accountNoAccountChipChores => 'Chores';

  @override
  String get accountNoAccountChipAppointments => 'Appointments';

  @override
  String get accountNoAccountChipFamilyCircle => 'Family Circle';

  @override
  String get accountNoAccountFamilyAdmin => 'Family admin';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get signUpNameLabel => 'Name';

  @override
  String get signUpEmailLabel => 'Email';

  @override
  String get signUpPasswordLabel => 'Password';

  @override
  String get signUpSuccessMessage =>
      'Thanks, You have finished the the registration.';

  @override
  String get signUpNameRequired => 'Please enter your name';

  @override
  String get signUpEmailRequired => 'Please enter an email';

  @override
  String get signUpEmailInvalid => 'Please enter a valid email';

  @override
  String get signUpPasswordRequired => 'Please enter a password';

  @override
  String get signUpPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get signUpUnexpectedError => 'An unexpected error occurred.';

  @override
  String get peopleInvalidFamilyCode =>
      'Invalid family code. Please try again.';

  @override
  String get invitePeopleTitle => 'Invite People';

  @override
  String get invitePeopleSent => 'Invite sent!';

  @override
  String get invitePeopleSend => 'Send Invite';

  @override
  String get invitePeopleEmailLabel => 'Email';

  @override
  String get invitePeopleRelationshipLabel => 'Relationship';

  @override
  String get invitePeopleRelationshipSelf => 'Self';

  @override
  String get invitePeopleRelationshipSpouse => 'Spouse';

  @override
  String get invitePeopleRelationshipChild => 'Child';

  @override
  String get invitePeopleRelationshipParent => 'Parent';

  @override
  String get invitePeopleRelationshipOther => 'Other';

  @override
  String get invitePeopleError => 'Failed to send invite email.';

  @override
  String invitePeopleEmailSubject(String relationship) {
    return 'You have been invited as a $relationship for VitaFolder';
  }

  @override
  String get peopleEmptyCreateFamily => '+ Create Family';

  @override
  String get peopleEmptyEnterCode => 'Enter Invite Code';

  @override
  String get peopleEmptyJoinFamily => 'Join Family';

  @override
  String get peopleEmptyAskAdmin => 'Ask your family admin for the invite code';

  @override
  String get peopleEmptyEmailInvite => 'Email Invite';

  @override
  String get peopleEmptyEmailInviteSubtitle =>
      'Check your email for an invitation link';

  @override
  String get peopleEmptyPrivateSecure => 'Private & Secure';

  @override
  String get peopleEmptyPrivateSecureSubtitle =>
      'Only people with the code or a direct invite can join.';

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

  @override
  String get createReminderTitle => 'New Reminder';

  @override
  String get createReminderTitleLabel => 'Title';

  @override
  String get createReminderTitleRequired => 'Enter a title';

  @override
  String get createReminderBodyLabel => 'Details';

  @override
  String get createReminderTypeLabel => 'Type';

  @override
  String get createReminderDueDateLabel => 'Due date';

  @override
  String get createReminderRepeatRuleLabel => 'Repeat';

  @override
  String get createReminderRepeatNever => 'Never';

  @override
  String get createReminderRepeatDaily => 'Daily';

  @override
  String get createReminderRepeatWeekly => 'Weekly';

  @override
  String get createReminderRepeatMonthly => 'Monthly';

  @override
  String get createReminderSaveButton => 'Create Reminder';

  @override
  String get createReminderSuccessMessage => 'Reminder created successfully';

  @override
  String get createReminderTypeRenewal => 'Renewal';

  @override
  String get createReminderTypeAppointment => 'Appointment';

  @override
  String get createReminderTypeVaccine => 'Vaccine';

  @override
  String get createReminderTypeReimbursement => 'Reimbursement';

  @override
  String get createReminderTypeBirthday => 'Birthday';

  @override
  String get createReminderTypeChores => 'Chores';

  @override
  String get createReminderTypeCustom => 'Custom';

  @override
  String get reminderStatusPending => 'Pending';

  @override
  String get reminderStatusSent => 'Sent';

  @override
  String get reminderStatusDone => 'Done';

  @override
  String get reminderStatusDismissed => 'Dismissed';

  @override
  String get reminderStatusCancelled => 'Cancelled';
}
