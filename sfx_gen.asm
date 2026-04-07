include "sfx_macros.inc"

    .assume adl=1
    .org $40000

    jp start_here

    .align 64
    .db "MOS",0,1   

; --- Constants ---
MAX_SELECTION:  EQU 16
COLUMN_INPUT:   EQU 24

; --- Variables ---
selection_mode: db 0
cursor_y_pos:   dw 10   ; start position
cursorFrame:    db 10

; Volume Envelope (Command 6)
venv_type:       db 1
venv_attack:     dl 400
venv_decay:      dl 100
venv_sustain:    db 100
venv_release:    dl 2000

; Frequency Envelope (Command 7)
fenv_count:     db 2        ; Number of phases
fenv_control:   db 1        ; Control byte (0=once, 1=loop)
fenv_step:      dl 30       ; Step length (ms)
fenv_p1_adj:    dl 10       ; Phase 1: Adjustment per step
fenv_p1_step:   dl 50       ; Phase 1: Number of steps
fenv_p2_adj:    dl -10      ; Phase 2: Adjustment per step
fenv_p2_step:   dl 50       ; Phase 2: Number of 

; --- Sound Parameter Block ---
chan_val:       db 0
vol_val:        db 60          
freq_val:       dl 440
dur_val:        dl 1500

; Input Buffer
text_buffer:    blkb 16, 0

;-------------
; Strings
;------------
msg_title:      db "== Agon SFX Generator ==", 13, 10, 0
msg_title_ul:   db "========================", 0

msg_venv_hdr:   db "VOLUME ENVELOPE    ", 0
msg_hdr_ul:     db "---------------------", 0
msg_venv_type:  db ": Type     (0-2)   :", 0
msg_venv_att:   db ": Attack   (ms)    :", 0
msg_venv_dec:   db ": Decay    (ms)    :", 0
msg_venv_sus:   db ": Sustain  (0-127) :", 0
msg_venv_rel:   db ": Release  (ms)    :", 0

msg_fenv_hdr:   db "FREQUENCY ENVELOPE ", 0
;msg_hdr_ul:    db "-------------------", 0
msg_fenv_cnt:   db ": Phases   (1-4)   :", 0
msg_fenv_ctrl:  db ": Control  (0-1)   :", 0
msg_fenv_step:  db ": Step Len (ms)    :", 0
msg_fenv_p1a:   db ": P1 Adjust        :", 0
msg_fenv_p1s:   db ": P1 Steps         :", 0
msg_fenv_p2a:   db ": P2 Adjust        :", 0
msg_fenv_p2s:   db ": P2 Steps         :", 0

msg_note_hdr:   db "SOUND STATEMENT    ", 0
;msg_hdr_ul:    db "-------------------", 0
msg_chan:       db ": Channel  (0-2)   :", 0
msg_vol:        db ": Volume   (0-127) :", 0
msg_freq:       db ": Freq     (Hz)    :", 0
msg_dur:        db ": Duration (ms)    :", 0

msg_play:       db ": [PLAY SOUND]     :", 0
msg_play_but:   db "play", 0
;msg_hdr_ul:    db "-------------------", 0

msg_footer_hdr:   db "== Instructions ==", 0
msg_footer_ul:    db "==================", 0

msg_footer_0:     db "Use Cursor `Up' & `Down' keys to select the value to edit.", 0
msg_footer_1:     db "Press `Enter' Key to select `Edit' mode.", 0
msg_footer_2:     db "Note: ", 0
msg_footer_3:     db "the cursor box will be cyan when in edit mode.", 0
msg_footer_4:     db "Input your new Value.", 0
msg_footer_5:     db "Press `Enter' key again to save the value and exit `Edit' mode.", 0
msg_footer_6:     db "Finally move the cursor box to `[PLAY SOUND]' and press `Enter'.", 0

