pipeline {
    agent { label 'local' }
    environment {
        CREDS = credentials('a8543f6d-1f32-4a4c-bb31-d7fffe78828e')
    }
    stages {
        stage('Verify Credentials') {
            steps {
                script {
                    // Print the credentials to verify they are being set correctly
                    echo "GIT_USERNAME: ${CREDS_USR}"
                    echo "GIT_PASSWORD: ${CREDS_PSW}"
                    
                    // Save credentials to a file for use in the script
                    sh """
                    echo "GIT_USERNAME=${CREDS_USR}" > credentials.env
                    echo "GIT_PASSWORD=${CREDS_PSW}" >> credentials.env
                    cat credentials.env
                    """
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
                                "HTMLPart": "<h3>Hola Development Team, your project ${currentBuild.fullDisplayName} is not deployed, Build Failed </h3> < br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
    }
}