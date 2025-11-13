.data
	SEEDS_INIT: .word 4 		# Define o número inicial de sementes (4) por cavidade
	poco_p1: .word 24 		# Define o offset (deslocamento) em bytes para o poço do P1 (6 cavidades * 4 bytes)
	poco_p2: .word 52 		# Define o offset em bytes para o poço do P2 (13 cavidades * 4 bytes)
	tamanho_tabuleiro: .word 56 	# Define o tamanho total em bytes do tabuleiro (14 cavidades * 4 bytes)

	
	player_atual: .word 1 		# Variável para guardar o turno atual (1 ou 2)
	vitorias_p1: .word 0 		# Variável para contar as vitórias do Jogador 1
	vitorias_p2: .word 0 		# Variável para contar as vitórias do Jogador 2

	# --- Mensagens de Interface ---
	msg_bem_vindo: .asciz "Bem vindo ao jogo de Mancala\n"
	msg_mostra_tabuleiro: .asciz "Tabuleiro atual:\n"
	msg_play_p1: .asciz "Player 1\nEscolha uma cavidade entre [0-5]: "
	msg_play_p2: .asciz "Player 2\nEscolha uma cavidade entre [7-12]: "
	msg_sem_sementes: .asciz "Esta cavidade não está semeada, escolha uma com sementes.\n"
	msg_invalida: .asciz "Esta cavidade não é válida, tente novamente.\n"
	
	msg_p1: .asciz "      Vez do jogador 1\n" # (Nota: Esta msg não está a ser usada no seu código, 'mostrar_tabuleiro' não a chama)
	msg_p2: .asciz "      Vez do jogador 2\n" # (Nota: Esta msg não está a ser usada no seu código, 'mostrar_tabuleiro' não a chama)
	msg_vitoria_p1: .asciz "\nVitória do Player 1!"
	msg_vitoria_p2: .asciz "\nVitória do Player 2!"
	msg_empate: .asciz "\nO Empate!"
	msg_vitorias_p1: .asciz "Placar; P1 -> "
	msg_vitorias_p2: .asciz " | P2 -> "
	msg_novo_jogo: .asciz "\nDigite 1 para jogar novamente, 0 para sair"	
	
	barra: .asciz " | " 		# String para o separador visual
	espaco: .asciz " " 		# String para o espaço
	newline: .asciz "\n" 		# String para nova linha
	
.align 2 				# Alinha os dados seguintes em 4 bytes (para .space)
	tabuleiro: .space 56 		# Reserva 56 bytes (14 cavidades * 4 bytes) na memória para o tabuleiro

.text
	# --- Definição dos Registradores Salvos (s) ---
	# s0: ponteiro base do tabuleiro (endereço de 'tabuleiro')
	# s1: player_atual (carregado com 1 ou 2 quando necessário)
	# s2: offset poço P1 (carregado com 24)
	# s3: offset poço P2 (carregado com 52)
	
main:
	la s0, tabuleiro 	# Carrega o endereço (Load Address) de 'tabuleiro' para o registrador s0
	lw s2, poco_p1 		# Carrega o valor (Load Word) de 'poco_p1' (24) para s2
	lw s3, poco_p2 		# Carrega o valor (Load Word) de 'poco_p2' (52) para s3
	
	la a0, msg_bem_vindo 	# Carrega o endereço da mensagem de boas-vindas para a0 (argumento da syscall)
	li a7, 4 		# Carrega o código da syscall 4 (print string) para a7
	ecall 			# Executa a chamada de sistema (imprime a string)
	
	call inicializar_tabuleiro # Chama a função que vai preencher o tabuleiro com sementes
	
main_loop:	
	call mostrar_tabuleiro 	# Chama a função que imprime o estado atual do tabuleiro
	
	call verifica_fim_jogo 	# Chama a função que verifica se um dos lados está vazio
	li t1, 1 		# Carrega o número 1 para t1 (para comparar com o retorno da função)
	beq a0, t1, game_over 	# Salta (Branch) se a0 (retorno) == 1 (jogo acabou) para a etiqueta 'game_over'
	call processa_jogada 	# Se o jogo não acabou, chama a função que processa a jogada do jogador
	
	j main_loop 		# Salta incondicionalmente de volta para o início do 'main_loop'
	
