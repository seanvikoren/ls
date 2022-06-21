@echo off

:: EQU - equal
:: NEQ - not equal
:: LSS - less than
:: LEQ - less than or equal
:: GTR - greater than
:: GEQ - greater than or equal


:: ----------------------------------------------------------------
:: Main
setlocal enabledelayedexpansion enableextensions

	set defaultFileFilter=.

	:: if more than one paramter was passed, go to usage
	if not "%2"=="" (
		call :PrintUsage %defaultFileFilter%
		goto :eof
	)

	:: Handle empty
	if "%1"=="" (
		set _name=%defaultFileFilter%
	) else (
		set _name="%1"
	)

	:: Print  information based on _name being a directory or a file
	if exist "%_name%"/* (
		call :PrintDirectory %_name%
	) else (
		call :PrintFileAttributes %_name%
	)

endlocal
goto :eof


:: ----------------------------------------------------------------

:PrintUsage <defaultFileFilter>
	echo Usage: %~n0 ^[fileFilter ^| fileName^ ^| {default=%1}]
	goto :eof
	

:: ----------------------------------------------------------------

:PrintFileMetaData <fileName>
	setlocal enabledelayedexpansion enableextensions

	call :GetFileDetailLine _line %1 C
	call :SplitLine _size _user _fileName %_line%
	call :CommaFormat formattedNumber %_size%
	call :GetTimeStamp timeStampCreation %_line%
	
	call :GetFileDetailLine _line %1 A
	call :GetTimeStamp timeStampAccessed %_line%
	
	call :GetFileDetailLine _line %1 W
	call :GetTimeStamp timeStampWritten %_line%
	
	:: Wite out the description
	echo:
	echo %_fileName% (%formattedNumber% bytes)
	echo Owned by '%_user%'
	echo:
	echo %timeStampCreation% Created
	echo %timeStampAccessed% Accessed
	echo %timeStampWritten% Written
	echo:
	call :PrintFileAttributes %1
	
	endlocal
goto :eof


:: ----------------------------------------------------------------

:PrintDirectory <name>
	setlocal enabledelayedexpansion enableextensions
	
	if "%1"=="" (
		set target=.
	) else (
		set target=%~1
	)

	set i=1
	for /F "usebackq tokens=*" %%g in (`dir /ogn /-c /4 %target%`) do (
		if %i% leq 4 (
			set lineList[!i!]=%%g
			set /a i+=1
		)
	)

	set /a "count=%i%-2"
	
	:: Get max width
	set maxCenterColumnWidth=usts
	call :GetMaxSizeWidth maxCenterColumnWidth lineList count
	
	:: Adjust for commas
	set /a commaCount=maxCenterColumnWidth/3
	set /a maxCenterColumnWidth+=commaCount
	
	:: Fixup Center Column
	if %maxCenterColumnWidth%==0 set /a maxCenterColumnWidth=2
	
	set pad=                                                                                        _
	set "pad=!pad:~0,%maxCenterColumnWidth%!"

	:: Loop over lines while reformatting
	::set /a fileSizeColumnWidth=17
	set /a fileSizeColumnWidth=maxCenterColumnWidth
	set /a i=0

	:PrintDirectoryLoop

		if %i%==%count% goto :PrintDirectoryContinue
		if %i% LEQ 3 goto :PrintDirectorySkip
		::if %i%==3 goto :PrintDirectoryContinue
		
			set line=!lineList[%i%]!
			set _date=!line:~0,10!
			
			::call :GetTimeStamp timeStamp %line%
			call :GetTimeStamp timeStamp %line:~0,20%
			
			:: Process directory marker and file sizes
			set directoryTag=!line:~25,3!

			if "!directoryTag!"=="DIR" (
				set centerColumn= d %pad%
			) else (
				call :CommaFormat formatted !line:~21,17!
				if "!formatted!"=="" (
					set centerColumn= l %pad%
				) else (
					call :PadSpacesLeft paddedString %fileSizeColumnWidth% "!formatted!"
					
					set columnFormattedSize=!paddedString!
					set centerColumn="!columnFormattedSize!"
				)
			)
			
			set tail=!line:~39,90!
			
			::echo %timeStamp% !centerColumn:~1,%fileSizeColumnWidth%! %tail%
			echo %timeStamp% !centerColumn:~1,%fileSizeColumnWidth%! %tail%
		
		:PrintDirectorySkip	
		set /a i+=1

	goto :PrintDirectoryLoop
	
	:PrintDirectoryContinue

	endlocal
goto :eof


:: ----------------------------------------------------------------

:GetMaxSizeWidth <maxWith> <list> <count>
	setlocal enabledelayedexpansion enableextensions
	
	set lineList=%2
	set /a count=%3
	set /a maxWidth=0
	set /a i=0
	
	:GetMaxSizeWidthLoop

		if %i%==%count% goto GetMaxSizeWidthContinue
		if %i% LEQ 3 goto :GetMaxSizeWidthSkip
		
			set line=!lineList[%i%]!
			
			:: Process directory marker and file sizes
			set directoryTag=!line:~25,3!
			if not "!directoryTag!"=="DIR" (
				set "n=!line:~21,17!"
				call :GetLength width !n!
				if !width! gtr !maxWidth! set /a maxWidth=width
			)
			
		:GetMaxSizeWidthSkip
		set /a i+=1

	goto :GetMaxSizeWidthLoop
	
	:GetMaxSizeWidthContinue

	endlocal & (
		set "%1=%maxWidth%"
	)
goto :eof


:: ----------------------------------------------------------------

:GetTimeStamp <timeStamp> <listLine(will decompose)>
	setlocal enabledelayedexpansion enableextensions
	
	set _date=%2
	set _time=%3
	set _ampm=%4
	
	call :ConvertTimeTo24Hour time24 %_time% %_ampm%
	set timeStamp=%_date% %time24%
	
	endlocal & (
		set %1=%timeStamp%
	)
goto :eof


:: ------------------------------------------

:ConvertTimeTo24Hour <time24> <time> <ampm>
	setlocal enabledelayedexpansion enableextensions
	
	if not %3==PM (
		set "_time24=%2"
	) else (
		set _time=%2
		set "m=!_time:~3,2!"
		if "!_time:~0,1!"=="0" (
			set "h=!_time:~1,1!"
		) else (
			set "h=!_time:~0,2!"
		)
		
		if !h!==12 (
			set /a h-=12
			set "h=0!h!:"
		) else (
			set /a h+=12
			set "h=!h!:"
		)
		
		set "_time24=!h!!m!"
	)
	
	endlocal & (
		set "%1=%_time24%"
	)
goto :eof


:: ----------------------------------------------------------------

:GetExternalType <result> <name>
	setlocal enabledelayedexpansion enableextensions

	set t=objectNotFound
	if exist %2 (
		if not exist %2\* ( 
			set t=file
		) else (
			set t=directory
		)
	)
	endlocal & (
		set "%1=%t%"
	)
goto :eof


:: ----------------------------------------------------------------

:StringReplace <result> <targetSymbol> <replacementSymbol> <source>
	setlocal enabledelayedexpansion enableextensions

	set targetSymbol=%~3
	set replacementSymbol=%~2
	set s=%4

	call set s=%%s:%replacementSymbol%=%targetSymbol%%%
	
	endlocal & (
		set "%1=%s%"
	)
goto :eof


:: ----------------------------------------------------------------

:PadSpacesLeft <result> <bufferSize> <source>
	setlocal enabledelayedexpansion enableextensions
	
	set /a bufferSize=%2
	set s0=                                                                                                                 %~3
	set s1=!s0:~-%bufferSize%!

	endlocal & (
		set "%1=%s1%"
	)
goto :eof


:: ----------------------------------------------------------------

:SplitLine <size> <user> <fileName> <listLine(will decompose)>
	setlocal enabledelayedexpansion enableextensions
	
	endlocal & (
		set "%1=%7"
		set "%2=%8"
		set "%3=%9"
	)
goto :eof


:: ----------------------------------------------------------------

:GetFileDetailLine <line> <name> <temporalContext[C|A|W]>
	setlocal enabledelayedexpansion enableextensions
	
	set command=dir /ogn /-c /4 /t%3 /q %2

	set /a i=0
	for /F "usebackq tokens=*" %%g in (`%command%`) do (
		if !i!==3 (
			set _line=%%g
			goto :GetFileDetailLineContinue
		)
		set /a i+=1
	)
	
	:GetFileDetailLineContinue

	endlocal & (
		set "%1=%_line%"
	)
goto :eof


:: ----------------------------------------------------------------
		
:PrintFileAttributes <name>
	setlocal enabledelayedexpansion enableextensions
	set length=21
	call :StripQuotes attributeOffset "   "
	call :StripQuotes space " "
	
	::if defined
	::set "condition=y"
	
	call :GetExecutionResult a "attrib %2"
	set attributes=!a:~0,%length%!
	::echo %attributes% ^(%length%^)

	:: t was turning up in use  TODO: find scope leak
	set t=
	
	set /a loopIndex=0
	:PrintFileAttributesLoop
	
		if !loopIndex!==%length% goto :PrintFileAttributesContinue
	
		set g="!attributes:~%i%,1!"
		
		if not %g%==" " (
			call :StripQuotes g !g!
			set "!g!=x"
		)
		
		set /a loopIndex+=1
		goto :PrintFileAttributesLoop
		
	:PrintFileAttributesContinue
	
	:: ------------------------------
	if defined R (
		set _mark=x
	) else (
		set _mark=.
	)
	
	call :PrintAttributeDescription R "%attributeOffset%" %_mark%

	:: ------------------------------
	if defined A (
		set _mark=x
	) else (
		set _mark=.
	)
	
	call :PrintAttributeDescription A "%attributeOffset%" %_mark%
	
	:: ------------------------------
	if defined S (
		set _mark=x
	) else (
		set _mark=.
	)
	
	call :PrintAttributeDescription S "%attributeOffset%" %_mark%
	
	:: ------------------------------
	if defined H (
		set _mark=x
	) else (
		set _mark=.
	)
	
	call :PrintAttributeDescription H "%attributeOffset%" %_mark%

	:: ------------------------------
	:: Extended
	if defined B call :PrintAttributeDescription B "%attributeOffset%"
	if defined E call :PrintAttributeDescription E "%attributeOffset%"
	if defined C call :PrintAttributeDescription C "%attributeOffset%"
	if defined I call :PrintAttributeDescription I "%attributeOffset%"
	if defined N call :PrintAttributeDescription N "%attributeOffset%"
	if defined O call :PrintAttributeDescription O "%attributeOffset%"
	if defined T call :PrintAttributeDescription T "%attributeOffset%"
	if defined X call :PrintAttributeDescription X "%attributeOffset%"
	if defined U call :PrintAttributeDescription U "%attributeOffset%"
	if defined V call :PrintAttributeDescription V "%attributeOffset%"
	
	endlocal
goto :eof


:: ----------------------------------------------------------------

:PrintAttributeDescription <letter> <(optional)pad> <(optional)mark>

	if %1==R echo %~2%3 R  Read-only
	if %1==A echo %~2%3 A  Archive
	if %1==S echo %~2%3 S  System
	if %1==H echo %~2%3 H  Hidden
	
	:: Show Extended only if set
	if %1==B echo %~2x B  SMB Blob
	if %1==E echo %~2x E  Encrypted
	if %1==C echo %~2x C  Compressed (128:read-only)
	if %1==I echo %~2x I  Not content-indexed
	if %1==N echo %~2x N  Normal
	if %1==O echo %~2x O  Offline
	if %1==T echo %~2x T  Temporary
	if %1==X echo %~2x X  No scrub
	if %1==U echo %~2x U  Unpinned
	if %1==V echo %~2x V  Integrity

	goto :eof

:: ----------------------------------------------------------------

:StripQuotes <reurn> <source>
	set %1=%~2
	goto :eof
	
	
:: ----------------------------------------------------------------

:GetLength <length> <string>
	setlocal enabledelayedexpansion enableextensions
	set s=%2Z

	set /a i=0
	:whileGetLength
		set c=!s:~%i%,1!
		if "%c%"=="Z" goto :continueGetLength
		set /a i+=1
		goto :whileGetLength
		
	:continueGetLength

	endlocal & (
		set "%1=%i%"
	)
goto :eof


:: ----------------------------------------------------------------

:GetExecutionResult <result> <command>
	setlocal enabledelayedexpansion enableextensions
	
	set command=%2
	
	for /f "usebackq tokens=*" %%a in (`!command!`) do set r=%%a
	
	endlocal & (
		set "%1=%r%"
	)
goto :eof


:: ----------------------------------------------------------------

:GetExternalType <result> <name>
	setlocal enabledelayedexpansion enableextensions

	set t=objectNotFound
	if exist %2 (
		if not exist %2\* ( 
			set t=file
		) else (
			set t=directory
		)
	)
	endlocal & (
		set "%1=%t%"
	)
goto :eof


:: ----------------------------------------------------------------
:: echo without newline
::
:: pros: no newline
::
:: cons:
::      Can't emit spaces or tabs
::      Leading quotes may be stripped
::      Leading white space may be stripped
::      Leading '=' causes a syntax error

:Emit <sourceWithoutSpacesOrTabs>
	<nul set /p =%1
	goto :eof


:: ----------------------------------------------------------------

:CommaFormat <formattedNumber> <number>
	setlocal enabledelayedexpansion enableextensions
	
	call :GetLength count %~2
	set s=Z%~2
	set s1=
	set /a i=count
	set /a j=0
	set /a limit=count-1

	:CommaFormatLoop
		set c=!s:~%i%,1!
		if "%c%"=="Z" goto :CommaFormatContinue
		
		set "s1=!c!!s1!"
		set /a k = j %% 3

		if %k%==2 if %j% lss %limit% set s1=,!s1!

		set /a i-=1
		set /a j+=1
	goto :CommaFormatLoop

	:CommaFormatContinue

	endlocal & (
		set "%1=%s1%"
	)
goto :eof
