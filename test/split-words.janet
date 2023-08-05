(use testament)


(review ../argy-bargy :prefix "")


(deftest split-words-one-line
  (def actual
    (split-words "strange what desire will make foolish people do"))
  (def expect
    @["strange" "what" "desire" "will" "make" "foolish" "people" "do"])
  (is (== expect actual)))


(deftest split-words-multi-line
  (def actual
    (split-words
      ``
      For fear is an opinion of some great evil impending over us,
      and grief is an opinion of some great evil present; and, indeed,
      it is a freshly conceived opinion of an evil so great, that to
      grieve at it seems right: it is of that kind, that he who is uneasy
      at it thinks he has good reason to be so.
      ``))
  (def expect
    @["For" "fear" "is" "an" "opinion" "of" "some" "great" "evil" "impending"
      "over" "us," "and" "grief" "is" "an" "opinion" "of" "some" "great" "evil"
      "present;" "and," "indeed," "it" "is" "a" "freshly" "conceived" "opinion"
      "of" "an" "evil" "so" "great," "that" "to" "grieve" "at" "it" "seems"
      "right:" "it" "is" "of" "that" "kind," "that" "he" "who" "is" "uneasy"
      "at" "it" "thinks" "he" "has" "good" "reason" "to" "be" "so."])
  (is (== expect actual)))


(run-tests!)
