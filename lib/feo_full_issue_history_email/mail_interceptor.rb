module FeoFullIssueHistoryEmail
  class MailInterceptor
    def self.delivering_email(message)
      return unless should_include_history?

      # Check if this is an issue notification email
      issue = extract_issue_from_headers(message)
      return unless issue

      Rails.logger.info "FEO History: Interceptor processing issue ##{issue.id}"
      Rails.logger.info "FEO History: Original subject: #{message.subject}"

      append_issue_history(message, issue)

      Rails.logger.info "FEO History: Final subject: #{message.subject}"
    end

    private

    def self.should_include_history?
      Setting.plugin_feo_full_issue_history_email['include_history'].to_s == 'true'
    rescue
      true
    end

    def self.extract_issue_from_headers(message)
      # Extract issue ID from X-Redmine-Issue-Id header
      issue_id = message.header['X-Redmine-Issue-Id']&.value
      return nil unless issue_id

      Issue.find_by(id: issue_id)
    rescue
      nil
    end

    def self.append_issue_history(message, issue)
      history_text = build_history_text(issue)
      history_html = build_history_html(issue)
      Rails.logger.info "FEO History: History text length: #{history_text.length} chars"

      # Insert into text part after issue details
      if message.text_part
        original_body = message.text_part.body.to_s
        Rails.logger.info "FEO History: Original text_part body length: #{original_body.length}"
        # Find the separator line after issue details and insert history before it
        if original_body =~ /(.*?----------------------------------------\n)(.*)/m
          message.text_part.body = $1 + history_text + "\n" + $2
        else
          # Fallback: append to end
          message.text_part.body = original_body + "\n\n" + history_text
        end
        Rails.logger.info "FEO History: New text_part body length: #{message.text_part.body.to_s.length}"
      elsif !message.html_part
        # Plain text only email
        Rails.logger.info "FEO History: Using plain message.body"
        original_body = message.body.to_s
        if original_body =~ /(.*?----------------------------------------\n)(.*)/m
          message.body = $1 + history_text + "\n" + $2
        else
          message.body = original_body + "\n\n" + history_text
        end
      end

      # Insert into HTML part after issue details
      if message.html_part
        original_html = message.html_part.body.to_s
        Rails.logger.info "FEO History: Original html_part body length: #{original_html.length}"
        # Insert after the details list (after </ul>)
        if original_html =~ /(<ul class="details".*?<\/ul>)(.*?<hr)/m
          message.html_part.body = original_html.sub(/(<ul class="details".*?<\/ul>)(.*?)(<hr)/m, "\\1#{history_html}\\3")
        else
          # Fallback: insert before closing body tag
          if original_html =~ /<\/body>/i
            message.html_part.body = original_html.sub(/<\/body>/i, "#{history_html}</body>")
          else
            message.html_part.body = original_html + history_html
          end
        end
        Rails.logger.info "FEO History: New html_part body length: #{message.html_part.body.to_s.length}"
      end
    end

    def self.build_history_text(issue)
      output = []
      output << ""
      output << "----------------------------------------"
      output << I18n.t(:label_history)
      output << "----------------------------------------"

      issue.journals.reorder(created_on: :desc).each do |journal|
        user_name = journal.user ? journal.user.name : I18n.t(:label_user_anonymous)
        timestamp = journal.created_on.strftime('%Y-%m-%d %H:%M')

        # Show notes if present
        if journal.notes.present?
          output << ""
          output << "#{timestamp}, #{user_name} napsal(a):"
          output << journal.notes
        end

        # Show only file attachments
        attachment_details = journal.details.select { |d| d.property == 'attachment' && d.value.present? }
        attachment_details.each do |detail|
          output << ""
          output << "#{timestamp}, #{user_name} přidal(a) soubor: #{detail.value}"
        end
      end

      output << "----------------------------------------"
      output << ""
      output.join("\n")
    end

    def self.build_history_html(issue)
      require 'cgi'
      output = []
      output << '<h2 style="font-family:sans-serif;margin:1em 0 0.5em 0;font-size:1.1em">'
      output << CGI.escapeHTML(I18n.t(:label_history))
      output << '</h2>'

      issue.journals.reorder(created_on: :desc).each do |journal|
        user_name = journal.user ? journal.user.name : I18n.t(:label_user_anonymous)
        timestamp = journal.created_on.strftime('%Y-%m-%d %H:%M')

        # Show notes if present
        if journal.notes.present?
          output << '<div style="margin:0.5em 0">'
          output << '<strong>'
          output << CGI.escapeHTML("#{timestamp}, #{user_name} napsal(a):")
          output << '</strong>'
          output << '<p style="margin:0.3em 0 0.5em 1em">'
          output << CGI.escapeHTML(journal.notes).gsub("\n", '<br>')
          output << '</p>'
          output << '</div>'
        end

        # Show only file attachments
        attachment_details = journal.details.select { |d| d.property == 'attachment' && d.value.present? }
        attachment_details.each do |detail|
          output << '<div style="margin:0.5em 0">'
          output << '<strong>'
          output << CGI.escapeHTML("#{timestamp}, #{user_name} přidal(a) soubor: #{detail.value}")
          output << '</strong>'
          output << '</div>'
        end
      end

      output.join("\n")
    end

    def self.format_detail(detail)
      case detail.property
      when 'attr'
        label = I18n.t("field_#{detail.prop_key}", default: detail.prop_key.to_s.humanize)
        old_value = detail.old_value.presence || '-'
        new_value = detail.value.presence || '-'
        "  * #{label}: \"#{old_value}\" → \"#{new_value}\""
      when 'attachment'
        "  * #{I18n.t(:label_attachment)}: #{detail.value}"
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

# Register the interceptor
# The to_prepare in init.rb ensures this loads after other plugins
ActionMailer::Base.register_interceptor(FeoFullIssueHistoryEmail::MailInterceptor)
Rails.logger.info "FEO History: Interceptor registered"
