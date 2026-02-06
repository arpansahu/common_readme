#!/bin/bash
# repos_config.sh - Repository configuration for Jenkins pipeline creation

# List of repositories with their details
# Each line: repo_name|git_url|has_build|has_deploy|type

REPOS_LIST="
common_readme|https://github.com/arpansahu/common_readme.git|false|false|readme_management
arpansahu_dot_me|https://github.com/arpansahu/arpansahu_dot_me.git|true|true|django
borcelle_crm|https://github.com/arpansahu/borcelle_crm.git|true|true|django
chew_and_cheer|https://github.com/arpansahu/chew_and_cheer.git|true|true|django
clock_work|https://github.com/arpansahu/clock_work.git|true|true|django
django_starter|https://github.com/arpansahu/django_starter.git|true|true|django
great_chat|https://github.com/arpansahu/great_chat.git|true|true|django
numerical|https://github.com/arpansahu/numerical.git|true|true|django
school_chale_hum|https://github.com/arpansahu/school_chale_hum.git|true|true|django
third_eye|https://github.com/arpansahu/third_eye.git|true|true|django
altered_datum_api|https://github.com/arpansahu/altered_datum_api.git|true|true|django
"

# GitHub credentials ID in Jenkins
GITHUB_CRED_ID="github_auth"

# Default branch
DEFAULT_BRANCH="main"
