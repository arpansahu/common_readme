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
    "https://github.com/arpansahu/arpansahu_dot_me"
    # Add more repositories as needed
)

# Directory where the script is located
SCRIPT_DIR=$(pwd)

# Function to update README.md for each repository
process_repo() {
    local repo_url=$1
    local repo_name=$(basename -s .git "$repo_url")

    # Remove the repository directory if it already exists
    if [ -d "$repo_name" ]; then
        echo "Removing existing repository directory: $repo_name"
        rm -rf "$repo_name"
    fi

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
            # Copy readme.html to the script directory for later use
            cp "readme_manager_html_detailed/readme.html" "$SCRIPT_DIR/readme_${repo_name}.html"
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

# Function to update arpansahu_dot_me repository with all readme.html files
update_arpansahu_repo() {
    local repo_arpansahu_url="https://github.com/arpansahu/arpansahu_dot_me"
    local repo_arpansahu_name=$(basename -s .git "$repo_arpansahu_url")

    # Remove the arpansahu_dot_me repository directory if it already exists
    if [ -d "$repo_arpansahu_name" ]; then
        echo "Removing existing repository directory: $repo_arpansahu_name"
        rm -rf "$repo_arpansahu_name"
    fi

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
        echo "Failed to clone arpansahu_dot_me repository: $repo_arpansahu_url"
        return
    fi

    # Navigate to the repository directory
    cd "$repo_arpansahu_name" || { echo "Failed to navigate to repository directory: $repo_arpansahu_name"; return; }

    # Copy all collected readme.html files to the appropriate location
    for readme_file in "$SCRIPT_DIR"/readme_*.html; do
        repo_name=$(basename "$readme_file" .html | sed 's/^readme_//')
        echo "Copying $readme_file to $repo_arpansahu_name/templates/modules/project_detailed/project_partials/$repo_name/readme.html"
        mkdir -p "templates/modules/project_detailed/project_partials/$repo_name"
        cp "$readme_file" "templates/modules/project_detailed/project_partials/$repo_name/readme.html"
    done

    # Stage all changes
    git add templates/modules/project_detailed/project_partials/*/readme.html

    echo "Checking differences for readme.html files"
    git --no-pager diff --cached

    # Check if there are any differences between the working directory and the index
    if git diff --cached --exit-code; then
        echo "No changes to commit for $repo_arpansahu_name"
    else
        # Commit and push the changes
        git commit -m "Automatic Update readme.html for all repositories"
        if git push "$AUTHENTICATED_ARPANSAHU_URL"; then
            echo "Successfully pushed changes for $repo_arpansahu_name"
        else
            echo "Failed to push changes for $repo_arpansahu_name"
        fi
    fi

    # Navigate back to the script directory
    cd "$SCRIPT_DIR"

    # Remove the cloned arpansahu_dot_me repository
    rm -rf "$repo_arpansahu_name"
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

    # Iterate over the list of repositories and process each one
    for repo in "${REPOS[@]}"; do
        if [ -z "$SPECIFIC_REPO" ] || [ "$repo" == "$SPECIFIC_REPO" ]; then
            process_repo "$repo"
        fi
    done

    # Update the arpansahu_dot_me repository with all collected readme.html files
    update_arpansahu_repo

    # Clean up temporary readme.html files
    rm -f "$SCRIPT_DIR"/readme_*.html
}

# Execute the main function with provided arguments or default to prod environment and all repositories
main "$@"