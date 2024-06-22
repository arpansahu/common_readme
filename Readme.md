
# Common README Project

The `common_readme` project is designed to automate the process of updating README files across multiple repositories. This project leverages Jenkins for Continuous Integration (CI) and Continuous Deployment (CD) to ensure that all README files are consistently updated with the latest information.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project automates the process of updating README files in multiple repositories. It uses Jenkins to run a script that clones the repositories, updates their README files based on a template and additional content, and pushes the changes back to the repositories.

## Features

- **Automated README Updates**: Automatically update README files across multiple repositories.
- **Continuous Integration**: Leverage Jenkins for automated CI/CD pipelines.
- **Credential Management**: Securely handle GitHub credentials using Jenkins credentials store.
- **Conflict Handling**: Automatically pulls the latest changes to avoid conflicts during push.
- **Scalable**: Easily add or remove repositories to be updated.

## Requirements

- Jenkins server
- GitHub account with repositories to be managed
- Jenkins credentials for GitHub authentication
- Necessary permissions to push changes to the repositories

## Setup

### Jenkins Setup

1. **Install Jenkins**: Ensure Jenkins is installed and running on your server.
2. **Install Plugins**: Install the following Jenkins plugins:
   - Credentials Binding Plugin
   - Git Plugin
   - Pipeline Plugin
3. **Configure Credentials**: Add your GitHub credentials to Jenkins. Note the credentials ID for later use.

### Repository Setup

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/arpansahu/common_readme.git
   cd common_readme
   ```

2. **Make Scripts Executable**:
   ```sh
   chmod +x update_all_projects_readme.sh
   ```

### Jenkins Pipeline Configuration

1. **Create a New Pipeline Job**:
   - Go to Jenkins Dashboard
   - Click on "New Item"
   - Select "Pipeline" and enter a name for your job

2. **Configure the Pipeline**:
   - In the Pipeline section, select "Pipeline script from SCM"
   - Set the SCM to "Git"
   - Enter the repository URL: `https://github.com/arpansahu/common_readme.git`
   - Enter the credentials ID you configured earlier
   - Set the script path to `Jenkinsfile`

## Usage

1. **Run the Jenkins Pipeline**: Manually trigger the pipeline from the Jenkins dashboard to start the process.
2. **Automatic Trigger**: Configure a webhook on GitHub to automatically trigger the Jenkins pipeline on push events.

### Script Details

- **update_all_projects_readme.sh**: Main script to update README files in all specified repositories.
- **readme_manager/update_readme.sh**: This script and directory are present in every project other than `common_readme`. It clones `requirements.txt`, `readme_updater.py`, and `baseREADME.md`, activates the Python environment, installs `requirements.txt`, and runs `readme_updater.py`, which uses `baseREADME.md` to update the README file.
- **readme_updater.py**: Python script that updates the README file by combining content from various sources, both local and remote.

### Local vs Production

The `update_all_projects_readme.sh` script can be run in both local and production environments. By default, it assumes a production environment, but you can specify `local` to run without credentials:

- **Local Run**:
  ```sh
  ./update_all_projects_readme.sh local
  ```

- **Production Run** (Jenkins):
  The Jenkins pipeline will automatically pass the `prod` environment parameter.

## Contributing

Contributions are welcome! Please follow these steps to contribute:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some feature'`)
5. Push to the branch (`git push origin feature/your-feature-name`)
6. Open a Pull Request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
