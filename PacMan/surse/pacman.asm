.386
.model flat, stdcall
;-------------------------------------------------------------------------------------------------------------------------------------------------

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc

;declaram simbolul start ca public - de acolo incepe executia
public start

;-------------------------------------------------------------------------------------------------------------------------------------------------
.data
include digits.inc
include pacman.inc
include letters.inc
include map.inc

;aici declaram date
window_title DB "PACMAN", 0
area_width EQU 1500
area_height EQU 800

playble_width EQU 1096

area DD 0

play DD 0
nr_puncte DD 0
scor DD 0
lives DD 3
game_over DD 0
the_end DD 0
ok DD 1
reset DD 0
start_btn DD 0
super_power DD 0

counter DD 0
counter5 DD 26
counter_sp DD 31

player_Xindex DD 11
player_Yindex DD 12
playerX DD 40+48*11
playerY DD 40+48*12
directie DD 0, 0, 0, 0

startX DD 40+48*11
startY DD 40+48*12
start_Xindex DD 11
start_Yindex DD 12

dir_fantome DD 4, 2, 1, 3
pozX_fantome DD 40+11*48, 40+10*48, 40+11*48, 40+12*48
pozY_fantome DD 40+6*48, 40+7*48, 40+8*48, 40+7*48
Xindex_fantome DD 11, 10, 11, 12
Yindex_fantome DD 6, 7, 8, 7

start_dir DD 4, 2, 1, 3
startX_fantome DD 40+11*48, 40+10*48, 40+11*48, 40+12*48
startY_fantome DD 40+6*48, 40+7*48, 40+8*48, 40+7*48
startX_index DD 11, 10, 11, 12
startY_index DD 6, 7, 8, 7

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

mapX DD 40
mapY DD 40
map_width EQU 23
map_height EQU 15 

image_width EQU 48
image_height EQU 48

button_x EQU 190+23*48
button_y EQU 20+4*48
button_size_x EQU 70
button_size_y EQU 40

;----------------------------------------------------------------------------------------------------------------------------MAKE_TEXT
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0000000h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

;--------------------------------------------------------MAKE_TEXT_MACRO

make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

;-------------------------------------------------------------------------------------------------------------------------------MAKE_IMAGE
make_image proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp + arg1]
	lea esi, pacman
	sub eax, 'A'
	
	mov ebx, image_width
	mul ebx
	mov ebx, image_height
	mul ebx
	shl eax, 2
	
	add esi, eax
	mov ecx, image_height
	
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, image_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	
	push ecx
	mov ecx, image_width
	
bucla_simbol_coloane:
	mov ebx, [esi]
	cmp dword ptr [esi], 0ffffffh
	je simbol_pixel_negru
	mov dword ptr [edi], ebx
	jmp simbol_pixel_next
	
simbol_pixel_negru:
	mov dword ptr [edi], 0000000h
simbol_pixel_next:
	add esi, 4
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	
	popa
	mov esp, ebp
	pop ebp
	ret
make_image endp

;--------------------------------------------------------MAKE_IMAGE_MACRO

draw_pacman_image macro simbol, drawArea, x, y
	push y
	push x
	push drawArea
	push simbol
	call make_image
	add esp, 16
endm

;----------------------------------------------------------------------------------------------------------------------------MAKE_MAP

make_map proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, 0
	lea esi, map
	
	mov ebx, map_width
	mul ebx
	mov ebx, map_height
	mul ebx
	add esi, eax
	
	mov ecx, map_height
	
	jmp bucla_simb_linii
	
;----------------------------------------------------DRAW_MAPA
draw_vid:
	draw_pacman_image 'A', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_perete:
	draw_pacman_image 'F', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_punct:
	draw_pacman_image 'G', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_poarta_sus:
	draw_pacman_image 'L', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_poarta_dreapta:
	draw_pacman_image 'M', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_poarta_jos:
	draw_pacman_image 'N', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_poarta_stanga:
	draw_pacman_image 'O', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_coroana:
	draw_pacman_image 'P', area, mapX, mapY
	jmp simbol_pixel_next
	
draw_spatiu:
	draw_pacman_image 'A', area, mapX, mapY
	jmp simbol_pixel_next
	
;------------------------------------------------------BUCLA	
bucla_simb_linii:	
	mov mapX, 40
	push ecx
	mov ecx, map_width
	
bucla_simb_coloane:
	cmp byte ptr [esi], 0
	je draw_spatiu
	
	cmp byte ptr [esi], 1
	je draw_perete
	
	cmp byte ptr [esi], 2
	je draw_punct
	
	cmp byte ptr [esi], 3
	je draw_poarta_sus
	
	cmp byte ptr [esi], 4
	je draw_poarta_dreapta
	
	cmp byte ptr [esi], 5
	je draw_poarta_jos
	
	cmp byte ptr [esi], 6
	je draw_poarta_stanga
	
	cmp byte ptr [esi], 7
	je draw_spatiu
	
	cmp byte ptr [esi], 8
	je draw_coroana
	
	cmp byte ptr [esi], 9
	je draw_vid
	
simbol_pixel_next:
	inc esi
	mov ebx, 48
	add mapX, ebx
	loop bucla_simb_coloane
	mov ebx, 48
	add mapY, ebx
	pop ecx
	loop bucla_simb_linii
	mov mapY, 40
	
;--------------------------------------------------FINAL_MAKE_MAP
final:
	popa
	mov esp, ebp
	pop ebp
	ret
make_map endp

;--------------------------------------------------MAKE_MAP_MACRO

make_map_macro macro
	call make_map
endm

;------------------------------------------------------------------------------------------------------------------------LINE_HORIZONTAL

line_horizontal macro x, y, len, color
local bucla_linie
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
	
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_linie;
endm

;--------------------------------------------------------------------------------------------------------------------------LINE_VERTICAL

line_vertical macro x, y, len, color
local bucla_linie
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
	
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4*area_width
	loop bucla_linie;
endm

;--------------------------------------------------------------------------------------------------------------------------COMPARA

compara macro n, x1, y1, x2, y2
local x_egal, y_egal, over, comp, final
	
	mov eax, x1
	mov ebx, x2
	mov ecx, y1
	mov edx, y2

