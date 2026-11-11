;Memory related functions, excluding the actual reader as that needs to be separate so the Relay can #include only that
#include %A_LineFile%\..\IC_BrivMaster_Memory_Reader.ahk

class IC_BrivMaster_EngineSettings_Class extends IC_BrivMaster_Memory_Static_Pointer_Class ;EngineSettings class contains IC's EngineSettings class structure. Useful for finding webroot for doing server calls.
{
    Refresh()
    {
        if (!_IBM_MM.IsAttached) ;Don't build offsets if no client is available to check variable types.
            return
        baseAddress:=_IBM_MM.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.BasePtr.BaseAddress!=baseAddress)
        {
            this.BasePtr.BaseAddress:=baseAddress
            if (this.UnityGameEngine=="")
            {
                this.UnityGameEngine:={}
                this.UnityGameEngine.Core:={}
                this.UnityGameEngine.Core.EngineSettings:=new IBM_GOS(this.StructureOffsets)
                this.UnityGameEngine.Core.EngineSettings.BasePtr:=new IC_BrivMaster_Memory_Base_Pointer_Class(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                #include *i %A_LineFile%\..\Offsets\IC_EngineSettings_Import.ahk
                return
            }
            this.UnityGameEngine.Core.EngineSettings.BasePtr:=new IC_BrivMaster_Memory_Base_Pointer_Class(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets, "EngineSettings")
            this.ResetBasePtr(this.UnityGameEngine.Core.EngineSettings)
        }
    }
}

class IC_BrivMaster_GameSettings_Class extends IC_BrivMaster_Memory_Static_Pointer_Class ;GameSettings class contains IC's GameSettings class structure. Useful for finding details for doing server calls
{
    Refresh()
    {
        if (!_IBM_MM.IsAttached) ;Don't build offsets if no client is available to check variable types.
            return
        baseAddress:=_IBM_MM.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.BasePtr.BaseAddress!=baseAddress)
        {
            this.BasePtr.BaseAddress:=baseAddress
            if (this.CrusadersGame=="")
            {
                this.CrusadersGame:={}
                this.CrusadersGame.GameSettings:=new IBM_GOS(this.StructureOffsets)
                this.CrusadersGame.GameSettings.BasePtr:=new IC_BrivMaster_Memory_Base_Pointer_Class(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
                #include *i %A_LineFile%\..\Offsets\IC_GameSettings_Import.ahk
                return
            }
            this.CrusadersGame.GameSettings.BasePtr := new IC_BrivMaster_Memory_Base_Pointer_Class(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets, "GameSettings")
            this.ResetBasePtr(this.CrusadersGame.GameSettings)
        }
    }
}

class IC_BrivMaster_IdleGameManager_Class extends IC_BrivMaster_Memory_Pointer_Class ;GameManager class contains the in game data structure layout
{
    Refresh()
    {
        if (!_IBM_MM.IsAttached) ;Don't build offsets if no client is available to check variable types
            return
        baseAddress:=_IBM_MM.baseAddress["mono-2.0-bdwgc.dll"]+this.ModuleOffset
        if (this.BasePtr.BaseAddress!=baseAddress)
        {
            this.BasePtr.BaseAddress:=baseAddress
            if (this.IdleGameManager=="")
            {
                this.IdleGameManager:=New IBM_GOS(this.StructureOffsets)
                this.IdleGameManager.BasePtr:=new IC_BrivMaster_Memory_Base_Pointer_Class(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets, "IdleGameManager")
                #include *i %A_LineFile%\..\Offsets\IC_IdleGameManager_Import.ahk
                return
            }
            ;Objects exist, update memory addresses only. Note: Once imports have been built, IdleGameManager is no longer used for GameObjects. Structure builds from this -> this.game, NOT this.IdleGameManager.game
            this.IdleGameManager.BasePtr:=new IC_BrivMaster_Memory_Base_Pointer_Class(this.BasePtr.BaseAddress, this.ModuleOffset, this.StructureOffsets)
            this.ResetBasePtr(this.IdleGameManager)
        }
    }
}

class IC_BrivMaster_Memory_Static_Pointer_Class extends IC_BrivMaster_Memory_Pointer_Class
{
    staticOffset:=0

    __new(moduleOffset := 0, staticOffset:=0, structureOffsets:=0)
    {
        this.ModuleOffset:=moduleOffset + 0  ;Do maths on strings created by json to make sure they are values, otherwise memory leaks can occur in memory reads
        this.StaticOffset:=staticOffset + 0
        if(structureOffsets.Count() > 0)
        {
            size:=structureOffsets.Count()
            loop, %size%
            {
                structureOffsets[A_Index]:=structureOffsets[A_Index] + 0
            }
        }
        else
            structureOffsets:=structureOffsets + 0
        this.structureOffsets:=structureOffsets
        this.Refresh()
    }
}

class IC_BrivMaster_Memory_Base_Pointer_Class
{
    ModuleOffset:=0
    StructureOffsets:=0
    BaseAddress:=""

    __new(baseAddress:=0, moduleOffset:=0, structureOffsets:=0, className:="")
    {
        this.BaseAddress:=baseAddress
        this.ModuleOffset:=moduleOffset
        this.StructureOffsets:=structureOffsets
        this.ClassName:=className
    }
}

class IC_BrivMaster_Memory_Pointer_Class
{
    ModuleOffset:=0
    StructureOffsets:=0
    BasePtr:={}

    __new(moduleOffset:=0, structureOffsets:=0)
    {
        this.ModuleOffset:=moduleOffset=="" ? "" : moduleOffset + 0 ;Do maths on strings created by json to make sure they are values, otherwise memory leaks can occur in memory reads.

        if(structureOffsets.Count() > 0)
        {
            size:=structureOffsets.Count()
            loop, %size%
            {
                structureOffsets[A_Index] := structureOffsets[A_Index] + 0
            }
        }
        else
            structureOffsets:=structureOffsets + 0
        this.StructureOffsets:=structureOffsets
        this.Refresh()
    }

    ResetBasePtr(currentObj)
    {
        this["basePtr"] := currentObj.BasePtr
        for k,v in this
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "IBM_GOS" AND v.FullOffsets != "")
            {
                v.BasePtr:=currentObj.BasePtr
                v.ResetBasePtr(this) ; Go into game objects
            }
        }
    }

    Refresh() ;Scaffolding
	{ 
    }

    ResetUnstableCollectionsOnly()
    {
        for k,v in this
        {
            if(!IsObject(v) OR !ObjGetBase(v).__Class=="IBM_GOS" OR k=="BasePtr")
                continue
            else
                this[k].ResetUnstableCollectionsOnly()
        }
    }
}
     
class IBM_GOS ;Class used to describe memory locations. Updated to be 64-bit only. GameObjectStructure per the original, and given a short name as it's in every line of imports and saving a few bytes is saving a few bytes
{
    ;Reserved words for IBM_GOS. Imports with same name will cause unpredictable behavior.
    FullOffsets:=Array()		; Full list of offsets required to get from base pointer to this object
    ValueType:="Int"            ; ValueType describes what kind of data is at the location in memory. Note: "List", "Dict", "Stack", "Queue" and "HashSet" are not a memory data type but are being used to identify conditions such as when a ListIndex must be added.
    Offset:=0x0                 ; The offset from last object to this object.
    IsAddedIndex:=false         ; __Get lookups on non-existent keys will create key objects with this value being true. Prevents cloning non-existent values.
    _CollectionKeyType:=""
    _CollectionValType:=""
    BasePtr:={}
    LastDictVersion:=""
    LastDictVersionByKey:={}
    StartAtLastPos:=False
    LastDictIndex:={}
    DictionaryObject:={}
    static LastDictPos:=0
    static ReadIsLocked:=False
    static InvalidDictionaryKeyString:="<invalid key>"
    static SystemTypes:={ "System.Byte" : "Char"
        ,"System.UByte" : "UChar"
        ,"System.Short" : "Short"
        ,"System.UShort" : "UShort"
        ,"System.Int32" : "Int"
        ,"System.UInt32" : "UInt"
        ,"System.Int64" : "Int64"
        ,"System.Enum" : "Int"
        ,"System.UInt64" : "Int64"
        ,"System.Single" : "Float"
        ,"System.USingle" : "UFloat"
        ,"System.Double" : "Double"
        ,"System.Boolean" : "Char"
        ,"System.String" : "UTF-16"
        ,"Engine.Numeric.Quad" : "Quad" }
    static ValueTypeToBytes := { "Char": 0x4, "UChar": 0x4, "Short": 0x4
                                , "UShort": 0x4, "Int": 0x4, "UInt": 0x4
                                , "Int64": 0x8, "UInt64": 0x8, "Float": 0x4
                                , "UFloat": 0x4, "Double": 0x8, "Char": 0x4, "UTF-16" : 0x8, "Quad": 0x10 }

