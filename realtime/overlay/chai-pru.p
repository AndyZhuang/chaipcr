.origin 0               // offset of start of program in PRU memory
 .macro  MOV32
    .mparam dst, src
        MOV     dst.w0, src & 0xFFFF
        MOV     dst.w2, src >> 16
    .endm
 
   
 .entrypoint START       // program entry point used by the debugger 
 
 
 #define temp32reg r10    // temporary register 4bytes
 #define PRU0_R31_VEC_VALID  32; 
 #define PRU_EVTOUT_0        3 
 #define PRU_EVTOUT_1        4 
 // Using register 0 for all temporary storage (reused multiple times) 
 START:
    // clear interrupt
    MOV r2,0x00000000
    MOV r3,0x00
    SBBO r2,r3,0,4

    MOV32     temp32reg, (0x00000000 | 21)
    SBCO      temp32reg, C0, 0x24, 4

    // For future uses.
    //MOV    r0, 0x00000000                                // for future uses
    //LBBO   r1, r0, 0, 4                                  // for future uses 
 MAINLOOP:
    QBBS    END, r31.t30      // Exit when receive an interrupt

    QBBS  MAINLOOP, r31.t16                             // loop if pin is still HIGH
    
    MOV R31.b0, PRU0_R31_VEC_VALID | PRU_EVTOUT_0 
INLOOP:
    QBBS    END, r31.t30      // Exit when receive an interrupt
    QBBC  INLOOP , r31.t16                             // loop if pin is still LOW
    QBA   MAINLOOP                                       // loop to main
 END:
    SET r2,r2.t0
    MOV r3,0x00
    SBBO r2,r3,0,4
    MOV R31.b0, PRU0_R31_VEC_VALID | PRU_EVTOUT_0 
    HALT     
