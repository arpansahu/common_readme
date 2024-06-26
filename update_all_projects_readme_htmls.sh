#!/bin/bash

# Function to set up the environment
setup_environment() {
    if [ "$ENVIRONMENT" != "local" ]; then
        # Path to the GIT_ASKPASS helper script
        GIT_ASKPASS_HELPER="$(pwd)/git-askpass.sh"

        # Create the GIT_ASKPASS helper script
        echo "Creating GIT_ASKPASS helper script"
        cat <<EOF > "$GIT_ASKPASS_HELPER"
#!/bin/sh
echo \$GIT_PASSWORD
EOF
        chmod +x "$GIT_ASKPASS_HELPER"

        # Export GIT_ASKPASS
        export GIT_ASKPASS="$GIT_ASKPASS_HELPER"
    fi
}

# List of project repositories to clone
REPOS=(
    "https://github.com/arpansahu/great_chat"
    # Add more repositories as needed
)

# Directory where the script is located
SCRIPT_DIR=$(pwd)

# Function to update README.md for each repository
update_readme() {
    local repo_url=$1
    local repo_name=$(basename -s .git "$repo_url")

    # Extract repository path from URL
    REPO_PATH="${repo_url#https://github.com/}"

    # Construct the authenticated URL for prod, plain URL for local
    if [ "$ENVIRONMENT" != "local" ]; then
        AUTHENTICATED_URL="https://${GIT_USERNAME}@github.com/${REPO_PATH}"
    else
        AUTHENTICATED_URL="https://github.com/${REPO_PATH}"
    fi

    # Log the URL being used (without exposing the password)
    echo "Using URL: $AUTHENTICATED_URL"

    # Clone the repository
    echo "Cloning repository: $AUTHENTICATED_URL"
    if git clone "$AUTHENTICATED_URL"; then
        echo "Successfully cloned repository: $repo_url"
    else
        echo "Failed to clone repository: $repo_url"
        return
    fi

    # Navigate to the repository directory
    cd "$repo_name" || { echo "Failed to navigate to repository directory: $repo_name"; return; }

    # Common readme to html script path within the project
    README_TO_HTML_SCRIPT_PATH="readme_manager_html_detailed/convert_readme_to_html.sh"

    # Run the update_readme.sh script
    if [ -f "$README_TO_HTML_SCRIPT_PATH" ]; then
        echo "Running readme to html script: $README_TO_HTML_SCRIPT_PATH"
        bash "$README_TO_HTML_SCRIPT_PATH"

        # Check if readme.html was created or updated
        if [ -f "readme_manager_html_detailed/readme.html" ]; then
            echo "inside if "
            
            local repo_arpansahu_url="https://github.com/arpansahu/arpansahu.me"
            local repo_arpansahu_name=$(basename -s .git "$repo_arpansahu_url")

            # Extract repository path from URL
            REPO_ARPANSAHU_PATH="${repo_arpansahu_url#https://github.com/}"

            # Construct the authenticated URL for prod, plain URL for local
            if [ "$ENVIRONMENT" != "local" ]; then
                AUTHENTICATED_ARPANSAHU_URL="https://${GIT_USERNAME}@github.com/${REPO_ARPANSAHU_PATH}"
            else
                AUTHENTICATED_ARPANSAHU_URL="https://github.com/${REPO_ARPANSAHU_PATH}"
            fi

            # Log the AUTHENTICATED_ARPANSAHU_URL URL being used (without exposing the password)
            echo "Using URL: $AUTHENTICATED_ARPANSAHU_URL"

            # Clone the repository
            echo "Cloning repository: $AUTHENTICATED_ARPANSAHU_URL"
            if git clone "$AUTHENTICATED_ARPANSAHU_URL"; then
                echo "Successfully cloned ARPASAHU.ME repository: $repo_arpansahu_url"
            else
                echo "Failed to clone ARPANSAHU.ME repository: $repo_arpansahu_url"
                return
            fi

            # COPY readme.html to this arpansahu.me repository (here our command line is still in the root directory of $repo_name)
            echo "COPY readme_manager_html_detailed/readme.html to this arpansahu.me repository $repo_arpansahu_name/templates/modules/project_detailed/project_partials/great_chat/"
            cp "readme_manager_html_detailed/readme.html" "$repo_arpansahu_name/templates/modules/project_detailed/project_partials/great_chat/"
            
            # Navigate to the repository directory
            cd "$repo_arpansahu_name" || { echo "Failed to navigate to repository directory: $repo_arpansahu_name"; return; }

            # Stage the README.md file
            git add templates/modules/project_detailed/project_partials/great_chat/readme.html

            echo "Checking differences for readme.html"
            git --no-pager diff --cached templates/modules/project_detailed/project_partials/great_chat/readme.html

            # Check if there are any differences between the working directory and the index
            if git diff --cached --exit-code templates/modules/project_detailed/project_partials/great_chat/readme.html; then
                echo "readme.html not changed for $repo_arpansahu_name"
            else
                # Commit and push the changes
                git commit -m "Automatic Update readme.html for $repo_arpansahu_name"
                if git push "$AUTHENTICATED_ARPANSAHU_URL"; then
                    echo "Successfully pushed changes for $repo_arpansahu_name"
                else
                    echo "Failed to push changes for $repo_arpansahu_name"
                fi
            fi
        else
            echo "readme.html not found after running update script for $repo_name"
        fi
    else
        echo "Readme to Html script not found: $README_TO_HTML_SCRIPT_PATH"
    fi

    # Navigate back to the script directory
    cd "$SCRIPT_DIR"

    # Remove the cloned repository
    rm -rf "$repo_name"
}

# Main script execution
main() {
    # Determine the environment
    ENVIRONMENT=${1:-prod}

    # Setup the environment
    setup_environment

    # Change to the directory where the script is located
    cd "$SCRIPT_DIR"

    # Determine the specific repository to update if provided, else update all
    SPECIFIC_REPO=$2

    # Iterate over the list of repositories and update the README.md for each
    for repo in "${REPOS[@]}"; do
        if [ -z "$SPECIFIC_REPO" ] || [ "$repo" == "$SPECIFIC_REPO" ]; then
            update_readme "$repo"
        fi
    done
}

# Execute the main function with provided arguments or default to prod environment and all repositories
main "$@"