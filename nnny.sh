#!/usr/bin/env bash

target_dir="/usr/bin/nnny"
tmp_dir=$(mktemp -d -t nnny-XXXXXX)

function error() {
	>&2 echo "$@"
	cleanup
	exit 1
}

function cleanup() {
	rm -rf ${tmp_dir}
}

function pushd () {
    command pushd "$@" > /dev/null
}

function popd () {
    command popd "$@" > /dev/null
}

if [ $(whoami) != "root" ]; then
	error "You need to run nnny as root!"
fi

if [ ! -e ./package.json ]; then
	error "You need to run nnny on the same directory as your package.json!"
fi

type curl > /dev/null 2>&1 || {
	error "You need curl to use nnny!"
}

type jq > /dev/null 2>&1 || {
	pushd ${tmp_dir}
		curl -sOL "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" || {
			error "jq not found, and can't be installed temporarily"
		}
		mv jq-linux64 jq
        chmod +x jq
		PATH="$PATH:$(pwd)"
	popd
}

package_json=$(< ./package.json)

node_version=$(echo ${package_json} | jq -r .engines.node)
npm_version=$(echo ${package_json} | jq -r .engines.npm)
yarn_version=$(echo ${package_json} | jq -r .engines.yarn)

# Blatantly stolen from:
# https://github.com/creationix/nvm/blob/d8689f6b9aabcb2ac92691bd088eaf60a24e377a/nvm.sh#L1593
case "$(uname -m)" in
	x86_64 | amd64) arch="x64" ;;
	i*86) arch="x86" ;;
	aarch64) arch="arm64" ;;
esac

function install_node() {
	NODE_BASE_URL="https://nodejs.org/dist"

	version_name="node-v${node_version}-linux-${arch}"
	file_name="${version_name}.tar.gz"
	url="${NODE_BASE_URL}/v${node_version}/${file_name}"
	node_target_dir="${target_dir}/${version_name}"

	pushd ${tmp_dir}
		curl -s -O ${url} || {
			error "The node v${npm_version} installation failed!"
		}

		tar -xf ${file_name}
		mv ${version_name} ${target_dir}

		ln -s "${node_target_dir}/bin/node" /usr/bin/node
		ln -s "${node_target_dir}/bin/npm" /usr/bin/npm
		ln -s "${node_target_dir}/bin/npx" /usr/bin/npx
	popd

	echo "Installed node v${node_version}"
}

function install_yarn() {
	YARN_BASE_URL="https://api.github.com/repos/yarnpkg/yarn/releases/tags"
	api_url="${YARN_BASE_URL}/v${yarn_version}"
	file_name="yarn-${yarn_version}.js"

	response=$(curl -s ${api_url})

	if [ $(echo ${response} | jq -r .message) == "Not Found" ]; then
		error "The Yarn version ${yarn_version} doesn't exist!" || (
			error "The Yarn v${yarn_version} installation failed!"
		)
	fi

	url=$(echo ${response} | \
		jq -r ".assets[]  | select(.name == "'"'"${file_name}"'"'") | .browser_download_url")

	pushd ${tmp_dir}
		curl -sOL ${url}
		mv ${file_name} /usr/bin/yarn
		chmod +x /usr/bin/yarn
	popd

	echo "Installed yarn v${yarn_version}"
}

function install_npm() {
	npm install -g "npm@${npm_version}" > /dev/null || (
		error "The npm@${npm_version} installation failed!"
	)
	echo "Installed npm v${npm_version}"
}

mkdir -p ${target_dir}

if [ ${node_version} == "null" ]; then
	error "You must specify a node version in your package.json, in the engines object!"
fi

install_node

if [ ${yarn_version} != "null" ]; then
	install_yarn
fi

if [ ${npm_version} != "null" ]; then
	install_npm
fi

cleanup