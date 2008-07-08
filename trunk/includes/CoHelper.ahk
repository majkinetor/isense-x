/*
CoHelper.ahk
*/

VTable(ppv, idx)
{
   Return DecodeInteger(DecodeInteger(ppv) + idx * 4)
}

DecodeInteger(ptr)
{
   Return *ptr | *++ptr << 8 | *++ptr << 16 | *++ptr << 24
}

EncodeInteger(ref, val)
{
   DllCall("ntdll\RtlFillMemoryUlong", "Uint", ref, "Uint", 4, "Uint", val)
}

Ansi2Unicode(ByRef sString, ByRef wString, nLen = 0)
{
   If !nLen
      nLen := DllCall("MultiByteToWideChar"
      , "Uint", 0
      , "Uint", 0
      , "Uint", &sString
      , "int",  -1
      , "Uint", 0
      , "int",  0)

   VarSetCapacity(wString, nLen * 2)

   DllCall("MultiByteToWideChar"
      , "Uint", 0
      , "Uint", 0
      , "Uint", &sString
      , "int",  -1
      , "Uint", &wString
      , "int",  nLen)
}

Unicode2Ansi(ByRef wString, ByRef sString, nLen = 0)
{
   pString := wString + 0 > 65535 ? wString : &wString

   If !nLen
      nLen := DllCall("WideCharToMultiByte"
      , "Uint", 0
      , "Uint", 0
      , "Uint", pString
      , "int",  -1
      , "Uint", 0
      , "int",  0
      , "Uint", 0
      , "Uint", 0)

   VarSetCapacity(sString, nLen)

   DllCall("WideCharToMultiByte"
      , "Uint", 0
      , "Uint", 0
      , "Uint", pString
      , "int",  -1
      , "str",  sString
      , "int",  nLen
      , "Uint", 0
      , "Uint", 0)
}

CLSID4ProgID(Byref CLSID, sProgID)
{
   VarSetCapacity(CLSID, 16)
   Ansi2Unicode(sProgID, wProgID)
   DllCall("ole32\CLSIDFromProgID", "str", wProgID, "str", CLSID)
}

GUID4String(Byref CLSID, sString)
{
   VarSetCapacity(CLSID, 16, 0)
   Ansi2Unicode(sString, wString, 39)
   DllCall("ole32\CLSIDFromString", "str", wString, "str", CLSID)
}

String4GUID(Byref CLSID)
{
   VarSetCapacity(wString, 39 * 2)
   DllCall("ole32\StringFromGUID2", "str", CLSID, "str", wString, "int", 39)
   Unicode2Ansi(wString, sString, 39)
   Return sString
}

CreateObject(ByRef CLSID, ByRef IID, CLSCTX = 5)
{
   If ( StrLen(CLSID) = 38 )
   GUID4String(CLSID, CLSID)
   If ( StrLen(  IID) = 38 )
   GUID4String(  IID,   IID)
   DllCall("ole32\CoCreateInstance", "str", CLSID, "Uint", 0, "Uint", CLSCTX, "str", IID, "UintP", ppv)
   Return ppv
}

GetObject(Namespace)
{
   Ansi2Unicode(Namespace, wNamespace)
   GUID4String(IID_IDispatch, "{00020400-0000-0000-C000-000000000046}")
   DllCall("ole32\CoGetObject", "str", wNamespace, "Uint", 0, "str", IID_IDispatch, "UintP", pdisp)
   Return pdisp
}

GetActiveObject(ProgID)
{
   CLSID4ProgID(CLSID, ProgID)
   DllCall("oleaut32\GetActiveObject", "str", CLSID, "Uint", 0, "UintP", punk)
   Return punk
}

SysAllocString(sString)
{
   Ansi2Unicode(sString, wString)
   Return DllCall("oleaut32\SysAllocString", "str", wString)
}

SysFreeString(pString)
{
   Return DllCall("oleaut32\SysFreeString", "Uint", pString)
}

OleInitialize()
{
   DllCall("ole32\OleInitialize", "Uint", 0)
}

OleUninitialize()
{
   DllCall("ole32\OleUninitialize")
}

CoInitialize()
{
   DllCall("ole32\CoInitialize", "Uint", 0)
}

CoUninitialize()
{
   DllCall("ole32\CoUninitialize")
}

QueryInterface(ppv, ByRef IID)
{
   If ( StrLen(IID) = 38 )
   GUID4String(IID,   IID)
   DllCall(DecodeInteger(DecodeInteger(ppv)), "Uint", ppv, "str", IID, "UintP", ppv)
   Return ppv
}

AddRef(ppv)
{
   Return DllCall(DecodeInteger(DecodeInteger(ppv) + 4), "Uint", ppv)
}

Release(ppv)
{
   Return DllCall(DecodeInteger(DecodeInteger(ppv) + 8), "Uint", ppv)
}

QueryService(ppv, ByRef SID, ByRef IID)
{
   If ( StrLen(SID) = 38 )
   GUID4String(SID,   SID)
   If ( StrLen(IID) = 38 )
   GUID4String(IID,   IID)
   GUID4String(IID_IServiceProvider, "{6D5140C1-7436-11CE-8034-00AA006009FA}")
   DllCall(DecodeInteger(DecodeInteger(ppv)), "Uint", ppv, "str", IID_IServiceProvider, "UintP", psp)
   DllCall(DecodeInteger(DecodeInteger(psp) + 12), "Uint", psp, "str", SID, "str", IID, "UintP", ppv)
   DllCall(DecodeInteger(DecodeInteger(psp) +  8), "Uint", psp)
   Return ppv
}

