#!/bin/bash
# generate_job_xml.sh - Generate Jenkins job XML configuration

generate_build_job_xml() {
    local job_name=$1
    local repo_url=$2
    local branch=${3:-main}
    local jenkinsfile_path=${4:-Jenkinsfile-build}
    
    cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1436.vfa_244484591f">
  <actions/>
  <description>Build pipeline for ${job_name} - Builds Docker images and pushes to Harbor registry</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.37.3.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3983.vb_b_c3d3c8c7d">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.5.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${repo_url}</url>
          <credentialsId>github_auth</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/${branch}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>${jenkinsfile_path}</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
}

generate_deploy_job_xml() {
    local job_name=$1
    local repo_url=$2
    local branch=${3:-main}
    local jenkinsfile_path=${4:-Jenkinsfile-deploy}
    local build_job_name="${job_name}_build"
    
    cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1436.vfa_244484591f">
  <actions/>
  <description>Deployment pipeline for ${job_name} - Deploys application from Harbor registry. Automatically triggered after successful build.</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <jenkins.triggers.ReverseBuildTrigger>
          <spec></spec>
          <upstreamProjects>${build_job_name}</upstreamProjects>
          <threshold>
            <name>SUCCESS</name>
            <ordinal>0</ordinal>
            <color>BLUE</color>
            <completeBuild>true</completeBuild>
          </threshold>
        </jenkins.triggers.ReverseBuildTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3983.vb_b_c3d3c8c7d">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.5.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${repo_url}</url>
          <credentialsId>github_auth</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/${branch}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>${jenkinsfile_path}</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
}

generate_readme_job_xml() {
    local job_name=$1
    local repo_url=$2
    local branch=${3:-main}
    
    cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1436.vfa_244484591f">
  <actions/>
  <description>Common README Management Pipeline - Updates README files across all projects</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>project_git_url</name>
          <description>Project name to process</description>
          <defaultValue></defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>environment</name>
          <description>Environment to run the script in</description>
          <defaultValue>prod</defaultValue>
          <trim>false</trim>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.37.3.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3983.vb_b_c3d3c8c7d">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.5.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${repo_url}</url>
          <credentialsId>github_auth</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/${branch}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
}

# Export functions
export -f generate_build_job_xml
export -f generate_deploy_job_xml
export -f generate_readme_job_xml
