; Desenvolvido por João Augusto - 18185  e Murilo Sanches - 18187
;
;Todas as funções do jogo estão implementadas corretamente, 
; porém deram alguns problemas:
;
; Problema 1: não encontrarmos uma forma simples de fazer uma lista ligada com os meteoros e lasers, 
;             e todas as outras maneiras de contornar esse problema também deram errado também.
;
; 1 - Na primeira tentativa tentamos instanciar um novo laser ou um novo meteoro por tempo ou toda vez que o jogador apertasse [F],
;     porém não conseguimos instanciar uma nova instancia da struct laserDuplo e MeteoroSTr no arquivo '.asm'
; 2 - Assim tentamos instanciar todas os lasers e meteoros no '.inc', e depois so modificariamos os valores dos campos,
;     porém não conseguimos modificar isso porque dava um novo erro, além dissod essa forma traria outro problema que o jogo não seria mais infinito
; 
; Problema 2: o sistema de pontuação ao invés de escrever os números, estava escrevendo o caracteres da tabela ASCII.
;             
; Problema 3: não sabiamos como desenhar caracteres direito usando o TextOut, assim não ficou com um design tão bonito e agradável.
;
; Problema 4: não conseguiamos testar o fim do jogo por não ter como perder, 
;             porém implementamos todos os códigos e caso conseguissemos solucionar o problema 1, poderiamos testar
;             e acredito eu que estaria tudo funcionando corretamente.  
;

.386                   
.model flat, stdcall   
option casemap:none  

include asteroid.inc

  .DATA
    AppName db "Asteroid",0

  .DATA?
    hInstance HINSTANCE ?
    CommandLine LPSTR ?

.CODE

start:  
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    invoke ExitProcess,eax       ; cleanup & return to operating system


; carrega as imagens 
  loadimages proc

    invoke LoadBitmap, hInstance, 100
    mov nave,eax

    invoke LoadBitmap, hInstance, 101
    mov coracao, eax

    invoke LoadBitmap, hInstance, 102
    mov laser, eax

    invoke LoadBitmap, hInstance, 103
    mov meteoro, eax

    invoke LoadBitmap, hInstance, 104
    mov meteoroQuebrado, eax

    invoke LoadBitmap, hInstance, 105
    mov explosao, eax

    invoke LoadBitmap, hInstance, 111
    mov fundoDoJogo, eax

    invoke LoadBitmap, hInstance, 112
    mov fundoDoInicio, eax

    invoke LoadBitmap, hInstance, 113
    mov fundoPerdeu, eax

    ret
  loadimages endp   


; pega o tamanho maximo da tela
  getWindowSize proc

     invoke GetSystemMetrics,SM_CXSCREEN 
        invoke TopXY, X, eax
        mov MaxX, eax

        invoke GetSystemMetrics,SM_CYSCREEN 
        invoke TopXY, Y, eax
        mov MaxY, eax

    ret
    
  getWindowSize endp

; estados do jogo

estagiosDoJogo proc

  .if estagio == 0
    mov eax, fundoDoInicio
    mov telaAtual, eax
  .endif

  .if estagio == 1
    mov eax, fundoDoJogo
    mov telaAtual, eax
  .endif

  .if estagio == 2 
    mov eax, fundoPerdeu
    mov telaAtual, eax
  .endif

  .if estagio == 3
    mov eax, fundoRank
    mov telaAtual, eax
  .endif

  ret
estagiosDoJogo endp


; decidade a imagem do meteoro dependendo das condições dele
decideImagem proc addrMeteoro:DWORD
  assume ebx:ptr meteoroStr

  mov ebx, addrMeteoro
  
  .if [ebx].vida == 2
    mov edx, meteoro
  .elseif [ebx].vida == 1
    mov edx, meteoroQuebrado 
  .elseif [ebx].vida == 0
    mov edx, explosao
  .endif
  ret
decideImagem endp

; funcao toca musica laser
tocaMusicaLaser proc
  mov   open_lpstrElementName,OFFSET musicaTiro
  mov   open_lpstrDeviceType, 0h
  invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
  invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_FROM or MCI_NOTIFY,offset play_dwCallback
  ret
tocaMusicaLaser endp

; funcao toca musica laser
tocaMusicaExplosao proc
  mov   open_lpstrElementName,OFFSET musicaExplosao
  mov   open_lpstrDeviceType, 0h
  invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
  invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_FROM or MCI_NOTIFY,offset play_dwCallback
  ret
tocaMusicaExplosao endp

