(use testament)


(review ../argy-bargy :prefix "")


(deftest indent-str-single-line
  (def actual
    (indent-str "hello there" 0 2 0 80))
  (def expect @"  hello there")
  (is (== expect actual)))


(deftest indent-str-multiline-to-more-lines
  (def actual
    (indent-str (string "A longish line\n"
                        "Second line")
                0 2 2 10))
  (def expect
    @``
       A longish
       line
       Second
       line
     ``)
  (is (== expect actual)))


(run-tests!)
