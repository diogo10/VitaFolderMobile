// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HouseMira';

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
  String get onboardingNextStep => 'Next Step';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingTitle1 => 'Your Family,\nIn One Place';

  @override
  String get onboardingSubtitle1 =>
      'Bring everyone together in a private, secure circle. Stay connected with real-time status and instant updates.';

  @override
  String get onboardingTitle2 => 'Smart Family\nReminders';

  @override
  String get onboardingSubtitle2 =>
      'Set tasks and appointments for anyone. Get notified together and never miss a family milestone.';

  @override
  String get onboardingTitle3 => 'Secure & Private\nBy Design';

  @override
  String get onboardingSubtitle3 =>
      'Only your family circle can see your data. Manage admin roles and keep your home safe and organized.';

  @override
  String get onboardingAtHome => 'At Home';

  @override
  String get onboardingAtWork => 'At Work';

  @override
  String get onboardingEndToEndEncryption => 'End-to-End Encryption';

  @override
  String get onboardingReminderMedicineTitle => 'Lily\'s Medicine';

  @override
  String get onboardingReminderMedicineTime => 'Today · 8:30 AM';

  @override
  String get onboardingReminderGroceryTitle => 'Grocery Run';

  @override
  String get onboardingReminderGroceryTime => 'Today · 5:00 PM';

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
      'Join my family circle on HouseMira.';

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
  String get homeSuccessGreetingMorning => 'Good morning,';

  @override
  String get homeSuccessGreetingAfternoon => 'Good afternoon,';

  @override
  String get homeSuccessGreetingEvening => 'Good evening,';

  @override
  String homeSuccessActiveMembers(int members, int pending) {
    return '$members members active today · $pending reminders pending';
  }

  @override
  String get homeSuccessAddTaskTitle => 'Add Task';

  @override
  String get homeSuccessAddTaskSubtitle => 'Quickly schedule a task or event';

  @override
  String get homeSuccessAddTaskButton => 'Add';

  @override
  String get homeSuccessManageActivityTitle => 'Manage Activity';

  @override
  String get homeSuccessManageActivitySubtitle => 'Review everything scheduled';

  @override
  String get homeSuccessManageActivityButton => 'Open';

  @override
  String get homeSuccessRemindersAdd => 'Add';

  @override
  String get homeSuccessRemindersToday => 'Today';

  @override
  String get homeSuccessRemindersTomorrow => 'Tomorrow';

  @override
  String get homeSuccessRemindersNoDate => 'No date';

  @override
  String get homeSuccessCircleManage => 'Manage';

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
  String accountSettingsInviteMembersSubtitleWithCode(
    String familyCode,
    String subtitle,
  ) {
    return '$familyCode - $subtitle';
  }

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
  String get appBrandName => 'HouseMira';

  @override
  String get accountNoAccountTitleTop => 'Your family,';

  @override
  String get accountNoAccountTitleBottom => 'organised together';

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
  String get accountNoAccountEmailPlaceholder => 'you@example.com';

  @override
  String get accountNoAccountPasswordPlaceholder => '••••••••';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get signUpTitleTop => 'Join the circle,';

  @override
  String get signUpTitleBottom => 'start organizing.';

  @override
  String get signUpSubtitle =>
      'Create your account and invite your family members to start collaborating today.';

  @override
  String get signUpContinueGoogle => 'Sign up with Google';

  @override
  String get signUpOrEmail => 'or email';

  @override
  String get signUpNameLabel => 'Full Name';

  @override
  String get signUpNamePlaceholder => 'John Doe';

  @override
  String get signUpEmailLabel => 'Email address';

  @override
  String get signUpEmailPlaceholder => 'you@example.com';

  @override
  String get signUpPasswordLabel => 'Password';

  @override
  String get signUpPasswordPlaceholder => 'Create a strong password';

  @override
  String get signUpPasswordHint =>
      'Must be at least 8 characters long with a mix of letters and numbers.';

  @override
  String get signUpCreateAccount => 'Create Account';

  @override
  String get signUpAlreadyHaveAccount => 'Already have an account?';

  @override
  String get signUpSignInLink => 'Sign In';

  @override
  String get signUpAgreePrefix => 'By creating an account, you agree to our ';

  @override
  String get signUpTermsOfService => 'Terms of Service';

  @override
  String get signUpAgreeAnd => ' and ';

  @override
  String get signUpPrivacyPolicy => 'Privacy Policy';

  @override
  String get signUpAgreeSuffix => '.';

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
  String get signUpPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get signUpUnexpectedError => 'An unexpected error occurred.';

  @override
  String get peopleInvalidFamilyCode =>
      'Invalid family code. Please try again.';

  @override
  String get invitePeopleTitle => 'Invite People';

  @override
  String get invitePeopleHeroTitle => 'Grow your circle';

  @override
  String get invitePeopleHeroDescriptionPrefix =>
      'Enter your family member\'s email address below to send them an invitation to join ';

  @override
  String get invitePeopleHeroDescriptionGeneric =>
      'Enter your family member\'s email address below to send them an invitation to join your family.';

  @override
  String get invitePeopleEmailAddressLabel => 'Email Address';

  @override
  String get invitePeopleEmailPlaceholder => 'family@example.com';

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
    return 'You have been invited as a $relationship for HouseMira';
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
  String get remindersHeaderAll => 'All';

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
  String get createReminderTimeLabel => 'Time';

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
  String get createReminderNotifyTitle => 'Notifications';

  @override
  String get createReminderNotifyToggle => 'Notify me on this device';

  @override
  String get createReminderNotifyNoDateHint =>
      'Set a date to enable notifications';

  @override
  String get createReminderNotifyAtTime => 'At time';

  @override
  String get createReminderNotify15Min => '15 min before';

  @override
  String get createReminderNotify1Hour => '1 hour before';

  @override
  String get createReminderNotify1Day => '1 day before';

  @override
  String get createReminderNotifyDisabledMessage =>
      'Notifications are disabled. Enable them to receive reminders.';

  @override
  String get createReminderNotifySavedWithoutPermission =>
      'Reminder saved, but notifications are disabled.';

  @override
  String get createReminderNotifyUpdatedWithoutPermission =>
      'Reminder updated, but notifications are disabled.';

  @override
  String get createReminderNotifyOpenSettings => 'Settings';

  @override
  String get createReminderNotifyExactAlarmMessage =>
      'For on-time alerts, allow exact alarms in Settings.';

  @override
  String get createReminderSaveButton => 'Create Reminder';

  @override
  String get createReminderSuccessMessage => 'Reminder created successfully';

  @override
  String get createReminderUpdatedMessage => 'Reminder updated successfully';

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

  @override
  String get remindersLoadedSectionToday => 'Today';

  @override
  String get remindersLoadedSectionTomorrow => 'Tomorrow';

  @override
  String get remindersLoadedSectionNoDate => 'No date';

  @override
  String get remindersLoadedSectionAllDay => 'All day';

  @override
  String get reminderDeleteDialogTitle => 'Remove reminder';

  @override
  String reminderDeleteDialogMessage(String title) {
    return 'Are you sure you want to remove \"$title\"?';
  }

  @override
  String get reminderDeleteDialogConfirm => 'Remove';

  @override
  String get remindersCalendarViewCalendar => 'View as calendar';

  @override
  String get remindersCalendarViewList => 'View as list';

  @override
  String get remindersCalendarEmptyDay => 'No reminders for this day';

  @override
  String get createReminderTitleEdit => 'Edit Reminder';

  @override
  String get createReminderSaveButtonEdit => 'Save Changes';

  @override
  String get remindersFilterChores => 'Chores';

  @override
  String get remindersFilterAppointments => 'Appointments';

  @override
  String get remindersFilterBirthdays => 'Birthdays';

  @override
  String get remindersFilterRenewal => 'Renewal';

  @override
  String get remindersFilterVaccine => 'Vaccine';

  @override
  String get remindersFilterReimbursement => 'Reimbursement';

  @override
  String get remindersFilterCustom => 'Custom';

  @override
  String get remindersFilterTitle => 'Filter Reminders';

  @override
  String get remindersFilterApply => 'Apply Filters';

  @override
  String get needToBeLoggedIn =>
      'You need to be logged in to perform this action';

  @override
  String get familySettingsTitle => 'Family Settings';

  @override
  String get familyNameLabel => 'Family name';

  @override
  String get familyNameHint => 'Enter family name';

  @override
  String get manageMembersTitle => 'Manage Members';

  @override
  String memberCount(int count) {
    return '$count Total';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleChild => 'Child';

  @override
  String get roleMember => 'Member';

  @override
  String get youBadge => 'YOU';

  @override
  String removeMemberConfirm(String name, String familyName) {
    return 'Remove $name from $familyName?';
  }

  @override
  String get dangerZoneTitle => 'Danger Zone';

  @override
  String get deleteFamilyTitle => 'Delete Family Circle';

  @override
  String get deleteFamilyDescription =>
      'This action cannot be undone. All data, tasks, and members will be permanently removed.';

  @override
  String get deleteFamilyButton => 'Delete Circle';

  @override
  String get saveButton => 'Save';

  @override
  String get savedButton => 'Saved';

  @override
  String get saveSuccess => 'Family settings saved successfully';

  @override
  String get deleteSuccess => 'Family circle deleted';

  @override
  String get onlyAdminCanAccess =>
      'Only family admins can access family settings.';

  @override
  String get createReminderTitleHint => 'e.g. Weekly Grocery Run';

  @override
  String get createReminderBodyHint => 'Add some notes about this reminder...';

  @override
  String get createReminderOptional => 'Optional';

  @override
  String get remindersAllCaughtUp => 'You\'re all caught up 🎉';

  @override
  String peopleWidgetsPendingInviteSent(String email, String sentAt) {
    return '$email · sent $sentAt';
  }

  @override
  String get createReminderErrorNoFamily => 'No family found';

  @override
  String get createReminderErrorAuthRequired => 'Authentication required';

  @override
  String get familySettingsErrorNotFound => 'Family not found';
}