# -----------------------------------------------------------------
# Função: inicializar_tabuleiro
# Preenche o tabuleiro com 4 sementes (de SEEDS_INIT), exceto os poços (que são 0)
# -----------------------------------------------------------------
inicializar_tabuleiro:
	lw t0, SEEDS_INIT 	# Carrega o valor 4 da variável 'SEEDS_INIT' para t0
	
	# --- CORREÇÃO ---
	li t1, 14 		# Carrega o número 14 (total de cavidades) para t1 (limite do loop)
	# ------------------
	
	li t2, 0 		# Inicializa o contador 'i' (índice) em t2 com 0
	li t6, 4 		# Carrega o número 4 para t6 (para multiplicar o índice pelo tamanho da word)
	
init_loop:
	beq t2, t1, init_fim 	# Salta se t2 (i) == t1 (14) para 'init_fim' (fim do loop)
	
	mul t3, t2, t6 		# Calcula o offset em bytes: t3 = t2 (i) * t6 (4)
	
	# verifica se o offset (t3) é igual ao dos poços (s2 ou s3)
	beq t3, s2, init_poco 	# Salta se o offset t3 == offset do poço P1 (s2)
	beq t3, s3, init_poco 	# Salta se o offset t3 == offset do poço P2 (s3)
	
	add t4, s0, t3 		# Calcula o endereço da cavidade: t4 = s0 (base) + t3 (offset)
	sw t0, 0(t4) 		# Armazena (Store Word) o valor de t0 (4 sementes) no endereço t4
	j init_continua 	# Salta para continuar o loop
	
init_poco:
	add t4, s0, t3 		# Calcula o endereço da cavidade (que é um poço)
	sw zero, 0(t4) 		# Armazena 0 (registrador zero) no endereço do poço

init_continua:
	addi t2, t2, 1 		# Incrementa o contador: i++
	j init_loop 		# Salta de volta para o início do 'init_loop'
	
init_fim:
	la t0, player_atual 	# Carrega o endereço da variável 'player_atual' para t0
	li t1, 1 		# Carrega o número 1 (Jogador 1) para t1
	sw t1, 0(t0) 		# Armazena o valor 1 na variável 'player_atual'
	ret 			# Retorna da função 'inicializar_tabuleiro'
	
# -----------------------------------------------------------------
# Função: mostrar_tabuleiro
# Imprime o tabuleiro formatado no terminal
# -----------------------------------------------------------------
mostrar_tabuleiro:
	addi sp, sp, -4 	# Aloca 4 bytes na pilha (stack) (move o ponteiro da pilha para baixo)
	sw ra, 0(sp) 		# Armazena o 'ra' (Return Address) na pilha, para saber para onde voltar
	
	la a0, msg_mostra_tabuleiro # Carrega o endereço da string "Tabuleiro atual:" para a0
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a string)
	
	# (Nota: As suas mensagens msg_p1 e msg_p2 não estão a ser impressas aqui)
	
	la a0, espaco 		# Carrega o endereço da string " "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime um espaço inicial)
	
	li t0, 12 		# Inicializa o índice 'i' (em t0) em 12 (lado P2)
	li t1, 6 		# Define o limite 'i' (em t1) em 6 (para parar *antes* de 6)
	li t6, 4 		# Carrega o número 4 para t6 (para multiplicação)
	
print_loop_p2:
	beq t0, t1, print_loop_p2_fim # Salta se t0 (i) == t1 (6) para 'print_loop_p2_fim'
	
	mul t2, t0, t6 		# Calcula o offset em bytes: t2 = t0 (i) * t6 (4)
	add t3, s0, t2 		# Calcula o endereço: t3 = s0 (base) + t2 (offset)
	lw a0, 0(t3) 		# Carrega o valor (word) da cavidade (endereço t3) para a0
	li a7, 1 		# Carrega a syscall 1 (print integer) para a7
	ecall 			# Executa (imprime o número de sementes)
	
	la a0, barra 		# Carrega o endereço da string " | "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime o separador)
	
	addi t0, t0, -1 	# Decrementa o índice 'i' (para imprimir P2 ao contrário, de 12 para 7)
	j print_loop_p2 	# Salta de volta para o 'print_loop_p2'

print_loop_p2_fim:
	la a0, newline 		# Carrega o endereço da string "\n"
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a nova linha)
	
	add t0, s0, s3 		# Calcula o endereço do poço P2: t0 = s0 (base) + s3 (offset 52)
	lw a0, 0(t0) 		# Carrega o valor (sementes) do poço P2 para a0
	li a7, 1 		# Carrega a syscall 1 (print integer)
	ecall 			# Executa (imprime o placar P2)
	
	li t0, 6 		# Inicializa um contador (t0) em 6 (para imprimir 6 separadores)
