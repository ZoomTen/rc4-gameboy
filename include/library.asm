lcd_disable:
	ld a, [rLCDC]
	rlca
	ret nc
.wait
	ld a, [rLY]
	cp 144
	jr c, .wait
	ld a,[rLCDC]
	res LCD_ENABLE_BIT, a
	ld [rLCDC],a
	ret

lcd_enable:
	push hl
	ld hl, rLCDC
	set LCD_ENABLE_BIT, [hl]
	pop hl
	ret

mem_fill_fast:: ; (hl dest, a byte, b len)
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret

mem_fill:: ; (hl dest, d byte, bc len)
.loop
	ld a, d
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, .loop
	ret

mem_cpy:: ; (de src, hl dest, bc len)
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, .loop
	ret

mem_cpy_double:: ; (de src, hl dest, bc len)
.loop
	ld a, [de]
	inc de
	ld [hli], a
	ld [hli], a
	dec bc
	ld a, c
	or b
	jr nz, .loop
	ret
