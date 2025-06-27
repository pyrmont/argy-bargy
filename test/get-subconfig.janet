(use ../deps/testament)


(review ../argy-bargy :prefix "")


(deftest get-subconfig-with-rules
  (def actual
    (get-subconfig @[["example" {:rules ["--foo" {:kind :flag}]}]]
                   "example"))
  (def expect {:rules ["--foo" {:kind :flag}]})
  (is (== expect actual)))

(deftest get-subconfig-with-subs
  (def actual
    (get-subconfig @[["foo" {:subs ["bar" {}]}]]
                   "foo"))
  (def expect {:subs ["bar" {}]})
  (is (== expect actual)))


(run-tests!)
