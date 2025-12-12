# FEO Full Issue History Email

Redmine plugin that adds complete issue history to email notifications.

## Features

- Adds full issue history (all journals) to `issue_add` and `issue_edit` email notifications
- Shows chronological list of all changes with:
  - Date and time
  - User who made the change
  - Comments (notes)
  - Field changes (details)
- Configurable via plugin settings (can be enabled/disabled)
- Supports multiple languages (EN, CS)

## Requirements

- Redmine >= 6.0.0
- Rails >= 7.0

## Installation

1. Copy plugin to Redmine plugins directory:
   ```bash
   cd /usr/src/redmine/plugins
   git clone https://github.com/feo-cz/feo_full_issue_history_email.git
   ```

2. Restart Redmine:
   ```bash
   touch /usr/src/redmine/tmp/restart.txt
   ```

3. Configure plugin in Administration → Plugins → FEO Full Issue History Email → Configure

## Configuration

Go to **Administration → Plugins → FEO Full Issue History Email → Configure**

- **Include full history in email notifications**: Enable/disable the plugin functionality (default: enabled)

## Usage

Once enabled, all email notifications for:
- New issues (`issue_add`)
- Issue updates (`issue_edit`)

will include a complete history section at the end showing all journals in chronological order.

## Example Output

```
----------------------------------------
2025-01-10 14:33 – Jan Novák
Notes:
This is a comment about the change.

Changes:
  * Subject: "Old subject" → "New subject"
  * Priority: "Normal" → "High"
----------------------------------------
```

## Author

FEO - https://www.feo.cz

## License

This plugin is released under the MIT License.
