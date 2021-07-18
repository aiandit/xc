pipeline {
  parameters {
    string(name: 'host',         defaultValue: "pc1", description: 'Hostname')
    string(name: 'user',         defaultValue: "developer",   description: 'Username')
    string(name: 'depldir',      defaultValue: "/opt/ai-and-it", description: 'Install directory')
    string(name: 'repo',         defaultValue: "dev-host:git/xc", description: 'XC Repo')
  }

  agent {
    label "linux"
  }

  stages {

    stage('get-version') {
	steps {
            sh 'ls -l'
            sh 'whoami; hostname; env|sort'
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
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"whoami\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"ping -c 1 famserv.local\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"ssh -vvv joy@famserv.local ls -lA\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"cd $params.depldir && git clone $params.repo\""
	    }
	}
    }

    stage('deploy') {
        steps {
	    sshagent (credentials: ['dev-key']) {
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"cd $params.depldir/xc && sudo ./ci/prepare-system.sh\""
		sh "ssh -o StrictHostKeyChecking=no ${params.user}@${params.host} \"cd $params.depldir/xc && sudo ./ci/config-system.sh ${params.host}\""
            }
	}
    }

  }
}
