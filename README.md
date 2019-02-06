# Elten Mobile
This repository contains an initial sketch of the source code of  Elten client for mobile systems (iOS, Android).
Elten is a social network designed to integrate the blind community, more details can be found on [the official website of the project](https://elten-net.eu).
The following mobile application is in the early beta test stage and is far from being distributed in AppStore, I would ask you to keep this in mind when testing it.
The wider client for Windows is in a stable stage, available in [another repository](https://github.com/dawidpieper/elten2).
## Technical details
The application is written in Ruby language, using rubymotion technology.
In principle, it will be cross-platform, although for now it is only developed for iOS.
## Requirements
* A computer with Mac OS version 10.14 installed
* Apple Developer account
* XCode developer tools
* Rubymotion software
## Dependencies
The dependency list is still in the development stage and will most likely change dynamically.
Most of them should be dealt with by the Bundler:
$ bundle install
There may occur problems with dependencies released on cocoapods, in which case you should build them manually using xCode.
## Building
After configuring the environment, to compile the application for iOS, just use rake predefined tasks
$ rake ios:archive
## To do
There is a lot, the inspiration should be the desktop client repository. 
First of all, we need to rebuild the application interface (add tabbar and fill main screen), handle profile editing, blogs, polls, extend notifications...
Not to mention writing an engine for Android.
### A call for pull requests
For all pull requests I will be very obliged, below some information about the structure of this code:
* The corresponding files are located in the "app" folder:
* "app/views" - individual screens code
* "app/internal" - EltenAPI shared functions (details: see the desktop repository)
* "app/ios" - references to the iOS API, providing audio support, window construction (expansion of the used Flow library) and so on. (Those files shall be  rewritten  for Android and put in  "app/android" folder.)
Thank you for all your contribution!
## License
The following code is distributed under Open Public License.
You are not permitted to redistribute its modified versions without the permission of its author.
You are entitled to provide patchs that the end user would be able to perform in order to modify the software, though.
No sublicensed libraries nor code are included in this repository, they're used although in the build process. They, obviously, are licensed under  their appropriate license aggreements.