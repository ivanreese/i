#!/usr/bin/env coffee

child_process = require "node:child_process"
fs = require "node:fs"
PleaseReload = require "please-reload"
{ parseArgs } = require "node:util"

# Generic Helpers

# Who needs chalk when you can just roll your own ANSI escape sequences
do ()->
  for fmt, v of red: 31, green: 32, yellow: 33, blue: 34, magenta: 35, cyan: 36
    do (fmt, v)-> global[fmt] = (t)-> "\x1b[#{v}m" + t + "\x1b[0m"

# console.log should have expression semantics
log = (...things)-> console.log ...things; things[0]

# Get nicely parsed command line options
args = (options)->
  parsed = parseArgs { args: process.argv[3..], options, strict: false }
  if options? then parsed else parsed.positionals

# Saner default for execSync
exec = (cmd, opts = {stdio: "inherit"})-> child_process.execSync cmd, opts

debounce = (time, fn)->
  timeout = null
  ()->
    clearTimeout timeout
    timeout = setTimeout fn, time

dotfiles = /(^|[\/\\])\../

# File watcher
runWatcher = (path, cmd, debounceTime = 100)->
  runActionsSoon = debounce debounceTime, ()-> exec cmd
  try fs.watch path, recursive: true, (eventType, filename)-> if filename and not dotfiles.test(filename) then runActionsSoon()
  catch error then log red "Watching #{path} failed"

# Domain Helpers / Config

help =
  help:  "Babe you're reading it"
  up:    "Update brew, npm, and i"
  serve: "Run PleaseReload at the given path (pwd by default)"
  watch: "Give a path, and all following text as a cmd"
  fps:   "Metal performance HUD — pass a truthy arg to show, falsey to hide"

version = ()-> require("./package.json").version

# Commands

commands = {}

commands.help = ()->
  log ""
  log cyan "i the cli • Version #{version()}"
  log ""
  maxNameLength = 0
  for name, description of help
    maxNameLength = Math.max name.length, maxNameLength
  for name, description of help
    log yellow " " + name.padEnd(maxNameLength + 2) + blue description
  log ""

commands.up = ()->
  log yellow "\nUpdating " + cyan "brew"
  exec "brew update"
  exec "brew upgrade"
  exec "brew cleanup"

  log yellow "\nUpdating " + cyan "npm"
  exec "npm i -g npm --silent"
  exec "npm i -g coffeescript --silent"

  log yellow "\nUpdating " + cyan "i"
  exec "npm i -g i-the-cli --silent"

  log green "i am now version:"
  exec "i version"
  log ""

commands.version = ()->
  log version()

commands.serve = ()->
  [path] = args()
  PleaseReload.serve path or "."

commands.watch = ()->
  [path, ...rest] = args()
  runWatcher path, rest.join(" ")

commands.fps = ()->
  [flag] = args()
  flag = if JSON.parse flag then 1 else 0
  exec("/bin/launchctl setenv MTL\_HUD\_ENABLED #{flag}")
  console.log "Metal Performance HUD " + if flag then "on" else "off"

# Main

command = process.argv[2] or "help"

if commands[command]
  do commands[command]
else
  log red "\n  Error: " + yellow command + red " is not a valid command."
  commands.help()
