(use testament)


(review ../argy-bargy :prefix "")


(deftest get-rule-by-name
  (def actual (get-rule "help" @[["help" {:kind :flag :name "help"}]]))
  (def expect {:kind :flag :name "help"})
  (is (== expect actual)))


(deftest get-rule-by-short-name
  (def actual
    (get-rule "h" @[["help"
                     {:help "Show this help message."
                      :kind :help
                      :name "help"
                      :noex? true
                      :short "h"}]]))
  (def expect
    {:help "Show this help message."
     :kind :help
     :name "help"
     :noex? true
     :short "h"})
  (is (== expect actual)))


(run-tests!)
