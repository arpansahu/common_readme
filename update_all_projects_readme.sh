#!/bin/bash

# Function to set up the environment
setup_environment() {
    if [ "$ENVIRONMENT" != "local" ]; then
        # Path to the GIT_ASKPASS helper script
        GIT_ASKPASS_HELPER="$(pwd)/git-askpass.sh"

        # Create the GIT_ASKPASS helper script
        echo "Creating GIT_ASKPASS helper script"
        echo '#!/bin/sh' > "$GIT_ASKPASS_HELPER"
        echo 'echo $GIT_PASSWORD' >> "$GIT_ASKPASS_HELPER"
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

# Function to update Readme.md for each repository
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

    # Common readme update script path within the project
    UPDATE_SCRIPT_PATH="readme_manager/update_readme.sh"

    # Run the update_readme.sh script
    if [ -f "$UPDATE_SCRIPT_PATH" ]; then
        echo "Running update script: $UPDATE_SCRIPT_PATH"
        bash "$UPDATE_SCRIPT_PATH"

        # Check if Readme.md was created or updated
        if [ -f "Readme.md" ]; then
            # Pull the latest changes from the remote repository
            git pull --rebase

            # Stage the Readme.md file
            git add Readme.md

            # Print the difference detected
            echo "Checking differences for Readme.md"
            git diff --cached Readme.md

            # Check if there are any differences between the working directory and the index
            if git diff --cached --exit-code Readme.md; then
                echo "Readme.md not changed for $repo_name"
            else
                # Commit and push the changes
                git commit -m "Update Readme.md"
                if git push "$AUTHENTICATED_URL"; then
                    echo "Successfully pushed changes for $repo_name"
                else
                    echo "Failed to push changes for $repo_name"
                fi
            fi
        else
            echo "Readme.md not found after running update script for $repo_name"
        fi
    else
        echo "Update script not found: $UPDATE_SCRIPT_PATH"
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

    # Iterate over the list of repositories and update the Readme.md for each
    for repo in "${REPOS[@]}"; do
        if [ -z "$SPECIFIC_REPO" ] || [ "$repo" == "$SPECIFIC_REPO" ]; then
            update_readme "$repo"
        fi
    done
}

# Execute the main function with provided arguments or default to prod environment and all repositories
main "$@"