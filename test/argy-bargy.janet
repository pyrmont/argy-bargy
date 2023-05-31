(import testament :prefix "")
(import ../src/argy-bargy)


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
        (argy-bargy/parse-args config))))
  (def expect {:err "" :out "" :res {:cmd "program" :opts @{"foo" true} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-option-count
  (def config {:rules ["--foo" {:kind :count}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo" "--foo"]]
        (argy-bargy/parse-args config))))
  (def expect {:err "" :out "" :res {:cmd "program" :opts @{"foo" 2} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-option-single
  (def config {:rules ["--foo" {:kind :single}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo" "bar"]]
        (argy-bargy/parse-args config))))
  (def expect {:err "" :out "" :res {:cmd "program" :opts @{"foo" "bar"} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-option-multi
  (def config {:rules ["--foo" {:kind :multi}]})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo" "bar" "--foo" "qux"]]
        (argy-bargy/parse-args config))))
  (def expect {:err "" :out "" :res {:cmd "program" :opts @{"foo" ["bar" "qux"]} :params @{}}})
  (is (== expect actual)))


(deftest parse-with-usage-error
  (def msg
      `program: unrecognized option '--foo'
      Try 'program --help' for more information.`)
  (def config {})
  (def actual
    (capture
      (with-dyns [:args @["program" "--foo"]]
        (argy-bargy/parse-args config))))
  (def expect {:err (string msg "\n") :out "" :res nil})
  (is (== expect actual)))


(deftest parse-with-usage-help
  (def msg
      `usage: program [OPTION]...

       Optional:
       -h, --help    Show this help message.`)
  (def config {})
  (def actual
    (capture
      (with-dyns [:args @["program" "--help"]]
        (argy-bargy/parse-args config))))
  (def expect {:err "" :out (string msg "\n") :res nil})
  (is (== expect actual)))


(deftest parse-subcommand-with-option-flag
  (def config {})
  (def subcommands {"example" {:rules ["--foo" {:kind :flag}]}})
  (def actual
    (capture
      (with-dyns [:args @["program" "example" "--foo"]]
        (argy-bargy/parse-args-with-subcommands config subcommands))))
  (def expect {:err "" :out "" :res @{:cmd "program" :globals @{} :sub "example" :opts @{"foo" true} :params @{}}})
  (is (== expect actual)))


(run-tests!)
