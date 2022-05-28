    DEVICE ZXSPECTRUM48
    org $8000

SCR_ADDR = $4000
SRC_LEN = $1800 
Y_MAX = 192

LOW5 = $1F
TOP3 = $E0
TOPBIT = $80
; This mask will restrict byte addresses to the screen bitmap
REJ_MASK = $18
; This mask will also allow writes to the color attributes but not further
; REJ_MASK = $1B
ADDR_PREFIX = $40

; Places random dots in the spectrum video memory (starry night)
; The Speccy has a notoriously weird addressing mode for graphics
; The 2 byte pattern is like that:
; 0 1 0 | Y7 Y6 | Y3 Y2 Y0 || Y5 Y4 Y3 | X4 X3 X2 X1 X0
; For starry field we just plot a random coord so only
; thing that needs to be done is to be sure that y < 192
start:
    ; algo 1: sample x, y and do the bit shuffling
    
    ; just put on l pretending 3 high bits of x are from y
    ;ld bc, hl
    ;ld l, a

    ; rejection sampling, only take y<192
reject:
    ;call random
    ; just keep it
    call random
    ld a, h
    ld b, a
    and LOW5
    cp REJ_MASK
    ; reject sampled address if goes above REJ_MASK - bitmap or bitmap + attr
    jr NC, reject

    ld a, b
   
    and LOW5
    or ADDR_PREFIX
    ld h, a

    ld a, b
    and TOP3
    rlca
    rlca
    rlca
    ; now b contains the pixel on the x byte to be set: 0, ..., 7
    ld b, a
    inc b
    ; form byte on a
    ld a, TOPBIT
shift_pixel:
    rlca
    djnz shift_pixel
    ld b, (hl)
    xor b
    ld (hl), a
    ; form the top 
    jp start

; 16-bit xorshift pseudorandom number generator by John Metcalf
; 20 bytes, 86 cycles (excluding ret)

; returns   hl = pseudorandom number
; corrupts   a

; generates 16-bit pseudorandom numbers with a period of 65535
; using the xorshift method:

; hl ^= hl << 7
; hl ^= hl >> 9
; hl ^= hl << 8

; some alternative shift triplets which also perform well are:
; 6, 7, 13; 7, 9, 13; 9, 7, 13.
random:
  ld hl,1       ; seed must not be 0

  ld a,h
  rra
  ld a,l
  rra
  xor h
  ld h,a
  ld a,l
  rra
  ld a,h
  rra
  xor l
  ld l,a
  xor h
  ld h,a
  ; self-modifying code, i think
  ld (random+1),hl

  ret

    SAVESNA "juc.sna", start