print_espacos_meio:
	beq t0, zero, print_espacos_meio_fim # Salta se o contador t0 == 0
	la a0, espaco 		# Carrega o endereço da string " "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime espaço)
	la a0, barra 		# Carrega o endereço da string " | "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime separador)
	addi t0, t0, -1 	# Decrementa o contador
	j print_espacos_meio 	# Salta de volta para 'print_espacos_meio'
	
print_espacos_meio_fim:
	
	add t0, s0, s2		# Calcula o endereço do poço P1: t0 = s0 (base) + s2 (offset 24)
	lw a0, 0(t0) 		# Carrega o valor (sementes) do poço P1 para a0
	li a7, 1 		# Carrega a syscall 1 (print integer)
	ecall 			# Executa (imprime o placar P1)
	
	la a0, newline 		# Carrega o endereço da string "\n"
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a nova linha)

	# imprime lado P1 (0 a 5)
	la a0, espaco 		# Carrega o endereço da string " "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime um espaço inicial)

	li t0, 0 		# Inicializa o índice 'i' (em t0) em 0 (lado P1)
	li t1, 6 		# Define o limite 'i' (em t1) em 6 (para parar em 6)
	li t6, 4 		# Carrega o número 4 para t6 (para multiplicação)
	
print_loop_p1:
	beq t0, t1, print_loop_p1_fim # Salta se t0 (i) == t1 (6) para 'print_loop_p1_fim'
	
	mul t2, t0, t6 		# Calcula o offset em bytes: t2 = t0 (i) * t6 (4)
	add t3, s0, t2 		# Calcula o endereço: t3 = s0 (base) + t2 (offset)
	lw a0, 0(t3) 		# Carrega o valor (word) da cavidade (endereço t3) para a0
	li a7, 1 		# Carrega a syscall 1 (print integer)
	ecall 			# Executa (imprime o número de sementes)
	
	la a0, barra 		# Carrega o endereço da string " | "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime o separador)
	
	addi t0, t0, 1 		# Incrementa o índice 'i' (para imprimir P1 na ordem, de 0 para 5)
	j print_loop_p1 	# Salta de volta para o 'print_loop_p1'
	
print_loop_p1_fim:
	la a0, newline 		# Carrega o endereço da string "\n"
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a nova linha)
	
	#restaura stack que foi usada para armazenar ra
	lw ra, 0(sp) 		# Restaura o 'ra' (Return Address) da pilha para o registrador 'ra'
	addi sp, sp, 4 		# Liberta os 4 bytes da pilha (move o ponteiro da pilha para cima)
	ret 			# Retorna da função 'mostrar_tabuleiro'

# -----------------------------------------------------------------
# Função: processa_jogada
# Pede, valida e processa a jogada do jogador atual
# -----------------------------------------------------------------
processa_jogada:
	addi sp, sp, -4 	# Aloca 4 bytes na pilha para salvar 'ra'
	sw ra, 0(sp) 		# Armazena 'ra' na pilha
	
loop_pede_jogada: 		# Rótulo de início do loop (para casos de erro)
	la t0, player_atual 	# Carrega o endereço da variável 'player_atual'
	lw s1, 0(t0) 		# Carrega o valor (1 ou 2) de 'player_atual' para s1
	
	li t0, 1 		# Carrega o número 1 para t0 (para comparar)
	beq s1, t0, play_p1 	# Salta se s1 (jogador) == 1 para 'play_p1'
	
play_p2:
	la a0, msg_play_p2 	# Carrega a mensagem "Player 2..." para a0
	li t1, 7 		# Define o limite mínimo da jogada (7) para t1
	li t2, 12 		# Define o limite máximo da jogada (12) para t2
	j pede_jogada 		# Salta para a secção que pede o input
	
play_p1:
	la a0, msg_play_p1 	# Carrega a mensagem "Player 1..." para a0
	li t1, 0 		# Define o limite mínimo da jogada (0) para t1
	li t2, 5 		# Define o limite máximo da jogada (5) para t2

