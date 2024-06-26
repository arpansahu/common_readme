import requests
import os
from include_files import include_files

# Define the main base README file and the new README file
base_readme_file = os.path.join(os.path.dirname(__file__), "baseREADME.md")
new_readme_file = os.path.join(os.path.dirname(__file__), "..", "Readme.md")

# Function to fetch content from a URL or local file
def fetch_content(file_url):
    print(f"Fetching content from: {file_url}")
    if file_url.startswith("http"):
        try:
            response = requests.get(file_url)
            response.raise_for_status()
            print(f"Successfully fetched content from: {file_url}")
            return response.text
        except requests.RequestException as e:
            print(f"Error fetching {file_url}: {e}")
            raise FileNotFoundError(f"Error fetching {file_url}: {e}")
    else:
        try:
            with open(file_url, "r") as local_file:
                print(f"Successfully read local file: {file_url}")
                return local_file.read()
        except FileNotFoundError as e:
            print(f"Error reading local file {file_url}: {e}")
            raise

# Function to recursively replace placeholders
def include_file_content(content, include_files):
    placeholders_found = True
    iteration = 0

    while placeholders_found:
        print(f"Iteration {iteration}:")
        placeholders_found = False
        for placeholder, file_url in include_files.items():
            placeholder_tag = f"[{placeholder}]"
            if placeholder_tag in content:
                placeholders_found = True
                print(f"Found placeholder: {placeholder_tag}")
                try:
                    included_content = fetch_content(file_url)
                    content = content.replace(placeholder_tag, included_content)
                except FileNotFoundError as e:
                    print(f"Stopping process due to missing file: {e}")
                    return None
        iteration += 1
    
    return content

# Check if the base README file exists
if not os.path.exists(base_readme_file):
    print(f"Error: The base README file '{base_readme_file}' does not exist.")
else:
    # Read the base README file content
    with open(base_readme_file, "r") as base_file:
        readme_content = base_file.read()

    # Replace all placeholders with their corresponding file content from GitHub or local files
    readme_content = include_file_content(readme_content, include_files)

    if readme_content is not None:
        # Write the updated content to the new README file
        with open(new_readme_file, "w") as new_file:
            new_file.write(readme_content)
        print("Readme.md has been created with the referenced content.")
    else:
        print("Process stopped due to missing file.")