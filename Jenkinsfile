pipeline {
  agent any
  stages {
    stage('Initial') {
      steps {
        sh '''echo "This is the first stage"

find . -type f -name "test*.sh" > "${OUTPUTFILE}"

cat "${OUTPUTFILE}"'''
      }
    }
  }
  environment {
    TESTENV = '1'
    OUPUTFILE = 'trial.list'
  }
}