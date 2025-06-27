(use ../deps/testament)


(review ../argy-bargy :prefix "")


(deftest conform-subconfigs-one
  (def actual
    (conform-subconfigs ["example"
                         {:rules ["--foo" {:kind :flag}]}]))
  (def expect
    @[["example"
       {:rules ["--foo" {:kind :flag}]}]])
  (is (== expect actual)))


(deftest conform-subconfigs-two
  (def actual
    (conform-subconfigs ["clone"
                         {:rules ["--recursive" {:kind :flag}
                                  "--depth" {:kind :single
                                             :value :integer}]}
                         "commit"
                         {:rules ["--allow-empty" {:kind :flag}]}]))
  (def expect
    @[["clone"
       {:rules ["--recursive" {:kind :flag}
                "--depth" {:kind :single
                           :value :integer}]}]
      ["commit"
       {:rules ["--allow-empty" {:kind :flag}]}]])
  (is (== expect actual)))


(run-tests!)
