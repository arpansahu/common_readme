#!/bin/bash

# Source the repository list
source repos_list.sh

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

# Directory where the script is located
SCRIPT_DIR=$(pwd)

# Function to check if wiki repository exists
check_wiki_exists() {
    local repo_url=$1
    local repo_wiki_url="${repo_url%.git}.wiki.git"

    if git ls-remote "$repo_wiki_url" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to update Home.md for each repository
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
    
    # Check if readme.html was created or updated
    if [ -f "readme_manager/partials/introduction.md" ]; then
        echo "inside if "
        
        local repo_wiki_url="${repo_url%.git}.wiki.git"
        local repo_wiki_name=$(basename -s .git "$repo_wiki_url")

        # Check if the wiki exists
        if ! check_wiki_exists "$repo_url"; then
            echo "Wiki repository does not exist for $repo_name. Please initialize the wiki using the GitHub UI."
            cd "$SCRIPT_DIR"
            rm -rf "$repo_name"
            return
        fi

        # Extract repository path from URL
        REPO_WIKI_PATH="${repo_wiki_url#https://github.com/}"

        # Construct the authenticated URL for prod, plain URL for local
        if [ "$ENVIRONMENT" != "local" ]; then
            AUTHENTICATED_WIKI_URL="https://${GIT_USERNAME}@github.com/${REPO_WIKI_PATH}"
        else
            AUTHENTICATED_WIKI_URL="https://github.com/${REPO_WIKI_PATH}"
        fi

        # Log the AUTHENTICATED_WIKI_URL URL being used (without exposing the password)
        echo "Using URL: $AUTHENTICATED_WIKI_URL"

        # Clone the repository
        echo "Cloning repository: $AUTHENTICATED_WIKI_URL"
        if git clone "$AUTHENTICATED_WIKI_URL"; then
            echo "Successfully cloned WIKI FOR repository: $repo_wiki_url"
        else
            echo "Failed to clone WIKI repository: $repo_wiki_url"
            return
        fi

        # Copy the file and echo the action
        echo "COPY readme_manager/partials/introduction_main.md to this wiki repository $repo_wiki_name/Home.md"
        cp "readme_manager/partials/introduction_main.md" "$repo_wiki_name/Home.md"
        
        # Navigate to the repository directory
        cd "$repo_wiki_name" || { echo "Failed to navigate to repository directory: $repo_wiki_name"; return; }

        # Stage the Home.md file
        git add Home.md

        echo "Checking differences for Home.md"
        git --no-pager diff --cached Home.md


        # Check if there are any differences between the working directory and the index
        if git diff --cached --exit-code Home.md; then
            echo "Home.md not changed for $repo_wiki_name"
        else
            # Commit and push the changes
            git commit -m "Automatic Update Home.md for $repo_wiki_name"
            if git push "$AUTHENTICATED_WIKI_URL"; then
                echo "Successfully pushed changes for $repo_wiki_name"
            else
                echo "Failed to push changes for $repo_wiki_name"
            fi
        fi
        ls
    else
        echo "Home.md not found after running update script for $repo_name"
    fi
    
    # Navigate back to the script directory
    cd "$SCRIPT_DIR"

    # Remove the cloned repository
    echo "Cleaning up ..."
    rm -rf "$repo_name"
    rm -rf "$repo_wiki_name"
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

    # Iterate over the list of repositories and update the Home.md for each
    for repo in "${REPOS[@]}"; do
        if [ -z "$SPECIFIC_REPO" ] || [ "$repo" == "$SPECIFIC_REPO" ]; then
            update_readme "$repo"
        fi
    done
}

# Execute the main function with provided arguments or default to prod environment and all repositories
main "$@"