comp:
	cmp eax, ebx
	je x_egal
	jmp final

x_egal:
	cmp ecx, edx
	je y_egal
	jmp final
	
y_egal:
	cmp super_power, 1
	jne over
	mov counter5, 0
	add scor, 100
	mov ebx, startX_fantome[n]
	mov pozX_fantome[n], ebx
	mov ebx, startY_fantome[n]
	mov pozY_fantome[n], ebx
	mov ebx, startX_index[n]
	mov Xindex_fantome[n], ebx
	mov ebx, startY_index[n]
	mov Yindex_fantome[n], ebx
	jmp final
	
over:
	cmp ok, 1
	jne final
	
	mov game_over, 1
	mov play, 0
	mov ok, 0
	dec lives
	
final:	
endm

;-------------------------------------------------------------------------------------------------------------------GENERATE_DIRECTION
generate_direction macro n, err
local final, incearca_stanga, incearca_stanga_jos, incearca_stanga_sus
local incearca_dreapta, incearca_dreapta_sus, incearca_dreapta_jos
local solve_stanga, solve_jos, solve_dreapta, solve_sus, find_next
local nu_stanga, nu_jos, nu_dreapta, nu_sus

	lea esi, map
	mov eax, Yindex_fantome[n]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[n]
	add esi, eax
	
	mov eax, Xindex_fantome[n]
	sub eax, player_Xindex
	add eax, err
	
	mov ebx, Yindex_fantome[n]
	sub ebx, player_Yindex
	sub ebx, err
	
	cmp eax, 0
	jle incearca_dreapta
	jmp incearca_stanga

nu_sus:
	cmp byte ptr [esi+23], 1
	jne solve_jos
	cmp byte ptr [esi+1], 1
	jne solve_dreapta
	cmp byte ptr [esi-1], 1
	jne solve_stanga
	jmp final
	
nu_dreapta:
	cmp byte ptr [esi-23], 1
	jne solve_sus
	cmp byte ptr [esi+23], 1
	jne solve_jos
	cmp byte ptr [esi-1], 1
	jne solve_stanga
	mov dir_fantome[n], 2
	jmp final
	
nu_jos:
	cmp byte ptr [esi-23], 1
	jne solve_sus
	cmp byte ptr [esi+1], 1
	jne solve_dreapta
	cmp byte ptr [esi-1], 1
	jne solve_stanga
	jmp final	
	
nu_stanga:
	cmp byte ptr [esi-23], 1
	jne solve_sus
	cmp byte ptr [esi+1], 1
	jne solve_dreapta
	cmp byte ptr [esi+23], 1
	jne solve_jos
	mov dir_fantome[n], 4
	jmp final
	
find_next:
	cmp dir_fantome[n], 1
	je nu_jos
	cmp dir_fantome[n], 2
	je nu_stanga
	cmp dir_fantome[n], 3
	je nu_sus
	cmp dir_fantome[n], 4
	je nu_dreapta
	
	jmp final
	
solve_sus:
	cmp byte ptr [esi-23], 1
	je find_next
	mov dir_fantome[n], 1
	jmp final
	
solve_dreapta:
	cmp byte ptr [esi+1], 1
	je find_next
	mov dir_fantome[n], 2
	jmp final
	
solve_jos:
	cmp byte ptr [esi+23], 1
	je find_next
	mov dir_fantome[n], 3
	jmp final
	
solve_stanga:
	cmp byte ptr [esi-1], 1
	je find_next
	mov dir_fantome[n], 4
	jmp final
	
;---------------------------JUMATATEA DREAPTA	
incearca_dreapta_jos:
	mov ecx, eax
	sub ecx, ebx
	cmp ecx, 0
	jg solve_jos
	jmp solve_dreapta
	
incearca_dreapta_sus:
	mov ecx, eax
	sub ecx, ebx
	cmp ecx, 0
	jl solve_sus
	jmp solve_dreapta
	
incearca_dreapta:
	cmp ebx, 0
	jle incearca_dreapta_jos
	jmp incearca_dreapta_sus
	
;----------------------------JUMATATEA STANGA
incearca_stanga_sus:
	mov ecx, eax
	sub ecx, ebx
	cmp ecx, 0
	cmp eax, ebx
	jg solve_stanga
	jmp solve_sus

incearca_stanga_jos:
	mov ecx, eax
	sub ecx, ebx
	cmp ecx, 0
	jl solve_jos
	jmp solve_stanga
	
incearca_stanga:
	cmp ebx, 0
	jge incearca_stanga_sus
	jmp incearca_stanga_jos

final:
endm

;------------------------------------------------------------------------------------------------------------------------DRAW_FUNCTION
; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
;--------------------------------------STA_PE_LOC
	cmp play, 1
	je mai_departe
	
stop_pacman:
	mov directie[0], 0
	mov directie[1], 0
	mov directie[2], 0
	mov directie[3], 0
	
	mov dir_fantome[0], 0
	mov dir_fantome[1*4], 0
	mov dir_fantome[2*4], 0
	mov dir_fantome[3*4], 0
;---------------------------------------------

mai_departe:
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	
	;mai jos e codul care intializeaza fereastra cu pixeli negri
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	
	;backgorund negru
	push eax
	push 0
	push area
	call memset
	add esp, 12
	jmp always_loop
