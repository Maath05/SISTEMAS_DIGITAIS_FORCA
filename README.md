Este relatório apresenta o projeto, a modelagem e implementação em linguagem de des-
crição de hardware (VHDL) e a validação por simulação de um sistema digital que im-
plementa o Jogo da Forca. A implementação foi feita em hardware sobre o kit de de-
senvolvimento Xilinx Spartan-3, que serve como plataforma de interação com o usuário.
Quatro chaves seletoras da placa são usadas como entrada de dados, sendo reaproveitadas
em momentos diferentes para informar, em sequência, o código da operação desejada e os
dois operandos. Para organizar essa sequência, o projeto emprega botões de confirmação:
a cada acionamento, o valor presente nas chaves é registrado e o sistema avança para a
etapa seguinte do processo de inserção. 
O objetivo do circuito é armazenar uma palavra secreta, receber palpites de letras
inseridos pelo usuário, verificar a ocorrência da letra na palavra, contabilizar tentativas
incorretas e sinalizar as condições de vitória ou derrota. 