parameter_table:
    ; Volume Envelope (0-4)
    db COLUMN_INPUT
    db 10
    db 1
    dl venv_type
    db COLUMN_INPUT
    db 11
    db 2
    dl venv_attack
    db COLUMN_INPUT
    db 12
    db 2
    dl venv_decay
    db COLUMN_INPUT
    db 13
    db 1
    dl venv_sustain
    db COLUMN_INPUT
    db 14
    db 2
    dl venv_release

    ; Frequency Envelope (5-11)
    db COLUMN_INPUT
    db 18
    db 1
    dl fenv_count
    db COLUMN_INPUT
    db 19
    db 1
    dl fenv_control
    db COLUMN_INPUT
    db 20
    db 2
    dl fenv_step
    db COLUMN_INPUT
    db 21
    db 2
    dl fenv_p1_adj
    db COLUMN_INPUT
    db 22
    db 2
    dl fenv_p1_step
    db COLUMN_INPUT
    db 23
    db 2
    dl fenv_p2_adj
    db COLUMN_INPUT
    db 24
    db 2
    dl fenv_p2_step

    ; Sound Statement (12-15)
    db COLUMN_INPUT
    db 28
    db 1
    dl chan_val
    db COLUMN_INPUT
    db 29
    db 1
    dl vol_val
    db COLUMN_INPUT
    db 30
    db 2
    dl freq_val
    db COLUMN_INPUT
    db 31
    db 2
    dl dur_val

    ; Play Button (16)
    db 12
    db 33
    db 0
    dl 0

start_here:
    push af
    push bc
    push de
    push ix
    push iy

    ; Initial Hardware Setup
    SET_MODE 0
    SET_NONSCALED_GRAPHICS
    SET_TXT_BG_COL black
    SET_TXT_COL bright_white
    CLS

    call Load_Note_Asset
    call Load_Cursor_Assets
    Activate_amount_sprites 1
    call draw_ui
    call Draw_Note_Image
    call display_all_values
    call update_cursor_pos

main_loop:
    V_SYNC 
    call check_keys
    Update_GPU 
    jp main_loop

; --- UI Routines ---
draw_ui:
    SET_TXT_COL bright_cyan

    TABTO 28, 1 
    ld hl, msg_title
    call print_str
    TABTO 28, 2 
    ld hl, msg_title_ul
    call print_str

    ; --- Volume Envelope Section (Rows 4-9) ---
    TABTO 2, 8
    ld hl, msg_venv_hdr
    call print_str
    TABTO 2, 9
    ld hl, msg_hdr_ul
    call print_str

    SET_TXT_COL bright_white

    TABTO 3, 10
    ld hl, msg_venv_type
    call print_str
    TABTO 3, 11
    ld hl, msg_venv_att
    call print_str
    TABTO 3, 12
    ld hl, msg_venv_dec
    call print_str
    TABTO 3, 13
    ld hl, msg_venv_sus
    call print_str
    TABTO 3, 14
    ld hl, msg_venv_rel
    call print_str

    ; --- Frequency Envelope Section (Rows 11-18) ---
    SET_TXT_COL bright_cyan

    TABTO 2, 16
    ld hl, msg_fenv_hdr
    call print_str
    TABTO 2, 17
    ld hl, msg_hdr_ul
    call print_str

    SET_TXT_COL bright_white

    TABTO 3, 18
    ld hl, msg_fenv_cnt
    call print_str
    TABTO 3, 19
    ld hl, msg_fenv_ctrl
    call print_str
    TABTO 3, 20
    ld hl, msg_fenv_step
    call print_str
    TABTO 3, 21
    ld hl, msg_fenv_p1a
    call print_str
    TABTO 3, 22
    ld hl, msg_fenv_p1s
    call print_str
    TABTO 3, 23
    ld hl, msg_fenv_p2a
    call print_str
    TABTO 3, 24
    ld hl, msg_fenv_p2s
    call print_str

    ; --- Sound Statement Section (Rows 20-24) ---
    SET_TXT_COL bright_cyan

    TABTO 2, 26
    ld hl, msg_note_hdr
    call print_str
    TABTO 2, 27
    ld hl, msg_hdr_ul
    call print_str

    SET_TXT_COL bright_white
    TABTO 3, 28
    ld hl, msg_chan
    call print_str
    TABTO 3, 29
    ld hl, msg_vol
    call print_str
    TABTO 3, 30
    ld hl, msg_freq
    call print_str
    TABTO 3, 31
    ld hl, msg_dur
    call print_str

    SET_TXT_COL bright_cyan

    ; play
    TABTO 3, 33
    ld hl, msg_play
    call print_str
    TABTO 2, 34
    ld hl, msg_hdr_ul
    call print_str
    
    ; play button
    TABTO 24, 33
    ld hl, msg_play_but
    call print_str

    ; Instructions (Title)
    TABTO 31, 49
    ld hl, msg_footer_hdr
    call print_str
    TABTO 31, 50
    ld hl, msg_footer_ul
    call print_str
    
    SET_TXT_COL bright_white

    ; Instructions
    TABTO 2, 52
    ld hl, msg_footer_0
    call print_str
    TABTO 2, 53
    ld hl, msg_footer_1
    call print_str

    SET_TXT_COL bright_cyan

    TABTO 2, 54
    ld hl, msg_footer_2
    call print_str

    SET_TXT_COL bright_white

    TABTO 8, 54
    ld hl, msg_footer_3
    call print_str
    TABTO 2, 55
    ld hl, msg_footer_4
    call print_str
    TABTO 2, 56
    ld hl, msg_footer_5
    call print_str
    TABTO 2, 57
    ld hl, msg_footer_6
    call print_str

    ret

