    .data
led_register: .word 0           # Simulação do registrador de LEDs

    .text
    .globl main

main:
    li $t0, 0                   # Inicializa contador em 0
    li $t1, 15                  # Valor máximo do contador

loop:
    sw $t0, led_register        # Atualiza os LEDs com o valor do contador
    jal delay_1s                # Chama a função de atraso de 1 segundo

    addi $t0, $t0, 1            # Incrementa o contador
    bne $t0, $t1, loop          # Se contador < 15, continua no loop

    j end

# Função de atraso de 1 segundo (baseado no clock de 25MHz)
delay_1s:
    li $t2, 25000000            # 1 segundo de espera (25M ciclos)

delay_loop:
    addi $t2, $t2, -1           # Decrementa contador
    bne $t2, $zero, delay_loop  # Enquanto não for zero, continua

    jr $ra                      # Retorna para a função principal
    
end:
    j end
