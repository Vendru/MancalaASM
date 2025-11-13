.data
	SEEDS_INIT: .word 4
	poco_p1: .word 24 # índice 6*4 bytes
	poco_p2: .word 52 # 13*4
	tamanho_tabuleiro: .word 56

	
	player_atual: .word 1
	vitorias_p1: .word 0
	vitorias_p2: .word 0

	msg_bem_vindo: .asciz "Bem vindo ao jogo de Mancala\n"
	msg_mostra_tabuleiro: .asciz "Tabuleiro atual:\n"
	msg_play_p1: .asciz "Player 1\nEscolha uma cavidade entre [0-5]: "
	msg_play_p2: .asciz "Player 2\nEscolha uma cavidade entre [7-12]: "
	msg_sem_sementes: .asciz "Esta cavidade não está semeada, escolha uma com sementes.\n"
	msg_invalida: .asciz "Esta cavidade não é válida, tente novamente.\n"
	

	msg_vitoria_p1: .asciz "\nVitória do Player 1!"
	msg_vitoria_p2: .asciz "\nVitória do Player 2!"
	msg_empate: .asciz "\nO Empate!"
	msg_vitorias_p1: .asciz "Placar; P1 -> "
	msg_vitorias_p2: .asciz " | P2 -> "
	msg_novo_jogo: .asciz "\nDigite 1 para jogar novamente, 0 para sair"	
	
	barra: .asciz " | "
	espaco: .asciz " "
	newline: .asciz "\n"
	
.align 2
	tabuleiro: .space 56 # 14 cavidades

.text
	# s0: ponteiro base do tabuleiro
	# s1: player_atual (1 ou 2)
	# s2: offset poço P1 (24)
	# s3: offset poço P2 (52)
	
main:
	la s0, tabuleiro 
	lw s2, poco_p1 
	lw s3, poco_p2
	
	la a0, msg_bem_vindo
	li a7, 4
	ecall
	
	call inicializar_tabuleiro
	
main_loop:	
	call mostrar_tabuleiro
	
	call verifica_fim_jogo
	li t1, 1
	beq a0, t1, game_over 
	call processa_jogada
	
	j main_loop
	
inicializar_tabuleiro:
	lw t0, SEEDS_INIT 
	
	li t1, 14 
	
	li t2, 0 
	li t6, 4 
	
init_loop:
	beq t2, t1, init_fim 
	
	mul t3, t2, t6 
	
	beq t3, s2, init_poco
	beq t3, s3, init_poco
	
	add t4, s0, t3 
	sw t0, 0(t4) 
	j init_continua
	
init_poco:
	add t4, s0, t3
	sw zero, 0(t4)

init_continua:
	addi t2, t2, 1
	j init_loop
	
init_fim:
	la t0, player_atual
	li t1, 1
	sw t1, 0(t0)
	ret
	
mostrar_tabuleiro:
	addi sp, sp, -4
	sw ra, 0(sp)
	
	la a0, msg_mostra_tabuleiro
	li a7, 4
	ecall
	
	la a0, espaco
	li a7, 4
	ecall
	
	li t0, 12 
	li t1, 6 
	li t6, 4 
	
print_loop_p2:
	beq t0, t1, print_loop_p2_fim
	
	mul t2, t0, t6 
	add t3, s0, t2 
	lw a0, 0(t3) 
	li a7, 1
	ecall
	
	la a0, barra
	li a7, 4
	ecall
	
	addi t0, t0, -1
	j print_loop_p2

print_loop_p2_fim:
	la a0, newline
	li a7, 4
	ecall
	
	add t0, s0, s3
	lw a0, 0(t0)
	li a7, 1
	ecall
	
	li t0, 6
print_espacos_meio:
	beq t0, zero, print_espacos_meio_fim
	la a0, espaco
	li a7, 4
	ecall
	la a0, barra
	li a7, 4
	ecall
	addi t0, t0, -1
	j print_espacos_meio
	
print_espacos_meio_fim:
	
	add t0, s0, s2    
	lw a0, 0(t0)
	li a7, 1
	ecall
	
	la a0, newline
	li a7, 4
	ecall

	la a0, espaco
	li a7, 4
	ecall

	li t0, 0
	li t1, 6
	li t6, 4
	
