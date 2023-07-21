# Argy-Bargy API

## argy-bargy

[parse-args](#parse-args), [parse-args-with-subcommands](#parse-args-with-subcommands)

## parse-args

**function**  | [source][1]

```janet
(parse-args config)
```

Parse the `(dyn :args)` value for a program

This function takes a `config` struct containing the following keys:

* `:rules` - Tuple of rules to use to parse the arguments.
* `:info` - Struct of messages to use in help output.

### Rules

The dynamic variable `:args` is parsed according to the rules tuple. This
tuple is a series of key-value pairs.

#### Options

If the key is a string, the rule will be applied to option arguments
(arguments that begin with a `-` or `--`). The value associated with each key
is a struct that can have the following keys:

* `:kind` - The kind of option. Values are `:flag`, `:count`, `:single` and
  `:multi`. A flag is a binary choice (e.g. true/false, on/off) that can
  only occur once. A count is a monotonically increasing integral value that
  can occur one or more times. A single is a value that can only occur once.
  A multi is a value that can occur one or more times.
* `:short` - A single letter that is used with `-` rather than `--` and can
  be combined with other short options (e.g. `-lah`).
* `:help` - The help text for the option, displayed in the usage message.
* `:default` - A default value that is used if the option occurs.
* `:no-eg?` - Whether to hide the option from the generated usage example.
* `:value` - A one-argument function that converts the text that is parsed to
  another kind of value. This function can be used for validation. If the
  return value is `nil`, the input is considered to fail parsing and a usage
  error message is printed instead.  Instead of a function, a keyword can be
  provided and Argy-Bargy's internal converter will be used instead. The
  valid keywords are :string and :integer.

A `--help` option is added automatically unless provided in the rules tuple.
Options will be separated by a blank line if the rules tuple includes a
`---` separator.

#### Parameters

If the key is a keyword, the rule will be applied to parameter arguments
(arguments that are not options). The value associated with each key is a
struct that can have the following keys:

* `:help` - Help text for the parameter, displayed in the usage message.
* `:default` - Default value that is used if the parameter does not occur.
* `:required` - Whether the parameter is required to exist.
* `:value` - One-argument function that converts the textual value that is
  parsed to a value that will be returned in the return struct. This function
  can be used for validation. If the return value is `nil`, the input is
  considered to fail parsing and a usage error message is printed instead.
  Instead of a function, a keyword can be provided and Argy-Bargy's converter
  will be used instead. The valid keywords are `:string` and `:integer`.
* `:rest` - Whether this rule should capture all following parameters. Only
  one parameter rule can have `:rest` set to `true`.

### Info

The info struct contains messages that are used in the usage help. The struct
can have the following keys:

* `:about` - Message describing the program at a high level.
* `:usages` - Collection of usage examples to be used in the usage message.
  If no examples are provided, one will be generated automatically based on
  the provided rules.
* `:opts` - Message printed immediately prior to listing of options.
* `:params` - Message printed immediately prior to listing of parameters.
* `:rider` - Message printed at the end of the usage message.

### Return Value

Once parsed, the return value is a table with `:cmd`, `:opts` and `:params`
keys. The value associated with each key is a table containing the values
parsed for each matching rule. The table also includes `:error?` and `:help?`
keys that can be used to determine if the parsing completed successfully.

[1]: argy-bargy.janet#L534

## parse-args-with-subcommands

**function**  | [source][2]

```janet
(parse-args-with-subcommands config subcommands)
```

Parse the `(dyn :args)` value for a program with subcommands

This function takes a `config` struct and a `subcommands` struct.

### Config

The `config` struct should contain the following keys:

* `:rules` - Tuple of rules to use to parse the arguments.
* `:info` - Struct of messages to use in help output.

The rules tuple is similar to that in `parse-args` except that parameter
rules are ignored.

The info struct is similar to that in `parse-args` except that the `:params`
key is ignored. A `:subcmds` key can be provided and is displayed immediately
prior to the listing of subcommands.

### Subcommands

The `subcommands` tuple is a series of key-value pairs. Each key is a string
and each value is a struct. The key is the name of the subcommand. The struct
includes the same keys as the `config` struct used in `parse-args`. A `:help`
key can be provided and is used in the listing of subcommands.

### Return Value

Once parsed, the return value is a table with `:cmd`, `:globals`, `:sub`,
`:opts` and `:params` keys.  The value associated with the `:cmd`, `:opts`
and `:params` keys are the same as that in `parse-args`. The value associated
with the `:globals` and `:sub` keys are the globals options and the name of
the subcommand respectively. The table also includes `:error?` and `:help?`
keys that can be used to determine if the parsing completed successfully.

[2]: argy-bargy.janet#L658

