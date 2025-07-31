# GIC
CSR for GIC

| Address | Registers |
|---------|-----------|
|0x0|isr|
|0x1|imr|

## 0x0 isr
Interruption Status Register

### [7:0] value
0: interrupt is inactive, 1: interrupt is active

## 0x1 imr
Interruption Mask Register

### [7:0] enable
0: interrupt is disable, 1: interrupt is enable

