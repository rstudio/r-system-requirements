let fs = require('fs')

// Define the supported operating systems, distributions, and versions here.
// Typically, this should be the only thing you modify when adding an OS,
// distribution, and/or version.
const distros = [
    {
        "name": "debian",
        "distros": [ "debian" ],
        "versions": [ "stretch", "buster" ]
    },
    {
        "name": "ubuntu",
        "distros": [ "ubuntu" ],
        "versions": [ "xenial", "bionic" ]
    },
    {
        "name": "centos",
        "distros": [ "centos", "redhat" ],
        "versions": [ "6", "7" ]
    },
    {
        "name": "opensuse",
        "distros": [ "opensuse" ],
        "versions": [ "42", "15" ]
    },
    {
        "name": "sle",
        "distros": [ "sle" ],
        "versions": [ "12", "15" ]
    }
]

// The template for each distribution. Typically, you should not need to modify this.
const distro_template = function(os, name, distros) {
    return {
        "properties": {
            "os": {"const": os},
            "distribution": {
                "enum": distros,
            },
            "version": {
                "type": "object",
                "properties": {
                    "exactly": {
                        "$ref": `#/definitions/versions/${name}`
                    },
                    "range": {
                        "type": "object",
                        "properties": {
                            "at_least": {
                                "$ref": `#/definitions/versions/${name}`
                            },
                            "at_most": {
                                "$ref": `#/definitions/versions/${name}`
                            }
                        },
                        "required": ["at_least", "at_most"],
                        "additionalProperties": false
                    }
                },
                "oneOf": [
                    {
                        "required": ["exactly"]
                    },
                    {
                        "required": ["range"]
                    }
                ],
                "additionalProperties": false
            }
        },
        "required": ["os"],
        "additionalProperties": false
    }
}

// Read in the template and parse it. This will become the schema.
const template = fs.readFileSync('schema.template.json')
const schema = JSON.parse(template)

// Define a variable to hold the definitions that we'll insert in the schema.
const defs = {
    versions: {}
}

// Create the definitions.
for (let i=0; i < distros.length; i++) {
    const distro = distros[i]
    let distroEnum = []
    for (let i=0; i < distro.versions.length; i++) {
        const ver = distro.versions[i]
        distroEnum = distroEnum.concat(ver)
    }

    // Each distribution needs a version definition...
    defs.versions[distro.name] = {
        enum: distroEnum
    }

    // ...and also a definition named after the distribution.
    defs[distro.name] = distro_template('linux', distro.name, distro.distros)
}

// Insert the definitions in the schema and write it to disk.
schema.definitions = defs
fs.writeFileSync("schema.json", JSON.stringify(schema, null, 2))
