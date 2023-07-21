# Global values

(def- dir-sep "/")
(def- max-width 120)
(def- pad-inset 4)
(def- pad-right 6)
(def- hr "---")

(var- cols nil)
(var- command nil)
(var- helped? false)
(var- errored? false)


# Utility functions

(defn- get-cols
  ```
  Get the columns in the terminal
  ```
  []
  (if (nil? cols)
    (do
      (def cmd
        (if (= :windows (os/which))
          ["powershell" "-command" "&{(get-host).ui.rawui.WindowSize.Width;}"]
          ["tput" "cols"]))
      (with [f (file/temp)]
        (os/execute cmd :p {:out f})
        (file/seek f :set 0)
        (def out (file/read f :all))
        (def tcols (scan-number (string/trim out)))
        (min tcols max-width)))
    cols))


(defn- get-rule
  ```
  Get a rule matching a name
  ```
  [name rules]
  (var res nil)
  (each [k v] rules
    (when (or (= k name) (= (get v :short) name))
      (set res v)
      (break)))
  res)


(defn- get-subconfig
  ```
  Gets a subconfig matching a name
  ```
  [name subconfigs]
  (var res nil)
  (each [k v] subconfigs
    (when (= k name)
      (set res v)
      (break)))
  res)


(defn- split-words
  ```
  Split a string into words
  ```
  [str]
  (def res @[])
  (def buf @"")
  (var i 0)
  (while (def curr-c (get str i))
    (++ i)
    (if (not (or (= 32 curr-c) (= 10 curr-c)) )
      (buffer/push buf curr-c)
      (when-let [next-c (get str i)]
        (++ i)
        (array/push res (string buf))
        (buffer/clear buf)
        (cond
          (= 10 next-c)
          (array/push res (string/from-bytes curr-c next-c))

          (= 32 next-c)
          nil

          (buffer/push buf next-c)))))
  (unless (empty? buf)
    (array/push res (string buf)))
  res)


(defn- stitch
  ```
  Stitch together components into a string, only adding a separator when
  adjacent components are non-nil
  ```
  [parts &opt sep]
  (default sep " ")
  (string/join (filter truthy? parts) sep))


(defn- indent-str
  ```
  Indent a string by a number of spaces at the start

  If a maximum width is provided, wrap and indent lines by the
  hanging padding.
  ```
  [str startw &opt startp hangp maxw]
  (default startp 0)
  (default hangp 0)
  (default maxw cols)
  (def res (buffer (string/repeat " " startp)))
  (var currw startw)
  (var first? true)
  (each word (split-words str)
    (cond
      first?
      (do
        (buffer/push res word)
        (+= currw (length word))
        (set first? false))

      (= "\n\n" word)
      (do
        (buffer/push res word (string/repeat " " hangp))
        (set currw hangp)
        (set first? true))

      (< (+ currw 1 (length word)) maxw)
      (do
        (buffer/push res " " word)
        (+= currw (+ 1 (length word))))

      (do
        (buffer/push res "\n" (string/repeat " " hangp) word)
        (set currw (+ hangp (length word))))))
  res)


# Usage messages

(defn- usage-error
  ```
  Print the usage error message to stderr
  ```
  [& msg]
  (unless (or errored? helped?)
    (set errored? true)
    (eprint command ": " ;msg)
    (eprint "Try '" command " --help' for more information.")))


(defn- usage-parameters
  ```
  Print the usage descriptions for the parameters
  ```
  [info rules]
  (def usages @[])
  (var pad 0)

  (each [name rule] rules
    (def usage-prefix (string " " (string/ascii-upper name)))
    (def usage-help
      (stitch [(rule :help)
               (when (rule :default)
                 (string "(Default: " (rule :default) ")"))]))
    (array/push usages [usage-prefix usage-help])
    (set pad (max (+ pad-inset (length usage-prefix)) pad)))

  (unless (empty? usages)
    (print)
    (when (info :params)
      (print (info :params)))
    (each [prefix help] usages
      (def startp (- pad (length prefix)))
      (print prefix (indent-str help (length prefix) startp pad (- cols pad-right))))))


