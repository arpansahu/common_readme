Note: agent {label 'local'} is used to specify which node will execute the jenkins job deployment. So local linux server is labelled with 'local' are the project with this label will be executed in local machine node.

* Configure a Jenkins project from jenkins ui located at https://jenkins.arpansahu.me

Make sure to use Pipeline project and name it whatever you want I have named it as per [JENKINS PROJECT NAME]

![Jenkins Pipeline Configuration](/Jenkins-deploy.png)

* Configure another Jenkins project from jenkins ui located at https://jenkins.arpansahu.me

Make sure to use Pipeline project and name it whatever you want I have named it as {project_name}_build

![Jenkins Build Pipeline Configuration](/Jenkins-build.png)

This pipeline is triggered on another branch named as build. Whenever a new commit is pushed, it checks 
if there are changes in the files other then few .md files and dependabot.yml file. If, changes are there it pushed the image.
If image is pushed successfully, email is sent to notify and then another Jenkins Pipeline [JENKINS BUILD PROJECT NAME] is called.


In this above picture you can see credentials right? you can add your github credentials and harbor
from Manage Jenkins on home Page --> Manage Credentials

and add your GitHub credentials from there

* Add a .env file to you project using following command (This step is no more required stage('Dependencies'))

    ```bash
    sudo vi  /var/lib/jenkins/workspace/[JENKINS PROJECT NAME]/.env
    ```

    Your workspace name may be different.

    Add all the env variables as required and mentioned in the Readme File.

* Add Global Jenkins Variables from Dashboard --> Manage --> Jenkins
  Configure System
 
  * MAIL_JET_API_KEY
  * MAIL_JET_API_SECRET
  * MAIL_JET_EMAIL_ADDRESS
  * MY_EMAIL_ADDRESS

Now you are good to go.