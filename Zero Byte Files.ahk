﻿;Environment
;Version: 1.023. 8th Oct 2017
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
SetBatchLines,-1 ;Thanks Helgef <3

;Variables
NameOfProgram = xcloudx01's Empty File Finder
;Get settings from ini file. Check to see if .ini file exists first.
Ifexist,ZeroByteFinderSettings.ini
{
			fileread,Temp,ZeroByteFinderSettings.ini
			ifinstring,Temp,[settings]
				GoSub,LoadSettings
			Else
				gosub, SetDefaultVariableValues
}
Else
	gosub, SetDefaultVariableValues

;GUI
Gui, Add, Text, x12 y19 w90 h20 , Where to search:
Gui, Add, Text, x335 y60 w150 h20 +Right vScanningText,
Gui, Add, Button, x452 y19 w30 h20 gSelectSearchDirectory, ..
Gui, Add, Button, x190 y49 w100 h30 gFindZeroByteFiles vFindFilesButton Default, Find zero byte files
Gui, Add, Button, x190 y49 w100 h30 gCancelScan vCancelScanButton, Cancel
GuiControl,Hide,CancelScanButton
Gui, Add, Checkbox, x10 y49 w170 vRecurse Checked%Recurse%,Scan inside sub-directories
Gui, Add, Edit, x102 y19 w340 h20 vSearchDirectory, %SearchDirectory%
Gui, Add, Progress, x10 y80 w475 h10 cBlue vProgressBar
Gui, Show, h100 w490, %NameOfProgram%
Menu,Menu1,Add,Copy path to clipboard,CopyToClipboard ;Used when rightclicking a found empty file.
Menu,Menu1,Add,Show in Explorer,HighlightInExplorer ;Used when rightclicking a found empty file.
Menu,Menu1,Add,Delete file/s,DeleteFile ;Used when rightclicking a found empty file.

;Hotkeys
Hotkey,IfWinActive,Empty files were found!
Hotkey,del,DeleteFile
Hotkey,IfWinActive,%NameOfProgram%
Hotkey,esc,GuiClose
Hotkey,IfWinActive,Empty files were found!
Hotkey,esc,2GuiClose
Hotkey,IfWinActive,Delete file confirmation
Hotkey,esc,DeleteMultipleFilesNo
Return

