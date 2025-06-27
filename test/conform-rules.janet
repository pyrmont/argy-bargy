(use ../deps/testament)


(review ../argy-bargy :prefix "")


(deftest conform-rules-help-flag
  (def actual (conform-rules ["help" {:kind :flag}]))
  (def expect [@[["help" @{:kind :flag :name "help"}]] @[]])
  (is (== expect actual)))


(deftest conform-rules-empty
  (def actual (conform-rules []))
  (def expect [@[["help" {:help "Show this help message."
                          :kind :help
                          :name "help"
                          :noex? true
                          :short "h"}]]
               @[]])
  (is (== expect actual)))


(deftest conform-rules-parameter-with-help
  (def actual (conform-rules [:file-path
                              {:help "File to examine and may be change"}]))
  (def expect [@[["help" {:help "Show this help message."
                          :kind :help
                          :name "help"
                          :noex? true
                          :short "h"}]]
               @[[:file-path
                  {:help "File to examine and may be change"}]]])
  (is (== expect actual)))


(deftest conform-rules-two-parameters
  (def actual (conform-rules [:port {:help "The netrepl server port."
                                     :default 9865
                                     :value :integer}
                              :host {:help "The netrepl server host."
                                     :default "localhost"}]))
  (def expect [@[["help" {:help "Show this help message."
                          :kind :help
                          :name "help"
                          :noex? true
                          :short "h"}]]
               @[[:port {:default 9865
                         :help "The netrepl server port."
                         :value :integer}]
                 [:host {:default "localhost"
                         :help "The netrepl server host."}]]])
  (is (== expect actual)))


(run-tests!)
