#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force

Gui, Add, Text, x12 y19 w90 h20 , Where to search:
Gui, Add, Button, x452 y19 w30 h20 , ..
Gui, Add, Button, x190 y49 w100 h30 gFindZeroByteFiles, Find zero byte files
Gui, Add, Edit, x102 y19 w340 h20 , WhereToSearch
Gui, Add, Progress, x10 y80 w470 h10 cBlue vProgressBar
Gui, Show, h100 w500, Cloud's Empty File Finder
Menu,Menu1,Add,Copy to clipboard,CopyToClipboard ;Used when rightclicking a found empty file.
Return

FindZeroByteFiles:
	gui 1:submit,nohide
	ZeroByteFilesFoundArray := Object() ; Create a blank array
	ZeroByteFilesCount = 0
	NumberOfFiles = 0
	ListOfZeroByteFiles =
	Loop Files, %A_ScriptDir%\*.*,R  ; Recurse into subfolders.
		NumberOfFiles ++
	Loop Files, %A_ScriptDir%\*.*,R  ; Recurse into subfolders.
	{
		PercentScanned := Ceil(A_Index / NumberOfFiles * 100) ;Round up
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
		GuiControl,, Debug, No corrupt files were found.`r`n
	}
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