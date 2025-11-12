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
	
	msg_p1: .asciz "      Vez do jogador 1\n"
	msg_p2: .asciz "      Vez do jogador 2\n"
	msg_vitoria_p1: .asciz "\nVitória do Player 1!"
	msg_vitoria_p2: .asciz "\nVitória do Player 2!"
	msg_empate: .asciz "\nO Empate!"
	msg_vitorias_p1: .asciz "Placar; P1 -> "
	msg_vitorias_p2: .asciz " | p2 -> "
	msg_novo_jogo: .asciz "\nDigite 1 para jogar novamente"	
	
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
	la s0, tabuleiro #carrega o endereço inicial do tabuleiro
	lw s2, poco_p1 # deslocamento para o poco p1
	lw s3, poco_p2 # = p2
	
	la a0, msg_bem_vindo
	li a7, 4
	ecall
	
	call inicializar_tabuleiro
	
main_loop:	
	call mostrar_tabuleiro
	
	call verifica_fim_jogo
	li t1, 1
	beq a0, t1, fim_jogo # se o a0 for 1 é pq o jogo acabou
	call processa_jogada
	
	j main_loop
	
inicializar_tabuleiro:
	lw t0, SEEDS_INIT # t0 recebe 4 sementes iniciais
	lw t1, tabuleiro # t1 = 14 cavidades
	li t2, 0 # t2 = i contador
	li t5, 4
init_loop:
	
	beq t2, t1, init_fim # se chegar na ultima cavidade acaba o loop init
	mul t3, t2, t5 # multiplica o indice por 4 para o addi, o deslocamento é de 4 em 4 bytes
	# verifica se algum dos deslocamentos for igual aos dos poços
	beq t3, s2, init_poco
	beq t3, s3, init_poco
	add t4, s0, t3 # t4 recebe o endereço inicial do tabuleiro + deslocamento
	sw t0, 0(t4) # carrega o seeds init na cavidade -> 4 sementes
	j init_continua
	
init_poco:
	add t4, s0, t3
	sw zero, 0(t4) #como é poço preenche com nada = 0

init_fim:
	la t0, player_atual
	li t1, 1
	sw t1, 0(t0)
	ret
	
mostrar_tabuleiro:
	#addi -4 salva um espaço de 4 bytes para o ra
	addi sp, sp, -4
	sw ra, 0(sp)
	
	la a0, msg_mostra_tabuleiro
	li a7, 4
	ecall
	
	la a0, msg_p2
	li a7, 4
	ecall
	
	la a0, espaco
	li a7, 4
	ecall
	
	li t0, 12 #indice t0 que começa em 12
	li t1, 6 #t1 limite do p2, que termina em 6
	
print_loop_p2:
	beq t0, t1, print_loop_p2_fim
	li t6, 4
	mul t2, t0, t6 #deslocamento indice * 4
	add t3, s0, t2 #deslocamento + endereço base = posição desejada
	lw a0, (t3) #carrega o valor de sementes
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
	
	add t0, s0, s2        # Endereço poço P1
	lw a0, (t0)
	li a7, 1
	ecall
	
	la a0, newline
	li a7, 4
	ecall

	#  imprime lado P1 (0 a 5)
	la a0, espaco
	li a7, 4
	ecall

	li t0, 0 # t0 = i (começa em 0)
	li t1, 6 # t1 = limite (para quando i == 6)
	
print_loop_p1:
	beq t0, t1, print_loop_p1_fim
	li t6, 4
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
	la a0, msg_p1
	li a7, 4
	ecall
	
	la a0, newline
	li a7, 4
	ecall
	
	#restaura stack que foi usada para armazenar ra
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

processa_jogada:
	addi sp, sp, -4
	sw ra, 0(sp)
	
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
	mv t3, a0 # t3 recebe a cavidade selecionada
	
	#verifica se está entre 0 e 5 ou 7 e 12(depende se veio de play_p1 ou p2)
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
	j pede_jogada

jogada_sem_sementes:
	la a0, msg_sem_sementes
	li a7, 4
	ecall
	j pedir_jogada
	
fim_processa_jogada:
	lw ra, 0(sp)
	addi sp, sp, 4
	ret
	
distribui_sementes:
	mv t0, a0             # t0 = índice atual
	mv t1, a1             # t1 = sementes na mão
	
	#esvazia a cavidade inicial
	li t6, 4
	mul t2, t0, t6
	add t2, s0, t2
	sw zero, 0(t2)

distribui_loop:
	beq t1, zero, distribui_fim
	
	addi t0, t0, 1
	#se chegar no indice 14, volta para o 0
	lw t2, tabuleiro
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
	lw t4, 0(t3) #carrega sementes atuais
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
	
	j troca_turno
	
distribui_denovo:
	li a0, 1
	ret

troca_turno:
	li a0, 0
	ret