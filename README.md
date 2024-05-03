# System Requirements for R Packages

[![CI Status](https://github.com/rstudio/r-system-requirements/actions/workflows/ci.yml/badge.svg)](https://github.com/rstudio/r-system-requirements/actions/workflows/ci.yml)

R packages can depend on one another, but they can also depend on software
external to the R ecosystem. On Ubuntu 18.04, for example, in order to install
the `curl` R package, you must have previously run `apt-get install libcurl`. R
packages often note these dependencies inside their DESCRIPTION files, but this
information is free-form text that varies by package. 

This repository contains a catalog of "rules" that can be used to systematically
identify these dependencies and generate commands to install them.

You may be expecting to see a list like:

| Package | SystemRequirements Field | Dependency |
| ------  | ----------- | ----- | 
| rgdal   | "for building from source: GDAL >= ..." | libgdal-dev |


Storing this information as a table in this format is not efficient. Many R
packages do not have any system dependencies, so the table would be very
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
The two catalogs have different data formats, test coverage, and target
different operating systems.

## Rule Coverage

The rules presented in this repository are extensively tested with the following process:

1. A Docker container is started with a minimal [base R image](https://github.com/rstudio/r-docker).
2. A target R package is identified. The catalog of rules is applied to install any known requirements
for the package into the Docker container.
3. The package is installed.

If the package install is successful, there is a high chance the existing rules
are sufficient. If the install fails, there is an indication that a rule is
missing. This process is repeated for all CRAN packages across 6 Linux
distributions: Ubuntu 16/18, CentOS 7/8, openSUSE 42/15.

The results are summarized below:

*Percentage of CRAN Packages that Install Successfully*

| | Ubuntu 16 | Ubuntu 18 |  CentOS 7 | CentOS 8 |  openSUSE 42.3 |  openSUSE 15.0 | 
| --- | ---   | -------- | --------- | -------- | -------------- | -------------- |
| No Rules| 78% | 78.1% | 77.8% | | 77.7% | 78.2% |
| With Rules | 93.5% | 95.8% | 93.7% | | 88.5% | 89.7% | 


*Percentage Weighted by Downloads*

This table contains similar results as the table above, but adjusted by
download. This metric indicates how good the rules are for the majority of
packages R users are likely to install, discounting the long tail of packages
that have system requirements but are not frequently used.

| | Ubuntu 16 | Ubuntu 18 |  CentOS 7 | CentOS 8 |  openSUSE 42.3 |  openSUSE 15.0 | 
| --- | ---   | --------  | --------  | -------- | -------------- | -------------- |
| No Rules| 90.1% | 90.1% | 90.1% | | 90% | 90.2% | 
| With Rules | 98.5% | 99.2% | 98.6% | | 96.1% | 96.3% | 

Both tests run with R 3.5.3 for all CRAN packages as of April 4, 2019.

## Operating Systems

The rules in this catalog support the following operating systems:

- Ubuntu 20.04, 22.04, 24.04
- CentOS 7
- Rocky Linux 8*, 9
- Red Hat Enterprise Linux 7, 8, 9
- openSUSE 15.5
- SUSE Linux Enterprise 15 SP5
- Debian 10, 11, 12, unstable
- Fedora 36, 37, 38, 39
- Windows (for R 4.0+ only)

\* Rocky Linux 8 is specified as `centos8` for backward compatibility.
CentOS 8 reached end of support on December 31, 2021.

---

## For Developers

We welcome contributions to this catalog! To report a bug or request a rule,
please open an issue in this repository. To add or update a rule, fork this
repository and submit a pull request.

### Overview

Each system requirement rule is described by a JSON file in the [`rules`](rules)
directory. The file is named <code><i>rule-name</i>.json</code>, where
*`rule-name`* is typically the name of the system dependency.

For example, here's an excerpt from a rule for the Protocol Buffers (protobuf)
library at [`rules/libprotobuf.json`](rules/libprotobuf.json).

```js
{
  "patterns": ["\\blibprotobuf\\b"],  // regex which matches "libprotobuf" or "LIBPROTOBUF; libxml2"
  "dependencies": [
    {
      "packages": ["protobuf-devel"],  // to install the package: "yum install protobuf-devel"
      "pre_install": [
        {
          "command": "yum install -y epel-release"  // add the EPEL repository before installing
        }
      ],
      "constraints": [
        {
          "os": "linux",
          "distribution": "centos",  // make these instructions specific to CentOS 7
          "versions": ["7"]
        }
      ]
    }
  ]
}
```

Other examples:
- Simple rule: [git.json](rules/git.json)
- OS version constraints (package names vary by OS version): [libmysqlclient.json](rules/libmysqlclient.json)
- Pre-install steps (adding the EPEL repo on CentOS/RHEL): [gdal.json](rules/gdal.json)
- Post-install steps (reconfiguring R for Java): [java.json](rules/java.json)

### JSON Fields

```js
{
  "patterns": [...],
  "dependencies": [
    {
      "packages": [...],
      "constraints": [
        {
          "os": ...,
          "distribution": ...,
          "versions": [...]
        }
      ],
      "pre_install": [
        {
          "command": ...,
          "script": ...
        }
      ],
      "post_install": [
        {
          "command": ...,
          "script": ...
        }
      ]
    }
  ]
}
```

#### Top-level fields

| Field | Type | Description |
| ----- | ---- | ----------- |
| `patterns` | Array | Regular expressions to match `SystemRequirements` fields. Case-insensitive. Note that the escape character must be escaped itself (`\\.` to match a dot). Use word boundaries (`\\b`) for more accurate matches.<br/>Example: `["\\bgnu make\\b", "\\bgmake\\b"]` to match `GNU Make` or `gmake; OpenSSL` |
| `dependencies` | Array | Rules for installing the dependency on one or more operating systems. See [dependencies](#dependencies). |

#### Dependencies

| Field | Type | Description |
| ----- | ---- | ----------- |
| `packages` | Array | Packages installed through the default system package manager (e.g. apt, yum, zypper). Examples: `["libxml2-dev"]`, `["tcl", "tk"]` |
| `constraints` | Array | One or more operating system constraints. See [constraints](#constraints). |
| `pre_install` | Array | Optional commands or scripts to run before installing packages (e.g. adding a third-party repository). See [pre/post-install actions](#prepost-install-actions).
| `post_install` | Array | Optional commands or scripts to run after installing packages (e.g. cleaning up). See [pre/post-install actions](#prepost-install-actions).

#### Constraints

| Field | Type | Description |
| ----- | ---- | ----------- |
| `os` | String | Operating system. Only `"linux"` is supported for now. |
| `distribution` | String | Linux distribution. One of `"ubuntu"`, `"debian"`, `"centos"`, `"redhat"`, `"opensuse"`, `"sle"`, `"fedora"` |
| `versions` | Array | Optional set of OS versions. If unspecified, the rule applies to all supported versions. See [`systems.json`](systems.json) for supported values by OS. Example: `["18.04"]` for Ubuntu. |

#### Pre/post-install actions

Pre-install and post-install actions can be specified as either a `command` or
`script`. Commands are preferred unless there's complicated logic involved.

| Field | Type | Description |
| ----- | ---- | ----------- |
| `command` | String | A shell command. Example: `"yum install -y epel-release"` |
| `script` | String | A shell script found in the [`scripts`](scripts) directory. Example: `"centos_epel.sh"` |

### Adding a rule

A typical workflow for adding a new rule:

1. Come up with regular expressions to match all R packages with the system
   dependency. See [`sysreqs.json`](test/sysreqs.json) for a sample list of
   CRAN packages and their `SystemRequirements` fields.
   Note that the applicable R packages don't have to be on CRAN; they can be on
   GitHub or other repositories, such as Bioconductor and rOpenSci.
2. Determine the system packages and any pre/post-install steps if needed.
   The more operating systems covered, the better, but it's fine if only some
   operating systems are covered.

   Useful resources for finding packages across different OSs:
   - https://pkgs.org
   - https://repology.org

   Or to search for packages on each OS:
   ```sh
   # Ubuntu/Debian
   apt-cache search <package-name>

   # CentOS/RHEL/Fedora
   yum search <package-name>

   # openSUSE/SLE
   zypper search <package-name>
   ```
3. Add the new rule as a <code><i>rule-name</i>.json</code> file in the `rules` directory.
4. Run the schema tests and (optionally) the system package tests locally.
5. Submit a pull request.

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

To update the list of R packages and system requirements used for testing, run:

```sh
make update-sysreqs
```

#### System package tests

[Docker](https://www.docker.com/) images are provided to help validate system
packages on supported OSs.

Available tags:
- `focal` (Ubuntu 20.04)
- `jammy` (Ubuntu 22.04)
- `noble` (Ubuntu 24.04)
- `buster` (Debian 10)
- `bullseye` (Debian 11)
- `bookworm` (Debian 12)
- `sid` (Debian unstable)
- `centos7` (CentOS 7)
- `centos8` (Rocky Linux 8)
- `rockylinux9` (Rocky Linux 9)
- `opensuse155` (openSUSE 15.5)
- `fedora36` (Fedora 36)
- `fedora37` (Fedora 37)
- `fedora38` (Fedora 38)
- `fedora39` (Fedora 39)

To build the images:

```sh
# Build a specific image (e.g. focal)
make build-focal

# Build all images
make build-all
```

To test the rules:

```sh
# Test a specific rule on an OS (e.g. focal)
make test-focal RULES=rules/libcurl.json

# Test a specific rule on all OSs
make test-all RULES=rules/libcurl.json

# Test all rules on all OSs
make test-all
```

### Schema

The JSON schema is defined in the file [`schema.json`](schema.json). Do not
modify this file directly, since it is automatically generated. Instead, modify
`schema.template.json` and then run `npm run generate-schema`. The
`generate-schema` target is automatically run when running `npm test`.

If you need to modify the distros and/or versions supported in the schema definitions, 
modify [`systems.json`](systems.json).
