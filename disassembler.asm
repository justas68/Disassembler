.MODEL small
.stack 100h 
.DATA    
viso dw 00, 00, 00, 00
sk db 255 dup(0)   ;duomenu failo vardas
rez db 255 dup(0)  ;rezultatu failo vardas
buf db 16 dup (0)  ;cia saugomi nuskaityti simboliai
mod dw 4 dup (0)
reg dw 4 dup (0)
rm_nr db 4 dup (0)
rm dw 3 dup (0) 
betop db 8 dup (0) 
baitu_nr db 0, 1, 0, 0, ': ', ' ',' '
w db 2 dup (0)
d db 2 dup (0) 
tarpas db '            ' 
kiek db 0, 0  
enteris db 13, 10
fp dw 00, 00, 00
opk db 0
poslinkis db 15 dup (0) 
dvit_sk db '[:'
kablelis db ', '  
reg1  db 'al cl dl bl ah ch dh bh '
reg2  db 'ax cx dx bx sp bp si di '
kom1  db 'MOV  PUSH POP  ADD  INC  '
kom2  db 'SUB  DEC  CMP  MUL  DIV  CALL  '
kom3  db 'RET  JMP  LOOP INT  RETF  '
kom4  db 'JO   JNO  JB   JNB  JE   JNE  JBE  JA   '
kom5  db 'JS   JNS  JP   JNP  JL   JGE  JLE  JG   JCXZ '
prefix db 'es:cs:ss:ds: '
segpref dw 00, 00,00, 00
sr db 'es cs ss ds ' 
ad1 db '[bx+si][bx+di][bp+si][bp+di][si][di][[bx]'
poz1 db 0, 7, 14, 21, 28, 32,36, 37, 41 
ad2 db '[bx+si+[bx+di+[bp+si+[bp+di+[si+[di+[bp+[bx+'
poz2 db 0, 7,14, 21,28, 32, 36, 40, 44   
g db 'byte ptr word ptr ' 
skaiciai db '0123456789ABCDEF'
fail_ db 'Justas Tvarijonas PS 1 kursas 3 grupe 2016m.',13, 10,  'Si programa disasemblina 8086 architekturos koda$'
klaida_su db 'sukuriant rezultatu faila istiko klaida$'
klaida_atidarymo db 'klaida atidarant duomenu faila (galbut jo nera)$' 
nope db 'neatpazinta'
.CODE
;------------------------
strt:            
    mov dx, @data
    mov ds, dx
;------------- 
    call failai
    call atidaryk
   ; nuo cia prasides main programa
main: 
    call skaityk 
    cmp ax, 0 
    jg tol
    call pabaiga
tol: 
    mov segpref[2], 0 
    mov di, 0       
    call baito_nr
    mov si, offset buf
    mov opk, 1
    mov al, [si]
    mov segpref, offset prefix
    cmp al, 26h
    je pref    
    mov segpref, offset prefix+3
    cmp al, 2eh               
    je pref 
    mov segpref, offset prefix+6
    cmp al, 36h
    je pref                   
    mov segpref, offset prefix+9
    cmp al, 3eh
    je pref
    jmp nreg
pref:
    inc opk
    inc si
    mov segpref[2], 3 
    
nreg:    
    mov al, [si]
    and al, 11111100b  
    cmp al, 0
    mov bx, offset kom1+15 
    je _1    
    cmp al, 28h
    mov bx, offset kom2
    je _1          ;mod reg r/m [poslinkis]
    cmp al, 38h
    mov bx, offset kom2+10
    je _1
    cmp al, 88h
    mov bx, offset kom1
    je _1 
    jmp n_reg 
;----------------------
_1:      
   mov viso[6], bx
   call mod_reg
   jmp radau
n_reg: 
    mov al, [si]
    cmp al, 8fh
    je gal_r_m2 
    and al, 11111110b    ;mod *** r/m [poslinkis]
    cmp al, 0F6h
    je gal_r_m3
    cmp al, 0FEh
    je gal_r_m1
    jmp bojb
