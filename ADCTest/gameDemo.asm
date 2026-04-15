ORG 0

; =========================================================
; ADC Target Game
; ---------------------------------------------------------
; Display layout:
;   HEX5 HEX4 = Score
;   HEX3 HEX2 = Current ADC/player value
;   HEX1 HEX0 = Target
;
; Game flow:
; 1. Initialize variables
; 2. Wait until all switches are down
; 3. Generate a random 8-bit target
; 4. Display the target
; 5. Read ADC input through the peripheral
; 6. Scale ADC value from 12 bits to 8 bits
; 7. Display the current value
; 8. Compare ADC value to target
; 9. Show feedback on LEDs
; 10. If player wins, pause, increment score, and start next round
; =========================================================

Start:
    CALL Init

MainLoop:
    CALL WaitAllDown        ; Make sure switches are reset before next round
    CALL GenerateTarget     ; Generate random target T
    CALL DisplayTarget      ; Show target on HEX1:HEX0
    CALL DisplayScore       ; Show score on HEX5:HEX4

GameLoop:
    CALL ReadADC            ; Read analog input and scale to 8 bits
    CALL DisplayCurrentValue ; Show current ADC/player value on HEX3:HEX2
    CALL CompareToTarget    ; Check if ADC value matches target
    CALL DisplayFeedback    ; Show too low / too high / win on LEDs

    LOAD WinFlag            ; Keep looping until player wins
    JZERO GameLoop

    CALL WinPause           ; Hold the win display briefly
    CALL IncrementScore     ; Increase score if player wins
    JUMP MainLoop           ; Start a new round


; =========================================================
; Init
; Reset all variables to zero at the start of the game
; =========================================================
Init:
    LOAD ZeroVal
    STORE Counter
    STORE Target
    STORE ADCValue
    STORE WinFlag
    STORE Score
    STORE Diff
    STORE DelayCount

    CALL DisplayScore
    RETURN


; =========================================================
; WaitAllDown
; Wait until all switches are turned off before beginning
; the next round. The switch state is displayed on the LEDs
; =========================================================
WaitAllDown:
    IN Switches
    OUT LEDs
    JNZ WaitAllDown
    RETURN


; =========================================================
; GenerateTarget
; Uses a free-running counter as a random generator.
; Counter keeps increasing until SW9 is raised.
; Then Counter mod 256 becomes the target.
; Similar to Lab8
; =========================================================
GenerateTarget:
GenLoop:
    LOAD Counter
    ADDI 1
    STORE Counter

    IN Switches
    OUT LEDs
    AND SW9Mask             ; Check if SW9 is high
    JZERO GenLoop           ; If not, keep counting

    LOAD Counter
    AND Mask8Bit            ; Target = Counter mod 256
    STORE Target
    RETURN


; =========================================================
; DisplayTarget
; Displays the 8-bit target across two HEX displays.
; HEX1 = high nibble
; HEX0 = low nibble
; =========================================================
DisplayTarget:
    LOAD Target
    AND LowNibbleMask
    OUT Hex0                ; Display low nibble

    LOAD Target
    SHIFT -4
    AND LowNibbleMask
    OUT Hex1                ; Display high nibble
    RETURN


; =========================================================
; DisplayCurrentValue
; Displays the current ADC/player value across two HEX displays.
; HEX3 = high nibble
; HEX2 = low nibble
; =========================================================
DisplayCurrentValue:
    LOAD ADCValue
    AND LowNibbleMask
    OUT Hex2                ; Display low nibble

    LOAD ADCValue
    SHIFT -4
    AND LowNibbleMask
    OUT Hex3                ; Display high nibble
    RETURN


; =========================================================
; DisplayScore
; Displays the score across two HEX displays.
; HEX5 = high nibble
; HEX4 = low nibble
; =========================================================
DisplayScore:
    LOAD Score
    AND LowNibbleMask
    OUT Hex4                ; Display low nibble

    LOAD Score
    SHIFT -4
    AND LowNibbleMask
    OUT Hex5                ; Display high nibble
    RETURN