; desenha a tela inteira
  paint proc 
    LOCAL hDC:HDC
    LOCAL hMemDC:HDC
    LOCAL hMemDC2:HDC
    LOCAL hBitmap:HDC

    invoke BeginPaint, hWnd, ADDR paintstruct
    mov hDC, eax
    invoke CreateCompatibleDC, hDC
    mov hMemDC, eax
    invoke CreateCompatibleDC, hDC
    mov hMemDC2, eax
    invoke CreateCompatibleBitmap, hDC, MaxX, MaxY
    mov hBitmap, eax

    invoke SelectObject, hMemDC, hBitmap

    invoke estagiosDoJogo

    invoke SelectObject, hMemDC, telaAtual
    invoke BitBlt, hDC, 0, 0, X, Y, hMemDC, 0, 0, SRCCOPY

    .if estagio == 1

      ; escreve a pontuacao
      invoke lstrlen, addr pont
      invoke TextOut, hDC, 600, 10, addr pont, eax
      invoke lstrlen, addr pontuacao
      invoke TextOut, hDC, 700, 10, addr pontuacao, eax

      ; desenha a nave
      invoke SelectObject, hMemDC2, nave
      invoke TransparentBlt, hDC, player.pos.x, player.pos.y, NAVE_SIZE.x, NAVE_SIZE.y, hMemDC2, 0, 0, NAVE_SIZE.x, NAVE_SIZE.y, 16777215

      ; desenha as vidas
      invoke SelectObject, hMemDC2, coracao
      mov ebx, 0
      movzx ecx, player.vida ;guarda quantas vidas ele tem
      .while ebx != ecx 
        mov eax, 36
        mul ebx
        push ecx
        invoke TransparentBlt, hDC, eax, 0, LIFE_SIZE.x, LIFE_SIZE.y, hMemDC2, 0, 0, LIFE_SIZE.x, LIFE_SIZE.y, 16777215
        pop ecx
        inc ebx
      .endw 

      ; desenha os lasers
      .if listLaser.qtd == 30
        invoke SelectObject, hMemDC2, laser

          assume ebx:ptr laserDuplo
          mov ebx, offset listLaser.primeiro
            loop1:
              invoke TransparentBlt, hDC, [ebx].pos1.x, [ebx].pos1.y, LASER_SIZE.x, LASER_SIZE.y, hMemDC2, 0, 0, LASER_SIZE.x, LASER_SIZE.y, 16777215 
              invoke TransparentBlt, hDC, [ebx].pos2.x, [ebx].pos2.y, LASER_SIZE.x, LASER_SIZE.y, hMemDC2, 0, 0, LASER_SIZE.x, LASER_SIZE.y, 16777215 
              .if [ebx].prox == 0
                jmp fim1
              .else
                mov ebx, [ebx].prox
                jmp loop1
              .endif
          fim1:
      .endif

      ; desenha os meteoros
      .if listMeteoro.qtd != 0

        assume ebx:ptr meteoroStr
        mov ebx, listMeteoro.primeiro
        loop2:
          invoke decideImagem, addr meteoro0
          invoke SelectObject, hMemDC2, edx
          invoke TransparentBlt, hDC, [ebx].pos.x, [ebx].pos.y, METEORO_SIZE.x, METEORO_SIZE.y, hMemDC2, 0, 0, METEORO_SIZE.x, METEORO_SIZE.y, 16777215

        ; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        ; Caso o contador da explosao for 1, a imagem da explosao ja foi mostrada, 
        ; assim não deve-se mostrar novamente, portanto deve remove-lo da lista de meteoros  

          .if [ebx].prox == 0
            jmp fim2
          .else
            mov ebx, [ebx].prox
            jmp loop2 
          .endif 
        fim2:      
      .endif

    .endif
      
    .if estagio == 2
      invoke lstrlen, addr pont
      invoke TextOut, hDC, 300, 550, addr pont, eax
      invoke lstrlen, addr pontuacao
      invoke TextOut, hDC, 400, 50, addr pontuacao, eax
    .endif

    invoke BitBlt, hDC, 0, 0, MaxX, MaxY, hMemDC, 0, 0, SRCCOPY

    invoke DeleteDC, hMemDC
    invoke DeleteDC, hMemDC2
    invoke DeleteObject, hBitmap
    invoke EndPaint, hWnd, ADDR paintstruct

  ret
  paint endp

; funcao para reiniciar o jogo
reiniciar proc
  mov player.pos.x, 370
  mov player.pos.y, 500
  mov player.vida, 3

  mov pontuacao, 0
  mov contador, 0
  mov dificuldade, 700 
  
  ret
reiniciar endp  