pede_jogada:
	li a7,4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime o prompt "Escolha...")
	li a7, 5 		# Carrega a syscall 5 (read integer)
	ecall 			# Executa (lê o número do usuário)
	mv t3, a0 		# Move o número lido (que está em a0) para t3
	
	#verifica se está entre os limites (t1 e t2)
	blt t3,t1, jogada_invalida # Salta (Branch) se t3 (input) < t1 (limite min) para 'jogada_invalida'
	bgt t3,t2, jogada_invalida # Salta (Branch) se t3 (input) > t2 (limite max) para 'jogada_invalida'
	
	# Validação 2: Verifica se a cavidade tem sementes
	li t6, 4 		# Carrega 4 para t6
	mul t4, t3, t6 		# Calcula o offset: t4 = t3 (índice) * 4
	add t5, s0, t4 		# Calcula o endereço da cavidade: t5 = s0 (base) + t4 (offset)
	lw t6, 0(t5) 		# Carrega o valor (número de sementes) da cavidade para t6
	
	beq t6, zero, jogada_sem_sementes # Salta se t6 (sementes) == 0 para 'jogada_sem_sementes'
	
	# Jogada VÁLIDA: prepara para chamar a distribuição
	mv a0, t3 		# Move o índice escolhido (t3) para a0 (argumento 0)
	mv a1, t6 		# Move o número de sementes (t6) para a1 (argumento 1)
	call distribui_sementes 	# Chama a função de distribuição
	
	# Lógica pós-jogada: verificar se joga de novo
	li s4, 1 		# Carrega 1 para s4 (para comparar)
	beq a0, s4, fim_processa_jogada # Salta se a0 (retorno) == 1 (joga de novo)
	
	# Se a0 == 0, troca o turno
	li t0, 1 		# Carrega 1 para t0
	beq s1, t0, set_p2 	# Salta se o jogador atual (s1) == 1, para o mudar para 2
	
set_p1: 			# Se não saltou, era o P2
	li t1, 1 		# Carrega 1 (P1) para t1
	j salva_turno 		# Salta para salvar o turno
	
set_p2: 			# Se era P1, salta para aqui
	li t1, 2 		# Carrega 2 (P2) para t1

salva_turno:
	la t0, player_atual 	# Carrega o endereço da variável 'player_atual'
	sw t1, 0(t0) 		# Armazena o novo jogador (1 ou 2) na variável
	j fim_processa_jogada 	# Salta para o fim da função

jogada_invalida:
	la a0, msg_invalida 	# Carrega o endereço da mensagem de erro "inválida"
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime o erro)
	j loop_pede_jogada 	# Salta de volta para o *início* do loop (para carregar o prompt certo)

jogada_sem_sementes:
	la a0, msg_sem_sementes # Carrega o endereço da mensagem de erro "sem sementes"
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime o erro)
	j loop_pede_jogada 	# Salta de volta para o *início* do loop (para carregar o prompt certo)
	
fim_processa_jogada:
	lw ra, 0(sp) 		# Restaura 'ra' da pilha
	addi sp, sp, 4 		# Liberta a pilha
	ret 			# Retorna da função 'processa_jogada'
	
# -----------------------------------------------------------------
# Função: distribui_sementes
# Argumentos: a0 = índice inicial, a1 = sementes na mão
# Retorno: a0 = 1 (joga de novo), a0 = 0 (troca o turno)
# -----------------------------------------------------------------
distribui_sementes:
	mv t0, a0		# t0 = índice atual (copia do argumento a0)
	mv t1, a1		# t1 = sementes na mão (copia do argumento a1)
	
	#esvazia a cavidade inicial
	li t6, 4 		# Carrega 4 para t6
	mul t2, t0, t6 		# Calcula o offset da cavidade inicial: t2 = t0 (índice) * 4
	add t2, s0, t2 		# Calcula o endereço da cavidade inicial: t2 = s0 (base) + offset
	sw zero, 0(t2) 		# Armazena 0 (zera) na cavidade inicial

distribui_loop:
	beq t1, zero, distribui_fim # Salta se t1 (sementes na mão) == 0 para 'distribui_fim'
	
	addi t0, t0, 1 		# Avança o índice da cavidade: i++
	
	# --- CORREÇÃO (Wrap-Around) ---
	li t2, 14 		# Carrega o número 14 (limite do tabuleiro) para t2
	# --- FIM DA CORREÇÃO ---
	
	bne t0, t2, distribui_continua # Salta se t0 (i) != 14 (não deu a volta)
	li t0, 0 		# Se deu a volta (i == 14), reseta o índice para 0
