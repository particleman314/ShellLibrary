pipeline {
  agent {
    node {
      label 'Sample'
    }
    
  }
  stages {
    stage('Initial') {
      steps {
        sh 'echo "This is the first stage"'
      }
    }
    stage('Middle') {
      steps {
        echo 'This is a simple print message'
      }
    }
    stage('Final') {
      steps {
        git(url: 'https://github.com/particleman314/ShellLibrary.git', branch: 'master', credentialsId: 'particleman314:2ndblackbelt', poll: true)
      }
    }
  }
  environment {
    TESTENV = '1'
    BLAH = 'FOO'
  }
}