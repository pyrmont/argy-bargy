(use testament)


(review ../argy-bargy :prefix "")


(deftest stitch-no-nils
  (def actual (stitch @["desire" "will" "make" "foolish" "people"]))
  (def expect "desire will make foolish people")
  (is (== expect actual)))


(deftest stitch-with-nils
  (def actual (stitch @["strange" nil "what" "desire" "will" "make" nil]))
  (def expect "strange what desire will make")
  (is (== expect actual)))


(run-tests!)
