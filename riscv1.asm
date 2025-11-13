# Wendell Luis Neris - 2311100035
# Bruno Vendruscolo - 2221100004
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
	linha: .asciz " ---"
	
.align 2
	tabuleiro: .space 56 # 14 cavidades

.text
	# s0: ponteiro base do tabuleiro
	# s1: player_atual (1 ou 2)
	# s2: offset poço P1 (24)
	# s3: offset poço P2 (52)
	
main:
	la s0, tabuleiro 
	lw s2, poco_p1 #24 para poco p1
	lw s3, poco_p2 #52 para poco p2
	
	la a0, msg_bem_vindo
	li a7, 4
	ecall
	
	call inicializar_tabuleiro #chama função que semeia o tabuleiro inicialmente
	
main_loop:	
	call mostrar_tabuleiro #imprime o estado atual do tabuleiro
	
	call verifica_fim_jogo #chama função que verifica se um lado do tabuleiro ta vazio
	li t1, 1
	beq a0, t1, game_over 
	call processa_jogada #processa a jogada do jogador se o jogo não acabar
	
	j main_loop
	
inicializar_tabuleiro: #prenche tudo com 4 menos os poços
	lw t0, SEEDS_INIT 
	
	li t1, 14 #limite do loop
	
	li t2, 0  #contador
	li t6, 4 
	
init_loop:
	beq t2, t1, init_fim 
	
	mul t3, t2, t6 
	
	beq t3, s2, init_poco # se entrar em um desses é poço então preenche com 0
	beq t3, s3, init_poco
	
	add t4, s0, t3  #endereço da cavidade
	sw t0, 0(t4) 
	j init_continua
	
init_poco:
	add t4, s0, t3
	sw zero, 0(t4) #armazena 0 no poço

init_continua:
	addi t2, t2, 1 #adiciona no contador 
	j init_loop
	
init_fim: #armazena o valor de qual jogador é o atual
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
	
	li t0, 12  #indice = 12 (lado p2)
	li t1, 6  #limite 6 (vai parar antes do 6 -> 7)
	li t6, 4 
	
print_loop_p2:
	beq t0, t1, print_loop_p2_fim #se chegar em 6 acabou o tabuleiro do p2
	
	mul t2, t0, t6 #offset
	add t3, s0, t2 #endereço do indice
	lw a0, 0(t3) 
	li a7, 1
	ecall
	
	la a0, barra
	li a7, 4
	ecall
	
	addi t0, t0, -1 #decrementa para imprimir p2 de 12 pra 7
	j print_loop_p2

print_loop_p2_fim:
	la a0, newline
	li a7, 4
	ecall
	
	add t0, s0, s3 #chega no poço de p2 e imprime o valor
	lw a0, 0(t0)
	li a7, 1
	ecall
	
	li t0, 6 #contador para separadores do print
print_espacos_meio:
	beq t0, zero, print_espacos_meio_fim
	la a0, linha
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

	li t0, 0 #ao inves de 12, agora é 0 pois é o lado p1
	li t1, 6
	li t6, 4
	
print_loop_p1:
	beq t0, t1, print_loop_p1_fim
	
	mul t2, t0, t6 #offset
	add t3, s0, t2 #endereco
	lw a0, 0(t3) #carrega e imprime o valor
	li a7, 1
	ecall
	
	la a0, barra
	li a7, 4
	ecall
	
	addi t0, t0, 1 #aumenta o indice pois está sendo impresso de 0 a 5
	j print_loop_p1
	
print_loop_p1_fim:
	la a0, newline
	li a7, 4
	ecall
	
	lw ra, 0(sp)
	addi sp, sp, 4
	ret #retorna para mostra tabuleiro

processa_jogada: #valida e processa jogada do jogador atual,
	addi sp, sp, -4
	sw ra, 0(sp)#armazena o ra
	
loop_pede_jogada:
	la t0, player_atual
	lw s1,(t0)
	
	li t0, 1
	beq s1, t0, play_p1 #verifica de qual player é a vez de jogar
	
play_p2:
	la a0, msg_play_p2
	li t1, 7
	li t2, 12 	#p2 joga de 7 a 12, t1 e t2 sao limites
	j pede_jogada
	
