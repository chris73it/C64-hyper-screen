#import "helpers-line-0.asm"

.label border = $d020
.label background = $d021
.label screen = $0400

.label cia1_interrupt_control_register = $dc0d
.label cia2_interrupt_control_register = $dd0d

:BasicUpstart2(main)
.const RASTER_LINE = 310
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
  /*sta atemp
  stx xtemp
  sty ytemp*/

  :stabilize_irq()

  :cycles(56 - 4 - 2*12)
  lda vic2_screen_control_register2
  ora #%00001000
  tax
  lda vic2_screen_control_register2
  and #%11110111
  tay
  stx vic2_screen_control_register2
  sty vic2_screen_control_register2
  :cycles(3)

top_border_start:
  :cycles(63 - 3 - 8)
  stx vic2_screen_control_register2
  sty vic2_screen_control_register2

  .for (var i = 1; i < 43+7; i++) {
    :cycles(63 - 8)
    .if (i == 25) {
      :cycles(8)
    } else {
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }
  }
top_border_end:

rows: .for (var row = 0; row < 24; row++) {
    :cycles(20 - 8)
  bad_line:
    stx vic2_screen_control_register2
    sty vic2_screen_control_register2
    .for (var i = 0; i < 7; i++) {
      :cycles(63 - 8)
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }
  }
  :cycles(20 - 8)
  stx vic2_screen_control_register2
  sty vic2_screen_control_register2

last_char_row_start:
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
last_char_row_end:

bottom_border_start: 
  .for (var i = 0; i < 49+13; i++) {
    :cycles(63 - 8)
    .if (i == 20) {
      :cycles(8)
    } else {
      stx vic2_screen_control_register2
      sty vic2_screen_control_register2
    }
  }
bottom_border_end:

  jmp top_border_start

  /*asl vic2_interrupt_status_register
  :set_raster(RASTER_LINE)
  :mov16 #irq1 : $fffe
  lda atemp: #$00
  ldx xtemp: #$00
  ldy ytemp: #$00
  rti*/
