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


;;; carrega as imagens 
  loadimages proc

    invoke LoadBitmap, hInstance, 100
    mov nave,eax

    invoke LoadBitmap, hInstance, 102
    mov fundoDoJogo, eax

    invoke LoadBitmap, hInstance, 103
    mov coracao, eax

    invoke LoadBitmap, hInstance, 104
    mov laser, eax
    ret

  loadimages endp   


;;; Adiciona um laser
adicionaLaser proc  
  .if listLaser.qtd == 0      
    mov eax, player.pos.x 
    mov listLaser.primeiro.pos1.x, eax
    mov eax, player.pos.x 
    mov listLaser.primeiro.pos2.x, eax

    mov eax, player.pos.y
    mov listLaser.primeiro.pos1.y, eax
    mov listLaser.primeiro.pos2.y, eax
  .else
    ;laser1 laserStr<>

    ;.if listLaser.primeiro.prox == 0
      
    ;.endif
  .endif

  inc listLaser.qtd
ret
adicionaLaser endp


;;; pega o tamanho maximo da tela
  getWindowSize proc

     invoke GetSystemMetrics,SM_CXSCREEN 
        invoke TopXY, X, eax
        mov MaxX, eax

        invoke GetSystemMetrics,SM_CYSCREEN 
        invoke TopXY, Y, eax
        mov MaxY, eax

    ret
    
  getWindowSize endp

;;; estados do jogo

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

;;; desenhar os lasers
  paintLasers proc _hdc:HDC, _hMemDC:HDC, _hMemDC2:HDC
    invoke SelectObject, _hMemDC2, laser

    mov ebx, 0
    ;.while ebx != listLaser.qtd

    inc ebx
    ;.endw
    ret
  paintLasers endp


;;; desenha a tela inteira
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
      .if listLaser.qtd != 0
        invoke SelectObject, hMemDC2, laser
        invoke TransparentBlt, hDC, listLaser.primeiro.pos1.x, listLaser.primeiro.pos1.y, LASER_SIZE.x, LASER_SIZE.y, hMemDC2, 0, 0, LASER_SIZE.x, LASER_SIZE.y, 16777215 
    
        invoke TransparentBlt, hDC, listLaser.primeiro.pos2.x, listLaser.primeiro.pos2.y, LASER_SIZE.x, LASER_SIZE.y, hMemDC2, 0, 0, LASER_SIZE.x, LASER_SIZE.y, 16777215 
      .endif

    .endif

    invoke BitBlt, hDC, 0, 0, MaxX, MaxY, hMemDC, 0, 0, SRCCOPY

    invoke DeleteDC, hMemDC
    invoke DeleteDC, hMemDC2
    invoke DeleteObject, hBitmap
    invoke EndPaint, hWnd, ADDR paintstruct

  ret
  paint endp

; thread de desenho
 paintThread proc p:DWORD
    .while !over
        invoke Sleep, 17 ; 60 FPS

        invoke InvalidateRect, hWnd, NULL, FALSE

    .endw

    ret
paintThread endp 

fixCoordinates proc addrObj:dword
assume eax:ptr point
    mov eax, addrObj

    .if [eax].x > 800 && [eax].x < 80000000h
        mov [eax].x, 20
    .endif
    .if [eax].x <= 10 || [eax].x > 80000000h
        mov [eax].x, 800 - 20 
    .endif
    .if [eax].y > 600 - 30 && [eax].y < 80000000h
        mov [eax].y, 20
    .endif
    .if [eax].y <= 10 || [eax].y > 80000000h
        mov [eax].y, 600 - 80 
    .endif
assume eax:nothing
ret
fixCoordinates endp

;;; proc para encontrar as medidas maximas da tela
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

;muda a velocidade do pac dependendo da tecla q foi apertada
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

;função para o personagem se mover, baseado na velocidade
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

; função principal do jogo 
jogo proc p:DWORD
  LOCAL area:RECT

  .while estagio == 0 ;menu (espera o usuário apertar enter)
    invoke Sleep, 30
  .endw

  game:
  .while estagio == 1
    invoke Sleep, 30

    invoke movePlayer
  .endw

  .while estagio == 3
    invoke Sleep, 30
  .endw

  jmp game

  ret
jogo endp

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

      mov estagio, 1

      mov eax, offset jogo 
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread1ID 
      invoke CloseHandle, eax 

      mov eax, offset paintThread
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2ID
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

      .elseif (wParam == 20)
        mov keydown, FALSE
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