     __new(baseStructureOrFullOffsets, ValueType := "Int", appendedOffsets*) ;Creates a new instance of IBM_GOS
    {
        this.ValueType:=ValueType
        if(appendedOffsets[1]) ; Copy base and add offset
        {
            this.BasePtr:=baseStructureOrFullOffsets.BasePtr
            this.Offset:=appendedOffsets[1]
            this.FullOffsets:=baseStructureOrFullOffsets.FullOffsets.Clone()
            this.FullOffsets.Push(this.Offset*)
        }
        else
            this.FullOffsets.Push(baseStructureOrFullOffsets*)
    }

    ; BEWARE of cases where you may be looking in a dictionary for a key that is the same as a value of the object in the dictionary (e.g. dictionary["Effect"].Effect)
    ; When a key is not found for objects which have collections, use this function.
    __Get(key, index:=0, startAtLastPos:=False, byteSizeOverride:=0x0) ;TODO: Why does this assign to returnObj which is never used?
    {
        static notificationSet:=False
        this.StartAtLastPos:=startAtLastPos ;Always default to false unless set otherwise
        ; Properties are not found using HasKey().
        if(key=="" OR key=="_ArrayDimensions")
            return returnObj:=this.ReturnGameObject("")
        else if(key=="size") ;size attempts to find choose the offset for the size of the collection and return a IBM_GOS that has that offset included.
            return returnObj:=this.ReturnGameObject(this.CreateSizeObject())
        else if(key=="_head" AND this.ValueType=="Queue")
            return returnObj:=this.ReturnGameObject(this.CreateHeadObject())
        else if (key=="__version")
            return returnObj:=this.ReturnGameObject(this.CreateVersionObject())
        ;if(this.ValueType=="Dict" OR this.ValueType=="SortedDict")  ;Special case for Dictionary collections in a gameobject. Store dictionary items with keys that have a system type to speed up future lookups. Do not store unstable keys.
        ;    return returnObj:=this.ReturnGameObject(this.GetDictionaryObject(key, index))
		if(this.ValueType=="Dict")  ;Special case for Dictionary collections in a gameobject. Store dictionary items with keys that have a system type to speed up future lookups. Do not store unstable keys. Irisiri - version without SortedDict as it is not used
            return returnObj:=this.ReturnGameObject(this.GetDictionaryObject(key, index))
        else if(this.ValueType=="List" OR this.ValueType=="Stack" OR this.ValueType=="Queue") ;Special case for List/Stack/Queue collections in a gameobject.
		{
            if ((resultObject:=this.HandleListStackQueue(key))!="")
                return returnObj:=this.ReturnGameObject(resultObject)
        }
        else if (this.ValueType== "HashSet")
		{
            if key is not integer ;Don't try to create key objects when keys are invalid
                return returnObj:=this.ReturnGameObject("")
            this.UpdateCollectionOffsets(key, 0x18, this.CalculateHashSetOffset(key) + 0)
            return returnObj:=this.ReturnGameObject(this[key])
        }
        else if key is number
        {
            this.UpdateCollectionOffsets(key, "", (this.CalculateArrayOffset(key,, byteSizeOverride) + 0))
            return returnObj:=this.ReturnGameObject(this[key])
        }
        return returnObj:=this.ReturnGameObject("")
    }

    GetOffsets() ; Returns the full offsets of this object after BaseAddress.
	{
        return this.FullOffsets
    }

    CreateSizeObject()
    {
        ; TODO: (from Anti) Check HashSet<T> variations that appear to have 0x20, 0x30 for "count"
        sizeObject := this.QuickClone()
        sizeObject.ValueType := "Int"
        if(this.ValueType == "Stack")
            sizeObject.FullOffsets.Push(0x20)
        else if(this.ValueType == "Queue")
            sizeObject.FullOffsets.Push(0x28)
        else if(this.ValueType == "Dict")
            sizeObject.FullOffsets.Push(0x40)
        ;else if(this.ValueType == "SortedDict") ;Irisiri - SortedDict not used
        ;    sizeObject.FullOffsets.Push(0x20,0x30)
        else if(this.ValueType == "HashSet")
            sizeObject.FullOffsets.Push(0x30)
        else
        { ; Assume Array / this.ValueType == "List"
            sizeObject.ValueType:=this.ValueType ;TODO: Why does this overwrite the Int type with array/list type? The size can only be an Int?
            sizeObject.FullOffsets.Push(0x18)
        }
        return sizeObject
    }

    ; Create an object to read the head of a Queue.
    CreateHeadObject()
    {
        headObject:=this.QuickClone()
        headObject.FullOffsets.Push(0x20)
        return headObject
    }

    CreateVersionObject()
    {
        versionObject:=this.QuickClone()
        versionObject.ValueType:="Int"
        if(this.ValueType == "Stack")
            versionObject.FullOffsets.Push(0x2C)
        else if(this.ValueType == "List")
            versionObject.FullOffsets.Push(0x1C)
        else if(this.ValueType == "Queue")
            versionObject.FullOffsets.Push(0x28)
        else if(this.ValueType == "Dict")
            versionObject.FullOffsets.Push(0x4C)
        ;else if(this.ValueType == "SortedDict") ;Irisiri - SortedDict not used
        ;    sizeObject.FullOffsets.Push(0x20,0x30) ;This was 0x20,0x3, which seems unlikely as not 4-byte aligned? We don't actually use any of these to test with
        else if(this.ValueType == "HashSet")
            versionObject.FullOffsets.Push(0x104)
        else ; Unsupported ValueType
            return ""
        return versionObject
    }

    HandleListStackQueue(key)
    {
        IBM_GOS.ReadIsLocked:=True ;Lock before creating list/stack/queue collections
        if key is number
        {
            offset := this.CalculateOffset(key) + 0
            this.UpdateCollectionOffsets(key, 0x10, offset)
            return returnObj := this.ReturnGameObject(this[key])
        }
        else if (key=="_items")
        {
            _items:=this.StableClone()
            _items.FullOffsets.Push(0x10)
            _items.ValueType:="Int64"
            return returnObj:=this.ReturnGameObject(_items)
        }
        return returnObj := this.ReturnGameObject("")
    }

    GetDictionaryObject(key, index)
    {
        IBM_GOS.ReadIsLocked:=True                                            				; Lock gameobject reads while a dictionary is being built
        if(IsObject(key) AND key.Count()==2)
            key:=key[1], index:=key[2]
        isUnstable:=IBM_GOS.SystemTypes[this._CollectionKeyType] == ""        				; Check if Key value is not a known type - Unstable is a dictionary of pointers that can change k,v pairs often.
        if(isUnstable AND this.DoesCollectionNeedReset())
            this.ResetCollection()
        if (key=="key")
        {
            offset:=this.CalculateDictOffset(["key",index]) + 0                         	; Expected offset to the key for the <index>th entry.
            keyReadObj:=this.GetKeyObj(index)
            offsetInsertLoc:=keyReadObj.FullOffsets.Count() + 1,                          	; Current offsets count
            this.UpdateChildrenWithFullOffsets(keyReadObj, offsetInsertLoc, [0x18, offset])	; Update all sub-objects with their missing collection/item offsets.
            return returnObj:=this.ReturnGameObject(keyReadObj)                             ; return temporary key object
        }
        else if (key=="value")
        {
            offset:=this.CalculateDictOffset(["value",index]) + 0                           ; Expected offset to the key for the <index>th entry.
            keyReadObj:=this.GetKeyObj(index)
            IBM_GOS.ReadIsLocked:=False                                      				; Disable lock before read
            key:=keyReadObj.Read()
            if(index==this.LastDictIndex[key])                                            	; Use previously created object if it is still being used.
                return this.DictionaryObject[key]                                           ; Return cached key
            else if (key=="")
                return this.ReturnGameObject("")
            else
                this.DictionaryObject[key]:=""                                            	; Clear cached key if it exists.
            IBM_GOS.ReadIsLocked:=True                                       				; Enable Lock before building entry
            this.BuildDictionaryEntry(key, index, 0x18, offset)          					; Build a dictionary entry for this key.
            return returnObj:=this.ReturnGameObject(this.DictionaryObject[key])				; return the temporary value object with access to all objects it has access to.
        }
        else
        {
            ; TODO: (from Anti) Look into feasibility of using same dictionary hash function to look up keys. (Requires DLL call?) Current method is O(n) instead of O(1)
            if(this.LastDictVersionByKey[key]!="" AND this.__version.Read()==this.LastDictVersionByKey[key])                    ; Use previously created object if it is still being used.
                return returnObj:=this.ReturnGameObject(this.DictionaryObject[key])
            keyIndex:=this.GetDictIndexOfKeyQuick(key)                                    	; Look up what index has the key entry equal to the key passed in.
            if(keyIndex < 0)                                                                ; Failed to find index, do not create an entry.
                return returnObj:=this.ReturnGameObject("")                               	; Reset read lock before returning nothing
            if(keyIndex!="" AND keyIndex==this.LastDictIndex[key])                          ; Use previously created object if it is still being used.
                return returnObj:=this.ReturnGameObject(this.DictionaryObject[key])       	; Return cached key
            else
                this.DictionaryObject[key] := ""
        }
        return returnObj := this.ReturnGameObject("")
    }

