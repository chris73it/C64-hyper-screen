#import "helpers.asm"

.label border = $d020
.label background = $d021
.label screen = $0400

.label cia1_interrupt_control_register = $dc0d
.label cia2_interrupt_control_register = $dd0d

:BasicUpstart2(main)
.const RASTER_LINE = $33 - 3
main:
  sei

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

// row 50 ($32 in hex) - 1st xing background but without chars
  :cycles(56 - 3 - 2*8)
  lda vic2_screen_control_register2
  ora #%00001000
  tax
  lda vic2_screen_control_register2
  and #%11110111
  tay
  :cycles(3)

first_char_row:
// row 51 ($33 in hex) - It is a bad line (YSCROLL is 3)
  first_bad_line:
    :cycles(20 - 8 - 3)
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
// row [52:58] ([$34:$3A] in hex)
    .for (var i = 0; i < 7; i++) {
      :cycles(63 - 8)
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }

central_char_rows:
  .for (var row = 1; row < 24; row++) {
// row 51 ($33 in hex) - It is a bad line (YSCROLL is 3)
    :cycles(20 - 8)
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
// row [52:58] ([$34:$3A] in hex)
    .for (var i = 0; i < 7; i++) {
      :cycles(63 - 8)
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }
  }

last_char_row:
// row 59 ($3B in hex) - It is a bad line (YSCROLL is 3)
  :cycles(20 - 8)
  stx vic2_screen_control_register2
  sty vic2_screen_control_register2
// row 60 ($3C in hex)
  .var rasterline = $f3
  .for (var i = 0; i < 7; i++, rasterline++) {
    .if(rasterline == $f3) {
      :cycles(63 - 8 - 10)
      lda vic2_screen_control_register1
      ora #%00001000
      sta vic2_screen_control_register1
    } else .if(rasterline == $f7) {
      :cycles(63 - 8 - 10)
      lda vic2_screen_control_register1
      and #%11110111
      sta vic2_screen_control_register1
    } else {
      :cycles(63 - 8)
    }
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
  }

bottom_border_start:
  .for (var i = 0; i < 49; i++) {
    :cycles(63 - 8)
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
  }

bottom_border_end:
  .for (var i = 0; i < 13; i++) {
    :cycles(63 - 8)
    .if (i == 100) {
      :cycles(8)
    } else {
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }
  }

next_frame:
  .for (var i = 0; i < 7; i++) {
    :cycles(63 - 8)
    .if (i == 100) {
      :cycles(8)
    } else {
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }
  }

top_border_start:
  .for (var i = 0; i < 43; i++) {
    :cycles(63 - 8)
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
  }

top_border_end:
  jmp first_bad_line 

  asl vic2_interrupt_status_register
  :set_raster(RASTER_LINE)
  :mov16 #irq1 : $fffe
  lda atemp: #$00
  ldx xtemp: #$00
  ldy ytemp: #$00
  rti




