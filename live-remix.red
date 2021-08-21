Red [needs: view]

do %remix-grammar-AST.red
do %transpiler.red

last-working: copy ""

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

grid-snap: 25
grid-snap-active: true

grid-generater-code: function [
	/extern grid-snap [integer!]  {Snap change wanted}
	/extern grid-snap-active [logic!]  {If we want the snap to happen}
] [
	; if grid-snap-active [
	; 	res: rejoin ["^/circle : make shape of {^/^-{-0.5, 0.5},^/^-{0.5, 0.5},^/^-{0.5, -0.5},^/^-{-0.5, -0.5}^/} with size 5^/starting with [x: 0] repeat " (to-string (400 / grid-snap)) " times^/^-starting with [y : 0] repeat " (to-string (600 / grid-snap)) " times^/^-^-plot (circle) at center with (x) and (y)^/^-^-y : y + " (to-string grid-snap) "^/^-x : x + " (to-string grid-snap) "^/plot (shape) at center with (x) and (y):^/^-shape [position] : {x, y}^/^-draw (shape)"]
	; 	return res
	; ]
	return ""	
]

run-remix: function [
	{ Execute the remix code in "code". 
	  Put the output in the output area. }
	code [string!]
	/running-first-time
	/extern successful-parse
][
	; append the remix code that generates the cross which appears in the centre of the
	; graphical area
	centre-crosshair-remix-code: "^/draw line from ({-5, 5}) to {5, -5}^/draw line from ({-5, -5}) to {5, 5}"
	code: rejoin [code centre-crosshair-remix-code grid-generater-code]
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
	update-line-count
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

; updates the global line count
update-global-line: function [
	/extern new-line [integer!] {global number of lines}
] [
	length: (length? split commands/text newline)
	new-line: length
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

; function which updates the line count, if for some reason it did not happen when a verseion changes
update-line-count: function[
	/extern command-lines [integer!] { the number of lines  used for version control}
	/extern new-line [integer!] { the global number of lines}
	 ][
	length: (length? split commands/text newline)
	command-lines: length
	new-line: length
]

command-lines: 1
; returns if last keystroke is enter
enter-key-pressed: function[text /extern new-line][
	length: (length? split text newline)
	if (length <> new-line)[
		new-line: length ; update new length
		return true
	]
	return false	
]

;;; overriding the function in transpiler.red

add-check: false ; variable to only append once
add-function: function[text /extern add-check][
	either add-check [
		add-check: false
	] [
		add-check: true

		formatter: copy "^/^/; recently generated function^/"
		formatter-for-text: copy ""
		append formatter-for-text tab
		append formatter-for-text "showline "
		append formatter-for-text dbl-quote

		; if the function has parameters
		either ((find text "|") <> none )[
			lines: split commands/text newline
			; find the line which contains the new function
			foreach line lines [
				if ((find line "(") <> none)[
					letter: charset [#"A" - #"Z" #"a" - #"z"  "0123456789" ]
					test: copy line
					replace test ["(" any[letter] ")"] "|" ; replace the parameter aspect
					replace/all test " " "_"
					if (test == text)[ ; check to ensure the correct line is found
						append formatter copy line
						append formatter ":^/"
						append formatter-for-text copy line
						replace/all formatter-for-text "(" ""
						replace/all formatter-for-text ")" ""
						break
					]
				]
			]
		] [
			append formatter copy text
			append formatter ":^/"
			append formatter-for-text copy text
		]

		; replace previous comment
		replace/all commands/text "^/; recently generated function" ""
		replace/all formatter "_" " "

		; append formatter-for-text " made"
		append formatter-for-text dbl-quote
		replace/all formatter-for-text "_" " "

		; append function declaration to command area
		append commands/text formatter
		append commands/text formatter-for-text
	]
]

;; returns true if the current command area is filled and unique to existing versions
unique-and-filled: function[text /extern memory-list][
	if (text = "")[ ; check if empty
		return false
	]
	;;return here
	text-copy: copy text
	replace/all text-copy newline ""
	foreach memory memory-list [ ; check uniqueness
		memory-copy: copy memory
		replace/all memory-copy newline "" 
		if (memory-copy = text-copy) [ ; compare while ignoring new lines
			return false
		]
	]
	return true
]

; redefine existing function to generate function
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
			if (enter-key-pressed commands/text) [ ; check if enter keystroke was pressed
				add-function remix-call/fnc-name
			]
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

draw-line: function [
    { Overridden version - Draw a line from start to finish. }
    start [hash! map!] "with x and y"
    finish [hash! map!] "with x and y"
][
    start: point-to-pair start
    finish: point-to-pair finish
		; offsetting the start and finish points to make them relative to the centre
		; of the graphical area
    start/1: start/1 + 200
    start/2: start/2 + 300
    finish/1: finish/1 + 200
    finish/2: finish/2 + 300
    either draw-layer = 0 [
        line-command: compose [line (start * 2) (finish * 2)]
        draw background append copy background-pen line-command
    ][
        line-command: compose [line (start) (finish)]
        append/only draw-command-layers/:draw-layer line-command
    ]
    none
]

draw-circle: function [
    { Overridden version - Draw a circle. }
    radius [number!]
    centre [hash! map!] "x, y"
][
    centre: point-to-pair centre
		; offsetting the centre to make them relative to the centre
		; of the graphical area
    centre/1: centre/1 + 200
    centre/2: centre/2 + 300
    either draw-layer = 0 [
        circle-command: reduce ['circle centre * 2 radius * 2]
        draw background append copy background-pen circle-command
    ][
        circle-command: reduce ['circle centre radius]
        append/only draw-command-layers/:draw-layer circle-command
    ]
    none
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

; Block containing (it 'remembers') the points clicked on in graphics area
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
		; clear the remembered points clicked on if the autogenerated code has been deleted by the user
		if (
			((length? find live-commands/text "draw circle of (") = none)
			and 
			((length? find live-commands/text "draw line from (") = none)
			and
			((length? find live-commands/text "auto-generated-shape : make shape of {^/") = none)
		) [
			clear points-clicked-on
		]
		; run the code
		run-remix (rejoin [commands/text "^/" live-commands/text "^/"]) 
]

; corresponds to the radio buttons under "Select the shape drawing method"
shape-drawing-method: "closed-shape"
; corresponds to the radio buttons under "Select the shape drawing method"
shape-interaction-method: "draw"

change-grid-size: function [
	{ Change grid snap rating}
	/extern grid-snap [integer!]  {Snap change wanted}
	/extern grid-snap-active [logic!]  {If we want the snap to happen}
] [
	either grid-size/text = "None" [
		grid-snap-active: false
		grid-snap: 1
	][
		grid-snap-active: true
		grid-snap: to-integer (copy grid-size/text)
	]
	; grid-generater-code
	refresh-panels
]

visualize-clicked-points: func [
		{ Visualize the points based on the number of points clicked }
		x [integer!]   {x-coordinate clicked on}
		y [integer!]   {y-coordinate clicked on}
		
][
	; offset the coordinates so that they are relative to the centre of the 
	; the graphical area
	x: x - 200
	y: y - 300
	; Synchronize the points written in code with the 'remembered' points
	case [
		(length? points-clicked-on) = 1 [
			; Synchronize the first point written in code with the 'remembered' first point
			; The statement from which the center is to be extracted will look like the following:
			; draw circle of (2) at ({190, 124})

			if (not ((length? live-commands/text) = none)) [
				text-to-process: copy live-commands/text
				; start extracting the code auto-generated when points are clicked on
				text-to-process: find text-to-process ") at ("
				if (not ((length? text-to-process) = none)) [
					; find the opening bracket of the points list in remix code
					text-to-process: find text-to-process "{"
					reverse text-to-process
					; locate where the point description ends
					text-to-process: find text-to-process ")}"
					; remove the closing bracket 
					remove/part text-to-process 1
					reverse text-to-process
					points-clicked-on: copy []
					append points-clicked-on text-to-process ; update the 'remembered' center
				]
			]
		]
		(length? points-clicked-on) = 2 [
			; to-complete
		]
		(length? points-clicked-on) > 2 [
			; Synchronize the points written in code with the 'remembered' clicked points
			; The list of points will looks like the following:
			; {
			; {x1, y1},
			; {x2, y2},
			; ... more points (no comma at the end)
			; }
			if (not ((length? live-commands/text) = none)) [
				text-to-process: copy live-commands/text
				; start extracting the code auto-generated when points are clicked on
				text-to-process: find text-to-process "auto-generated-shape : make shape of {"
				if (not ((length? text-to-process) = none)) [
					; find the opening bracket of the points list in remix code
					text-to-process: find text-to-process "{"
					; remove the first bracket and the following newline character
					remove/part text-to-process 2
					reverse text-to-process
					; locate where the list of points ends
					text-to-process: find text-to-process "}^/"
					; remove the closing bracket and the newline
					remove/part text-to-process 2
					reverse text-to-process
					synced-points: split text-to-process ",^/"
					points-clicked-on: copy synced-points ; update the 'remembered' points
				]
			]
		]
	]

	either (shape-interaction-method = "draw") [
		; process the latest clicked point
		point-clicked-on-radius: 2
		either (shape-drawing-method = "closed-shape") [
			append points-clicked-on rejoin ["{" (to-string (round/to x grid-snap)) ", " (to-string (round/to y grid-snap)) "}"]

			clear live-commands/text 
			case [
				; plot a point
				(length? points-clicked-on) = 1 [
					append live-commands/text rejoin ["draw circle of (" point-clicked-on-radius ") at (" points-clicked-on/1 ")"]
				]
				; draw a line by joining two points
				(length? points-clicked-on) = 2 [
					append live-commands/text rejoin ["draw line from (" points-clicked-on/1 ") to (" points-clicked-on/2 ")"]
				]
				; draw a polygon
				(length? points-clicked-on) > 2 [
					; format the points as remix code
					points-of-shape: replace/all (rejoin points-clicked-on) "}" "},^/"
					; remove the last comma in the `points-of-shape` string (the newline
					; following the comma is unaffected)
					remove at points-of-shape ((length? points-of-shape) - 1)
					append live-commands/text rejoin ["auto-generated-shape : make shape of {^/" points-of-shape "}^/^/" "auto-generated-shape [size] : 1^/" "draw (auto-generated-shape)"]
				]
			]
		][
			; when shape-drawing-method = "circle"
			append points-clicked-on rejoin ["{" (to-string (round/to x grid-snap)) ", " (to-string (round/to y grid-snap)) "}"]
			clear live-commands/text
			case [
				; define the center
				(length? points-clicked-on) = 1 [
					append live-commands/text rejoin ["draw circle of (" point-clicked-on-radius ") at (" points-clicked-on/1 ")"]
				]
				; draw circle as radius is now provided
				(length? points-clicked-on) = 2 [
					; extract x-coordinate of first point
					x1: copy points-clicked-on/1
					x1: find/tail x1 "{"
					reverse x1
					x1: find/tail x1 ","
					reverse x1
					x1: to-integer x1

					; extract y-coordinate of first point
					y1: copy points-clicked-on/1
					y1: find/tail y1 ", "
					reverse y1
					y1: find/tail y1 "}"
					reverse y1
					y1: to-integer y1
					
					x2: x
					y2: y
					radius:  to-integer (((x1 - x2) ** 2) + ((y1 - y2) ** 2)) ** 0.5
					append live-commands/text rejoin ["draw circle of (" radius ") at (" points-clicked-on/1 ")"]
					clear points-clicked-on
				]
			]
		]
	][
		append commands/text rejoin ["^/^/replicated-shape : based on (" shapes-dropdown/text ")^/replicated-shape [position] : {" (x + 200) ", " (y + 300) "}^/draw (replicated-shape)"]
	]
	refresh-panels
]

use-autogenerated-code: func [
	name [string!] {the name of the shape}
] [
	if (commands/text = commands-default-text) [
		clear commands/text
	]
	live-commands/text 
	formatted-name: copy (replace/all name " " "-") ; remove spacing
	replace/all live-commands/text "auto-generated-shape" formatted-name ; replace template with name
	commands/text: rejoin [commands/text "^/^/" live-commands/text]
	clear live-commands/text
	refresh-panels
]

clear-temp-code-area: func [] [
	live-commands/text: copy ""
	clear points-clicked-on
	refresh-panels
]

clear-permanent-code-area: func [] [
	commands/text: copy ""
	refresh-panels
]

update-polygons-in-code: func [] [
		; extract names of all polygons present in the commands area
		lines-of-command: split commands/text newline
		polygon-names: copy []
		foreach line-of-command lines-of-command [
			polygon-search-token: find line-of-command " : make shape of"
			; print polygon-search-token
			if (not (polygon-search-token = none)) [
				; parse line-of-command [copy a-polygon to [" : make shape of" | " :make shape of" | ":make shape of"]]
				a-polygon: replace line-of-command polygon-search-token ""
				append polygon-names a-polygon
			]
		]
		shapes-dropdown/data: polygon-names
]

; for user's code area
commands-default-text: copy "Type your code here.^/"
; for auto code generation area 
live-commands-default-text: copy "Interactive auto generated code will appear here.^/"

view/tight [
	title "Live"

	below
	panel-1: panel 1200x600 158.167.247 [
		below
		commands: area 
			400x300 
			"Type your code here.^/"
			on-focus [
				if (commands/text = commands-default-text) [
					commands/text: copy ""
				]
			]
			on-unfocus [
				if (commands/text = "") [
					commands/text: copy commands-default-text
				]
			]
			on-key-up [
				either error? result: try [refresh-panels] [
					try [
						run-remix last-working
						colour-area/color: 255.0.0
					]
				] [
					; check if there is sufficient amount of lines added/removed
					if count-enters commands/text [
						; check if the code is 'unique'
						if unique-and-filled commands/text [
							; save the text and appending it as an option for user selection
							attempt [
								save-text commands/text
								append version-select/data (to-string (length? memory-list))
							]
						]
					]
					last-working: copy commands/text
					colour-area/color: 25.255.25
				]
				update-global-line


			]

		auto-code-generation-panel: panel 400x100 247.247.158 [
			text 400x30 "AUTO-GENERATED CODE BELOW (Write your code above this only)"
			return
			name: text 30x20 "Name:"
			new-shape-name: area 120x20
			button "Use auto-generated code" [
				; check if the shape is a polygon
				either (length? points-clicked-on) > 2 [
					; check if a name is provided
					either (none? new-shape-name/text ) [
						alert ["Please provide a name"]
					] [
						use-autogenerated-code new-shape-name/text ; bring created content to pernament area
						; save the text into the dropdown and memory
						save-text commands/text
						append version-select/data (new-shape-name/text)
						new-shape-name/text: copy "" ; reset name field
						last-working: copy commands/text
					]				
				] [
					use-autogenerated-code "" ; bring created content to pernament area
					; save the text into the dropdown and memory
					save-text commands/text
					append version-select/data (to-string (length? memory-list))
				]
			]
		]
		
		live-commands: area
			400x250
			live-commands-default-text
			on-key-up [
				attempt [
					refresh-panels 
				]
			]

		return
		across
		paper: base 400x600 on-time [do-draw-animate]
		on-down [
			visualize-clicked-points event/offset/x event/offset/y
		]

		; setting up the graphics panel so that "on standard paper" will not
		; necessarily need to be called before the attempt to generate any graphics
		do [setup-paper 255.255.255 400 600]

		below
		version-area: panel 360x220 247.158.158 [
			; below 
			text "Save Rate"
			across
			save-rate: drop-down 120 "5" data ["5" "10" "15" "20" "Never"] on-change [
				change-detection-rate
			]
			text 70x30 ""
			colour-area: panel 50x50 25.255.25

			return
			text "Version Selected"
			across
			version-select: drop-down 120 "None Made" data [] on-change [
				version-selection
			]
			return
			new-name: area 120x20
			rename-name: button 120 "Name Version" [
				save-text commands/text
				append version-select/data (copy new-name/text)
			]
			return
			next-v: button 120 "(Next)" [version-change "+"]
			previous-v: button 120 "(Previous)" [version-change "-"]
			return
			latest: button 120 "Latest" [latest-version]

			; write: button 120 "Write to File" [write-file]
		]

		text "============================================="

		live-points-area: panel 360x300 158.247.176 [
			text "Select the shape interaction method"
			return
			shape-interaction-panel: panel 340x100 247.158.158 [
				radio "draw-shape" on-down [
					shape-interaction-method: "draw"
					shapes-dropdown/enabled?: false
					close-shape/enabled?: true
					circle-shape/enabled?: true
					] data [true]
				radio "replicate-shape" on-down [
					shape-interaction-method: "replicate" 
					shapes-dropdown/enabled?: true
					close-shape/enabled?: false
					circle-shape/enabled?: false
				] 
				return
				shapes-dropdown: drop-down 120 "Choose shape" data [] disabled on-down [update-polygons-in-code]
			]
			return
			text "Select the shape drawing method"
			return
			close-shape: radio "closed-shape" on-down [shape-drawing-method: "closed-shape" clear points-clicked-on] data [true]
			circle-shape: radio "circle" on-down [shape-drawing-method: "circle" clear points-clicked-on]
			return 
			button "Clear temporary code area" [clear-temp-code-area]
			button "Clear permanent code area" [clear-permanent-code-area]
			return
			text "Grid Size"
			across
			grid-size: drop-down 120 "25" data ["10" "25" "50" "None"] on-change [
				change-grid-size
			]
		]
	]

	panel-2: panel 1200x100 158.167.247 [
		output-area: area 
			1180x80
	]


]
