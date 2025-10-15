# Argy-Bargy

[![Test Status][icon]][status]

[icon]: https://github.com/pyrmont/argy-bargy/workflows/test/badge.svg
[status]: https://github.com/pyrmont/argy-bargy/actions?query=workflow%3Atest

Argy-Bargy is a fancy argument parsing library for Janet.

## Features

Argy-Bargy has the following features:

- parses options (arguments that begin with a `--` or `-`)
  - supports four option types (flags, counts, single values and
    multiple values)
  - supports user-defined conversions from text input
  - support parsing of combined short options (e.g. `-lah`)
  - support the use of `=` and white space between long options and values
- parses parameters (arguments that are not options)
  - supports positional parameters and catch-all parameters
  - supports user-defined conversions from text
  - supports required parameters and default values
- parses subcommands
  - supports arbitrary number of subcommands
  - supports per-subcommand options and parameters
- generates documentation
  - generates usage help based on parsing rules
  - supports user-defined usage examples
  - indents usage instructions automatically

## Installation

Add the dependency to your `info.jdn` file:

```janet
  :dependencies ["https://github.com/pyrmont/argy-bargy"]
```

## Usage

Argy-Bargy can be used like this:

### Without Subcommands

```janet
(import argy-bargy)

(def rules
  ["--foo" {:kind :single
            :help "The option foo takes a single value."}
   "--bar" {:kind :flag
            :help "The option bar is a flag."}
   :srcs   {:help  "The source files for the program."
            :rest? true}])

(def info
  {:about "A program that does something to the 'srcs' parameters."
   :rider "For more information, visit our website at example.com/program."})

(def config {:rules rules :info info})

(argy-bargy/parse-args "program" config)
```

If the argument is `-h`, the following will be printed to stdout:

```text
usage: program [--foo <foo>] [--bar] srcs...

A program that does something to the 'srcs' parameters.

Parameters:

 srcs    The source files for the program.

Options:

     --foo <foo>    The option foo takes a single value.
     --bar          The option bar is a flag.
 -h, --help         Show this help message.

For more information, visit our website at example.com/program.
```

### With Subcommands

```janet
(import argy-bargy)

(def subcommands
  ["foo" {:rules {:kind :single
                  :help "The option foo takes a single value."}
          :help  "Run the foo command."}
   "bar" {:rules {:kind :flag
                  :help "The option bar is a flag."}
          :help  "Run the bar command."}])

(def info
  {:about "A program that provides subcommands that do something."
   :rider "For more information, visit our website at example.com/program."})

(def config {:info info :subs subcommands})

(argy-bargy/parse-args "program" config)
```

If the argument is `-h`, the following will be printed to stdout:

```text
usage: program <subcommand> [<args>]

A program that provides subcommands that do something.

Options:

 -h, --help    Show this help message.

Subcommands:

 foo    Run the foo command.
 bar    Run the bar command.

For more information on each subcommand, type 'program help <subcommand>'.

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
