Red [
	Title: "test-grammar"
	Needs: view
]

files: [
	"ex/factorial.rem"
	"ex/factorial2.rem"
	"ex/primes.rem"
	"ex/test1.rem"
	"ex/test2.rem"
	"ex/test3.rem"
	"ex/test4.rem"
	"ex/test5.rem"
	"ex/test6.rem"
	"ex/test7.rem"
	"ex/test8.rem"
	"ex/test9.rem"
	"ex/test10.rem"
	"ex/test11.rem"
	"ex/test12.rem"
	"ex/test13.rem"
	"ex/test14.rem"
	"ex/test15.rem"
	"ex/test16.rem"
	"ex/test17.rem"
	"ex/test18.rem"
	"ex/test19.rem"
	"ex/test20.rem"
	"ex/test21.rem"
	"ex/test22.rem"
	"ex/test23.rem"
	"ex/test24.rem"
	"ex/test25.rem"
	"ex/test26.rem"
	"ex/test27.rem"
	"ex/test28.rem"
	; "ex/drawing.rem"
]

foreach file files [
	command: append copy "remix " file ;"red remix-test.red " file
	call/console/shell command
	; reload the whole interpreter
	; do %remix-grammar-AST.red

	; print ["^/FILENAME:" file]

	; ; print "SOURCE CODE"
	; ; print read file

	; source: append copy "^/" read %standard-lib.rem
	; source: append append source read file copy "^/"

	; first-pass: parse source split-words
	; clean-lex: tidy-up first-pass
	; lex-symbols: spit-out-symbols clean-lex

	; ; print "^/LEX OUTPUT"
	; ; ?? lex-symbols

	; ; print "^/PARSE"
	; ast: parse lex-symbols [collect program]

	; do %transpiler.red

	; ; print "^/TRANSPILED OUTPUT"

	; transpile-functions function-map
	; red-code: transpile-main ast
	; ; print []
	; ; probe red-code

	; print "^/PROGRAM OUTPUT"
	; do red-code
	print "DONE^/"
]