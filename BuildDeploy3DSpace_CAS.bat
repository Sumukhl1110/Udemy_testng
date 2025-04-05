@echo off
setlocal

set server=D:\dsplm\products\R2017X\3dspace
set build=true
set deploy=true
set webappname=3dspace
set connectorPort=8090
set shutdownPort=9006
set ajpPort=9007
set version=R2017x
set jvmsize=medium

set serviceurl=https://3dspace.iut-nantes.univ-nantes.prive:8444
set	SWYM_URL=https://3dswym.iut-nantes.univ-nantes.prive:8446
set	PASSPORT_URL=https://3dpassport.iut-nantes.univ-nantes.prive:8443/3dpassport
set	SEARCH_URL=https://3dsearch.iut-nantes.univ-nantes.prive:8448/federated
set	ENOVIA_URL=https://3dspace.iut-nantes.univ-nantes.prive:8444
set	DASHBOARD_URL=https://3ddashboard.iut-nantes.univ-nantes.prive:8445/3ddashboard
set	MYAPPS_URL=https://3dspace.iut-nantes.univ-nantes.prive:8444/3dspace
set	SERVICE_URL=https://3dspace.iut-nantes.univ-nantes.prive:8444/3dspace
set COMMENT_URL=https://3dnotification.iut-nantes.univ-nantes.prive:8446/3dcomment
set NOTIFICATION_URL=https://3dnotification.iut-nantes.univ-nantes.prive:8446/3dnotification
set	MX_SMTP_HOST=smtp.univ-nantes.prive
set	MX_SMTP_SENDER=admin_platform@iut-nantes.univ-nantes.prive
set	MX_PAM_AUTHENTICATE_CLASS=com.dassault_systemes.plmsecurity.authentication.CASAuthenticationWithReauth
set	MX_PAM_AUTHENTICATE_ARG=remote_user

set do_jpo_compilation=false
set admin_user=creator

if "%SWYM_URL%"=="" set EnvVariables=PASSPORT_URL_EQUAL_%PASSPORT_URL%\0SEARCH_URL_EQUAL_%SEARCH_URL%\0ENOVIA_URL_EQUAL_%ENOVIA_URL%\0MYAPPS_URL_EQUAL_%MYAPPS_URL%\0SERVICE_URL_EQUAL_%MYAPPS_URL%\0DASHBOARD_URL_EQUAL_%DASHBOARD_URL%\0COMMENT_URL_EQUAL_%COMMENT_URL%\0NOTIFICATION_URL_EQUAL_%NOTIFICATION_URL%\0MX_SMTP_HOST_EQUAL_%MX_SMTP_HOST%\0MX_PAM_AUTHENTICATE_CLASS_EQUAL_%MX_PAM_AUTHENTICATE_CLASS%\0MX_PAM_AUTHENTICATE_ARG_EQUAL_%MX_PAM_AUTHENTICATE_ARG%\0MX_SMTP_SENDER_EQUAL_%MX_SMTP_SENDER%
if NOT "%SWYM_URL%"=="" set EnvVariables=SWYM_URL_EQUAL_%SWYM_URL%\0PASSPORT_URL_EQUAL_%PASSPORT_URL%\0SEARCH_URL_EQUAL_%SEARCH_URL%\0ENOVIA_URL_EQUAL_%ENOVIA_URL%\0MYAPPS_URL_EQUAL_%MYAPPS_URL%\0SERVICE_URL_EQUAL_%MYAPPS_URL%\0DASHBOARD_URL_EQUAL_%DASHBOARD_URL%\0COMMENT_URL_EQUAL_%COMMENT_URL%\0NOTIFICATION_URL_EQUAL_%NOTIFICATION_URL%\0MX_SMTP_HOST_EQUAL_%MX_SMTP_HOST%\0MX_PAM_AUTHENTICATE_CLASS_EQUAL_%MX_PAM_AUTHENTICATE_CLASS%\0MX_PAM_AUTHENTICATE_ARG_EQUAL_%MX_PAM_AUTHENTICATE_ARG%\0MX_SMTP_SENDER_EQUAL_%MX_SMTP_SENDER%
	
rem fixed
set os=win_b64

rem fixed
set serviceNameTomEE=3DSpaceTomEE

rem Activate Passport fragment
set fragments_path=%server%\%os%\resources\warutil\fragment

rem fragment holding Passport filters
set fragmentname=PassportAuthentication.web.xml.part
set fragmentname_orig=PassportAuthentication.web.xml.part.deactivated

rem emxSystem.properties
set file1=%server%\managed\properties\emxSystem.properties
set file1save=%server%\managed\properties\emxSystem.properties.sav

set file2=%server%\STAGING\ematrix\properties\emxSystem.properties
set file2save=%server%\STAGING\ematrix\properties\emxSystem.properties.sav