gal_r_m1:
    inc si
    mov al, [si]
    and al, 00111000b
    mov bx, offset kom1+20 
    cmp al, 0
    je tikrai_r_m 
    mov bx, offset kom3+5 
    cmp al, 20h
    je tikrai_r_m
    mov bx, offset kom1+5
    cmp al, 30h
    je tikrai_r_m  
    mov bx, offset kom2+5  ;tikrina ar antras baitas
    cmp al, 8              ; atitinka *** reiksmes
    je tikrai_r_m  
    mov bx, offset kom2+25
    cmp al, 10h
    je tikrai_r_m  
    cmp al, 18h
    je tikrai_r_m  
    mov bx, offset kom3+5
    cmp al, 28
    je tikrai_r_m
    dec si
    jmp bojb
gal_r_m2:
    inc si
    mov al, [si]
    and al, 00111000b
    cmp al, 0
    mov bx, offset kom1+10
    je tikrai_r_m
    dec si
    jmp bojb
gal_r_m3:
    inc si
    mov al, [si]
    and al, 00111000b
    cmp al, 20h
    mov bx, offset kom2+15
    je tikrai_r_m
    cmp al, 30h
    mov bx, offset kom2+20
    je tikrai_r_m 
    dec si
    jmp bojb
tikrai_r_m:
    mov viso[6], bx
    call r_m
    jmp radau    
bojb:                                       
    and al, 11111110b  
    mov bx, offset kom1+15
    cmp al, 4
    je _bojb      
    mov bx, offset kom2+10
    cmp al, 3Ch
    je _bojb      
    mov bx, offset kom2     
    cmp al, 2Ch      ;*******w bojb[bovb]
    je _bojb
    jmp p_seg
_bojb: 
    mov viso[6], bx
    call _bojb_
    jmp radau
p_seg:
    mov al, [si]
    and al, 11100111b
    mov bx, offset kom1+5
    cmp al, 6
    je _p_seg     
    mov bx, offset kom1+10   ;***sr***
    cmp al, 7
    je _p_seg
    jmp o_reg 
_p_seg: 
    mov viso[6], bx
    call p_seg_
    jmp radau
o_reg: 
    mov al, [si]
    and al, 11111000b
    mov bx, offset kom1+20
    cmp al, 40h
    je _o_reg     
    mov bx, offset kom2+5    ;*****reg
    cmp al, 48h
    je _o_reg     
    mov bx, offset kom1+5
    cmp al, 50h
    je _o_reg     
    mov bx, offset kom1+10
    cmp al, 58h
    je _o_reg  
    jmp con_jump
_o_reg:  
    mov viso[6], bx
    call o_reg_
    jmp radau
con_jump:
    mov al, [si]
    mov bx, offset kom4
    cmp al, 70h
    je _con_jump1
    mov bx, offset kom4+5        ;beveik vient conditional jumpai
    cmp al, 71h
    je _con_jump1
    mov bx, offset kom4+10
    cmp al, 72h
    je _con_jump1
    mov bx, offset kom4+15
    cmp al, 73h
    je _con_jump
    mov bx, offset kom4+20
    cmp al, 74h
    je _con_jump
    mov bx, offset kom4+25
    cmp al, 75h
    je _con_jump
    mov bx, offset kom4+30
    cmp al, 76h
    je _con_jump
    jmp ttt
_con_jump1:
	jmp _con_jump
ttt:
    mov bx, offset kom4+35
    cmp al, 77h
    je _con_jump
    mov bx, offset kom5
    cmp al, 78h
    je _con_jump
    mov bx, offset kom5+5
    cmp al, 79h
    je _con_jump
    mov bx, offset kom5+10
    cmp al, 7Ah
    je _con_jump
    mov bx, offset kom5+15
    cmp al, 7Bh
    je _con_jump
    mov bx, offset kom5+20
    cmp al, 7ch
    je _con_jump
    mov bx, offset kom5+25
    cmp al, 7Dh
    je _con_jump
    mov bx, offset kom5+30
    cmp al, 7Eh 
    je _con_jump
    mov bx, offset kom5+35
    cmp al, 7Fh 
    je _con_jump
    mov bx, offset kom5+40
    cmp al, 0E3h 
    je _con_jump
    mov bx, offset kom3+5
    cmp al, 0EBh 
    je _con_jump
    mov bx, offset kom3+10
    cmp al, 0E2h 
    je _con_jump
    mov bx, offset kom3+15
    cmp al, 0CDh 
    je _con_jump   
    jmp mod_bojb
