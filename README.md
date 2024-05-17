# xargsb - xargs re-implemented using BASH job control

This tool solves some historical issues with `xargs` that seem unlikely to be resolved in that tool in the
future. It was created to serve the needs of CI/CD primarily, where BASH scripting tends to excel in
problem solving, and replacement of core tools is a viable solution to work-around legacy tool limitations.

#### What's wrong with `xargs`?

`xargs` has some heavy restrictions on environment size and command line length which exist largely to solve
performance and limited memory-use issues on antiquated flavors of unix running on antiquated hadrware.
Moreover, the actual performance of the tool is quite poor by modern job-spawning standards, and is easily
bested by well-vetted and heavily optimized systems like BASH's builtin job control.

## How to use

### Requirements

 - BASH 5.0 is required, as this tool leverages the `wait -p VARNAME` feature.
 - BASH 5.2 or newer for best results, due to many small bugfixes issued to `wait -p` since its introduction
   in 5.0.

### Implicit use strategy (recommended for CI and Docker)

`xargsb` is somewhat near 90% compatible with `xargs` command line and can be used at the system-wide level
in many situations - particuarly in controlled environments like CI tasks and Docker images where the subset
of tools being run is well-known. This is most easily done by adding the following BASH script to the environment
PATH:

```
#!/bin/bash

exec xargsb "$@"
```

### Explicit use strategy

Invoke `xargsb` in the place of `xargs` within programs you author. This method is preferential for tools which
expect to be downloaded and run by a wide subset of end users and are not intended for use in controlled
development environments such as work PCs or CIs. In this strategy, the tool is packaged with other BASH-scripted
software and is invoked explicitly using a relative path prefix from the caller script, eg.

```
"$(dirname $0)/xargsb"
```

#### Drawbacks

Invocation of `xargsb` through subprocess launch via other scripting languages (python, golang, C, etc) may
fail unless the subprocess is explicitly launched using the shell (and on Windows, the shell will not default
to BASH and so it may fail even then). However, it's uncommonly rare for higher level programs to use xargs,
instead preferring to utilize their own thread-creation andf management systems, and in practice only shell
scripts typically engage in its use.

## Behavioral Differences from `xargs`

#### `--no-run-if-empty` is the _default_ behavior for `xargsb`

It is currently not possible to have this tool run a command if there are no arguments in the input to pass to
the command. This was chosen because the vast majority of the time its the actual behavior that users expect
and yet it is unusual for users to actually specify `-r` until their use case surfaces surprising errors as a
result.

## Why name it `xargsb` ?

... the `b` stands for BASH. It had originally been named `xxargs` but that was already the name used for the
earliest versions of gnu `parallel`, and so it seemed a good idea to avoid those.

## Future Roadmap

_This section is for would-be contributors to this tool._

### Implement the remainder of `xargs` command line options

Pretty self-explanatory. The most interesting missing options would seem to be:

 [ ] `--process-slot-var`
 [ ] 

There are a couple options which may not be particuarly useful for implement or honor at this point:

 - `--max-chars` (`-s`)
 - `--exit`  (`-x`)

Those exist mostly to work around limitations of xargs itself. There is a commandline length limit for BASH
but it typically hovers around 128k to 256k on current gen systems where xargs would be useful (eg, the sort
that have enough cores to merit parallel execution). Furthermore, there are usually many other workarounds
for limiting CLI length such that it needn't be built into the xargs tool itself, and implementation of such
a feature generically could impose some surprising amount of performance hit. Implementing the options is
still worthwhile at some point in the future - the value is low and thus in terms of priority they shoudl come
last after everything else.

### Build a new tool with a different name with a new CLI

This would be something more akin to `parallel` but likely not following its example for CLI. `parallel` is
somewhat ovelry complicated in all the things it supports built-in, where it should probably outsource some
of those responsibilities to other unit-sized tools.

The name of such a tool is also an interesting exercise. The name at that point should no longer contain the
name `xargs` in whole, since that name generally invokes/implies CLI compatibility. Moreover, while a popular
use of xargs is parallel execution, it is by no means the only use, and a new version of such a tool should
aim for the same all-inclusive use cases as `xargs`, thereby discouraging names that imply async/parallel
execution (eg, gnu `parallel` is not an ideal name for a tool meant to supersede xargs).
