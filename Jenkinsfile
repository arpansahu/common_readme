pipeline {
    agent { label 'local' }
    stages {
        stage('Update READMEs') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'a8543f6d-1f32-4a4c-bb31-d7fffe78828e', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                        sh 'git config --global user.name "arpansahu"'
                        sh 'git config --global user.email "arpanrocks95@gmail.com"'
                        sh 'chmod +x update_all_projects_readme.sh'
                        sh './update_all_projects_readme.sh'
                    }
                }
            }
        }
    }
    post {
        success {
            sh """curl -s \
            -X POST \
            --user ${MAIL_JET_API_KEY}:${MAIL_JET_API_SECRET} \
            https://api.mailjet.com/v3.1/send \
            -H "Content-Type:application/json" \
            -d '{
                "Messages":[
                        {
                                "From": {
                                        "Email": "${MAIL_JET_EMAIL_ADDRESS}",
                                        "Name": "ArpanSahuOne Jenkins Notification"
                                },
                                "To": [
                                        {
                                                "Email": "${MY_EMAIL_ADDRESS}",
                                                "Name": "Development Team"
                                        }
                                ],
                                "Subject": "${currentBuild.fullDisplayName} deployed successfully",
                                "TextPart": "Hola Development Team, your project ${currentBuild.fullDisplayName} is now deployed",
                                "HTMLPart": "<h3>Hola Development Team, your project ${currentBuild.fullDisplayName} is now deployed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
        failure {
            sh """curl -s \
            -X POST \
            --user ${MAIL_JET_API_KEY}:${MAIL_JET_API_SECRET} \
            https://api.mailjet.com/v3.1/send \
            -H "Content-Type:application/json" \
            -d '{
                "Messages":[
                        {
                                "From": {
                                        "Email": "${MAIL_JET_EMAIL_ADDRESS}",
                                        "Name": "ArpanSahuOne Jenkins Notification"
                                },
                                "To": [
                                        {
                                                "Email": "${MY_EMAIL_ADDRESS}",
                                                "Name": "Developer Team"
                                        }
                                ],
                                "Subject": "${currentBuild.fullDisplayName} deployment failed",
                                "TextPart": "Hola Development Team, your project ${currentBuild.fullDisplayName} deployment failed",
                                "HTMLPart": "<h3>Hola Development Team, your project ${currentBuild.fullDisplayName} is not deployed, Build Failed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
    }
}