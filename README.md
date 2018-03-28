# nnny

> An opinionated tool to install node.js, npm, npx and yarn in build scripts.

`nnny` is an opinionated tool that provides an extremely simple way to install
`node.js`, `npm`, `npx`, and `yarn` within your build scripts.

## How simple?

Just `cd` into your Node app's directory, and run:

```shell
$ curl -so- https://raw.githubusercontent.com/MeLlamoPablo/nnny/v1.0.0/nnny.sh | sudo bash
```

## In what ways is it opinionated?

In order to keep `nnny` ultra simple, it must follow some opinions, which will
make it useless for some use cases. Those opinions are:

* `nnny` is only intended to be used in build scripts (Dockerfiles to build
[Docker](https://www.docker.com/) images, Vagrantfiles to build
[Vagrant](https://www.vagrantup.com/) VMs, or just good ol' shell scripts to
build [AWS AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)s).

	`nnny`'s installs are immutable, which means that it doesn't provide updates.
Instead, to update, you need to rebuild the whole image. This renders `nnny`
useless for day to day use, for which you should use other tools like
[nvm](https://github.com/creationix/nvm).
* `nnny` will extract your `node`, `npm` and `yarn` versions from your
[engines](https://docs.npmjs.com/files/package.json#engines) field in
`package.json` (`npx`'s version depends on `npm`'s). There's no other way to
specify the desired versions.

	As you would have guessed, `nnny` is meant to do a deterministic per-project
install. If you have multiple projects (e.g: one
[Express](https://expressjs.com/) app for the backend and one
[React](https://reactjs.org/) app for the frontend), consider having separate
containers/images/VMs of each.

	For instance, one good use case would be to have a Docker container to
perform the production build of the React app, which then will send the built
images to a second Docker container that will host the backend (which serves
the frontend).
* `nnny` doesn't support [SemVer](https://semver.org/). You must always provide
the exact version numbers that you need.

	The NPM ecosystem is highly controversial because of poor (in my opinion,
and in many others') management of the dependency structure. There are many
cases (left-pad, request, npm v5.7.0...) that demonstrate that the whole
ecosystem is a mess.

	`nnny`'s purpose is to provide deterministic builds. In order to achieve so,
it must always install the exact same version. This obviously comes with the
drawback that you must watch out for security bugs and update your versions in
the case of such an event.
* `nnny` is only tested on `Ubuntu 18.04`, although it should run just fine on
other Linux systems. `nnny` will probably not work on OSX, and it absolutely
will not work on Windows.
* `nnny` will place `node`, `npm`, `npx` and `yarn` in `/usr/bin/`. There is
no way to specify the destination path.

## How to test

In order to test `nnny`, just execute the `test.sh` file (preferably inside a
container and not in your main system).

This repository contains a Dockerfile to make running the tests easy:

```shell
$ git clone https://github.com/MeLlamoPablo/nnny.git
$ cd nnny
$ docker build -t nnny .
$ docker run -i nnny /nnny/test.sh
```