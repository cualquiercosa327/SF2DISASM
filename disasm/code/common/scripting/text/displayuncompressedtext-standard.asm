
; ASM FILE code\common\scripting\text\displayuncompressedtext-standard.asm :
; Display uncompressed text function

; =============== S U B R O U T I N E =======================================

; Display any prefixed with length string in the dialogue window.

; In: a0 = names table pointer, d0.w = number of names, DIALOGUE_NAME_INDEX_1 = name index


namesNumber = -6
tablePointer = -4

DisplayUncompressedText:
                
                movem.l d0-a6,-(sp)
                link    a6,#-6
                move.l  a0,tablePointer(a6)
                move.w  d0,namesNumber(a6)
                bsr.w   CreateDialogueWindow
                move.b  #1,((CURRENTLY_TYPEWRITING-$1000000)).w
                clr.b   ((DIALOGUE_REGULAR_TILE_TOGGLE-$1000000)).w
                move.l  #DIALOGUE_NAME_INDEX_1,((CURRENT_DIALOGUE_NAME_INDEX_ADDRESS-$1000000)).w
                move.b  #1,((USE_REGULAR_DIALOGUE_FONT-$1000000)).w
                
                ; Clear window
                bsr.w   ClearDialogueWindowLayout
                move.w  ((DIALOGUE_WINDOW_INDEX-$1000000)).w,d0
                subq.w  #1,d0
                move.w  d0,-(sp)
                bsr.w   GetWindowEntryAddress
                movea.l (a0),a1
                bsr.w   LoadDialogueWindowLayout
                move.w  (sp)+,d0
                move.w  #$8080,d1
                bsr.w   SetWindowDestination
                bsr.w   WaitForVInt
                
                bsr.w   GetCurrentDialogueNameIndex ; get text name index -> d1.w
                tst.w   namesNumber(a6)
                bmi.s   @Text               ; skip to @Text if names number parameter = -1
                cmp.w   namesNumber(a6),d1
                bhi.s   @Number
                
                ; Load ASCII string
@Text:          movea.l tablePointer(a6),a0
                jsr     FindName
                bsr.w   CopyAsciiBytesForDialogueString
                bra.s   @Print_Loop
                
                ; Write number if exceeding the threshold set by the names number parameter
@Number:        moveq   #0,d0
                move.w  d1,d0
                bsr.w   WriteAsciiNumber
                lea     ((DIALOGUE_STRING_TO_PRINT-$1000000)).w,a1
                move.l  a1,((CURRENT_DIALOGUE_ASCII_BYTE_ADDRESS-$1000000)).w
                lea     ((LOADED_NUMBER-$1000000)).w,a0
                moveq   #9,d1
                
@CopyNumber_Loop:
                clr.w   d0
                move.b  (a0)+,d0
                cmpi.b  #32,d0
                beq.s   @Skip
                move.b  d0,(a1)+
@Skip:          dbf     d1,@CopyNumber_Loop
                
                clr.b   (a1)
                
@Print_Loop:    bsr.w   GetNextTextSymbol
                bset    #0,((DIALOGUE_REGULAR_TILE_TOGGLE-$1000000)).w
                bne.s   @Continue
                cmpi.b  #2,((DIALOGUE_TYPEWRITING_CURRENT_X-$1000000)).w
                beq.s   @Continue
                st      ((DIALOGUE_TYPEWRITING_CURRENT_X-$1000000)).w
                
@Continue:      bsr.w   ApplyAutomaticNewDialogueLine
                bsr.w   SymbolsToGraphics
                bsr.w   HandleDialogueTypewriting
                tst.l   ((CURRENT_DIALOGUE_ASCII_BYTE_ADDRESS-$1000000)).w
                bne.s   @Print_Loop
                
                clr.b   ((CURRENTLY_TYPEWRITING-$1000000)).w
                unlk    a6
                movem.l (sp)+,d0-a6
                rts

    ; End of function DisplayUncompressedText
