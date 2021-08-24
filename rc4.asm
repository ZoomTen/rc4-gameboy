; SPDX-License-Identifier: MIT

; ----------------------------------------------
; RC4 algorithm implemented in Game Boy assembly
; Zumi, 2021-08-24
; ----------------------------------------------
; yes, this sucks
; yes, you can use it
; but if you need a license, see the MIT license
; text.
; 
; keep in mind:
;     - encrypted AND decrypted messages are
;       both NULL-terminated
;
;     - maximum length of message is 256 bytes
; ----------------------------------------------

; where to put the keyscheduling pool (in wram, $100 bytes)
WRAM_KEYSCHED_POOL equ wPool

; the encrypted message will be placed DIRECTLY AFTER the pool
; so make sure you have some space for that

; it's best to place this in HRAM
PRGA_BUFFER_BYTE equ hPRGABuffer

; sanity check
assert WRAM_KEYSCHED_POOL == HIGH(WRAM_KEYSCHED_POOL) * $100, \
	"WRAM_KEYSCHED_POOL location must be padded to the nearest $100\n\t(Currently it is set to {WRAM_KEYSCHED_POOL})"

key_schedule_init:
; initialize WRAM_KEYSCHED_POOL with incrementing values
; from $00 - $ff
	xor a
	ld hl, WRAM_KEYSCHED_POOL
	ld b, $ff
.init
	ld [hli], a
	inc a
	dec b
	jr nz, .init
; place the final value
	ld [hl], $ff
	ret

key_schedule:
; de <- Key location

; This assumes a key that is terminated with $00!

; initialize all values
	ld bc, 0
	ld hl, WRAM_KEYSCHED_POOL

; save start of key
	push de

.loop ; do
	ld l, c
	ld a, [de]
	and a
	jr nz, .not_reached_keylength

; wrap around key
	pop de
	ld a, [de]
; save start of key again for later
	push de

.not_reached_keylength
; key_pointer++
; b = *(pool_pointer + c) + *(key_pointer)
	inc de

	add b
	ld b, [hl]
	add b
	ld b, a

; swap(pool_pointer + b, pool_pointer + c)
	push bc
		ld l, b
		ld a, [hl]
		push hl
			ld l, c
			ld b, [hl]
			ld [hl], a
		pop hl
		ld [hl], b
	pop bc

; c++
	inc c

; while (end of internal state hasn't been reached)
	jr nz, .loop

; resolve dangling stack
	pop de
	ret

encrypt_message:
	xor a
	ld [PRGA_BUFFER_BYTE], a
	ld hl, WRAM_KEYSCHED_POOL
	ld bc, 0
.loop
	ld a, [de]
	and a
; end here if encountering termination byte
	ret z

	inc de

; save original byte of message
	ld b, a

; do pseudo-random keystream
	push hl
		inc c
		ld l, c
		ld h, [hl]
		ld a, [PRGA_BUFFER_BYTE]
		add h
		ld [PRGA_BUFFER_BYTE], a
	; reset h
		ld h, HIGH(WRAM_KEYSCHED_POOL)

		push bc
			ld l, a
			ld b, [hl]
			push hl
				ld l, c
				ld a, [hl]
				ld [hl], b
			pop hl
			ld [hl], a

			add b
			ld l, a
			ld a, [hl]
		pop bc
	pop hl
; generated keystream byte is placed in accumulator

; actually encrypt/decrypt the message
; this assumes the message will be placed DIRECTLY after WRAM_KEYSCHED_POOL
; in other words, WRAM_KEYSCHED_POOL + $100
	xor a, b
	inc h
	ld [hl], a
	dec h
	inc l
	jr .loop

