pipeline {
  agent any
  stages {
    stage('Initial') {
      steps {
        sh 'echo "This is the first stage"'
      }
    }
  }
  environment {
    TESTENV = '1'
    BLAH = 'FOO'
  }
}