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
    ;invoke  uFMOD_PlaySong, musicaDeFundo, 0, XM_FILE

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
      .if listLaser.qtd == 0
        invoke SelectObject, hMemDC2, laser

        mov eax, player.pos.x
        mov ebx, 1
        add ebx, eax
        invoke TransparentBlt, hDC, ebx, player.pos.y, LASER_SIZE.x, LASER_SIZE.y, hMemDC2, 0, 0, LASER_SIZE.x, LASER_SIZE.y, 16777215 
        mov eax, player.pos.x
        mov ebx, 31
        add ebx, eax
        invoke TransparentBlt, hDC, ebx, player.pos.y, LASER_SIZE.x, LASER_SIZE.y, hMemDC2, 0, 0, LASER_SIZE.x, LASER_SIZE.y, 16777215 
      .endif

      ; desenha os meteoros
      .if listMeteoro.qtd == 0
        invoke SelectObject, hMemDC2, meteoro

        invoke TransparentBlt, hDC, 300, 50, METEORO_SIZE.x, METEORO_SIZE.y, hMemDC2, 0, 0, METEORO_SIZE.x, METEORO_SIZE.y, 16777215
        invoke SelectObject, hMemDC2, meteoroQuebrado
        invoke TransparentBlt, hDC, 400, 50, METEORO_SIZE.x, METEORO_SIZE.y, hMemDC2, 0, 0, METEORO_SIZE.x, METEORO_SIZE.y, 16777215
        invoke SelectObject, hMemDC2, explosao
        invoke TransparentBlt, hDC, 500, 50, EXPLOSAO_SIZE.x, EXPLOSAO_SIZE.y, hMemDC2, 0, 0, EXPLOSAO_SIZE.x, EXPLOSAO_SIZE.y, 16777215
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
  assume ecx:ptr meteoroStr

  mov ecx, meteoroStr
  invoke isColliding, player.pos, [ecx].pos, NAVE_SIZE, METEORO_SIZE
  .if edx == TRUE
    dec player.vida
    .if player.vida == 0
      invoke reiniciar
      mov estagio, 3
      ret
    .endif 
  .endif

  assume ecx:nothing
  ret
hitMeteoro endp

; verifica se o laser acertou em um meteoro e faz o meteoro perder vida ou ser destruido
colisaoLaser proc addrLaser:DWORD, addrMeteoro:DWORD
  assume ebx:ptr laserStr
  assume ecx:ptr meteoroStr

  mov ebx, addrLaser
  mov ecx, addrMeteoro
  invoke isColliding, [ebx].pos1, [ecx].pos, LASER_SIZE, METEORO_SIZE
  .if edx == TRUE
    dec [ecx].vida

    ; remover o meteoro da lista ligada caso sua vida seja 0
    ; remover o laser da lista ligada caso acerte o meteoro
  .endif 

  invoke isColliding, [ebx].pos2, [ecx].pos, LASER_SIZE, METEORO_SIZE
  .if edx == TRUE
    dec [ecx].vida
    
    ; remover o meteoro da lista ligada caso sua vida seja 0
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
assume eax:ptr point
    mov eax, addrObj

    .if [eax].x > 800 && [eax].x < 80000000h
        mov [eax].x, 20
    .endif
    .if [eax].x <= 10 || [eax].x > 80000000h
        mov [eax].x, 780
    .endif 
    .if [eax].y > 520 && [eax].y < 80000000h
        mov [eax].y, 520
    .endif
    .if [eax].y <= 10 || [eax].y > 80000000h
        mov [eax].y, 10 
    .endif
assume eax:nothing
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
  mov edx, 500 
  ret
randomizer endp

; funcao para mover os meteoros 
moveMeteoros proc uses eax, addrMeteoro:DWORD
assume edx:ptr meteoroStr
  mov edx, addrMeteoro
  .if [edx].vida != 0
    mov eax, [edx].pos.x
    mov ebx, [edx].speed.x
    .if bx > 7fh
      or bx, 65280
    .endif
    add eax, ebx
    mov [edx].pos.x, eax
    mov eax, [edx].pos.y
    mov ebx, [edx].speed.y
    .if bx > 7fh 
      or bx, 65280
    .endif
    add ax, bx
    mov [edx].pos.y, eax   
  .endif     
  ret
moveMeteoros endp

; funcao para mover os lasers
moveLasers proc uses eax, addrLaser:DWORD
assume edx:ptr laserStr
mov edx, addrLaser

  mov eax, [edx].pos1.x
  mov ebx, [edx].speed.x
  .if bx > 7fh
    or bx, 65280
  .endif
  add eax, ebx
  mov [edx].pos1.x, eax
  mov eax, [edx].pos1.y
  mov ebx, [edx].speed.y
  .if bx > 7fh 
    or bx, 65280
  .endif
  add ax, bx
  mov [edx].pos1.y, eax

  mov eax, [edx].pos2.x
  mov ebx, [edx].speed.x
  .if bx > 7fh
    or bx, 65280
  .endif
  add eax, ebx
  mov [edx].pos2.x, eax
  mov eax, [edx].pos2.y
  mov ebx, [edx].speed.y
  .if bx > 7fh 
    or bx, 65280
  .endif
  add ax, bx
  mov [edx].pos2.y, eax
  ret