;------------------------------------------------------------------------------------------------------------EVT_CLICK
evt_click:	
	
	mov eax, [ebp+arg2]
	cmp eax, button_x
	jl always_loop
	cmp eax, button_x + button_size_x
	jg always_loop
	
	mov eax, [ebp+arg3]
	cmp eax, button_y
	jl always_loop
	cmp eax, button_y + button_size_y
	jg always_loop
	
	mov start_btn, 1

	;--------------------------------------------------------------------RESET
	mov play, 1
	mov ok, 1
	mov game_over, 0
	mov counter5, 0
	
	mov eax, startX
	mov playerX, eax
	mov eax, startY
	mov playerY, eax
	mov eax, start_Xindex
	mov player_Xindex, eax
	mov eax, start_Yindex
	mov player_Yindex, eax
	
	mov directie[0], 0
	mov directie[1], 0
	mov directie[2], 0
	mov directie[3], 0
	
	mov eax, startX_fantome[0]
	mov pozX_fantome[0], eax
	mov eax, startX_fantome[1*4]
	mov pozX_fantome[1*4], eax
	mov eax, startX_fantome[2*4]
	mov pozX_fantome[2*4], eax
	mov eax, startX_fantome[3*4]
	mov pozX_fantome[3*4], eax
	
	mov eax, startY_fantome[0]
	mov pozY_fantome[0], eax
	mov eax, startY_fantome[1*4]
	mov pozY_fantome[1*4], eax
	mov eax, startY_fantome[2*4]
	mov pozY_fantome[2*4], eax
	mov eax, startY_fantome[3*4]
	mov pozY_fantome[3*4], eax
	
	mov eax, startX_index[0]
	mov Xindex_fantome[0], eax
	mov eax, startX_index[1*4]
	mov Xindex_fantome[1*4], eax
	mov eax, startX_index[2*4]
	mov Xindex_fantome[2*4], eax
	mov eax, startX_index[3*4]
	mov Xindex_fantome[3*4], eax
	
	mov eax, startY_index[0]
	mov Yindex_fantome[0], eax
	mov eax, startY_index[1*4]
	mov Yindex_fantome[1*4], eax
	mov eax, startY_index[2*4]
	mov Yindex_fantome[2*4], eax
	mov eax, startY_index[3*4]
	mov Yindex_fantome[3*4], eax
	
	mov eax, start_dir[0]
	mov dir_fantome[0], eax
	mov eax, start_dir[1*4]
	mov dir_fantome[1*4], eax
	mov eax, start_dir[2*4]
	mov dir_fantome[2*4], eax
	mov eax, start_dir[3*4]
	mov dir_fantome[3*4], eax

;--------------------------------------------------INITITIALIZARE_MATRICE	
	cmp reset, 1
	jne always_loop
	
	mov nr_puncte, 0
	mov the_end, 0
	mov reset, 0
	mov lives, 3
	mov play, 1
	mov scor, 0
	
	lea esi, map
	mov eax, 0
	mov ebx, map_width
	mul ebx
	mov ebx, map_height
	mul ebx
	add esi, eax
	
	mov ecx, map_height
	jmp b_linii
	
fa_punct:
	mov byte ptr [esi], 2
	draw_pacman_image 'G', area, mapX, mapY
	jmp pixel_next
	
fa_coroana:
	mov byte ptr [esi], 8
	draw_pacman_image 'P', area, mapX, mapY
	jmp pixel_next
	
b_linii:	
	mov mapX, 40
	push ecx
	mov ecx, map_width
	
b_coloane:
	cmp byte ptr [esi], 0
	je fa_punct
	cmp byte ptr [esi], 7
	je fa_coroana
	
pixel_next:
	inc esi
	mov ebx, 48
	add mapX, ebx
	loop b_coloane
	mov ebx, 48
	add mapY, ebx
	pop ecx
	loop b_linii
	mov mapY, 40
	
	jmp always_loop
	
;-------------------------------------------------------------------------------POZITI_FAIL
playerY_fail:
	mov ebx, playerY
	mov playerY, ebx
	jmp cmp_dir_fantome

playerX_fail:
	mov ebx, playerX
	mov playerX, ebx
	jmp cmp_dir_fantome	
	
playerX_to_0: ;trebuie sa sterg ultimu punct din dreapta
	lea esi, map
	mov eax, player_Yindex
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	add esi, eax
	
	mov byte ptr [esi], 0
	
	mov player_Xindex, 0
	mov ebx, 40
	mov playerX, ebx
	jmp cmp_dir_fantome	

playerX_to_max:
	lea esi, map
	mov eax, player_Yindex
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	add esi, eax
	
	mov byte ptr [esi], 0
	
	mov player_Xindex, 22
	mov ebx, playble_width
	mov playerX, ebx
	jmp cmp_dir_fantome	

;---------------------------------------------------PUNCTE
creste_puncte:
	lea esi, map
	mov eax, player_Yindex
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	add esi, eax
	
	inc nr_puncte
	inc scor
	mov byte ptr [esi], 0
	
	cmp directie[0], 1
	je dir_sus_final
	
	cmp directie[1], 1
	je dir_dreapta_final
	
	cmp directie[2], 1
	je dir_jos_final
	
	cmp directie[3], 1
	je dir_stanga_final
	
	jmp cmp_dir_fantome

;---------------------------------------------------COROANA
coroana:
	lea esi, map
	mov eax, player_Yindex
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	add esi, eax
	
	inc nr_puncte
	add scor, 20
	mov super_power, 1
	mov counter_sp, 0
	mov byte ptr [esi], 7
	
	cmp directie[0], 1
	je dir_sus_final
	
	cmp directie[1], 1
	je dir_dreapta_final
	
	cmp directie[2], 1
	je dir_jos_final
	
	cmp directie[3], 1
	je dir_stanga_final
	
	jmp cmp_dir_fantome
	
;-------------------------------------------------------------------------------------VERIFICARE_DIRECTII_PACMAN
dir_sus: ;-------------------------------------------SUS
	lea esi, map
	mov eax, player_Yindex
	dec eax
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	add esi, eax
	
	cmp byte ptr [esi], 1
	je playerY_fail
	
	cmp byte ptr [esi], 3
	je playerY_fail
	
	cmp byte ptr [esi], 4
	je playerY_fail
	
	cmp byte ptr [esi], 5
	je playerY_fail
	
	cmp byte ptr [esi], 6
	je playerY_fail
	
	add esi, map_width 
	cmp byte ptr [esi], 2
	je creste_puncte
	
dir_sus_final:
	cmp byte ptr [esi], 8
	je coroana
	
	dec player_Yindex
	mov ebx, 48
	sub playerY, ebx
	jmp cmp_dir_fantome

