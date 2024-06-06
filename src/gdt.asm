    global setGDT32:function

gdtr:
    dw      0
    dd      0

setGDT32:
    XOR     EAX, EAX
    MOV     AX, [esp + 4]
    MOV     [gdtr], AX
    MOV     EAX, [ESP + 8]
    MOV     [gdtr + 2], EAX
    LGDT    [gdtr]
    RET
