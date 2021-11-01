# Global values

(def- max-width 120)
(def- pad-inset 4)
(def- pad-right 6)

(var- command "")
(def- config @{:info {} :orules {} :prules [] :srules {}})
(var- errored? false)


# Functions

(defn- long-opts
  ```
  Filter short options from option rules
  ```
  [opts]
  (filter (fn [[name _]] (not (one? (length name)))) (pairs opts)))


(defn- get-cols
  ```
  Get the columns in the terminal
  ```
  []
  (def p (os/spawn ["tput" "cols"] :p {:out :pipe :err :pipe}))
  (def err (:wait p))
  (def cols (if (zero? err) (-> (p :out) (:read :all) string/trim scan-number)))
  (min (or cols max-width) max-width))


(defn- indent-str
  ```
  Indent a string by a number of spaces at the start

  If a maximum width is provided, wrap and indent lines by the
  hanging padding.
  ```
  [str startp &opt hangp maxw]
  (default hangp startp)
  (default maxw math/inf)
  (def res (buffer (string/repeat " " (dec startp))))
  (def words (->> (string/split " " str) (filter |(not (empty? $)))))
  (var currw hangp)
  (each word words
    (if (< (+ currw 1 (length word)) maxw)
      (do
        (buffer/push res " " word)
        (+= currw (+ 1 (length word))))
      (do
        (buffer/push res "\n" (string/repeat " " hangp) word)
        (set currw (+ hangp (length word))))))
  res)


(defn- usage-error
  ```
  Print the usage error message to stderr
  ```
  [& msg]
  (unless errored?
    (set errored? true)
    (eprint command ": " ;msg)
    (eprint "Try '" command " --help' for more information.")))


(defn- usage
  ```
  Print the usage message
  ```
  []
  (set errored? true)

  (def cols (get-cols))
  (def info (get config :info {}))
  (def orules (get config :orules {}))
  (def prules (get config :prules []))

  (if (info :examples)
    (each example (info :examples)
      (print example))
    (do
      (prin "usage: " command)
      (unless (zero? (length orules))
        (prin " [OPTION]..."))
      (each [name rule] prules
        (prin " ")
        (cond
          (and (rule :rest) (rule :required))
          (prin (string/ascii-upper name) "...")

          (rule :rest)
          (prin "[" (string/ascii-upper name) "...]")

          (prin (string/ascii-upper name))))
      (print)))

  (when (info :about)
    (print)
    (print (info :about)))

  (when (info :param-intro)
    (print)
    (print (info :param-intro)))

  (def pfrags @[])
  (var ppad 0)

  (each [name rule] prules
    (def usage-prefix
      (string
        " " (string/ascii-upper name)
        ;(if (or (= :single (rule :kind)) (= :multi (rule :kind)))
          [" " (or (rule :value-name) "VALUE")]
          [])
        ;(if (rule :default)
          ["=" (rule :default)]
          [])))
    (def usage-help (or (-?>> (rule :help) (string/replace-all "\n" " ")) ""))
    (array/push pfrags [usage-prefix usage-help])
    (set ppad (max (+ pad-inset (length usage-prefix)) ppad)))

  (unless (empty? pfrags)
    (print)
    (each [prefix help] pfrags
      (def startp (- ppad (length prefix)))
      (print prefix (indent-str help startp ppad (- cols pad-right)))))

  (when (info :option-intro)
    (print)
    (print (info :option-intro)))

  (def ofrags @{:req @[] :opt @[]})
  (def opad @{:req 0 :opt 0})

  (each [name rule] (sort (long-opts orules))
    (def usage-prefix
      (string
        ;(if (rule :short)
          [" -" (rule :short) ","]
          ["    "])
        " --" name
        ;(if (or (= :single (rule :kind)) (= :multi (rule :kind)))
          [" " (or (rule :value-name) "VALUE")]
          [])
        ;(if (rule :default)
          ["=" (rule :default)]
          [])))
    (def usage-help (or (-?>> (rule :help) (string/replace-all "\n" " ")) ""))
    (def k (if (rule :required) :req :opt))
    (array/push (ofrags k) [usage-prefix usage-help])
    (put opad k (max (+ pad-inset (length usage-prefix)) (opad k))))

  (each k [:req :opt]
    (unless (empty? (ofrags k))
      (print)
      (print " " (if (= k :req) "Required" "Optional") ":")
      (each [prefix help] (ofrags k)
        (def startp (- (opad k) (length prefix)))
        (print prefix (indent-str help startp (opad k) (- cols pad-right))))))

  (when (info :rider)
    (print)
    (print (info :rider))))


