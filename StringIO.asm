TITLE Low Level I/O Procedures  (StringIO.asm)

; Author: Mike Meller
; Last Modified: 8/15/2023
; Description:  Prompt user to enter SDWORD values and collect them into a string buffer.
;				Convert the strings into the corresponding SDWORDs and store them in an array.
;				Reject numbers that are too big or containing illegitimate symbols.
;				Calculate and display the sum and truncated average of the array.

INCLUDE Irvine32.inc


; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Description: Prints a prompt to the user then stores the user response into a buffer.
;	Uses mDisplayString macro and ReadString
;
; Preconditions: Do not use EDX, ECX, or EAX as arguements.
;				 Uses mDisplayString macro to print the string.
;
; Postconditions: None, all general registers preserved
;
; Receives:	
; promptStrAddr = A pointer to a string
; bufferAddr	= A pointer to a buffer to accept input
; bufferSize	= Value indicating how many elements the buffer can hold
; bytesReadAddr = A pointer to an output value to indicate how many bytes were read from the user
;
; Returns: 
; The prompt string is printed to terminal.
; The buffer is modified to contain the users input. 
; The value at bytesReadAddr contains the number of bytes entered by the user.
; -----------------------------------------------------------------------------------------
mGetString MACRO promptStrAddr, bufferAddr, bufferSize, bytesReadAddr
	;preserve registers
	PUSHAD
	
	;Print the prompt
	mDisplayString	promptStrAddr

	;Setup and call read string
	MOV				EDX, bufferAddr
	MOV				ECX, bufferSize
	CALL			ReadString

	;Store the output of ReadString
	MOV				[bytesReadAddr], EAX

	;Restore registers
	POPAD			
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Description: Prints a string to the terminal using WriteString.
;
; Preconditions: Do not use EDX as arguement
;
; Postconditions: None, EDX preserved.
;
; Receives:	
; strAdr = A pointer to a string
; 
;
; Returns: 
; The string is printed to terminal.
; -----------------------------------------------------------------------------------------
mDisplayString MACRO strAdr
	;preserve registers
	PUSH			EDX

	;Print the string with WriteString
	MOV				EDX,  strAdr
	CALL			WriteString

	;Restore registers
	POP				EDX				
ENDM

	;Constants
	ABS_MAX_SDWORD_VAL	= 2147483648	;SDWORD acceptable value is -2^31 to 2^31 - 1 or -2147483648 to 2147483647
	NUM_USER_INPUTS		= 10


.data

	;Strings
	intro			BYTE	"	Converting between strings and numerical values by Mike Meller",13,10,0
	description		BYTE	"This program will prompt the user for 10 integer string inputs corresponding to SDWORD values. ",
							"The strings will be processed for validity and converted into numerical SDWORDS to be stored in and array. ",
							"The sum and truncated average of the final array will be displayed.",13,10,0

	EC1				BYTE	"	**EC: Numbers user input lines and displays running total of valid numbers",13,10,0

	promptUser		BYTE	") Please enter an signed number: ",0
	invalidEntry	BYTE	"ERROR: Your entry was invalid!",13,10,
							"Please re-enter a signed number : ",0

	dispNums		BYTE	"You entered the following numbers: ",13,10,0
	partialSumStr	BYTE	"The sum of the numbers so far is: ",0
	sumStr			BYTE	"The sum of these numbers is: ",0
	avgStr			BYTE	"The truncated average is: ",0

	comma			BYTE	",",0
	space			BYTE	" ",0

	;Buffers and numeric variables
	buffer			BYTE	20 DUP(0)
	valArray		SDWORD	NUM_USER_INPUTS DUP(0)
	bufferSize		DWORD	SIZEOF buffer
	bytesRead		DWORD	?

	processedVal	SDWORD	?
	arraySum		SDWORD	?
	arrayAvg		SDWORD	?


.code

main PROC

; --------------------------
; Print the intro
; --------------------------
	mDisplayString	OFFSET intro
	mDisplayString	OFFSET EC1
	mDisplayString	OFFSET description
	CALL			CrLf

; --------------------------
; Ask user for NUM_USER_INPUTS string inputs of 32 bit signed integers using ReadVal
;	Store the corresponding numerical value in an array
; --------------------------

	;Loop NUM_USER_INPUTS times starting from the first index in valArray
	MOV				EDI, OFFSET valArray
	MOV				ECX, NUM_USER_INPUTS

