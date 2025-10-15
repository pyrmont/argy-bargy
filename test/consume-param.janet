(use ../deps/testament)

(review ../argy-bargy :prefix "")

(deftest consume-param-single
  (def result @{:cmd "program" :opts @{} :params @{}})
  (def actual-ret
    (consume-param result
                   [:foo {}]
                   @["-foo"]
                   0
                   1))
  (def expect-ret 1)
  (is (== expect-ret actual-ret))
  (def actual result)
  (def expect @{:cmd "program" :opts @{} :params @{:foo "-foo"}})
  (is (== expect actual)))

(run-tests!)