;Função para saber se objetos estão colidindo, guarda true ou false no edx
isColliding proc obj1Pos:point, obj2Pos:point, obj1Size:point, obj2Size:point
    
    push eax
    push ebx

    mov eax, obj1Pos.x
    add eax, obj1Size.x 
    mov ebx, obj2Pos.x
    add ebx, obj2Size.x

    .if obj1Pos.x < ebx && eax > obj2Pos.x
        mov eax, obj1Pos.y
        add eax, obj1Size.y
        mov ebx, obj2Pos.y
        add ebx, obj2Size.y
        
        .if obj1Pos.y < ebx && eax > obj2Pos.y ;estão colidindo
            mov edx, TRUE
        .else
            mov edx, FALSE
        .endif
    .else
        mov edx, FALSE
    .endif

    pop ebx
    pop eax

    ret

isColliding endp  

; verifica se o jogador bateu em um meteoro e faz ele morrer ou perder vida
hitMeteoro proc addrMeteoro:DWORD
  assume ebx:ptr meteoroStr

  mov ebx, meteoroStr
  invoke isColliding, player.pos, [ebx].pos, NAVE_SIZE, METEORO_SIZE
  .if edx == TRUE
    dec player.vida
    .if player.vida == 0
      invoke reiniciar
      mov estagio, 3
      ret
    .endif 
  .endif

  assume ebx:nothing
  ret
hitMeteoro endp

; verifica se o laser acertou em um meteoro e faz o meteoro perder vida ou ser destruido
colisaoLaser proc addrLaser:DWORD, addrMeteoro:DWORD
  assume ebx:ptr laserDuplo
  assume ecx:ptr meteoroStr

  mov ebx, addrLaser
  mov ecx, addrMeteoro
  invoke isColliding, [ebx].pos1, [ecx].pos, LASER_SIZE, METEORO_SIZE
  .if edx == TRUE
    dec [ecx].vida

    .if [ecx].vida == 0
      invoke tocaMusicaExplosao
    .endif
    ; remover o laser da lista ligada caso acerte o meteoro
  
  .endif 

  invoke isColliding, [ebx].pos2, [ecx].pos, LASER_SIZE, METEORO_SIZE
  .if edx == TRUE
    dec [ecx].vida

    .if [ecx].vida == 0
      invoke tocaMusicaExplosao
    .endif
    ; remover o laser da lista ligada caso acerte o meteoro

  .endif 

  assume ebx:nothing
  assume ecx:nothing
  ret
 colisaoLaser endp 

; thread de desenho
 paintThread proc p:DWORD
    .while !over
        invoke Sleep, 17 ; 60 FPS

        invoke InvalidateRect, hWnd, NULL, FALSE

    .endw

    ret
paintThread endp 

;função para um objeto n sair da tela, mas sim voltar pelo outro lado
fixCoordinates proc addrObj:dword
assume ebx:ptr point
    mov ebx, addrObj

    .if [ebx].x > 800 && [ebx].x < 80000000h
        mov [ebx].x, 20
    .endif
    .if [ebx].x <= 10 || [ebx].x > 80000000h
        mov [ebx].x, 780
    .endif 
    .if [ebx].y > 520 && [ebx].y < 80000000h
        mov [ebx].y, 520
    .endif
    .if [ebx].y <= 10 || [ebx].y > 80000000h
        mov [ebx].y, 10 
    .endif
assume ebx:nothing
ret
fixCoordinates endp

; proc para encontrar as medidas maximas da tela
  TopXY proc wDim:DWORD, sDim:DWORD

      shr sDim, 1      ; divide screen dimension by 2
      shr wDim, 1      ; divide window dimension by 2
      mov eax, wDim    ; copy window dimension into eax
      sub sDim, eax    ; sub half win dimension from half screen dimension

      return sDim

  TopXY endp

  SetTamanho proc
    mov player.pos.x, 370
    mov player.pos.y, 500
    ret
  SetTamanho endp

