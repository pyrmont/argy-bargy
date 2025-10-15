(use ../deps/testament)

(review ../argy-bargy :prefix "")

(deftest parser-lookup-option-by-long-name
  (def parser (make-parser {:rules ["help" {:kind :flag}]}))
  (def actual (get-in parser [:long-opts "help"]))
  (def expect {:kind :flag :name "help"})
  (is (== expect actual)))

(deftest parser-lookup-option-by-short-name
  (def parser (make-parser {:rules ["help" {:kind :help
                                            :short "h"
                                            :help "Show this help message."
                                            :noex? true}]}))
  (def actual (get-in parser [:short-opts "h"]))
  (def expect {:help "Show this help message."
               :kind :help
               :name "help"
               :noex? true
               :short "h"})
  (is (== expect actual)))

(deftest parser-adds-help-automatically
  (def parser (make-parser {:rules []}))
  (def actual (get-in parser [:long-opts "help"]))
  (def expect {:help "Show this help message."
               :kind :help
               :name "help"
               :noex? true
               :short "h"})
  (is (== expect actual)))

(deftest parser-parameters-in-order
  (def parser (make-parser {:rules [:file-path
                                        {:help "File to examine and may be change"}]}))
  (def actual (parser :params))
  (def expect @[[:file-path
                 {:help "File to examine and may be change"}]])
  (is (== expect actual)))

(deftest parser-multiple-parameters
  (def parser (make-parser {:rules [:port {:help "The netrepl server port."
                                           :default 9865
                                           :value :integer}
                                    :host {:help "The netrepl server host."
                                           :default "localhost"}]}))
  (def actual (parser :params))
  (def expect @[[:port {:default 9865
                        :help "The netrepl server port."
                        :value :integer}]
                [:host {:default "localhost"
                        :help "The netrepl server host."}]])
  (is (== expect actual)))

(deftest parser-preserves-ordered-rules
  (def parser (make-parser {:rules ["verbose" {:kind :flag}]}))
  (def actual (get-in parser [:ordered :opts]))
  # Should have verbose and auto-added help
  (is (= 2 (length actual)))
  (def verbose-rule (first actual))
  (is (= "verbose" (first verbose-rule)))
  (is (= :flag (get-in verbose-rule [1 :kind]))))

(deftest parser-lookup-subcommand
  (def parser (make-parser {:subs ["example"
                                   {:rules ["--foo" {:kind :flag}]}]}))
  (def actual (get-in parser [:subs "example"]))
  (def expect {:rules ["--foo" {:kind :flag}]})
  (is (== expect actual)))

(deftest parser-multiple-subcommands
  (def parser (make-parser {:subs ["clone"
                                   {:rules ["--recursive" {:kind :flag}
                                            "--depth" {:kind :single
                                                       :value :integer}]}
                                   "commit"
                                   {:rules ["--allow-empty" {:kind :flag}]}]}))
  (def clone-config (get-in parser [:subs "clone"]))
  (def commit-config (get-in parser [:subs "commit"]))
  (is (not (nil? clone-config)))
  (is (not (nil? commit-config)))
  (is (= ["--recursive" {:kind :flag}
          "--depth" {:kind :single
                     :value :integer}]
         (clone-config :rules)))
  (is (= ["--allow-empty" {:kind :flag}]
         (commit-config :rules))))

(deftest parser-subcommand-with-nested-subs
  (def parser (make-parser {:subs ["foo" {:subs ["bar" {}]}]}))
  (def actual (get-in parser [:subs "foo"]))
  (def expect {:subs ["bar" {}]})
  (is (== expect actual)))

(deftest parser-preserves-ordered-subcommands
  (def parser (make-parser {:subs ["clone" {}
                                   "commit" {}]}))
  (def actual (get-in parser [:ordered :subs]))
  (def expect @[["clone" {}]
                ["commit" {}]])
  (is (== expect actual)))

(run-tests!)