update_cursor_pos:
    call get_table_ptr          ; This already uses BC=6 and handles the loop correctly

    inc hl                      ; Skip X
    ld a, (hl)                  ; Load Y Row

    ; Convert Row to Pixels (Row * 8)
    ld l, a
    ld h, 8
    mlt hl                      ; HL = Row * 8
    ld (cursor_y_pos), hl

    Select_Sprite_8bit 0

    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 21            ; Command: swap frame
    rst.lil $10
    ld a, (cursorFrame)
    rst.lil $10

    ld a, 23
    rst.lil $10
    ld a, 27
    rst.lil $10
    ld a, 13            ; Move Sprite Command
    rst.lil $10
    
    ld hl, 192          ; Fixed X position (24 x 8)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    
    ld hl, (cursor_y_pos)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10

    Show_Sprite

    ret

; --- Input Logic ---
check_keys:
    ; Check UP
    ld b, $07
    ld c, 1
    call Is_Key_Held_Matrix
    jr nz, move_up

    ; Check DOWN
    ld b, $05
    ld c, 1
    call Is_Key_Held_Matrix
    jr nz, move_down

    ; Check ENTER
    ld b, $09
    ld c, 1
    call Is_Key_Held_Matrix
    jr nz, handle_enter
    ret

move_up:
    ld a, (selection_mode)
    or a
    ret z
    dec a
    ld (selection_mode), a
    call update_cursor_pos
    call wait_for_keyup
    ret

move_down:
    ld a, (selection_mode)
    cp MAX_SELECTION
    ret z
    inc a
    ld (selection_mode), a
    call update_cursor_pos
    call wait_for_keyup
    ret

handle_enter:
    ld a, (selection_mode)
    cp MAX_SELECTION
    jp z, .do_play

    Load_Next_Frame
    Update_GPU

    ; --- Calculate Text Row ---
    call get_table_ptr
    push hl                     ; Save table pointer

    ; Move Text Cursor
    ld a, 31
    rst.lil $10                 ; VDU 31
    ld a, (hl)                  ; Table X
    rst.lil $10
    inc hl
    ld a, (hl)                  ; Table Y
    rst.lil $10

    ; Get Input
    ld hl, text_buffer
    ld bc, 10
    ld e, 1
    ld a, $09
    rst.lil $08                 ; MOS_EDITLINE
    
    call buffer_to_int          ; HL = numeric result

    pop ix                      ; IX = table entry start
    ld b, (ix + 2)              ; Get Type (1=byte, 2=word)
    ld iy, (ix + 3)             ; Get Address (dl part)
    
    ld a, b
    cp 1
    jr nz, .save_word
    ld (iy + 0), l
    jp .done
