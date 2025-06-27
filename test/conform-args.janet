(use ../deps/testament)


(review ../argy-bargy :prefix "")


(deftest conform-args-long-option-ws-separated-value
  (def actual (conform-args ["cargo" "build" "--target" "release"]))
  (def expect @["cargo" "build" "--target" "release"])
  (is (== expect actual)))


(deftest conform-args-long-option-equals-separated-value
  (def actual (conform-args ["./configure" "--prefix=$HOME/.local"]))
  (def expect @["./configure" "--prefix" "$HOME/.local"])
  (is (== expect actual)))


(deftest conform-args-combined-short-options
  (def actual (conform-args ["ps" "-auxww"]))
  (def expect @["ps" "-a" "-u" "-x" "-w" "-w"])
  (is (== expect actual)))


(deftest conform-args-handling-beyond-double-dash
  (def actual (conform-args ["ls" "-al" "--" "fun" "-to" "--try=me"]))
  (def expect @["ls" "-a" "-l" "--" "fun" "-to" "--try=me"])
  (is (== expect actual)))


(run-tests!)
