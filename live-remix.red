Red [needs: view]

do %remix-grammar-AST.red
do %transpiler.red

call-back: function [
	event [word!] 
	match? [logic!] 
	rule [block!] 
	input [series!] 
	stack [block!]
	/extern successful-parse
][
	if all [event = 'end match?][
		successful-parse: true
	]
	true
]

prin: function [
	{ Replace the standard "prin" function, which used in the built-in show functions. }
	output [string!]
][
	append output-area/text output
]

run-remix: function [
	{ Execute the remix code in "code". 
	  Put the output in the output area. }
	code [string!]
	/running-first-time
	/extern successful-parse
][
	; N.B. remember to include the standard-lib
	; source: append (append (copy "^/") (read %standard-lib.rem)) "^/"
	source: copy "^/"
	source: append (append source code) "^/"
	; get the lexer output
	first-pass: parse source split-words
	clean-lex: tidy-up first-pass
	lex-symbols: spit-out-symbols clean-lex
	; parse
	successful-parse: false
	ast: parse/trace lex-symbols [collect program] :call-back
	if not successful-parse [
		return
	]
	; transpile
	transpile-functions function-map
	red-code: transpile-main ast
	; run
	; use output-area only after it has been defined
	if not running-first-time [
		output-area/text: copy ""
	]
	do red-code
]

;;; code for writing to a file

write-file: function [/extern memory-list] [
	; save %Code.red memory-list/(length? memory-list)

	either (length? memory-list) = 0 [
		print "No Versions Saved"
	] [
		; save %Code.red memory-list/(length? memory-list)
		; write/lines %Code.red memory-list/(length? memory-list)
		; write/lines %testfile.txt ["a line" "another line"] EXAMPLE
		print "TO BE COMPLETED"	
	]
]

;;; code for version manipulation

new-line: 1 ; the 'global' amount of lines in the commands text area
detection-rate: 5 ; default autosaving rate
save-mode: true ; boolean to consider if autosaving is desired

memory-list: [] ; series of strings to store the commands at different verseions

; saving a current version into the list
save-text: function [text][
	append memory-list (copy text)
	exit
]

; function to display the selected version
version-selection: function [] [
	either version-select/selected = none [
		print "Nothing selected"
	] [
		commands/text: copy (memory-list/(to-integer (version-select/selected))) ; allows non-integer values
	
		; update output of associated code
		attempt [
			refresh-panels 
		]
	]
]

; function to display the latest TODO refine the function above with it to make this file less cluttered
latest-version: function [] [
	either (length? memory-list) = 0 [
		print "No Versions Made"
	] [
		commands/text: copy (memory-list/(to-integer (length? memory-list))) ; allows non-integer values
		version-select/selected: (length? memory-list)
		; update output of associated code
		attempt [
			refresh-panels 
		]
	]
]

; function to display the next/previous function TODO refine this function with the two above for less clutter
version-change: function [change] [
	either (length? memory-list) = 0 [
		print "No Versions Made"
	] [
		; ensure a version is selected in the first place
		either version-select/selected = none [
			version-select/selected: 1
		] [
			either change = "+" [
				if (to-integer (version-select/selected)) < (length? memory-list) [
					version-select/selected: ((version-select/selected) + 1)
				]
			] [
				if (to-integer (version-select/selected)) > 1 [
					version-select/selected: ((version-select/selected) - 1)
				]
			]
		]
		commands/text: copy (memory-list/(to-integer (version-select/selected) ))
		attempt [
			refresh-panels 
		]
	]
]

; function to check if a new version should be saved, given the parameters provided
count-enters: function[text /extern new-line /extern detection-rate /extern save-mode] [
	length: (length? split text newline)
	if save-mode = true [
		if (length >= (new-line + detection-rate)) [
			new-line: length
			return true
		] 
		if (length <= (new-line - detection-rate))[
			new-line: length
			return true
		]
	]
	return false
]