    GetKeyObj(index)
    {
        keyOffset:=this.CalculateDictOffset(["key",index]) + 0					; Expected offset to the value for the <index>th entry.
        keyReadObject:=this.QuickClone()										; temp object for lookup
        keyReadObject.FullOffsets.Push(0x18, keyOffset)							; add offsets for key
        keyReadObject.ValueType:=IBM_GOS.SystemTypes[this._CollectionKeyType]	; Update key's value type if it is known
        if (keyReadObject.ValueType=="")                                     	; Key value is not a known type which means the key is likely a pointer and subject to unpredictable changes. (Do not cache these dictionary lookups)
            keyReadObject.ValueType:="Int64"
        return keyReadObject
    }

    ReturnGameObject(object)
    {
        IBM_GOS.ReadIsLocked:=False ; Reset read lock before returning if needed
        return object
    }

    QuickClone() ; Function makes copy of the current object and its lists but not a full deep copy.
    {
        var:=new IBM_GOS(this.FullOffsets)
        var.BasePtr:=this.BasePtr.Clone() ;TODO: Why do we need to clone the base pointer, it's just a reference? Might have been something added to try to address a memory leak due to AHK reference counting?
        var.ValueType:=this.ValueType
        var.Offset:=this.Offset
        var._CollectionKeyType:=this._CollectionKeyType
        var._CollectionValType:=this._CollectionValType
        if (this._ArrayDimensions)
            var._ArrayDimensions:=this._ArrayDimensions
        return var
    }

    Clone(typeOfObject:="") ; Function makes a deep copy of the current object.
    {
        var:=new IBM_GOS(this.FullOffsets)
        for k,v in this ;Iterate all the elements of the game object structure and clone time
        {
            if(isObject(v) AND k=="DictionaryObject") ; Ignore self referential dictionary.
                continue
            else if(IsObject(v) AND k!="BasePtr") ; Keep BasePtr as a reference
                var[k]:=v.Clone()
            else
                var[k]:=v
        }
        return var
    }

    StableClone() ; For cloning without copying dynamically added items to the clone. Ignores objects with IsAddedIndex = true
    {
        var:=new IBM_GOS(this.FullOffsets)
        for k,v in this ;Iterate all the elements of the game object structure and clone them
        {
            if(isObject(v) AND k=="DictionaryObject") ; Do not copy self referential dictionary objects
                continue
            if(!IsObject(v) OR k=="BasePtr") ; Keep BasePtr as a reference
            {
                var[k] := v
                continue
            }
            if(ObjGetBase(v).__Class == "IBM_GOS" AND !v.IsAddedIndex)
                var[k]:=v.StableClone()
            else if(ObjGetBase(v).__Class != "IBM_GOS")
                var[k]:=v.Clone()
        }
        return var
    }

    BuildDictionaryEntry(key, keyindex, collectionEntriesOffset, offset)     ; Build a dictonary entry for the key.
    {
        this.DictionaryObject[key]:=""                                               ; Delete key object before building new ones.
        this.DictionaryObject.Delete(key)
        this.DictionaryObject[key]:=this.Clone()                                     ; Deep copy of this object.
        this.LastDictIndex[key]:=keyIndex                                            ; Creating new index for key; remember this index.
        this.DictionaryObject[key].IsAddedIndex:=true                                ; Stable clones won't copy this object
        offsetInsertLoc:=this.DictionaryObject[key].FullOffsets.Count() + 1,         ; Current offsets count.
        this.DictionaryObject[key].FullOffsets.Push(collectionEntriesOffset, offset)   ; Add the offsets to this object so the .Read() will give the value of the value.
        this.DictionaryObject[key].ValueType:=IBM_GOS.SystemTypes[this._CollectionValType] ? IBM_GOS.SystemTypes[this._CollectionValType] : this.DictionaryObject[key].ValueType
        this.LastDictVersionByKey[key]:=this.__version.Read()
        this.UpdateChildrenWithFullOffsets(this.DictionaryObject[key], offsetInsertLoc, [collectionEntriesOffset, offset]) ; Update all sub-objects with their missing collection/item offsets.
    }

    UpdateCollectionOffsets(key, collectionEntriesOffset, offset) ;Creates a gameobject at key, updates its offsets, copies the other values in the object to key object, propagates changes down chain of objects under key.
    {
        this[key]:=this.StableClone()
        this[key].IsAddedIndex:=true
        if (this._ArrayDimensions)
            this[key]._ArrayDimensions := this._ArrayDimensions - 1
        location := this.FullOffsets.Count() + 1
        if(collectionEntriesOffset=="") ; Array type, has no items
        {
            this[key].FullOffsets.Push(offset)
            this.UpdateChildrenWithFullOffsets(this[key], location, [offset])
        }
        else
        {
            this[key].FullOffsets.Push(collectionEntriesOffset, offset)
            this.UpdateChildrenWithFullOffsets(this[key], location, [collectionEntriesOffset, offset])
        }
    }

    UpdateChildrenWithFullOffsets(currentObj, insertLoc:=1, offset:="") ; Starting at currentObj, updates the fulloffsets variable in key and all children of key recursively.
    {
        for k,v in currentObj
        {
            if(IsObject(v) AND ObjGetBase(v).__Class=="IBM_GOS" AND v.FullOffsets!="")
            {
                v.FullOffsets.InsertAt(insertLoc, offset*)
                v.UpdateChildrenWithFullOffsets(v, insertLoc, offset)
            }
            else if (k=="DictionaryObject")
                for x,y in v
                    y.UpdateChildrenWithFullOffsets(y, insertLoc, offset)
        }
    }

    Read(valueType:="")
    {
        if(IBM_GOS.ReadIsLocked)
            return ""
        if(!valueType)
            valueType:=this.ValueType
        baseAddress:=this.BasePtr.BaseAddress ? this.BasePtr.BaseAddress + 0 : this.BasePtr.BaseAddress ; do math on non-null non-zero value to ensure number instead of string. Prevents memory leaks.
        if (baseAddress<=0)
            return ""
        if(valueType=="UTF-16") ; take offsets of string and add offset to "value" of string
        {
            offsets:=this.FullOffsets.Clone()
            offsets.Push(0x14)
            var:=_IBM_MM.instance.readstring(baseAddress, bytes:=0, valueType, offsets*) ;TODO: Why the assignment to 'bytes' here?
        }
        ;else if (valueType=="List" OR valueType=="Dict" OR valueType=="SortedDict" OR valueType=="HashSet" OR valueType=="Stack" OR valueType=="Queue") ; custom ValueTypes not in classMemory.ahk
        ;{
        ;    var:=_IBM_MM.instance.read(baseAddress, "Int", (this.GetOffsets())*)
        ;}
		else if (valueType=="List" OR valueType=="Dict" OR valueType=="HashSet" OR valueType=="Stack" OR valueType=="Queue") ; custom ValueTypes not in classMemory.ahk Irisiri - version of above with SortedDict removed as not used
        {
            var:=_IBM_MM.instance.read(baseAddress, "Int", (this.GetOffsets())*)
        }
        else if (valueType=="Array")
        {
            valueType:=IBM_GOS.SystemTypes[this._CollectionValType]
            if (this._ArrayDimensions > 0)
                valueType:="Int64"
            var := _IBM_MM.instance.read(baseAddress, , (this.GetOffsets())*)
        }
        else if (valueType == "Quad") ; custom ValueTypes not in classMemory.ahk
        {
            offsets := this.GetOffsets().Clone()
            first8 := _IBM_MM.instance.read(baseAddress, "Int64", (offsets)*)
            lastIndex := offsets.Count()
            offsets[lastIndex] := offsets[lastIndex] + 0x8
            second8 := _IBM_MM.instance.read(baseAddress, "Int64", (offsets)*)
            var := this.ConvQuadToString3( first8, second8 )
        }
		/*
        else if (valueType=="Double?") ;This is for nullable double, which BM is not currently using
        {
            var:=_IBM_MM.instance.read(baseAddress, "Double", (this.GetOffsets())*)
            if !var
            {
                offsets:=this.GetOffsets().Clone()
                lastIndex:=offsets.Count()
                offsets[lastIndex]:=offsets[lastIndex] + 0x8
                var:=_IBM_MM.instance.read(baseAddress, "Double", (offsets)*)
            }
        }
		*/
        else
        {
            var:=_IBM_MM.instance.read(baseAddress, valueType, (this.GetOffsets())*)
        }
        return var
    }

