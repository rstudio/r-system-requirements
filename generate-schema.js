let fs = require('fs')

// The template for each distribution. Typically, you should not need to modify this.
const system_template = function(os, name, distros) {
    return {
        "properties": {
            "os": {"const": os},
            "distribution": {
                "enum": distros,
            },
            "version": {
                "type": "array",
                "items": {
                    "type": "object",
                    "minLength": 1,
                    "properties": {
                        "operator": {
                            "enum": [ "==", "<", ">", "<=", ">=", "!=" ]
                        },
                        "value": {
                            "$ref": `#/definitions/versions/${name}`
                        },
                    },
                    "required": [ "value" ],
                    "additionalProperties": false
                },
            }
        },
        "required": ["os"],
        "additionalProperties": false
    }
}

// Define the supported operating systems, distributions, and versions in
// `systems.json`. Typically, this should be the only thing you modify when
// adding an OS, distribution, and/or version.
//
// Read in the systems list
const systemsText = fs.readFileSync('systems.json')
const systems = JSON.parse(systemsText)

// Read in the template and parse it. This will become the schema.
const template = fs.readFileSync('schema.template.json')
const schema = JSON.parse(template)

// Define a variable to hold the definitions that we'll insert in the schema.
const defs = {
    versions: {}
}

// Create the definitions.
for (let i=0; i < systems.length; i++) {
    const system = systems[i]
    let versionsEnum = []
    for (let i=0; i < system.versions.length; i++) {
        const ver = system.versions[i]
        versionsEnum = versionsEnum.concat(ver)
    }

    // Each distribution needs a version definition...
    defs.versions[system.name] = {
        enum: versionsEnum
    }

    // ...and also a definition named after the distribution.
    defs[system.name] = system_template('linux', system.name, system.distros)
}

// Insert the definitions in the schema and write it to disk.
schema.definitions = defs
fs.writeFileSync("schema.json", JSON.stringify(schema, null, 2))