; function to modify the save rate
change-detection-rate: function[/extern detection-rate /extern save-mode][
	either save-rate/text = "Never" [
		save-mode: false
	] [
		save-mode: true
		attempt [
			detection-rate: to-integer save-rate/text
		]
	]
	
]

;;; functions to detect enter keystroke

command-lines: 1
enter-key-pressed: function[text /extern command-lines][
	length: (length? split text newline)
	if (length <> command-lines)[
		command-lines: length
		return true
	]
	return false	
]

;;; overriding the function in transpiler.red

add-check: false
add-function: function[text /extern add-check][
	either add-check [
		add-check: false
	] [
		add-check: true
		formatter: copy "^/^/; newly generated function^/"
		formatter-for-text: copy ""
		append formatter copy text
		append formatter ":^/"
		append formatter-for-text tab
		append formatter-for-text "showline "
		append formatter-for-text dbl-quote
		append formatter-for-text copy text
		append formatter-for-text dbl-quote

		replace/all formatter "_" " "
		replace/all formatter "|" "(?)"
		replace/all formatter-for-text "_" " "
		replace/all formatter-for-text "|" "TBC"

		append commands/text formatter
		append commands/text formatter-for-text

	]
]

create-red-function-call: function [
	{ Return the red equivalent of a function call. }
	remix-call "Includes the name and parameter list"
][
	the-fnc: select function-map remix-call/fnc-name
	if the-fnc = none [
		; check if the name can be pluralised.
		either (the-fnc: pluralised remix-call/fnc-name) [
			print ["Careful:" remix-call/fnc-name "renamed." ]
		][
			; print ["Error:" remix-call/fnc-name "not declared."]
			; function: copy remix-call/fnc-name
			add-function remix-call/fnc-name
			return ; changed from quit for live coding
		]
	]
	if all [ ; check if it is a recursive call
		the-fnc/red-code = none
		the-fnc/fnc-def = []
	][ ; at the moment no reference parameters in recursive calls
		red-stmt: to-word remix-call/fnc-name
		red-params: create-red-parameters remix-call/actual-params
		return compose [(red-stmt) (red-params)]
	]
	either the-fnc/red-code [ ; an ordinary function call
		red-stmt: first the-fnc/red-code
		either (red-stmt = 'get-item) or (red-stmt = 'set-item) [
			red-params: deal-with-word-key remix-call/actual-params
		][
			red-params: create-red-parameters remix-call/actual-params
		]
		return compose [(red-stmt) (red-params)]
	][ ; a reference function call
		copy-fnc: copy/deep the-fnc/fnc-def
		formals: the-fnc/formal-parameters
		actual-parameters: copy []
		bind-word: none
		forall formals [
			formal-param: first formals
			actual-param: pick remix-call/actual-params (index? formals)
			either (first formal-param) = #"#" [
				if actual-param/type <> "variable" [
					print "Error: The actual parameter for a reference parameter must be a variable."
					quit
				]
				bind-word: to-word actual-param/name ; doesn't matter if more than one
				replace/all/deep copy-fnc (to-word formal-param) bind-word
				; there is a potential problem here
				; an existing variable in the function code could have the same name
				; as the actual parameter
			][
				append actual-parameters actual-param
			]
		]
		red-params: create-red-parameters actual-parameters
		compose/deep [do reduce [do bind [(copy-fnc)] quote (bind-word) (red-params)]]
	]
]

; run (load into Red runtime) the standard remix library
stdlib: read %standard-lib.rem
run-remix/running-first-time stdlib

; Setting up the graphics area by overriding the associated func
setup-paper: func [
    { Overridden version - Prepare the paper and drawing instructions.
      At the moment I am using a 2x resolution background for the paper. }
    colour [tuple!]
    width [integer!]
    height [integer!]
][
    paper-size: as-pair width height
    background-template: reduce [paper-size * 2 colour]
    background: make image! background-template
		paper/color: colour
		do [
				all-layers/1: compose [image background 0x0 (paper-size)]
				paper/draw: all-layers
				paper/rate: none
		]
    none
]

