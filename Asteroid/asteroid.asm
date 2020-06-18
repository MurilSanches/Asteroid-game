.386                   
.model flat, stdcall   
option casemap :none  

include asteroid.inc

szText MACRO Name, Text:VARARG
  LOCAL lbl
    jmp lbl
      Name db Text,0
    lbl:
  ENDM

m2m MACRO M1, M2
  push M2
  pop  M1
ENDM

return MACRO arg
  mov eax, arg
  ret
ENDM

  WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
  WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
  TopXY PROTO   :DWORD,:DWORD
  PlaySound	PROTO	STDCALL :DWORD, :DWORD, :DWORD

  .DATA
    AppName db "Asteroid",0

  .DATA?
    MaxY dd ?
    MaxX dd ?

.CODE

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    invoke ExitProcess,eax       ; cleanup & return to operating system

  getWindowSize proc
     invoke GetSystemMetrics,SM_CXSCREEN 
        invoke TopXY,x,eax
        mov MaxX, eax

        ; pega o tamanho maximo da altura da tela em pixel
        invoke GetSystemMetrics,SM_CYSCREEN 
        invoke TopXY,y,eax
        mov MaxY, eax

    ret
    
  getWindowSize endp

  paintPos proc  uses eax _hMemDC:HDC, _hMemDC2:HDC, addrPoint:dword, addrPos:dword
    assume edx:ptr point
    assume ecx:ptr point

    mov edx, addrPoint
    mov ecx, addrPos

    mov eax, [ecx].x
    mov ebx, [ecx].y
    invoke TransparentBlt, _hMemDC, eax, ebx, [edx].x, [edx].y, _hMemDC2, 0, 0, [edx].x, [edx].y, 16777215

ret
paintPos endp

  loadimages proc

    invoke LoadBitmap, hInstance, 100
    mov nave,eax

    invoke LoadBitmap, hInstance, 101
    mov h_background, eax
    ret

  loadimages endp

  paintbackground proc hDC:HDC, _hMemDC:HDC, _hMemDC2:HDC, _hBitmap:HDC
    invoke SelectObject, _hMemDC2, h_background
    invoke BitBlt, _hMemDC, 0, 0, 800, 600, _hMemDC2, 0, 0, SRCCOPY
  ret
  paintbackground endp

  paintnave proc hDC:HDC, _hMemDC:HDC, _hMemDC2:HDC, _hBitmap:HDC
    invoke SelectObject, _hMemDC2, nave
    invoke paintPos, _hMemDC, _hMemDC2, addr NAVE_, addr pac.playerObj.pos ;pinta
  paintnave endp

  paint proc hDC:HDC, _hMemDC:HDC, _hMemDC2:HDC, _hBitmap:HDC

    invoke BeginPaint, hWnd, ADDR paintstruct
    mov hDC, eax
    invoke CreateCompatibleDC, hDC
    mov _hMemDC, eax
    invoke CreateCompatibleDC, hDC
    mov _hMemDC2, eax
    invoke CreateCompatibleBitmap, hDC, MaxX, MaxY
    mov _hBitmap, eax

    invoke SelectObject, hMemDC, hBitmap




    invoke BitBlt, hDC, 0, 0, MaxX, MaxY, _hMemDC, 0, 0, SRCCOPY

    invoke DeleteDC, _hMemDC
    invoke DeleteDC, _hMemDC2
    invoke DeleteObject, _hBitmap
    invoke EndPaint, hWnd, ADDR paintstruct

  ret
  paint endp

  TopXY proc wDim:DWORD, sDim:DWORD

      shr sDim, 1      ; divide screen dimension by 2
      shr wDim, 1      ; divide window dimension by 2
      mov eax, wDim    ; copy window dimension into eax
      sub sDim, eax    ; sub half win dimension from half screen dimension

      return sDim

  TopXY endp

; cria a janela 
  WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        szText szClassName,"Game"

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                               or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        m2m wc.hInstance,      hInst               ; instance handle
        mov wc.hbrBackground,  COLOR_BTNFACE+1    ; system color
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset szClassName  ; window class name
          invoke LoadIcon,hInst,500    ; icon ID   ; resource icon
        mov wc.hIcon,          eax
          invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc     ; register the window class
       
       ; cria a tela do aplicativo
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR AppName,
                              WS_OVERLAPPEDWINDOW,
                              MaxX, MaxY, x, y,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax  ; copy return value into handle DWORD


        ;; menu horizontal
        ;invoke LoadMenu,hInst,600                 ; load resource menu
        ;invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

    .WHILE TRUE
                invoke GetMessage, ADDR msg,NULL,0,0 
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg 
                invoke DispatchMessage, ADDR msg 
    .ENDW
      mov eax,msg.wParam ;retorna o código de saída no eax
      ret 

  WinMain endp

  WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL hDC    :HDC
    LOCAL Ps     :PAINTSTRUCT
    LOCAL X     :DWORD
    LOCAL Y     :DWORD

    LOCAL hMemDC:HDC
    LOCAL hMemDC2:HDC
    LOCAL hBitmap:HDC

    .IF uMsg == WM_CREATE
      invoke loadimages
      invoke paint, hDC, hMemDC, hMemDC2, hBitmap

    .elseif uMsg == WM_LBUTTONDOWN   
     

    .elseif uMsg == WM_CREATE
        mov     X,100
        mov     Y,100
    
    ; funcão do botao fechar 
    .elseif uMsg == WM_CLOSE
        szText TheText,"Voce quer mesmo sair do jogo"
        invoke MessageBox,hWin,ADDR TheText,ADDR AppName,MB_YESNO
          .if eax == IDNO
            return 0
          .endif
    ; após fechar o app
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0

    .elseif uMsg == WM_KEYDOWN ;se o usuario apertou alguma tecla

      .if (wParam == 77h || wParam == 57h || wParam == VK_UP) ;w ou seta pra cima
          ;print "cima", 13,10
          ;mov direction, D_TOP

      .elseif (wParam == 61h || wParam == 41h || wParam == VK_LEFT) ;a ou seta pra esquerda
          ;print "esquerda", 13,10
          ;mov direction, D_LEFT

      .elseif (wParam == 73h || wParam == 53h || wParam == VK_DOWN) ;s ou seta pra baixo
          ;print "baixo", 13,10
          ;mov direction, D_DOWN

      .elseif (wParam == 64h || wParam == 44h || wParam == VK_RIGHT) ;d ou seta pra direita
          ;print "direita", 13,10
          ;mov direction, D_RIGHT

      .elseif (wParam == 20)
          ;atira
      .endif
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret

  WndProc endp
end start
