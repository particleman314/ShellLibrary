#!/usr/bin/env bash

sample_upload_file='test_artifactory.sh'

artifact_upload
assert_failure $?

artifact_upload --filename "${sample_upload_file}"
assert_failure $?

artifact_upload --filename "${sample_upload_file}" --groupid 'test' --artifactid 'shell' --versionid '0.05'
assert_failure $?

set_artifactory_server --value 'build.dev.fco'
set_artifactory_port --value '80'
set_artifactory_server_path --value 'artifactory'
set_artifactory_repository --value 'libs-snapshot-bci-local'

artifact_upload --filename "${sample_upload_file}" --groupid 'test' --artifactid 'shell' --versionid '0.05'
assert_failure $?

set_artifactory_user --value 'klumi01'
encpass="$( encode_passwd 'QMigraine1' )"
set_artifactory_password --value "${encpass}"

artifact_upload --filename "${sample_upload_file}" --groupid 'test' --artifactid 'shell' --versionid '0.05'
assert_success $?

artifact_upload --filename "${sample_upload_file}" --groupid 'test' --artifactid 'shell' --versionid '0.05' --add-version-to-name
assert_success $?