; Allowing functions to be redefined temporarily so that re-execution of code
; does not create trouble
insert-function: function [
    { Overridden version - Insert a function into the function map table }
    func-object [object!]   {the function object}
][
    name: to-function-name func-object/template
    put function-map name func-object
]

; loading the graphics statements which should be executed everytime
precursor-statements: read %precusor-graphics-statements.rem

; Block containing the points clicked on in graphics area
; Each element inside is a representation of a coordinate
; like: {0, 0}
points-clicked-on: make block! 0

refresh-panels: func [
		{ Clears the input text and graphics panels and then executes the remix 
		code in the input panel }
][
		; first execute the necessary graphics related statements
		run-remix precursor-statements
		; clean the graphics area
		draw-command-layers: copy/deep [[]]
		all-layers/2: draw-command-layers
		; run the code
		run-remix commands/text 
]

visualize-clicked-points: func [
		{ Visualize the points based on the number of points clicked }
		x [integer!]   {x-coordinate clicked on}
		y [integer!]   {y-coordinate clicked on}
	][
		append points-clicked-on rejoin ["{" x ", " y "}"]
		clear commands/text ; clear the input text panel
		point-clicked-on-radius: 2
		case [
			; plot a point
			(length? points-clicked-on) = 1 [
				commands/text: rejoin ["draw circle of (" point-clicked-on-radius ") at (" points-clicked-on/1 ")"]
			]
			; draw a line by joining two points
			(length? points-clicked-on) = 2 [
				commands/text: rejoin ["draw line from (" points-clicked-on/1 ") to (" points-clicked-on/2 ")"]
			]
			; draw a polygon
			(length? points-clicked-on) > 2 [
				; format the points as remix code
				points-of-shape: replace/all (rejoin points-clicked-on) "}" "},^/"
				; remove the last comma in the `points-of-shape` string (the newline
				; following the comma is unaffected)
				remove at points-of-shape ((length? points-of-shape) - 1)
				commands/text: rejoin ["shape1 : make shape of {^/" points-of-shape "}^/^/" "shape1 [size] : 1^/" "draw (shape1)"]
			]
		]
		refresh-panels
]


view/tight [
	title "Live"
	commands: area 
		400x600 
		on-key-up [
			; check if a a line is added or lost
			if (enter-key-pressed commands/text) [
				either error? result: try [refresh-panels] [
					; if valid command
					attempt [
						refresh-panels
					]
				] [
					; if line added is above threshold
					if count-enters commands/text [
						attempt [
							save-text commands/text
							append version-select/data (to-string (length? memory-list))
						]
					]
				]
			]
		]

	output-area: area 
		400x600

	paper: base 400x600 on-time [do-draw-animate]
	on-down [
		visualize-clicked-points event/offset/x event/offset/y
		; add line count check for length
		if count-enters commands/text [
			attempt [
				save-text commands/text
				append version-select/data (to-string (length? memory-list))
			]
		]
	]

	; setting up the graphics panel so that "on standard paper" will not
	; necessarily need to be called before the attempt to generate any graphics
	do [setup-paper 255.255.255 400 600]

	version-area: panel 400x220 255.0.0 [
		below 
		save-rate: drop-down 120 "Save Rate" data ["5" "10" "15" "20" "Never"] on-change [
			change-detection-rate
		]
		version-select: drop-down 120 "Code Versions" data []
		show-version: button 120 "Show Selected Version" [version-selection]

		empty: text
		new-name: area 120x20
		rename-name: button 120 "Name Version" [
			save-text commands/text
			append version-select/data (copy new-name/text)
			]
		return
		latest: button 120 "Latest" [latest-version]
		next-v: button 120 "(Next)" [version-change "+"]
		previous-v: button 120 "(Previous)" [version-change "-"]
		empty: text
		write: button 120 "Write to File" [write-file]
	]
]