; muda a velocidade do pac dependendo da tecla q foi apertada
changePlayerSpeed proc direction:BYTE, keydown:BYTE

  .if keydown == TRUE
    .if direction == D_TOP ; w / seta pra cima
        mov player.speed.y, -6
        mov player.speed.x, 0
        mov player.dir, D_TOP
    .elseif direction == D_DOWN ; s / seta pra baixo
        mov player.speed.y, 6
        mov player.speed.x, 0
        mov player.dir, D_DOWN
    .elseif direction == D_LEFT ; a / seta pra esquerda
        mov player.speed.x, -6
        mov player.speed.y, 0
        mov player.dir, D_LEFT
    .elseif direction == D_RIGHT ; d / seta pra direita
        mov player.speed.x, 6
        mov player.speed.y, 0
        mov player.dir, D_RIGHT
    .endif
  .else
    .if direction == D_TOP ; w / seta pra cima
        mov player.speed.y, 0
        mov player.speed.x, 0
        mov player.dir, D_TOP
    .elseif direction == D_DOWN ; s / seta pra baixo
        mov player.speed.y, 0
        mov player.speed.x, 0
        mov player.dir, D_DOWN
    .elseif direction == D_LEFT ; a / seta pra esquerda
        mov player.speed.x, 0
        mov player.speed.y, 0
        mov player.dir, D_LEFT
    .elseif direction == D_RIGHT ; d / seta pra direita
        mov player.speed.x, 0
        mov player.speed.y, 0
        mov player.dir, D_RIGHT
    .endif
  .endif  
      
  assume ecx: nothing
  ret
changePlayerSpeed endp

; funcao para randomizar numeros

randomizer proc
  mov ecx, 500 
  ret
randomizer endp

; funcao para mover os meteoros 
moveMeteoros proc uses eax, addrMeteoro:DWORD
assume ebx:ptr meteoroStr
  mov ebx, addrMeteoro
  .if [ebx].vida != 0
    mov eax, [ebx].pos.x
    mov edx, [ebx].speed.x
    .if dx > 7fh
      or dx, 65280
    .endif
    add eax, edx
    mov [ebx].pos.x, eax
    mov eax, [ebx].pos.y
    mov edx, [ebx].speed.y
    .if dx > 7fh 
      or dx, 65280
    .endif
    add ax, dx
    mov [ebx].pos.y, eax   
  .endif     
  ret
moveMeteoros endp

; funcao para mover os lasers
moveLasers proc uses eax, addrLaser:DWORD
assume ebx:ptr laserDuplo
mov ebx, addrLaser

  mov eax, [ebx].pos1.x
  mov edx, [ebx].speed.x
  .if dx > 7fh
    or dx, 65280
  .endif
  add eax, ebx
  mov [ebx].pos1.x, eax
  mov eax, [ebx].pos1.y
  mov edx, [ebx].speed.y
  .if dx > 7fh 
    or dx, 65280
  .endif
  add ax, dx
  mov [ebx].pos1.y, eax

  mov eax, [ebx].pos2.x
  mov edx, [ebx].speed.x
  .if dx > 7fh
    or dx, 65280
  .endif
  add eax, edx
  mov [ebx].pos2.x, eax
  mov eax, [ebx].pos2.y
  mov edx, [ebx].speed.y
  .if dx > 7fh 
    or dx, 65280
  .endif
  add ax, dx
  mov [ebx].pos2.y, eax
  ret
moveLasers endp

; função para o personagem se mover, baseado na velocidade
movePlayer proc uses eax
  mov eax, player.pos.x
  mov ebx, player.speed.x
  .if bx > 7fh
    or bx, 65280
  .endif
  add eax, ebx
  mov player.pos.x, eax
  mov eax, player.pos.y
  mov ebx, player.speed.y
  .if bx > 7fh 
    or bx, 65280
  .endif
  add ax, bx
  mov player.pos.y, eax
  invoke fixCoordinates, addr player.pos
  ret
movePlayer endp