    ;==============
    ;Helper Methods
    ;==============

    CalculateOffset(listItem, indexStart:=0) ;Used to calculate offsets the offsets of an item in a list by its index value.
    {
        if(indexStart) ; If list is not 0 based indexing
            listItem--             ; AHK uses 1 based array indexing, switch to 0 based
		; Note: Some 64-bit lists will still use 4 byte offsets instead of 8.
		; Handle lists of varying size items
		hasType1:=IBM_GOS.SystemTypes[this._CollectionValType]!=""
		type1Bytes:=hasType1 ? IBM_GOS.ValueTypeToBytes[IBM_GOS.SystemTypes[this._CollectionValType]] : 0x8
		itemSize:=hasType1 ? type1Bytes : 0x8
		offset:=0x20 + (listItem*itemSize)
		return offset
    }

    CalculateDictOffset(array) ;Used to calculate offsets of an item in a dict. requires an array with "key" or "value" as first entry and the dict index as second. indices start at 0.
    {
        ; Special Case not included here:
        ; 64-Bit Entries start at 0x18
        ; Values follow rule: [0x20 + 0x10 + (index * 0x18)
        ; 0x20 = baseOffset ?
        ; 0x10 = valueOffset ?
        ; index = array.2
        ; 0x18 = offsetInterval
        ; Second Special case:
        ; 0x20 + (A_index - 1) * 0x10 | 0x10 + (A_Index - 1) * 0x10
		
		; --- handle dictionary types with different size offsets ---
		; Look up if it's a key/value are standard types
		hasType1:=IBM_GOS.SystemTypes[this._CollectionKeyType]!=""
		hasType2:=IBM_GOS.SystemTypes[this._CollectionValType]!=""
		; Look up correct byte sizes for standard types used in c# dictionaries. Default non-standard byte size (8) otherwise.
		type1Bytes:=hasType1 ? IBM_GOS.ValueTypeToBytes[IBM_GOS.SystemTypes[this._CollectionKeyType]] : 0x8
		type2Bytes:=hasType2 ? IBM_GOS.ValueTypeToBytes[IBM_GOS.SystemTypes[this._CollectionValType]] : 0x8
		itemSize:=(hasType1 AND hasType2 AND type1Bytes == 0x4 and type2Bytes == 0x4) ? 0x4 : 0x8
		; ---
		baseOffset:=0x28 ;64-bit dictionary entries start at 0x28
		; Default entry sizes (e.g. int/int dict entries will be 0x10 bytes apart)
		offsetInterval:=itemSize==0x4 ? 0x10 : 0x18
		; Special case for Quads as values
		offsetInterval:=IBM_GOS.SystemTypes[this._CollectionValType]=="Quad" ? 0x20 : offsetInterval
		; value of entry starts after the key for the entry
		valueOffset:=itemSize
        offset:=baseOffset + (offsetInterval * array.2)
        if (array.1=="value")
            offset+=valueOffset
        return offset
    }

    CalculateArrayOffset(indexLoc, indexStart:=0, byteSizeOverride:=0x0)
    {
        if(indexStart) ; If list is not 0 based indexing
            indexLoc--             ; AHK uses 0 based array indexing, switch to 0 based
		if(!byteSizeOverride) ; _ArrayDimensions not decremented until after this function is called. 1 is effectively 0.
			itemSize:=(this._ArrayDimensions != "" AND  this._ArrayDimensions <= 1 AND _IC_BrivMaster_Memory_Reader_Class.aTypeSize[IBM_GOS.SystemTypes[this._CollectionValType]]) ? _IC_BrivMaster_Memory_Reader_Class.aTypeSize[IBM_GOS.SystemTypes[this._CollectionValType]] : 0x8
		else
			itemSize:=byteSizeOverride
		offset:=0x20 + (indexLoc * itemSize)
		return offset
    }

    CalculateHashSetOffset(key) ;Used to calculate offsets of an item in a dict. requires an array with "key" or "value" as first entry and the dict index as second. indices start at 0.
    {
		hasType1:=IBM_GOS.SystemTypes[this._CollectionKeyType] != "" ;Look up if key is a standard type
		type1Bytes:=hasType1 ? IBM_GOS.ValueTypeToBytes[IBM_GOS.SystemTypes[this._CollectionKeyType]] : 0x8 ;Look up correct byte sizes for standard types used in c# HashSets. Default non-standard byte size (8) otherwise.
		itemSize:=(hasType1 AND type1Bytes == 0x4) ? 0x4 : 0x8
		baseOffset:=itemSize==0x4 ? 0x20 : 0x28 ; 64-bit HashSet entries start at 0x20 for base types, 0x28 for class types
		; Default entry sizes (e.g. int hash entries will be 0xC bytes apart. Class types willbe 0x10 bytes apart)
		offsetInterval:=itemSize==0x4 ? 0xC : 0x10
		; Special case for Quads as values TODO: Find out why this is commented out, do Quads not provide a hash function?
		;offsetInterval := IBM_GOS.SystemTypes[this._CollectionValType] == "Quad" ? 0x20 : offsetInterval
		; value of entry starts after the key for the entry
		valueOffset:=itemSize ;TODO: What is the point of this variable?
        offset:=baseOffset + (offsetInterval * key)
        return offset
    }

    GetDictIndexOfKeyQuick(key) ;Iterates a dictionary collection looking for the matching key value
    {
        wasLocked:=IBM_GOS.ReadIsLocked
        IBM_GOS.ReadIsLocked:=False                                               ; Disable lock before read
        dictCount:=this.size.Read()
        IBM_GOS.ReadIsLocked:=wasLocked                                           ; Reset read lock after read
        if (dictCount<0 OR dictCount>32000)                                                 ; skip attempts on unreasonable dictionary sizes.
            return ""
        currIndex:=Array()
        currIndex[1]:="Key"
        indexReadObject:=new IBM_GOS(this.FullOffsets)
        indexReadObject.BasePtr:=this.BasePtr
        indexReadObject.FullOffsets.Push(0x18) ; Collection Items offset for Dictionaries
        indexReadObject.ValueType:=IBM_GOS.SystemTypes[this._CollectionKeyType] ? IBM_GOS.SystemTypes[this._CollectionKeyType] : "Int64"
        loop, % dictCount
        {
            if (A_Index > 1)
                indexReadObject.FullOffsets.Pop()                                               ; pop last index offset that was added in loop
            if (this.StartAtLastPos)
                currIndex[2]:=position:=Mod(A_Index + IBM_GOS.LastDictPos, dictCount + 1)  ; Continue lookup from last location searched. Useful for ordered dictionaries.
            else
                currIndex[2]:=position:=A_Index - 1
            currIndexOffset:=this.CalculateDictOffset(currIndex)                              ; Index offset
            indexReadObject.FullOffsets.Push(currIndexOffset)
            IBM_GOS.ReadIsLocked:=False                                           ; Disable lock before read
            currKey:=indexReadObject.Read()
            IBM_GOS.ReadIsLocked:=wasLocked                                       ; Reset read lock after read
            if (currKey==key)
            {
                indexReadObject:=""
                valueOffset:=this.CalculateDictOffset(["value",position]) + 0
                this.BuildDictionaryEntry(key, position, 0x18, valueOffset)          ; fully Build Dictionary object.
                this.LastDictVersionByKey[key] := this.__version.Read()
                IBM_GOS.LastDictPos:=position                                     ; Save last position used for this dict entry, save last place in dictionary reads for faster sequential dictionary lookups.
                return position
            }
        }
        IBM_GOS.LastDictPos:=0
        return -1
    }

    ConvQuadToString3(FirstEight, SecondEight) ;Converts 16 byte Quad value into a string representation.
    {
        f := log(FirstEight + (2.0**63))
        decimated:=(log(2) * SecondEight / log(10)) + f
        if(decimated<=4)
            return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 2) . ""
        exponent:=floor(decimated)
        significand:=round(10**(decimated - exponent), 2)
        return significand . "e" . exponent
    }

