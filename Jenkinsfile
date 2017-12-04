pipeline {
  agent any
  stages {
    stage('Initial') {
      steps {
        sh 'echo "This is the first stage"'
        writeFile(file: 'testfiles', text: '${abc}')
      }
    }
  }
  environment {
    TESTENV = '1'
    BLAH = 'FOO'
  }
}