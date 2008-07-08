ISense_TrimLeft(byRef pTxt)
{

	loop, % StrLen(pTxt)
	{
		c := chr( *(&pTxt + A_Index-1) )
		if (c=A_Space OR c=A_Tab)
			continue

		StringTrimLeft, pTxt, pTxt, A_Index-1
		return
	}

	return ""
}

;----------------------------------------------------------------------------------------------
; Returns position of first delimiter encountered in the text
;
ISense_GetNextDelimiter( pTxt, pDelims, pOffset=0 )
{

	loop, % StrLen( pTxt ) - pOffset
	{
		c := chr( *(&pTxt + A_Index - 1 + pOffset)  )

		if c in %pDelims%
			return A_Index + pOffset
	}
	return 0
}

;----------------------------------------------------------------------------------------------

ISense_Trace(pMsg, add = false)
{	global
	static last

	if (add)
		pMsg := last . pMsg  

	if (ISense_trace)
		ToolTip, %pMsg%, 0, 0 

	last := pMsg
}

;----------------------------------------------------------------------------------------------

ISense_ExtractInteger(ByRef pSource, pOffset = 0, pIsSigned = false, pSize = 4)
{
	Loop %pSize% 
		result += *(&pSource + pOffset + A_Index-1) << 8*(A_Index-1)
	if (!pIsSigned OR pSize > 4 OR result < 0x80000000)
		return result
	return -(0xFFFFFFFF - result + 1)
}

ISense_InsertInteger(pInteger, ByRef pDest, pOffset = 0, pSize = 4)
{
    Loop %pSize%  ; Copy each byte in the integer into the structure as raw binary data.
        DllCall("RtlFillMemory", "UInt", &pDest + pOffset + A_Index-1, "UInt", 1, "UChar", pInteger >> 8*(A_Index-1) & 0xFF)
}
