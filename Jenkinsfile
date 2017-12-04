pipeline {
  agent any
  stages {
    stage('DirCreation') {
      steps {
        pwd(tmp: true)
        dir(path: './sampleDirectory') {
          sh '''pwd
echo "I\'m inside"'''
        }
        
      }
    }
  }
  environment {
    TESTENV = '1'
    OUPUTFILE = 'trial.list'
  }
}