    ResetBasePtr(currentObj, name :="")
    {
        this.BasePtr:=currentObj.BasePtr
        for k,v in this
        {
            if(IsObject(v) AND ObjGetBase(v).__Class == "IBM_GOS" AND v.FullOffsets != "")
                v.ResetBasePtr(currentObj)
            else if(k=="DictionaryObject")
                for dictKey, dictValue in v
                    dictValue.ResetBasePtr(currentObj) ; Assume gameobjects, since dictionaryObject should be dict of gameobjects.
        }
    }

    DoesCollectionNeedReset()
    {
        wasLocked:=IBM_GOS.ReadIsLocked
        IBM_GOS.ReadIsLocked:=False                                           ; Disable lock before read
        needsReset:=(this.LastDictVersion!=this.__version.Read())
        IBM_GOS.ReadIsLocked:=wasLocked                                       ; Reset lock before return
        return needsReset
    }

    ResetCollection()
    {
        this.DictionaryObject:={}
        this.LastDictIndex:={}
        wasLocked:=IBM_GOS.ReadIsLocked
        IBM_GOS.ReadIsLocked:=False                                           ; Disable lock before read
        this.LastDictVersion:=this.__version.Read()
        IBM_GOS.ReadIsLocked:=wasLocked                                       ; Reset lock before return
    }

    ResetCollections()
    {
        this.DictionaryObject:={}
        this.LastDictIndex:={}
        for k,v in this
        {
            if(!IsObject(v) OR !(ObjGetBase(v).__Class=="IBM_GOS") OR k=="BasePtr")
                continue
            if(v.IsAddedIndex)
                this[k]:="", this.Delete(k)
            else
                this[k].ResetCollections()
        }
    }

    ResetUnstableCollectionsOnly()
    {
        for k,v in this
        {
            if(!IsObject(v) OR !(ObjGetBase(v).__Class=="IBM_GOS") OR k=="BasePtr")
                continue
            if(v.IsAddedIndex AND IBM_GOS.SystemTypes[this._CollectionKeyType]=="")
                this[k]:="", this.Delete(k)
            else
                this[k].ResetUnstableCollectionsOnly()
        }
    }

	IBM_ReBase(baseItem:="") ;Propogate a new base address through all child objects. Call without argument for base item
	{
		if (IsObject(baseItem)) ;Child object
		{
			this.BasePtr:=baseItem.BasePtr
			this.FullOffsets:=baseItem.FullOffsets.Clone()
			this.FullOffsets.Push(this.Offset*)
		}
		else ;The base item we called from
		{
			this.BasePtr:=new IC_BrivMaster_Memory_Base_Pointer_Class(_IBM_MM.instance.getAddressFromOffsets(this.BasePtr.BaseAddress,this.FullOffsets*))
			this.FullOffsets:=Array()          ; Full list of offsets required to get from base pointer to this object
			this.BaseAddressPtr:=""            ; The name of the pointer class that created this object.
			this.Offset:=0x0                   ; The offset from last object to this object.
			;TODO: Is forcing IsAddedIndex below appropriate? I think it is so that we can ReBase collection members without the next read just overwriting it
			this.IsAddedIndex:=false           ; __Get lookups on non-existent keys will create key objects with this value being true. Prevents cloning non-existent values.
		}
		for k,v in this ;Recurse children
        {
			if(IsObject(v) AND ObjGetBase(v).__Class == "IBM_GOS" AND v.FullOffsets != "" AND k != "BasePtr")
            {
                if(v.IsAddedIndex) ;Remove created objects
					this.Delete(k)
				else
					v.IBM_ReBase(this)
            }
        }

	}
}

class _IBM_MM ;A class to manage and make available instances of _IC_BrivMaster_Memory_Reader_Class
{
    _exeName:=""
    baseAddress:={}
    handle:=""

    exeName[]
    {
        get
        {
            return this._exeName
        }
        set
        {
            return this._exeName:=value
        }
    } 

    isAttached
    {
        get
        {
            return this.instance.attached
        }
    }
	
    Refresh(moduleName:="mono-2.0-bdwgc.dll", pid:="")
    {
        this.isInstantiated:=false
        ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
        ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
        ;Also, if the target process is running as admin, then the script will also require admin rights!
        ;Note: The program identifier can be any AHK windowTitle i.e.ahk_exe, ahk_class, ahk_pid, or simply the window title.
        ;handle is an optional variable in which the opened handle is stored.
        if (pid)
			processLookup:="AHK_PID " . pid
		else
			processLookup:="AHK_EXE " . this._exeName
		this.instance:=New _IC_BrivMaster_Memory_Reader_Class(processLookup, handle)
        this.handle:=handle
        if IsObject(this.instance)
        {
            this.isInstantiated := true
        }
        else
        {
            this.baseAddress[moduleName]:=-1
            return false
        }
        this.baseAddress[moduleName]:=this.instance.getModuleBaseAddress(moduleName)
        return true
    }
}

class IC_BrivMaster_MemoryFunctions_Class
{
	__new(fileLoc:="IC_Offsets.json")
	{
        FileRead, offsetData, %fileLoc%
        if(offsetData=="")
        {
            MsgBox 16, Briv Master, % "Offset data not found. Please review the BM Game tab of the settings."
            if(ObjGetBase(g_IBM).__Class=="IC_BrivMaster_GemFarm_Class") ;Exit from the gem farm, but not the hub - or we won't be able to select any offsets!
				ExitApp
        }
        currentPointers:=AHK_JSON.Load(offsetData)
		this.Versions:={} ;All the verison information is stored in the pointer JSON file, so load
		this.Versions.Import_Revision:=currentPointers["Import_Revision"]
		this.Versions.Import_Version_Major:=currentPointers["Import_Version_Major"]
		this.Versions.Import_Version_Minor:=currentPointers["Import_Version_Minor"]
		this.Versions.Platform:=currentPointers["Platform"]
		this.Versions.Pointer_Revision:=currentPointers["Pointer_Revision"]
		this.Versions.Pointer_Version_Major:=currentPointers["Pointer_Version_Major"]
		this.Versions.Pointer_Version_Minor:=currentPointers["Pointer_Version_Minor"]
        this.GameManager:=new IC_BrivMaster_IdleGameManager_Class(currentPointers.IdleGameManager.moduleAddress, currentPointers.IdleGameManager.moduleOffset)
        this.GameSettings:=new IC_BrivMaster_GameSettings_Class(currentPointers.GameSettings.moduleAddress, currentPointers.GameSettings.staticOffset, currentPointers.GameSettings.moduleOffset)
        this.EngineSettings:=new IC_BrivMaster_EngineSettings_Class(currentPointers.EngineSettings.moduleAddress, currentPointers.EngineSettings.staticOffset, currentPointers.EngineSettings.moduleOffset)
		this.FavoriteFormations:={} ;Irisiri - used for formation caching by the looks of it
		this.LastFormationSavesVersion:={} ;Irisiri - used for formation caching by the looks of it
		this.SlotFormations:={} ;Irisiri - used for formation caching by the looks of it
    }

	OpenProcessReader(pid:="") ;If supplied with a PID will have the memory manager load that instead of using the window
    {
        _IBM_MM.exeName:=g_IBM_Settings["IBM_Game_Exe"]
        isExeRead:=_IBM_MM.Refresh(,pid)
        if(isExeRead==-1)
            return
        if(_IBM_MM.handle=="")
            MsgBox, , , Could not read from exe. Try running as Admin. , 7
		this.GameManager.Refresh()
        this.GameSettings.Refresh()
        this.EngineSettings.Refresh()
    }

 	GetImportsVersion()
	{
        return this.Versions.Import_Version_Major . this.Versions.Import_Version_Minor . " " . this.Versions.Import_Revision ;'639 A', '639.1 B'
    }

	ReadBaseGameVersion()
	{
        return this.GameSettings.MobileClientVersion.Read()
    }

