    global setIDT32:function

idtr:
    dw      0
    dd      0

setIDT32:
    XOR     EAX, EAX
    MOV     AX, [esp + 4]
    MOV     [idtr], AX
    MOV     EAX, [ESP + 8]
    MOV     [idtr + 2], EAX
    LIDT    [idtr]
    RET
