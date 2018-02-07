#!/usr/bin/env bash

artifact_download
assert_failure $?

artifact_download --groupid 'test' --artifactid 'shell' --versionid '0.05' --extension '.sh'
assert_failure $?

set_artifactory_server --value 'build.dev.fco'
set_artifactory_port --value '80'
set_artifactory_server_path --value 'artifactory'
set_artifactory_repository --value 'libs-snapshot-bci-local'

artifact_download --groupid 'test' --artifactid 'shell' --versionid '0.05' --extension '.sh'
assert_failure $?

set_artifactory_user --value 'klumi01'
encpass="$( encode_passwd 'QMigraine1' )"
set_artifactory_password --value "${encpass}"

artifact_download --filename "${SUBSYSTEM_TEMPORARY_DIR}/test_download.sh" --groupid 'test' --artifactid 'shell' --versionid '0.05' --extension '.sh'
assert_success $?

