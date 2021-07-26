Red [
    needs 'view
    file: %choice-faces.red
    Author: "Mike Parr"
]

; check1-changed: function [] [
;     print ["check1-has changed.  Current state is: " check1/data]
; ]


; drop1-selection: function [] [;;;;;;;;;ok
;     either drop-down1/selected = none [
;         print "drop-down1: no selection yet"
;     ] [
;         print ["Drop-down1: " mold pick drop-down1/data drop-down1/selected]
;     ]
; ]


; postal-selection: function [] [
;     either postal-drop-list/selected = none [
;         print "drop-list - no selection yet"
;     ] [
;         print ["Selected position in postal-drop-list: " postal-drop-list/selected]
;         ;multiply by 2 to get corresponding integer in list
;         print ["Postal cost: " pick postal-drop-list/data postal-drop-list/selected * 2]
;     ]
; ]


; days-textlist-value: function [] [           ;-- handle no selection         
;     either days-text-list/selected = -1 [
;         print "text-list: no selection yet"
;     ] [ 
;         print ["text-list: " pick days-text-list/data days-text-list/selected]
;     ]
; ]


view [
    a: radio "abced" data [true]
    radio "HEHE" 

]