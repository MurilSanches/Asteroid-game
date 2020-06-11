  .386                   ; minimum processor needed for 32 bit
  .model flat, stdcall   ; FLAT memory model & STDCALL calling
  option casemap :none   ; set code to case sensitive

  include \masm32\include\windows.inc
  include \masm32\include\user32.inc
  include \masm32\include\kernel32.inc
  include \MASM32\INCLUDE\gdi32.inc
  include \Masm32\include\winmm.inc 
  includelib \masm32\lib\user32.lib
  includelib \masm32\lib\kernel32.lib
  includelib \MASM32\LIB\gdi32.lib

; Bibliotecas para MCI tocar o mp3 
	includelib \Masm32\lib\winmm.lib

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

  .data
    AppName db "Asteroid",0
    CommandLine   dd 0
    hWnd          dd 0
    hInstance     dd 0
		musicadefundo db "Star_Wars-_The_Imperial_March_Darth_Vader_s_Theme.mp3",0         
		tiro          db "zapsplat_science_fiction_retro_laser_beam_002_44337.mp3",0         
		explosao	    db "zapsplat_science_fictyion_explosion_puff_smoke_medium_001_45027.mp3",0		; Sound file

		; - MCI_OPEN_PARMS Structure ( API=mciSendCommand ) -
		open_dwCallback     dd ?
		open_wDeviceID     dd ?
		open_lpstrDeviceType  dd ?
		open_lpstrElementName  dd ?
		open_lpstrAlias     dd ?

		; - MCI_GENERIC_PARMS Structure ( API=mciSendCommand ) -
		generic_dwCallback   dd ?

		; - MCI_PLAY_PARMS Structure ( API=mciSendCommand ) -
		play_dwCallback     dd ?
		play_dwFrom       dd ?
		play_dwTo        dd ?

    char          WPARAM 20h

  .code

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke GetCommandLine        ; provides the command line address
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       ; cleanup & return to operating system

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

        ;====================
        ; Put LOCALs on stack
        ;====================

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        LOCAL x  :DWORD
        LOCAL y  :DWORD
        LOCAL MaxX  :DWORD
        LOCAL MaxY  :DWORD

        szText szClassName,"Game"

        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

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

       
        ; tamanho da tela
        mov x, 800
        mov y, 600

        ; pega o tamanho maximo da largura da tela em pixels
        invoke GetSystemMetrics,SM_CXSCREEN 
        invoke TopXY,x,eax
        mov MaxX, eax

        ; pega o tamanho maximo da altura da tela em pixel
        invoke GetSystemMetrics,SM_CYSCREEN 
        invoke TopXY,y,eax
        mov MaxY, eax

       ; cria a tela do aplicativo
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR AppName,
                              WS_OVERLAPPEDWINDOW,
                              MaxX, MAxY, x, y,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax  ; copy return value into handle DWORD


        ;; menu horizontal
        ;invoke LoadMenu,hInst,600                 ; load resource menu
        ;invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
      cmp eax, 0                                  ; exit if GetMessage()
      je ExitLoop                                 ; returns zero
      invoke TranslateMessage, ADDR msg           ; translate it
      invoke DispatchMessage,  ADDR msg           ; send it to message proc
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL X     :DWORD
    LOCAL Y     :DWORD

    .if uMsg == WM_COMMAND
    

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
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    ; ----------------------------------------------------
    ; This procedure calculates the top X & Y co-ordinates
    ; for the CreateWindowEx call in the WinMain procedure
    ; ----------------------------------------------------

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

end start
