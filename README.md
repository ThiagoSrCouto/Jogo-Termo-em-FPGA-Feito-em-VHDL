# Jogo Termo em FPGA (VHDL)

O projeto de sistemas digitais em placas de FPGA (_Field-Programmable Gate Array_) permite implementar controladores de periféricos e máquinas de controle com determinismo temporal estrito, paralelismo e independência total de processadores de propósito geral.

Nesse contexto, este repositório contém a descrição em hardware (VHDL) de um sistema digital completo capaz de receber entradas de um usuário por meio de um **teclado PS/2**, diferenciar e processar diferentes teclas pressionadas e apresentar respostas visuais dinâmicas em tempo real no **display LCD 16×2** integrado à placa de FPGA.

---

## Regras e Funcionamento do Jogo

A proposta consiste na implementação em hardware do jogo **Termo**:

1. **Definição da Palavra Secreta:** Em cada partida, um primeiro operador define uma palavra secreta de **cinco letras** (`A` a `Z`), podendo corrigir eventuais erros de digitação com a tecla `BACKSPACE` e confirmar a entrada com `ENTER`.
2. **Tentativas e Avaliação:** Em seguida, o jogador dispõe de até **seis tentativas** para descobrir a palavra oculta. A cada palpite submetido, o circuito avalia cada caractere e exibe o resultado no display LCD por meio dos seguintes símbolos:
   - `*` — Letra correta na posição exata;
   - `?` — Letra presente na palavra secreta, porém em outra posição;
   - `_` — Letra ausente na palavra secreta.
3. **Encerramento:** Caso o jogador acerte todas as letras dentro das seis tentativas, uma mensagem de vitória é exibida. Caso as tentativas se esgotem, o jogador perde a partida e a palavra secreta é revelada no display.

---

## Arquitetura e Estrutura do Repositório

O sistema foi estruturado de forma modular e síncrona em VHDL, operando com um sinal de _clock_ de **50 MHz** (período de `20 ns`), dividido nos seguintes arquivos:

- **`toplevel.vhd` (`termo_top`):** Entidade _Top-Level_ estrutural responsável por instanciar e conectar os módulos internos às portas físicas da FPGA.
- **`ps2_keyboard.vhd` (`ps2_keyboard`):** Controlador de teclado PS/2 com filtragem digital de ruído, desserialização de quadros de 11 bits, descarte de _break codes_ (`0xF0`) e decodificação _Scan Code Set 2_ para ASCII.
- **`termo_core.vhd` (`termo_core`):** Núcleo de controle e regras do jogo, composto pela máquina de estados finitos (FSM) de seis estados, registradores de palavras, comparador combinacional em duas passagens e formatador das linhas ASCII do display.
- **`display.vhd` (`lcd_controller`):** Controlador de temporização paralela (interface de 8 bits) responsável pela sequência de inicialização e atualização contínua do display LCD 16×2.
- **`toplevel.ucf`:** Arquivo de restrições físicas (_User Constraints File_) para mapeamento dos pinos de I/O (clock, reset, interface PS/2 e barramento LCD) e definição da restrição temporal de `20.000 ns`.