moveLasers endp

; função para o personagem se mover, baseado na velocidade
movePlayer proc uses eax

    ;invoke willCollide, pac.direction, addr pac.playerObj
      ;.if edx == FALSE
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
    ;.endif
    ret
movePlayer endp

; funcao que invoca os meteoros com o tempo
invocarMeteoros proc
  .if listMeteoro.qtd == 0
    invoke randomizer
    ;meteoro1 meteoroStr<>
    ;mov listMeteoro.primeiro, OFFSET meteoro1
  .else
    mov contador, 0
    ;.while contador != listMeteoro.qtd
      add contador, 1
    ;.endw
  .endif
  ret
invocarMeteoros endp

; Adiciona um laser
adicionaLaser proc  
  .if listLaser.qtd == 0      
    laser1 laserStr<>
    mov listLaser.primeiro, OFFSET laser1
  .else
    mov contador, 0
    ;.while contador != listLaser.qtd 
      add contador, 1
    ;.endw
  .endif

  add listLaser.qtd, 1
  ret
adicionaLaser endp

; função principal do jogo 
jogo proc p:DWORD
  LOCAL area:RECT

  .while estagio == 0 ;menu (espera o usuário apertar enter)
    invoke Sleep, 30
  .endw

  game:
  .while estagio == 1
    invoke Sleep, 30

    ; verifica se bateu nos meteoros

    ; verifica se os lasers barem nos meteoros

    ; chama a funcao para mover a nave
    invoke movePlayer
    
    ; mover os lasers
    mov contador, 0
    push eax
    assume eax:ptr laserStr
    mov eax, offset listLaser.primeiro

    ;.while contador != listLaser.qtd
      invoke moveLasers, addr [eax]
      add contador, 1
      .if [eax].prox != 0
        mov eax, [eax].prox
      .else
        mov ebx, offset listLaser.qtd
        mov contador, ebx
      .endif
    ;.endw  
    assume eax:nothing
    pop eax

    ; mover os meteoros
    mov contador, 0
    push eax
    assume eax:ptr meteoroStr    
    mov eax, offset listMeteoro.primeiro

    ;.while contador != listLaser.qtd
      invoke moveMeteoros, addr [eax]
      add contador, 1    
      .if [eax].prox != 0
        mov eax, [eax].prox 
      .else
        mov ebx, offset listMeteoro.qtd
        mov contador, ebx
      .endif
    ;.endw
    assume eax:nothing
    pop eax
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

    invoke invocarMeteoros

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

      mov eax, offset contagemPontuacao
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread3ID
      invoke CloseHandle, eax

      mov eax, offset invocar
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread3ID
      invoke CloseHandle, eax 

    ; após fechar o app
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0

    .elseif uMsg == WM_PAINT
      invoke paint

    .elseif uMsg == WM_KEYUP 
      .if (wParam == 77h || wParam == 57h || wParam == VK_UP) ;w ou seta pra cima
        mov keydown, FALSE
        mov direction, D_TOP

      .elseif (wParam == 61h || wParam == 41h || wParam == VK_LEFT) ;a ou seta pra esquerda
        mov keydown, FALSE
        mov direction, D_LEFT

      .elseif (wParam == 73h || wParam == 53h || wParam == VK_DOWN) ;s ou seta pra baixo
        mov keydown, FALSE
        mov direction, D_DOWN

      .elseif (wParam == 64h || wParam == 44h || wParam == VK_RIGHT) ;d ou seta pra direita          
        mov keydown, FALSE
        mov direction, D_RIGHT

      .elseif (wParam == 13)
        .if estagio == 0 || estagio == 2 || estagio == 3
          mov estagio, 1 
        .endif      

      .elseif (wParam == 46h)
        mov keydown, TRUE
        mov direction, 5
        invoke adicionaLaser 
      .endif

      .if direction != -1
        mov atirou, 1
         invoke changePlayerSpeed, direction, keydown
      .endif  
  

    .elseif uMsg == WM_KEYDOWN ;se o usuario apertou alguma tecla

      .if (wParam == 77h || wParam == 57h || wParam == VK_UP) ;w ou seta pra cima
        mov keydown, TRUE
        mov direction, D_TOP

      .elseif (wParam == 61h || wParam == 41h || wParam == VK_LEFT) ;a ou seta pra esquerda
        mov keydown, TRUE
        mov direction, D_LEFT

      .elseif (wParam == 73h || wParam == 53h || wParam == VK_DOWN) ;s ou seta pra baixo
        mov keydown, TRUE
        mov direction, D_DOWN

      .elseif (wParam == 64h || wParam == 44h || wParam == VK_RIGHT) ;d ou seta pra direita          
        mov keydown, TRUE
        mov direction, D_RIGHT

      .elseif (wParam == 13)
        .if estagio == 0 || estagio == 2 || estagio == 3
          mov estagio, 1 
        .endif      

      .elseif (wParam == 46h)
        mov keydown, TRUE
        mov direction, 5
        invoke adicionaLaser  
      .endif

      .if direction != -1
        mov atirou, 1
        invoke changePlayerSpeed, direction, keydown
      .endif  
    .endif    

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret

  WndProc endp
end start