retMeteoro proc addrPos:DWORD
  assume ebx:ptr meteoroStr

  .if (addrPos == 0)
    mov ebx, offset meteoro1
  .elseif (addrPos == 1)
    mov ebx, offset meteoro2
  .elseif (addrPos == 2)
    mov ebx, offset meteoro3
  .elseif (addrPos == 3)
    mov ebx, offset meteoro4
  .elseif (addrPos == 4)
    mov ebx, offset meteoro5
  .elseif (addrPos == 5)
    mov ebx, offset meteoro6
  .elseif (addrPos == 6)
    mov ebx, offset meteoro7
  .elseif (addrPos == 7)
    mov ebx, offset meteoro8
  .elseif (addrPos == 8)
    mov ebx, offset meteoro9
  .elseif (addrPos == 9)
    mov ebx, offset meteoro10
  .elseif (addrPos == 10)
    mov ebx, offset meteoro11
  .elseif (addrPos == 11)
    mov ebx, offset meteoro12
  .elseif (addrPos == 12)
    mov ebx, offset meteoro13
  .elseif (addrPos == 13)
    mov ebx, offset meteoro14
  .elseif (addrPos == 14)
    mov ebx, offset meteoro15
  .elseif (addrPos == 15)
    mov ebx, offset meteoro16
  .elseif (addrPos == 16)
    mov ebx, offset meteoro17
  .elseif (addrPos == 17)
    mov ebx, offset meteoro18
  .elseif (addrPos == 18)
    mov ebx, offset meteoro19
  .elseif (addrPos == 19)
    mov ebx, offset meteoro20
  .elseif (addrPos == 20)
    mov ebx, offset meteoro21
  .elseif (addrPos == 21)
    mov ebx, offset meteoro22
  .elseif (addrPos == 22)
    mov ebx, offset meteoro23
  .elseif (addrPos == 23)
    mov ebx, offset meteoro24
  .elseif (addrPos == 24)
    mov ebx, offset meteoro25
  .elseif (addrPos == 25)
    mov ebx, offset meteoro26
  .elseif (addrPos == 26)
    mov ebx, offset meteoro27
  .elseif (addrPos == 27)
    mov ebx, offset meteoro28
  .elseif (addrPos == 28)
    mov ebx, offset meteoro29
  .elseif (addrPos == 29)
    mov ebx, offset meteoro30
  .elseif (addrPos == 30)
    mov ebx, offset meteoro31
  .elseif (addrPos == 31)
    mov ebx, offset meteoro32
  .elseif (addrPos == 32)
    mov ebx, offset meteoro33
  .elseif (addrPos == 33)
    mov ebx, offset meteoro34
  .elseif (addrPos == 34)
    mov ebx, offset meteoro35
  .elseif (addrPos == 35)
    mov ebx, offset meteoro36
  .elseif (addrPos == 36)
    mov ebx, offset meteoro37
  .elseif (addrPos == 37)
    mov ebx, offset meteoro38
  .elseif (addrPos == 38)
    mov ebx, offset meteoro39
  .elseif (addrPos == 39)
    mov ebx, offset meteoro40
  .elseif (addrPos == 40)
    mov ebx, offset meteoro41
  .elseif (addrPos == 41)
    mov ebx, offset meteoro42
  .elseif (addrPos == 42)
    mov ebx, offset meteoro43
  .elseif (addrPos == 43)
    mov ebx, offset meteoro44
  .elseif (addrPos == 44)
    mov ebx, offset meteoro45
  .elseif (addrPos == 45)
    mov ebx, offset meteoro46
  .elseif (addrPos == 46)
    mov ebx, offset meteoro47
  .elseif (addrPos == 47)
    mov ebx, offset meteoro48
  .elseif (addrPos == 48)
    mov ebx, offset meteoro49
  .elseif (addrPos == 49)
    mov ebx, offset meteoro50
  .endif  

  ret
retMeteoro endp 

; funcao que invoca os meteoros com o tempo
invocarMeteoros proc

  invoke randomizer
  assume ebx:ptr meteoroStr
  invoke retMeteoro, addr listMeteoro.qtd

  ;mov [ebx].pos.x, ecx
  ;mov [ebx].pos.y, 0
  ;mov [ebx].speed.x, offset METEORO_SPEED.x
  ;mov [ebx].speed.y, offset METEORO_SPEED.y
  ;mov [ebx].vida, 2
  ;mov [ebx].contador, 0
  ;mov [ebx].prox, 0

  .if listMeteoro.qtd == 0
    mov listMeteoro.primeiro, ebx
  .else
    assume eax:ptr meteoroStr
    mov eax, listMeteoro.primeiro
    loop1:
      .if [eax].prox == 0
        mov [eax].prox, ebx
        jmp fim
      .endif

      mov eax, [eax].prox
      jmp loop1
    fim:
  .endif
  mov eax, listMeteoro.qtd
  inc eax
  mov listMeteoro.qtd, eax
  ret
invocarMeteoros endp

