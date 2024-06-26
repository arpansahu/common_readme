Each repository contains an `update_readme.sh` script located in the `readme_manager` directory. This script is responsible for updating the README file in the repository by pulling in content from various sources.

### What it Does

The `update_readme.sh` script performs the following actions:

1. **Clone Required Files**: Clones the `requirements.txt`, `readme_updater.py`, and `baseREADME.md` files from the `common_readme` repository.
2. **Set Up Python Environment**: Creates and activates a Python virtual environment.
3. **Install Dependencies**: Installs the necessary dependencies listed in `requirements.txt`.
4. **Run Update Script**: Executes the `readme_updater.py` script to update the README file using `baseREADME.md` and other specified sources.
5. **Clean Up**: Deactivates the Python virtual environment and removes it.

### How to Use

To run the `update_readme.sh` script, navigate to the `readme_manager` directory and execute the script:

```bash
cd readme_manager && ./update_readme.sh
```

This will update the `README.md` file in the root of the repository with the latest content from the specified sources.

### Updating Content

If you need to make changes that are specific to the project or project-specific files, you might need to update the content of the partial README files. Here are the files that are included:

- **Project-Specific Files**: 
  - `env.example`
  - `docker-compose.yml`
  - `Dockerfile`
  - `Jenkinsfile`

- **Project-Specific Partial Files**:
  - `INTRODUCTION`: `../readme_manager/partials/introduction.md`
  - `DOC_AND_STACK`: `../readme_manager/partials/documentation_and_stack.md`
  - `TECHNOLOGY QNA`: `../readme_manager/partials/technology_qna.md`
  - `DEMO`: `../readme_manager/partials/demo.md`
  - `INSTALLATION`: `../readme_manager/partials/installation.md`
  - `DJANGO_COMMANDS`: `../readme_manager/partials/django_commands.md`
  - `NGINX_SERVER`: `../readme_manager/partials/nginx_server.md`

These files are specific to the project and should be updated within the project repository.

- **Common Files**:
  - All other files are common across projects and should be updated in the `common_readme` repository.

There are a few files which are common for all projects. For convenience, these are inside the `common_readme` repository so that if changes are made, they will be updated in all the projects' README files.

```python
[INCLUDE FILES]
```

Also, remember if you want to include new files, you need to change the `baseREADME` file and the `include_files` array in the `common_readme` repository itself.