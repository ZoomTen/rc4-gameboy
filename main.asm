INCLUDE "include/hardware.asm"

wStack EQU $dfff
wPool EQU $c000
wRC4Message EQU wPool + $100
hPRGABuffer EQU $ff90

SECTION "int_vbi", ROM0[$40]
	jp frame_event

SECTION "entry", ROM0[$100]
_entry:
	jp start

SECTION "start", ROM0[$150]
start:
; --- standard gameboy init stuff ---
	di
	ld sp, wStack
	call lcd_disable

; initialize registers
	ld a, %11100100
	ld [rBGP], a

	xor a
	ld [rSCX], a
	ld [rSCY], a

; clear WRAM, VRAM
	ld hl, wPool
	ld bc, $200
	call mem_fill

	ld hl, vChars0
	ld bc, $2000
	call mem_fill

	ld a,%00000001  	; Enable V-blank interrupt
	ld [rIE], a
	ei

; --- how to call the RC4 algorithm ---
; init the key schedule
	call key_schedule_init

; load your key here
	ld de, Key
rept 1	; number of rounds (for CipherSaber2 implementation)
	call key_schedule
endr

; de is the same every time so you can
; call key_schedule multiple times

; load your message here
	ld de, EncryptedMessage
	call encrypt_message ; exactly the same for decrypting/encrypting

; -------------------------------------

; copy ASCII set
	ld de, Letters
	ld hl, $8200
	ld bc, $8 * $60
	call mem_cpy_double

; copy decrypted message
	ld de, wRC4Message
	ld hl, $9902
	ld bc, $100
	call mem_cpy

	call lcd_enable

; infinite loop
.loop
	halt
	nop
	jr .loop

INCLUDE "rc4.asm"
INCLUDE "include/library.asm"

frame_event:
	ld a, [rSCX]
	inc a
	ld [rSCX], a
	reti

; --- data ---

Key:
	db "gameboy"
	db 0	; terminator

EncryptedMessage:
	db $8e, $c0, $a0, $4a
	db $a9, $f4, $bf, $30
	db $5d, $82, $b4, $07
	db $01, $3b, $37, $41
	db $03, $eb, $d8, $bb
	db $ba, $94
	db 0	; terminator

Letters:
	INCBIN "include/ascii.2bpp"