retLaser proc addrPos:DWORD
  assume ebx:ptr laserDuplo

  .if (addrPos == 0)
    mov ebx, offset laser1
  .elseif (addrPos == 1)
    mov ebx, offset laser2
  .elseif (addrPos == 2)
    mov ebx, offset laser3
  .elseif (addrPos == 3)
    mov ebx, offset laser4
  .elseif (addrPos == 4)
    mov ebx, offset laser5
  .elseif (addrPos == 5)
    mov ebx, offset laser6
  .elseif (addrPos == 6)
    mov ebx, offset laser7
  .elseif (addrPos == 7)
    mov ebx, offset laser8
  .elseif (addrPos == 8)
    mov ebx, offset laser9
  .elseif (addrPos == 9)
    mov ebx, offset laser10
  .elseif (addrPos == 10)
    mov ebx, offset laser11
  .elseif (addrPos == 11)
    mov ebx, offset laser12
  .elseif (addrPos == 12)
    mov ebx, offset laser13
  .elseif (addrPos == 13)
    mov ebx, offset laser14
  .elseif (addrPos == 14)
    mov ebx, offset laser15
  .elseif (addrPos == 15)
    mov ebx, offset laser16
  .elseif (addrPos == 16)
    mov ebx, offset laser17
  .elseif (addrPos == 17)
    mov ebx, offset laser18
  .elseif (addrPos == 18)
    mov ebx, offset laser19
  .elseif (addrPos == 19)
    mov ebx, offset laser20
  .elseif (addrPos == 20)
    mov ebx, offset laser21
  .elseif (addrPos == 21)
    mov ebx, offset laser22
  .elseif (addrPos == 22)
    mov ebx, offset laser23
  .elseif (addrPos == 23)
    mov ebx, offset laser24
  .elseif (addrPos == 24)
    mov ebx, offset laser25
  .elseif (addrPos == 25)
    mov ebx, offset laser26
  .elseif (addrPos == 26)
    mov ebx, offset laser27
  .elseif (addrPos == 27)
    mov ebx, offset laser28
  .elseif (addrPos == 28)
    mov ebx, offset laser29
  .elseif (addrPos == 29)
    mov ebx, offset laser30
  .elseif (addrPos == 30)
    mov ebx, offset laser31
  .elseif (addrPos == 31)
    mov ebx, offset laser32
  .elseif (addrPos == 32)
    mov ebx, offset laser33
  .elseif (addrPos == 33)
    mov ebx, offset laser34
  .elseif (addrPos == 34)
    mov ebx, offset laser35
  .elseif (addrPos == 35)
    mov ebx, offset laser36
  .elseif (addrPos == 36)
    mov ebx, offset laser37
  .elseif (addrPos == 37)
    mov ebx, offset laser38
  .elseif (addrPos == 38)
    mov ebx, offset laser39
  .elseif (addrPos == 39)
    mov ebx, offset laser40
  .elseif (addrPos == 40)
    mov ebx, offset laser41
  .elseif (addrPos == 41)
    mov ebx, offset laser42
  .elseif (addrPos == 42)
    mov ebx, offset laser43
  .elseif (addrPos == 43)
    mov ebx, offset laser44
  .elseif (addrPos == 44)
    mov ebx, offset laser45
  .elseif (addrPos == 45)
    mov ebx, offset laser46
  .elseif (addrPos == 46)
    mov ebx, offset laser47
  .elseif (addrPos == 47)
    mov ebx, offset laser48
  .elseif (addrPos == 48)
    mov ebx, offset laser49
  .elseif (addrPos == 49)
    mov ebx, offset laser50
  .endif  
  
  ret
retLaser endp

; Adiciona um laser
adicionaLaser proc  
  assume ebx:ptr laserDuplo
  invoke retLaser, addr listLaser.qtd

  mov eax, 1
  add eax, player.pos.x
  ;mov [ebx].pos1.x, eax

  mov eax, 31
  add eax, player.pos.x
  ;mov [ebx].pos2.x, eax

  ;mov [ebx].pos1.y, offset player.pos.y
  ;mov [ebx].pos2.y, offset player.pos.y
  ;mov [ebx].speed.x, offset LASER_SPEED.x
  ;mov [ebx].speed.y, offset LASER_SPEED.y
  ;mov [ebx].prox, 0

  .if listLaser.qtd == 0      
    mov listLaser.primeiro, ebx
  .else
    assume eax:ptr laserDuplo
    mov eax, listLaser.primeiro
    loop1:
      .if [eax].prox == 0
        mov [eax].prox, ebx
        jmp fim
      .endif

      mov eax, [eax].prox
      jmp loop1
    fim:
    assume eax:nothing
    assume ebx:nothing
  .endif

  ;mov eax, listLaser.qtd
  ;inc eax
  ;mov listLaser.qtd, eax
  ret
adicionaLaser endp

runThread proc 
  
  mov eax, offset contagemPontuacao
  invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread3ID
  invoke CloseHandle, eax

  mov eax, offset invocar 
  invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread4ID
  invoke CloseHandle, eax
  ret
runThread endp


