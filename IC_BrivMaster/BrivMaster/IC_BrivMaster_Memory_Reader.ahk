;A basic memory class by RHCP. Irisiri - this is separated as it is used by the relay script, and we don't want that to have to load too much bloat along the way. Comments stripped for the same reason; see original SH copy if wanted. 
class _IC_BrivMaster_Memory_Reader_Class
{
	; List of useful accessible values. Some of these inherited values (the non objects) are set when the new operator is used
	static baseAddress, hProcess, PID
	, attached:=false
	, readStringLastError:=false
	, aTypeSize:={    "UChar":    1,  "Char":     1
					,   "UShort":   2,  "Short":    2
					,   "UInt":     4,  "Int":      4
					,   "UFloat":   4,  "Float":    4
					,   "Int64":    8,  "Double":   8}  
	, aRights:={  "PROCESS_ALL_ACCESS": 0x001F0FFF
				,   "PROCESS_CREATE_PROCESS": 0x0080
				,   "PROCESS_CREATE_THREAD": 0x0002
				,   "PROCESS_DUP_HANDLE": 0x0040
				,   "PROCESS_QUERY_INFORMATION": 0x0400
				,   "PROCESS_QUERY_LIMITED_INFORMATION": 0x1000
				,   "PROCESS_SET_INFORMATION": 0x0200
				,   "PROCESS_SET_QUOTA": 0x0100
				,   "PROCESS_SUSPEND_RESUME": 0x0800
				,   "PROCESS_TERMINATE": 0x0001
				,   "PROCESS_VM_OPERATION": 0x0008
				,   "PROCESS_VM_READ": 0x0010
				,   "PROCESS_VM_WRITE": 0x0020
				,   "SYNCHRONIZE": 0x00100000}

	__new(program, byRef handle:="") ;TODO: Change this to only work with a PID, and find the PID if needed elsewhere?
	{         
		if(this.PID:=handle:=this.findPID(program)) ; set handle to 0 if program not found
		{
			dwDesiredAccess:=this.aRights.PROCESS_QUERY_INFORMATION | this.aRights.PROCESS_VM_OPERATION | this.aRights.PROCESS_VM_READ | this.aRights.SYNCHRONIZE | this.aRights.PROCESS_SUSPEND_RESUME ;SYNCHRONIZE is for use with isHandleValid(), which we are not currently using - but possibly should be
			if this.hProcess:=handle:=this.OpenProcess(this.PID, dwDesiredAccess) ; NULL/Blank if failed to open process for some reason
			{
				this.pNumberOfBytesRead:=DllCall("GlobalAlloc", "UInt", 0x0040, "Ptr", A_PtrSize, "Ptr") ; 0x0040 initialise to 0
				this.readStringLastError:=false
				this.attached:=true
				this.BaseAddress:=this.getModuleBaseAddress() ;If script is 64 bit, getModuleBaseAddress() should always work
				return this
			}
		}
		return
	}

	__delete()
	{
		this.closeHandle(this.hProcess)
		if this.pNumberOfBytesRead
			DllCall("GlobalFree", "Ptr", this.pNumberOfBytesRead)
		return
	}

	findPID(program) ;Irisiri - removed WindowMatchMode parameter handling as we always use 3
	{
		if RegExMatch(program, "i)\s*AHK_PID\s+(0x[[:xdigit:]]+|\d+)", pid) ;If user passes an AHK_PID, don't bother searching. There are cases where searching windows for PIDs wont work - console apps
			return pid1
		mode:=A_TitleMatchMode
		SetTitleMatchMode, 3
		WinGet, pid, pid, %program%
		SetTitleMatchMode, %mode%    ; In case executed in autoexec

		; If use 'ahk_exe test.exe' and winget fails (which can happen when setSeDebugPrivilege is required),
		; try using the process command. When it fails due to setSeDebugPrivilege, setSeDebugPrivilege will still be required to openProcess
		; This should also work for apps without windows.
		if (!pid && RegExMatch(program, "i)\bAHK_EXE\b\s*(.*)", fileName))
		{
			; remove any trailing AHK_XXX arguments
			filename := RegExReplace(filename1, "i)\bahk_(class|id|pid|group)\b.*", "")
			filename := trim(filename)    ; extra spaces will make process command fail       
			; AHK_EXE can be the full path, so just get filename
			SplitPath, fileName , fileName
			if (fileName) ; if filename blank, scripts own pid is returned
			{
				process, Exist, %fileName%
				pid := ErrorLevel
			}
		}
		return pid ? pid : 0 ; PID is null on fail, return 0
	}