print_loop_p1:
	beq t0, t1, print_loop_p1_fim
	
	mul t2, t0, t6
	add t3, s0, t2
	lw a0, 0(t3)
	li a7, 1
	ecall
	
	la a0, barra
	li a7, 4
	ecall
	
	addi t0, t0, 1
	j print_loop_p1
	
print_loop_p1_fim:
	la a0, newline
	li a7, 4
	ecall
	
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

processa_jogada:
	addi sp, sp, -4
	sw ra, 0(sp)
	
loop_pede_jogada:
	la t0, player_atual
	lw s1,(t0)
	
	li t0, 1
	beq s1, t0, play_p1
	
play_p2:
	la a0, msg_play_p2
	li t1, 7
	li t2, 12
	j pede_jogada
	
play_p1:
	la a0, msg_play_p1
	li t1, 0
	li t2, 5

pede_jogada:
	li a7,4
	ecall
	li a7, 5
	ecall
	mv t3, a0 

	blt t3,t1, jogada_invalida
	bgt t3,t2, jogada_invalida
	
	li t6, 4
	mul t4, t3, t6
	add t5, s0, t4
	lw t6, 0(t5)
	
	beq t6, zero, jogada_sem_sementes
	
	mv a0, t3
	mv a1, t6
	call distribui_sementes
	
	li s4, 1
	beq a0, s4, fim_processa_jogada
	
	li t0, 1
	beq s1, t0, set_p2
	
set_p1:
	li t1, 1
	j salva_turno
	
set_p2:
	li t1, 2

salva_turno:
	la t0, player_atual
	sw t1, 0(t0)
	j fim_processa_jogada

jogada_invalida:
	la a0, msg_invalida
	li a7, 4
	ecall
	j loop_pede_jogada

jogada_sem_sementes:
	la a0, msg_sem_sementes
	li a7, 4
	ecall
	j loop_pede_jogada
	
fim_processa_jogada:
	lw ra, 0(sp)
	addi sp, sp, 4
	ret
	
distribui_sementes:
	mv t0, a0
	mv t1, a1
	

	li t6, 4
	mul t2, t0, t6
	add t2, s0, t2
	sw zero, 0(t2)

distribui_loop:
	beq t1, zero, distribui_fim
	
	addi t0, t0, 1
	
	li t2, 14
	
	bne t0, t2, distribui_continua
	li t0, 0
distribui_continua:

	li t6, 4
	mul t2, t0, t6
	
	li t3, 1
	beq s1, t3, checa_poco_p2
	
	beq t2, s2, distribui_loop
	j distribui_plantar
	
checa_poco_p2:
	beq t2, s3, distribui_loop
	
distribui_plantar:
	add t3, s0, t2
	lw t4, 0(t3) 
	addi t4, t4, 1
	sw t4, 0(t3)
	
	addi t1, t1, -1
	j distribui_loop
	
distribui_fim:
	li t1, 1
	beq s1, t1, checa_poco_p1
	
	beq t2, s3, distribui_denovo
	j checa_captura
	
checa_poco_p1:
	beq t2, s2, distribui_denovo
	
checa_captura:
	li t6, 1
	bne t4, t6, troca_turno
	
	
	li t3, 1
	beq s1, t3, checa_lado_p1
	
	li t5, 7
	blt t0, t5, troca_turno
	li t5, 12
	bgt t0, t5, troca_turno
	j captura
	
checa_lado_p1:
	li t5,5
	bgt t0, t5, troca_turno
	
captura:
	li t5,12
	sub t5, t5, t0
	li t6, 4
	mul t5, t5, t6 
	add t5, s0, t5 
	lw t6, 0(t5)
	sw zero, 0(t5)
	
	beq t6, zero, troca_turno
	addi t6, t6, 1 
	add t3, s0, t2
	sw zero, 0(t3)
	
	li t3, 1
	beq s1, t3, add_poco_p1
	
	add t5, s0, s3
	lw t4, 0(t5)
	add t4, t4, t6
	sw t4, 0(t5)
	j troca_turno
	
add_poco_p1:
	add t5, s0, s2
	lw t4, 0(t5)
	add t4, t4, t6
	sw t4, 0(t5)
	j troca_turno
	