_con_jump: 
    mov viso[6], bx
    call con_jump_
    jmp radau 
mod_bojb:
    mov al, [si]
    and al, 11111110b 
    cmp al, 0C6h
    je gal_mod_bojb2
    and al, 11111100b
    cmp al, 80h
    je gal_mod_bojb1 
    jmp ajb
gal_mod_bojb1:
    inc si
    mov al, [si]
    and al, 00111000b
    mov bx, offset kom1+15
    cmp al, 0
    je tikrai_mod_bojb 
    mov bx, offset kom2
    cmp al, 28h
    je tikrai_mod_bojb
    mov bx, offset kom2+10
    cmp al, 38h
    je tikrai_mod_bojb
    dec si
    jmp ajb
gal_mod_bojb2:
    inc si
    mov al, [si]
    and al, 00111000b 
    mov bx, offset kom1
    cmp al, 0
    je tikrai_mod_bojb 
    dec si
    jmp ajb
tikrai_mod_bojb: 
    mov viso[6], bx
    call _mod_bojb
    jmp radau 
    ;------
ajb:
    mov al, [si]
    and al, 11111110b 
    mov bx, offset kom1
    cmp al, 0A0h          ;mov su akumu 
    je _ajb     
    cmp al, 0A2h
    je _ajb  
    jmp _ret 
_ajb:    
    mov viso[6], bx
    call ajb_
    jmp radau
_ret:
    mov al, [si]
    mov bx, offset kom3+20 
    cmp al, 0CBh
    je _ret_ 
    mov bx, offset kom3
    cmp al, 0C3h
    je _ret_
    jmp ajb_srjb
_ret_:
    mov viso[6], bx
    call ret_
    jmp radau
ajb_srjb:
    mov al, [si]
    mov bx, offset kom3+5
    cmp al, 0EAh
    je _ajb_srjb  
    mov bx, offset kom2+25
    cmp al, 9Ah
    je _ajb_srjb
    jmp dar_ret
_ajb_srjb:
    mov viso[6], bx
    call ajb_srjb_
    jmp radau
dar_ret:
    mov al, [si]
    mov bx, offset kom3
    cmp al, 0C2h
    je _dar_ret
    mov bx, offset kom3+20
    cmp al, 0CAh
    je _dar_ret
    mov bx, offset kom2+20
    cmp al, 0E8h
    je _dar_ret
    mov bx, offset kom3+5
    cmp al, 0E9h
    je _dar_ret
    jmp liko
_dar_ret:
    mov viso[6], bx
    call dar_ret_
    jmp radau
liko:
    mov al, [si]
    and al, 11110000b 
    mov bx, offset kom1
    cmp al, 0B0h
    je mov_bet
    mov al, [si]
    and al, 11111101b
    mov bx, offset kom1
    cmp al, 8Ch
    je mov_sr
    jmp vsio
mov_sr: 
    mov viso[6], bx
    call mov_sr_
    jmp radau
mov_bet:
    mov viso[6], bx
    call mov_bet_
    jmp radau
vsio:              
    call isvesk_baita
    mov dx, offset nope
    mov di, 11
    call isvesk_poslinki
radau:
        mov dx, offset enteris
    mov di, 2
    call isvesk_poslinki
    jmp main         
;------------------------------


;tiria pirmos grupės komandas
;d w mod reg r/m poslinkis
mod_reg proc
    inc si 
    inc opk
    call w_d
    call koks_mod
    call koks_reg      
    call koks_rm_nr
    call koks_r_m
    call isvesk_baita
    call isvesk_kom_pav
    cmp d, 2
    je pirma_reg  
    call isvesk_rm 
    call isvesk_kableli
    call isvesk_reg
    ret
pirma_reg:
    call isvesk_reg
    call isvesk_kableli
    call isvesk_rm   
