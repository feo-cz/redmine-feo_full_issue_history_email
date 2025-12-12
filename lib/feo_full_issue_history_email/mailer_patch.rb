module FeoFullIssueHistoryEmail
  module MailerPatch
    def self.included(base)
      base.class_eval do
        helper :feo_issue_history
      end
    end

    module Helper
      def include_issue_history?
        Setting.plugin_feo_full_issue_history_email['include_history'].to_s == 'true'
      end

      def format_journal_details(detail)
        case detail.property
        when 'attr'
          label = l("field_#{detail.prop_key}", default: detail.prop_key.to_s.humanize)
          old_value = detail.old_value.presence || '-'
          new_value = detail.value.presence || '-'
          "  * #{label}: \"#{old_value}\" → \"#{new_value}\""
        when 'attachment'
          "  * #{l(:label_attachment)}: #{detail.value}"
        when 'cf'
          custom_field = CustomField.find_by(id: detail.prop_key)
          field_name = custom_field ? custom_field.name : "Custom field #{detail.prop_key}"
          old_value = detail.old_value.presence || '-'
          new_value = detail.value.presence || '-'
          "  * #{field_name}: \"#{old_value}\" → \"#{new_value}\""
        else
          old_value = detail.old_value.presence || '-'
          new_value = detail.value.presence || '-'
          "  * #{detail.prop_key}: \"#{old_value}\" → \"#{new_value}\""
        end
      end
    end
  end
end

# Register helper module
ActionView::Base.send(:include, FeoFullIssueHistoryEmail::MailerPatch::Helper)

# Include patch in Mailer
Mailer.send(:include, FeoFullIssueHistoryEmail::MailerPatch)
