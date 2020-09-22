pipeline {
  parameters {
    string(name: 'host',         defaultValue: "raspberrypi", description: 'Hostname')
    string(name: 'user',         defaultValue: "pi",          description: 'Username')
    string(name: 'depldir',      defaultValue: "/opt/ai-and-it", description: 'Install directory')
    string(name: 'repo',         defaultValue: "https://github.com/aiandit/xc.git", description: 'XC Repo')
  }

  agent any

  stages {
    stage('get-version') {
      steps {
        sh 'ls -l'
	sshagent (credentials: ['wj-pc']) {
           sh 'ssh-add -l -E md5'
	}
      }
    }

    stage('info') {
        steps {
	    sshagent (credentials: ['wj-pc']) {
		sh "ssh ${params.user}@${params.host} \"whoami\""
		sh "ssh ${params.user}@${params.host} \"groups\""
		sh "ssh ${params.user}@${params.host} \"env\""
		sh "ssh ${params.user}@${params.host} \"ls -l\""
		sh "ssh ${params.user}@${params.host} \"hostname\""
            }
	}
    }

    stage('checkout') {
        steps {
	    sshagent (credentials: ['wj-pc']) {
		sh "ssh ${params.user}@${params.host} \"sudo mkdir -p $params.depldir\""
		sh "ssh ${params.user}@${params.host} \"sudo chown -R $params.user $params.depldir\""
		sh "ssh ${params.user}@${params.host} \"$params.depldir && git clone $params.repo\""
	    }
	}
    }

    stage('deploy') {
        steps {
	    sshagent (credentials: ['wj-pc']) {
		sh "ssh ${params.user}@${params.host} \"$params.depldir/xc && ./ci/prepare-system.sh\""
            }
	}
    }

  }
}