(defn- usage-subcommands
  ```
  Print a usage message about subcommands
  ```
  []
  (set errored? true)

  (def cols (get-cols))
  (def info (get config :info {}))
  (def rules (get config :srules {}))

  (if (info :examples)
    (each example (info :examples)
      (print example))
    (prin "usage: " command " <command> <args>"))

  (when (info :about)
    (print)
    (print (info :about)))

  (def frags @[])
  (var pad 0)

  (each [command [_ info]] (sort (pairs rules))
    (def usage-prefix (string " " command))
    (def usage-help (or (-?>> (info :help) (string/replace-all "\n" " ")) ""))
    (array/push frags [usage-prefix usage-help])
    (set pad (max (+ pad-inset (length usage-prefix)) pad)))

  (unless (empty? frags)
    (print)
    (print "The following subcommands are available:")
    (print)
    (each [prefix help] frags
      (def startp (- pad (length prefix)))
      (print prefix (indent-str help startp pad (- cols pad-right)))))

  (when (info :rider)
    (print)
    (print (info :rider))))


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
  [rules oargs args i &opt is-short?]
  (def arg (in args i))
  (def name (string/slice (in args i) (if is-short? 1 2)))
  (if-let [rule (rules name)
           kind (rule :kind)]
    (case kind
      :help
      (usage)

      :flag
      (do
        (put oargs name true)
        (inc i))

      :count
      (do
        (put oargs name (-> (oargs name) (or 0) inc))
        (inc i))

      (if (or (= kind :single)
              (= kind :multi))
        (if-let [arg (get args (inc i))]
          (if-let [val (convert arg (rule :value))]
            (do
              (case kind
                :single (put oargs name val)
                :multi  (put oargs name (array/push (or (oargs name) @[]) val)))
              (+ 2 i))
            (usage-error "value passed to " arg " is invalid"))
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
  [rules pargs args i]
  (def pos (length pargs))
  (if-let [[name rule] (or (get rules pos)
                           (rest-capture rules))]
    (if-let [arg (in args i)
             val (convert arg (rule :value))]
      (do
        (if (rule :rest)
          (put pargs name (array/push (or (pargs name) @[]) val))
          (put pargs name val))
        (inc i))
      (usage-error "'" arg "' is invalid value for " (string/ascii-upper name)))
    (usage-error "too many parameters passed")))


(defn- conform-args
  ```
  Conform arguments

  In particular, split short-options out if provided together.
  ```
  [args]
  (def res @[])
  (def grammar ~{:main      (+ :long-opt :short-opt ':rest)
                 :rest      (some 1)
                 :long-opt  (* '(* "--" (any (if-not "=" 1))) (? (* "=" ':rest)))
                 :short-opt (* '(* "-" 1) (any (% (* (constant "-") '1))))})
  (each arg args
    (array/concat res (peg/match grammar arg)))
  res)


(defn- conform-rules
  ```
  Conform rules
  ```
  [rules]
  (unless (even? (length rules))
    (errorf "number of elements in rules must be even: %p" rules))
  (def orules @{})
  (def prules @[])
  (var rest-capture? false)

  (put orules "help" {:kind  :help
                      :short "h"
                      :help  "Show this help message."})

  (each [k v] (partition 2 rules)
    (unless (or (string? k) (keyword? k))
      (errorf "names of rules must be strings or keywords: %p" k))
    (unless (or (struct? v) (table? v))
      (errorf "each rule must be struct or struct or table: %p" v))
    (unless (or (keyword? k) ({:flag true :count true :single true :multi true} (v :kind)))
      (errorf "each option rule must be of kind :flag, :count, :single or :multi: %p" v))
    (when (and (keyword? k) rest-capture?)
      (errorf "parameter rules cannot occur after rule that captures :rest: %p" v))
    (cond
      (string? k)
      (let [name (if (string/has-prefix? "--" k) (string/slice k 2) k)]
        (when (string/has-prefix? "-" name)
          (errorf "long option name must be provided: %p" name))
        (unless (> (length name) 2)
          (errorf "option names must be at least two characters: %p" name))
        (put orules name v)
        (put orules (v :short) v))

      (keyword? k)
      (do
        (array/push prules [k (if (v :rest) v (merge v {:required true}))])
        (set rest-capture? (v :rest)))))
  [orules prules])


(defn parse
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
  ```
  [rules &opt info has-command?]
  (set errored? false)
  (def oargs @{})
  (def pargs @{})

  (def args (conform-args (dyn :args)))
  (def num-args (length args))
  (var i (if has-command? 2 1))
  (set command (string/join (array/slice args 0 i) " "))

  (def [orules prules] (conform-rules rules))
  (put config :info info)
  (put config :orules orules)
  (put config :prules prules)

  (while (< i num-args)
    (def arg (in args i))
    (set i (cond
             (= "--" arg)
             (inc i)

             (string/has-prefix? "--" arg)
             (consume-option orules oargs args i)

             (= "-" arg)
             (usage-error "illegal use of '-'")

             (string/has-prefix? "-" arg)
             (consume-option orules oargs args i (string/slice arg 1))

             (consume-param prules pargs args i)))
    (when (nil? i)
      (break)))

  (unless errored?
    (each [name rule] prules
      (when (nil? (pargs name))
        (if (rule :required)
          (usage-error (string/ascii-upper name) " is required")
          (put pargs name (rule :default)))))

    (each [name rule] (long-opts orules)
      (when (nil? (oargs name))
        (when (rule :required)
          (usage-error "--" name " is required"))
        (put oargs name (rule :default)))))

  (unless errored?
    {:opts oargs :params pargs}))


(defn parse-with-subcommands
  ```
  Parse the `(dyn :args)` value for a program with subcommands

  The function requires an `info` struct with information for the top-level
  usage messages (this can be empty). In addition, a series of key-value pairs
  should be provided with the key being the name of the subcommand and the
  value being a tuple of rules and info that match the values expected by
  `parse`.

  The return value is the same struct returned by `parse` but with one
  additional key, `:sub`. The value is a string with the matching subcommand.
  ```
  [info &keys configs]
  (def num-args (dyn :args))

  (def pcommand (in (dyn :args) 0))

  (set command pcommand)
  (put config :info info)
  (put config :srules configs)

  (def scommand (get (dyn :args) 1))
  (cond
    (or (one? num-args)
        (= "--help" scommand)
        (= "-h" scommand))
    (usage-subcommands)

    (string/has-prefix? "-" scommand)
    (usage-error "unrecognized option '" scommand "'")

    (nil? (configs scommand))
    (usage-error "unrecognized command '" scommand "'")

    (let [[args info] (configs scommand)]
      (put (parse args info true) :sub scommand))))
