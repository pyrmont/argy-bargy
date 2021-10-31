# Argy-Bargy API

## argy-bargy

[parse](#parse), [parse-with-subcommands](#parse-with-subcommands)

## parse

**function**  | [source][1]

```janet
(parse rules &opt info has-command?)
```

Parse the `(dyn :args)` value for a program

This function takes a user-defined `rules` tuple  and parses the values in
the dynamic variable `:args` according to the rules. The tuple is a series of
key-value pairs.

If the key is a string, the rule will be applied to option arguments
(arguments that begin with a `-` or `--`). The value is a struct that can
have the following keys:

* `:kind` - The kind of option. Values are `:flag`, `:count`, `:single` and
  `:multi`. A flag is a binary choice (e.g. true/false, on/off) that can
  only occur once. A count is a monotonically increasing integral value that
  can occur one or more times. A single is a value that can only occur once.
  A multi is a value that can occur one or more times.
* `:short` - A single letter that is used with `-` rather than `--` and can
  be combined with other short options (e.g. `-lah`).
* `:help` - The help text for the option, displayed in the usage message.
* `:default` - A default value that is used if the option occurs.
* `:required` - Whether the option is required to occur.
* `:value` - A one-argument function that converts the text that is parsed to
  another kind of value. This function can be used for validation. If the
  return value is `nil`, the input is considered to fail parsing and a usage
  error message is printed instead.  Instead of a function, a keyword can be
  provided and Argy-Bargy's internal converter will be used instead. The
  valid keywords are :string and :integer.

If the key is a keyword, the rule will be applied to parameter arguments
(arguments that are not options). The value is a struct that can have the
following keys:

* `:help` - The help text for the parameter, displayed in the usage message.
* `:default` - A default value that is used if the parameter does not occur.
* `:required` - Whether the parameter is required to occur.
* `:value` - A one-argument function that converts the textual value that is
  parsed to a value that will be returned in the return struct. This function
  can be used for validation. If the return value is `nil`, the input is
  considered to fail parsing and a usage error message is printed instead.
  Instead of a function, a keyword can be provided and Argy-Bargy's converter
  will be used instead. The valid keywords are :string and :integer.
* `:rest` - Whether this rule should capture all following parameters. Only
  one parameter rule can have `:rest` set to `true`.

A user can also provide an `info` struct that contains descriptions that will
be used in usage messages that are output in response to user input.

Once parsed, the return value is a strruct with `:opts` and `:params` keys.
The value associated with each key is a table containing the values parsed
for each matching rule.

[1]: src/argy-bargy.janet#L360

## parse-with-subcommands

**function**  | [source][2]

```janet
(parse-with-subcommands info &keys configs)
```

Parse the `(dyn :args)` value for a program with subcommands

The function requires an `info` struct with information for the top-level
usage messages (this can be empty). In addition, a series of key-value pairs
should be provided with the key being the name of the subcommand and the
value being a tuple of rules and info that match the values expected by
`parse`.

The return value is the same struct returned by `parse` but with one
additional key, `:sub`. The value is a string with the matching subcommand.

[2]: src/argy-bargy.janet#L463

