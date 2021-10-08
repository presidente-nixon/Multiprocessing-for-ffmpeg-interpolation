@echo off
setlocal enabledelayedexpansion
color 0a
title Multiprocessing for FFmpeg Interpolation v0.5-alpha
echo Multiprocessing for FFmpeg Interpolation v0.5-alpha-github.com/presidente-nixon/Multiprocessing-for-FFmpeg-Interpolation Copyright (c) 2021 presidente_nixon
rem Multiprocessing for FFmpeg Interpolation v0.5-alpha-github.com/presidente-nixon/Multiprocessing-for-FFmpeg-Interpolation Copyright (c) 2021 presidente_nixon

rem dynamicRange: Either sdr(standard dynamic range) or hdr(high dynamic range)
set dynamicRange=%2
rem instances: how many threads the program will use
set /a instances=%4
rem encoder: encoding for interpolation, either h264 or hevc
set encoder=%6

echo checking the inputs
if not !encoder!==h264 if not !encoder!==hevc (
	echo encoder type not valid.
	if not !dynamicRange!==sdr if not !dynamicRange!==hdr (
		echo dynamic range type not valid.
	)
	
	if !instances! gtr 128 (
		echo instances amount not valid.
	)
	
	pause
	exit
)	

if not !dynamicRange!==sdr if not !dynamicRange!==hdr (
	echo dynamic range type not valid.
	if !instances! gtr 128 (
		echo instances amount not valid.
	)
	
	pause
	exit
)

if !instances! gtr 128 (
	echo instances amount not valid.
	pause
	exit
)

echo inputs valid

rem fileType: input file type
set fileType=%1
rem fileType: input file location
set inLocation=%3
rem interpolatedRate: output fps
set /a interpolatedRate=%5
rem fileType: output file location
set outLocation=%7

echo creating workspace
cd ..
md input
md output
md workspace

echo copying input files to input folder
for %%a in ("!inLocation!\*.!fileType!") do (
	rem input file name with file format and directory
	set fileName=%%a
	
	xcopy "!fileName!" input /c /y
)

cd input
for %%a in ("*.!fileType!") do (
	rem input file name with file format
	set fileName=%%a
	rem input file name
	set name=!fileName:~0,-4!
	
	echo reading resolution of !fileName!
	cd ..
	for /f "usebackq tokens=* delims=" %%b in (`externals\ffprobe -v error -select_streams v:0 -show_entries stream^=width,height -of csv^=s^=x:p^=0 "input\!fileName!" 2^>^&1`) do (
		set /a resolution=%%b
	)
	
	echo calculating bitrate and maxbitrate
	if !resolution!==1920x1080 (
		if !interpolatedRate! leq 30 (
			if !dynamicRange!==sdr (
				set /a bitrate=8
				set /a maxBitrate=10
			) else (
				set /a bitrate=10
				set /a maxBitrate=12
			)
		) else (
			if !dynamicRange!==sdr (
				set /a bitrate=12
				set /a maxBitrate=15
			) else (
				set /a bitrate=15
				set /a maxBitrate=16
			)
		)
	) else if !resolution!==1280x720 (
		if !interpolatedRate! leq 30 (
			if !dynamicRange!==sdr (
				set /a bitrate=5
				set /a maxBitrate=7
			) else (
				set /a bitrate=7
				set /a maxBitrate=8
			)
		) else (
			if !dynamicRange!==sdr (
				set /a bitrate=8
				set /a maxBitrate=10
			) else (
				set /a bitrate=10
				set /a maxBitrate=12
			)
		)
	) else if !resolution!==2560x1440 (
		if !interpolatedRate! leq 30 (
			if !dynamicRange!==sdr (
				set /a bitrate=16
				set /a maxBitrate=20
			) else (
				set /a bitrate=20
				set /a maxBitrate=24
			)
			) else (
			if !dynamicRange!==sdr (
					set /a bitrate=24
				set /a maxBitrate=30
			) else (
				set /a bitrate=30
				set /a maxBitrate=35
			)
		)
	) else if !resolution!==3840x2160 (
		if !interpolatedRate! leq 30 (
			if !dynamicRange!==sdr (
				set /a bitrate=35
				set /a maxBitrate=45
			) else (
				set /a bitrate=44
				set /a maxBitrate=56
			)
		) else (
			if !dynamicRange!==sdr (
				set /a bitrate=53
				set /a maxBitrate=68
			) else (
				set /a bitrate=66
				set /a maxBitrate=85
			)
		)
	) else if !resolution!==852x480 (
		if !interpolatedRate! leq 30 (
			set /a bitrate=3
			set /a maxBitrate=4
		) else (
			set /a bitrate=4
			set /a maxBitrate=5
		)
	) else if !resolution!==480x360 (
		if !interpolatedRate! leq 30 (
			set /a bitrate=1
			set /a maxBitrate=2
		) else (
			set /a bitrate=2
			set /a maxBitrate=3
		)
	) else (
		set /a bitrate=66
		set /a maxBitrate=85
	)
	
	echo bitrate and maxbitrate calculated, now saving
	echo !bitrate! > workspace\!name!_settings.txt
	echo !maxBitrate! >> workspace\!name!_settings.txt
	echo !encoder! >> workspace\!name!_settings.txt
	cd input
)

cd ..
for /l %%a in (1,1,!instances!) do (
	set /a instance=%%a
	
	echo setting up subworkspace!instance!
	md workspace\subworkspace!instance!\sub-out
	xcopy externals\algorithm.bat workspace\subworkspace!instance! /c /y
	
	cd input
	for %%b in ("*.!fileType!") do (
		rem input file name with file format
		set fileName=%%b
		rem input file name
		set name=!fileName:~0,-4!
		rem output file name
		set outName=workspace\subworkspace!instance!\!name!
		
		echo reading file duration
		cd ..
		for /f "usebackq tokens=* delims=" %%c in (`externals\ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "input\!fileName!" 2^>^&1`) do (
			set /a duration=%%c
		)
		
		echo calculating split videos durations
		set /a newDuration=!duration!/!instances!
		set /a start=!instance!*!newDuration!-!newDuration!
		set /a end=!newDuration!*!instance!
		
		echo splitting
		externals\ffmpeg -i "input\!fileName!" -ss !start! -to !end! -c copy "!outName! #!instance!.mkv"
		cd input
	)
	
	rem starting the interpolation software
	cd ..
	cd workspace\subworkspace!instance!
	echo starting algorithm!instance!
	start /b algorithm !instance! !fileType! !instances! !interpolatedRate! !outLocation!
	cd ../..
)

cd externals
exit