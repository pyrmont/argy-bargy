(use testament)


(review ../argy-bargy :prefix "")


(deftest convert-integer
  (def actual (convert "3" :integer))
  (def expect 3)
  (is (== expect actual)))


(deftest convert-string
  (def actual (convert "hello" :string))
  (def expect "hello")
  (is (== expect actual)))


(deftest convert-custom
  (def actual (convert "[1 2 3]" (fn [x] (parse x))))
  (def expect [1 2 3])
  (is (== expect actual)))


(run-tests!)