;---------------------------------------------------DREAPTA	
dir_dreapta:
	lea esi, map
	mov eax, player_Yindex
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	inc eax
	add esi, eax
	
	cmp player_Xindex, 22
	je playerX_to_0
	
	cmp byte ptr [esi], 1
	je playerX_fail
	
	cmp byte ptr [esi], 3
	je playerX_fail
	
	cmp byte ptr [esi], 4
	je playerX_fail
	
	cmp byte ptr [esi], 5
	je playerX_fail
	
	cmp byte ptr [esi], 6
	je playerX_fail
	
	dec esi
	cmp byte ptr [esi], 2
	je creste_puncte
	
dir_dreapta_final:
	cmp byte ptr [esi], 8
	je coroana
	
	inc player_Xindex	
	mov ebx, 48
	add playerX, ebx
	jmp cmp_dir_fantome

;-------------------------------------------------------JOS
dir_jos:
	lea esi, map
	mov eax, player_Yindex
	inc eax
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	add esi, eax
	
	cmp byte ptr [esi], 1
	je playerY_fail
	
	cmp byte ptr [esi], 3
	je playerY_fail
	
	cmp byte ptr [esi], 4
	je playerY_fail
	
	cmp byte ptr [esi], 5
	je playerY_fail
	
	cmp byte ptr [esi], 6
	je playerY_fail
	
	sub esi, map_width 
	cmp byte ptr [esi], 2
	je creste_puncte

dir_jos_final:
	cmp byte ptr [esi], 8
	je coroana

	inc player_Yindex
	mov ebx, 48
	add playerY, ebx
	jmp cmp_dir_fantome

;-----------------------------------------------------STANGA
dir_stanga:
	lea esi, map
	mov eax, player_Yindex
	mov ebx, map_width
	mul ebx
	add eax, player_Xindex
	dec eax
	add esi, eax
	
	cmp player_Xindex, 0
	jle playerX_to_max
	
	cmp byte ptr [esi], 1
	je playerX_fail
	
	cmp byte ptr [esi], 3
	je playerX_fail
	
	cmp byte ptr [esi], 4
	je playerX_fail
	
	cmp byte ptr [esi], 5
	je playerX_fail
	
	cmp byte ptr [esi], 6
	je playerX_fail
	
	inc esi 
	cmp byte ptr [esi], 2
	je creste_puncte
	
dir_stanga_final:
	cmp byte ptr [esi], 8
	je coroana
	
	dec player_Xindex
	mov ebx, 48
	sub playerX, ebx
	
	jmp cmp_dir_fantome

;-------------------------------------BACK_NORMAL
back_normal:
	mov super_power, 0
	jmp verif_dir

pauza:
	cmp super_power, 1
	je stop_fantome
	
	mov directie[0], 0
	mov directie[1*4], 0
	mov directie[2*4], 0
	mov directie[3*4], 0
	
stop_fantome:
	mov dir_fantome[0], 0
	mov dir_fantome[1*4], 0
	mov dir_fantome[2*4], 0
	mov dir_fantome[3*4], 0
	jmp verif_sp
	
;-----------------------------------------------------------------------------------------------------------------EVT_TIMER
evt_timer:
	inc counter
	inc counter5
	inc counter_sp
	
	cmp counter5, 5
	jle pauza
	mov start_btn, 0
	
verif_sp:
	cmp counter_sp, 25
	je back_normal
	
verif_dir:	
	cmp directie[0], 1
	je dir_sus
	
	cmp directie[1], 1
	je dir_dreapta
	
	cmp directie[2], 1
	je dir_jos
	
	cmp directie[3], 1
	je dir_stanga

;----------------------------------------CMP_DIR_FANTOME	
cmp_dir_fantome:
	
	;--------------------------
	mov edx, 0
	mov eax, counter
	mov ebx, 4
	div ebx
	;--------------------------
	
	dir_fantoma_0:
		cmp edx, 1
		jne dir_fantoma_1
	
		cmp dir_fantome[0], 1
		je fantoma0_sus
		cmp dir_fantome[0], 2
		je fantoma0_dreapta
		cmp dir_fantome[0], 3
		je fantoma0_jos
		cmp dir_fantome[0], 4
		je fantoma0_stanga

	;---------------------------
	dir_fantoma_1:
		cmp edx, 0
		jne dir_fantoma_2
	
		cmp dir_fantome[1*4], 1
		je fantoma1_sus
		cmp dir_fantome[1*4], 2
		je fantoma1_dreapta
		cmp dir_fantome[1*4], 3
		je fantoma1_jos
		cmp dir_fantome[1*4], 4
		je fantoma1_stanga
		
	;--------------------------
	dir_fantoma_2:
		cmp edx, 3
		jne dir_fantoma_3
	
		cmp dir_fantome[2*4], 1
		je fantoma2_sus
		cmp dir_fantome[2*4], 2
		je fantoma2_dreapta
		cmp dir_fantome[2*4], 3
		je fantoma2_jos
		cmp dir_fantome[2*4], 4
		je fantoma2_stanga
	
	;--------------------------
	dir_fantoma_3:
		cmp edx, 2
		jne always_loop
		
		cmp dir_fantome[3*4], 1
		je fantoma3_sus
		cmp dir_fantome[3*4], 2
		je fantoma3_dreapta
		cmp dir_fantome[3*4], 3
		je fantoma3_jos
		cmp dir_fantome[3*4], 4
		je fantoma3_stanga
	
	jmp always_loop
	
;--------------------------------------------------------------------------------------------------------VERIFICARE_DRIRECTII_FANTOME

;---------------------------------------------------------------------------------FANTOMA_0
;------------------------------------------FANTOMA_0_SUS
fantoma0_sus:
	lea esi, map
	mov eax, Yindex_fantome[0]
	dec eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[0]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma0_sus_final
	
	mov ebx, pozY_fantome[0]
	mov pozY_fantome[0], ebx
	jmp dir_fantoma_1
	;--------------------------
	
fantoma0_sus_final:
	dec Yindex_fantome[0]
	mov ebx, 48
	sub pozY_fantome[0], ebx
	jmp dir_fantoma_1

;-----------------------------------------FANTOMA_0_DREAPTA
fantoma0_dreapta:
	lea esi, map
	mov eax, Yindex_fantome[0]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[0]
	inc eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport0_x_0
	
	mov ebx, pozX_fantome[0]
	mov pozX_fantome[0], ebx
	jmp dir_fantoma_1	
	
	;---------------------------TELEPORT
