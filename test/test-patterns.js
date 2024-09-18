const fs = require('fs')
const path = require('path')

let args = process.argv.slice(2)

let verbose = false
let strict = false
args = args.filter(arg => {
  if (arg === '-v' || arg === '--verbose') {
    verbose = true
    return false
  }
  if (arg === '-s' || arg === '--strict') {
    strict = true
    return false
  }
  return true
})

const rules = args.map(file => {
  const contents = fs.readFileSync(file)
  return JSON.parse(contents)
})

const SYSREQS_FILE = path.resolve(__dirname, 'sysreqs.json')
const sysreqs = JSON.parse(fs.readFileSync(SYSREQS_FILE))

rules.forEach(rule => {
  rule.patterns.forEach(pattern => {
    // Test for syntax errors, like invalid escape sequences, using Unicode-aware mode.
    // RegExp otherwise does not perform some of these syntax checks.
    new RegExp(pattern, 'u')

    const regexp = new RegExp(pattern, 'i')
    const matched = sysreqs.filter(s => s.SystemRequirements.match(regexp))
    console.log('pattern:', JSON.stringify(pattern))
    console.log('matched:', matched.length)
    if (strict && matched.length === 0) {
      throw new Error(`no system requirements matched for pattern ${JSON.stringify(pattern)}`)
    }
    if (verbose) {
      console.log(JSON.stringify(matched, null, 2), '\n')
    }
  })
})