; função principal do jogo 
jogo proc p:DWORD
  LOCAL area:RECT

  .while estagio == 0 ;menu (espera o usuário apertar enter)
    invoke Sleep, 30
  .endw

  game:
  .if estagio == 1
    invoke runThread
  .endif
  .while estagio == 1
    invoke Sleep, 30

    ; verifica se bateu nos meteoros
    .if listMeteoro.qtd != 0
      assume eax:ptr meteoroStr
      mov eax, listMeteoro.primeiro
      loop1:
        invoke hitMeteoro, addr [eax]
        .if [eax].prox != 0
          mov eax, [eax].prox
          jmp loop1
        .endif
          jmp fim1
        fim1:
      assume eax:nothing 
    .endif

    ; verifica se os lasers bateram nos meteoros
    .if listMeteoro.qtd != 0 
      .if listLaser.qtd != 0
        assume eax:ptr meteoroStr
        assume ebx:ptr laserDuplo
        mov eax, listMeteoro.primeiro
        mov ebx, listLaser.primeiro

        loop2:
          loop3:
            invoke colisaoLaser, addr [ebx], addr [eax]
            .if [eax].prox != 0
              mov eax, [eax].prox
              jmp loop3
            .endif
              jmp fim3
            fim3:
          .if [ebx].prox != 0
            mov ebx, [ebx].prox
            jmp loop2
          .endif
            jmp fim2
          fim2:
        .endif 
      .endif     

    ; chama a funcao para mover a nave
    invoke movePlayer
    
    ; mover os lasers
    .if   listLaser.qtd == 40
      assume eax:ptr laserDuplo
      mov eax, offset listLaser.primeiro

      loop4:
        invoke moveLasers, addr [eax]
        .if [eax].prox != 0
          mov eax, [eax].prox
          jmp loop4
        .else
          jmp fim4
        .endif
      fim4:
      assume eax:nothing
    .endif

    ; mover os meteoros
    .if listMeteoro.qtd != 0
      assume eax:ptr meteoroStr    
      mov eax, offset listMeteoro.primeiro
      loop5:
        invoke moveMeteoros, addr [eax] 
        .if [eax].prox != 0
          mov eax, [eax].prox 
          jmp loop5
        .else
          jmp fim5
        .endif
      fim5:
      assume eax:nothing
    .endif
  .endw

  .while estagio == 3
    invoke Sleep, 30
  .endw
  
  jmp game
  ret
jogo endp


; funcao para invocar meteoros por tempo
invocar proc p:DWORD
  LOCAL area:RECT

  invoca:
  .while estagio == 1
    invoke Sleep, dificuldade

    ;invoke invocarMeteoros

    .if pontuacao > 1000
      mov dificuldade, 600
    .elseif pontuacao > 2000
      mov dificuldade, 500
    .elseif pontuacao > 3000
      mov dificuldade, 400
    .elseif pontuacao > 4000
      mov dificuldade, 300
    .elseif pontuacao > 5000
      mov dificuldade, 250
    .elseif pontuacao > 6000
      mov dificuldade, 200
    .elseif pontuacao > 7000
      mov dificuldade, 150
    .elseif pontuacao > 8000
      mov dificuldade, 100
    .elseif pontuacao > 9000
      mov dificuldade, 50
    .elseif pontuacao > 10000
      mov dificuldade, 10
    .endif
  .endw
  
  jmp invoca
  ret
invocar endp

; funcao para a contagem de pontos
contagemPontuacao proc p:DWORD
  LOCAL area:RECT

  timer:
  .while estagio == 1
    invoke Sleep, 100

    add pontuacao, 1
  .endw

  jmp timer
  ret
contagemPontuacao endp

tocaMusica proc  p:DWORD
  .while !over
   mov   open_lpstrElementName,OFFSET musicaDeFundo
   mov   open_lpstrDeviceType, 0h
   invoke mciSendCommandA,0,MCI_OPEN, MCI_OPEN_ELEMENT,offset open_dwCallback 
   invoke mciSendCommandA,open_wDeviceID,MCI_PLAY,MCI_FROM or MCI_NOTIFY,offset play_dwCallback
   invoke Sleep, 186000
  .endw
  invoke mciSendCommandA,open_wDeviceID,MCI_CLOSE,0,offset generic_dwCallback
  ret
tocaMusica endp