ret
endp
;tiria antros grupes komandas
;w mod r/m poslinkis
r_m proc
    inc opk
    call w_d
    call koks_mod
    call koks_rm_nr
    call koks_r_m 
    call isvesk_baita
    call isvesk_kom_pav
    cmp mod, 0C0h
    je jau_gali_vest
    cmp viso[6], 02c6h
    je bus_kaskoks
    cmp viso[6], 02cbh
    je bus_kaskoks
    cmp viso[6], 02b2h
    je bus_kaskoks
    cmp viso[6], 02bch 
    je bus_kaskoks
    jmp jau_gali_vest
bus_kaskoks:
    cmp w, 1
    je bus_word_ptr
    lea dx, g
    mov cx, 9
    mov ah, 40h
    int 21h
    jmp jau_gali_vest
bus_word_ptr:  
    lea dx, g+9
    mov cx, 9
    mov ah, 40h
    int 21h
jau_gali_vest: 
    call isvesk_rm
    ret
endp 
;tiria trecios grupes komandas 
;akumas+bet op
_bojb_:
    inc si
    call w_d
    dec si
    cmp w, 1
    je taip
    mov mod, 00 
    mov reg, offset reg1
    jmp ne
taip:
    mov mod, 80h 
    mov reg, offset reg2
ne: 
    call pos
    dec di
    call isvesk_baita
    call isvesk_kom_pav
    call isvesk_reg 
    call isvesk_kableli
    mov dx, offset poslinkis
    call isvesk_poslinki
    ret
endp  
;tiria ketvirtos grupes komandas
;push pop segreg
p_seg_ proc
    call koks_segreg
    call isvesk_baita
    call isvesk_kom_pav
    call isvesk_reg
    ret
endp 
;tiria penktos grupes komandas
;inc dec push pop zodinis registras
o_reg_ proc 
    call koks_rm_nr
    mov bx, 0
    mov bl, 3
    mul bl    
    mov ah, 0
    mov reg, offset reg2
    add reg, ax
    call isvesk_baita
    call isvesk_kom_pav
    call isvesk_reg
    ret
endp 
;tirai sestos grupes komandas
; conditianal jumpai bei int
con_jump_ proc
    mov mod, 00
    cmp al, 0CDh
    jne ieskosim_zymes
    call pos 
    jmp isvedam
ieskosim_zymes:
    call zyme
    inc di 
    inc opk
isvedam: 
    dec di
    call isvesk_baita
    call isvesk_kom_pav 
    mov dx, offset poslinkis
    call isvesk_poslinki
    ret
endp
;tiria septintos grupes komandas 
;s w mod 000 r/m [poslinkis] betarpiskas operandas
_mod_bojb proc
    inc opk
    call w_d 
    dec si
    mov al, [si]  
    inc si
    and al, 11110000b
    cmp al, 0C0h
    jne toll
    mov d, 0 
toll:
    call koks_mod
    call koks_rm_nr
    call koks_r_m 
    call bet_op
    call isvesk_baita
    call isvesk_kom_pav  
    cmp mod, 0c0h
    je isvedem_ptr
    cmp w, 0
    je bus_byte
    lea dx, g+9
    mov cx, 9
    mov ah, 40h
    int 21h
    jmp isvedem_ptr
bus_byte:
    lea dx, g
    mov cx, 9
    mov ah, 40h
    int 21h
isvedem_ptr: 
    mov cx, di
    mov di, viso[8]
    mov viso[8], cx
    call isvesk_rm 
    call isvesk_kableli
    mov di, viso[8]
    mov dx, offset betop
    call isvesk_poslinki
    ret
endp 
;tiria astuntos grupes komandas
ajb_ proc
    inc si
    call w_d 
    mov mod, 80h
    call pos
    cmp w, 0
    je bus_al
    mov reg, offset reg2
    jmp toleliau
bus_al:
    mov reg, offset reg1
toleliau:     
    mov w, 1
    call isvesk_baita
    call isvesk_kom_pav
    cmp d, 2
    je vesim_al 
    call isvesk_reg
    call isvesk_kableli
    mov dx, segpref 
    mov segpref[4], di
    mov di, segpref[2]
    call isvesk_poslinki 
    mov di, segpref[4]  
    lea dx, dvit_sk
    mov cx, 1
    mov ah, 40h
    int 21h
    mov dx, offset poslinkis
    call isvesk_poslinki 
    ret