teleport0_x_0:
	cmp Xindex_fantome[0], 22
	jne fantoma0_dreapta_final
	
	mov Xindex_fantome[0], 0
	mov ebx, 40
	mov pozX_fantome[0], ebx
	;----------------------------
	
fantoma0_dreapta_final:
	inc Xindex_fantome[0]	
	mov ebx, 48
	add pozX_fantome[0], ebx
	jmp dir_fantoma_1	

;------------------------------------------FANTOMA_0_JOS
fantoma0_jos:
	lea esi, map
	mov eax, Yindex_fantome[0]
	inc eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[0]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma0_jos_final
	
	mov ebx, pozY_fantome[0]
	mov pozY_fantome[0], ebx
	jmp dir_fantoma_1
	;--------------------------
	
fantoma0_jos_final:
	inc Yindex_fantome[0]
	mov ebx, 48
	add pozY_fantome[0], ebx
	jmp dir_fantoma_1
	
;--------------------------------------------FANTOMA_0_STANGA
fantoma0_stanga:
	lea esi, map
	mov eax, Yindex_fantome[0]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[0]
	dec eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport0_0_x
	
	mov ebx, pozX_fantome[0]
	mov pozX_fantome[0], ebx
	jmp dir_fantoma_1	
	
	;---------------------------TELEPORT
teleport0_0_x:
	cmp Xindex_fantome[0], 0
	jne fantoma0_stanga_final
	
	mov Xindex_fantome[0], 22
	mov ebx, playble_width
	mov pozX_fantome[0], ebx
	;----------------------------
	
fantoma0_stanga_final:
	dec Xindex_fantome[0]	
	mov ebx, 48
	sub pozX_fantome[0], ebx
	jmp dir_fantoma_1	
	
;---------------------------------------------------------------------------------FANTOMA_1
;------------------------------------------FANTOMA_1_SUS
fantoma1_sus:
	lea esi, map
	mov eax, Yindex_fantome[1*4]
	dec eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[1*4]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma1_sus_final
	
	mov ebx, pozY_fantome[1*4]
	mov pozY_fantome[1*4], ebx
	jmp dir_fantoma_2
	;--------------------------
	
fantoma1_sus_final:
	dec Yindex_fantome[1*4]
	mov ebx, 48
	sub pozY_fantome[1*4], ebx
	jmp dir_fantoma_2

;-----------------------------------------FANTOMA_1_DREAPTA
fantoma1_dreapta:
	lea esi, map
	mov eax, Yindex_fantome[1*4]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[1*4]
	inc eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport1_x_0
	
	mov ebx, pozX_fantome[1*4]
	mov pozX_fantome[1*4], ebx
	jmp dir_fantoma_2	
	
	;---------------------------TELEPORT
teleport1_x_0:
	cmp Xindex_fantome[1*4], 22
	jne fantoma1_dreapta_final
	
	mov Xindex_fantome[1*4], 0
	mov ebx, 40
	mov pozX_fantome[1*4], ebx
	;----------------------------
	
fantoma1_dreapta_final:
	inc Xindex_fantome[1*4]	
	mov ebx, 48
	add pozX_fantome[1*4], ebx
	jmp dir_fantoma_2	

;------------------------------------------FANTOMA_1_JOS
fantoma1_jos:
	lea esi, map
	mov eax, Yindex_fantome[1*4]
	inc eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[1*4]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma1_jos_final
	
	mov ebx, pozY_fantome[1*4]
	mov pozY_fantome[1*4], ebx
	jmp dir_fantoma_2
	;--------------------------
	
fantoma1_jos_final:
	inc Yindex_fantome[1*4]
	mov ebx, 48
	add pozY_fantome[1*4], ebx
	jmp dir_fantoma_2
	
;--------------------------------------------FANTOMA_1_STANGA
fantoma1_stanga:
	lea esi, map
	mov eax, Yindex_fantome[1*4]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[1*4]
	dec eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport1_0_x
	
	mov ebx, pozX_fantome[1*4]
	mov pozX_fantome[1*4], ebx
	jmp dir_fantoma_2	
	
	;---------------------------TELEPORT
teleport1_0_x:
	cmp Xindex_fantome[1*4], 0
	jne fantoma1_stanga_final
	
	mov Xindex_fantome[1*4], 22
	mov ebx, playble_width
	mov pozX_fantome[1*4], ebx
	;----------------------------
	
fantoma1_stanga_final:
	dec Xindex_fantome[1*4]	
	mov ebx, 48
	sub pozX_fantome[1*4], ebx
	jmp dir_fantoma_2	
	
;---------------------------------------------------------------------------------FANTOMA_2
;------------------------------------------FANTOMA_2_SUS
fantoma2_sus:
	lea esi, map
	mov eax, Yindex_fantome[2*4]
	dec eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[2*4]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma2_sus_final
	
	mov ebx, pozY_fantome[2*4]
	mov pozY_fantome[2*4], ebx
	jmp dir_fantoma_3
	;--------------------------
	
fantoma2_sus_final:
	dec Yindex_fantome[2*4]
	mov ebx, 48
	sub pozY_fantome[2*4], ebx
	jmp dir_fantoma_3

;-----------------------------------------FANTOMA_2_DREAPTA
fantoma2_dreapta:
	lea esi, map
	mov eax, Yindex_fantome[2*4]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[2*4]
	inc eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport2_x_0
	
	mov ebx, pozX_fantome[2*4]
	mov pozX_fantome[2*4], ebx
	jmp dir_fantoma_3	
	
	;---------------------------TELEPORT
teleport2_x_0:
	cmp Xindex_fantome[2*4], 22
	jne fantoma2_dreapta_final
	
	mov Xindex_fantome[2*4], 0
	mov ebx, 40
	mov pozX_fantome[2*4], ebx
	;----------------------------
	
fantoma2_dreapta_final:
	inc Xindex_fantome[2*4]	
	mov ebx, 48
	add pozX_fantome[2*4], ebx
	jmp dir_fantoma_3	

