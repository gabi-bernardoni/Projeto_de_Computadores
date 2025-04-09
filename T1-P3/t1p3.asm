    .data
led_register: .word 0           # Simulacao do registrador de LEDs

    .text
    .globl main

main:
    li $t0, 0                   # Inicializa contador em 0
    li $t1, 15                  # Valor maximo do contador

loop:
    sw $t0, led_register        # Atualiza os LEDs com o valor do contador
    jal delay_1s                # Chama a funcao de atraso de 1 segundo

    addi $t0, $t0, 1            # Incrementa o contador
    bne $t0, $t1, loop          # Se contador < 15, continua no loop

    j end

# Funcao de atraso de 1 segundo (baseado no clock de 25MHz)
delay_1s:
    li $t2, 25000000            # 1 segundo de espera (25M ciclos)

delay_loop:
    addi $t2, $t2, -1           # Decrementa contador
    bne $t2, $zero, delay_loop  # Enquanto nao for zero, continua

    jr $ra                      # Retorna para a funcao principal
    
end:
    j end