play_p1:
	la a0, msg_play_p1
	li t1, 0	#p1 joga de 0 a 5
	li t2, 5

pede_jogada: #carrega o indice que o jogador escolhe jogar
	li a7,4
	ecall
	li a7, 5
	ecall
	mv t3, a0 
			#verifica se a jogada está entre o limite permitido, caso não vai para jogada invalida
	blt t3,t1, jogada_invalida
	bgt t3,t2, jogada_invalida

	li t6, 4
	mul t4, t3, t6
	add t5, s0, t4
	lw t6, 0(t5)
	
	beq t6, zero, jogada_sem_sementes 	#verifica se a cavidade tem sementes
	
	mv a0, t3 #indice escolhido
	mv a1, t6 #qtd sementes
	call distribui_sementes
	
	li s4, 1 #se a0 for 1 joga dnv
	beq a0, s4, fim_processa_jogada
	
	li t0, 1 # se for 0 troca o turno
	beq s1, t0, set_p2
	
set_p1: # era o p2, vai pra p1
	li t1, 1
	j salva_turno
	
set_p2: #era p1, vai pra p2
	li t1, 2

salva_turno: #salva quem é o jogador atual no "player atual" e vai pro fim da função
	la t0, player_atual
	sw t1, 0(t0)
	j fim_processa_jogada

jogada_invalida: #mostra a msg de inválida e volta pro inicio do loop
	la a0, msg_invalida
	li a7, 4
	ecall
	j loop_pede_jogada

jogada_sem_sementes:	#mostra a msg de sem sementes e volta pro inicio do loop
	la a0, msg_sem_sementes
	li a7, 4
	ecall
	j loop_pede_jogada
	
fim_processa_jogada: # libera a pilha e volta pra chamada da processa jogada + 4
	lw ra, 0(sp)
	addi sp, sp, 4
	ret
	
distribui_sementes: #t0 indice atual #t1 sementes na mão
	mv t0, a0
	mv t1, a1
	
	#esvazia a cavidade inicial
	li t6, 4
	mul t2, t0, t6
	add t2, s0, t2
	sw zero, 0(t2)

distribui_loop: 
	beq t1, zero, distribui_fim #se 0 sementes -> fim
	
	addi t0, t0, 1 #incrementa o indice
	
	li t2, 14 #limite do tabuleiro
	
	bne t0, t2, distribui_continua #se não for a ultima casa continua
	li t0, 0 # se for volta pra casa 0 (da a volta)
distribui_continua:

	li t6, 4
	mul t2, t0, t6 #offset indice atual
	
	li t3, 1
	beq s1, t3, checa_poco_p2 #se for p1, checa se é o poco do p2
	
	beq t2, s2, distribui_loop # se ta aqui é p2, pula o poço p1 se o offset do indice for igual offset do poço do p1
	j distribui_plantar # se nao for o poço do p1 pode plantar
	
checa_poco_p2:
	beq t2, s3, distribui_loop # se for o poço do p2 pula
	
distribui_plantar: #planta 1 semente na cavidade (soma 1 no valor do endereço)
	add t3, s0, t2
	lw t4, 0(t3) 
	addi t4, t4, 1
	sw t4, 0(t3)
	
	addi t1, t1, -1 #decrementa 1 semente da mão 
	j distribui_loop
	
distribui_fim: #t0 indice ultima semente, #t2 offset, t4 sementes na cavidade
	li t1, 1
	beq s1, t1, checa_poco_p1 #p1 checa se é poço a ultima casa 
	
	beq t2, s3, distribui_denovo #se cair aqui é p2, verifica se é poço
	j checa_captura
	
checa_poco_p1:
	beq t2, s2, distribui_denovo #se for distribui dnv
	
checa_captura:
	#condição 2: caiu numa cavidade que agora tem 1 semente
	li t6, 1
	bne t4, t6, troca_turno
	#condição 1: caiu no lado do player atual
	li t3, 1
	beq s1, t3, checa_lado_p1 #se for p1 checa o lado do p1
	#se não checa o lado p2
	li t5, 7
	blt t0, t5, troca_turno
	li t5, 12
	bgt t0, t5, troca_turno
	j captura
	
