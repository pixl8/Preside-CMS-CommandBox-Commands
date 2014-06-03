/**
 * Start a PresideCMS server
 **/
component extends="commandbox.system.BaseCommand" excludeFromHelp=false {

	property name="serverService" inject="ServerService";
	
	/**
	 * @port.hint port number
	 * @openbrowser.hint open a browser after starting
	 * @directory.hint web root for this server
	 * @name.hint short name for this server
	 * @stopPort.hint stop socket listener port number
	 * @force.hint force start if status is not stopped
	 * @debug.hint sets debug log level
	 **/
	function run( 
		Numeric port=0,
		Boolean openbrowser=true,
		String directory="",
		String name="",
		Numeric stopPort=0,
		Boolean force=false,
		Boolean debug=false
	){
		// prepare webroot and short name
		var webroot = arguments.directory is "" ? shell.pwd() : arguments.directory;
		var name 	= arguments.name is "" ? listLast( webroot, "\/" ) : arguments.name;
		webroot = fileSystemUtil.resolveDirectory( webroot );
		
		// get server info record, create one if this is the first time.
		var serverInfo = serverService.getServerInfo( webroot );
		// we don't want to changes the ports if we're doing stuff already
		if( serverInfo.status is "stopped" || arguments.force ){
			serverInfo.name = name;
			serverInfo.port = arguments.port;
			serverInfo.stopsocket = arguments.stopPort;
		}
		serverInfo.webroot 	= webroot;
		serverInfo.debug 	= arguments.debug;

		_prepareDirectories( serverInfo );

		// startup the service using server info struct
		print.line();
		print.greenLine("***********************************************************************************************************************************");
		print.greenLine( serverService.start( serverInfo, arguments.openbrowser, arguments.force, arguments.debug ) );
		print.greenLine("***********************************************************************************************************************************");
		print.line();
	}

	/**
	 * Private method to setup the web config directories with Preside specific configuration
	 * 
	 */
	private void function _prepareDirectories( required struct serverInfo ) output=true {
		serverInfo.serverConfigDir = shell.getHomeDir() & "/server";

		var webDir      = serverInfo.serverConfigDir & "/custom/" & serverInfo.name;
		var presideServerDir  = webDir & "/preside";
		var resourceDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/_resources";
		
		serverInfo.webConfigDir    = webDir & "/web";

		if ( !DirectoryExists( webDir ) ) {
			print.yellowLine( "Setting up your Preside server for first time use..." ).toConsole();
			DirectoryCreate( webDir );
		}
		if ( !DirectoryExists( serverInfo.webConfigDir ) ) {
			DirectoryCopy( serverInfo.serverConfigDir & "/railo-web", serverInfo.webConfigDir, true );

			print.line().toConsole();
			var presideLocation = shell.ask( "Install fresh version of Preside [Y/n]? " );
			if ( presideLocation == "n" ) {
				print.line().toConsole();
				var presideLocation = shell.ask( "Enter the path to Preside: " );
				while( !DirectoryExists( presideLocation ) && !FileExists( presideLocation & "/system/BaseApplication.cfc" ) ) {
					print.redLine( "The path you entered is not a valid Preside path!").toConsole();
					presideLocation = shell.ask( "Enter the path to Preside: " );
				}

			} else {
				var validVersion = false;

				while ( !validVersion ) {
					validVersion = true;
					print.line().toConsole();
					presideVersion  = shell.ask( "Which version of preside do you wish to install? (0.1.0) " );
					if ( !Len( Trim( presideVersion ) ) ) {
						presideVersion = "0.1.0";
					}
					presideLocation = "http://downloads.presidecms.com/bleeding-edge/PresideCMS-#presideVersion#.zip"; // in future this would be handled MUCH better!
					
					var presideZip = GetTempDirectory() & "/PresideCMS-#presideVersion#.zip";
					try {
						print.line( "Downloading Preside from [#presideLocation#]... please be patient" ).toConsole();
						http getasBinary=true file=presideZip url=presideLocation throwOnError=true;
					} catch ( any e ) {
						validVersion = false;
						print.redLine( "Invalid preside version [#presideVersion#]. No download found at [#presideLocation#]." ).toConsole();
					}
				}
				
				zip action="unzip" file="#presideZip#" destination=serverInfo.webConfigDir;

				presideLocation = "{railo-web}/preside";
			}

			var railoWebXml = FileRead( resourceDir & "/railo-web.xml.cfm" );
			railoWebXml = ReplaceNoCase( railoWebXml, "${presideLocation}", presideLocation );
			FileWrite( serverInfo.webConfigDir & "/railo-web.xml.cfm", railoWebXml );
		}
		if ( !DirectoryExists( presideServerDir ) ) {
			DirectoryCreate( presideServerDir );
			zip action="unzip" file="#resourceDir#/PresideServer.zip" destination=presideServerDir;
			var webxml = FileRead( presideServerDir   & "/web.xml" );
			webxml = ReplaceNoCase( webxml, "${webConfigDir}"   , serverInfo.webConfigDir, "all" );
			webxml = ReplaceNoCase( webxml, "${serverConfigDir}", serverInfo.serverConfigDir, "all" );
			FileWrite( presideServerDir & "/web.xml", webxml );
		}

		serverInfo.libDirs  = presideServerDir  & "/lib";
		serverInfo.webXml   = presideServerDir  & "/web.xml";
		serverInfo.trayIcon = resourceDir & "/trayicon.png";
	}

}