(use testament)


(import ../argy-bargy)


(defmacro capture [& body]
  (with-syms [out err res]
    ~(do
       (def ,out @"")
       (def ,err @"")
       (with-dyns [:out ,out :err ,err]
         (def ,res (do ,;body))
         {:res ,res :out (string ,out) :err (string ,err)}))))


(deftest parse-with-option-flag
  (def config {:rules ["--foo" {:kind :flag}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out ""
               :res {:cmd "program" :opts @{"foo" true} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-option-count
  (def config {:rules ["--foo" {:kind :count}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo" "--foo"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out ""
               :res {:cmd "program" :opts @{"foo" 2} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-option-single
  (def config {:rules ["--foo" {:kind :single}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo" "bar"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out ""
               :res {:cmd "program" :opts @{"foo" "bar"} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-option-multi
  (def config {:rules ["--foo" {:kind :multi}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo" "bar" "--foo" "qux"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out ""
               :res {:cmd "program" :opts @{"foo" ["bar" "qux"]} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-usage-error
  (def msg
      `program: unrecognized option '--foo'
      Try 'program --help' for more information.`)
  (def config {})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err (string msg "\n")
               :out ""
               :res {:cmd "program" :error? true :opts @{} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-usage-help
  (def msg
      `usage: program

       -h, --help    Show this help message.`)
  (def config {})
  (def actual
    (capture
      (with-dyns [:args @["program" "--help"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out (string msg "\n")
               :res {:cmd "program" :help? true :opts @{} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-usage-help-separators
  (def msg
       `usage: program [--foo]

            --foo     An option.

        -h, --help    Show this help message.`)
  (def config {:rules ["--foo" {:kind :flag
                                :help "An option."}
                       "---"]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--help"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out (string msg "\n")
               :res @{:cmd "program" :help? true :opts @{} :params @{}}})
  (is (== expect actual)))


(deftest parse-subcommand-with-option-flag
  (def config {:subs ["example" {:rules ["--foo" {:kind :flag}]}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "example" "--foo"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out ""
               :res @{:cmd "program" :opts @{} :sub {:cmd "example" :opts @{"foo" true} :params @{}}}})
  (is (== expect actual)))


(deftest parse-multiple-subcommands
  (def config {:subs ["foo" {:subs ["bar" {}]}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "foo" "bar"]]
        (argy-bargy/parse-args "program" config))))
  (def expect {:err ""
               :out ""
               :res @{:cmd "program" :opts @{} :sub {:cmd "foo" :opts @{} :sub @{:cmd "bar" :opts @{} :params @{}}}}})
  (is (== expect actual)))


(run-tests!)
