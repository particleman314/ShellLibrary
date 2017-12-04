pipeline {
  agent any
  stages {
    stage('Initial') {
      steps {
        sh 'echo "This is the first stage"'
      }
    }
    stage('Looking for Tests') {
      steps {
        sh '''abc = $( find . -type f -name "test*.sh" )
printf "%s\\n" ${abc}
'''
      }
    }
  }
  environment {
    TESTENV = '1'
    BLAH = 'FOO'
  }
}