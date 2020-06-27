# Modeline & Notes {{{
# vim: set sw=4 ts=4 sts=4 et tw=79 foldlevel=0 foldmethod=marker foldmarker={{{,}}}:
#
# }}}

# 
# When is this file read?
#
# Pretty much all the time. Any interactive or non-interactive shell reads this
# file. Pretty much the only way to get a non-interactive shell (as I
# understand things), is by running a script with a `#!...` line. I'd expect
# also a cronjob (and probably other things I'm not thinking about).
#
# At any rate the important thing about this file is not that it's read by
# pretty much any shell, but it's the _ONLY_ file that's read via a
# non-interactive shell (i.e. primarily scripts). 
#
# As a result, we don't want to put much in here that's not necessary for an
# invoked script. Like path's that we might want. The other item of interest
# here is that a non-interactive shell will inherit the environment from the
# calling shell. Note importantly, this does NOT include aliases (think `env`
# vs `set`).
#
# So if we're in an interactive shell and run a script, it will inherit the
# existing environment, pretty much negating the need to put anything in this
# file (since anything at the level of what we would put in here would get
# inherited by the script).
#
# So the _ONLY_ time we would really need anything for shell scripts in here
# would be if were running a script from a shell that hasn't been configured
# with our enviroment. In other words, a script that we didn't invoke
# interactively. Like say if we were running a cronjob.
#
