Configure script
==================
by Eduardo San Martin Morote aka Posva
[http://posva.net/](http://posva.net)

posva13@gmail.com

This script generate a Makefile with the right dependencies for each file that need to be compiled. It also checks for any dos file and convert it to unix if the option -a is used.
![pic](http://i.imgur.com/Futju0p.png)

Help
------------
To check the help pass the -h option to the script.

FAQ
---
Why do I get `\e[00;33` everywhere?
The bash version in /bin/bash isn't the right one, symlink a newer one (like `5.0`). Use [Homebrew](http://brew.sh/) to install it
on Mac. Linux shouldn't have any issue :)

License
-----
The script is distributed under the GNU v3 License.
