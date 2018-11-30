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

  lda #$f0
  sta $3fff

  lda #1
  sta border
  lda #0
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

// row 50 ($32 in hex) - 1st xing background but without chars
  :cycles(56 - 3 - 6)
  lda #%11001000                     // 40 columns
  sta vic2_screen_control_register2
  //FIXME: Investigate why it does not work!
  //:cycles(3)

first_char_row:
// row 51 ($33 in hex) - It is a bad line (YSCROLL is 3)
  first_bad_line:
    :cycles(20 /*- 3*/ - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
    :cycles(3)

loop_over:
// row [52:58] ([$34:$3A] in hex)
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 3 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z

    .for (var i = 1; i < 6; i++) {
      rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
      :cycles(63 - 6 - 6)
      lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
    }

    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 1*6) // was 2*6
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
    // ...cycle 56...
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    //FIXME: Is it a problem that 40 cols happens at the56th cycle? YES!!!

central_char_rows:
  .for (var row = 1; row < 4; row++) {  //FIXME: was 24 times..!
// row 51 ($33 in hex) - It is a bad line (YSCROLL is 3)
    :cycles(20 - 1*6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z

// row [52:58] ([$34:$3A] in hex)
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z

    .for (var i = 1; i < 6; i++) {
      rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
      :cycles(63 - 6 - 6)
      lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
    }

    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 1*6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
    // ...cycle 56...
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
  }
/*
last_char_row:
// row $f2 in hex - It is a bad line (YSCROLL is 3)
  :cycles(20 - 1*6 - 6)
  lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z

// row $f3 in hex
  rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
  :cycles(63 - 6 - 10 - 6)
  lda vic2_screen_control_register1
  ora #%00001000
  sta vic2_screen_control_register1
  lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z

// row $f4:$f6
  .for (var i = 1; i < 4; i++) {
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
  }

// row $f7
  rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
  :cycles(63 - 6 - 10 - 6)
  lda vic2_screen_control_register1
  and #%11110111
  sta vic2_screen_control_register1
  lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z

// row $f8:$f9
  .for (var i = 5; i < 7; i++) {
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
  }
*/
/*
bottom_border_start:
// row 300 ($12C in hex)
  .for (var i = 0; i < 49; i++) {
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
  }

bottom_border_end:
  .for (var i = 0; i < 13; i++) {
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
  }

next_frame:
  .for (var i = 0; i < 7; i++) {
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
  }

top_border_start:
  .for (var i = 0; i < 43; i++) {
    rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz
    :cycles(63 - 6 - 6)
    lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z
  }
  // ...cycle 56...
  rol vic2_screen_control_register2  // 40 cols %011001xy > %11001xyz


// First bad line
  :cycles(20 - 6 - 6)
  lsr vic2_screen_control_register2  // 38 cols %11001xyz > %011001xy > z

top_border_end:
  jmp loop_over
*/
  asl vic2_interrupt_status_register
  :set_raster(RASTER_LINE)
  :mov16 #irq1 : $fffe
  lda atemp: #$00
  ldx xtemp: #$00
  ldy ytemp: #$00
  rti




