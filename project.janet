(declare-project
  :name "Argy-Bargy"
  :description "A fancy command-line argument parser for Janet"
  :author "Michael Camilleri"
  :license "MIT"
  :url "https://github.com/pyrmont/argy-bargy"
  :repo "git+https://github.com/pyrmont/argy-bargy"
  :dependencies []
  :dev-dependencies ["https://github.com/janet-lang/spork"
                     "https://github.com/pyrmont/testament"])

(declare-source
  :source ["src/argy-bargy.janet"])


# Development

(def project-meta (dyn :project))


(task "dev-deps" []
  (if-let [deps (project-meta :dev-dependencies)]
    (each dep deps
      (bundle-install dep))
    (do (print "no dependencies found") (flush))))


(task "netrepl" []
  (with-dyns [:pretty-format "%.20M"]
   (import spork/netrepl)
   (eval ~(netrepl/server "127.0.0.1" "9365"))))