;------------------------------------------FANTOMA_2_JOS
fantoma2_jos:
	lea esi, map
	mov eax, Yindex_fantome[2*4]
	inc eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[2*4]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma2_jos_final
	
	mov ebx, pozY_fantome[2*4]
	mov pozY_fantome[2*4], ebx
	jmp dir_fantoma_3
	;--------------------------
	
fantoma2_jos_final:
	inc Yindex_fantome[2*4]
	mov ebx, 48
	add pozY_fantome[2*4], ebx
	jmp dir_fantoma_3
	
;--------------------------------------------FANTOMA_2_STANGA
fantoma2_stanga:
	lea esi, map
	mov eax, Yindex_fantome[2*4]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[2*4]
	dec eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport2_0_x
	
	mov ebx, pozX_fantome[2*4]
	mov pozX_fantome[2*4], ebx
	jmp dir_fantoma_3	
	
	;---------------------------TELEPORT
teleport2_0_x:
	cmp Xindex_fantome[2*4], 0
	jne fantoma2_stanga_final
	
	mov Xindex_fantome[2*4], 22
	mov ebx, playble_width
	mov pozX_fantome[2*4], ebx
	;----------------------------
	
fantoma2_stanga_final:
	dec Xindex_fantome[2*4]	
	mov ebx, 48
	sub pozX_fantome[2*4], ebx
	jmp dir_fantoma_3	
	
	;---------------------------------------------------------------------------------FANTOMA_3
;------------------------------------------FANTOMA_3_SUS
fantoma3_sus:
	lea esi, map
	mov eax, Yindex_fantome[3*4]
	dec eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[3*4]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma3_sus_final
	
	mov ebx, pozY_fantome[3*4]
	mov pozY_fantome[3*4], ebx
	jmp always_loop
	;--------------------------
	
fantoma3_sus_final:
	dec Yindex_fantome[3*4]
	mov ebx, 48
	sub pozY_fantome[3*4], ebx
	jmp always_loop

;-----------------------------------------FANTOMA_3_DREAPTA
fantoma3_dreapta:
	lea esi, map
	mov eax, Yindex_fantome[3*4]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[3*4]
	inc eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport3_x_0
	
	mov ebx, pozX_fantome[3*4]
	mov pozX_fantome[3*4], ebx
	jmp always_loop	
	
	;---------------------------TELEPORT
teleport3_x_0:
	cmp Xindex_fantome[3*4], 22
	jne fantoma3_dreapta_final
	
	mov Xindex_fantome[3*4], 0
	mov ebx, 40
	mov pozX_fantome[3*4], ebx
	;----------------------------
	
fantoma3_dreapta_final:
	inc Xindex_fantome[3*4]	
	mov ebx, 48
	add pozX_fantome[3*4], ebx
	jmp always_loop	

;------------------------------------------FANTOMA_3_JOS
fantoma3_jos:
	lea esi, map
	mov eax, Yindex_fantome[3*4]
	inc eax
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[3*4]
	add esi, eax
	
	;-----------------------FAIL
	cmp byte ptr [esi], 1
	jne fantoma3_jos_final
	
	mov ebx, pozY_fantome[3*4]
	mov pozY_fantome[3*4], ebx
	jmp always_loop
	;--------------------------
	
fantoma3_jos_final:
	inc Yindex_fantome[3*4]
	mov ebx, 48
	add pozY_fantome[3*4], ebx
	jmp always_loop
	
;--------------------------------------------FANTOMA_3_STANGA
fantoma3_stanga:
	lea esi, map
	mov eax, Yindex_fantome[3*4]
	mov ebx, map_width
	mul ebx
	add eax, Xindex_fantome[3*4]
	dec eax
	add esi, eax
	
	;---------------------------FAIL
	cmp byte ptr [esi], 1
	jne teleport3_0_x
	
	mov ebx, pozX_fantome[3*4]
	mov pozX_fantome[3*4], ebx
	jmp always_loop	
	
	;---------------------------TELEPORT
teleport3_0_x:
	cmp Xindex_fantome[3*4], 0
	jne fantoma3_stanga_final
	
	mov Xindex_fantome[3*4], 22
	mov ebx, playble_width
	mov pozX_fantome[3*4], ebx
	;----------------------------
	
fantoma3_stanga_final:
	dec Xindex_fantome[3*4]	
	mov ebx, 48
	sub pozX_fantome[3*4], ebx
	jmp always_loop	
	
;-------------------------------------------------------------------------------------------------ALWAYS_LOOP
always_loop:
	;afisam valoarea scor-ului(sute, zeci si unitati)
	mov ebx, 10
	mov eax, scor
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 230+23*48, 65+7*48
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 220+23*48, 65+7*48
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 210+23*48, 65+7*48
	
	;----------------------------------------------------------------------PAC-MAN
	;---chenar
	line_horizontal 50+23*48, 43, 335, 0ffffffh
	line_vertical 50+23*48, 43, 234, 0ffffffh
	line_vertical 385+23*48, 43, 235, 0ffffffh
	line_horizontal 50+23*48, 37+5*48, 335, 0ffffffh
	
	make_text_macro 'P', area, 190+23*48, 30+1*48
	make_text_macro 'A', area, 200+23*48, 30+1*48
	make_text_macro 'C', area, 210+23*48, 30+1*48
	line_horizontal 220+23*48, 40+1*48, 10, 0ffffffh
	make_text_macro 'M', area, 230+23*48, 30+1*48
	make_text_macro 'A', area, 240+23*48, 30+1*48
	make_text_macro 'N', area, 250+23*48, 30+1*48
	
	;---buton-start
	line_horizontal 190+23*48, 20+4*48, 70, 0ffffffh
	line_vertical 190+23*48, 20+4*48, 40, 0ffffffh
	line_vertical 260+23*48, 20+4*48, 40, 0ffffffh
	line_horizontal 190+23*48, 60+4*48, 70, 0ffffffh
	
	make_text_macro 'S', area, 200+23*48, 30+4*48
	make_text_macro 'T', area, 210+23*48, 30+4*48
	make_text_macro 'A', area, 220+23*48, 30+4*48
	make_text_macro 'R', area, 230+23*48, 30+4*48
	make_text_macro 'T', area, 240+23*48, 30+4*48
	
	;----------------------------------------------------------GAME_OVER
	
	cmp game_over, 1
	jne ready_go
	
	line_horizontal 50+23*48, 30+2*48, 335, 0ffffffh
	make_text_macro 'G', area, 180+23*48, 50+2*48
	make_text_macro 'A', area, 190+23*48, 50+2*48
	make_text_macro 'M', area, 200+23*48, 50+2*48
	make_text_macro 'E', area, 210+23*48, 50+2*48
	make_text_macro ' ', area, 220+23*48, 50+2*48
	make_text_macro 'O', area, 230+23*48, 50+2*48
	make_text_macro 'V', area, 240+23*48, 50+2*48
	make_text_macro 'E', area, 250+23*48, 50+2*48
	make_text_macro 'R', area, 260+23*48, 50+2*48
	line_horizontal 50+23*48, 40+3*48, 335, 0ffffffh
	
	;--------------------------------------------------------READY_GO
