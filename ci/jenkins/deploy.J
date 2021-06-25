pipeline {
  parameters {
    string(name: 'host',         defaultValue: "pc1", description: 'Hostname')
    string(name: 'user',         defaultValue: "developer",   description: 'Username')
    string(name: 'depldir',      defaultValue: "/opt/ai-and-it", description: 'Install directory')
    string(name: 'repo',         defaultValue: "dev-host:git/xc", description: 'XC Repo')
    string(name: 'branch',       defaultValue: "master", description: 'XC Repo Branch')
  }

  agent {
    label "linux"
  }

  stages {

    stage('get-version') {
	steps {
            sh 'ls -l'
	    sshagent (credentials: ['dev-key']) {
		sh 'ssh-add -l -E md5'
	    }
	}
    }

    stage('info') {
        steps {
	    sshagent (credentials: ['dev-key']) {
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"whoami\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"groups\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"env\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"ls -l\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"hostname\""
            }
	}
    }

    stage('checkout') {
        steps {
	    sshagent (credentials: ['dev-key']) {
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} " +
                   " \"sudo mkdir -p $params.depldir\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"sudo chown -R $params.user $params.depldir\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"cd $params.depldir && rm -rf xc\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"cd $params.depldir && git clone -b $params.branch $params.repo xc\""
	    }
	}
    }

    stage('deploy') {
        steps {
	    sshagent (credentials: ['dev-key']) {
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"cd $params.depldir/xc && sudo ./ci/prepare-system.sh\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"cd $params.depldir/xc && sudo ./ci/config-system.sh\""
            }
	}
    }

  }
}
