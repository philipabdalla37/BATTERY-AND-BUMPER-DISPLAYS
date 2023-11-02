;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 
		
; Definitions

LCD_DAT      EQU  PORTB     ;LCD data port, bits - PB7,...,PB0
LCD_CNTR   EQU  PTJ           ;LCD control port, bits - PE7(RS),PE4(E)
LCD_E           EQU $80                       ; LCD E-signal pin
LCD_RS        EQU $40                    ; LCD RS-signal pin
; Variable/data section

                        ORG   $3850
BCD_BUFFER EQU *    ; The following registers are the BCD buffer area                        
TEN_THOUS RMB 1     ;10,000 digit
THOUSANDS   RMB 1     ;1,000 digit
HUNDREDS     RMB 1      ;100 digit
TENS                  RMB 1                  ;10 digit
UNITS                 RMB 1                 ;1 digit
BCD_SPARE     RMB 2           ;Extra space for the decimal point and string terminator
NO_BLANK        RMB 1                  ;Used in ’leading zero’ blanking by BCD2ASC
; Code section
                      ORG $4000
                      
Entry:
_Startup:
            LDS   #$4000      ;initialize the stack pointer
            JSR   initAD      ;initialize ATD converter
            JSR   initLCD     ;initialize LCD
            JSR   clrLCD      ;clear LCD & home cursor    
            LDX   #msg1       ;display msg1
            JSR   putsLCD     ;"
            LDAA  #$C0        ;move LCD cursor to the 2nd row
            JSR   cmd2LCD
            LDX   #msg2       ;display msg2
            JSR   putsLCD     ;"
lbl         MOVB  #$90,ATDCTL5  ;r.just., unsign., sing.conv., mult., ch0, start conv.
            BRCLR ATDSTAT0, $80, * ;wait until the conversion sequence is complete
            LDAA  ATDDR4L         ;load the ch4 result into AccA
            LDAB  #$39            ;AccB = 39
            MUL                   ;AccD = 1st result x 39
            ADDD  #$600          ;AccD = 1st result x 39 + 600
            JSR   int2BCD
            JSR   BCD2ASC
            LDAA  #$8D        ;move LCD cursor to the 1st row, end of msg1
            JSR   cmd2LCD     ;"
            LDAA  TEN_THOUS   ;output the TEN_THOUS ASCII character
            JSR   putcLCD     ;"
            LDAA  THOUSANDS   ;output the THOUSANDS ASCII character
            JSR   putcLCD     ;"
            LDAA  #$2E        ;Output the HUNDREDS ASCII
            JSR   putcLCD     ;"
            LDAA  HUNDREDS    ;output the HUNDREDS ASCII character
            JSR   putcLCD     ;"     
            LDAA  #$CA        ;move LCD cursor to the 2nd row, end of msg2
            JSR   cmd2LCD     ;"
            BRCLR PORTAD0,%00000100,bowON
            LDAA  #$31        ;output ’1’ if bow sw OFF
            BRA   bowOFF
bowON       LDAA  #$30        ;output ’0’ if bow sw ON
bowOFF      JSR   putcLCD
            LDAA  #$20        ;hex value for space character
            JSR   putcLCD
            BRCLR PORTAD0,#%00001000,sternON
            LDAA  #$31        ; output '1' if stern sw OFF
            BRA   sternOFF
sternON:    LDAA  #$30        ; output '0' if stern sw ON
sternOFF:   JSR   putcLCD   
            JMP   lbl
msg1:       dc.b "Battery volt ",0
msg2:       dc.b "Sw status ",0


;FROM LAB 2
initLCD   BSET  DDRB,%11111111   ;Configure pins PB7-PB0 as output for port B
          BSET  DDRJ,%11000000          ;Configure pins 6 (Contol Byte of LCD- RS) and 7(Connected to enable output on the keypad and Enable on LCD - E) as ouputs of port J
          LDY   #2000                                    ;Load register Y with decimal 2000  - delay by 0.1sec
          JSR   del_50us                               ;jump to delay 50us subroutine
          LDAA  #$28                                      ;Load accumulatore a with a hex value of 28    , set 4-bit daya, 2-line display
          JSR   cmd2LCD                              ;jump to cmd2LCD subroutine
          LDAA  #$0C                                      ;  Display will be on, cursor off, blinking off
          JSR   cmd2LCD                              ; jump to cmd2LCD subroutine
          LDAA  #$06                                       ;Entry Mode set, movve cursor right after entering a character
          JSR   cmd2LCD                               ; jump to cmd2LCD subroutine
          RTS                                                      ;return from subroutine