distribui_continua:

	li t6, 4 		# Carrega 4 para t6
	mul t2, t0, t6 		# Calcula o offset em bytes da cavidade atual: t2 = t0 (i) * 4
	
	# Lógica para pular o poço do oponente
	li t3, 1 		# Carrega 1 para t3 (para comparar)
	beq s1, t3, checa_poco_p2 # Salta se s1 (jogador) == 1 (P1), para verificar o poço P2
	
	# Se chegou aqui, é o Jogador 2
	beq t2, s2, distribui_loop # (É P2) Salta se o offset t2 == poço P1 (s2) (pula o poço P1)
	j distribui_plantar 	# (É P2) Não é o poço P1, pode plantar
	
checa_poco_p2:
	# Se chegou aqui, é o Jogador 1
	beq t2, s3, distribui_loop # (É P1) Salta se o offset t2 == poço P2 (s3) (pula o poço P2)
	
distribui_plantar:
	add t3, s0, t2 		# Calcula o endereço da cavidade: t3 = s0 (base) + t2 (offset)
	lw t4, 0(t3) 		# Carrega o valor atual (word) da cavidade para t4
	addi t4, t4, 1 		# Adiciona 1 semente
	sw t4, 0(t3) 		# Armazena o novo valor
	
	addi t1, t1, -1 	# Decrementa o número de sementes na mão
	j distribui_loop 	# Salta de volta para o início do 'distribui_loop'
	
distribui_fim:
	# (t0 = índice onde caiu a última semente)
	# (t2 = offset onde caiu a última semente)
	# (t4 = total de sementes na cavidade final)
	
	# Lógica de Turno Extra
	li t1, 1 		# Carrega 1 para t1
	beq s1, t1, checa_poco_p1 # Salta se o jogador (s1) == 1
	
	# É P2: checa se caiu no poço P2 (s3)
	beq t2, s3, distribui_denovo # Salta se t2 (offset final) == s3 (poço P2)
	j checa_captura 	# Se não, vai checar a captura
	
checa_poco_p1:
	# É P1: checa se caiu no poço P1 (s2)
	beq t2, s2, distribui_denovo # Salta se t2 (offset final) == s2 (poço P1)
	
checa_captura:
	# Condição 2: Caiu numa cavidade que agora tem 1 semente?
	li t6, 1 		# Carrega 1 para t6
	bne t4, t6, troca_turno # Salta se t4 (sementes na cavidade) != 1 (não pode capturar)
	
	# Condição 1: Caiu no lado correto?
	li t3, 1 		# Carrega 1 para t3
	beq s1, t3, checa_lado_p1 # Salta se o jogador (s1) == 1
	
	# É P2: Verifica se caiu no lado P2 (índices 7-12)
	li t5, 7 		# Carrega 7 (limite min)
	blt t0, t5, troca_turno # Salta se t0 (índice) < 7 (lado P1)
	li t5, 12 		# Carrega 12 (limite max)
	bgt t0, t5, troca_turno # Salta se t0 (índice) > 12 (poço P2)
	j captura 		# Se está entre 7-12, salta para capturar
	
checa_lado_p1:
    # É P1: Verifica se caiu no lado P1 (índices 0-5)
	li t5, 5 		# Carrega 5 (limite max)
	bgt t0, t5, troca_turno # Salta se t0 (índice) > 5 (poço P1)
	
captura:
    # Condição 3: A cavidade oposta tem sementes?
	li t5, 12 		# Carrega 12 (para calcular o oposto)
	sub t5, t5, t0 		# t5 = 12 - t0 (índice_oposto)
	li t6, 4 		# Carrega 4 para t6
	mul t5, t5, t6 		# Calcula o offset oposto: t5 = índice_oposto * 4
	add t5, s0, t5 		# t5 = endereço da cavidade oposta
	lw t6, 0(t5) 		# t6 = sementes na cavidade oposta
	
	beq t6, zero, troca_turno # CONDIÇÃO 3: Salta se t6 (sementes_opostas) == 0 (não captura)
	
	# CAPTURA VÁLIDA!
	sw zero, 0(t5) 		# Zera a cavidade oposta (armazena 0 no endereço t5)
	
	addi t6, t6, 1 		# t6 = sementes_capturadas = sementes_opostas + 1 (a semente da jogada)
	add t3, s0, t2 		# t3 = endereço da cavidade ATUAL (calculado antes)
	sw zero, 0(t3) 		# Zera a cavidade atual (armazena 0 no endereço t3)
	
	li t3, 1 		# Carrega 1 para t3
	beq s1, t3, add_poco_p1 # Salta se o jogador (s1) == 1
	
	# Adiciona ao poço P2
	add t5, s0, s3 		# t5 = endereço do poço P2
	lw t4, 0(t5) 		# t4 = sementes atuais no poço P2
	add t4, t4, t6 		# t4 = sementes_atuais + sementes_capturadas
	sw t4, 0(t5) 		# Armazena o novo total no poço P2
	j troca_turno 		# Salta para trocar o turno
	
