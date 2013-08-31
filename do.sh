
#! /bin/bash

# I usually have this kind of script in my project folder so that I don't have to manually write the configure options everytime I add new dependencies to the project
# This one is what I use in my project InputManager:
# https://github.com/posva/InputManager

./configure.sh -aD -s src -o obj -b bin -c "xcrun clang++" -O "-Wall -Wextra -O2 -std=c++11 -stdlib=libc++" -Isrc -L/usr/local/lib -e cpp -E main -M Makefile -l "-framework sfml-system -framework sfml-window -framework sfml-graphics"
