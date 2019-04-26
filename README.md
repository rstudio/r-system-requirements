# System Requirements for R Packages

[![Travis Build Status](https://travis-ci.com/rstudio/r-system-requirements.svg?token=MNvJQsCy2iwsWpHV8ezP&branch=master)](https://travis-ci.com/rstudio/r-system-requirements)
[![CircleCI Build Status](https://circleci.com/gh/rstudio/r-system-requirements.svg?style=svg&circle-token=a281bb1cf9155796c3b112a77fce743cbdbff93d)](https://circleci.com/gh/rstudio/r-system-requirements)

R packages can depend on one another, but they can also depend on software
external to the R ecosystem. On Ubuntu 18.04, for example, in order to install
the `curl` R package, you must have previously run `apt-get install libcurl`. R
packages often note these dependencies inside their DESCRIPTION files, but this
information is free-form text that varies by package. 

This repository contains a catalog of "rules" that can be used to systematically
identify these dependencies and generate programmatic commands to install them.

You may be expecting to see a list like:

| package | Requirements Field | Dependency |
| ------  | ----------- | ----- | 
| rgdal   | "for building from source: GDAL >= ..." | libgdal-dev |


Storing this information as a table in this format is not efficient. Many R
packages do not have any system dependencies, so the table would be vert
sparse. Moreover, R packages are added at an exponential rate, so maintaining
this data would be nearly impossible.

Instead, this repository contains a set of rules that map a
`SystemRequirements` field, e.g. `rgdal`'s "for building from source: GDAL >=
1.11.4 and <= 2.5.0, library from ..." to a platform specific install command:
`apt-get install libgdal-dev gdal-bin libproj-dev`.
 

## Usage 

The primary purpose of this catalog is to support [RStudio Package
Manager](https://rstudio.com/products/package-manager) which knows how to
translate these rules into install steps for specific packages or
repositiories. However, the community is free to use and contribute to these
rules subject to the MIT license. 

RStudio Package Manager is professionally supported, but RStudio does not offer
support for these rules. Please file questions in [RStudio
Community](https://community.rstudio.com) or open an issue in this repository.

A similar project is maintained by [R-Hub](https://github.com/r-hub/sysreqsdb).
The primary difference between the two catalogs is in the data format and the
test coverage.

## Test Coverage

The rules presented in this repository are extensively tested with the following process:

1. A Docker container is started with a minimal [base R image](https://github.com/rstudio/r-docker).
2. A target R package is identified. The catalog of rules is applied to install any known requirements
for the package into the Docker container.
3. The package is installed.

If the package install is successful, there is a high chance the existing rules
are sufficient. If the install fails, there is an indication that a rule is
missing. This process is repeated for all CRAN packages across 6 Linux
distributions: Ubuntu 16/18, CentOS 6/7, openSUSE 42/15.  

The results are summarized below:

*Percentage of CRAN Packages that Install Successfully*

| | Ubuntu 16 | Ubuntu 18 |  CentOS 6 |  CentOS 7 |  openSUSE 42.3 |  openSUSE 15.0 | 
| --- | ---   | --------  | --------  | --------- | -------------- | -------------- |
| No Rules| 78% | 78.1% | 77.4% | 77.8% | 77.7% | 78.2% |
| With Rules | 93.5% | 95.8% | 91.9% | 93.7% | 88.5% | 89.7% | 


*Percentage Weighted by Downloads*

This table contains similar results as the table above, but adjusted by
download. This metric indicates how good the rules are for the majority of
packages R users are likely to install, discounting the long tail of packages
that have system requirements but are not frequently used.

| | Ubuntu 16 | Ubuntu 18 |  CentOS 6 |  CentOS 7 |  openSUSE 42.3 |  openSUSE 15.0 | 
| --- | ---   | --------  | --------  | --------- | -------------- | -------------- |
| No Rules| 90.1% | 90.1% | 90% | 90.1% | 90% | 90.2% | 
| With Rules | 98.5% | 99.2% | 98.1% | 98.6% | 96.1% | 96.3% | 

Both tests run with R 3.5.2 for all CRAN packages as of April 4, 2019.

---

# For Developers

We welcome contributions to this catalog, please open a pull request.

### Schema

The JSON schema is defined in the file `schema.json`. Do not modify this file directly,
since it is automatically generated. Instead, modify `schema.template.json` and then run
`npm run generate-schema`. The `generate-schema` target is automatically run when running
`npm test`.

If you need to modify the distros and/or versions supported in the schema definitions, 
modify `generate-schema.js`.

### Testing

#### Schema tests

To lint and validate rules against the schema, you'll need [Node.js](https://nodejs.org/).

```sh
# Install dependencies
npm install

# Run the tests
npm test
```

To list R packages and system requirements matched by a rule:

```sh
# List matching system requirements for a rule
npm run test-patterns -- rules/libcurl.json --verbose

# List matching system requirements for all rules
npm run test-patterns-all -- --verbose

# Fail if a rule doesn't match any system requirements
npm run test-patterns-all -- --strict
```

#### System package tests

[Docker](https://www.docker.com/) images are provided to help validate system
packages on supported OSs.

Available tags:
- `trusty` (Ubuntu 14.04)
- `xenial` (Ubuntu 16.04)
- `bionic` (Ubuntu 18.04)
- `jessie` (Debian 8)
- `stretch` (Debian 9)
- `centos6` (CentOS 6)
- `centos7` (CentOS 7)
- `opensuse42` (openSUSE 42.3)
- `opensuse15` (openSUSE 15.0)

To build the images:

```sh
# Build a specific image (e.g. trusty)
make build-trusty

# Build all images
make build-all
```

To test the rules:

```sh
# Test a specific rule on an OS (e.g. trusty)
make test-trusty RULES=rules/libcurl.json

# Test a specific rule on all OSs
make test-all RULES=rules/libcurl.json

# Test all rules on all OSs
make test-all
```
