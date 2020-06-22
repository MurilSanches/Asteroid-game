;include files
include \masm32\include\windows.inc

include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \Masm32\include\winmm.inc 
include \masm32\include\msimg32.inc


;libraries
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\msimg32.lib
includelib \masm32\lib\winmm.lib

; Local prototypes

WinMain      PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc      PROTO :DWORD,:DWORD,:DWORD,:DWORD
TopXY        PROTO :DWORD,:DWORD
FillBuffer   PROTO :DWORD,:DWORD,:BYTE
Paint_Proc   PROTO :DWORD,:DWORD

;struct que é usada para definir coisas com x e y (posição e velocidade)
point struct 
    x dd 0      
    y dd 0
point ends

;atributos que todo objeto tem, serve como uma classe mãe

naveStr struct
  pos point<>
  dir byte 0
  speed point<>
  vida byte 3
naveStr ends

meteoroStr struct
  pos point<>
  speed point<>
  vida byte 2
  contador byte 0
  prox dd 0
meteoroStr ends

meteoros struct
  primeiro dd 0
  qtd byte 0
meteoros ends

laserStr struct
  pos1 point<>
  pos2 point<>
  speed point<>
  prox dd 0
laserStr ends

lasers struct
  primeiro dd 0
  qtd byte 0
lasers ends


;Local macros

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


.CONST
  ;tamanho da tela
  X EQU 800   
  Y EQU 600

  ;pos
  D_RIGHT       EQU 0 
  D_TOP         EQU 1  
  D_LEFT        EQU 2     
  D_DOWN        EQU 3

  ;tamanhos
  NAVE_SIZE point<40, 45>
  LIFE_SIZE point<36, 34>
  LASER_SIZE point<5, 10>
  EXPLOSAO_SIZE point<25, 25>
  METEORO_SIZE point<23, 20>

.DATA
  ; imagens
    nave dd 0
    coracao dd 0
    laser dd 0
    meteoro dd 0
    explosao dd 0
    meteoroQuebrado dd 0

    ; background
    fundoDoInicio dd 0
    fundoDoJogo dd 0
    fundoPerdeu dd 0
    fundoRank dd 0
    
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

 ;variaveis musicais
  musicaDeFundo db "Star_Wars-_The_Imperial_March_Darth_Vader_s_Theme.mp3",0         
  musicaTiro          db "zapsplat_science_fiction_retro_laser_beam_002_44337.mp3",0         
  musicaExplosao	    db "zapsplat_science_fictyion_explosion_puff_smoke_medium_001_45027.mp3",0		; Sound file

  over byte 0 ;
  hWnd          dd 0


  ;telas
  estagio byte 0

  ;instancias 
  player naveStr <<370, 500>, 0, <0, 0>, 3>
  listLaser lasers<OFFSET laser0, 0>
  listMeteoro meteoros<OFFSET meteoro0, 0>

  meteoro0 meteoroStr<>
  laser0 laserStr<>

  pont db "Pontuacao: ", 0
  
  atirou byte 0
  pontuacao dd 0
  dificuldade dd 700
  contador dd 0
  
  posInicial point<600, 100>
.DATA?
    thread1ID DWORD ?
    thread2ID DWORD ?
    thread3ID DWORD ?
    thread4ID DWORD ?
    thread5ID DWORD ?
    MaxY dd ?
    MaxX dd ?

    telaAtual dd ?



