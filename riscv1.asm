	.data
msg_welcome: .asciz "\n Bem vindo ao jogo de Mancala"
msg_win: .asciz " ° Jogador venceu!"
p2_label: .asciz "\n P2: "
p1_label: .asciz "\n P1: "
mancala:   .asciz "\n P2 Mancala: "
p1_mancala: .asciz "\n P1 Mancala: "
newline:  .asciz "\n"
barra: .asciz " | "
msg_play: .asciz "Insira o número da casa para a jogada (0 a 5): "
msg_teste: .asciz "\n teste!"
msg_fim_erro: .asciz "Isso é um erro, o programa chegou ao fim"

n0: .word 0
n4: .word 4

.align 2

BOARD: .space 56

.text

###################################### s0 - turno; s1 - vitórias, s2 - board p1 s3 - board p2;###########################################v

main:
call board_init

main_loop:
call imprime_tabuleiro
call play

board_init:
la s2, BOARD #carrega o address do inicio do board

li t0, 28 #offset para 7 words(cada player vai ter 7 casas * 4 bytes, 28)
add s3, s2, t0 #ponteiro para inicio do tabuleiro do p2, board+ 28 bytes, 7 casas a direita

reset_board: #reseta todas as posicoes do tabuleiro
li t0, 0
li t1, 4

sw t0, (s2) 
sw t1, 4(s2)
sw t1, 8(s2)
sw t1, 12(s2)
sw t1, 16(s2)
sw t1, 20(s2)
sw t1, 24(s2)

sw t1, (s3) 
sw t1, 4(s3)
sw t1, 8(s3)
sw t1, 12(s3)
sw t1, 16(s3)
sw t1, 20(s3)
sw t0, 24(s3)
j ret

imprime_tabuleiro:
mv a2, s2 #copia o tabuleiro "verdadeiro" (s2 e s3) para a2 e a3
mv a3, s3
li t0, 0 #indice
li t1, 7
imprime_p1:
beq t0, t1, imprime_tabuleiro_p2
lw t2, 0(a2)
mv a0, t2
li a7, 1
ecall
la a0, barra
li a7, 4
ecall
addi t0, t0, 1
addi a2, a2, 4
j imprime_p1
	
imprime_tabuleiro_p2:
la a0, newline
li a7, 4
ecall
li t0, 0
li t1, 7
imprime_p2:
beq t0, t1, fim_imprime_p2
lw t3, 0(a3)
mv a0, t3
li a7, 1
ecall
la a0, barra
li a7,4
ecall
addi t0, t0, 1
addi a3, a3, 4
j imprime_p2
	
fim_imprime_p2:
j ret

play: 
li t0, 1 #checa de quem é o turno
li t1, 2
ble s0, t0, play_p1
bge s0, t1, play_p2

play_p1:
la a0, p1_label
li a7, 4
ecall #P1 (msg_play)
la a0, msg_play
ecall #print msg play
li a7, 5
ecall #le int
mv t1, a0 #t1=int lida

li t2, 4
mul t1, t1,t2 #int lida*4
mv a5, s2 #a5 = tabuleiro
add a5, t1, a5 #a5=casa escolhida para jogada
lw t0, (a5) #t0=numero de sementes da casa
sw zero, (a5) #zera a casa escolhida

loop_play_p1:


play_p2:
la a0, p2_label
li a7, 4
ecall #P2 (msg_play)
la a0, msg_play
ecall
li a7, 5
ecall
mv t1, a0

fim_erro:
la a0, msg_fim_erro
li a7, 4
ecall

fim:
li a7,10
ecall

teste:
la a0, msg_teste
li a7, 4
ecall
j fim

ret:
ret

