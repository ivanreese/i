#!/usr/bin/env coffee

child_process = require "node:child_process"
fs = require "node:fs"
PleaseReload = require "please-reload"
{ parseArgs } = require "node:util"

# Generic Helpers

# Who needs chalk when you can just roll your own ANSI escape sequences
do ()->
  fmts =
    bold: 1, dim: 2, italic: 3, underline: 4, overline: 53, inverse: 7, strike: 9,
    black: 30, red: 31, green: 32, yellow: 33, blue: 34, magenta: 35, cyan: 36, white: 37,
    blackBright: 90, grey: 90, redBright: 91, greenBright: 92, yellowBright: 93, blueBright: 94, magentaBright: 95, cyanBright: 96, whiteBright: 97,
    bgBlack: 40, bgRed: 41, bgGreen: 42, bgYellow: 43, bgBlue: 44, bgMagenta: 45, bgCyan: 46, bgWhite: 47,
    bgBlackBright: 100, bgGrey: 100, bgRedBright: 101, bgGreenBright: 102, bgYellowBright: 103, bgBlueBright: 104, bgMagentaBright: 105, bgCyanBright: 106, bgWhiteBright: 107
  for fmt, v of fmts
    do (fmt, v)-> global[fmt] = (t)-> "\x1b[#{v}m" + t + "\x1b[0m"

# Pad the start and end of a string to a target length
padAround = (str, len = 80, char = " ")->
  str.padStart(Math.ceil(len/2 + str.length/2), char).padEnd(len, char)

# Wrap a string to the a desired character length
# https://stackoverflow.com/a/51506718/313576
linewrap = (s, len = 80, sep = "\n")-> s.replace new RegExp("(?![^\\n]{1,#{len}}$)([^\\n]{1,#{len}})\\s", "g"), "$1#{sep}"

# Prepend a string with a newline. Useful when logging.
br = (m)-> "\n" + m

# Indent a string using a given line prefix
indent = (str, prefix = "  ")-> prefix + str.replaceAll "\n", "\n" + prefix

# Surround a string with another string
surround = (inner, outer = " ")-> outer + inner + outer

# Generate a nice divider, optionally with text in the middle
divider = (s = "")-> br padAround(s, 80, "─") + "\n"

# console.log should have expression semantics
log = (...things)-> console.log ...things; things[0]

# Get nicely parsed command line options
args = (options)->
  parsed = parseArgs { args: process.argv[3..], options, strict: false }
  if options? then parsed else parsed.positionals

# Saner default for execSync
exec = (cmd, opts = {stdio: "inherit"})-> child_process.execSync cmd, opts

# Little sugary filesystem helpers
exists = (filePath)-> fs.existsSync filePath
readdir = (filePath)-> fs.readdirSync(filePath).filter (i)-> i isnt ".DS_Store"
mkdir = (filePath)-> fs.mkdirSync filePath, recursive: true
rm = (filePath)-> if exists filePath then fs.rmSync filePath, recursive: true
isDir = (filePath)-> fs.statSync(filePath).isDirectory()
read = (filePath)-> if exists filePath then fs.readFileSync(filePath).toString()

# Domain Helpers / Config

help =
  help:   "Babe you're reading it"
  update: "Update brew, npm, and i"
  serve:  "Runs PleaseReload in the current dir"
  fps:    "Metal performance HUD — pass a truthy arg to show, falsey to hide"

version = ()-> require("./package.json").version

# Commands

commands = {}

commands.help = ()->
  log ""
  log cyan "  i cli • Version #{version()}"
  maxNameLength = 0
  for name, description of help
    maxNameLength = Math.max name.length, maxNameLength
  for name, description of help
    log yellow "    " + name.padEnd(maxNameLength + 2) + blue description
  log ""

commands.update = ()->
  log yellow "\nUpdating " + cyan "brew"
  exec "brew update"
  exec "brew upgrade"
  exec "brew cleanup"

  log yellow "\nUpdating " + cyan "npm"
  exec "npm i -g npm --silent"
  exec "npm i -g coffeescript --silent"

  log yellow "\nUpdating " + cyan "i"
  exec "npm i -g i-cli --silent"

  log green "i am now version:"
  exec "i version"
  log ""

commands.version = ()->
  log version()

commands.serve = ()->
  PleaseReload.serve "."

commands.fps = ()->
  [flag] = args()
  flag = if flag then 1 else 0
  exec("/bin/launchctl setenv MTL\_HUD\_ENABLED #{flag}")
  console.log "Metal Performance HUD " + if flag then "on" else "off"

# Main

command = process.argv[2] or "help"

if commands[command]
  do commands[command]
else
  log red "\n  Error: " + yellow command + red " is not a valid command."
  commands.help()
