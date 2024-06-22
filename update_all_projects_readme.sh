#!/bin/bash

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
    
    # Construct the authenticated URL
    AUTHENTICATED_URL="https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${REPO_PATH}"

    # Log the URL being used (without exposing the password)
    echo "Using URL: $AUTHENTICATED_URL"

    # Check if we can access the repository
    echo "Checking access to repository: $repo_url"
    if curl -u "${GIT_USERNAME}:${GIT_PASSWORD}" -o /dev/null -sIf "https://github.com/${REPO_PATH}"; then
        echo "Successfully authenticated to repository: $repo_url"
    else
        echo "Failed to authenticate to repository: $repo_url"
        return
    fi

    # Clone the repository using Jenkins credentials
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
            # Stage the Readme.md file
            git add Readme.md
            
            # Check if there are any differences between the working directory and the index
            if git diff --cached --exit-code Readme.md; then
                echo "Readme.md not changed for $repo_name"
            else
                # Commit and push the changes using Jenkins credentials
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
    # Change to the directory where the script is located
    cd "$SCRIPT_DIR"
    
    # Iterate over the list of repositories and update the Readme.md for each
    for repo in "${REPOS[@]}"; do
        update_readme "$repo"
    done
}

# Execute the main function
main