checa_lado_p1: #checa se está num indice menor ou igual a 5, para ver se é do p1
	li t5, 5
	bgt t0, t5, troca_turno
	
captura:
	#verifica se a cavidade oposta, 12 - indice atual, tem sementes
	li t5,12
	sub t5, t5, t0
	li t6, 4
	mul t5, t5, t6 
	add t5, s0, t5 
	lw t6, 0(t5)
	sw zero, 0(t5)
	
	beq t6, zero, troca_turno # se não tiver, troca de turno
				#se tiver, adiciona 1 + a cavidade oposta e zera a cavidade oposta
	addi t6, t6, 1 
	add t3, s0, t2
	sw zero, 0(t3)
				
	li t3, 1
	beq s1, t3, add_poco_p1 #se for p1, adiciona no poço 1
	
	#se não adiciona no poço 2
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
	li a0, 1 # a0 é 1 pra rodar dnv
	ret

troca_turno:
	li a0, 0 #a0 é 0 pra trocar de turno
	ret
	
verifica_fim_jogo: #soma os lados p1 e p2, se algum for 0, limpa o outro e retorna 1 em a0 pro jogo acabar
	addi sp, sp, -20
	sw ra, 0(sp)
	sw s4, 4(sp) 
	sw s5, 8(sp) 
	sw s6, 12(sp) 
	sw s7, 16(sp) 

	li s4, 0  #s4 da soma
	li s6, 0  #contador
	li t1, 4 
checa_p1_loop:
	#percorre os endereços e soma todas as sementes
	li t0, 6
	beq s6, t0, check_p1_fim
	
	mul t2, s6, t1
	add t3, s0, t2
	lw t4, 0(t3)  
	add s4, s4, t4
	
	addi s6, s6, 1
	j checa_p1_loop
check_p1_fim:
	#soma as sementes do lado do p2
	li s5, 0
	li s6, 7
	li t1, 4 
checa_p2_loop:
	li t0, 13 
	beq s6, t0, checa_p2_fim
	#percorre e soma
	mul t2, s6, t1
	add t3, s0, t2
	lw t4, 0(t3)
	add s5, s5, t4
	
	addi s6, s6, 1
	j checa_p2_loop
checa_p2_fim:
	#pega os valores somados e vê se algum da 0(vazio)
	beq s4, zero, captura_final
	beq s5, zero, captura_final
	#se não as pilhas sao liberadas e o jogo continua
	li a0, 0 
	j restaura_reg

captura_final:	#jogo acabou então ocorre a captura final

	#pega o valor dos poços
	
	#p1
	add s7, s0, s2 
	lw t0, 0(s7)   
	
	#p2
	add s6, s0, s3 
	lw t1, 0(s6)   
	
	
	bne s4, zero, p2_vazio
	#p1 vazio, move sementes para poço p2 e limpa o lado
	add t1, t1, s5 
	sw t1, 0(s6)   
	call limpa_p2 
	j seta_game_over
	
p2_vazio: #p2 tava vazio, então move sementes para poço p1 e limpa o lado
	add t0, t0, s4 
	sw t0, 0(s7)
	call limpa_p1 
	
seta_game_over:
	li a0, 1 #acaba o jogo

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
	
	#carrega as sementes dos poços
	add t0, s0, s2 
	lw s4, 0(t0) 
	add t1, s0, s3 
	lw s5, 0(t1)
	#compara pra ver quem ganhou e então vai para armazenar a vitoria
	bgt s4, s5, vitoria_p1
	bgt s5, s4, vitoria_p2
	#se der empate acaba a contagem
	la a0, msg_empate
	li a7, 4
	ecall
	j fim_contagem 

vitoria_p1: #carrega msg vitoria e incrementa 1 no placar pro lado do p1
	la a0, msg_vitoria_p1
	li a7, 4
	ecall

	la t0, vitorias_p1
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	j fim_contagem

vitoria_p2:#carrega msg vitoria e incrementa 1 no placar pro lado do p2
	la a0, msg_vitoria_p2
	li a7, 4
	ecall

	la t0, vitorias_p2
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	j fim_contagem

fim_contagem: #mostra o placar e pede se quer começar novo jogo 1 - sim 0, - não
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