;FROM LAB 2
clrLCD    LDAA  #$01        ;Clear display and return to home position
          JSR   cmd2LCD          ; jump to cmd2LCD subroutine
          LDY   #40                         ;Load register Y with decimal 40
          JSR   del_50us             ;jump to delay 50us subroutine
          RTS                                   ;return from subroutine
          
;FROM LAB 2
del_50us: PSHX             ;Stack point will subtract by 2 and high bits of X will go on top and low bits of X will go on bottom to safe info about X 
eloop:    LDX   #30           ;Loads decimal 30 to register X
iloop:    PSHA                    ;Wasting TIME
          PULA
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP
          NOP                     ;21 NOP
          PSHA
          PULA
          NOP
          NOP
          DBNE  X,iloop          ;decrement X and branch to iloop if answer if not equal to zero
          DBNE  Y,eloop          ;decrement Y and branch to eloop if answer if not equal to zero
          PULX                            ;Pull the first two bytes from stack and store then into X again and adds SP by 2
          RTS   
          
;FROM LAB 2
;Sends command from accumulator A to the LCD

cmd2LCD:  BCLR  LCD_CNTR,LCD_RS           ;Clear actual pin 7 in Port E -->0
          JSR   dataMov                                                  ;Jump to subroutine dataMov
          RTS                                                                     ;return from subroutine
          
;FROM LAB2       
;Outputs a Null terminated string to by register x

putsLCD   LDAA  1,X+                           ;Load   acc A with X and then add 1 to X
          BEQ   donePS                              ;Branch if equal to zero
          JSR   putcLCD                              ;jump to subroutine putcLCD to display the character
          BRA   putsLCD                              ;Load will load the next letter
donePS    RTS                                          ;return from subroutine


;FROM LAB 2
;Outputs the character in accumulator A to Lcd

putcLCD   BSET  LCD_CNTR,LCD_RS        ;Set the RS - > Control Byte     
          JSR   dataMov                                           ;jump subroute datamov to display character
          RTS


;FROM LAB 2
dataMov   BSET  LCD_CNTR,LCD_E                 ;Set actual pin 4 to a 1 in Port E  (E-SIGNAL is high)
          STAA  LCD_DAT                                            ;Send high bits of  acc A to port S (Data Bye of LCD)
          BCLR  LCD_CNTR,LCD_E                         ;Clear port E's pin 4 ->0
          
          LSLA                                                                   ;Sfift A by four to the left
          LSLA
          LSLA
          LSLA
          
          BSET  LCD_CNTR,LCD_E                       ;set the E-signal to a 1   (ready to read)
          STAA  LCD_DAT                                          ;Sending the lower 4 bits of Acc A to Data byte
          BCLR  LCD_CNTR,LCD_E                        ;Clear E-signal             (done reading)
                                                                                     
          LDY   #1                                                          ;Load decimal 1 register Y
          JSR   del_50us                                              ;Jump to delay 5us subrouine
          RTS      
          
;BINARY 16 TO BCD CONVRESION- SECTION 8       
int2BCD     XGDX      ;Save the binary number into .X
            LDAA  #0  ;Clear the BCD_BUFFER
            STAA  TEN_THOUS
            STAA  THOUSANDS
            STAA  HUNDREDS
            STAA  TENS
            STAA  UNITS
            STAA  BCD_SPARE
            STAA  BCD_SPARE+1
*
            CPX   #0 ;Check for a zero input
            BEQ   CON_EXIT ;and if so, exit
*
            XGDX          ;Not zero, get the binary number back to .D as dividend
            LDX   #10      ;Setup 10 (Decimal!) as the divisor
            IDIV          ;Divide: Quotient is now in .X, remainder in .D
            STAB  UNITS       ;Store remainder
            CPX   #0        ;If quotient is zero,
            BEQ   CON_EXIT     ; then exit