(defn- usage-options
  ```
  Print the usage descriptions for the options
  ```
  [info rules]
  (def usages @[])
  (var pad 0)

  (each [name rule] rules
    (if (= hr name)
      (array/push usages [nil nil])
      (do
        (def usage-prefix
          (stitch [(if (rule :short)
                     (string " -" (rule :short) ",")
                     "    ")
                   (string "--" name)
                   (when (or (= :single (rule :kind)) (= :multi (rule :kind)))
                     (string "<" (or (rule :proxy) name) ">"))
                   ]))
        (def usage-help
          (stitch [(rule :help)
                   (when (rule :default)
                     (string "(Default: " (rule :default) ")"))]))
        (array/push usages [usage-prefix usage-help])
        (set pad (max (+ pad-inset (length usage-prefix)) pad)))))

  (unless (empty? usages)
    (print)
    (when (info :opts)
      (print (info :opts))))

  (each [prefix help] usages
    (if (nil? help)
      (print)
      (do
        (def startp (- pad (length prefix)))
        (print prefix (indent-str help (length prefix) startp pad (- cols pad-right)))))))


(defn- usage-subcommands
  ```
  Print the usage descriptions for the subcommands
  ```
  [info subconfigs]
  (def usages @[])
  (var pad 0)

  (each [name config] subconfigs
    (if (= hr name)
      (array/push usages [nil nil])
      (do
        (def usage-prefix (string " " name))
        (def usage-help (get config :help ""))
        (array/push usages [usage-prefix usage-help])
        (set pad (max (+ pad-inset (length usage-prefix)) pad)))))

  (unless (empty? usages)
    (print)
    (when (info :subcmds)
      (print (info :subcmds)))
    (each [prefix help] usages
      (if (nil? help)
        (print)
        (do
          (def startp (- pad (length prefix)))
          (print prefix (indent-str help (length prefix) startp pad (- cols pad-right))))))
    (print)
    (print "For more information on each subcommand, type '" command " help <subcommand>'.")))


(defn- usage-example
  ```
  Prints a usage example
  ```
  [orules prules]
  (print
    (indent-str
      (string "usage: "
              command
              ;(map (fn [[name rule]]
                      (unless (or (nil? rule) (rule :no-eg?))
                        (string " [--" name
                                (when (or (= :single (rule :kind))
                                          (= :multi (rule :kind)))
                                  (string " <" (or (rule :proxy) (rule :name)) ">"))
                                "]")))
                    orules)
              ;(map (fn [[name rule]]
                      (def proxy (string/ascii-upper name))
                      (string " "
                              (cond
                                (and (rule :rest) (rule :required))
                                (string proxy  "...")

                                (rule :rest)
                                (string "[" proxy "...]")

                                proxy)))
                    prules))
      0
      0
      (+ 7 (length command) 1)
      (- cols pad-right))))


(defn- usage
  ```
  Print the usage message
  ```
  [&opt info [orules prules]]
  (default info {})
  (default orules {})
  (default prules [])

  (unless (or errored? helped?)
    (set helped? true)

    (if (info :usages)
      (each example (info :usages)
        (print example))
      (usage-example orules prules))

    (when (info :about)
      (print)
      (print (indent-str (info :about) 0)))

    (usage-parameters info prules)
    (usage-options info orules)

    (when (info :rider)
      (print)
      (print (indent-str (info :rider) 0)))))


(defn- usage-with-subcommands
  ```
  Print the usage message with subcommands
  ```
  [info [orules sunconfigs]]
  (unless (or errored? helped?)
    (set helped? true)

    (if (info :usages)
      (each example (info :usages)
        (print example))
      (print "usage: " command " <subcommand> [args...]"))

    (when (info :about)
      (print)
      (print (indent-str (info :about) 0)))

    (usage-options info orules)
    (usage-subcommands info sunconfigs)

    (when (info :rider)
      (print)
      (print (indent-str (info :rider) 0)))))


# Processing functions

(defn- convert
  ```
  Convert a textual value using the converter

  Internal functions are called if the converter is one of the following:

  * `:string` - Returns the value as-is.
  * `:integer` - Converts the value to an integer.
  ```
  [arg converter]
  (if (nil? converter)
    arg
    (cond
      (keyword? converter)
      (case converter
        :string
        arg

        :integer
        (let [[ok? res] (protect (scan-number arg))]
          (when (and ok? (int? res))
            res)))

      (function? converter)
      (converter arg))))


