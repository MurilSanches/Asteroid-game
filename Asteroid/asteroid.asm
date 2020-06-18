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


;;; carrega as imagens 
  loadimages proc

    invoke LoadBitmap, hInstance, 100
    mov nave,eax

    invoke LoadBitmap, hInstance, 101
    mov h_background, eax
    ret

  loadimages endp    


;;; pega o tamanho maximo da tela
  getWindowSize proc

     invoke GetSystemMetrics,SM_CXSCREEN 
        invoke TopXY,x,eax
        mov MaxX, eax

        invoke GetSystemMetrics,SM_CYSCREEN 
        invoke TopXY,y,eax
        mov MaxY, eax

    ret
    
  getWindowSize endp

;;; pinta uma posição qualquer
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

;; pinta o fundo da tela
  paintbackground proc _hDC:HDC, _hMemDC:HDC, _hMemDC2:HDC
    invoke SelectObject, _hMemDC2, h_background
    invoke BitBlt, _hMemDC, 0, 0, x, y, _hMemDC2, 0, 0, SRCCOPY
  ret
  paintbackground endp

;;; desenha a nave
  paintnave proc _hDC:HDC, _hMemDC:HDC, _hMemDC2:HDC
    invoke SelectObject, _hMemDC2, nave
    invoke paintPos, _hMemDC, _hMemDC2, addr NAVE_SIZE_POINT, addr posInicial ;pinta
  paintnave endp

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

    ;invoke paintbackground, hDC, hMemDC, hMemDC2
    invoke paintnave, hDC, hMemDC, hMemDC2

    invoke BitBlt, hDC, 0, 0, x, y, hMemDC, 0, 0, SRCCOPY

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

;;; proc para encontrar as medidas maximas da tela
  TopXY proc wDim:DWORD, sDim:DWORD

      shr sDim, 1      ; divide screen dimension by 2
      shr wDim, 1      ; divide window dimension by 2
      mov eax, wDim    ; copy window dimension into eax
      sub sDim, eax    ; sub half win dimension from half screen dimension

      return sDim

  TopXY endp

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
        mov clientRect.right, x
        mov clientRect.bottom, y

        invoke AdjustWindowRect, addr clientRect, WS_CAPTION, FALSE

        mov eax, clientRect.right
        sub eax, clientRect.left
        mov ebx, clientRect.bottom
        sub ebx, clientRect.top
       
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR AppName,
                              WS_OVERLAPPEDWINDOW,
                              MaxX, MaxY, x, y,
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

    .IF uMsg == WM_CREATE
      invoke loadimages

      mov eax, offset paintThread
      invoke CreateThread, NULL, NULL, eax, 0, 0, addr thread2ID
      invoke CloseHandle, eax

    ; após fechar o app
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0

    .elseif uMsg == WM_PAINT
      invoke paint

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