_get_inputs:

	;EC1, calculate what number user input this is into EAX
	MOV				EAX, NUM_USER_INPUTS
	SUB				EAX, ECX
	ADD				EAX, 1

	;EC1, print what number user input this is
	PUSH			bufferSize
	PUSH			OFFSET buffer
	PUSH			EAX
	CALL			WriteVal

	;Pass parameters on the stack and call ReadVal to get a value from the user
	PUSH			ABS_MAX_SDWORD_VAL
	PUSH			OFFSET invalidEntry
	PUSH			OFFSET processedVal
	PUSH			OFFSET bytesRead
	PUSH			bufferSize
	PUSH			OFFSET buffer
	PUSH			OFFSET promptUser
	CALL			ReadVal

	;Store the numerical value from the user string input in the array
	MOV				EAX, processedVal
	MOV				[EDI], EAX

	;EC1, calculate the sum so far with calcAvg on the partially filled array
	PUSH			OFFSET arrayAvg
	PUSH			OFFSET arraySum
	PUSH			NUM_USER_INPUTS
	PUSH			OFFSET valArray
	CALL			calcAvg	

	;EC1, print the sum so far
	mDisplayString	OFFSET partialSumStr
	PUSH			bufferSize
	PUSH			OFFSET buffer
	PUSH			arraySum
	CALL			WriteVal
	CALL			CrLf
	CALL			CrLf

	;Go to next array index
	ADD				EDI, 4

	;Adjust ECX to loop
	DEC				ECX
	CMP				ECX, 0
	JNE				_get_inputs


; --------------------------
; Print the array of numerical values as ASCII strings
; --------------------------

	;Setup loop, NUM_USER_INPUTS times starting from the first val in valArray
	MOV				ECX, NUM_USER_INPUTS
	MOV				ESI, OFFSET valArray

	;Print the title
	CALL			CrLf
	mDisplayString	OFFSET dispNums

_show_nums:
	;Pass the value we want to print from the array and the string buffer to WriteVal
	PUSH			bufferSize
	PUSH			OFFSET buffer
	PUSH			[ESI]
	CALL			WriteVal

	;If this is the last value to print, we dont need a comma after it
	CMP				ECX, 1
	JNG				_no_comma

	;Print a comma and a space after each value
	mDisplayString	OFFSET comma
	mDisplayString	OFFSET space

_no_comma:
	;Go to next position in the array
	ADD				ESI, 4
	LOOP			_show_nums

; --------------------------
; Calculate and display the sum and avg value
; --------------------------

	;Pass parameters on the stack and call calcAvg
	PUSH			OFFSET arrayAvg
	PUSH			OFFSET arraySum
	PUSH			NUM_USER_INPUTS
	PUSH			OFFSET valArray
	CALL			calcAvg	
	CALL			CrLf

	mDisplayString	OFFSET sumStr
	PUSH			bufferSize
	PUSH			OFFSET buffer
	PUSH			arraySum
	CALL			WriteVal
	CALL			CrLf

	mDisplayString	OFFSET avgStr
	PUSH			bufferSize
	PUSH			OFFSET buffer
	PUSH			arrayAvg
	CALL			WriteVal
	CALL			CrLf

	Invoke			ExitProcess, 0	; exit to operating system
main ENDP



; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Description:	Get a string input from the user that corresponds to a 32 bit signed integer.
;				Store the corresponding numerical SDWORD in an output variable.
;				Reject any non-numerical characters except +/- if they occur at the front of the string.
;				Reject any value too big to be stored in an SDWORD.
;				If value is rejected, user is re-prompted for a new one.
;
; Preconditions: 
;	Uses mGetString macro to get input from the user
;	Value being read fits into an SDWORD (-2^31 to 2^31 - 1)
;	Buffer is large enough to hold a string corresponding to any SDWORD
;
; Postconditions: None, all general registers and flags preserved
;
; Receives:	[EBP + 8]  = Input reference to a string prompt to print to user
;			[EBP + 12] = Input reference to a buffer to store string from user
;			[EBP + 16] = Input Value, the size of the buffer
;			[EBP + 20] = Input reference to the number of bytes read
;			[EBP + 24] = Output reference to the numerical value being calculated.
;			[EBP + 28] = Input reference to an error string to print to use
;			[EBP + 32] = Input value, max value for an SDWORD
;
; Returns:	Prints prompts and error messages to the terminal window.
;			Stores an SDWORD in the output variable.
; -----------------------------------------------------------------------------------------
ReadVal PROC
	LOCAL		isNegative:BYTE

	;Preserve regsisters and flags
	PUSHAD
	PUSHFD
	

	;Call the get string macro with stack passed parameters
	mGetString		[EBP + 8], [EBP + 12], [EBP + 16], [EBP + 20]

