	.data
msg_welcome: .asciz "\n Bem vindo ao jogo de Mancala"
msg_win: .asciz "\n Jogador venceu"
p2_label: .asciz "\n P2: "
p1_label: .asciz "\n P1: "
kalahs:   .asciz "\n P2 Mancala: "
p1_kalah: .asciz "  P1 Mancala: "
newline:  .asciz "\n"
barra: .asciz " | "

.align 2

BOARD_P1: .word 0,4,4,4,4,4,4
BOARD_P2: .word 4,4,4,4,4,4,0

.text
.globl main  # Torna a 'main' visível para o sistema
# s0 - turno; s1 - vitórias;

main:
	call board_init
	li a7,10
	ecall
board_init:
la a2, BOARD_P1
la a3, BOARD_P2

imprime_tabuleiro_p1:
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
	li a7, 10
	ecall