vesim_al:
    mov dx, segpref 
    mov segpref[4], di
    mov di, segpref[2]
    call isvesk_poslinki 
    mov di, segpref[4]
    lea dx, dvit_sk
    mov cx, 1
    mov ah, 40h
    int 21h
    mov dx, offset poslinkis
    call isvesk_poslinki 
    call isvesk_kableli
    call isvesk_reg
    ret
endp 
;isveda 9 grupes komandas (ret ir retf)
ret_ proc
    call isvesk_baita
    call isvesk_kom_pav
    ret
endp
;tiria 10grupės komandas (jmp, call, isorinis tiesioginis) 
ajb_srjb_ proc
    add opk, 4 
    call isvesk_baita
    call isvesk_kom_pav
    mov si, offset buf
    mov mod, 80h
    sub opk, 1
    call pos
    dec di
    mov dx, offset dvit_sk
    call isvesk_simboli 
    mov dx, offset poslinkis
    call isvesk_poslinki
    sub opk, 4 
    mov si, offset buf
    call pos
    mov dx, offset dvit_sk+1
    call isvesk_simboli
    mov dx, offset poslinkis
    call isvesk_poslinki 
    mov opk, 5
    ret
endp  
;tiria 11 grupes komandas
dar_ret_ proc
    mov mod, 80h
    call pos
    call isvesk_baita
    call isvesk_kom_pav
    dec di
    mov dx, offset poslinkis
    call isvesk_poslinki
    mov opk, 3
    ret
endp        
;isskirtinis atvejis (mov segreg, rm)
mov_sr_ proc 
    inc opk
    inc si
    call w_d
    mov w, 1
    call koks_mod
    call koks_rm_nr
    call koks_r_m
    mov si, offset buf
    inc si
    cmp segpref[2], 3 
    jne nebuvo_pref
    inc si
nebuvo_pref:
    call koks_segreg
    call isvesk_baita
    call isvesk_kom_pav
    cmp d, 2
    je pirma_sr
    call isvesk_rm
    call isvesk_kableli
    call isvesk_reg    
    ret
pirma_sr:
    call isvesk_reg
    call isvesk_kableli
    call isvesk_rm
    ret
endp
;isskirtinis atvejis, mov reg, betarpiskas op
mov_bet_ proc 
    mov ax, 0
    mov al, [si]
    and al, 00001000b
    cmp al, 0
    je _1_bait_
    mov mod, 80h
    mov al, [si]
    and al, 00000111b
    mov bl, 3
    mul bl
    mov reg, offset reg2
    add reg, ax
    jmp ieskok_bo 
_1_bait_:    
    mov mod, 0 
    mov al, [si]
    and al, 00000111b
    mov bl, 3
    mul bl
    mov reg, offset reg1
    add reg, ax
ieskok_bo:
    inc si 
    call pos
    dec di
    call isvesk_baita
    call isvesk_kom_pav
    call isvesk_reg
    call isvesk_kableli
    mov dx, offset poslinkis
    call isvesk_poslinki
    ret
endp            
;suranda segmentini registra
koks_segreg proc
    mov al, [si]
    and al, 00011000b
    cmp al, 0
    jne gal_cs
    mov reg, offset sr
    ret
gal_cs:
    cmp al, 8
    jne gal_ss
    mov reg, offset sr+3
    ret
gal_ss:
    cmp al, 10h
    jne reiskias_ds 
    mov reg, offset sr+6
    ret
reiskias_ds:
    mov reg, offset sr+9
    ret
endp 
;suranda betarpiska operanda
;ji isplecia jeigu reikia
; mov viso[8], di!
bet_op proc
    mov viso[8], di
    mov si, offset buf
    mov dx, 0
    mov dl, opk
    add si, dx
    cmp w, 0
    je nereiks_s
    cmp d, 2
    je plesim
    call skaiciuok_bojb
    ret
plesim:
    mov al, [si]
    and al, 10000000b
    cmp al, 80h
    jne nuliai
    mov betop[0], 'F'
    mov betop[1], 'F' 
    jmp ispletem
nuliai:
    mov betop[0], '0'
    mov betop[1], '0'