_restart:
	;Initialize isNegative flag, assume positive by default
	MOV				isNegative, 0

	;Setup for going through the string backwards
	STD
	MOV				ECX, [EBP + 20] ;Size of string
	MOV				ESI, [EBP + 12] ;First character of string
	ADD				ESI, ECX		;Move to last character of string
	SUB				ESI, 1			;Move back one position so we dont start from the null

	;use EDI to accumulate the SDWORD value converted from the string digit by digit
	MOV				EDI, 0

_processingLoop:

	;Put the current character in Al
	LODSB

	;If we are not on the first character of string, jump ahead.
	CMP				ECX, 1
	JNE				_dont_check_sign

	;If there is only one character in the string, require it to be a numerical value
	PUSH			EAX
	MOV				EAX, [EBP + 20]
	CMP				EAX, 1
	POP				EAX
	JE				_dont_check_sign

	;Otherwise, check for a character indicated the sign of the number. ASCII for + is 43, ASCII for - is 45
	CMP				AL, 43
	JE				_positiveVal 
	CMP				AL, 45
	JE				_negativeVal
	JMP				_dont_check_sign

_negativeVal:
	MOV				isNegative, 1
	JMP				_nextIteration

_positiveVal:
	MOV				isNegative, 0
	JMP				_nextIteration

	;If not the first char or a +/- wasnt detected, check what value this char is
_dont_check_sign:
	
	;ASCII 0 = 48, 9 = 57. Check whether we are outside this range, jump to invalid if so
	CMP				AL, 48
	JNGE			_invalid
	CMP				AL, 57
	JNLE			_invalid

	;If a valid character, subtract 48 from the ascii value to get the numerical value. Store in EBX
	SUB				AL, 48
	MOVZX			EBX, AL 

	;Preserve ECX value for the outer loop
	PUSH			ECX

	;Find what place in the number we are looking at. Place = (Number of Bytes Read) - ECX
	MOV				EAX, [EBP + 20]
	SUB				EAX, ECX

	;If we are at the 1s place, no need to scale
	CMP				EAX, 0
	JE				_mul_done

	;Otherwise, place value = 10 ^ (place)
	MOV				ECX, EAX
	MOV				EAX, 1
	
	;Do exponentation by looping multiplication
_exponentiation:
	MOV				EDX, 10
	MUL				EDX
	JC				_pop_and_invalid	;Make sure this multiplication doesnt carry, would mean input was too many digits

	LOOP			_exponentiation

	;Multiple the digit value by the place value
	MUL				EBX
	JC				_pop_and_invalid	;Make sure this mulitplication doesnt carry
	MOV				EBX, EAX
	JMP				_mul_done

	;Make sure we POP ECX for stack balance before we go to invalid
_pop_and_invalid:
	POP				ECX
	JMP				_invalid

	;Jump here after figuring out what value this character in the string represents
_mul_done:
	;Restore ECX to continue the main outer loop
	POP				ECX

	;Accumulate the value so far
	ADD				EDI, EBX
	JC				_invalid			;Make sure the addition doesnt carry

	;Check if the final value is too big for a SDWORD even though it fits into our register unsigned
	CMP				EDI, [EBP + 32] ; Abs max value for a SDWORD
	JA				_invalid

	;Jump or arrive here to continue to the next character in our string
_nextIteration:
	LOOP			_processingLoop

	;After number is assembled, check if it was positive and jump to pos
	CMP				isNegative, 1
	JNE				_pos

	;Otherwise negate and jump to done
	NEG				EDI
	JMP				_done

_pos:
	;Positive number max value is one smaller than abs(max negative value). 
	MOV				EAX, [EBP + 32]
	SUB				EAX, 1
	CMP				EDI, EAX
	JA				_invalid
	JMP				_done

	;Label to jump to in case the user entered input that was invalid (illegal symbols, too big)
_invalid:

	;Call the get string macro with a different prompt to user and jump all the way back to process the new input
	mGetString		[EBP + 28], [EBP + 12], [EBP + 16], [EBP + 20]
	JMP				_restart
		

	;If string was succesfully processed into a valid SDWORD, store the result in the output var