	isHandleValid() ;TODO: Not used by BM, but possibly should be...
	{
		return 0x102 = DllCall("WaitForSingleObject", "Ptr", this.hProcess, "UInt", 0)
		; WaitForSingleObject return values
		; -1 if called with null hProcess (sets lastError to 6 - invalid handle)
		; 258 / 0x102 WAIT_TIMEOUT - if handle is valid (process still running)
		; 0  WAIT_OBJECT_0 - if process has terminated        
	}

	openProcess(PID, dwDesiredAccess)
	{
		r:=DllCall("OpenProcess", "UInt", dwDesiredAccess, "Int", False, "UInt", PID, "Ptr")
		return r ? r : "" ;If fails with 0x5 ERROR_ACCESS_DENIED (when setSeDebugPrivilege() is req.), the func. returns 0 rather than null!! Set it to null. If fails for another reason, then it is null.
	}   

	closeHandle(hProcess)
	{
		return DllCall("CloseHandle", "Ptr", hProcess)
	}

	numberOfBytesRead()
	{
		return !this.pNumberOfBytesRead ? -1 : NumGet(this.pNumberOfBytesRead+0, "Ptr")
	}

	read(address, type:="UInt", aOffsets*)
	{
		result:=""
		if(!this.aTypeSize.hasKey(type)) ;If invalid type RPM() returns success (as bytes to read resolves to null in dllCall()) so set errorlevel to invalid parameter for DLLCall() i.e. -2
			return "", ErrorLevel:=-2 
		if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", aOffsets.maxIndex() ? this.getAddressFromOffsets(address, aOffsets*) : address, type "*", result, "Ptr", this.aTypeSize[type], "Ptr", this.pNumberOfBytesRead)
			return result
		return        
	}

	readString(address, sizeBytes := 0, encoding:="UTF-8", aOffsets*)
	{
		bufferSize := VarSetCapacity(buffer, sizeBytes ? sizeBytes : 100, 0)
		this.ReadStringLastError := False
		if aOffsets.maxIndex()
			address := this.getAddressFromOffsets(address, aOffsets*)
		if !sizeBytes  ; read until null terminator is found or something goes wrong
		{
			; Even if there are multi-byte-characters (bigger than the encodingSize i.e. surrogates) in the string, when reading in encodingSize byte chunks they will never register as null (as they will have bits set on those bytes)
			if (encoding = "utf-16" || encoding = "cp1200")
				encodingSize := 2, charType := "UShort", loopCount := 2
			else encodingSize := 1, charType := "Char", loopCount := 4
			Loop
			{   ; Lets save a few reads by reading in 4 byte chunks
				if !DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", address + ((outterIndex := A_index) - 1) * 4, "Ptr", &buffer, "Ptr", 4, "Ptr", this.pNumberOfBytesRead) || ErrorLevel
					return "", this.ReadStringLastError := True 
				else loop, %loopCount%
				{
					if NumGet(buffer, (A_Index - 1) * encodingSize, charType) = 0 ; NULL terminator
					{
						if (bufferSize < sizeBytes := outterIndex * 4 - (4 - A_Index * encodingSize)) 
							VarSetCapacity(buffer, sizeBytes)
						break, 2
					}  
				} 
			}
		}
		if DllCall("ReadProcessMemory", "Ptr", this.hProcess, "Ptr", address, "Ptr", &buffer, "Ptr", sizeBytes, "Ptr", this.pNumberOfBytesRead)   
			return StrGet(&buffer,, encoding)  
		return "", this.ReadStringLastError := True             
	}
	