ispletem:
    mov di, 4
    mov bl, 0016
    mov al, [si]
    mov ah, 0
    div bl
    mov betop[2], al
    mov betop[3], ah
    cmp betop[2], 9
    jg virs2
    add betop[2], 30h
    jmp antra_dalis
virs2:
    add betop[2], 37h
antra_dalis:
     cmp betop[3], 9
    jg virs3
    add betop[3], 30h 
    inc opk
    ret
virs3:
    add betop[3], 37h 
    inc opk
    ret  
nereiks_s:
    call skaiciuok_bojb
    ret
endp
;suskaiciuoja betarpiska operanda, 1 arba 2 baitus                     
skaiciuok_bojb proc
    mov di, 0 
    mov dx, 0
    cmp w, 1
    je _2baitu 
    inc opk
    mov dx, 1 
    jmp ll
_2baitu:
    inc si  
    add opk, 2
    mov dx, 2 
ll:
    mov al, [si]
    mov ah, 0
    mov bl, 10h
    div bl 
    mov bl, 1 
    mov betop[di], al
    mov betop[di+1], ah 
dar_kart:
    cmp betop[di], 9
    jg virs2_
    add betop[di], 30h
    jmp maziau2
virs2_:
    add betop[di], 37h
maziau2:    
    dec bl 
    inc di
    cmp bl, 0
    jge dar_kart 
    dec dx
    cmp dx, 0
    je galas
    dec si
    jmp ll
galas: 
    ret
endp              
; suranda w ir d, naudoja al registra 
w_d proc
    dec si
    mov al, [si]
    and al, 000000010b
    mov d, al
    mov al, [si]
    and al, 000000001b
    mov w, al
    inc si
    ret
endp 
;suranda mod, naudoja al registra
koks_mod proc
    mov ah, 0
    mov al, [si]
    and al, 11000000b     ;suranda mod
    mov mod, ax
    ret
endp   
; suranda reg, naudoja al ir bl registrus
koks_reg proc 
    mov ah, 0
    mov al, [si]
    and al, 00111000b            ;suranda reg
    mov bl, 8
    div bl
    mov bl, 3
    mul bl  
    mov reg, ax
    ret  
;suranda r/m, naudoja al registra
endp
koks_rm_nr proc
    mov al, [si]
    and al, 000000111b       ;suranda r/m
    mov rm_nr, al
ret
endp
koks_r_m proc 
;----------------------- 
;nustato, koks bus efektyvus adresas, bei registras
;naudoja bl registra
    mov ax, 0
    mov al, rm_nr
    cmp w, 1
    je zodziu
    add reg, offset reg1
    cmp mod, 0            ;w=0
    jne _0_1               ;mod=00
    mov rm, offset ad1
    mov rm[2], offset poz1 
    cmp rm_nr, 6 
    je tiesioginis1
    ret           
    tiesioginis1:
    mov mod, 80h
    call pos
    ret
_0_1: 
    cmp mod, 0C0h
    je _1_1_ 
    call pos
    mov rm, offset ad2        ; mod=01 arba 10
    mov rm[2], offset poz2
    ret
_1_1_:
    mov bl, 3
    mul bl 
    mov rm, ax
    add rm, offset reg1   ;mod=11    (mod=reg)
    ret    
zodziu:  
    add reg, offset reg2
    cmp mod, 0            ;w=1
    jne _0_1_             ; mod=0
    mov rm, offset ad1
    mov rm[2], offset poz1
    cmp rm_nr, 6 
    je tiesioginis2
    ret           
    tiesioginis2:
    mov mod, 80h
    call pos 
    ret
_0_1_: 
    cmp mod, 0C0h
    je _1_1__ 
    call pos
    mov rm, offset ad2          ;mod=01 arba 10
    mov rm[2], offset poz2 
    ret
_1_1__:
    mov bl, 3
    mul bl 
    mov rm, ax                    ;mod=11(mod=reg)
    add rm, offset reg2
    ret     
endp      
;spausdina istirtus baitus
;naudoja ax, cx, bx, dx registrus
isvesk_baita proc
    mov si, offset buf
    mov al, opk
    mov kiek, al 