;Buttons
FindZeroByteFiles: ;Main function of the script
Gui 1:submit,nohide
GuiControl 1:,ProgressBar,0
IfNotExist,%SearchDirectory% ;Only run when searchdir actually exists.
{
			msgbox,48,Error!,The search directory was not found!
			return
		}
		;Blank out needed variables.
			CancelRequested = 0 ;Reset any cancel requests
			ZeroByteFilesFoundArray := Object() ; Create a blank array
			ZeroByteFilesFoundArrayExtension := Object() ; Create a blank array
			ZeroByteFilesCount = 0
			NumberOfFilesToScan = 0
			ListOfZeroByteFiles =
		GuiControl,Show,CancelScanButton
		GuiControl,Hide,FindFilesButton
		GuiControl,,ScanningText,Enumerating files..
		If Recurse ;Convert binary to R or blank for recursive function
			RecurseIntoSubdirectories = R
		Else
			RecurseIntoSubdirectories =
		Loop Files, %SearchDirectory%\*.*,%RecurseIntoSubdirectories% ;Count how many files there are to scan.
		{
			ifinstring,A_LoopFileFullPath,$RECYCLE.BIN ;Skip scanning the recycle bin
				continue
			if CancelRequested
				Break
			else
				NumberOfFilesToScan ++
		}
		if NumberOfFilesToScan = 1 ;Error out if there's nothing to do.
		{
			GuiControl,,ScanningText,No files in the scan folder.
			GuiControl,Hide,CancelScanButton
			GuiControl,Show,FindFilesButton
			return
		}
		else
		{
			GuiControl,,ScanningText,Scanning..
			Loop Files, %SearchDirectory%\*.*,%RecurseIntoSubdirectories%
			{
				ifinstring,A_LoopFileFullPath,$RECYCLE.BIN ;Skip scanning the recycle bin
					continue
				if CancelRequested
					Break
				else
				{
					PercentScanned := Ceil(A_Index / NumberOfFilesToScan * 100) ;Round up percentage value
					GuiControl,,ProgressBar,%PercentScanned%
					FileGetSize,FileSize,%A_LoopFileFullPath%
					if FileSize = 0
					{
						ZeroByteFilesCount ++
						ZeroByteFilesFoundArray.Insert(A_LoopFileFullPath)
						ZeroByteFilesFoundArrayExtension.Insert(A_LoopFileExt)
					}
				}
			}
			if CancelRequested
				{
					GuiControl,,ScanningText,Scan cancelled.
					GuiControl,Hide,CancelScanButton
					GuiControl,Show,FindFilesButton
					GuiControl,,ProgressBar,0
					return
				}
			If ZeroByteFilesCount
			{
				GuiControl,,ScanningText,Empty files were found!
				ListViewWidth = 980
				FileNameWidth := Ceil(ListViewWidth - 105 * 0.8 )
				ExtensionWidth = 80
				Gui 2: Add, ListView, altsubmit x10 y29 w980 h540 gSelectFoundZeroByteFile, Path|Extension
				Gui,2:default ;Needed to add items to list with LV_Add			
				Loop %ZeroByteFilesCount%
					{
						FilePath := ZeroByteFilesFoundArray[A_Index]
						stringreplace,FilePath,FilePath,\\,\,A ;Correct any double slashes
						FileExt := ZeroByteFilesFoundArrayExtension[A_Index]
						LV_Add("",FilePath,FileExt)
					}			
					Gui 2: Add, Text, x10 y9 w60 h20 , Empty Files:
					Gui 2: Add, Text, x400 y9 w250 h20 , Doubleclick an item to highlight it in Explorer.
					Gui 2: Add, Button, x9 y572 w150 h30 g2GuiClose, Close
					Gui 2: Add, Button, x842 y572 w150 h30 gDeleteFile, Delete selected file/s
					LV_ModifyCol(1,FileNameWidth)
					LV_ModifyCol(2,ExtensionWidth)				
					Gui 2: Show, h609 w1000, Empty files were found!
			}
			else
				GuiControl,,ScanningText,No empty files found.
			GuiControl,Hide,CancelScanButton
			GuiControl,Show,FindFilesButton
			return
		}
		
	DeleteFile:
		Gui,2:default ;Needed for LV_GetCount
		BUFFERSelectedEventInListView := SelectedEventInListView ;This variable gets changed the second the mouse gets clicked, we need to store its current value.
		BUFFERSelectedZeroByteFile := SelectedZeroByteFile ;This variable gets changed the second the mouse gets clicked, we need to store its current value.	
		NumberOfFilesToDelete := LV_GetCount("S")
		if NumberOfFilesToDelete = 1
		{
			if BUFFERSelectedZeroByteFile = Path ;If something went wrong with detecting the path, don't go any further with deleting.
				return
			Msgbox,36,Delete file confirmation,The following file will be deleted to the recycle bin:`n%BUFFERSelectedZeroByteFile%`n`nDo you wish to continue?
			ifMsgBox yes
			{
				filerecycle,%BUFFERSelectedZeroByteFile%
				LV_Delete(BUFFERSelectedEventInListView)
			}
		}
		else ;Make a list of what files were selected for deletion.
		{
			SelectedFilesForDeletionList = EMPTY ;Wipe the selected file list before we start our selections to it.
			RowNumber = 0  ; This causes the first loop iteration to start the search at the top of the list.
			Loop
			{
				RowNumber := LV_GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.
				if not RowNumber  ; The above returned zero, so there are no more selected rows.
					break
				LV_GetText(LvText, RowNumber)
				If SelectedFilesForDeletionList = EMPTY
					SelectedFilesForDeletionList = %LvText% ;First item doesn't need a linebreak/pipe character.
				else
					SelectedFilesForDeletionList = %SelectedFilesForDeletionList%|%LvText%
			}
			if SelectedFilesForDeletionList = EMPTY ;If we scanned everything selected and still came back empty, don't bother showing the UI.
				return
			Gui 3: Add, ListBox, x12 y39 w450 h140 HScroll, %SelectedFilesForDeletionList%
			Gui 3: Add, Text, x12 y19 w440 h20 , The following files will be deleted:
			Gui 3: Add, Text, x12 y189 w440 h20 , Do you wish to continue?
			Gui 3: Add, Button, x252 y219 w100 h30 gDeleteMultipleFilesYes +Default, Yes
			Gui 3: Add, Button, x362 y219 w100 h30 gDeleteMultipleFilesNo, No
			Gui 3: Show, h264 w477, Delete file confirmation
		}
		return

	DeleteMultipleFilesYes:
		Gui 3: Destroy
		Gui,2: default ;Needed to delete items from list with LV_Delete
			loop, % LV_GetCount("S")
				{
					LV_GetText(LvText, LV_GetNext(-1))
					LV_Delete(LV_GetNext(-1))
					filerecycle, % LvText
				}
		return

	DeleteMultipleFilesNo:
		Gui 3: Destroy
		return
		
	CancelScan:
		CancelRequested = 1
		return

	SelectSearchDirectory:
		FileSelectFolder,SelectedNewSearchFolder,SearchDirectory,3
		if SelectedNewSearchFolder ;Only update on user selected a new folder, not on a cancel.
		{
			SearchDirectory := SelectedNewSearchFolder
			GuiControl 1:,SearchDirectory,%SearchDirectory%
		}
		return		

	SelectFoundZeroByteFile: ;This acts more like a function. It's called anytime something is selected in the list of found files.
		Gui,2:default ;Needed for LV_GetText
		if (A_GuiEvent = "Doubleclick" or A_GuiEvent = "RightClick") ;If double or rightclick, method is slightly different.
		{
			LV_GetText(SelectedZeroByteFile, A_EventInfo) ;what file is currently selected in the listview.
			StringGetPos,SlashPos,SelectedZeroByteFile,\,R
			StringMid,SelectedZeroByteFileDirectory,SelectedZeroByteFile,0,SlashPos ;Trim the variable until we just have the directory
			SelectedEventInListView := A_EventInfo
			If A_GuiEvent = Doubleclick
				gosub,HighlightInExplorer
			else if A_GuiEvent = Rightclick
				 Menu,Menu1,Show
		}
		else
		{
			RowNumber = 0  ; This causes the first loop iteration to start the search at the top of the list.
			Loop
			{
				RowNumber := LV_GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.
				if not RowNumber  ; The above returned zero, so there are no more selected rows.
					break
				LV_GetText(SelectedZeroByteFile, RowNumber)
				SelectedEventInListView := RowNumber
			}
			return
}
return

;Subroutines
SetDefaultVariableValues:
SearchDirectory = %A_WorkingDir%
Recurse = 1
return

LoadSettings:
iniread,Recurse,ZeroByteFinderSettings.ini,Settings,Recurse
iniread,SearchDirectory,ZeroByteFinderSettings.ini,Settings,SearchDirectory
if (SearchDirectory = "ERROR" or SearchDirectory = "") ;Restore default if saved value was an error or blank
	SearchDirectory = %A_WorkingDir%
Return

SaveSettings:
gui 1:submit,nohide
IniWrite,%Recurse%,ZeroByteFinderSettings.ini,Settings,Recurse
IniWrite,%SearchDirectory%,ZeroByteFinderSettings.ini,Settings,SearchDirectory
return

CopyToClipboard:
clipboard = %SelectedZeroByteFile%
return

HighlightInExplorer:
Run,% "explorer.exe /e`, [color=Red]/n[/color]`, /select`," SelectedZeroByteFile
return

GuiClose:
gosub,SaveSettings
ExitApp

2GuiClose:
GuiControl 1:,ProgressBar,0
GuiControl 1:,ScanningText,
GuiControl 1:Hide,CancelScanButton
GuiControl 1:Show,FindFilesButton
Gui 2: Destroy
return

3GuiClose:
Gui 3: Destroy
return