.save_word:
    ld (iy + 0), hl
.done:
    call display_all_values

    Load_Next_Frame
    Update_GPU
    
    call wait_for_keyup
    ret

.do_play:
    call play_sfx
    call wait_for_keyup
    ret

buffer_to_int:
    ; Simple ASCII to Integer (Decimal)
    ld hl, 0
    ld ix, text_buffer
.loop:
    ld a, (ix)
    cp 13               ; CR?
    ret z
    cp 0                ; Null?
    ret z
    sub '0'
    jr c, .next
    cp 10
    jr nc, .next
    
    ; HL = HL * 10 + A
    push af
    ld d, h
    ld e, l
    add hl, hl          ; *2
    add hl, hl          ; *4
    add hl, de          ; *5
    add hl, hl          ; *10
    pop af
    ld e, a
    ld d, 0
    add hl, de
.next:
    inc ix
    jr .loop

play_sfx:
    ; --- 1. Set Volume Envelope ---
    ld a, 23
    rst.lil $10
    ld a, 0
    rst.lil $10
    ld a, $85                   ; SOUND Command
    rst.lil $10
    ld a, (chan_val)
    rst.lil $10
    ld a, 6                     ; Set Volume Envelope Sub-command
    rst.lil $10
    ld a, (venv_type)
    rst.lil $10
    
    ld hl, (venv_attack)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    
    ld hl, (venv_decay)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    
    ld a, (venv_sustain)
    rst.lil $10
    
    ld hl, (venv_release)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    
    ; --- Set Frequency Envelope ---
    ld a, 23
    rst.lil $10
    ld a, 0
    rst.lil $10
    ld a, $85
    rst.lil $10
    ld a, (chan_val)
    rst.lil $10
    ld a, 7                     ; Command 7: Freq Envelope
    rst.lil $10
    ld a, 1                     ; Mode 1
    rst.lil $10
    ld a, (fenv_count)          ; Number of phases
    rst.lil $10
    ld a, (fenv_control)        ; Control byte
    rst.lil $10
    
    ld hl, (fenv_step)          ; Step Length
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10

    ; Phase 1
    ld hl, (fenv_p1_adj)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    ld hl, (fenv_p1_step)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    
    ; Phase 2 (Only sent if fenv_count >= 2)
    ld hl, (fenv_p2_adj)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    ld hl, (fenv_p2_step)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10

    ; --- 2. Set Waveform ---
    ld a, 23
    rst.lil $10
    ld a, 0
    rst.lil $10
    ld a, $85
    rst.lil $10
    ld a, (chan_val)
    rst.lil $10
    ld a, 4                     ; Set Waveform
    rst.lil $10
    ld a, 0                     ; Type 0 (Square)
    rst.lil $10

    ; --- 3. Play the Note ---
    ld a, 23
    rst.lil $10
    ld a, 0
    rst.lil $10
    ld a, $85
    rst.lil $10
    ld a, (chan_val)
    rst.lil $10
    ld a, 0                     ; Play Note Command
    rst.lil $10
    ld a, (vol_val)
    rst.lil $10
    ld hl, (freq_val)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    ld hl, (dur_val)
    ld a, l
    rst.lil $10
    ld a, h
    rst.lil $10
    ret

; ==============================================================================
; Routine: display_all_values
; Purpose: Redraws all numeric parameter values from the table to the screen.
; ==============================================================================
display_all_values:
    ld a, 0                     ; Start index 0
    ld ix, parameter_table      ; IX points to start of table
