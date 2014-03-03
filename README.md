Configure script
==================
by Eduardo San Martin Morote aka Posva
[http://posva.net/](http://posva.net)

posva13@gmail.com

**If you have python3 you should use this version instead: [https://github.com/posva/configure.py](https://github.com/posva/configure.py)**

Intro
-----

The main purpose of this script is to generate `Makefiles` as [CMake](http://www.cmake.org/) does but being way more simple and therefore designed for more simple projects. You should use this script for C/C++ projects but it can be adapted to almost any other language. 

The scripts checks for any `dos` file and convert it to `unix` (It changes the character used in each eol) if the option -a is used. Otherwise the script won't be able to run due to `grep` and some of the regexp. I just think that having `dos` eol is ugly and everybody should use `unix` eol.

![pic](http://i.imgur.com/Futju0p.png)

Help
----
To check the help pass the -h option to the script.

FAQ
---
Why do I get `\e[00;33` everywhere?
The bash version in /bin/bash isn't the right one, symlink a newer one (like `5.0`). Use [Homebrew](http://brew.sh/) to install it
on Mac. Linux shouldn't have any issue :)

License
-------
The script is distributed under the GNU v3 License.