_done:
	MOV				ECX, EDI
	MOV				EDI, [EBP + 24]
	MOV				[EDI], ECX

	;Restore registers and flags
	POPFD
	POPAD

	;We pushed 5 references, 1 DWORD value, and 1 imm32 before calling
	RET				28

ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Description:	Takes in an SDWORD and converts it to a string of ASCII digits and prints the string.
;
; Preconditions: Uses mDisplayString macro to print the string.
;				 Buffer is large enough to contain any SDWORD.
;
; Postconditions: None, all general registers and flags preserved.
;
; Receives:	[EBP + 8]  = Input value, the number to convert to ascii digits
;			[EBP + 12] = Output reference, buffer to hold the string 
;			[EBP + 16] = Input value, size of the string buffer
;
; Returns: Prints to the terminal window. Output buffer will be modified.
; -----------------------------------------------------------------------------------------
WriteVal PROC
	LOCAL			isNegative:BYTE

	;Preserve regsisters and flags
	PUSHAD
	PUSHFD

	;Put the value into ESI
	MOV				ESI, [EBP + 8]
	CMP				ESI, 0
	JNS				_not_negative

	;If negative, set boolean and negate to work with positive number
	NEG				ESI
	MOV				isNegative, 1

_not_negative:

	;Setup for string loop, write in reverse
	STD
	MOV				EDI, [EBP + 12]
	MOV				ECX, [EBP + 16]
	ADD				EDI, ECX
	SUB				EDI, 2
	
	;Start dividing by 10 repeatedly to get one digit at a time
_div_loop:

	MOV				EAX, ESI
	MOV				EDX, 0
	MOV				EBX, 10
	DIV				EBX

	;The new number for the next iteration is our quotient
	MOV				ESI, EAX

	;Remainder is what we want to add to the string buffer
	MOV				AL, DL

	;Convert from number to ASCII and store in string buffer
	ADD				AL, 48
	STOSB

	;If all the remains is 0, we are done. Otherwise keep dividing.
	CMP				ESI, 0
	JNE				_div_loop

	;Read back what was stored in the negative flag.
	CMP				isNegative, 1
	JNE				_no_neg_sign

	;If negative number, add a minus sign to the string
	MOV				AL, 45
	STOSB

_no_neg_sign:

	;Move forward one index in EDI to get back to string start, pass in this reference to mDisplayString
	ADD				EDI, 1
	mDisplayString	EDI
	
	;Restore regsisters and flags
	POPFD
	POPAD

	;We pushed 1 reference and 2 DWORDS before calling
	RET				12

WriteVal ENDP


; ---------------------------------------------------------------------------------
; Name: calcAvg
;
; Description: Calculates the sum and truncated average of all elements in an array.
;
; Preconditions: Sum of all digits must be within the range of an SDWORD.
;
; Postconditions: None, all registers and flags preserved.
;
; Receives:	[EBP + 8]  = Input reference to an array of values
;			[EBP + 12] = Input value, the number of elements in the array
;			[EBP + 16] = Output reference, sum of all values in the array
;			[EBP + 20] = Output reference, truncated average of all values in the array
;
; Returns: The sum and truncated average are stored in the two outputs.
; -----------------------------------------------------------------------------------------
calcAvg PROC
	
	;Set up stack frame
	PUSH			EBP
	MOV				EBP, ESP

	;Preserve registers and flags
	PUSHAD
	PUSHFD

	;Setup for looping through array
	MOV				ESI, [EBP + 8]
	MOV				ECX, [EBP + 12]
	MOV				EDI, [EBP + 16]

	;Make sure we start with 0 in our output
	MOV				EAX, 0
	MOV				[EDI], EAX

	;Loop to sum all the values into ESI
_array_sum:
	MOV				EAX, [ESI]
	ADD				[EDI], EAX
	ADD				ESI, 4

	LOOP			_array_sum

	;Find the average
	MOV				EAX, [EDI]
	CDQ							
	MOV				EBX, [EBP + 12]
	IDIV			EBX

	;Store the average
	MOV				EDI, [EBP + 20]
	MOV				[EDI], EAX

	;Restore registers and flags
	POPFD
	POPAD
	POP				EBP

	;We pushed 3x references and 1 DWORD value before calling
	RET 16


calcAvg ENDP
; (insert additional procedures here)

END main
