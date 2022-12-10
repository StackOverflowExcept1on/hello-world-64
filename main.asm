; We are targeting at x86_64, windows
BITS 64

; Section name in exe file
SECTION .text

; Header with internal windows structures
; https://github.com/wine-mirror/wine/blob/master/include/winternl.h

; See also
; https://en.wikipedia.org/wiki/Process_Environment_Block

; NtWriteFile syscall id, you can find syscall in your ntdll
; https://j00ru.vexillium.org/syscalls/nt/64/
NT_WRITE_FILE_SYSCALL_ID: equ 8

; syscalls ABI on windows x86_64:

; argument order: r10, rdx, r8, r9
; register eax stores syscall id
; register r10 is used as first argument instead of rcx

; stack:
; rsp + 0x00 -> [pseudo return address]

; rsp + 0x08 -> [shadow space for arg 1]
; rsp + 0x10 -> [shadow space for arg 2]
; rsp + 0x18 -> [shadow space for arg 3]
; rsp + 0x20 -> [shadow space for arg 4]

; rsp + 0x28 -> [arg 5]
; rsp + 0x30 -> [arg 6]
; rsp + 0x38 -> [arg 7]
; rsp + 0x40 -> [arg 8]
; rsp + 0x48 -> [arg 9]
; ...

; NtWriteFile (see https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/nf-ntifs-ntwritefile)
;  arg | type             | name          | register | desc
; -----|------------------|---------------|----------|---------------------
;    1 | HANDLE           | FileHandle    | r10      |
;    2 | HANDLE           | Event         | rdx      | unused
;    3 | PIO_APC_ROUTINE  | ApcRoutine    | r8       | unused
;    4 | PVOID            | ApcContext    | r9       | unused
;    5 | PIO_STATUS_BLOCK | IoStatusBlock | rsp+0x28 | unused (required)
;    6 | PVOID            | Buffer        | rsp+0x30 |
;    7 | ULONG            | Length        | rsp+0x38 |
;    8 | PLARGE_INTEGER   | ByteOffset    | rsp+0x40 | should be 0 at time of syscall
;    9 | PULONG           | Key           | rsp+0x48 | should be 0 at time of syscall

; Export symbol "_start"
GLOBAL _start
_start:
    ; allocate memory
    ; stack size = 80 (see https://github.com/JustasMasiulis/inline_syscall/blob/master/include/inline_syscall.inl)
    ; If I understand correctly, then the stack size is calculated like this:
    ; 1. 8 bytes for "pseudo ret address"
    ; 2. NtWriteFile has 9 args, 9 * 8 = 72 bytes (first 32 bytes is shadow space)
    ; 3. stack alignment by 16, in our case is nothing to align
    sub rsp, 80

    ; arg 1, r10 = NtCurrentTeb()->ProcessParameters->hStdOutput
    ; most useful structs is described in wine source code
    ; see: https://github.com/wine-mirror/wine/blob/master/include/winternl.h
    ; r10 = 0x60 (offset to PEB)
    push 0x60
    pop r10

    ; r10 = PEB*
    mov r10, gs:[r10]
    ; 0x20 is RTL_USER_PROCESS_PARAMETERS offset
    mov r10, [r10 + 0x20]
    ; 0x28 is hStdOutput offset
    mov r10, [r10 + 0x28]

    ; arg 2, rdx = 0
    xor edx, edx

    ; arg 3, r8 = 0, not necessary
    ; xor r8, r8

    ; arg 4, r9 = 0, not necessary
    ; xor r9, r9

    ; arg 5, [rsp + 0x28]
    ; this is not quite correct, but we will just overwrite the memory location
    ; called "stack shadow space"
    ; see: https://stackoverflow.com/questions/30190132/what-is-the-shadow-space-in-x64-assembly
    ; memory from rsp to [rsp + sizeof(IO_STATUS_BLOCK)] will be overwritten after syscall
    ; sizeof(IO_STATUS_BLOCK) = 16 bytes
    mov [rsp + 0x28], rsp

    ; arg 6, [rsp + 0x30]
    ; this is dirty hack to save bytes and push string to register rax
    ; call instruction will push address of hello world string to the stack and jumps to label `message_label`
    ; so, we can store address of string using pop instruction
    call message_label
    message: db 'Hello World!'
    message_label: pop rax
    mov [rsp + 0x30], rax

    ; arg 7, [rsp + 0x38]
    message_length: equ message_label - message
    push message_length
    pop rax
    mov dword [rsp + 0x38], eax

    ; arg 8, [rsp + 0x40], not necessary
    ; mov qword [rsp + 0x40], 0

    ; arg 9, [rsp + 0x48], not necessary
    ; mov qword [rsp + 0x48], 0

    ; eax = syscall id of NtWriteFile(...)
    push NT_WRITE_FILE_SYSCALL_ID
    pop rax

    ; perform syscall after passing all arguments
    syscall

    ; eax = 0 (exit code)
    xor eax, eax

    ; deallocate memory
    add rsp, 80

    ; exit from function
    ret
