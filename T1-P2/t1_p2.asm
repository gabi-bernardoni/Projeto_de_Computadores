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
    
    la      $t0,array               # coloca em $t0 o endereço inicial do vetor array (0x10010000)
    lb      $t1,6($t0)              # $t1<= 0xffffffef (primero byte é terceiro byte do segundo elemento)
    bgez    $t1, main               # Obviamente, esta isntrução não deve saltar
    lbu     $t1,6($t0)              # $t1<= 0x000000ef (primero byte é terceiro byte do segundo elemento)
    xori    $t1,$t1,0xff            # $t1<= 0x00000010, inverte byte inferior
    sb      $t1,6($t0)              # byte 2 do segundo elemento do vetor <= 10 (resto não muda)
                                    # CUIDADO, mudou elemento do array a ser processado por soma_ct
    addiu   $t0,$zero,0x1           # $t0<= 0x00000001
    subu    $t0,$zero,$t0           # $t0<= 0xffffffff
    bgez    $t0,loop                # Esta instrução nunca deve saltar, pois $t0 = -1
    slt     $t3,$t0,$t1             # $t3<= 0x00000001, pois -1 < 10
    beq     $t3, $zero, main        # Obviamente, esta instrução não deve saltar
    sltu    $t3,$t0,$t1             # $t3<= 0x00000000, pois (2^32)-1 > 10
    bne     $t3, $zero, main        # Obviamente, esta instrução não deve saltar
    slti    $t3,$t0,0x1             # $t3<= 0x00000001, pois -1 < 1
    beq     $t3, $zero, main        # Obviamente, esta instrução não deve saltar
    sltiu   $t3,$t0,0x1             # $t3<= 0x00000000, pois (2^32)-1 > 1
    bne     $t3, $zero, main        # Obviamente, esta instrução não deve saltar
        
########################################
# soma uma constante a um vetor
########################################
soma_ct:
    la      $t0,array               # coloca em $t0 o endereço do vetor (0x10010000)
    la      $t1,size                # coloca em $t1 o endereço do tamanho do vetor 
    lw      $t1,0($t1)              # coloca em $t1 o tamanho do vetor
    la      $t2,const               # coloca em $t2 o endereço da constante
    lw      $t2,0($t2)              # coloca em $t2 a constante
loop:    
    blez    $t1,end_add             # se/quando tamanho é/torna-se 0, fim do processamento
    lw      $t3,0($t0)              # coloca em $t3 o próximo elemento do vetor
    addu    $t3,$t3,$t2             # soma constante
    sw      $t3,0($t0)              # atualiza no vetor o valor do elemento
    addiu   $t0,$t0,4               # atualiza ponteiro do vetor. Lembrar, 1 palavra=4 posições de memória
    addiu   $t1,$t1,-1              # decrementa contador de tamanho do vetor
    j       loop                    # continua execução
        
########################################
# teste de subrotinas aninhadas
########################################
end_add:
    li      $sp, 0x10010800         # inicializa stack pointer (sp)
    addiu   $sp,$sp,-4              # aloca espaço na pilha para uma palavra
    sw      $ra,0($sp)              # salva endereço de retorno de quem chamou
    jal     sum_tst                 # salta para subrotina sum_tst
    lw      $ra,0($sp)              # ao retornar, recupera endereço de retorno da pilha
    addiu   $sp,$sp,4               # atualiza apontador de pilha 

# teste de lh, lhu e sh
    la $s7, var_c
    li $s6, 0x1111
    
    sh $s6, 0($s7)                  # var_c[15:0] <= 0x1111 (var_c = 0x00001111)
    li $s6, 0x2222
    sh $s6, 2($s7)                  # var_c[31:16] <= 0x2222 (var_c = 0x22221111)
    
    lh $s5, -20($s7)                # $s5 <= 0xffffed44
    bgez $s5, main                  # Obviamente, esta instrução não deve saltar
    
    lhu $s5, 0($s7)                 # $s5 <= 0x00001111
    lhu $s4, 2($s7)                 # $s4 <= 0x00002222
end:    
    jr      $ra                     # volta para o "sistema operacional" (PROGRAMA ACABA AQUI)

#############################################
# Início da primeira subrotina: sum_tst
############################################
sum_tst:
    la      $t0,var_a               # pega endereço da primeira variável (pseudo-instrução)
    lw      $t0,0($t0)              # toma o valor de var_a e coloca em $t0
    la      $t1,var_b               # pega endereço da segunda variável (pseudo-instrução)
    lw      $t1,0($t1)              # toma o valor de var_b e coloca em $t1
    addu    $t2,$t1,$t0             # soma var_a com var_b e coloca resultado em $t2
    addiu   $sp,$sp,-8              # aloca espaço na pilha
    sw      $t2,0($sp)              # no topo da pilha coloca o resultado da soma
    sw      $ra,4($sp)              # abaixo do topo coloca o endereço de retorno
    la      $t3,ver_ev              # pega endereço da subrotina ver_ev (pseudo-instrução)
    jalr    $t9,$t3                 # chama subrotina que verifica se resultado da soma é par
    lw      $ra,4($sp)              # ao retornar, recupera endereço de retorno da pilha
    addiu   $sp,$sp,8               # atualiza apontador de pilha
    jr      $ra                     #  Retorna para quem chamou

######################################################        
# Início da segunda subrotina: ver_ev. 
# Trata-se de subrotina folha, que não usa pilha
#####################################################
ver_ev:    
    lw      $t3,0($sp)              # tira dados do topo da pilha (parâmetro)
    andi    $t3,$t3,1               # $t3 <= 1 se parâmetro é ímpar, 0 caso contrário
    jr      $t9                     # e retorna

########################################
# área de dados
########################################
    .data
# para trecho que soma constante a vetor
# byte 2 da segunda palavra (0xef) vira 0x10 antes de exec soma_ct
array:      .word    0xabcdef03 0xcdefab18 0xefabcd35 0xbadcfeab 0xdcfebacd 0xfebadc77 0xdefabc53 0xcbafed45
size:       .word    0x8            # número de elementos do vetor
const:      .word    0xffffffff     # constante -1 em complemento de 2

# para trecho de teste de chamadas de subrotinas
var_a:      .word    0xff           # 
var_b:      .word    0x100          #

# para testar acesso a memoria com half word
var_c:      .word    0
