#ifndef GIC_REGISTERS_H
#define GIC_REGISTERS_H

#include <stdint.h>

// Module      : GIC
// Description : CSR for GIC
// Width       : 8

//==================================
// Register    : isr
// Description : Interruption Status Register
// Address     : 0x0
//==================================
#define GIC_ISR 0x0

// Field       : isr.value
// Description : 0: interrupt is inactive, 1: interrupt is active
// Range       : [7:0]
#define GIC_ISR_VALUE      0
#define GIC_ISR_VALUE_MASK 255

//==================================
// Register    : imr
// Description : Interruption Mask Register
// Address     : 0x1
//==================================
#define GIC_IMR 0x1

// Field       : imr.enable
// Description : 0: interrupt is disable, 1: interrupt is enable
// Range       : [7:0]
#define GIC_IMR_ENABLE      0
#define GIC_IMR_ENABLE_MASK 255

//----------------------------------
// Structure {module}_t
//----------------------------------
typedef struct {
  uint8_t isr; // 0x0
  uint8_t imr; // 0x1
} GIC_t;

#endif // GIC_REGISTERS_H