distribui_denovo:
	li a0, 1
	ret

troca_turno:
	li a0, 0
	ret
	
verifica_fim_jogo:
	addi sp, sp, -20
	sw ra, 0(sp)
	sw s4, 4(sp) 
	sw s5, 8(sp) 
	sw s6, 12(sp) 
	sw s7, 16(sp) 

	li s4, 0 
	li s6, 0 
	li t1, 4 
checa_p1_loop:
	li t0, 6
	beq s6, t0, check_p1_fim
	
	mul t2, s6, t1
	add t3, s0, t2
	lw t4, 0(t3)  
	add s4, s4, t4
	
	addi s6, s6, 1
	j checa_p1_loop
check_p1_fim:

	li s5, 0
	li s6, 7
	li t1, 4 
checa_p2_loop:
	li t0, 13 
	beq s6, t0, checa_p2_fim
	
	mul t2, s6, t1
	add t3, s0, t2
	lw t4, 0(t3)
	add s5, s5, t4
	
	addi s6, s6, 1
	j checa_p2_loop
checa_p2_fim:

	beq s4, zero, captura_final
	beq s5, zero, captura_final
	
	li a0, 0 
	j restaura_reg

captura_final:
	add s7, s0, s2 
	lw t0, 0(s7)   
	
	add s6, s0, s3 
	lw t1, 0(s6)   
	
	
	bne s4, zero, p2_vazio 
	
	add t1, t1, s5 
	sw t1, 0(s6)   
	call limpa_p2 
	j seta_game_over
	
p2_vazio:
	add t0, t0, s4 
	sw t0, 0(s7)
	call limpa_p1 
seta_game_over:
	li a0, 1

restaura_reg:
	lw ra, 0(sp)
	lw s4, 4(sp)
	lw s5, 8(sp)
	lw s6, 12(sp)
	lw s7, 16(sp)
	addi sp, sp, 20
	ret


limpa_p1:
	addi sp, sp, -4
	sw ra, 0(sp)
	li t0, 0 
	li t2, 4 
limpa_p1_loop:
	li t1, 6 
	beq t0, t1, limpa_p1_fim
	
	mul t3, t0, t2
	add t3, s0, t3
	sw zero, 0(t3)
	
	addi t0, t0, 1
	j limpa_p1_loop
limpa_p1_fim:
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

limpa_p2:
	addi sp, sp, -4
	sw ra, 0(sp)
	li t0, 7 
	li t2, 4 
limpa_p2_loop:
	li t1, 13 
	beq t0, t1, limpa_p2_fim
	
	mul t3, t0, t2
	add t3, s0, t3
	sw zero, 0(t3)
	
	addi t0, t0, 1
	j limpa_p2_loop
limpa_p2_fim:
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

game_over:
	call mostrar_tabuleiro
	

	add t0, s0, s2 
	lw s4, 0(t0) 
	add t1, s0, s3 
	lw s5, 0(t1)
	
	bgt s4, s5, vitoria_p1
	bgt s5, s4, vitoria_p2
	
	la a0, msg_empate
	li a7, 4
	ecall
	j fim_contagem 

vitoria_p1:
	la a0, msg_vitoria_p1
	li a7, 4
	ecall

	la t0, vitorias_p1
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	j fim_contagem

vitoria_p2:
	la a0, msg_vitoria_p2
	li a7, 4
	ecall

	la t0, vitorias_p2
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	j fim_contagem

fim_contagem:
	la a0, msg_vitorias_p1
	li a7, 4
	ecall
	
	la t0, vitorias_p1
	lw a0, 0(t0)
	li a7, 1
	ecall
	
	la a0, msg_vitorias_p2
	li a7, 4
	ecall
	
	la t0, vitorias_p2
	lw a0, 0(t0)
	li a7, 1
	ecall
	
	la a0, msg_novo_jogo
	li a7, 4
	ecall
	
	la a0, newline
	li a7, 4
	ecall
	
	li a7, 5
	ecall
	
	li t0, 1
	beq a0, t0, novo_jogo
	
	li a7, 10
	ecall

novo_jogo:
	call inicializar_tabuleiro
	j main_loop