.val_loop:
    push af                     ; Save loop index (0-15)
    
    ; --- 1. Move Cursor to coordinates stored in Table ---
    ld a, 31                    ; VDU 31 (TABTO)
    rst.lil $10
    ld a, (ix + 0)              ; X coordinate from table
    rst.lil $10
    ld a, (ix + 1)              ; Y coordinate from table
    rst.lil $10
    
    ; --- 2. Fetch Variable Address from Table ---
    ld iy, (ix + 3)             ; IY = The variable's memory address
    
    ; --- 3. Load Value into HL based on Type ---
    ld a, (ix + 2)              ; Type (1=byte, 2=dl)
    cp 1
    jr nz, .read_long
    ld hl, 0
    ld l, (iy + 0)              ; Read 8-bit byte
    jr .check_sign
.read_long:
    ld hl, (iy + 0)             ; Read 24-bit long (dl)

.check_sign:
    bit 7, h                    ; Check if negative (bit 23 of 24-bit value)
    jr z, .print_pos
    
    push hl
    ld a, '-'                   ; Print minus sign for negative numbers
    rst.lil $10
    pop hl
    
    ; Negate HL: HL = 0 - HL to get positive value for printer
    push hl
    pop de
    ld hl, 0
    or a
    sbc hl, de
    
.print_pos:
    call print_int_unsigned     ; Print the number currently in HL

    ; --- 4. Advance to next table entry ---
    ld de, 6                    ; Each entry is 6 bytes
    add ix, de
    
    pop af                      ; Restore index
    inc a
    cp MAX_SELECTION            ; Loop 16 times
    jr nz, .val_loop
    ret