add_poco_p1:
    # Adiciona ao poço P1
	add t5, s0, s2 		# t5 = endereço do poço P1
	lw t4, 0(t5) 		# t4 = sementes atuais no poço P1
	add t4, t4, t6 		# t4 = sementes_atuais + sementes_capturadas
	sw t4, 0(t5) 		# Armazena o novo total no poço P1
	j troca_turno 		# Salta para trocar o turno
	
distribui_denovo:
	li a0, 1 		# Define o valor de retorno a0 = 1 (Joga de novo)
	ret 			# Retorna da função
	
troca_turno:
	li a0, 0 		# Define o valor de retorno a0 = 0 (Troca o turno)
	ret 			# Retorna da função
	
# -----------------------------------------------------------------
# Função: verifica_fim_jogo
# Soma os lados P1 e P2. Se algum for 0, limpa o outro e retorna 1.
# Retorno: a0 = 1 (jogo acabou), a0 = 0 (jogo continua)
# -----------------------------------------------------------------
verifica_fim_jogo:
	# Salva registradores que vamos usar (s4-s7) e ra
	addi sp, sp, -20 	# Aloca 20 bytes na pilha (5 registradores * 4 bytes)
	sw ra, 0(sp) 		# Salva 'ra' na pilha (offset 0)
	sw s4, 4(sp) 		# Salva 's4' na pilha (offset 4)
	sw s5, 8(sp) 		# Salva 's5' na pilha (offset 8)
	sw s6, 12(sp) 		# Salva 's6' na pilha (offset 12)
	sw s7, 16(sp) 		# Salva 's7' na pilha (offset 16)

	# 1. Soma as sementes do lado do P1 (cavidades 0-5)
	li s4, 0 		# Inicializa s4 (soma_p1) = 0
	li s6, 0 		# Inicializa s6 (contador 'i') = 0
	li t1, 4 		# Carrega 4 para t1 (para multiplicação)
checa_p1_loop:
	li t0, 6 		# Carrega 6 (limite) para t0
	beq s6, t0, check_p1_fim # Salta se s6 (i) == 6
	
	mul t2, s6, t1 		# Calcula o offset: t2 = s6 (i) * 4
	add t3, s0, t2 		# Calcula o endereço: t3 = s0 (base) + offset
	lw t4, 0(t3) 		# Carrega o valor (sementes) da cavidade
	add s4, s4, t4 		# Adiciona as sementes à soma: soma_p1 += sementes
	
	addi s6, s6, 1 		# Incrementa o contador: i++
	j checa_p1_loop 	# Salta de volta para 'checa_p1_loop'
check_p1_fim:

	# 2. Soma as sementes do lado do P2 (cavidades 7-12)
	li s5, 0 		# Inicializa s5 (soma_p2) = 0
	li s6, 7 		# Inicializa s6 (contador 'i') = 7
	li t1, 4 		# Carrega 4 para t1 (para multiplicação)
checa_p2_loop:
	li t0, 13 		# Carrega 13 (limite) para t0
	beq s6, t0, checa_p2_fim # Salta se s6 (i) == 13
	
	mul t2, s6, t1 		# Calcula o offset: t2 = s6 (i) * 4
	add t3, s0, t2 		# Calcula o endereço: t3 = s0 (base) + offset
	lw t4, 0(t3) 		# Carrega o valor (sementes) da cavidade
	add s5, s5, t4 		# Adiciona as sementes à soma: soma_p2 += sementes
	
	addi s6, s6, 1 		# Incrementa o contador: i++
	j checa_p2_loop 	# Salta de volta para 'checa_p2_loop'
