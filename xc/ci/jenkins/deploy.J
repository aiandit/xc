pipeline {
  parameters {
    string(name: 'host',         defaultValue: "famserv", description: '')
    string(name: 'depldir',      defaultValue: "/opt/ai-and-it", description: '')
  }
  agent {
    label "${params.host}"
  }
  stages {
    stage('get-version') {
      steps {
        sh 'ls -l'
      }
    }

    stage('info') {
        steps {
            sh 'whoami'
            sh 'groups'
            sh 'ls -l /usr/local'
            sh 'env | sort'
            sh 'pwd'
        }
    }

    stage('checkout') {
        steps {
            sh "mkdir -p $params.depldir"
            dir("$params.depldir") {
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/master']],
                          doGenerateSubmoduleConfigurations: false,
                          extensions: [
                              [$class: 'CleanBeforeCheckout'],
                              [$class: 'RelativeTargetDirectory', relativeTargetDir: 'xc']
                          ],
                          submoduleCfg: [],
                          userRemoteConfigs: [[credentialsId: 'joy-fs', url: 'famserv:git/xc']]])
                sh 'ls -l'
            }
            dir("$params.depldir/xc/xc") {
                script {
                    env.VERSION = readFile 'ci/VERSION'
                    env.BUILD = sh label: 'Test', returnStdout: true, script: './ci/get-build-number.sh'
                }
                sh 'echo VERSION=$VERSION BUILD=$BUILD'
            }
        }
    }

    stage('deploy') {
        steps {
            dir("$params.depldir/xc/xc") {
                sh './ci/prepare-system.sh'
                sh './ci/config-system.sh'
            }
        }
    }

  }
}
