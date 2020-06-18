include \masm32\include\windows.inc

include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \Masm32\include\winmm.inc 
include \masm32\include\msimg32.inc


includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\msimg32.lib
includelib \masm32\lib\winmm.lib

;struct que é usada para definir coisas com x e y (posição e velocidade)
point struct 
    x dd 0      
    y dd 0
point ends

;atributos que todo objeto tem, serve como uma classe mãe
gameObject struct
    initPos     point <> 
    pos         point <>
    speed       point <>
gameObject ends


.CONST

    x EQU 800   
    y EQU 600

.DATA

  h_background        dd 0

  nave dd 0

  NAVE_SIZE_POINT point<30,30>

  paintstruct        PAINTSTRUCT <>

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

  musicadefundo db "Star_Wars-_The_Imperial_March_Darth_Vader_s_Theme.mp3",0         
    tiro          db "zapsplat_science_fiction_retro_laser_beam_002_44337.mp3",0         
    explosao	    db "zapsplat_science_fictyion_explosion_puff_smoke_medium_001_45027.mp3",0		; Sound file

    CommandLine   dd 0
    hWnd          dd 0
    hInstance     dd 0

.DATA?