ready_go:
	cmp start_btn, 1
	jne you_win
	
	make_text_macro ' ', area, 180+23*48, 50+2*48
	make_text_macro ' ', area, 190+23*48, 50+2*48
	make_text_macro ' ', area, 200+23*48, 50+2*48
	make_text_macro ' ', area, 210+23*48, 50+2*48
	make_text_macro ' ', area, 220+23*48, 50+2*48
	make_text_macro ' ', area, 230+23*48, 50+2*48
	make_text_macro ' ', area, 240+23*48, 50+2*48
	make_text_macro ' ', area, 250+23*48, 50+2*48
	make_text_macro ' ', area, 260+23*48, 50+2*48
	
	line_horizontal 50+23*48, 30+2*48, 335, 0ffffffh
	make_text_macro 'R', area, 180+23*48, 50+2*48
	make_text_macro 'E', area, 190+23*48, 50+2*48
	make_text_macro 'A', area, 200+23*48, 50+2*48
	make_text_macro 'D', area, 210+23*48, 50+2*48
	make_text_macro 'Y', area, 220+23*48, 50+2*48
	line_horizontal 230+23*48, 60+2*48, 10, 0ffffffh
	make_text_macro 'G', area, 240+23*48, 50+2*48
	make_text_macro 'O', area, 250+23*48, 50+2*48
	line_horizontal 50+23*48, 40+3*48, 335, 0ffffffh
	
	;---------------------------------------------------------YOU_WIN
you_win:
	
	cmp nr_puncte, 155
	jne sfarsit
	
	mov play, 0
	mov reset, 1
	
	make_text_macro ' ', area, 180+23*48, 50+2*48
	make_text_macro ' ', area, 190+23*48, 50+2*48
	make_text_macro ' ', area, 200+23*48, 50+2*48
	make_text_macro ' ', area, 210+23*48, 50+2*48
	make_text_macro ' ', area, 220+23*48, 50+2*48
	make_text_macro ' ', area, 230+23*48, 50+2*48
	make_text_macro ' ', area, 240+23*48, 50+2*48
	make_text_macro ' ', area, 250+23*48, 50+2*48
	make_text_macro ' ', area, 260+23*48, 50+2*48
	
	line_horizontal 50+23*48, 30+2*48, 335, 0ffffffh
	make_text_macro ' ', area, 180+23*48, 50+2*48
	make_text_macro 'Y', area, 190+23*48, 50+2*48
	make_text_macro 'O', area, 200+23*48, 50+2*48
	make_text_macro 'U', area, 210+23*48, 50+2*48
	make_text_macro ' ', area, 220+23*48, 50+2*48
	make_text_macro 'W', area, 230+23*48, 50+2*48
	make_text_macro 'I', area, 240+23*48, 50+2*48
	make_text_macro 'N', area, 250+23*48, 50+2*48
	make_text_macro ' ', area, 260+23*48, 50+2*48
	line_horizontal 50+23*48, 40+3*48, 335, 0ffffffh
	
	;----------------------------------------------------------THE_END
sfarsit:
	
	cmp the_end, 1
	jne resume_score
	
	line_horizontal 50+23*48, 30+2*48, 335, 0ffffffh
	make_text_macro ' ', area, 180+23*48, 50+2*48
	make_text_macro 'T', area, 190+23*48, 50+2*48
	make_text_macro 'H', area, 200+23*48, 50+2*48
	make_text_macro 'E', area, 210+23*48, 50+2*48
	line_horizontal 220+23*48, 60+2*48, 10, 0ffffffh
	make_text_macro 'E', area, 230+23*48, 50+2*48
	make_text_macro 'N', area, 240+23*48, 50+2*48
	make_text_macro 'D', area, 250+23*48, 50+2*48
	make_text_macro ' ', area, 260+23*48, 50+2*48
	line_horizontal 50+23*48, 40+3*48, 335, 0ffffffh
	
	;----------------------------------------------------------SCORE
resume_score:

	line_horizontal 50+23*48, 43+6*48, 335, 0ffffffh
	line_vertical 50+23*48, 43+6*48, 138, 0ffffffh
	line_vertical 385+23*48, 43+6*48, 139, 0ffffffh
	line_horizontal 50+23*48, 37+9*48, 335, 0ffffffh
	
	make_text_macro 'S', area, 200+23*48, 40+7*48
	make_text_macro 'C', area, 210+23*48, 40+7*48
	make_text_macro 'O', area, 220+23*48, 40+7*48
	make_text_macro 'R', area, 230+23*48, 40+7*48
	make_text_macro 'E', area, 240+23*48, 40+7*48
	
	;----------------------------------------------------------LIVES
	line_horizontal 50+23*48, 43+10*48, 335, 0ffffffh
	line_vertical 50+23*48, 43+10*48, 234, 0ffffffh
	line_vertical 385+23*48, 43+10*48, 235, 0ffffffh
	line_horizontal 50+23*48, 37+15*48, 335, 0ffffffh
	
	make_text_macro 'L', area, 200+23*48, 60+10*48
	make_text_macro 'I', area, 210+23*48, 60+10*48
	make_text_macro 'V', area, 220+23*48, 60+10*48
	make_text_macro 'E', area, 230+23*48, 60+10*48
	make_text_macro 'S', area, 240+23*48, 60+10*48

	
	cmp lives, 3
	jne aici2
	
	draw_pacman_image 'C', area, 200+23*48, 50+11*48
	draw_pacman_image 'C', area, 200+23*48, 60+12*48
	draw_pacman_image 'C', area, 200+23*48, 70+13*48

