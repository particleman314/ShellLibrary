pipeline {
  agent any
  stages {
    stage('Initial') {
      steps {
        sh '''echo "This is the first stage"

OUTPUTFILE = \'trial.list\'

find . -type f -name "test*.sh" > ${OUTPUTFILE}'''
      }
    }
  }
  environment {
    TESTENV = '1'
    BLAH = 'FOO'
  }
}