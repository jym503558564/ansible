#!/usr/bin/env bash
# We don't set -u here, due to pypa/virtualenv#150
set -ex
MYTMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')
trap 'rm -rf "${MYTMPDIR}"' EXIT
# This is needed for the ubuntu1604py3 tests
# Ubuntu patches virtualenv to make the default python2
# but for the python3 tests we need virtualenv to use python3
PYTHON=${ANSIBLE_TEST_PYTHON_INTERPRETER:-python}
# Test graceful failure for older versions of botocore
export ANSIBLE_ROLES_PATH=../
virtualenv --system-site-packages --python "${PYTHON}" "${MYTMPDIR}/botocore-less-than-1.10.57"
source "${MYTMPDIR}/botocore-less-than-1.10.57/bin/activate"
"${PYTHON}" -m pip install 'botocore<1.10.57' boto3
ansible-playbook -i ../../inventory -e @../../integration_config.yml -e @../../cloud-config-aws.yml -v playbooks/version_fail.yml "$@"
# Run full test suite
virtualenv --system-site-packages --python "${PYTHON}" "${MYTMPDIR}/botocore-recent"
source "${MYTMPDIR}/botocore-recent/bin/activate"
$PYTHON -m pip install 'botocore>=1.10.57' boto3
ansible-playbook -i ../../inventory -e @../../integration_config.yml -e @../../cloud-config-aws.yml -v playbooks/full_test.yml "$@"
