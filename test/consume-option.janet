(use ../deps/testament)


(review ../argy-bargy :prefix "")


(deftest consume-option-single
  (def result @{:cmd "example" :opts @{} :params @{}})
  (def actual-ret
    (consume-option result
                    @[["foo" @{:kind :flag
                               :name "foo"}]
                      ["help" {:help "Show this help message."
                               :kind :help
                               :name "help"
                               :noex? true
                               :short "h"}]]
                    @["example" "--foo"]
                    1
                    false))
  (def expect-ret 2)
  (is (== expect-ret actual-ret))
  (def actual result)
  (def expect @{:cmd "example" :opts @{"foo" true} :params @{}})
  (is (== expect actual)))


(run-tests!)
