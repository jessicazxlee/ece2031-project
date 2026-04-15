ORG 0

; =========================================================
; ADC Target Game
; ---------------------------------------------------------
; Display layout:
;   HEX3 HEX2 = Target
;   HEX1 HEX0 = Current ADC/player value
;
; LED behavior:
;   LED0 = too low
;   LED1 = too high
;   All LEDs on = within target range / win
;
; Game flow:
; 1. Initialize variables
; 2. Wait until all switches are down
; 3. Generate a random 8-bit target
; 4. Display the target
; 5. Read ADC input through the peripheral
; 6. Scale ADC value from 12 bits to 8 bits
; 7. Display current ADC value
; 8. Compare ADC value to target
; 9. Show feedback on LEDs
; 10. If player wins, pause, increment score, and start next round
; =========================================================

Start:
    CALL Init

MainLoop:
    CALL WaitAllDown        ; Wait until all switches are off
    CALL GenerateTarget     ; Generate random target
    CALL DisplayTarget      ; Show target on HEX3:HEX2

    LOAD ZeroVal
    OUT LEDs                ; Clear LEDs at the start of a new round

GameLoop:
    CALL ReadADC            ; Read analog input from ADC
    CALL DisplayCurrentValue ; Show current ADC value on HEX1:HEX0
    CALL CompareToTarget    ; Check if ADC value is within range
    CALL DisplayFeedback    ; Show too low / too high / win on LEDs

    LOAD WinFlag
    JZERO GameLoop          ; Keep playing until player wins

    CALL WinPause           ; Hold win display briefly
    CALL IncrementScore     ; Increment internal score
    JUMP MainLoop           ; Start next round


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
; =========================================================
GenerateTarget:
GenLoop:
    LOAD Counter
    ADDI 1
    STORE Counter

    IN Switches
    OUT LEDs
    AND SW9Mask
    JZERO GenLoop

    LOAD Counter
    AND Mask8Bit
    STORE Target
    RETURN


; =========================================================
; DisplayTarget
; Displays the 8-bit target across HEX3:HEX2
; HEX3 = high nibble
; HEX2 = low nibble
; =========================================================
DisplayTarget:
    LOAD Target
    AND LowNibbleMask
    OUT Hex2                ; low nibble of target

    LOAD Target
    SHIFT -4
    AND LowNibbleMask
    OUT Hex3                ; high nibble of target
    RETURN


; =========================================================
; DisplayCurrentValue
; Displays the current ADC/player value across HEX1:HEX0
; HEX1 = high nibble
; HEX0 = low nibble
; =========================================================
DisplayCurrentValue:
    LOAD ADCValue
    AND LowNibbleMask
    OUT Hex0                ; low nibble of ADC value

    LOAD ADCValue
    SHIFT -4
    AND LowNibbleMask
    OUT Hex1                ; high nibble of ADC value
    RETURN


; =========================================================
; ReadADC
; Reads the ADC peripheral using the known working sequence:
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
; Win if |ADCValue - Target| <= Tolerance
; With Tolerance = 4, the player wins if ADCValue is within ±4
; =========================================================
CompareToTarget:
    LOAD ZeroVal
    STORE WinFlag

    LOAD ADCValue
    SUB Target
    STORE Diff

    ; Convert negative difference to positive
    JPOS DiffPositive
    LOAD ZeroVal
    SUB Diff
    STORE Diff

DiffPositive:
    LOAD Diff
    SUB Tolerance
    JPOS NotWin

    LOAD OneVal
    STORE WinFlag
    RETURN

NotWin:
    RETURN


; =========================================================
; DisplayFeedback
; LED behavior:
; - Win: all LEDs on
; - ADCValue < Target: LED0 on
; - ADCValue > Target: LED1 on
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
; Holds the win display briefly before starting next round
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
; Increase score after a successful round
; Score is kept internally for now
; =========================================================
IncrementScore:
    LOAD Score
    ADDI 1
    AND Mask8Bit
    STORE Score
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
Tolerance:      DW 4
Mask8Bit:       DW &H00FF
LowNibbleMask:  DW &H000F
SW9Mask:        DW &H0200
LED0On:         DW &H0001
LED1On:         DW &H0002
AllOn:          DW &H03FF
DelayCountInit: DW 5000


; =========================================================
; Variables
; =========================================================
Counter:        DW 0
Target:         DW 0
ADCValue:       DW 0
WinFlag:        DW 0
Score:          DW 0
Diff:           DW 0
DelayCount:     DW 0