(defn- consume-option
  ```
  Consume an option
  ```
  [orules oargs args i &opt is-short?]
  (def arg (in args i))
  (def name (string/slice arg (if is-short? 1 2)))
  (if-let [rule (get-rule name orules)
           long-name (rule :name)
           kind (rule :kind)]
    (case kind
      :flag
      (do
        (put oargs long-name true)
        (inc i))

      :count
      (do
        (put oargs long-name (-> (oargs long-name) (or 0) inc))
        (inc i))

      (if (or (= kind :single)
              (= kind :multi))
        (if-let [input (get args (inc i))]
          (if-let [val (convert input (rule :value))]
            (do
              (case kind
                :single (put oargs long-name val)
                :multi  (put oargs long-name (array/push (or (oargs long-name) @[]) val)))
              (+ 2 i))
            (usage-error "'" input "' is invalid value for " arg))
          (usage-error "no value after option of type " kind))))
    (usage-error "unrecognized option '" arg "'")))


(defn- rest-capture
  ```
  Get the parameter that captures the rest of the values (if defined)
  ```
  [rules]
  (when-let [[name rule] (last rules)]
    (and (rule :rest) [name rule])))


(defn- consume-param
  ```
  Consume a parameter
  ```
  [prules pargs args i]
  (def pos (length pargs))
  (if-let [[name rule] (or (get prules pos)
                           (rest-capture prules))]
    (if-let [arg (get args i)]
      (if-let [val (convert arg (rule :value))]
        (do
          (if (rule :rest)
            (put pargs name (array/push (or (pargs name) @[]) val))
            (put pargs name val))
          (inc i))
        (usage-error "'" arg "' is invalid value for " (string/ascii-upper name)))
      (usage-error "no value for " (string/ascii-upper name)))
    (usage-error "too many parameters passed")))


(defn- conform-args
  ```
  Conform arguments

  In particular, split short-options out if provided together.
  ```
  [args]
  (def res @[])
  (def grammar ~{:main      (+ :long-opt :short-opt :rest)
                 :rest      '(some 1)
                 :long-opt  (* '(* "--" (any (if-not "=" 1))) (? (* "=" :rest)))
                 :short-opt (* '(* "-" 1) (any (% (* (constant "-") '1))))})
  (each arg args
    (array/concat res (peg/match grammar arg)))
  res)


(defn- conform-command
  ```
  Conform command
  ```
  [args]
  (->> (get args 0) (string/split dir-sep) last))


