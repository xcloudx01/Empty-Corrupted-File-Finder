﻿;Environment
	#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
	; #Warn  ; Enable warnings to assist with detecting common errors.
	SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	#SingleInstance Force
	SearchDirectory = %A_ScriptDir%
	Recurse = 1

;GUI
	Gui, Add, Text, x12 y19 w90 h20 , Where to search:
	Gui, Add, Text, x335 y60 w150 h20 +Right vScanningText,
	Gui, Add, Button, x452 y19 w30 h20 gSelectSearchDirectory, ..
	Gui, Add, Button, x190 y49 w100 h30 gFindZeroByteFiles vFindFilesButton, Find zero byte files
	Gui, Add, Button, x190 y49 w100 h30 gCancelScan vCancelScanButton, Cancel
	Gui, Add, Checkbox, x10 y49 w170 vRecurse Checked%Recurse%,Recurse into sub-directories?
	Gui, Add, Edit, x102 y19 w340 h20 vSearchDirectory, %SearchDirectory%
	Gui, Add, Progress, x10 y80 w475 h10 cBlue vProgressBar
	GuiControl,Hide,CancelScanButton
	Gui, Show, h100 w490, Cloud's Empty File Finder
	Menu,Menu1,Add,Copy to clipboard,CopyToClipboard ;Used when rightclicking a found empty file.
	Return

FindZeroByteFiles:
	Gui 1:submit,nohide
	CancelRequested = 0
	GuiControl,Show,CancelScanButton
	GuiControl,Hide,FindFilesButton
	GuiControl,,ScanningText,Enumerating files..
	If Recurse
		RecurseIntoSubdirectories = R
	Else
		RecurseIntoSubdirectories =
	ZeroByteFilesFoundArray := Object() ; Create a blank array
	ZeroByteFilesCount = 0
	NumberOfFilesToScan = 0
	ListOfZeroByteFiles =
	Loop Files, %SearchDirectory%\*.*,%RecurseIntoSubdirectories%  ; Recurse into subfolders.
	{
		if CancelRequested
			Break
		else
		NumberOfFilesToScan ++
	}
		GuiControl,,ScanningText,Scanning..
		Loop Files, %SearchDirectory%\*.*,%RecurseIntoSubdirectories%  ; Recurse into subfolders.
		{
			if CancelRequested
			{
				GuiControl,,ScanningText,Scan cancelled.
				GuiControl,Hide,CancelScanButton
				GuiControl,Show,FindFilesButton
				GuiControl,,ProgressBar,0
				return
			}
			PercentScanned := Ceil(A_Index / NumberOfFilesToScan * 100) ;Round up
			GuiControl,,ProgressBar,%PercentScanned%
			FileGetSize,FileSize,%A_LoopFileFullPath%
			if FileSize = 0
			{
				ZeroByteFilesCount ++
				;FileAppend, %A_LoopFileFullPath%`n, ZeroByteFiles.txt
				ZeroByteFilesFoundArray.Insert(A_LoopFileFullPath) 
			}
		}
		If ZeroByteFilesCount
		{
			Gui 2: Add, ListView, altsubmit x12 y29 w1390 h540 gSelectFoundZeroByteFile, Zero Byte Files
			Gui,2:default
			
			Loop %ZeroByteFilesCount%
				{
					element := ZeroByteFilesFoundArray[A_Index]
					LV_Add("",element)
				;	ListOfZeroByteFiles := ListOfZeroByteFiles . element . "|"
				}			
				Gui 2: Add, Text, x12 y9 w60 h20 , Empty Files:
				Gui 2: Add, Text, x592 y9 w250 h20 , Select an item to highlight in Explorer.
				Gui 2: Add, Button, x12 y569 w1390 h30 g2GuiClose, Close
				Gui 2: Show, x536 y234 h609 w1417, Empty files were found!
		}
		else
		{
			GuiControl,,ScanningText,No empty files found.
		}
		GuiControl,Hide,CancelScanButton
		GuiControl,Show,FindFilesButton
	return

CancelScan:
CancelRequested = 1
return

SelectSearchDirectory:
FileSelectFolder,SearchDirectory,SearchDirectory,3
GuiControl 1:,SearchDirectory,%SearchDirectory%
return

SelectFoundZeroByteFile:
	SelectedZeroByteFile := ZeroByteFilesFoundArray[A_EventInfo] ;Buffer what file is currently selected in the listview.
	StringGetPos,SlashPos,SelectedZeroByteFile,\,R
	StringMid,SelectedZeroByteFileDirectory,SelectedZeroByteFile,0,SlashPos ;Trim the variable until we just have the directory
	If A_GuiEvent = Doubleclick
	{
		;Run %SelectedZeroByteFileDirectory%
		Run,% "explorer.exe /e`, [color=Red]/n[/color]`, /select`," SelectedZeroByteFile
	}
	else if A_GuiEvent = Rightclick
		 Menu,Menu1,Show
	return

CopyToClipboard:
	clipboard = %SelectedZeroByteFile%
return

GuiClose:
ExitApp

2GuiClose:
Gui 2: Destroy
GuiControl 1:,ProgressBar,0
return