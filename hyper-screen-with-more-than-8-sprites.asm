#import "helpers.asm"

.label border = $d020
.label background = $d021
.label screen = $0400

.label cia1_interrupt_control_register = $dc0d
.label cia2_interrupt_control_register = $dd0d

:BasicUpstart2(main)
.const RASTER_LINE = 309
main:
  sei

  lda #$f0
  sta $3fff

  lda #WHITE
  sta border
  lda #BLACK
  sta background

  lda $01
  and #%11111101
  sta $01

  lda #%01111111
  sta cia1_interrupt_control_register
  sta cia2_interrupt_control_register
  lda cia1_interrupt_control_register
  lda cia2_interrupt_control_register

  lda #%00000001
  sta vic2_interrupt_control_register
  sta vic2_interrupt_status_register
  :set_raster(RASTER_LINE)
  :mov16 #irq1 : $fffe

  cli

loop:
  jmp loop

irq1:
  sta atemp
  stx xtemp
  sty ytemp

  :stabilize_irq()

last_line:
  // At the start of line with index 311 (stabilized at cycle 3)
  :cycles(56-3-2*8)
  lda vic2_screen_control_register2
  ora #%00001000
  tax
  lda vic2_screen_control_register2
  and #%11110111
  tay
  // We add 3 cycles and remove them immediately from the new_frame: this way
  // we have a compensation for the 3 cycles taken by the jmp at the end.
  :cycles(3)

new_frame:
  // At the end of line with index 311 (stabilized at cycle 56+3)
  :cycles(63-3-8)
  stx vic2_screen_control_register2
  sty vic2_screen_control_register2  // <<< Opens line with index 0

  // Lines with index from 0 to 49
  .for (var i = 0; i < 50; i++) {
    :cycles(63-8)
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2  // <<< Opens lines from index 1 to 50
  }

all_but_last_char_lines:
  // Start from line with index 51
  .for (var i = 0; i < 24; i++) {
    :cycles(20-8)
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
    .for (var j = 0; j < 7; j++) {
      :cycles(63-8)
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }
  }

last_char_line:
  :cycles(20-8)
  stx vic2_screen_control_register2
  sty vic2_screen_control_register2
  .var rasterline = $f3
  .for (var i = 0; i < 7; i++, rasterline++) {
    .if(rasterline == $f3) {
      :cycles(63-10-8)
      lda vic2_screen_control_register1
      ora #%00001000
      sta vic2_screen_control_register1
    } else .if(rasterline == $f7) {
      :cycles(63-10-8)
      lda vic2_screen_control_register1
      and #%11110111
      sta vic2_screen_control_register1
    } else {
      :cycles(63-8)
    }
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
  }

  // 49+12 lines of bottom border
  .for (var i = 0; i < 49+12; i++) {
    :cycles(63-8)
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
  }

  jmp new_frame

  asl vic2_interrupt_status_register
  :set_raster(RASTER_LINE)
  :mov16 #irq1 : $fffe
  lda atemp: #$00
  ldx xtemp: #$00
  ldy ytemp: #$00
  rti




