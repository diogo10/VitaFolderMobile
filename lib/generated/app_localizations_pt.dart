// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'VitaFolder';

  @override
  String get navHome => 'Início';

  @override
  String get navPeople => 'Pessoas';

  @override
  String get navReminders => 'Lembretes';

  @override
  String get navAccount => 'Conta';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get onboardingTitle1 => 'Reúna toda a sua família em um só lugar';

  @override
  String get onboardingSubtitle1 =>
      'Convide pais, filhos e cuidadores para entrar no seu círculo familiar privado e colaborar em tempo real.';

  @override
  String get onboardingTitle2 => 'Fique por dentro de cada tarefa';

  @override
  String get onboardingSubtitle2 =>
      'Compartilhe tarefas, compromissos e lembretes com o seu círculo para que nada passe despercebido.';

  @override
  String get onboardingTitle3 => 'Celebre cada momento em família';

  @override
  String get onboardingSubtitle3 =>
      'Mantenha todos conectados com lembretes simples, planos compartilhados e cronologias familiares.';

  @override
  String get onboardingFamilyCircleLabel => 'Círculo da Família';

  @override
  String get onboardingInviteBadge => '+ Convidar';

  @override
  String get homeError => 'Algo deu errado.';

  @override
  String get homeToday => 'Hoje';

  @override
  String get homeTasks => 'Tarefas';

  @override
  String get homeCompleted => 'Concluídas';

  @override
  String get homePending => 'Pendentes';

  @override
  String get homeEmptyHeaderTitle => 'Bem-vindo ao FamilyAdmin';

  @override
  String get homeEmptyHeaderSubtitle => 'Vamos começar';

  @override
  String get homeEmptyHeaderDescription =>
      'Seu hub familiar está pronto. Configure-o em alguns passos simples.';

  @override
  String get homeEmptyAddPeopleTitle => 'Adicione pessoas ao seu Círculo';

  @override
  String get homeEmptyAddPeopleSubtitle =>
      'Convide pais, filhos ou cuidadores para sua família.';

  @override
  String get homeEmptyAddPeopleButton => 'Adicionar';

  @override
  String get homeEmptyReminderTitle => 'Crie um Lembrete';

  @override
  String get homeEmptyReminderSubtitle =>
      'Agende tarefas, eventos e não perca nada.';

  @override
  String get homeEmptyReminderButton => 'Configurar';

  @override
  String get homeEmptyAccountTitle => 'Complete sua Conta';

  @override
  String get homeEmptyAccountSubtitle =>
      'Adicione seu nome, foto e dados de contato.';

  @override
  String get homeEmptyAccountButton => 'Ir';

  @override
  String get homeEmptyFooterCircleTitle => 'O Círculo';

  @override
  String get homeEmptyFooterAddPeopleLink => 'Adicionar pessoas';

  @override
  String get homeEmptyFooterNoMembersTitle => 'Nenhum membro ainda';

  @override
  String get homeEmptyFooterNoMembersDescription =>
      'Adicione familiares para começar a colaborar e acompanhar juntos.';

  @override
  String get homeEmptyFooterAddMemberButton => 'Adicionar Membro';

  @override
  String get homeEmptyInviteInviteParentTitle => 'Convide um Pai/Mãe';

  @override
  String get homeEmptyInviteInviteParentSubtitle =>
      'Colabore no seu hub familiar';

  @override
  String get homeEmptyInviteShareButton => 'Compartilhar';

  @override
  String get homeEmptyInviteShareMessage =>
      'Junte-se ao meu círculo familiar no VitaFolder.';

  @override
  String get homeEmptyRemindersSectionTitle => 'Próximos Lembretes';

  @override
  String get homeEmptyRemindersEmptyTitle => 'Nenhum lembrete ainda';

  @override
  String get homeEmptyRemindersEmptyDescription =>
      'Crie seu primeiro lembrete para manter a família organizada.';

  @override
  String get homeEmptyRemindersCreateButton => 'Criar Lembrete';

  @override
  String get homeSuccessGreetingMorning => 'Bom dia,';

  @override
  String get homeSuccessGreetingAfternoon => 'Boa tarde,';

  @override
  String get homeSuccessGreetingEvening => 'Boa noite,';

  @override
  String homeSuccessActiveMembers(int members, int pending) {
    return '$members membros ativos hoje · $pending lembretes pendentes';
  }

  @override
  String get homeSuccessAddTaskTitle => 'Adicionar Tarefa';

  @override
  String get homeSuccessAddTaskSubtitle =>
      'Agende rapidamente uma tarefa ou evento';

  @override
  String get homeSuccessAddTaskButton => 'Adicionar';

  @override
  String get homeSuccessManageActivityTitle => 'Gerenciar Atividade';

  @override
  String get homeSuccessManageActivitySubtitle =>
      'Revise tudo o que está agendado';

  @override
  String get homeSuccessManageActivityButton => 'Abrir';

  @override
  String get homeSuccessRemindersAdd => 'Adicionar';

  @override
  String get homeSuccessRemindersToday => 'Hoje';

  @override
  String get homeSuccessRemindersTomorrow => 'Amanhã';

  @override
  String get homeSuccessCircleManage => 'Gerenciar';

  @override
  String get peopleViewTryAgain => 'Tentar novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get peopleViewCreateFamily => 'Criar Família';

  @override
  String get peopleViewFamilyNameHint => 'Digite o nome da família';

  @override
  String get peopleEmptyTitle => 'Nenhum familiar ainda';

  @override
  String get peopleEmptyDescription =>
      'Adicione seu primeiro familiar para começar.';

  @override
  String get peopleLoadedTheCircle => 'O Círculo';

  @override
  String peopleLoadedMembersCount(int count, Object family) {
    return '$count membros · $family';
  }

  @override
  String get peopleLoadedInviteCodeCopied => 'Código de convite copiado';

  @override
  String get peopleLoadedInviteLinkCopied => 'Link de convite copiado';

  @override
  String get peopleLoadedInviteCodeRefreshed => 'Código de convite atualizado';

  @override
  String get peopleLoadedPendingInviteSent => 'há 2 dias';

  @override
  String get peopleLoadedInvitationSentAgain => 'Convite enviado novamente';

  @override
  String get peopleLoadedMembersTitle => 'Membros';

  @override
  String get peopleLoadedAddMemberButton => 'Adicionar Membro';

  @override
  String get peopleLoadedNotificationMessage => 'Nenhuma notificação nova';

  @override
  String get peopleLoadedProfileMessage => 'Perfil selecionado';

  @override
  String get peopleLoadedAddMemberSelected => 'Adicionar membro selecionado';

  @override
  String peopleLoadedMemberSelected(String name) {
    return '$name selecionado(a)';
  }

  @override
  String get peopleLoadedAddFamilyMemberSelected =>
      'Adicionar familiar selecionado';

  @override
  String get peopleLoadedRolePermissionsSelected =>
      'Permissões de função selecionadas';

  @override
  String get peopleWidgetsFamilyHeaderNotificationsTooltip => 'Notificações';

  @override
  String get peopleWidgetsFamilyHeaderProfileSemantics => 'Abrir perfil';

  @override
  String get peopleWidgetsFamilyMemberRoleAdmin => 'Admin';

  @override
  String get peopleWidgetsFamilyMemberRoleParent => 'Responsável';

  @override
  String get peopleWidgetsFamilyMemberRoleChild => 'Criança';

  @override
  String get peopleWidgetsFamilyMemberRoleMember => 'Membro';

  @override
  String get peopleWidgetsAddFamilyMemberTitle => 'Adicionar Familiar';

  @override
  String get peopleWidgetsAddFamilyMemberSubtitle =>
      'Convide por código ou email';

  @override
  String get peopleWidgetsInviteCodeCardLabel => 'Código de Convite Familiar';

  @override
  String get peopleWidgetsInviteCodeCopyTooltip => 'Copiar código de convite';

  @override
  String get peopleWidgetsInviteCodeShareButton => 'Compartilhar Link';

  @override
  String get peopleWidgetsInviteCodeRefreshButton => 'Atualizar Código';

  @override
  String get peopleWidgetsInviteCodeExpiresPrefix => 'Código expira em ';

  @override
  String peopleWidgetsInviteCodeExpiresDays(int count) {
    return '$count dias';
  }

  @override
  String get peopleWidgetsInviteCodeExpiresSuffix =>
      'Compartilhe apenas com familiares de confiança';

  @override
  String get peopleWidgetsPendingInviteCardTitle => '1 Convite Pendente';

  @override
  String get peopleWidgetsPendingInviteResendButton => 'Reenviar';

  @override
  String get peopleWidgetsRolePermissionsTitle => 'Funções';

  @override
  String get peopleWidgetsRolePermissionsDescription =>
      'Admins podem gerenciar todos os membros. Responsáveis podem adicionar tarefas. Crianças têm acesso apenas para visualizar.';

  @override
  String get peopleWidgetsRolePermissionsLearnMore => 'Saiba mais →';

  @override
  String get accountHeaderCurrentPlan => 'Plano Atual';

  @override
  String get accountHeaderPlanName => 'Family Pro';

  @override
  String get accountHeaderPlanDescription =>
      'Até 8 membros · Lembretes ilimitados';

  @override
  String get accountHeaderStatusActive => 'Ativo';

  @override
  String get accountSettingsAccountSection => 'CONTA';

  @override
  String get accountSettingsEditProfile => 'Editar Perfil';

  @override
  String get accountSettingsEditProfileSubtitle =>
      'Nome, foto, informações de contato';

  @override
  String get accountSettingsPasswordSecurity => 'Senha e Segurança';

  @override
  String get accountSettingsPasswordSecuritySubtitle => 'Alterar senha, 2FA';

  @override
  String get accountSettingsNotifications => 'Notificações';

  @override
  String get accountSettingsNotificationsSubtitle =>
      'Preferências de push e email';

  @override
  String get accountSettingsFamilySection => 'FAMÍLIA';

  @override
  String get accountSettingsFamilySettings => 'Configurações da Família';

  @override
  String get accountSettingsFamilySettingsSubtitle =>
      'Nome da família, preferências';

  @override
  String get accountSettingsRolesPermissions => 'Funções e Permissões';

  @override
  String get accountSettingsRolesPermissionsSubtitle =>
      'Gerenciar acesso de admin';

  @override
  String get accountSettingsInviteMembers => 'Convidar Membros';

  @override
  String get accountSettingsInviteMembersSubtitle =>
      'Compartilhar código de convite';

  @override
  String get accountSettingsSupportSection => 'SUPORTE';

  @override
  String get accountSettingsHelpFaq => 'Ajuda e FAQ';

  @override
  String get accountSettingsHelpFaqSubtitle =>
      'Obter respostas, falar com suporte';

  @override
  String get accountSettingsPrivacyPolicy => 'Política de Privacidade';

  @override
  String get accountSettingsPrivacyPolicySubtitle => 'Como tratamos seus dados';

  @override
  String get accountSettingsSignOut => 'Sair';

  @override
  String get accountSettingsSignOutSubtitle => 'Sair deste dispositivo';

  @override
  String get notificationSettingsTitle => 'Configurações de Notificação';

  @override
  String get notificationSettingsSection => 'NOTIFICAÇÕES';

  @override
  String get notificationSettingsEnableNotifications => 'Ativar notificações';

  @override
  String get notificationSettingsEnableNotificationsSubtitle =>
      'Seja notificado sobre lembretes e atualizações da família';

  @override
  String get notificationSettingsEmailUpdates => 'Atualizações por email';

  @override
  String get notificationSettingsEmailUpdatesSubtitle =>
      'Receba um resumo por email';

  @override
  String get notificationSettingsPermissionDenied =>
      'A permissão de notificações foi negada. Você pode ativá-la nas configurações do sistema.';

  @override
  String get notificationSettingsPermissionPermanentlyDenied =>
      'A permissão de notificações foi negada permanentemente. Ative-a nas configurações do sistema.';

  @override
  String get notificationSettingsError =>
      'Algo deu errado ao carregar suas configurações.';

  @override
  String get manageProfileTitle => 'Editar Perfil';

  @override
  String get manageProfileNameLabel => 'Nome';

  @override
  String get manageProfileSaveButton => 'Salvar';

  @override
  String get manageProfileNameRequired => 'Por favor, digite seu nome';

  @override
  String get manageProfileSuccessMessage => 'Perfil atualizado com sucesso';

  @override
  String get accountSignedOut => 'Sua sessão foi encerrada.';

  @override
  String get accountLoginFailed => 'Falha no login. Tente novamente.';

  @override
  String get accountPasswordResetSent =>
      'Enviamos um link para o seu email redefinir sua senha.';

  @override
  String get accountPasswordResetEnterEmail =>
      'Por favor, digite seu endereço de email.';

  @override
  String get accountPasswordResetFailed =>
      'Não foi possível enviar o link de redefinição. Tente novamente.';

  @override
  String get accountNoAccountContinueGoogle => 'Continuar com Google';

  @override
  String get accountNoAccountContinueApple => 'Continuar com Apple';

  @override
  String get accountNoAccountOrEmail => 'ou entre com email';

  @override
  String get accountNoAccountEmailLabel => 'Endereço de email';

  @override
  String get accountNoAccountPasswordLabel => 'Senha';

  @override
  String get accountNoAccountForgotPassword => 'Esqueceu a senha?';

  @override
  String get accountNoAccountSignIn => 'Entrar';

  @override
  String get accountNoAccountNewToApp => 'Novo no FamilyAdmin?';

  @override
  String get accountNoAccountCreateFreeAccount => 'Crie uma conta gratuita';

  @override
  String get accountNoAccountSecurePrivate => 'Seguro e privado';

  @override
  String get accountNoAccountFreeToStart => 'Grátis para começar';

  @override
  String get accountNoAccountFamilyPlan => 'Plano familiar';

  @override
  String get accountNoAccountTitle => 'Sua família, organizada em conjunto';

  @override
  String get accountNoAccountSubtitle =>
      'Gerencie seu círculo, defina lembretes e colabore em família — tudo em um só lugar.';

  @override
  String get accountNoAccountChipChores => 'Tarefas';

  @override
  String get accountNoAccountChipAppointments => 'Compromissos';

  @override
  String get accountNoAccountChipFamilyCircle => 'Círculo da Família';

  @override
  String get accountNoAccountFamilyAdmin => 'Admin da família';

  @override
  String get signUpTitle => 'Cadastre-se';

  @override
  String get signUpNameLabel => 'Nome';

  @override
  String get signUpEmailLabel => 'Email';

  @override
  String get signUpPasswordLabel => 'Senha';

  @override
  String get signUpSuccessMessage => 'Obrigado, você concluiu o cadastro.';

  @override
  String get signUpNameRequired => 'Por favor, digite seu nome';

  @override
  String get signUpEmailRequired => 'Por favor, digite um email';

  @override
  String get signUpEmailInvalid => 'Por favor, digite um email válido';

  @override
  String get signUpPasswordRequired => 'Por favor, digite uma senha';

  @override
  String get signUpPasswordTooShort =>
      'A senha deve ter pelo menos 6 caracteres';

  @override
  String get signUpUnexpectedError => 'Ocorreu um erro inesperado.';

  @override
  String get peopleInvalidFamilyCode =>
      'Código de família inválido. Tente novamente.';

  @override
  String get invitePeopleTitle => 'Convidar Pessoas';

  @override
  String get invitePeopleSent => 'Convite enviado!';

  @override
  String get invitePeopleSend => 'Enviar Convite';

  @override
  String get invitePeopleEmailLabel => 'Email';

  @override
  String get invitePeopleRelationshipLabel => 'Parentesco';

  @override
  String get invitePeopleRelationshipSelf => 'Eu mesmo(a)';

  @override
  String get invitePeopleRelationshipSpouse => 'Cônjuge';

  @override
  String get invitePeopleRelationshipChild => 'Filho(a)';

  @override
  String get invitePeopleRelationshipParent => 'Pai/Mãe';

  @override
  String get invitePeopleRelationshipOther => 'Outro';

  @override
  String get invitePeopleError => 'Falha ao enviar o email de convite.';

  @override
  String invitePeopleEmailSubject(String relationship) {
    return 'Você foi convidado(a) como $relationship para o VitaFolder';
  }

  @override
  String get peopleEmptyCreateFamily => '+ Criar Família';

  @override
  String get peopleEmptyEnterCode => 'Digite o Código de Convite';

  @override
  String get peopleEmptyJoinFamily => 'Entrar na Família';

  @override
  String get peopleEmptyAskAdmin =>
      'Peça o código de convite ao administrador da sua família';

  @override
  String get peopleEmptyEmailInvite => 'Convite por Email';

  @override
  String get peopleEmptyEmailInviteSubtitle =>
      'Verifique seu email para um link de convite';

  @override
  String get peopleEmptyPrivateSecure => 'Privado e Seguro';

  @override
  String get peopleEmptyPrivateSecureSubtitle =>
      'Apenas pessoas com o código ou um convite direto podem entrar.';

  @override
  String get remindersHeaderTitle => 'Lembretes';

  @override
  String get remindersHeaderAll => 'Todos';

  @override
  String get remindersErrorTitle => 'Algo deu errado';

  @override
  String get remindersErrorDescription =>
      'Não foi possível carregar os lembretes';

  @override
  String get remindersErrorRetry => 'Tentar novamente';

  @override
  String get remindersEmptyTitle => 'Nenhum lembrete ainda';

  @override
  String get remindersEmptyDescription =>
      'Mantenha sua família organizada — crie seu primeiro lembrete para tarefas, compromissos ou aniversários.';

  @override
  String get remindersEmptyCreateButton => 'Criar Primeiro Lembrete';

  @override
  String get remindersEmptySuggestionsTitle => 'O que você pode acompanhar?';

  @override
  String get remindersSuggestionsChoresTitle => 'Tarefas';

  @override
  String get remindersSuggestionsChoresSubtitle =>
      'Atribua tarefas recorrentes aos familiares';

  @override
  String get remindersSuggestionsAppointmentsTitle => 'Compromissos';

  @override
  String get remindersSuggestionsAppointmentsSubtitle =>
      'Médico, eventos escolares e planos pontuais';

  @override
  String get remindersSuggestionsBirthdaysTitle => 'Aniversários';

  @override
  String get remindersSuggestionsBirthdaysSubtitle =>
      'Nunca perca uma data especial para sua família';

  @override
  String get remindersSuggestionsAddButton => 'Adicionar';

  @override
  String get createReminderTitle => 'Novo Lembrete';

  @override
  String get createReminderTitleLabel => 'Título';

  @override
  String get createReminderTitleRequired => 'Digite um título';

  @override
  String get createReminderBodyLabel => 'Detalhes';

  @override
  String get createReminderTypeLabel => 'Tipo';

  @override
  String get createReminderDueDateLabel => 'Data de vencimento';

  @override
  String get createReminderRepeatRuleLabel => 'Repetir';

  @override
  String get createReminderRepeatNever => 'Nunca';

  @override
  String get createReminderRepeatDaily => 'Diariamente';

  @override
  String get createReminderRepeatWeekly => 'Semanalmente';

  @override
  String get createReminderRepeatMonthly => 'Mensalmente';

  @override
  String get createReminderSaveButton => 'Criar Lembrete';

  @override
  String get createReminderSuccessMessage => 'Lembrete criado com sucesso';

  @override
  String get createReminderTypeRenewal => 'Renovação';

  @override
  String get createReminderTypeAppointment => 'Compromisso';

  @override
  String get createReminderTypeVaccine => 'Vacina';

  @override
  String get createReminderTypeReimbursement => 'Reembolso';

  @override
  String get createReminderTypeBirthday => 'Aniversário';

  @override
  String get createReminderTypeChores => 'Tarefas';

  @override
  String get createReminderTypeCustom => 'Personalizado';

  @override
  String get reminderStatusPending => 'Pendente';

  @override
  String get reminderStatusSent => 'Enviado';

  @override
  String get reminderStatusDone => 'Concluído';

  @override
  String get reminderStatusDismissed => 'Dispensado';

  @override
  String get reminderStatusCancelled => 'Cancelado';

  @override
  String get remindersLoadedSectionToday => 'Hoje';

  @override
  String get remindersLoadedSectionTomorrow => 'Amanhã';

  @override
  String get remindersLoadedSectionAllDay => 'Dia todo';

  @override
  String get reminderDeleteDialogTitle => 'Remover lembrete';

  @override
  String reminderDeleteDialogMessage(String title) {
    return 'Tem certeza que deseja remover \"$title\"?';
  }

  @override
  String get reminderDeleteDialogConfirm => 'Remover';
}
