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
  String get homeEmptyRemindersSectionTitle => 'Próximos Lembretes';

  @override
  String get homeEmptyRemindersEmptyTitle => 'Nenhum lembrete ainda';

  @override
  String get homeEmptyRemindersEmptyDescription =>
      'Crie seu primeiro lembrete para manter a família organizada.';

  @override
  String get homeEmptyRemindersCreateButton => 'Criar Lembrete';

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
      ' · Compartilhe apenas com\nfamiliares de confiança';

  @override
  String get peopleWidgetsPendingInviteCardTitle => '1 Convite Pendente';

  @override
  String get peopleWidgetsPendingInviteResendButton => 'Reenviar';

  @override
  String get peopleWidgetsRolePermissionsTitle => 'Permissões de Função';

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
  String get remindersHeaderTitle => 'Lembretes';

  @override
  String get remindersHeaderSubtitle => 'Nada agendado ainda';

  @override
  String get remindersHeaderAll => 'Todos';

  @override
  String get remindersHeaderChores => 'Tarefas';

  @override
  String get remindersHeaderAppointments => 'Compromissos';

  @override
  String get remindersHeaderBirthdays => 'Aniversários';

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
}
