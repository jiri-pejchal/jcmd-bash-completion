# jcmd-bash-completion
This repository provides a bash completion script for the [jcmd](https://docs.oracle.com/en/java/javase/22/docs/specs/man/jcmd.html) utility, which sends diagnostic commands to a running Java Virtual Machine (JVM).

## Features
- Completes JVM process IDs (PIDs) and main class names
- Dynamically completes available diagnostic commands based on the selected JVM's capabilities

## Installation
Ensure that you have bash-completion installed and working in your shell.
If not, you can install it using your package manager.
For example, on Debian-based systems:
```sh
sudo apt-get install bash-completion
```
Clone the repository:
```sh
git clone https://github.com/jiri-pejchal/jcmd-bash-completion.git
cd jcmd-completion
```
Make the completion script available system-wide by copying it to the bash completion directory. This step requires administrative privileges (the path may vary depending on your operating system):
```sh
sudo cp jcmd-completion.bash /etc/bash_completion.d/jcmd-completion.bash
```

Start a new bash shell or source the completion script:
```sh
source /etc/bash_completion.d/jcmd-completion.bash
```

## Usage

### Selecting JVM processes
To list the running JVM processes, use:

```sh
$ jcmd <TAB>
```

This will display a list of PIDs and the main class names of the running JVMs, such as:
```sh
10345 com.intellij.idea.Main
10537 jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher
```

#### PID Completion
Select the JVM by typing the beginning of PID and pressing <kbd>TAB</kbd>. For instance:

```sh
$ jcmd 103<TAB>
```
completes to:
```bash
$ jcmd 10345
```

#### Main Class Name Completion
Select the JVM by typing the beginning of the full name of the class:

```sh
$ jcmd com.intellij<TAB>
```
completes to:
```sh
$ jcmd com.intellij.idea.Main
```
You can also complete using just the last part of the main class name:

```
$ jcmd M<TAB>
```
this will complete to:
```sh
jcmd Main
```

### Running jcmd Diagnostic Commands
Once a JVM(s) is selected by PID or main class name, the available commands are dynamically completed based on the capabilities of the selected JVM.
For example:

```
$ jcmd 10537 GC<TAB>
```

this will complete available commands such as:
```
GC.class_histogram GC.finalizer_info GC.heap_dump GC.heap_info GC.run
```

### Parameter Completion
Parameter completion is available for the command `GC.heap_dump`.

```sh
$ jcmd 10537 GC.heap_dump <TAB>

```

completes to
```sh
-all        -gz=        -overwrite  -parallel=
```
