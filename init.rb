Redmine::Plugin.register :feo_full_issue_history_email do
  name 'FEO Full Issue History Email'
  author 'FEO'
  description 'Adds complete issue history to email notifications (issue_add and issue_edit)'
  version '1.0.0'
  url 'https://github.com/feo-cz/feo_full_issue_history_email'
  author_url 'https://www.feo.cz'
  requires_redmine version_or_higher: '6.0.0'

  settings default: { 'include_history' => true },
           partial: 'settings/feo_full_issue_history_email'
end

Rails.application.config.after_initialize do
  require_relative 'lib/feo_full_issue_history_email/mail_interceptor'
end
