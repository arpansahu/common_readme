#!/bin/bash

# List of project repositories to clone
REPOS=(
    "https://github.com/arpansahu/great_chat"
    # Add more repositories as needed
)

# Directory where the script is located
SCRIPT_DIR=$(pwd)

# Git user configuration
GIT_USER_NAME="arpansahu"
GIT_USER_EMAIL="arpanrocks95@gmail.com"

# Function to update Readme.md for each repository
update_readme() {
    local repo_url=$1
    local repo_name=$(basename -s .git "$repo_url")
    
    # Clone the repository
    echo "Cloning repository: $repo_url"
    git clone "$repo_url"
    
    # Navigate to the repository directory
    cd "$repo_name"
    
    # Common readme update script path within the project
    UPDATE_SCRIPT_PATH="readme_manager/update_readme.sh"
    
    # Run the update_readme.sh script
    if [ -f "$UPDATE_SCRIPT_PATH" ]; then
        echo "Running update script: $UPDATE_SCRIPT_PATH"
        bash "$UPDATE_SCRIPT_PATH"
        
        # Check if Readme.md was created or updated
        if [ -f "Readme.md" ]; then
            if git diff --exit-code Readme.md; then
                echo "Readme.md not changed for $repo_name"
            else
                # Commit and push the changes
                git config user.name "$GIT_USER_NAME"
                git config user.email "$GIT_USER_EMAIL"
                git add Readme.md
                git commit -m "Update Readme.md"
                git push origin main
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
    # Change to the directory where the script is located
    cd "$SCRIPT_DIR"
    
    # Iterate over the list of repositories and update the Readme.md for each
    for repo in "${REPOS[@]}"; do
        update_readme "$repo"
    done
}

# Execute the main function
main