	pointer(address,finalType:="UInt",offsets*)
	{ 
		For index, offset in offsets
			address := this.Read(address,"Int64") + offset 
		Return this.Read(address, finalType)
	}

	getAddressFromOffsets(address, aOffsets*)
	{
		return aOffsets.Remove() + this.pointer(address,"Int64",aOffsets*) ; remove the highest key so can use pointer() to find final memory address (minus the last offset)       
	}

	getModuleBaseAddress(moduleName:="")
	{
		if (moduleName=="")
			moduleName:=this.GetModuleFileNameEx(0, True) ; main executable module of the process - get just fileName no path
		if r:=this.getModules(aModules, True) < 0
			return r ; -4, -3
		return aModules.HasKey(moduleName) ? aModules[moduleName].lpBaseOfDll : -1
		; no longer returns -5 for failed to get module info
	}  

	suspend()
	{
		return DllCall("ntdll\NtSuspendProcess", "Ptr", this.hProcess)
	}  

	resume()
	{
		return DllCall("ntdll\NtResumeProcess", "Ptr", this.hProcess)
	} 

	getModules(byRef aModules, useFileNameAsKey:=False)
	{
		aModules:=[]
		if !moduleCount:=this.EnumProcessModulesEx(lphModule)
			return -3  
		loop % moduleCount
		{
			this.GetModuleInformation(hModule := numget(lphModule, (A_index - 1) * A_PtrSize), aModuleInfo)
			aModuleInfo.Name := this.GetModuleFileNameEx(hModule)
			filePath := aModuleInfo.name
			SplitPath, filePath, fileName
			aModuleInfo.fileName := fileName
			if useFileNameAsKey
				aModules[fileName] := aModuleInfo
			else aModules.insert(aModuleInfo)
		}
		return moduleCount        
	}

	GetModuleFileNameEx(hModule:=0, fileNameNoPath:=False)
	{
		; ANSI MAX_PATH = 260 (includes null) - unicode can be ~32K.... but no one would ever have one that size
		; So just give it a massive size and don't bother checking. Most coders just give it MAX_PATH size anyway
		VarSetCapacity(lpFilename, 2048 * (A_IsUnicode ? 2 : 1)) 
		DllCall("psapi\GetModuleFileNameEx"
					, "Ptr", this.hProcess
					, "Ptr", hModule
					, "Str", lpFilename
					, "Uint", 2048 / (A_IsUnicode ? 2 : 1))
		if fileNameNoPath
			SplitPath, lpFilename, lpFilename ; strips the path so = GDI32.dll

		return lpFilename
	}

	EnumProcessModulesEx(byRef lphModule, dwFilterFlag:=0x03)
	{
		reqSize := ""
		lastError := A_LastError
		size := VarSetCapacity(lphModule, 4)
		loop 
		{
			DllCall("psapi\EnumProcessModulesEx"
						, "Ptr", this.hProcess
						, "Ptr", &lphModule
						, "Uint", size
						, "Uint*", reqSize
						, "Uint", dwFilterFlag)
			if ErrorLevel
				return 0
			else if (size >= reqSize)
				break
			else size := VarSetCapacity(lphModule, reqSize)  
		}
		; On first loop it fails with A_lastError = 0x299 as its meant to
		; might as well reset it to its previous version
		DllCall("SetLastError", "UInt", lastError)
		return reqSize // A_PtrSize ; module count  ; sizeof(HMODULE) - enumerate the array of HMODULEs     
	}

	GetModuleInformation(hModule, byRef aModuleInfo)
	{
		VarSetCapacity(MODULEINFO, A_PtrSize * 3), aModuleInfo := []
		return DllCall("psapi\GetModuleInformation"
					, "Ptr", this.hProcess
					, "Ptr", hModule
					, "Ptr", &MODULEINFO
					, "UInt", A_PtrSize * 3)
				, aModuleInfo := {  lpBaseOfDll: numget(MODULEINFO, 0, "Ptr")
								,   SizeOfImage: numget(MODULEINFO, A_PtrSize, "UInt")
								,   EntryPoint: numget(MODULEINFO, A_PtrSize * 2, "Ptr") }
	}
}