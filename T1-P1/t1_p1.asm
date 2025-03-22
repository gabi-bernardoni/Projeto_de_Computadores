# PSC: 2024/1
    
    .text                           # Declaração de início do segmento de texto
    .globl  main                    # Declaração de que o rótulo main é global

########################################
# testes de instruções individuais
########################################
main:   
    lui     $t0, 0xf3               #
    ori     $t0, $t0, 0x23          # $t0 <= 0x00f30023
    lui     $t1, 0x52               #
    ori     $t1, $t1, 0xe2          # $t1 <= 0x005200e2
    lui     $t2, 0x00               #
    ori     $t2, $t2, 0xff8f        # $t2 <= 0x0000ff8f
    beq     $t1, $t2, main          # Obviamente, esta instrução não deve saltar
    beq     $t1, $t1, equals        # Obviamente, esta instrução deve saltar
    j main
equals:
    bne     $t2, $t2, main          # Obviamente, esta instrução não deve saltar
    bne     $t1, $t2, next_i        # Obviamente, esta instrução deve saltar
    j       main                    # Obviamente, esta instrução nunca deve executar

next_i:    
    addu    $t3, $t0, $t1           # $t3 <= 0x00f30023 + 0x005200e2 = 0x01450105
    subu    $t4, $t0, $t1           # $t4 <= 0x00f30023 - 0x005200e2 = 0x00a0ff41
    subu    $t5, $t1, $t1           # $t5 <= 0x0
    and     $t6, $t0, $t1           # $t6 <= 0x00f30023 and 0x005200e2 = 0x00520022
    or      $t7, $t0, $t1           # $t7 <= 0x00f30023 or  0x005200e2 = 0x00f300e3
    xor     $t8, $t0, $t1           # $t8 <= 0x00f30023 xor 0x005200e2 = 0x00a100c1
    nor     $t9, $t0, $t1           # $t9 <= 0x00f30023 nor 0x005200e2 = 0xff0cff1c
    addiu   $t0, $t0, 0x00ab        # $t0 <= 0x00f30023  +  0x000000ab = 0x00f300ce
    andi    $s0, $t0, 0xf0ab        # $s0 <= 0x00f300ce and 0x0000f0ab = 0x0000008a
    xori    $s1, $s0, 0xffab        # $s1 <= 0x0000008a xor 0x0000ffab = 0x0000ff21
    move    $t0, $s1                # $t0 <= 0x0000ff21
    
    sll     $t0, $t0, 12            # $t0<= 0xff210000 (deslocado 12 bits para a esquerda)
    srl     $t0, $t0, 17            # $t0<= 0x000007f9 (deslocado 17 bits para a direita)
    sll     $t0, $t0, 21            # $t0<= 0xff200000 (deslocado 21 bits para a esquerda)
    sra     $t0, $t0, 21            # $t0<= 0xfffffff9 (deslocado 21 bits para a direita com o sinal)
    
    move     $t0, $s1                # $t0 <= 0x0000ff21
    li       $t1, 4
    sllv     $t0, $t0, $t1          # $t0<= 0x000ff210 (deslocado 4 bits para a esquerda)
    li       $t1, 9
    srlv     $t0, $t0, $t1          # $t0<= 0x000007f9 (deslocado 9 bits para a direita)
    li       $t1, 21
    sllv     $t0, $t0, $t1          # $t0<= 0xff200000 (deslocado 21 bits para a esquerda)
    srav     $t0, $t0, $t1          # $t0<= 0xfffffff9 (deslocado 21 bits para a direita com o sinal)
