#!/usr/bin/env bash

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}

function tmpdir() {
	mktemp -d -t nnny-test-XXXXXX
}

function verify_node() {
	expected_version="v$1"
	actual_version=$(node --version)

	if [ ${expected_version} != ${actual_version} ]; then
		echo "Expected npm version to be ${expected_version}, but was ${actual_version}"
		exit 1
	fi
}

function verify_yarn() {
	expected_version=$1

	if [ ${expected_version} == "none" ]; then
		if type yarn 2> /dev/null; then
			echo "Expected yarn to not be installed, but it was"
			exit 1
		fi
	else
		actual_version=$(yarn --version)

		if [ ${expected_version} != ${actual_version} ]; then
			echo "Expected yarn version to be ${expected_version}, but was ${actual_version}"
			exit 1
		fi
	fi
}

function verify_npm() {
	expected_version=$1
	actual_version=$(npm --version)

	if [ ${expected_version} != ${actual_version} ]; then
		echo "Expected npm version to be ${expected_version}, but was ${actual_version}"
		exit 1
	fi
}

function run_nnny() {
	(
		curl -so- https://raw.githubusercontent.com/MeLlamoPablo/nnny/master/nnny.sh | bash
	) > /dev/null
}

function cleanup() {
	rm -rf /usr/bin/node \
		/usr/bin/npm \
		/usr/bin/yarn \
		/usr/bin/npx \
		/usr/bin/nnny
}

pushd $(tmpdir)
	printf "nnny should install node and yarn, and update npm..."

	cat > package.json <<- EOF
	{
		"engines": {
			"node": "8.11.0",
			"yarn": "1.5.1",
			"npm": "5.7.1"
		}
	}
	EOF

	run_nnny

	verify_node 8.11.0
	verify_yarn 1.5.1
	verify_npm 5.7.1

	printf "\rnnny should install node and yarn, and update npm... Pass\n"
popd

cleanup

pushd $(tmpdir)
	printf "nnny should install only node..."

	cat > package.json <<- EOF
	{
		"engines": {
			"node": "8.11.0"
		}
	}
	EOF

	run_nnny

	verify_node 8.11.0
	verify_npm 5.6.0 # Bundled with node
	verify_yarn none

	printf "\rshould install only node... Pass\n"
popd

echo ""
echo "All tests passed successfully!"