(defn- conform-rules
  ```
  Conform rules
  ```
  [rules]
  (var rest-capture? false)
  (def orules @[])
  (def prules @[])
  (var help? false)

  (var i 0)
  (while (< i (length rules))
    (def k (get rules i))
    (if (string/has-prefix? hr k)
      (array/push orules [hr nil])
      (do
        (unless (or (string? k) (keyword? k))
          (errorf "names of rules must be strings or keywords: %p" k))
        (def v (get rules (++ i)))
        (when (nil? v)
          (errorf "number of elements in rules must be even: %p" rules))
        (unless (or (struct? v) (table? v))
          (errorf "each rule must be struct or table: %p" v))
        (unless (or (keyword? k) ({:flag true :count true :single true :multi true} (v :kind)))
          (errorf "each option rule must be of kind :flag, :count, :single or :multi: %p" v))
        (when (and (keyword? k) rest-capture?)
          (errorf "parameter rules cannot occur after rule that captures :rest: %p" v))
        (cond
          (string? k)
          (let [name (if (string/has-prefix? "--" k) (string/slice k 2) k)]
            (when (nil? (peg/find '(* :w (some (+ :w (set "-_"))) -1) name))
              (errorf "option name must be at least two alphanumeric characters: %p" name))
            (array/push orules [name (merge v {:name name})])
            (set help? (= "help" name)))

          (keyword? k)
          (do
            (array/push prules [k v])
            (set rest-capture? (v :rest))))))
    (++ i))

  (unless help?
    (array/push orules ["help" {:name   "help"
                                :kind   :help
                                :no-eg? true
                                :short  "h"
                                :help   "Show this help message."}]))
  [orules prules])


(defn- conform-subconfigs
  ```
  Conforms subconfigs
  ```
  [subcommands]
  (def subconfigs @[])
  (var i 0)
  (while (< i (length subcommands))
    (def k (get subcommands i))
    (if (string/has-prefix? hr k)
      (array/push subconfigs [hr nil])
      (do
        (unless (string? k)
          (errorf "names of subcommands must be strings: %p" k))
        (def v (get subcommands (++ i)))
        (when (nil? v)
          (errorf "number of elements in subcommands must be even: %p" subcommands))
        (unless (or (struct? v) (table? v))
          (errorf "each subcommand must be struct or table: %p" v))
        (array/push subconfigs [k v])))
    (++ i))
  subconfigs)


# Parsing functions

(defn parse-args
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
  ```
  [config]
  (set cols (get-cols))
  (set command (conform-command (dyn :args)))
  (set helped? false)
  (set errored? false)
  (def oargs @{})
  (def pargs @{})

  (def [orules prules] (conform-rules (get config :rules [])))

  (def all-args (conform-args (dyn :args)))
  (def num-args (length all-args))
  (var i 1)

  (while (< i num-args)
    (def arg (get all-args i))
    (set i (cond
             (or (= "--help" arg) (= "-h" arg))
             (usage (config :info) [orules prules])

             (= "--" arg)
             (usage-error "illegal use of '--'")

             (string/has-prefix? "--" arg)
             (consume-option orules oargs all-args i)

             (= "-" arg)
             (usage-error "illegal use of '-'")

             (string/has-prefix? "-" arg)
             (consume-option orules oargs all-args i true)

             (consume-param prules pargs all-args i)))
    (when (nil? i)
      (break)))

  (each [name rule] prules
    (when (nil? (pargs name))
      (if (rule :required)
        (usage-error (string/ascii-upper name) " is required")
        (put pargs name (rule :default)))))

  @{:cmd command :opts oargs :params pargs :error? errored? :help? helped?})


(defn parse-args-with-subcommands
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
  ```
  [config subcommands]
  (set cols (get-cols))
  (set command (conform-command (dyn :args)))
  (set helped? false)
  (set errored? false)
  (def gargs @{})
  (def oargs @{})
  (def pargs @{})
  (var subcommand nil)

  (def [orules _] (conform-rules (get config :rules [])))
  (def subconfigs (conform-subconfigs subcommands))

  (def all-args (conform-args (dyn :args)))
  (def num-args (length all-args))
  (var i 1)

  (while (< i num-args)
    (def arg (get all-args i))
    (set i (cond
             (or (nil? arg) (= "--help" arg) (= "-h" arg))
             nil

             (string/has-prefix? "--" arg)
             (consume-option orules gargs all-args i)

             (= "-" arg)
             (usage-error "illegal use of '-'")

             (string/has-prefix? "-" arg)
             (consume-option orules gargs all-args i true)

             (= "help" arg)
             (do
               (set subcommand (get all-args (++ i)))
               (def subconfig (get-subconfig subcommand subconfigs))
               (cond
                 (nil? subcommand)
                 nil

                 (nil? subconfig)
                 (usage-error "unrecognized subcommand '" subcommand "'")

                 (do
                   (set command (string command " " subcommand))
                   (usage (subconfig :info) (conform-rules (get subconfig :rules []))))))

             (do
               (set subcommand arg)
               (def subconfig (get-subconfig subcommand subconfigs))
               (if (nil? subconfig)
                 (usage-error "unrecognized subcommand '" subcommand "'")
                 (with-dyns [:args (-> (array/slice all-args i)
                                       (put 0 (string command " " subcommand)))]
                   (def old-command command)
                   (def subargs (parse-args subconfig))
                   (set command old-command)
                   (unless (nil? subargs)
                     (merge-into oargs (subargs :opts))
                     (merge-into pargs (subargs :params))))))))
    (when (nil? i)
      (break)))

  (when (nil? subcommand)
    (usage-with-subcommands (config :info) [orules subconfigs]))

  @{:cmd command :globals gargs :sub subcommand :opts oargs :params pargs :error? errored? :help? helped?})
