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
	
	li a0, 0 #EXEMPLO RETORNO
	ret

verifica_fim_jogo:
	# Salva registradores que vamos usar
	addi sp, sp, -20
	sw ra, 0(sp)
	sw s4, 4(sp)  # s4 = soma_p1
	sw s5, 8(sp)  # s5 = soma_p2
	sw s6, 12(sp) # s6 = registrador de loop
	sw s7, 16(sp) # s7 = endere�o do po�o

	# 1. Soma as sementes do lado do P1 (cavidades 0-5)
	li s4, 0 # s4 = soma_p1 = 0
	li s6, 0 # s6 = i = 0
check_p1_loop:
	li t0, 6 # limite
	beq s6, t0, check_p1_fim
	
	li t1, 4
	mul t2, s6, t1
	add t3, s0, t2
	lw t4, 0(t3)  # Carrega sementes da cavidade
	add s4, s4, t4 # soma_p1 += sementes
	
	addi s6, s6, 1
	j check_p1_loop
check_p1_fim:

	# 2. Soma as sementes do lado do P2 (cavidades 7-12)
	li s5, 0 # s5 = soma_p2 = 0
	li s6, 7 # s6 = i = 7
check_p2_loop:
	li t0, 13 # limite
	beq s6, t0, check_p2_fim
	
	li t1, 4
	mul t2, s6, t1
	add t3, s0, t2
	lw t4, 0(t3)  # Carrega sementes da cavidade
	add s5, s5, t4 # soma_p2 += sementes
	
	addi s6, s6, 1
	j check_p2_loop
check_p2_fim:

	# 3. Verifica se algum lado est� vazio
	beq s4, zero, game_over # Lado P1 est� vazio?
	beq s5, zero, game_over # Lado P2 est� vazio?
	
	# Se nenhum lado est� vazio, o jogo continua
	li a0, 0 # Retorna 0 (jogo n�o acabou)
	j restore_and_ret

game_over:
	# Jogo acabou. Precisamos fazer a captura final.
	
	# Carrega po�o P1
	add s7, s0, s2 # Endere�o do po�o P1
	lw t0, 0(s7)   # Valor atual po�o P1
	
	# Carrega po�o P2
	add s6, s0, s3 # Endere�o do po�o P2
	lw t1, 0(s6)   # Valor atual po�o P2
	
	# Se o lado P1 (s4) estava vazio, P2 captura o que sobrou (s5)
	# Se o lado P2 (s5) estava vazio, P1 captura o que sobrou (s4)
	
	bne s4, zero, p2_side_empty # O lado P1 N�O estava vazio? Pule.
	
	# Lado P1 estava vazio. Mova s5 (soma P2) para o po�o P2.
	add t1, t1, s5 # po�o_p2 += soma_p2
	sw t1, 0(s6)   # Salva novo valor no po�o P2
	call clear_p2_side # Limpa as cavidades do P2
	j set_game_over_return
	
p2_side_empty:
	# Lado P2 estava vazio. Mova s4 (soma P1) para o po�o P1.
	add t0, t0, s4 # po�o_p1 += soma_p1
	sw t0, 0(s7)   # Salva novo valor no po�o P1
	call clear_p1_side # Limpa as cavidades do P1

set_game_over_return:
	li a0, 1 # Retorna 1 (jogo acabou)

restore_and_ret:
	# Restaura registradores
	lw ra, 0(sp)
	lw s4, 4(sp)
	lw s5, 8(sp)
	lw s6, 12(sp)
	lw s7, 16(sp)
	addi sp, sp, 20
	ret


clear_p1_side:
	# Zera as cavidades 0-5
	addi sp, sp, -4
	sw ra, 0(sp)
	li t0, 0 # i
clear_p1_loop:
	li t1, 6 # limite
	beq t0, t1, clear_p1_end
	
	li t2, 4
	mul t2, t0, t2
	add t3, s0, t2
	sw zero, 0(t3) # Zera a cavidade
	
	addi t0, t0, 1
	j clear_p1_loop
clear_p1_end:
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

clear_p2_side:
	# Zera as cavidades 7-12
	addi sp, sp, -4
	sw ra, 0(sp)
	li t0, 7 # i
clear_p2_loop:
	li t1, 13 # limite
	beq t0, t1, clear_p2_end
	
	li t2, 4
	mul t2, t0, t2
	add t3, s0, t2
	sw zero, 0(t3) # Zera a cavidade
	
	addi t0, t0, 1
	j clear_p2_loop
clear_p2_end:
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

fim_jogo:
	# O jogo acabou (a0 = 1). Vamos verificar quem ganhou.
	
	# Mostra o tabuleiro final
	call mostrar_tabuleiro
	
	# Carrega sementes dos po�os
	add t0, s0, s2 # Endere�o po�o P1
	lw s4, 0(t0)   # s4 = total P1
	add t1, s0, s3 # Endere�o po�o P2
	lw s5, 0(t1)   # s5 = total P2
	
	# Compara os totais
	bgt s4, s5, vitoria_p1
	bgt s5, s4, vitoria_p2
	
	# Se n�o for maior, � empate
	la a0, msg_empate
	li a7, 4
	ecall
	j fim_contagem # Pula para o fim

vitoria_p1:
	la a0, msg_vitoria_p1
	li a7, 4
	ecall
	# Incrementa vit�rias P1
	la t0, vitorias_p1
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	j fim_contagem

vitoria_p2:
	la a0, msg_vitoria_p2
	li a7, 4
	ecall
	# Incrementa vit�rias P2
	la t0, vitorias_p2
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	j fim_contagem

fim_contagem:
	# Mostra o placar
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
	
	# Pergunta se quer jogar novamente
	la a0, msg_novo_jogo
	li a7, 4
	ecall
	
	la a0, newline # (Corrigindo: seu .data tem 'mewline', n�o 'newline')
	li a7, 4
	ecall
	
	li a7, 5 # L� um inteiro
	ecall
	
	li t0, 1
	beq a0, t0, novo_jogo # Se digitou 1, joga de novo
	
	# Se n�o, encerra o programa
	li a7, 10
	ecall

novo_jogo:
	call inicializar_tabuleiro
	j main_loop