*
            XGDX          ;else swap first quotient back into .D
            LDX   #10     ;and setup for another divide by 10
            IDIV
            STAB  TENS
            CPX   #0
            BEQ   CON_EXIT
*
            XGDX        ;Swap quotient back into .D
            LDX   #10     ;and setup for another divide by 10
            IDIV
            STAB  HUNDREDS
            CPX   #0
            BEQ   CON_EXIT
*
            XGDX          ;Swap quotient back into .D
            LDX   #10 ;and setup for another divide by 10
            IDIV
            STAB  THOUSANDS
            CPX   #0
            BEQ   CON_EXIT
*
            XGDX ;Swap quotient back into .D
            LDX   #10 ;and setup for another divide by 10
            IDIV
            STAB  TEN_THOUS
*
CON_EXIT    RTS   ;We’re done the conversion



;BCD TO ASCII CONVERSION--SECTION 10
BCD2ASC     LDAA  #0  ;Initialize the blanking flag
            STAA  NO_BLANK
*
C_TTHOU     LDAA  TEN_THOUS ;Check the ’ten_thousands’ digit
            ORAA  NO_BLANK
            BNE   NOT_BLANK1

ISBLANK1    LDAA  #$20 ;It’s blank
            STAA  TEN_THOUS ;so store a space
            BRA   C_THOU ;and check the ’thousands’ digit
*
NOT_BLANK1  LDAA  TEN_THOUS ;Get the ’ten_thousands’ digit
            ORAA  #$30 ;Convert to ascii
            STAA  TEN_THOUS
            LDAA  #$1 ;Signal that we have seen a ’non-blank’ digit
            STAA  NO_BLANK
*
C_THOU      LDAA  THOUSANDS ;Check the thousands digit for blankness
            ORAA  NO_BLANK ;If it’s blank and ’no-blank’ is still zero
            BNE   NOT_BLANK2
*
ISBLANK2    LDAA  #$30 ;Thousands digit is blank
            STAA  THOUSANDS ;so store a space
            BRA   C_HUNS ;and check the hundreds digit
*
NOT_BLANK2  LDAA  THOUSANDS; (similar to ’ten_thousands’ case)
            ORAA  #$30
            STAA  THOUSANDS
            LDAA  #$1
            STAA  NO_BLANK
*
C_HUNS      LDAA  HUNDREDS ;Check the hundreds digit for blankness
            ORAA  NO_BLANK ;If it’s blank and ’no-blank’ is still zero
            BNE   NOT_BLANK3
*
ISBLANK3    LDAA  #$20 ;Hundreds digit is blank
            STAA  HUNDREDS ;so store a space
            BRA   C_TENS ;and check the tens digit
*
NOT_BLANK3  LDAA  HUNDREDS ;(similar to ’ten_thousands’ case)
            ORAA  #$30
            STAA  HUNDREDS
            LDAA  #$1
            STAA  NO_BLANK
*
C_TENS      LDAA  TENS ;Check the tens digit for blankness
            ORAA  NO_BLANK ;If it’s blank and ’no-blank’ is still zero
            BNE   NOT_BLANK4
*
ISBLANK4    LDAA  #$20 ;Tens digit is blank
            STAA  TENS ;so store a space
            BRA   C_UNITS ;and check the units digit
*
NOT_BLANK4  LDAA  TENS ;(similar to ’ten_thousands’ case)
            ORAA  #$30
            STAA  TENS
*
C_UNITS     LDAA  UNITS ;No blank check necessary, convert to ascii.
            ORAA  #$30
            STAA  UNITS
*
            RTS       ;We’re done
       
          


initAD      MOVB  #$C0,ATDCTL2  ;power up AD, select fast flag clear
            JSR   del_50us      ;wait for 50 us
            MOVB  #$00,ATDCTL3  ;8 conversions in a sequence
            MOVB  #$85,ATDCTL4  ;res=8, conv-clks=2, prescal=12
            BSET  ATDDIEN,$0C    ;configure pins AN03,AN02 as digital inputs
            RTS 
; Interrupt vectors
                      

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