	ReadGameStarted()
	{
        return this.GameManager.game.gameStarted.Read()
    }

	ReadResetting()
	{
        return this.GameManager.game.gameInstances[0].ResetHandler.Resetting.Read()
    }

	ReadTransitioning()
	{
        return this.GameManager.game.gameInstances[0].Controller.areaTransitioner.IsTransitioning_k__BackingField.Read()
    }

    ReadTransitionDirection() ;0 = static (instant), 1 = right, 2 = left, 3 = JumpDown, 4 = FallDown (new)
	{
        return this.GameManager.game.gameInstances[0].Controller.areaTransitioner.transitionDirection.Read()
    }

    ReadFormationTransitionDir() ;0 = OnFromLeft, 1 = OnFromRight, 2 = OnFromTop, 3 = OffToLeft, 4 = OffToRight, 5 = OffToBottom (new)
	{
        return this.GameManager.game.gameInstances[0].Controller.formation.transitionDir.Read()
    }

	ReadAreaActive()
	{
        return this.GameManager.game.gameInstances[0].Controller.area.Active.Read()
    }

	ReadUserIsInited()
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.inited.Read()
    }

	ReadIsSplashVideoActive()
	{
        return this.GameManager.game.loadingScreen.SplashScreen.IsActive_k__BackingField.Read()
    }

	ReadClickLevel()
	{
        return this.GameManager.game.gameInstances[0].ClickLevel.Read()
    }

    ReadUserID()
	{
        ; return this.GameManager.game.gameUser.ID.Read() ;Alternative, not in imports currently
        return this.GameSettings.UserID.Read()
    }

    ReadUserHash()
	{
        ; return this.GameManager.game.gameUser.Hash.Read() ;Alternative, not in imports currently
        return this.GameSettings.Hash.Read()
    }

    ReadInstanceID()
	{
        return this.GameSettings._instance.instanceID.Read()
    }

	ReadWebRoot()
	{
        return this.EngineSettings.WebRoot.Read()
    }

    ReadPlatform()
	{
        return this.GameSettings.Platform.Read()
    }

	ReadGems()
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.redRubies.Read()
    }

	ReadCurrentObjID()
	{
        return this.GameManager.game.gameInstances[0].ActiveCampaignData.currentObjective.ID.Read()
    }

	ReadQuestRemaining()
	{
        return this.GameManager.game.gameInstances[0].ActiveCampaignData.currentArea.QuestRemaining.Read()
    }

	ReadCurrentZone()
	{
        return this.GameManager.game.gameInstances[0].ActiveCampaignData.currentAreaID.Read()
    }

    ReadHighestZone()
	{
        return this.GameManager.game.gameInstances[0].ActiveCampaignData.highestAvailableAreaID.Read()
    }

	ReadActiveGameInstance() ;TODO: Appears to duplicate IBM_GetActiveGameInstanceID via a different import, both are used currently
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.ActiveUserGameInstance.Read()
    }


    GetActiveModronFormation() ;Returns the formation array of the formation used in the currently active modron.
	{
        formation:=""
        formationSaveSlot:=this.GetActiveModronFormationSaveSlot()
        if(formationSaveSlot >= 0)
            formation := this.GetFormationSaveBySlot(formationSaveSlot) ;Get the formation using the index (slot)
        return formation
    }

	GetActiveModronFormationSaveSlot()
	{
        favorite:="M" ; (M)odron
        version:= this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2.__version.Read()
        if(this.FavoriteFormations[favorite]!="" AND version==this.LastFormationSavesVersion[favorite])
            return this.FavoriteFormations[favorite]
        ; Find the Campaign ID (e.g. 1 is Sword Cost, 2 is Tomb, 1400001 is Sword Coast with Zariel Patron, etc.)
        ; Find the SaveID associated to the Campaign ID
        ; Find the index (slot) of the formation with the correct SaveID
        formationSaveID:=this.GetModronFormationsSaveIDByFormationCampaignID(this.ReadFormationCampaignID())
        formationSavesSize:=this.ReadFormationSavesSize()
        if(formationSavesSize<=0 OR formationSavesSize>500) ; sanity check, should be < 51 saves per map.
            return ""
        formationSaveSlot := -1
        loop, %formationSavesSize%
        {
            if (this.ReadFormationSaveIDBySlot(A_Index - 1) == formationSaveID)
            {
                formationSaveSlot := A_Index - 1
                Break
            }
        }
        return formationSaveSlot
    }

    GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID) ;Uses FormationCampaignID to search the modron for the SaveID of the formation the active modron is using
	{
        modronSavesSlot:=this.GetCurrentModronSaveSlot() ;Find which modron core is being used
        return this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves[modronSavesSlot].FormationSaves[formationCampaignID].Read() ;Find SaveID for given formationCampaignID
    }

    GetCurrentModronSaveSlot() ;Finds the index of the current modron in ModronHandlers
	{
        activeGameInstance:=this.ReadActiveGameInstance()
        modronSavesSize:=this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves.size.Read()
        if(modronSavesSize <= 0 OR modronSavesSize > 20) ; sanity check, should be < 5 as of 2023-09-03
            return ""
        loop, %modronSavesSize%
            if (this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves[A_Index - 1].InstanceID.Read()==activeGameInstance)
                return A_Index - 1
    }

    GetModronResetArea() ;Finds the Modron Reset area for the current instance's core
	{
        return this.GetCoreTargetAreaByInstance(this.ReadActiveGameInstance())
    }

	GetCoreTargetAreaByInstance(InstanceID:=1)
	{
        saveSize:=this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves.size.Read() ;reads memory for the number of cores
        if(saveSize <= 0 OR saveSize > 50000) ; sanity check, should be a positive integer and less than 2005 as that is max allowed area as of 2023-09-03 Irisiri - unclear why the reset zone would be relevant here, number of cores possibly?
            return ""
        loop, %saveSize%  ;cycle through saved formations to find save slot of Favorite
            if (this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves[A_Index - 1].InstanceID.Read()==InstanceID)
                return this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves[A_Index - 1].targetArea.Read()
        return -1
    }

	ReadModronAutoFormation()
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves[this.GetCurrentModronSaveSlot()].TogglePreferences[0].Read()
    }

	ReadModronAutoReset()
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves[this.GetCurrentModronSaveSlot()].TogglePreferences[1].Read()
    }

	ReadModronAutoBuffs()
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.ModronHandler.modronSaves[this.GetCurrentModronSaveSlot()].TogglePreferences[2].Read()
    }

	ReadNumAttackingMonstersReached()
	{
        return this.GameManager.game.gameInstances[0].Controller.formation.numAttackingMonstersReached.Read()
    }

	ReadNumRangedAttackingMonsters()
	{
        return this.GameManager.game.gameInstances[0].Controller.formation.numRangedAttackingMonsters.Read()
    }

	ReadActiveMonstersCount()
	{
        return this.GameManager.game.gameInstances[0].Controller.area.activeMonsters.size.Read()
    }

    ReadFormationCampaignID() ;Reads the FormationCampaignID for the FormationSaves index passed in
	{
        return this.GameManager.game.gameInstances[0].FormationSaveHandler.FormationCampaignID.Read()
    }

    ReadFormationSaveIDBySlot(slot:=0) ;Reads the SaveID for the FormationSaves index passed in
	{
        return this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].SaveID.Read()
    }

	ReadOfflineTime()
	{
        return this.GameManager.game.gameInstances[0].OfflineHandler.OfflineTimeRequested_k__BackingField.Read()
    }

	ReadOfflineDone()
	{
        handlerState:=this.GameManager.game.gameInstances[0].OfflineHandler.CurrentState_k__BackingField.Read()
        stopReason:=this.GameManager.game.gameInstances[0].OfflineHandler.CurrentStopReason_k__BackingField.Read()
        return handlerState==0 AND stopReason != "" ; handlerstate is "inactive" and stopReason is not null
    }

	ReadResetsTotal()
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.StatHandler.Resets.Read()
    }

	ReadResetsCount()
	{
        return this.GameManager.game.gameInstances[0].ResetsSinceLastManual.Read()
    }

	ReadAutoProgressToggled()
	{
        return this.GameManager.game.gameInstances[0].Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButton.toggled.Read()
    }

	ReadWelcomeBackActive()
	{
        return this.GameManager.game.gameInstances[0].Screen.uiController.notificationManager.notificationDisplay.welcomeBackNotification.Active.Read()
    }

    GetFormationSaveBySlot(slot := 0, ignoreEmptySlots := 0) ;Read the champions saved in a given formation save slot. returns an array of champ ID with -1 representing an empty formation slot. When parameter ignoreEmptySlots is set to 1 or greater, empty slots (memory read value == -1) will not be added to the array.
	{
        currentVersion:=this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Formation.__version.Read()
        if(currentVersion != "" AND currentVersion==this.LastFormationSavesVersion["slot" . slot] AND this.SlotFormations["slot" . slot] != "")
        {
            if(!ignoreEmptySlots)
                return this.SlotFormations["slot" . slot].Clone()
            else if (currentVersion != "" AND currentVersion == this.LastFormationSavesVersion["slot" . slot . "1"] AND this.SlotFormations["slot" . slot . "1"] != "")
                return this.SlotFormations["slot" . slot . "1"].Clone()
            Formation:={}
            for indexVal,champID2 in this.SlotFormations["slot" . slot]
                if(champID2 != -1)
                    Formation.Push(champID2)
            return this.SlotFormations["slot" . slot . "1"]:=Formation.Clone()
        }
        Formation := {}
        _size := this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Formation.size.Read()
        if(_size <= 0 OR _size > 20) ; sanity check
            return ""
        loop, %_size%
        {
            champID := this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Formation[A_Index - 1].Read()
            if (!ignoreEmptySlots or champID != -1)
                Formation.Push( champID )
        }
        this.LastFormationSavesVersion["slot" . slot] := currentVersion
        this.SlotFormations["slot" . slot] := Formation.Clone()
        return Formation.Clone()
    }

    GetSavedFormationSlotByFavorite(favorite:=1) ;Looks for a saved formation matching a favorite. Returns "" on failure. Favorite, 0 = not a favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E). O(n) for potentially large list, try to limit use
	{
        formationSavesSize := this.ReadFormationSavesSize() ;Reads memory for the number of saved formations
        if(formationSavesSize <= 0 OR formationSavesSize > 500) ; sanity check, should be less than 51 as of 2023-09-03
            return ""
        formationSaveSlot := ""
        loop, %formationSavesSize% ;cycle through saved formations to find save slot of Favorite
            if (this.ReadFormationFavoriteIDBySlot(A_Index - 1)==favorite)
                return A_Index - 1
        return ""
    }

	ReadMostRecentFormationFavorite() ;Note this is the most recent requested - it DOES update if the formation swap fails, so is not reliable
	{
        return this.GameManager.game.gameInstances[0].FormationSaveHandler.mostRecentFormation.Favorite.Read()
    }

    GetFormationByFavorite(favorite:=0) ;Returns the formation stored at the favorite value passed in
	{
        version:= this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2.__version.Read()
        if(this.FavoriteFormations[favorite] != "" AND version == this.LastFormationSavesVersion[favorite])
            return this.FavoriteFormations[favorite]
        slot:=this.GetSavedFormationSlotByFavorite(favorite)
        formation := this.GetFormationSaveBySlot(slot)
        this.FavoriteFormations[favorite] := formation.Clone()
        this.LastFormationSavesVersion[favorite] := version
        return formation
    }


    GetCurrentFormation() ;Returns an array containing the current formation. Note: Slots with no hero are converted from 0 to -1 to match other formation saves
	{
        size := this.GameManager.game.gameInstances[0].Controller.formation.slots.size.Read()
        if(size <= 0 OR size > 14) ; sanity check, 12 is the max number of concurrent champions possible.
            return ""
        formation := Array()
        loop, %size%
        {
            heroID := this.ReadChampIDBySlot(A_Index - 1)
            formation.Push( heroID > 0 ? heroID : -1)
        }
        return formation
    }

	ReadChampIDBySlot(slot := 0)
	{
        return this.GameManager.game.gameInstances[0].Controller.formation.slots[slot].hero.def.ID.Read()
    }


    ReadFormationSavesSize() ;Read the number of saved formations for the active campaign
	{
        return this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2.size.Read()
    }

    ReadFormationFavoriteIDBySlot(slot:=0) ;reads if a formation save is a favorite 0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
	{
        return this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Favorite.Read()
    }

    ReadChestCountByID(chestID) ;Chests are stored in a dictionary under the "entries". It functions like a 32-Bit list but the ID is every 4th value. Item[0] = ID, item[1] = MAX, Item[2] = ID, Item[3] = count. They are each 4 bytes, not a pointer
	{
        return this.GameManager.game.gameInstances[0].Controller.userData.ChestHandler.chestCounts[chestID].Read()
    }

    ReadPatronID()
	{
        patronIDDef:=this.GameManager.game.gameInstances[0].PatronHandler.ActivePatron_k__BackingField.Read()
        if (patronIDDef==0 OR patronIDDef=="")
            return patronIDDef
        patronID:=this.GameManager.game.gameInstances[0].PatronHandler.ActivePatron_k__BackingField.ID.Read()
        if(patronID < 0 OR patronID > 100) ; Ignore clearly bad memory reads.
            patronID:=""
        return patronID
    }

	HeroHasFeatSavedInFormation(heroID:=58, featID:=2131, formationSlot:=1)
	{
        size:=this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[formationSlot].Feats[heroID].List.size.Read()
        if(size=="")
            return ""
        if(size<=0 OR size>10) ; sanity check
            return false
        Loop, %size%
            if (featID == this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[formationSlot].Feats[heroID].List[A_Index - 1].Read())
                return true
        return false
    }

	HeroHasAnyFeatsSavedInFormation(heroID := 58, formationSlot := 1)
	{
        size:=this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[formationSlot].Feats[heroID].List.size.Read()
        if(size == "")
            return ""
        if(size <= 0 OR size > 10) ; sanity check
            return false
        return true
    }

    GetHeroFeats(heroID)
	{
        if (heroID < 1)
            return ""
        size:=this.GameManager.game.gameInstances[0].Controller.userData.FeatHandler.heroFeatSlots[heroID].List.size.Read()
        if (size < 0 OR size > 10) ;Sanity check, should be < 4 but set to 10 in case of future feat num increase.
            return ""
        featList:=[]
        Loop, %size%
            featList.Push(this.GameManager.game.gameInstances[0].Controller.userData.FeatHandler.heroFeatSlots[heroID].List[A_Index - 1].ID.Read())
        return featList
    }

	IBM_GetWebRootFriendly() ;Handle failures for user-facing reads (mainly the log). WebRoot uses the EngineSettings pointer that moves a lot. TODO: Why is this in memory? Should probably be functions or shared functions
	{
		webRoot:=this.ReadWebRoot()
		if(!webRoot)
			webRoot:="Unable to read WebRoot"
		return webRoot
	}

	IBM_ReadGameVersionMinor() ;If the game is 636.2, return '.2'. This can be, and often is, empty
	{
		return this.GameSettings.VersionPostFix.Read()
    }

	IBM_IsBuffActive(buffName) ;Is a Gem Hunter potion active
	{
		buffSize:=this.GameManager.game.gameInstances[0].BuffHandler.activeBuffs.size.Read()
		if (buffSize < 0 OR size > 1000)
			return false
		loop %buffSize%
		{
			if (this.GameManager.game.gameInstances[0].BuffHandler.activeBuffs[A_Index-1].Name.Read()==buffName) ;TODO: Find out if this gets localised; might need to use the effect name (although that would collide with anything else that gave +50% gems)
				return true
		}
		return false
	}

	IBM_ReadBaseGameSpeed() ;Reads the game speed without the area transition multipier Diana applies, e.g. x10 will flick between x10 and x50 constantly - this will always return x10
	{
		areaTransMulti:=this.GameManager.game.gameInstances[0].areaTransitionTimeScaleMultiplier.Read()
        if (!areaTransMulti)
			areaTransMulti:=1 ;So we don't divide by zero
		return this.GameManager.TimeScale.Read() / areaTransMulti
	}

	IBM_ReadCurrentZoneMonsterHealthExponent() ;Returns 85.90308999 for 8e85 for example
	{
		MEMORY_HEALTH:=g_SF.Memory.GameManager.game.gameInstances[0].ActiveCampaignData.currentArea.Health
		first8:=MEMORY_HEALTH.Read("Int64") ;Quad
        newObject := MEMORY_HEALTH.QuickClone()
        offsetIndex := newObject.FullOffsets.Count()
        newObject.FullOffsets[offsetIndex] := newObject.FullOffsets[offsetIndex] + 0x8
		last8:= newObject.Read("Int64")
		return this.IBM_ConvQuadToExponent(first8,last8)
	}

	IBM_ConvQuadToExponent(FirstEight,SecondEight) ;Converts a quad to an exponent, e.g. 8e85 to 85.90308999. Necessary as AHK can't do Doubles let alone Quads TODO: Should this be in Memory or Shared functions?
    {
        f := log( FirstEight + ( 2.0 ** 63 ) )
        decimated := ( log( 2 ) * SecondEight / log( 10 ) ) + f
        if(decimated <= 4)
            return round((FirstEight + (2.0**63)) * (2.0**SecondEight), 2)
        exponent:=floor(decimated)
        significand:=round( 10 ** (decimated-exponent), 2 )
        return exponent + log(significand)
    }

	IBM_GetCurrentCampaignFavourExponent() ;Process the double directly to avoid AHK limits, or trying to manage it as a string
	{
		static indexCache:=""
		currencyID:=this.GameManager.game.gameInstances[0].ActiveCampaignData.AdventureDef._campaignDef.ResetCurrencyID.Read()
		if (currencyID=="")
			return
		RESET_DEFS:=this.GameManager.game.gameInstances[0].Controller.userData.ResetCurrencyHandler.ResetCurrencyDefs
		if(!indexCache OR RESET_DEFS[indexCache].ID.Read()!=currencyID) ;If there's no cached index, or the cached index no longer points to the right ID
		{
			indexCache:="" ;Reset as invalid
			size:=RESET_DEFS.size.Read()
			if(size<0 OR size>500)
				return
			loop, %size%
			{
				if(RESET_DEFS[A_Index-1].ID.Read()==currencyID)
				{
					indexCache:=A_Index-1
					break
				}
			}
		}
		full8bytes:=RESET_DEFS[indexCache].CurrentAmount.Read("Int64")+0
		sign:=(full8bytes & 0x8000000000000000) >> 63
		signMulti:=sign ? -1:1
		exponent:=((full8bytes & 0x7FF0000000000000) >> 52) - 1023 ;For IEEE 754 double
		mantissa:=(full8bytes & 0x000FFFFFFFFFFFFF) / 0x000FFFFFFFFFFFFF
		favourExp:=exponent * LOG(2) + LOG(signMulti*(1+mantissa)) ;As an exponent, e.g. 306.6 for 10^306.6=4e306
		return floor(favourExp)
	}

	IBM_ReadAreaMonsterDamageMultiplier()
    {
        return g_SF.Memory.GameManager.game.gameInstances[0].ActiveCampaignData.currentArea.AreaDef.MonsterDamageMultiplier.Read()
    }

	IBM_ReadCampaignMonsterDamageMultiplier()
    {
        return this.GameManager.game.gameInstances[0].ActiveCampaignData.currentRules.MonsterDamageModifier.Read()
    }

	IBM_ReadMonsterBaseDPS()
    {
        return this.GameManager.game.gameInstances[0].ActiveCampaignData.currentRules.monsterbaseStats.BaseDPS.Read()
    }

	IBM_ReadDPSGrowthCurve()
    {
        size:=this.GameManager.game.gameInstances[0].ActiveCampaignData.currentRules.monsterbaseStats.DPSGrowthRateCurve.size.Read()
		data:={}
		loop %size%
		{
			curvePoint:={}
			curvePoint.level:=this.GameManager.game.gameInstances[0].ActiveCampaignData.currentRules.monsterbaseStats.DPSGrowthRateCurve["key",A_Index-1].Read()
			curvePoint.value:=this.GameManager.game.gameInstances[0].ActiveCampaignData.currentRules.monsterbaseStats.DPSGrowthRateCurve[curvePoint.level].Read()
			data.Push(curvePoint)
		}
		return data
    }

	IBM_ReadGoldFirst8BytesBySeat(seat) ;Reads the first 8 bytes of the gold quad
    {
        return this.GameManager.game.gameInstances[0].Screen.uiController.bottomBar.heroPanel.activeBoxes[seat-1].lastGold.Read("Int64")
    }

	IBM_IsCurrentFormationEmpty() ;True if the current formation contains 0 champions
    {
        size:=this.GameManager.game.gameInstances[0].Controller.formation.slots.size.Read()
        if(size<=0 OR size>12) ;Sanity check
            return true ;Assumed that an invalid read means the formation is empty
        loop, %size%
        {
            heroID:=this.GameManager.game.gameInstances[0].Controller.formation.slots[A_index - 1].hero.def.ID.Read()
			if (heroID>0)
				return false
        }
		return true
    }

	IsCurrentFormationFull()
    {
        size:=this.GameManager.game.gameInstances[0].Controller.formation.slots.size.Read()
		loop %size%
        {
            if (this.GameManager.game.gameInstances[0].Controller.formation.slots[A_index - 1].hero.def.ID.Read()=="")
				return false
        }
        return true
    }

	IBM_ClickDamageLevelAmount() ;This is the base amount set per levelling seletion, e.g. always 1/10/25/100
	{
		return this.GameManager.game.gameInstances[0].Screen.uiController.bottomBar.heroPanel.clickDamageBox.levelUpAmount.Read()
	}

	IBM_GetFrontColumnSize() ;Used when we want to block champions from being levelled in the front formation slots so they do not share attacks with Briv
	{
		size:=this.GameManager.game.gameInstances[0].Controller.formation.slots.size.Read()
        frontCount:=0
        loop, %size% ;TODO: Can we break this loop once the column is >0? Not all that important as used only once per script run, though
        {
			if (this.GameManager.game.gameInstances[0].Controller.formation.slots[A_index - 1].SlotDef.Column.Read()==0) ;TODO: Might be a problem if there is a Xaryxis-like escort at the front of a formation in the future, read slot validity first?
				frontCount++
        }
		return frontCount
	}

	IBM_ReadIsInstanceDirty() ;Dirty = unsaved data
	{
		return this.GameManager.game.gameInstances[0].isDirty.Read()
	}

	IBM_ReadCurrentSave() ;Pointer to the current save, 0 if there isn't one active, so we can test if it's 0 or not. Non-zero whilst the game is saving
	{
		return this.GameManager.game.gameInstances[0].Controller.userData.SaveHandler.currentSave.Read()
	}

	IBM_ReadIsGameUserLoaded()
	{
		return this.GameManager.game.gameUser.Loaded.Read()
	}

    IBM_ReadClickLevelUpAllowed()
    {
        value:=this.GameManager.game.gameInstances[0].Screen.uiController.bottomBar.heroPanel.clickDamageBox.maxLevelUpAllowed.Read()
        return value=="" ? 1 : value ;TODO: Why does this default to 1 not 0?
    }

	IBM_ReadLastSave()
	{
		return this.GameManager.game.gameInstances[0].Controller.userData.SaveHandler.lastUserDataSaveTime.Read()
	}

	IBM_GetCurrentFormationChampions() ;Returns the champions in the formation, without positioning data, eg data[58]==true
    {
        size:=this.GameManager.game.gameInstances[0].Controller.formation.slots.size.Read()
        if(size<=0 OR size>12) ;Sanity check
            return ""
        champList:=[]
        loop, %size%
        {
            heroID:=this.GameManager.game.gameInstances[0].Controller.formation.slots[A_index - 1].hero.def.ID.Read()
            if (heroID > 0)
				champList[heroID]:=true
        }
        return champList
    }

	IBM_GetFormationFieldFamiliarCountBySlot(slot)
	{
		familiarCount:=0
		size:=this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Familiars["Clicks"].List.size.Read()
		if(size < 0 OR size > 10) ; sanity check, should be < 6 but set to 10 in case of future game field familiar increase.
			return ""
		loop %size%
		{
			if(this.GameManager.game.gameInstances[0].FormationSaveHandler.formationSavesV2[slot].Familiars["Clicks"].List[A_Index - 1].Read()>=0) ;Negative numbers are used to store gaps in familiar layout, e.g. -3,13,-2 means '3 empty spaces, familiar ID 13, 2 empty spaces'
				familiarCount++
		}
		return familiarCount
	}

	IBM_GetActiveGameInstanceID() ;This is the instance ID 1 to 4, NOT the ID if the instance in the gameInstances collection
	{
		return this.GameManager.game.gameInstances[0].InstanceUserData_k__BackingField.InstanceId.Read()
	}
	
	ResolvePointers(GOS) ;Takes an IBM_GOS object and uses the memory manager to extract the address
	{
		return _IBM_MM.instance.getAddressFromOffsets(GOS.BasePtr.BaseAddress,GOS.FullOffsets*)
	}
}