Configure script
==================
by Eduardo San Martin Morote aka Posva
[http://posva.net/](http://posva.net)

posva13@gmail.com

This script generate a Makefile with the right dependencies for each file that need to be compiled. It also checks for any dos file and convert it to unix if the option -a is used.
![pic](http://i.imgur.com/Futju0p.png)

Help
------------
Here is the help, you can get it aswell by passing the -h option
usage: 
`./configure.sh [-hDa] [-s src-dir] [-o obj-dir] [-b bin-dir] [-c compiler] [-O "compiler options"] [-L link-dirs] [-l lib] [-I include-dir] [-M Makefile-name] [-e file-extension] [-E executable-name]`
  -h    Show this help.
  -D    Supress the default options for -L,-I and -O
  -a    Automatic conversion of file in dos format to unix format. This option uses d
  -C    No colors.

Running without arguments is equivalent to this:
  `./configure.sh -D -s src -o obj -b bin -c "xcrun clang++" -O "-Wall -Wextra -O2 -std=c++11 -stdlib=libc++" -Isrc -L/usr/local/lib -e cpp -E main -M Makefile`

