Red [
	Title: "The Remix Grammar"
	Author: "Robert Sheehan"
	Version: 0.2
	Purpose: { The grammar of Remix.
	Some <tags> are followed by the <tag>'s value. }
]

do %lexer.red

END-OF-LINE: [<LINE> | <*LINE>]

END-OF-FN-CALL: [
	END-OF-LINE | <RBRACKET> | <rparen> | <rbrace> | <comma> | <operator>
]

; should never remove <RBRACKET> or <rparen> except with matching left hand term.
END-OF-STATEMENT: [
	[end | END-OF-LINE ] | ahead [<RBRACKET> | <rparen>]
]

program: [
	some [
		<LINE> | end
		| function-definition
		| statement
	]
]

; e.g.
; say if (a) equals (b): 
;	a = b
function-definition: [
	function-signature
	<colon> opt <colon>
	function-statements 
	END-OF-LINE
]

; e.g. from (start) to (finish) do (block)
function-signature: [
	some [
		<word> string!
		|
		<lparen> <word> string! <rparen> 
	]
]

function-statements: [
	ahead block! 
	into block-of-statements
]

block-of-statements: [
	any statement
]

deferred-block-of-statements: [ ; only here because of a difference in code generation
	block-of-statements
]

; functions and blocks can return an expression without the return call
statement: [
	[
		assignment-statement 
		| return-statement
		| redo-statement
		| expression
	]
	END-OF-STATEMENT
]

; e.g. abc : something
assignment-statement: [
	<word> string! 
	<colon> 
	expression
]

; e.g. return a + b
return-statement: [
	<word> "return" opt expression
]

; e.g redo
redo-statement: [
	<word> "redo"
] 

expression: [
	unary-expression not ahead <operator>
	|
	binary-expression
]

; e.g. 4 + a
binary-expression: [
	unary-expression 
	<operator> word!
	expression
]

unary-expression: [
	simple-expression
	|
	<lparen> expression <rparen> 
]

; at the moment a single word is a function call
; after finding the function call we need to see if it should be a variable call instead
simple-expression: [
	list-element-assignment
	| list-element
	| function-call 
	| <word> string!
	| <string> string! 
	| <number> number! 
	| <boolean> logic!
	| literal-list
]

; e.g. a-list [ any ] : value
list-element-assignment: [
	<word> string!
	<LBRACKET> expression <RBRACKET>
	<colon>
	expression
]

; e.g. a-list [3]
list-element: [
	<word> string!
	<LBRACKET> expression <RBRACKET>
	[end | ahead END-OF-FN-CALL]
]

function-call: [
	[
		<word> string! [end | ahead END-OF-FN-CALL]
		|
		2 20 [ ; currently a max of 20 parts to a function call
			<word> string!
			; a literal parameter
			| <string> string! | <number> number! | <boolean> logic! | literal-list

			; the next 4 are block parameters

			| <LBRACKET> ahead block! into [deferred-block-of-statements] <*LINE> <RBRACKET> 
			| ahead block! [into deferred-block-of-statements]
			| <LBRACKET> deferred-block-of-statements <RBRACKET> 
			| <lparen> <LBRACKET> deferred-block-of-statements <RBRACKET> <rparen>

			| <lparen> expression <rparen> 
		]
		[end | ahead END-OF-FN-CALL]
	]
]

literal-list: [
	<lbrace> list <rbrace>
]

key-value: [
	[
		<string> string! 
		| 
		<word> string!
	]
	<colon>
	[
		expression
		|
		<LBRACKET>
		deferred-block-of-statements
		<RBRACKET>
	]
]

list-item: [
	key-value
	|
	expression
	|
	<LBRACKET>
	deferred-block-of-statements
	<RBRACKET>
]

list: [
	list-item any [<comma> list-item]
	|
	none
]