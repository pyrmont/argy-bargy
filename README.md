# Argy-Bargy

[![Build Status](https://github.com/pyrmont/argy-bargy/workflows/build/badge.svg)](https://github.com/pyrmont/argy-bargy/actions?query=workflow%3Abuild)

Argy-Bargy is a fancy argument parsing library for Janet.

## Features

Argy-Bargy has the following features:

- parses options (arguments that begin with a `--` or `-`)
  - supports four option types (flags, counts, single values and
    multiple values)
  - supports user-defined conversions from text input
  - support parsing of combined short options (e.g. `-lah`)
  - support the use of `=` and white space between long options and values
- parses parameters (argument that are not options)
  - supports positional parameters and catch-all parameters
  - supports user-defined conversions from text
- parses subcommands
  - supports per-subcommand options and parameters
- generates documentation
  - generates usage help based on parsing rules
  - supports user-defined usage examples
  - indents usage instructions automatically

## Installation

Add the dependency to your `project.janet` file:

```clojure
(declare-project
  :dependencies ["https://github.com/pyrmont/argy-bargy"])
```

## Usage

Argy-Bargy can be used like this:

### Without Subcommands

```clojure
(import argy-bargy)

(def rules
  ["--foo" {:kind :single
            :help "The option foo takes a single value."}
   "--bar" {:kind :flag
            :help "The option bar is a flag."}
   :srcs   {:help "The source files for the program."
            :rest true}])

(def info
  {:about "A program that does something to the SRCS parameters."
   :rider "For more information, visit our website at example.com/program."})

(def config {:rules rules :info info})

(argy-bargy/parse-args config)
```

If the argument is `--help`, the following will be printed to stdout:

```text
usage: example [OPTION]... [SRCS...]

A program that does something to the SRCS parameters.

 SRCS    The source files for the program.

 Optional:
      --bar          The option bar is a flag.
      --foo VALUE    The option foo takes a single value.
  -h, --help         Show this help message.

For more information, visit our website at example.com/program.
```

### With Subcommands

```clojure
(import argy-bargy)

(def subcommands
  {"foo" {:rules {:kind :single
                  :help "The option foo takes a single value."}
          :help  "Run the foo command."}
   "bar" {:rules {:kind :flag
                  :help "The option bar is a flag."}
          :help  "Run the bar command."}})

(def info
  {:about "A program that provides subcommands that do something."
   :rider "For more information, visit our website at example.com/program."})

(def config {:info info})

(argy-bargy/parse-args-with-subcommands config subcommands)
```

If the argument is `--help`, the following will be printed to stdout:

```text
usage: example <subcommand> [args...]

A program that provides subcommands that do something.

 foo    Run the foo command.
 bar    Run the bar command.

For more information, visit our website at example.com/program.
```

## API

Documentation for Argy-Bargy's API is in [api.md][api].

[api]: https://github.com/pyrmont/argy-bargy/blob/master/api.md

## Bugs

Found a bug? I'd love to know about it. The best way is to report your bug in
the [Issues][] section on GitHub.

[Issues]: https://github.com/pyrmont/argy-bargy/issues

## Licence

Argy-Bargy is licensed under the MIT Licence. See [LICENSE][] for more details.

[LICENSE]: https://github.com/pyrmont/argy-bargy/blob/master/LICENSE