rem TomEE instances
set tomcat_install=%server%\%os%\code\tomcat\current
set tomcat_installNoCAS=%server%\%os%\code\tomcat\currentNoCAS

rem  remove previous backup of emxSystem.properties
echo removing backups of %file1% ...
if exist %file1save% del /Q %file1save% 
if exist %file2save% del /Q %file2save%

rem  make a copy of emxSystem.properties
echo Saving a copy of %file1% ...
copy %file1% %file1save% /V > NUL
copy %file2% %file2save% /V > NUL

rem activate external authentication in emxSystem.properties
echo Activating external authentication in emxSystem.properties files ...
cscript %server%\%os%\code\command\replace_string.vbs %file1% "emxFramework.External.Authentication = false" "emxFramework.External.Authentication = true" > NUL
cscript %server%\%os%\code\command\replace_string.vbs %file2% "emxFramework.External.Authentication = false" "emxFramework.External.Authentication = true" > NUL

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
	
	rem activate Passport fragment
	echo Activating Passport fragment ...
	if not exist %fragments_path%/%fragmentname% copy %fragments_path%\%fragmentname_orig% %fragments_path%\%fragmentname% /V 
	
	rem build J2EE archives
	call %server%\%os%\code\command\war_setup.bat %server%\%os%\code\command\war_setup.input	

	rem deactivating Passport fragment
	echo Deactivating Passport fragment ...
	if exist %fragments_path%\%fragmentname% del /Q %fragments_path%\%fragmentname% 
)

rem restore original properties files
echo Restoring original properties files ...
copy %file1save% %file1% /Y > NUL
copy %file2save% %file2% /Y > NUL
 
rem tomEE deployment
if "%deploy%"=="true" (

	echo Starting deployment step ...
	rem stop services
	echo Stopping %serviceNameTomEE%_%version%
	net stop %serviceNameTomEE%_%version% > NUL
	
	rem clean previous deployment
	if exist  %tomcat_install%\webapps\%webappname% (
		echo Cleaning %tomcat_install%\webapps\%webappname% ...
		rd /Q /S %tomcat_install%\webapps\%webappname%
	)
	
	rem copy webapp
	if exist %server%\distrib\%webappname% (
		echo Copying folder %webappname% into %tomcat_install%\webapps ...
		robocopy %server%\distrib\%webappname% %tomcat_install%\webapps\%webappname% /MIR > NUL
	)
	rem configure TomEE ports in server.xml
	echo Configuring %tomcat_install%\conf\server.xml ...
    cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_install%\conf\server.xml ".*Server port=.* shutdown=.*" %shutdownPort% SHUTDOWN > NUL
	cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_install%\conf\server.xml ".*Connector port=.* protocol=.*HTTP.*" %connectorPort% CONNECTION > NUL
	cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_install%\conf\server.xml ".*Connector port=.* protocol=.*AJP.*redirectPort.*" %ajpPort% AJP > NUL
	cscript %server%\%os%\code\command\replace_regexp.vbs %tomcat_install%\conf\server.xml ".*Host name=.*localhost.*appBase=.*" FAKE WEBAPPS > NUL
	
	rem create service 3DSpaceTomEE
	echo Creating service %serviceNameTomEE%_%version% ...
	
	rem last parameter "true" means CAS "on"
	call %server%\%os%\code\command\CreateTomcatService.bat %server% %webappname% %version% %jvmsize% %serviceNameTomEE% "true" %EnvVariables%
	
	TIMEOUT 5 > NUL
	
	echo Starting service %serviceNameTomEE%_%version% ...
	
	net start %serviceNameTomEE%_%version%
		
)

rem make a copy into distrib_CAS
if "%build%"=="true" (
	if exist %server%\distrib_CAS (
		echo Deleting folder %server%\distrib_CAS ...
		rd /Q /S %server%\distrib_CAS
	)
	echo Saving distrib folder and files into %server%\distrib_CAS ...
	robocopy %server%\distrib %server%\distrib_CAS /MIR > NUL
)


if NOT "%do_jpo_compilation%"=="false" GOTO :DO_JPO_COMPILE
if "%do_jpo_compilation%"=="false" GOTO :END

:DO_JPO_COMPILE
echo Starting JPO compilation ...
echo Enter %admin_user% 's password:
set /p creator_password=
if "%creator_password%" == "" ( set compile_cmd="set context user %admin_user% ; compile prog * force" )
if NOT "%creator_password%" == "" ( set compile_cmd="set context user %admin_user% password %creator_password% ; compile prog * force" )

call %server%\win_b64\code\bin\mql.exe -t -c %compile_cmd%
echo.
echo JPO compilation ended with code %ERRORLEVEL%
goto :END
	
:END
echo.
echo BuildDeploy3DSpace_CAS.bat ended.
