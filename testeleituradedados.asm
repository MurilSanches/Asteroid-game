.486                                    ; create 32 bit code
    .model flat, stdcall                    ; 32 bit memory model
    option casemap :none                    ; case sensitive
 
    include \masm32\include\windows.inc     ; always first
    include \masm32\macros\macros.asm       ; MASM support macros
    include \masm32\include\masm32.inc
    include \masm32\include\gdi32.inc
    include \masm32\include\user32.inc
    include \masm32\include\kernel32.inc
    
    includelib \masm32\lib\masm32.lib
    includelib \masm32\lib\gdi32.lib
    includelib \masm32\lib\user32.lib
    includelib \masm32\lib\kernel32.lib
    
.data?

.data
    oi db 'oi'
    LF EQU 0Ah ;caracter Line Feed como LF

.code

    start:
        mov eax, OFFSET oi
        print eax
        call ler_e_printar
        exit

        ler_e_printar proc
            mov ah, 1h
            int 21h
            mov bl, al
            print bl
        ler_e_printar endp

    end start