; cria a janela 
  WinMain proc hInst :HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR, CmdShow:DWORD
        LOCAL clientRect:RECT
        LOCAL wc:WNDCLASSEX
        LOCAL msg:MSG

        szText szClassName,"Game"

        mov wc.cbSize, sizeof WNDCLASSEX
        mov wc.style, CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc, OFFSET WndProc     
        mov wc.cbClsExtra, NULL
        mov wc.cbWndExtra, NULL

        m2m wc.hInstance, hInst               
        mov wc.hbrBackground, NULL    
        mov wc.lpszMenuName, NULL
        mov wc.lpszClassName, offset szClassName  

        invoke LoadIcon, hInst, 500    
        mov wc.hIcon, eax

        invoke LoadCursor, NULL, IDC_ARROW         
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc  

        mov clientRect.left, 0
        mov clientRect.top, 0
        mov clientRect.right, X
        mov clientRect.bottom, Y

        invoke AdjustWindowRect, addr clientRect, WS_CAPTION, FALSE

        mov eax, clientRect.right
        sub eax, clientRect.left
        mov ebx, clientRect.bottom
        sub ebx, clientRect.top
       
        invoke CreateWindowEx, NULL,
                              ADDR szClassName,
                              ADDR AppName,
                              WS_OVERLAPPED or WS_SYSMENU or WS_MINIMIZEBOX,
                              CW_USEDEFAULT, CW_USEDEFAULT, X, Y,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax 
        invoke ShowWindow,hWnd,SW_SHOWNORMAL      
        invoke UpdateWindow,hWnd                  

    .WHILE TRUE
                invoke GetMessage, ADDR msg,NULL,0,0 
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg 
                invoke DispatchMessage, ADDR msg 
    .ENDW
      mov eax,msg.wParam ;retorna o código de saída no eax
      ret 

  WinMain endp

  WndProc proc hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM      
    LOCAL direction:BYTE
    LOCAL keydown:BYTE
    mov direction, -1 
    mov keydown, -1

    .IF uMsg == WM_CREATE
      invoke SetTamanho
      invoke loadimages

      mov eax, offset jogo 
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread1ID 
      invoke CloseHandle, eax 

      mov eax, offset paintThread
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2ID
      invoke CloseHandle, eax

      mov eax, offset tocaMusica
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread5ID
      invoke CloseHandle, eax

    ; após fechar o app
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0

    .elseif uMsg == WM_PAINT
      invoke paint

    .elseif uMsg == WM_KEYUP 
      .if (wParam == 77h || wParam == 57h || wParam == VK_UP) ;w ou seta pra cima
        .if estagio == 1
          mov keydown, FALSE
          mov direction, D_TOP
        .endif

      .elseif (wParam == 61h || wParam == 41h || wParam == VK_LEFT) ;a ou seta pra esquerda
        .if estagio == 1
          mov keydown, FALSE
          mov direction, D_LEFT
        .endif

      .elseif (wParam == 73h || wParam == 53h || wParam == VK_DOWN) ;s ou seta pra baixo
        .if estagio == 1
          mov keydown, FALSE
          mov direction, D_DOWN
        .endif 

      .elseif (wParam == 64h || wParam == 44h || wParam == VK_RIGHT) ;d ou seta pra direita          
        .if estagio == 1
          mov keydown, FALSE
          mov direction, D_RIGHT
        .endif

      .elseif (wParam == 13)
        .if estagio == 0 || estagio == 2 || estagio == 3
          mov estagio, 1 
        .endif      

      .elseif (wParam == 46h)
        .if estagio == 1
          mov keydown, TRUE
          mov direction, 5
          invoke tocaMusicaLaser
          invoke adicionaLaser 
        .endif 
      .endif
      
      .if estagio == 1
        .if direction != -1
          mov atirou, 1
          invoke changePlayerSpeed, direction, keydown
        .endif 
      .endif 
  

    .elseif uMsg == WM_KEYDOWN ;se o usuario apertou alguma tecla

      .if (wParam == 77h || wParam == 57h || wParam == VK_UP) ;w ou seta pra cima
        .if estagio == 1
          mov keydown, TRUE
          mov direction, D_TOP
        .endif

      .elseif (wParam == 61h || wParam == 41h || wParam == VK_LEFT) ;a ou seta pra esquerda
        .if estagio == 1
          mov keydown, TRUE
          mov direction, D_LEFT
        .endif

      .elseif (wParam == 73h || wParam == 53h || wParam == VK_DOWN) ;s ou seta pra baixo
        .if estagio == 1
          mov keydown, TRUE
          mov direction, D_DOWN
        .endif

      .elseif (wParam == 64h || wParam == 44h || wParam == VK_RIGHT) ;d ou seta pra direita          
        .if estagio == 1
          mov keydown, TRUE
          mov direction, D_RIGHT
        .endif

      .elseif (wParam == 13)
        .if estagio == 0 || estagio == 2 || estagio == 3
          mov estagio, 1 
        .endif      

      .elseif (wParam == 46h)
        .if estagio == 1
          mov keydown, TRUE
          mov direction, 5
          invoke adicionaLaser  
          invoke tocaMusicaLaser
        .endif
      .endif

      .if estagio == 1
        .if direction != -1
          mov atirou, 1
          invoke changePlayerSpeed, direction, keydown
        .endif 
      .endif 
    .endif    

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret

  WndProc endp
end start
