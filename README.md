# r-system-requirements

[![Travis Build Status](https://travis-ci.com/rstudio/r-system-requirements.svg?token=MNvJQsCy2iwsWpHV8ezP&branch=master)](https://travis-ci.com/rstudio/r-system-requirements)
[![CircleCI Build Status](https://circleci.com/gh/rstudio/r-system-requirements.svg?style=svg&circle-token=a281bb1cf9155796c3b112a77fce743cbdbff93d)](https://circleci.com/gh/rstudio/r-system-requirements)

### Testing

To run the schema tests, you'll need [Node.js](https://nodejs.org/).

Install dependencies:

```sh
npm install
```

Lint and validate rules against the [schema](schema.json):

```sh
npm test
```

[Docker](https://www.docker.com/) images are provided to help test rules on
different OSs.

Supported tags:
- `trusty` (Ubuntu 14.04)
- `xenial` (Ubuntu 16.04)
- `bionic` (Ubuntu 18.04)
- `jessie` (Debian 8)
- `stretch` (Debian 9)
- `centos6` (CentOS 6)
- `centos7` (CentOS 7)
- `opensuse42` (OpenSUSE 42.3)

To build the images:

```sh
# Build a specific image
make build-trusty

# Build all images
make build-all
```

To test rules:

```sh
# Test a specific rule on an OS
make test-trusty RULES=rules/libcurl.json

# Test a specific rule on all OSs
make test-all RULES=rules/libcurl.json

# Test all rules on all OSs
make test-all
```