aici2:
	cmp lives, 2
	jne aici1
	
	draw_pacman_image 'C', area, 200+23*48, 50+11*48
	draw_pacman_image 'C', area, 200+23*48, 60+12*48
	draw_pacman_image 'A', area, 200+23*48, 70+13*48
	
aici1:
	cmp lives, 1
	jne aici0
	
	draw_pacman_image 'C', area, 200+23*48, 50+11*48
	draw_pacman_image 'A', area, 200+23*48, 60+12*48
	draw_pacman_image 'A', area, 200+23*48, 70+13*48

aici0:
	cmp lives, 0
	jne resume_loop
	
	mov the_end, 1
	mov reset, 1
	draw_pacman_image 'A', area, 200+23*48, 50+11*48
	draw_pacman_image 'R', area, 200+23*48, 60+12*48
	draw_pacman_image 'A', area, 200+23*48, 70+13*48
	
;----------------------------------------------------------------------------------LOOP
resume_loop:	
	make_map_macro ;------- actualizez constant harta
	
	generate_direction 0, -1;---- macro care genereaza directii
	generate_direction 1*4, 4;---- macro care genereaza directii
	generate_direction 2*4, 2;---- macro care genereaza directii
	generate_direction 3*4, -3;---- macro care genereaza directii
	
	;-----------------------------------------------------------------------COMPARA
	
	compara 0, playerX, playerY, pozX_fantome[0], pozY_fantome[0]
	compara 1*4, playerX, playerY, pozX_fantome[1*4], pozY_fantome[1*4]
	compara 2*4, playerX, playerY, pozX_fantome[2*4], pozY_fantome[2*4]
	compara 3*4, playerX, playerY, pozX_fantome[3*4], pozY_fantome[3*4]
	
;------------------------------------------------------------------SELECTARE_IMAGINI_PACMAN

selectare_imagini_pacman:
	cmp directie[0], 1
	je image_B
	
	cmp directie[1], 1
	je image_C
	
	cmp directie[2], 1
	je image_D
	
	cmp directie[3], 1
	je image_E
	
	draw_pacman_image 'C', area, playerX, playerY
	jmp selectare_imagini_fantome

;-----------------------------------------------------IMAGINI

image_B: ;--Pacman sus
	draw_pacman_image 'B', area, playerX, playerY
	jmp selectare_imagini_fantome

image_C: ;--Pacman dreapta
	draw_pacman_image 'C', area, playerX, playerY
	jmp selectare_imagini_fantome

image_D: ;--Pacman jos
	draw_pacman_image 'D', area, playerX, playerY
	jmp selectare_imagini_fantome

image_E: ;--Pacman stanga
	draw_pacman_image 'E', area, playerX, playerY
	jmp selectare_imagini_fantome

;-------------------------------------------------------------------SUPER_POWER
de_mancat:
	cmp dir_fantome[0], 0
	jl tasta_apasata
	draw_pacman_image 'Q', area, pozX_fantome[0], pozY_fantome[0]
	
	cmp dir_fantome[1*4], 0
	jl tasta_apasata
	draw_pacman_image 'Q', area, pozX_fantome[1*4], pozY_fantome[1*4]
	
	cmp dir_fantome[2*4], 0
	jl tasta_apasata
	draw_pacman_image 'Q', area, pozX_fantome[2*4], pozY_fantome[2*4]
	
	cmp dir_fantome[3*4], 0
	jl tasta_apasata
	draw_pacman_image 'Q', area, pozX_fantome[3*4], pozY_fantome[3*4]
	
	jmp tasta_apasata
	
;------------------------------------------------------------------SELECTARE_IMAGINI_FANTOME
selectare_imagini_fantome:

	cmp super_power, 1
	je de_mancat

	cmp dir_fantome[0], 0
	jl tasta_apasata
	draw_pacman_image 'H', area, pozX_fantome[0], pozY_fantome[0]
	
	cmp dir_fantome[1*4], 0
	jl tasta_apasata
	draw_pacman_image 'I', area, pozX_fantome[1*4], pozY_fantome[1*4]
	
	cmp dir_fantome[2*4], 0
	jl tasta_apasata
	draw_pacman_image 'J', area, pozX_fantome[2*4], pozY_fantome[2*4]
	
	cmp dir_fantome[3*4], 0
	jl tasta_apasata
	draw_pacman_image 'K', area, pozX_fantome[3*4], pozY_fantome[3*4]
	
	jmp tasta_apasata	

;--------------------------------------------------TASTA_APASATA

tasta_apasata:
	mov eax, [ebp+arg2]
	cmp eax, 'W'
	je pacman_sus
	
	mov eax, [ebp+arg2]
	cmp eax, 'D'
	je pacman_dreapta
	
	mov eax, [ebp+arg2]
	cmp eax, 'S'
	je pacman_jos
	
	mov eax, [ebp+arg2]
	cmp eax, 'A'
	je pacman_stanga
	
	jmp final_draw

;-----------------------------------------------DIRECTIE_PACMAN
	
pacman_sus:
	
	mov directie[0], 1
	mov directie[1], 0
	mov directie[2], 0
	mov directie[3], 0
	jmp final_draw
	
pacman_dreapta:
	
	mov directie[0], 0
	mov directie[1], 1
	mov directie[2], 0
	mov directie[3], 0
	jmp final_draw

pacman_jos:
	
	mov directie[0], 0
	mov directie[1], 0
	mov directie[2], 1
	mov directie[3], 0
	jmp final_draw
	
pacman_stanga:
	
	mov directie[0], 0
	mov directie[1], 0
	mov directie[2], 0
	mov directie[3], 1
	jmp final_draw
	
;-------------------------------------------------FINAL_DRAW
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------START

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	
	push eax
	call malloc
	add esp, 4
	mov area, eax

	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
