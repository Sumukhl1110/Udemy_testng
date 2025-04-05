@echo off
setlocal

set server=D:\dsplm\products\R2017X\3dspace
set build=true
set deploy=true
set webappname=internal
set connectorPort=8070
set shutdownPort=9056
set ajpPort=9057
set version=R2017x
set jvmsize=medium

rem fixed
set os=win_b64

rem TomEE instances
set tomcat_install=%server%\%os%\code\tomcat\current
set tomcat_installNoCAS=%server%\%os%\code\tomcat\currentNoCAS

set serviceNameTomEE=3DSpaceTomEENoCAS

rem check level
fc "%tomcat_install%\RELEASE-NOTES" "%tomcat_installNoCAS%\RELEASE-NOTES" > NUL
set RC=%ERRORLEVEL%

rem build war files
if "%build%"=="true" (
	echo Starting build step ...
	rem clean folders and inputs
	if exist %server%\distrib (
		echo Deleting folder %server%\distrib ...
		rd /Q /S %server%\distrib	
	)
	
	if exist %server%\%os%\code\command\war_setup.input (
		echo Deleting file %server%\%os%\code\command\war_setup.input ...
		del /Q %server%\%os%\code\command\war_setup.input
    )
		
	rem generate input file for warutil
	echo Creating file %server%\%os%\code\command\war_setup.input ...
	echo SERVERPATH=%server%>> %server%\%os%\code\command\war_setup.input
	echo WEBAPPS=%webappname%>> %server%\%os%\code\command\war_setup.input
	
	rem build J2EE archives
	call %server%\%os%\code\command\war_setup.bat %server%\%os%\code\command\war_setup.input		
)

rem tomEE deployment
if "%deploy%"=="true" (

	echo Starting deployment step ...
	rem stop services
	echo Stopping %serviceNameTomEE%_%version%
	net stop %serviceNameTomEE%_%version% > NUL
	
	if exist %tomcat_installNoCAS% (
		if %RC% == 0 (
			rem clean previous deployment
			if exist  %tomcat_installNoCAS%\webapps\%webappname% (
				echo Cleaning %tomcat_installNoCAS%\webapps\%webappname% ...
				rd /Q /S %tomcat_installNoCAS%\webapps\%webappname%
			)
			
			rem copy webapp
			if exist %server%\distrib\%webappname% (
				echo Copying folder %webappname% into %tomcat_installNoCAS%\webapps ...
				robocopy %server%\distrib\%webappname% %tomcat_installNoCAS%\webapps\%webappname% /MIR > NUL
			)	
		)
		
		if %RC% == 1 (
			echo "RELEASE-NOTES files are different - tomEE code needs to be updated ..."
			if exist  %tomcat_installNoCAS% (
				echo Cleaning %tomcat_installNoCAS% ...
				rd /Q /S %tomcat_installNoCAS%
			)
			
			echo Initializing %tomcat_installNoCAS% ...
			robocopy "%tomcat_install%" "%tomcat_installNoCAS%" /MIR > NUL
					
			if exist  %tomcat_installNoCAS%\webapps (
				echo Cleaning %tomcat_installNoCAS%\webapps ...
				rd /Q /S %tomcat_installNoCAS%\webapps
				md %tomcat_installNoCAS%\webapps
			)
			
			rem copy webapp
			if exist %server%\distrib\%webappname% (
				echo Copying folder %webappname% into %tomcat_installNoCAS%\webapps ...
				robocopy %server%\distrib\%webappname% %tomcat_installNoCAS%\webapps\%webappname% /MIR > NUL
			)	
		)
	)
	
	if not exist %tomcat_installNoCAS% ( 
		echo Initializing %tomcat_installNoCAS% ...
		robocopy "%tomcat_install%" "%tomcat_installNoCAS%" /MIR > NUL
		
		rem copy webapp
		if exist %server%\distrib\%webappname% (
			echo Copying folder %webappname% into %tomcat_installNoCAS%\webapps ...
			robocopy %server%\distrib\%webappname% %tomcat_installNoCAS%\webapps\%webappname% /MIR > NUL
		)		
	)
	
	rem configure TomEE ports in server.xml
	echo Configuring %tomcat_installNoCAS%\conf\server.xml ...
    cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_installNoCAS%\conf\server.xml ".*Server port=.* shutdown=.*" %shutdownPort% SHUTDOWN > NUL
	cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_installNoCAS%\conf\server.xml ".*Connector port=.* protocol=.*HTTP.*" %connectorPort% CONNECTION > NUL
	cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_installNoCAS%\conf\server.xml ".*Connector port=.* protocol=.*AJP.*redirectPort.*" %ajpPort% AJP > NUL
	cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_installNoCAS%\conf\server.xml ".*Host name=.*localhost.*appBase=.*" FAKE WEBAPPS > NUL
	
	rem create service 3DSpaceTomEE
	echo Creating service %serviceNameTomEE%_%version% ...
	call %server%\%os%\code\command\CreateTomcatService.bat %server% %webappname% %version% %jvmsize% %serviceNameTomEE% "false"
	
	TIMEOUT 5 > NUL
	
	echo Starting service %serviceNameTomEE%_%version% ...
	net start %serviceNameTomEE%_%version%
	
	TIMEOUT 5 > NUL
)

rem make a copy into distrib_NoCAS
if "%build%"=="true" (
	if exist %server%\distrib_NoCAS (
		echo Deleting folder %server%\distrib_NoCAS ...
		rd /Q /S %server%\distrib_NoCAS
	)
	echo Saving distrib folder and files into %server%\distrib_NoCAS ...
	robocopy %server%\distrib %server%\distrib_NoCAS /MIR > NUL
)

echo BuildDeploy3DExp_NoCAS.bat ended.
