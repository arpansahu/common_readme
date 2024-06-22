pipeline {
    agent { label 'local' }
    stages {
        stage('Update READMEs') {
            steps {
                script {
                    sh "chmod +x update_all_projects_readme.sh"
                    sh "./update_all_projects_readme.sh"
                }
            }
        }
    }
    post {
        success {
            sh """curl -s \
            -X POST \
            --user ${env.MAIL_JET_API_KEY}:${env.MAIL_JET_API_SECRET} \
            https://api.mailjet.com/v3.1/send \
            -H "Content-Type:application/json" \
            -d '{
                "Messages":[
                        {
                                "From": {
                                        "Email": "${env.MAIL_JET_EMAIL_ADDRESS}",
                                        "Name": "ArpanSahuOne Jenkins Notification"
                                },
                                "To": [
                                        {
                                                "Email": "${env.MY_EMAIL_ADDRESS}",
                                                "Name": "Development Team"
                                        }
                                ],
                                "Subject": "${env.currentBuild.fullDisplayName} deployed successfully",
                                "TextPart": "Hola Development Team, your project ${env.currentBuild.fullDisplayName} is now deployed",
                                "HTMLPart": "<h3>Hola Development Team, your project ${env.currentBuild.fullDisplayName} is now deployed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
        failure {
            sh """curl -s \
            -X POST \
            --user ${env.MAIL_JET_API_KEY}:${env.MAIL_JET_API_SECRET} \
            https://api.mailjet.com/v3.1/send \
            -H "Content-Type:application/json" \
            -d '{
                "Messages":[
                        {
                                "From": {
                                        "Email": "${env.MAIL_JET_EMAIL_ADDRESS}",
                                        "Name": "ArpanSahuOne Jenkins Notification"
                                },
                                "To": [
                                        {
                                                "Email": "${env.MY_EMAIL_ADDRESS}",
                                                "Name": "Development Team"
                                        }
                                ],
                                "Subject": "${env.currentBuild.fullDisplayName} deployment failed",
                                "TextPart": "Hola Development Team, your project ${env.currentBuild.fullDisplayName} deployment failed",
                                "HTMLPart": "<h3>Hola Development Team, your project ${env.currentBuild.fullDisplayName} is not deployed, Build Failed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
    }
}