import requests
import os
from include_files import include_files

# Define the main base README file and the new README file
base_readme_file = "baseREADME.md"
new_readme_file = "newReadme.md"

# Read the base README file content
with open(base_readme_file, "r") as base_file:
    readme_content = base_file.read()

# Function to fetch content from a URL or local file
def fetch_content(file_url):
    if file_url.startswith("http"):
        try:
            response = requests.get(file_url)
            response.raise_for_status()
            return response.text
        except requests.RequestException as e:
            print(f"Error fetching {file_url}: {e}")
            return ""
    else:
        try:
            with open(file_url, "r") as local_file:
                return local_file.read()
        except FileNotFoundError as e:
            print(f"Error reading {file_url}: {e}")
            return ""

# Function to recursively replace placeholders
def include_file_content(content, include_files):
    placeholders_found = True

    while placeholders_found:
        placeholders_found = False
        for placeholder, file_url in include_files.items():
            placeholder_tag = f"[{placeholder}]"
            if placeholder_tag in content:
                placeholders_found = True
                included_content = fetch_content(file_url)
                content = content.replace(placeholder_tag, included_content)
    
    return content

# Replace all placeholders with their corresponding file content from GitHub or local files
readme_content = include_file_content(readme_content, include_files)

# Write the updated content to the new README file
with open(new_readme_file, "w") as new_file:
    new_file.write(readme_content)

print("Readme.md has been created with the referenced content.")