spausdink:
    mov cx, 1
    mov al, [si] 
    mov ah, 0
    inc si
    mov bl, 16
    div bl 
    mov bx, fp[2]
    lea dx, skaiciai
    push ax
    mov ah, 0
    add dx, ax
    mov ah, 40h
    int 21h
    lea dx, skaiciai 
    pop ax
    mov al, ah
    mov ah, 0
    add dx, ax
    mov ah, 40h
    mov al, 0
    int 21h
    dec kiek
    cmp kiek, 0
    jne spausdink
    mov ch, 0
    mov cl, 16
    sub cl, opk
    sub cl, opk
    mov ah, 40h
    mov dx, offset tarpas
    int 21h 
    ret
endp
;isveda komandos pavadinima
;naudoja sx, cx, bx, dx
isvesk_kom_pav proc
    mov dx, viso[6]
    mov cx, 5
    mov ah, 40h
    int 21h
    mov cx, 3
    mov ah, 40h
    mov dx, offset tarpas
    int 21h
    ret
endp 
;
isvesk_rm proc 
    cmp mod, 0C0h
    je kaip_reg 
    mov dx, segpref 
    mov segpref[4], di
    mov di, segpref[2]
    call isvesk_poslinki 
    mov di, segpref[4]
    mov dx, rm 
    mov si, rm[2]
    mov ax, 0
    mov al, rm_nr
    add si, ax  
    inc si
    mov cl, [si]
    dec si
    mov al, [si]
    add dx, ax
    sub cl, [si]  
    mov ah, 40h
    mov bx, fp[2]
    int 21h
    mov dx, offset poslinkis
    call isvesk_poslinki
    ret 
    kaip_reg:
    mov dx, rm
    mov cx, 2
    mov bx, fp[2]
    mov ah, 40h
    int 21h
    ret
endp
isvesk_reg proc 
    mov dx, reg
    mov cx, 2
    mov bx, fp[2]
    mov ah, 40h
    int 21h
    ret
endp
isvesk_poslinki proc
    mov cx, di
    mov bx, fp[2]
    mov ah, 40h
    int 21h
    ret
endp
;suranda jump zyme
zyme proc   
    mov di, 0
sok:          
    mov al, baitu_nr[di]  
    mov poslinkis[di], al
    inc di
    cmp di, 4
    jne sok
    inc si
    mov al, [si]  
    cmp al, 80h
    jb maziau_uz
    dec poslinkis[1]
maziau_uz:
    mov bx, 0016
    div bl
    add poslinkis[2], al
    add poslinkis[3], ah 
    add poslinkis[3], 2
    dec di
dar_ne:
    cmp poslinkis[di], 16
    jl n_o
    sub poslinkis[di], 16
    dec di
    add poslinkis[di], 1
    inc di
n_o:      
    dec di
    cmp di, 0
    jne dar_ne
verciam:
    cmp poslinkis[di], 10
    jge raide
    add poslinkis[di], 30h
    jmp ne_raide
raide:
    add poslinkis[di], 37h
ne_raide:
    inc di
    cmp di, 4
    jne verciam
    ret
endp
        
;isveda baito numeri
;naudoja cx, di, ax
baito_nr proc   
    mov al, opk
    add baitu_nr[3], al
    cmp baitu_nr[3], 16
    jb ate
    sub baitu_nr[3], 16
    add baitu_nr[2], 1
    cmp baitu_nr[2], 16 
    jb ate
    sub baitu_nr[2], 16
    add baitu_nr[1], 1
    cmp baitu_nr[1], 16
    jb ate
    sub baitu_nr[1], 16
    add baitu_nr[0], 1  
ate:   
    mov bx, fp[2]
    mov cx, 1
    cmp di, 3
    jg baigiau
    mov dx, offset skaiciai 
    add dl, baitu_nr[di] 
    mov ah, 40h
    int 21h 
    inc di
    jmp ate
baigiau:
    mov ah, 40h
    mov cx, 3
    mov dx, offset baitu_nr[4]
    int 21h 
    mov di, 0
    ret