checa_p2_fim:

	# 3. Verifica se algum lado está vazio
	beq s4, zero, captura_final # Salta se s4 (soma P1) == 0
	beq s5, zero, captura_final # Salta se s5 (soma P2) == 0
	
	# Se nenhum lado está vazio, o jogo continua
	li a0, 0 		# Define o retorno a0 = 0 (jogo não acabou)
	j restaura_reg 		# Salta para restaurar a pilha e retornar

captura_final: 			# Rótulo interno (corrigido do bug de 'game_over' duplicado)
	# Jogo acabou. Precisamos fazer a captura final.
	
	# Carrega poço P1
	add s7, s0, s2 		# s7 = endereço do poço P1
	lw t0, 0(s7) 		# t0 = valor atual poço P1
	
	# Carrega poço P2
	add s6, s0, s3 		# s6 = endereço do poço P2
	lw t1, 0(s6) 		# t1 = valor atual poço P2
	
	
	bne s4, zero, p2_vazio 	# Salta se s4 (soma P1) != 0 (significa que P2 está vazio)
	
	# Lado P1 estava vazio. Mova s5 (soma P2) para o poço P2.
	add t1, t1, s5 		# poço_p2 = poço_p2 + soma_p2
	sw t1, 0(s6) 		# Armazena o novo valor no poço P2
	call limpa_p2 		# Chama a função para zerar as cavidades do P2
	j seta_game_over 	# Salta para definir o valor de retorno
	
p2_vazio:
	# Lado P2 estava vazio. Mova s4 (soma P1) para o poço P1.
	add t0, t0, s4 		# poço_p1 = poço_p1 + soma_p1
	sw t0, 0(s7) 		# Armazena o novo valor no poço P1
	call limpa_p1 		# Chama a função para zerar as cavidades do P1

seta_game_over:
	li a0, 1 		# Define o retorno a0 = 1 (jogo acabou)

restaura_reg:
	# Restaura registradores da pilha na ordem inversa
	lw ra, 0(sp) 		# Restaura 'ra'
	lw s4, 4(sp) 		# Restaura 's4'
	lw s5, 8(sp) 		# Restaura 's5'
	lw s6, 12(sp) 		# Restaura 's6'
	lw s7, 16(sp) 		# Restaura 's7'
	addi sp, sp, 20 	# Liberta os 20 bytes da pilha
	ret 			# Retorna da função 'verifica_fim_jogo'


# -----------------------------------------------------------------
# Função: limpa_p1
# Zera todas as cavidades do lado P1 (0-5)
# -----------------------------------------------------------------
limpa_p1:
	addi sp, sp, -4 	# Aloca 4 bytes na pilha para 'ra'
	sw ra, 0(sp) 		# Salva 'ra'
	li t0, 0 		# Inicializa 'i' (em t0) = 0
	li t2, 4 		# Carrega 4 para t2
limpa_p1_loop:
	li t1, 6 		# Carrega 6 (limite) para t1
	beq t0, t1, limpa_p1_fim # Salta se t0 (i) == 6
	
	mul t3, t0, t2 		# Calcula o offset: t3 = t0 (i) * 4
	add t3, s0, t3 		# Calcula o endereço (CORRIGIDO)
	sw zero, 0(t3) 		# Armazena 0 (zera) na cavidade
	
	addi t0, t0, 1 		# Incrementa: i++
	j limpa_p1_loop 	# Salta de volta para 'limpa_p1_loop'
limpa_p1_fim:
	lw ra, 0(sp) 		# Restaura 'ra'
	addi sp, sp, 4 		# Liberta a pilha
	ret 			# Retorna da função 'limpa_p1'

# -----------------------------------------------------------------
# Função: limpa_p2
# Zera todas as cavidades do lado P2 (7-12)
# -----------------------------------------------------------------
limpa_p2:
	addi sp, sp, -4 	# Aloca 4 bytes na pilha para 'ra'
	sw ra, 0(sp) 		# Salva 'ra'
	li t0, 7 		# Inicializa 'i' (em t0) = 7
	li t2, 4 		# Carrega 4 para t2
limpa_p2_loop:
	li t1, 13 		# Carrega 13 (limite) para t1
	beq t0, t1, limpa_p2_fim # Salta se t0 (i) == 13
	
	mul t3, t0, t2 		# Calcula o offset: t3 = t0 (i) * 4
	add t3, s0, t3 		# Calcula o endereço (CORRIGIDO)
	sw zero, 0(t3) 		# Armazena 0 (zera) na cavidade
	
	addi t0, t0, 1 		# Incrementa: i++
	j limpa_p2_loop 	# Salta de volta para 'limpa_p2_loop'
