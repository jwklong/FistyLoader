BITS 64

extern SDL_ShowSimpleMessageBox
extern FileSystemUtils_CreateDir
extern Environment_instance

extern gooballIds

extern loading_screen_hook_return
extern loading_screen_draw_hook_return
extern load_config_hook_return
extern eolgizmo_hook_return
extern ballfactory_start_hook_return
extern ballfactory_loop_hook_return
extern ballfactory_init_hook_return
extern ballfactory_constructor_hook1_return
extern ballfactory_constructor_hook2_return
extern get_template_info_hook_return
extern create_objects_hook_return
extern ball_deserialize_hook_return
extern itempipein_spawnball_hook_return
extern get_gooball_name_hook1_return
extern get_gooball_name_hook2_return
extern set_state_from_item_hook_return
extern set_state_from_ball_hook_return
extern try_shoot_ball_hook_return

extern initBallTable

section .fisty

global customGooballIds
global gooballCount
customGooballIds dq 0
gooballCount dq 0

; load_config_hook
; 
; Hooks into SDL2Environment::loadConfig to generate the fisty/ballTable.ini file
; if it doesn't already exist or load the file if it does.
load_config_hook:
    push rbx
    push rcx
    push rdx
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    
    mov rbp, rsp
    sub rsp, 64 + 128
    
    ; TODO: which registers does this clobber? (so i can get rid of some of the pushes and pops)
    call initBallTable

    add rsp, 64 + 128
    
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    
    ; softbranch
    mov qword [rsp+8], rbx
    jmp load_config_hook_return


; eolgizmo_hook
;
; Hooks into EOLGizmo::update and makes it use the custom gooballIds
; table rather than the default one.
eolgizmo_hook:
    ; rdx is free right now
    mov rdx, [rel customGooballIds]
    mov rbx, [rdx+rcx*8] ; rbx = char* ballName
    
    jmp eolgizmo_hook_return


; ballfactory_start_hook
;
; Hooks into BallFactory::load before the loop starts to make it
; use the custom gooballIds (why does that function even reference
; that?) and repurpose r14 into the gooballCount.
ballfactory_start_hook:
    mov r14, [rel gooballCount] ; r14 = gooballCount
    mov rsi, [rel customGooballIds] ; rsi = char** iterator
    add rsi, 8 ; make it point to gooballIds[1]
    jmp ballfactory_start_hook_return


; ballfactory_loop_hook
;
; Hooks into BallFactory::load during the loop to make it calculate
; the offset into this->templateInfos without r14.
ballfactory_loop_hook:
    ; this fucking sucks, I assumed multiplication would not be this stupid
    mov rax, rdi
    mov rcx, 0x4cb48
    mul rcx
    
    add rbx, rax
    mov rdx, rbx
    jmp ballfactory_loop_hook_return


; ballfactory_init_hook
;
; Hooks into BallFactory::init and modifies BallFactory's allocation size
; to be dynamically determined by gooballCount.
ballfactory_init_hook:
    mov rax, 0x4cb48 ; = sizeof(BallTemplateInfo)
    mov rcx, qword [rel gooballCount] ; = gooballCount
    mul rcx
    
    lea rcx, [rax+0x18]
    jmp ballfactory_init_hook_return


; ballfactory_constructor_hook1
; 
; Hooks into BallFactory's constructor and modifies the amount of templateInfos
; to be initialized with BallTemplateInfo's constructor.
ballfactory_constructor_hook1:
    mov r8, qword [rel gooballCount]
    jmp ballfactory_constructor_hook1_return


; ballfactory_constructor_hook2
; 
; Hooks into BallFactory's constructor and modifies the value
; this->templateInfos.length will be set to
ballfactory_constructor_hook2:
    mov rdx, qword [rel gooballCount]
    mov dword [rdi+0x8], edx
    jmp ballfactory_constructor_hook2_return


; get_template_info_hook
; 
; Hooks into BallFactory::getTemplateInfo and modifies the
; amount of templateInfos it iterates through to gooballCount
get_template_info_hook:
    inc r9 ; r9 = i
    mov r8, qword [rel gooballCount]
    cmp r9, r8
    jmp get_template_info_hook_return


; create_objects_hook
; 
; Hooks into Item::createObjects and modifies the maximum
; gooball type for userVars with type 4
create_objects_hook:
    mov rcx, qword [rel gooballCount]
    dec rcx
    
    pxor xmm3, xmm3
    cvtsi2ss xmm3, ecx
    jmp create_objects_hook_return


; ball_deserialize_hook
;
; Hooks into BallTemplateInfoUtils::Deserialize and
; replaces gooBallIds with customGooBallIds
ball_deserialize_hook:
    mov rax, [rel customGooballIds]
    jmp ball_deserialize_hook_return


; itempipein_spawnball_hook
;
; Hooks into ItemPipeIn::spawnBall and replaces
; gooBallIds with customGooBallIds
itempipein_spawnball_hook:
    mov rax, [rel customGooballIds]
    jmp itempipein_spawnball_hook_return


; loading_screen_hook
; 
; Hooks into the LoadingScreenRenderer constructor and reenables
; the unused loading screen watermark to now use the text
; in `loadingText`
loading_screen_hook:
    lea rdx, [rel loadingText]
    jmp loading_screen_hook_return


; get_gooball_name_hook1
;
; Hooks into GetGooBallName and replaces GooBallIds with
; customGooballIds
get_gooball_name_hook1:
    mov rax, [rel customGooballIds]
    jmp get_gooball_name_hook1_return


; get_gooball_name_hook2
;
; Hooks into GetGooBallName and unhardcodes the gooball count
get_gooball_name_hook2:
    mov rsi, [rel gooballCount]
    add rdx, rsi
    
    mov rcx, qword [rcx - 0x8]
    jmp get_gooball_name_hook2_return


; set_state_from_item_hook
;
; Hooks into ItemPropertiesGizmo::setStateFromItem and unhardcodes
; gooBallIds and gooballCount
set_state_from_item_hook:
    mov r9, [rel customGooballIds]
    mov dword [rsp+0x20], 1
    mov r8d, [rel gooballCount]
    sub r8d, 1
    
    jmp set_state_from_item_hook_return


; set_state_from_ball_hook
;
; Hooks into ItemPropertiesGizmo::setStateFromBall and unhardcodes
; gooBallIds and gooballCount
set_state_from_ball_hook:
    mov r8d, [rel gooballCount]
    mov r9, [rel customGooballIds]
    mov rbx, qword [rdi + 0xe1ac0]
    sub r8d, 1
    
    jmp set_state_from_ball_hook_return


; try_shoot_ball_hook
;
; Hooks into LauncherUtils::tryShootBall (?) and unhardcodes gooballIds
try_shoot_ball_hook:
    mov rdx, [rel customGooballIds]
    jmp try_shoot_ball_hook_return


%include "patch/ini_parse.s"

; constants
msgTitle db "Fisty Loader", 00h
ballTablePath db "fisty/ballTable.ini", 00h

baseGooballCount equ 39

loadingText db "Using FistyLoader v1.1", 00h
