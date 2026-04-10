; Macro file for sfx_gen.asm

; Call a MOS API function
macro MOSCALL arg1
	ld a, arg1
	rst.lil $08
endmacro

; Wait for Vertical Blanking Interval (VSYNC)
macro V_SYNC
    ld a, 23
    rst.lil $10
    ld a, 0
    rst.lil $10
    ld a, $C3
    rst.lil $10
endmacro

; Clear the screen
macro CLS
	ld a, 12                    ; clear screen
	rst.lil $10
endmacro

; Set Screen Mode
macro SET_MODE mode
	ld a, 22					; set mode...
	rst.lil $10
	ld a, mode					; to mode
	rst.lil $10
endmacro

; Set Text Foreground Colour
macro SET_TXT_COL col
	ld a, 17					; set text colour
	rst.lil $10
    ld a, col                   ; text colour to use		    
	rst.lil $10
endmacro

; Set Text Background Colour
macro SET_TXT_BG_COL col
	ld a, 17					; set text colour
	rst.lil $10
    ld a, col                   ; background colour to use
    add a, 128					    
	rst.lil $10
endmacro

; Disable Graphics Scaling
macro SET_NONSCALED_GRAPHICS
    ld a, 23                   
    rst.lil $10
    ld a, 0
    rst.lil $10
    ld a, 192
    rst.lil $10
    ld a, 0
    rst.lil $10
endmacro

macro HIDE_CURSOR
	ld a, 23					
	rst.lil $10
	ld a, 1		
	rst.lil $10
    ld a, 0		
	rst.lil $10
endmacro

macro SHOW_CURSOR
	ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a, 1
    rst.lil $10
endmacro

macro TABTO x, y
    ld a, 31
    rst.lil $10
    ld a, x
    rst.lil $10
    ld a, y
    rst.lil $10
endmacro

macro Show_Sprite
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 11            ; Command: Update sprites to GPU
    rst.lil $10
endmacro

macro Hide_Sprite
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 12            ; Hide Sprite
    rst.lil $10
endmacro

macro Select_Sprite_8bit sid
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 4             ; Command: Select Sprite
    rst.lil $10
    ld a, sid            ; Sprite Id
    rst.lil $10
endmacro

; select buffer 8bit
macro Select_Buffer_8bit bid
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 0
    rst.lil $10
    ld a, bid
    rst.lil $10
endmacro

macro Activate_amount_sprites amount 
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 7            ; Command: Activate the amount of sprites
    rst.lil $10
    ld a, amount            ; Amount of sprites to activate
    rst.lil $10
endmacro

macro Add_Frame_To_Sprite bid
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 6            ; Command: Add frame to sprite
    rst.lil $10
    ld a, bid            ; Bitmap id, Default frame
    rst.lil $10
endmacro

macro Load_Next_Frame
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 8       ; Command: Load the next frame
    rst.lil $10
endmacro

macro Update_GPU
    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 15           ; Command: update gpu
    rst.lil $10
endmacro

; -----------------------------------------------------------------------------
; COLOUR CONSTANTS
; -----------------------------------------------------------------------------
black:          equ     0
red:            equ     1
green:          equ     2
yellow:         equ     3
blue:           equ     4
magenta:        equ     5
cyan:           equ     6
grey:           equ     7
dark_grey:      equ     8
bright_red:     equ     9
bright_green:   equ     10
bright_yellow:  equ     11
bright_blue:    equ     12
bright_magenta: equ     13
bright_cyan:    equ     14
bright_white:   equ     15

macro MAKEBUFFEREDBITMAP id, width, height, data, colourCode

	; create buffer

	.db 	23,0,$A0 							; write block
	.dw 	64000 + id 							; ID (word)
	.db 	3	 								; 'create' command
	.dw 	width *  height / 8 				; data size = length 320 x 64 / 8 bits as b/w Decode_Room_Metadata

	; clear in case VDP already has one

	.db 	23,0,$A0 							; write block
	.dw 	64000 + id 							; ID (word)
	.db 	2	 								; 'create' command

	; write data to the buffer

	.db 	23,0,$A0 							; write block
	.dw 	64000 + id 							; ID (word)
	.db 	0	 								; 'write' command

	.dw 	width *  height / 8 				; data size = length 320 x 64 / 8 bits as b/w
			
	incbin data

	; convert the buffer to a single colour bitmap

	.db 	18,0 								; select colour to use
	.db 	colourCode							; 1 of 64 possible colours from palette

	; convert buffer block to bitmap with ID

	.db 	23,27,$20 							; select buffer bitmap to use
	.dw 	64000 + id 							; ID (word)

	; create a bitmap from that ID

	.db 	23,27,$21 							; create bitmap from buffer
	.dw 	width, height				 		; width, height (both words)
	.db 	2 		

endmacro