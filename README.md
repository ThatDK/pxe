# pxe
TO USE:
1. wget https://raw.githubusercontent.com/ThatDK/pxe/main/pxe-build.tar.gz (or download pxe-build.tar.gz file directly)
2. Rename file pxe-build.tar.gz
3. Make sure you are the root user
4. Copy pxe-build.tar.gz into /root directory
5. Unpack using tar -xvzf pxe-build.tar.gz
6. From /root/pxe-build directory, run pxe-build.sh
7. Change IPs in the directories mentioned after the script ends

The script was designed for Debian based distros. I have not written any for, or tried to write any for, other ditros yet.

Building a pxe server, thought of making a script that can make one by itself
The preseeds included do not have a username or password in them (for security purposes)

The script was thought of and thrown together quickly and I feel like it could be more efficient.

This is a personal project that was adapted from a former work project.

I do intend to write this for other ditros at some point, and in the same script.