endp  
; suskaiciuoja poslinki
;naudoja ax, bx, cx, di
; di saugoma kiek simboliu reiks spausdinti isvedant poslinki
pos proc 
    mov di, 0  
    mov dx, 0
    cmp mod, 80h
    je _2_baitu_ 
    inc opk  
    mov dx, 1
    jmp _pos_
_2_baitu_:  
    add opk, 2 
    mov dx, 2
_pos_: 
    lea si, buf
    dec opk 
    mov ch, 0
    mov cl, opk
    add si, cx
    inc opk
l:
    mov al, [si]
    mov ah, 0
    mov bl, 10h
    div bl 
    mov bl, 1 
    mov poslinkis[di], al
    mov poslinkis[di+1], ah 
dar_kart_:
    cmp poslinkis[di], 9
    jg virs
    add poslinkis[di], 30h
    jmp maziau
virs:
    add poslinkis[di], 37h
maziau:    
    dec bl 
    inc di
    cmp bl, 0
    jge dar_kart_ 
    dec dx
    cmp dx, 0
    je galas_
    dec si
    jmp l
galas_: 
    mov poslinkis[di], ']'
    inc di
    mov poslinkis[di], ' ' 
    ret
endp 
;------------------------ 
failai proc 
    mov bx, 0081h
    mov si, 0
    mov al, es:[0081h]
    cmp al, 0dh 
    je klaida_matyt
    mov ax, word ptr es:[0082h]
    xchg al, ah
    cmp ax, '/?'
    jne tarpas1 
klaida_matyt:
        mov cx, 3 
    call klaida
tarpas1:     
    mov al, es:[bx]
    cmp al, ' '
    jne pirm
    inc bx
    jmp tarpas1
pirm:
    mov al, es:[bx]
    cmp al, ' '
    je tarpas2
    cmp al, 0dh 
    jne ne_enter
    mov cx, 3
    call klaida
ne_enter:
    mov rez[si], al
    inc si
    inc bx
    jmp pirm
tarpas2:
    mov al, es:[bx]
    cmp al, ' '
    jne ant1
    inc bx
    jmp tarpas2
ant1:
    mov si, 0
ant:
    mov al, es:[bx]
    cmp al, 0dh
    je done
    mov sk[si], al
    inc si
    inc bx
    jmp ant
done:
    ret
 endp 
;-----------------------
atidaryk proc
    mov al, 0
    mov ah,3dh
    lea dx, sk 
    int 21h
    jnc at_rez
    mov cx, 1 
    call klaida 
at_rez:     
    mov fp[0], ax  
    mov cx, 0
    mov al, 0
    mov ah, 3ch
    mov dx, offset rez
    int 21h  
    jnc viskas_tvarkoj
    mov cx, 2
    call klaida
viskas_tvarkoj:
mov fp[2], ax 
    ret
endp   
;----------------------------
;skaitoma po 7 baitus
;naudoja ax, cx, dx 
skaityk proc
    mov ah, 0
    mov al, opk
    add viso[0], ax
    mov dx, viso[0]
    mov cx, 0
    mov ah, 42h
    mov al, 0
    mov bx, fp[0] 
    int 21h
    mov ah, 3fh
    mov cx, 7
    lea dx, buf
    int 21h        ;skaitymas po 7 baitus
    ret
endp
klaida proc
    cmp cx, 1
    jne gal_atidarymo
    lea dx, klaida_su  
    jmp isvesk_klaida
gal_atidarymo:
    cmp cx, 2
    jne pasirodo_ne
    lea dx, klaida_atidarymo
    jmp isvesk_klaida
pasirodo_ne:
    lea dx, fail_ 
isvesk_klaida:
    mov ah, 9h
    int 21h 
    call pabaiga
endp    
pabaiga proc
    mov bx, fp[0]
    mov ah, 3eh
    int 21h
    mov bx, fp[2]
    mov ah, 3Eh
    int 21h 
    mov ah, 4ch
    int 21h
endp   
isvesk_kableli proc
    mov bx, fp[2]
    mov ah, 40h
    mov cx, 2
    mov dx, offset kablelis
    int 21h
    ret
endp  
isvesk_simboli proc
    mov bx, fp[2]
    mov ah, 40h
    mov cx, 1
    int 21h
    ret
endp
end strt 