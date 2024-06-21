import requests

# Define the main base README file and the new README file
base_readme_file = "baseREADME.md"
new_readme_file = "Readme.md"

# Define a dictionary with the placeholders and their corresponding GitHub raw URLs
include_files = {
    "README of Docker Installation": "https://raw.githubusercontent.com/arpansahu/common_readme/main/Docker%20Readme/docker_installation.md",
    "README of Nginx Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/nginx.md",
    "README of Jenkins Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/Jenkins/Jenkins.md",
    "JENKINS_END": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/Jenkins/jenkins_end.md",
    "README of PostgreSql Server With Nginx Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/Postgres.md",
    "README of PGAdmin4 Server With Nginx Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/PostgresUI.md",
    "README of Portainer Server With Nginx Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/Portainer.md",
    "README of Redis Server Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/Redis.md",
    "README of Redis Commander Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/RedisComander.md",
    "README of Minio Server Setup": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/Minio.md",
    "README of Intro": "https://raw.githubusercontent.com/arpansahu/common_readme/main/AWS%20Deployment/Intro.md",
    "env.example": "https://raw.githubusercontent.com/arpansahu/great_chat/main/env.example",
    "docker-compose.yml": "https://raw.githubusercontent.com/arpansahu/great_chat/main/docker-compose.yml",
    "Dockerfile": "https://raw.githubusercontent.com/arpansahu/great_chat/main/Dockerfile",
    "Jenkinsfile": "https://raw.githubusercontent.com/arpansahu/great_chat/main/Jenkinsfile",
    "AWS DEPLOYMENT INTRODUCTION": "https://github.com/arpansahu/common_readme/blob/main/Introduction/aws_desployment_introduction.md",
    "STATIC_FILES": "https://github.com/arpansahu/common_readme/blob/main/Introduction/static_files_settings.md",
    "INTRODUCTION": "/readme_manager/partials/introduction.md",
    "DOC_AND_STACK": "readme_manager/partials/documentation_and_stack.md",
    "TECHNOLOGY QNA": "readme_manager/partials/technology_qna.md",
    "DEMO": "readme_manager/partials/demo.md",
    "INSTALLATION": "readme_manager/partials/installation.md",
    "DJANGO_COMMANDS": "readme_manager/partials/django_commands.md",
    "NGINX_SERVER": "readme_manager/partials/nginx_server.md",

}

# Read the base README file content
with open(base_readme_file, "r") as base_file:
    readme_content = base_file.read()

# Function to replace placeholders with actual file content from GitHub
def include_file_content_from_github(content, placeholder, file_url):
    try:
        response = requests.get(file_url)
        response.raise_for_status()
        included_content = response.text
        return content.replace(f"[{placeholder}]", included_content)
    except requests.RequestException as e:
        print(f"Error fetching {file_url}: {e}")
        return content

# Replace all placeholders with their corresponding file content from GitHub
for placeholder, file_url in include_files.items():
    readme_content = include_file_content_from_github(readme_content, placeholder, file_url)

# Write the updated content to the new README file
with open(new_readme_file, "w") as new_file:
    new_file.write(readme_content)

print("README.md has been created with the referenced content.")