limpa_p2_fim:
	lw ra, 0(sp) 		# Restaura 'ra'
	addi sp, sp, 4 		# Liberta a pilha
	ret 			# Retorna da função 'limpa_p2'

# -----------------------------------------------------------------
# Rótulo: game_over
# O jogo acabou. Anuncia o vencedor e pergunta se quer jogar de novo.
# -----------------------------------------------------------------
game_over:
	call mostrar_tabuleiro 	# Chama a função para mostrar o tabuleiro final (com lados limpos)
	
	# Carrega sementes dos poços para contagem final
	add t0, s0, s2 		# t0 = endereço do poço P1
	lw s4, 0(t0) 		# s4 = placar final P1
	add t1, s0, s3 		# t1 = endereço do poço P2
	lw s5, 0(t1) 		# s5 = placar final P2
	
	# Compara os totais
	bgt s4, s5, vitoria_p1 	# Salta se s4 > s5 (P1 ganhou)
	bgt s5, s4, vitoria_p2 	# Salta se s5 > s4 (P2 ganhou)
	
	# Se não for maior, é empate
	la a0, msg_empate 	# Carrega o endereço da mensagem de empate
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a mensagem)
	j fim_contagem 		# Salta para o fim da contagem

vitoria_p1:
	la a0, msg_vitoria_p1 	# Carrega o endereço da mensagem de vitória P1
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a mensagem)
	# Incrementa vitórias P1
	la t0, vitorias_p1 	# Carrega o endereço da variável 'vitorias_p1'
	lw t1, 0(t0) 		# Carrega o valor atual do placar P1
	addi t1, t1, 1 		# Adiciona 1 à vitória
	sw t1, 0(t0) 		# Armazena o novo placar P1
	j fim_contagem 		# Salta para o fim da contagem

vitoria_p2:
	la a0, msg_vitoria_p2 	# Carrega o endereço da mensagem de vitória P2
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a mensagem)
	# Incrementa vitórias P2
	la t0, vitorias_p2 	# Carrega o endereço da variável 'vitorias_p2'
	lw t1, 0(t0) 		# Carrega o valor atual do placar P2
	addi t1, t1, 1 		# Adiciona 1 à vitória
	sw t1, 0(t0) 		# Armazena o novo placar P2
	j fim_contagem 		# Salta para o fim da contagem

fim_contagem:
	# Mostra o placar geral
	la a0, msg_vitorias_p1 	# Carrega o endereço da string "Placar; P1 -> "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a string)
	
	la t0, vitorias_p1 	# Carrega o endereço da variável 'vitorias_p1'
	lw a0, 0(t0) 		# Carrega o valor das vitórias P1 para a0
	li a7, 1 		# Carrega a syscall 1 (print integer)
	ecall 			# Executa (imprime o número)
	
	la a0, msg_vitorias_p2 	# Carrega o endereço da string " | P2 -> "
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a string)
	
	la t0, vitorias_p2 	# Carrega o endereço da variável 'vitorias_p2'
	lw a0, 0(t0) 		# Carrega o valor das vitórias P2 para a0
	li a7, 1 		# Carrega a syscall 1 (print integer)
	ecall 			# Executa (imprime o número)
	
	# Pergunta se quer jogar novamente
	la a0, msg_novo_jogo 	# Carrega o endereço da string "Digite 1 para..."
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a string)
	
	la a0, newline 		# Carrega o endereço da string "\n"
	li a7, 4 		# Carrega a syscall 4 (print string)
	ecall 			# Executa (imprime a nova linha)
	
	li a7, 5 		# Carrega a syscall 5 (read integer)
	ecall 			# Executa (lê a resposta do usuário)
	
	li t0, 1 		# Carrega 1 para t0
	beq a0, t0, novo_jogo 	# Salta se a0 (input) == 1 para 'novo_jogo'
	
	# Se não, encerra o programa
	li a7, 10 		# Carrega a syscall 10 (exit)
	ecall 			# Executa (termina o programa)

novo_jogo:
	call inicializar_tabuleiro # Chama a função para resetar o tabuleiro
	j main_loop 		# Salta de volta para o 'main_loop' para um novo jogo