; ==============================================================================
; Routine: print_int_unsigned
; Purpose: Prints HL as decimal with leading zero suppression.
; ==============================================================================
print_int_unsigned:
    ld b, 0                     ; B = "Started Printing" flag (0=No)
    
    ld de, 10000
    call .proc_digit
    ld de, 1000
    call .proc_digit
    ld de, 100
    call .proc_digit
    ld de, 10
    call .proc_digit
    
    ; Final units digit (always print, even if it's 0)
    ld a, l
    add a, '0'
    rst.lil $10
    ret

.proc_digit:
    ld c, '0'                   ; C = digit character starting at ASCII '0'
.sub_loop:
    or a
    sbc hl, de                  ; Subtract divisor from HL
    jr c, .sub_done             ; If it underflows, we found our digit
    inc c                       ; Increment digit character
    jr .sub_loop
.sub_done:
    add hl, de                  ; Restore HL after underflow
    
    ld a, c
    cp '0'
    jr nz, .print_it            ; If digit is 1-9, always print it
    
    ld a, b                     ; Check flag: have we printed a digit yet?
    or a
    ret z                       ; If flag is 0, skip leading zero
    
    ld a, '0'
.print_it:
    ld b, 1                     ; Set flag: we've now started printing numbers
    ld a, c
    rst.lil $10
    ret

;---------------
; Print String
;---------------
print_str:
    ld a, (hl)
    or a
    ret z
    rst.lil $10
    inc hl
    jr print_str

wait_for_keyup:                         ; wait for key up state so we only do it once
    MOSCALL $08                         ; get IX pointer to sysvars
    ld a, (ix + 18h)                    ; get key state
    cp 0                                ; are keys up, none currently pressed?
    jp nz, wait_for_keyup               ; loop if there is a key still pressed
    ret

get_table_ptr:
    ld hl, parameter_table      ; Start at the beginning
    ld a, (selection_mode)      ; Get the current index
    or a                        ; Is it index 0?
    ret z                       ; If yes, HL is already correct, so return.

    ld bc, 6                    ; Each entry is 6 bytes
.sel_loop:
    add hl, bc                  ; Move to next entry
    dec a                       ; Decrement index counter
    jr nz, .sel_loop            ; If not zero, keep jumping
    ret

; =============================================================================
; Purpose: Draw the already-loaded Buffer 15 to the screen
; =============================================================================

Draw_Note_Image:
    ;Draw_Rect x1, y1, x2, y2, bgcol
   ; Draw_Filled_Rect 63, 20, 254, 67, (banner_colour)
    ; select and draw the title top
	ld a, 250
	ld (bitmap_x),a
    ld a,100                 ; y coords
	ld (bitmap_y),a 
	ld a,15                 ; bitmap/buffer id
	ld (which_bitmap),a 
	ld a,250
	ld (which_bitmap + 1),a

    ; draw bitmap
    push hl
	push bc
	ld hl, draw_bmStart
	ld bc, draw_bmEnd - draw_bmStart
	rst.lil $18
	pop bc
	pop hl
	ret 

draw_bmStart:
    		.db 23, 27, $20		 	; select bitmap (16 bit id)
which_bitmap:	.dw 0			 	; bitmap number 30

		.db 25, $ED	         	    ; plot bitmap at x,y
bitmap_x:	.dw 0	      	        ; to x pos (a word not a byte) 63
bitmap_y:	.dw 0		         	; to y pos (a word not a byte) 83
draw_bmEnd:

;---------------------------------
; Cursor Asset, Sprite 1
;---------------------------------
; Cursor Loader, using mono pbm file, buffers 1
Load_Cursor_Assets:

    Select_Sprite_8bit 0

    ; Load Cursor col white
    ld hl, loadCursor				            ; start of data to send
	ld bc, endLoadCursor - loadCursor		    ; length of data to send
	rst.lil $18
    Add_Frame_To_Sprite 10
    ; Load Cursor col cyan
    ld hl, loadCursor1				            ; start of data to send
	ld bc, endLoadCursor1 - loadCursor1		    ; length of data to send
	rst.lil $18
    Add_Frame_To_Sprite 11

    Hide_Sprite
    ret

; ---- Cursor .pbm mono images ----
                     ; id,  w,  h,  data,                 colourCode
loadCursor:	
	MAKEBUFFEREDBITMAP 10, 32, 8, "cursor.pbm", bright_white
endLoadCursor: 
loadCursor1:	
	MAKEBUFFEREDBITMAP 11, 32, 8, "cursor.pbm", bright_cyan 
endLoadCursor1:     

;------------------------
; Note Image
;------------------------
; Note Image Loader. using 400x212 mono pbm file, buffer 15
Load_Note_Asset:
    ld hl, loadGraphics				            ; start of data to send
	ld bc, endLoadGraphics - loadGraphics		; length of data to send
	rst.lil $18					             
	; take a break to catch up in 2 batches
	ld hl, loadGraphics				            ; start of data to send
	ld bc, endLoadGraphics - loadGraphics		; length of data to send
	rst.lil $18			

    ret

loadGraphics:	
	;                  id, width, height,    data,        colourCode
	MAKEBUFFEREDBITMAP 15, 400, 212, "note.pbm", grey 
endLoadGraphics:

;----------------------------------------------------------
; Is_Key_Held_Matrix
; Input: B = Byte Offset, C = Bit Number
; Output: NZ if pressed (1), Z if released (0)
;----------------------------------------------------------
Is_Key_Held_Matrix:
    push ix
    push bc
    
    ld a, $1E
    rst.lil $08             ; IX = Pointer to keyboard matrix Decode_Room_Metadata
    
    push ix
    pop hl                  ; HL = Start of matrix
    ld de, 0
    ld e, b                 ; DE = Offset (the byte index)
    add hl, de              ; HL = Start + Offset
    push hl
    pop ix                  ; IX = Correct Byte Address
    
    ld a, (ix + 0)          ; Load the byte from the matrix
    pop bc                  ; Restore Bit number into C
    
    ld b, a                 ; Store matrix byte into B
    ld a, 1
    inc c                   ; Increment for loop logic
_mask_loop:
    dec c
    jr z, _do_test
    add a, a                ; Shift bit left to create mask
    jr _mask_loop
_do_test:
    and b                   ; Isolate the bit (1 if pressed)
    pop ix
    ret