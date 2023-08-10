# Argy-Bargy API

## argy-bargy

[hr](#hr), [max-width](#max-width), [pad-inset](#pad-inset), [pad-right](#pad-right), [parse-args](#parse-args)

## hr

**string**  | [source][1]

```janet
"---"
```

String to use to insert line breaks between argument descriptions

[1]: argy-bargy.janet#L6

## max-width

**number**  | [source][2]

```janet
120
```

Maximum number of columns to use for usage messages

[2]: argy-bargy.janet#L3

## pad-inset

**number**  | [source][3]

```janet
4
```

Number of columns to pad argument descriptions from the left

[3]: argy-bargy.janet#L4

## pad-right

**number**  | [source][4]

```janet
0
```

Number of columns to pad argument descriptions from the right

[4]: argy-bargy.janet#L5

## parse-args

**function**  | [source][5]

```janet
(parse-args name config)
```

Parses the `(dyn :args)` value for a program

This function takes a `name` and a `config`. `name` is a string that
represents the name of the program and is used for usage messages. `config`
is a struct containing the following keys:

* `:rules` - Tuple of rules to use to parse the arguments.
* `:info` - Struct of messages to use in help output.

The `config` struct may also contain a tuple of subcommands under the `:subs`
key.

### Rules

The rule tuple is a series of alternating rule names and rule contents. The
rule name is either a string or a key. The rule contents is a struct.

#### Options

If the rule name is a string, the rule contents will be applied to option
arguments (arguments that begin with a `-` or `--`). The rule contents struct
can have the following keys:

* `:kind` - The kind of option. Values are `:flag`, `:count`, `:single` and
  `:multi`. A flag is a binary choice (e.g. true/false, on/off) that can
  only occur once. A count is a monotonically increasing integral value that
  can occur one or more times. A single is a value that can only occur once.
  A multi is a value that can occur one or more times.
* `:short` - A single letter that is used with `-` rather than `--` and can
  be combined with other short options (e.g. `-lah`).
* `:help` - The help text for the option, displayed in the usage message.
* `:default` - A default value that is used if the option occurs.
* `:noex?` - Whether to hide the option from the generated usage example.
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

If the rule name is a keyword, the rule contents will be applied to parameter
arguments (arguments that are not options). The rule contents struct can have
the following keys:

* `:help` - Help text for the parameter, displayed in the usage message.
* `:default` - Default value that is used if the parameter is not present.
* `:req?` - Whether the parameter is required to be present.
* `:value` - One-argument function that converts the textual value that is
  parsed to a value that will be returned in the return struct. This function
  can be used for validation. If the return value is `nil`, the input is
  considered to fail parsing and a usage error message is printed instead.
  Instead of a function, a keyword can be provided and Argy-Bargy's converter
  will be used instead. The valid keywords are `:string` and `:integer`.
* `:rest?` - Whether this rule should capture all unassigned parameters. Only
  one parameter rule can have `:rest?` set to `true`.

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

### Subcommands

The subcommands tuple is a series of alternating subcommand names and
subcommand configs. The subcommand name is a string that will match the name
of a subcommand. The config is a struct of the same form as the `config`
struct. Multiple levels of subcommands can be supported by simply having a
subcommand's `config` struct contain a `:subs` key with a subcommands tuple
of its own.

In  addition to names and configs, the tuple can contain instances of the
string "---". When printing usage information, subcommands that were
separated by a "---" will be separated by a line break.

### Return Value

Once parsed, the return value is a table with `:cmd`, `:opts`, and either
`:params` or `:sub` keys. The values associated with `:opts` and `:params`
are tables containing the values parsed according to the rules. The table
also includes `:err` and `:help` keys that contain either the error or help
messages that may have been generated during parsing.

[5]: argy-bargy.janet#L624

