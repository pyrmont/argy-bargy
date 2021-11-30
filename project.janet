(declare-project
  :name "Argy-Bargy"
  :description "A fancy command-line argument parser for Janet"
  :author "Michael Camilleri"
  :license "MIT"
  :url "https://github.com/pyrmont/argy-bargy"
  :repo "git+https://github.com/pyrmont/argy-bargy"
  :dependencies []
  :jeep/tree ".jeep"
  :jeep/dev-dependencies ["https://github.com/pyrmont/testament"])

(declare-source
  :source ["src/argy-bargy.janet"])