; =========================================================
; ReadADC
; Reads the ADC peripheral using the register interface:
; 1. Select ADC channel
; 2. Clear READY
; 3. Start conversion
; 4. Poll status until READY = 1
; 5. Read ADC result
; 6. Shift right by 4 so 12-bit ADC becomes 8-bit
; =========================================================
ReadADC:
    LOADI 0
    OUT ADC_CHAN            ; Select ADC channel 0

    LOADI 2
    OUT ADC_CTRL            ; CLEAR_READY

    LOADI 1
    OUT ADC_CTRL            ; START conversion

PollADC:
    IN ADC_STAT
    AND OneVal              ; Check READY bit
    JZERO PollADC           ; Wait until ready

    IN ADC_DATA
    STORE ADCValue          ; Read ADC result

    LOAD ADCValue
    SHIFT -4                ; Scale 12-bit ADC to 8-bit
    AND Mask8Bit
    STORE ADCValue
    RETURN


; =========================================================
; CompareToTarget
; Compares ADCValue directly to Target.
; Uses tolerance-based win condition:
;   win if |ADCValue - Target| <= Tolerance
; With Tolerance = 4, the player wins if the ADC value
; is within ±4 of the target.
; =========================================================
CompareToTarget:
    LOAD ZeroVal
    STORE WinFlag

    LOAD ADCValue
    SUB Target
    STORE Diff

    ; If difference is negative, take absolute value
    JPOS DiffPositive
    LOAD ZeroVal
    SUB Diff
    STORE Diff

DiffPositive:
    LOAD Diff
    SUB Tolerance
    JPOS NotWin             ; If Diff > Tolerance, no win

    LOAD OneVal
    STORE WinFlag           ; Otherwise, player wins
    RETURN

NotWin:
    RETURN


; =========================================================
; DisplayFeedback
; LED behavior:
; - Win: all LEDs on
; - ADCValue < Target: LED0 on (too low)
; - ADCValue > Target: LED1 on (too high)
; =========================================================
DisplayFeedback:
    LOAD WinFlag
    JZERO CheckHighLow

    LOAD AllOn
    OUT LEDs
    RETURN

CheckHighLow:
    LOAD ADCValue
    SUB Target
    JPOS TooHigh

TooLow:
    LOAD LED0On
    OUT LEDs
    RETURN

TooHigh:
    LOAD LED1On
    OUT LEDs
    RETURN


; =========================================================
; WinPause
; Holds the win display briefly before starting the next round
; =========================================================
WinPause:
    LOAD DelayCountInit
    STORE DelayCount

WinPauseLoop:
    LOAD DelayCount
    ADDI -1
    STORE DelayCount
    JZERO WinPauseDone
    JUMP WinPauseLoop

WinPauseDone:
    RETURN


; =========================================================
; IncrementScore
; Increase score after a successful round, then redisplay score
; =========================================================
IncrementScore:
    LOAD Score
    ADDI 1
    AND Mask8Bit
    STORE Score

    CALL DisplayScore
    RETURN


; =========================================================
; I/O Addresses
; =========================================================
Switches    EQU 000
LEDs        EQU 001
Hex0        EQU 004
Hex1        EQU 005
Hex2        EQU 006
Hex3        EQU 007
Hex4        EQU 008
Hex5        EQU 009

; ADC peripheral register addresses
ADC_CTRL    EQU &HC0
ADC_STAT    EQU &HC1
ADC_DATA    EQU &HC2
ADC_CHAN    EQU &HC3


; =========================================================
; Constants
; =========================================================
ZeroVal:        DW 0
OneVal:         DW 1
Tolerance:      DW 4         ; Win if within ±4 of target
Mask8Bit:       DW &H00FF
LowNibbleMask:  DW &H000F
SW9Mask:        DW &H0200    ; Switch 9
LED0On:         DW &H0001
LED1On:         DW &H0002
AllOn:          DW &H03FF

DelayCountInit: DW 5000      ; Adjust if pause is too short or too long


; =========================================================
; Variables
; =========================================================
Counter:        DW 0         ; Free-running counter for pseudo-random target
Target:         DW 0         ; Random target
ADCValue:       DW 0         ; Scaled ADC result
WinFlag:        DW 0         ; 1 if player wins, 0 otherwise
Score:          DW 0         ; Running score
Diff:           DW 0         ; Temporary difference storage
DelayCount:     DW 0         ; Used in WinPause