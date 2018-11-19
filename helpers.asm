#importonce

.label vic2_screen_control_register1 = $d011
.label vic2_screen_control_register2 = $d016
.label vic2_rasterline_register = $d012
.label vic2_interrupt_control_register = $d01a
.label vic2_interrupt_status_register = $d019

.macro stabilize_irq() {
  start:
    :mov16 #irq2 : $fffe
    inc vic2_rasterline_register
    asl vic2_interrupt_status_register
    tsx
    cli

    inc $fb
    dec $fb
    :nops(4)

  irq2:
    txs
    ldx #1+7 // 2
  !loop: // (2+3) * 7
    dex  // 2
    bne !loop- // 2
    bit $ea
  test:
    lda vic2_rasterline_register
    cmp vic2_rasterline_register
    beq next_instruction
  next_instruction:
}

.macro set_raster(line_number) {
  lda #line_number
  sta vic2_rasterline_register

  lda vic2_screen_control_register1
  .if (line_number > 255) {
    ora #%10000000
  } else {
    and #%01111111
  } 
  sta vic2_screen_control_register1
}

.pseudocommand mov16 source : destination {
  :_mov bits_to_bytes(16) : source : destination
}
.pseudocommand mov source : destination {
  :_mov bits_to_bytes(8) : source : destination
}
.pseudocommand _mov bytes_count : source : destination {
  .for (var i = 0; i < bytes_count.getValue(); i++) {
    lda extract_byte_argument(source, i) 
    sta extract_byte_argument(destination, i) 
  } 
}
.pseudocommand _add bytes_count : left : right : result {
  clc
  .for (var i = 0; i < bytes_count.getValue(); i++) {
    lda extract_byte_argument(left, i) 
    adc extract_byte_argument(right, i) 
    sta extract_byte_argument(result, i)
  } 
}
.function extract_byte_argument(arg, byte_id) {
  .if (arg.getType()==AT_IMMEDIATE) {
    .return CmdArgument(arg.getType(), extract_byte(arg.getValue(), byte_id))
  } else {
    .return CmdArgument(arg.getType(), arg.getValue() + byte_id)
  }
}
.function extract_byte(value, byte_id) {
  .var bits = _bytes_to_bits(byte_id)
  .eval value = value >> bits
  .return value & $ff
}
.function _bytes_to_bits(bytes) {
  .return bytes * 8
}
.function bits_to_bytes(bits) {
  .return bits / 8
}

.macro nops(count) {
  .for (var i = 0; i < count; i++) {
    nop
  }
}

.macro cycles(count) {
  .if (count < 2) {
    .error "The cycle count cannot be less than 2"
  }
  .if (mod(count, 2) != 0) {
    bit $ea
    .eval count -= 3 
  }
  :nops(count/2)
}
