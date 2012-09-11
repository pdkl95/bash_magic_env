Bash Magic Env
==============

Environment loader/unload er for [bash][1], that [automagically][2]
updates the environment as you change directories.

Why?
----

Bash and emacs are my IDE (and "desktop"), and the amount of junk I
have loaded at any one time has grown to unmanageable levels.
Ideally, this should limit many things to only the specific project
that needed them.

Instructions
------------

Just source the file into your bash environment, and 
set variables in a `.magic_env` located in the directory
hey should be active. The variables will be loaded  when you
`cd` to the directory, and unloaded when you leave.

If yo make a file called `.magic_env.unload` in the same
directory, it will be sourced into the shell  at the beginning
of the unload process.

Unfortunately, it's still a prototype
-------------------------------------

The above description is of only limited use at th emoment, as I
haven't written one of the more important features yet: recursive
detection of the `.magic_env` files up directory tree, towards root.

It needs to load the environmen whenever you are in the specific
directory, _or_ any of it's subdirectories, recursively.
This behavior would be very similar to how `git` finds the `.git`
directory for a project.

Furthermore, this would let you describe envrironments in a
heirarchy, loading more than one `.magic_env` at a time when
the trees overlap.

"But...overriding 'cd' is dangrous!"
------------------------------------

Yes, it is. It's also convenient at the moment. What has to happen
is that the `_magic_env_update` function must be called at
least once every directory change (more is ok).

I plan on using something like this, eventually, instead
of `cd(){...}` as currently used:

``` sh
    PROMPT_COMMAND="_magic_env_update ; ${PROMPT_COMMAND}"
```

Settings
--------

See the comments at the top of the script.



Copyright
---------

Copyright 2012 Brent Sanders

GPL-3, See COPYING for details.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    
[1]: http://www.gnu.org/software/bash/
[2]: http://catb.org/jargon/html/A/automagically.html


