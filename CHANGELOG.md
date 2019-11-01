# Changelog

## 5.0.3

* Allow `preside start` to be run in non-interactive shell with `preside start interactive=false`

## 5.0.1

* Ensure extension mapping is useful when compiling extension sources. e.g. /extension-name
* Ensure that CFConfig is installed before attempting extension compile command

## 5.0.0

* Add 'preside extension compile' command

## 4.0.0

* Add dependency fulfillment and checking between preside extensions in box install
* Add Preside min/max version checking for extension installs

## 2.1.8 > 3.0.2

* Refactor package to be a CommandBox module

## 2.1.0 > 2.1.8

* Remove whitespace reduction setting from the Lucee web config. This stops the preside commands from failing to format tables properly (e.g. with `cache stats` command).

## 2.0.4 > 2.1.0

* Add new webapp skeleton for creating non-cms based web applications on Preside
* Added a post install concept for skeletons

## 0.6.0 > 2.0.4

* Updated skeleton for `preside new site` command to use forgebox packages (in readiness for multiple skeleton options and simplifying the build process)
* Use a hires icon for `preside start` servers on Linux machines (now that we will have working AppIndicators in Linux with CommandBox)
* Do not prompt to download preside when we find preside already located in the webroot of the project when running `preside start` for the first time
