# Changelog

## 7.0.3

* Fix issue where server.json would always be overwritten
* Ensure custom trayIcons are not overwritten by the default

## 7.0.2

* Fix issue where declared extensions dependencies with no min/max version always overwrite previously installed versions (even if a lower version)

## 7.0.1

* Fix issue where dependencies installed in ways other then box.json would be overwritten when marked as a dependency of another extension. Causing issues with the wrong versions of software being installed.

## 7.0.0

Rewrite of core commands to bring up to date with latest changes and approaches from Commandbox. We now use cfconfig
for `preside server start` and have resolved the issues with datasource prompts overlapping Commandbox text

## 6.1.6

* Fix for broken paths in Gruntfile generated for new extension command when choosing to manage static assets with grunt

## 6.1.5

* Fix for issue where version number of package not read for dependencies stored in S3 with release version number in their filename

## 6.1.4

* Update the datasource definition in lucee web admin to include a db driver ([Pull requestion](https://github.com/pixl8/Preside-CMS-CommandBox-Commands/pull/16))

## 6.1.3

* Update to forgebox api calls for correctly fetching preside skeletons for the `preside new site` command

## 6.1.2

* Add ability for other packages to do programatic installs and skip the preside package compatibility checking

## 6.1.1

* When doing version compatibility checks, ignore snapshot part of version strings. i.e. 4.3.0-SNAPSHOT4598 should just be treated as 4.3.0

## 6.1.0

* Add ability for Preside extensions to expression compatibility issues with other extensions.

## 6.0.1-3

* Build fixes

## 6.0.0

* A whole new version of `preside new extension` that includes scaffolds for tests and Github actions flow for publishing to forgebox.

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
