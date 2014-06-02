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
		return serverService.start( serverInfo, arguments.openbrowser, arguments.force, arguments.debug );
	}

	/**
	 * Private method to setup the web config directories with Preside specific configuration
	 * 
	 */
	private void function _prepareDirectories( required struct serverInfo ) output=false {
		serverInfo.serverConfigDir = fileSystemUtil.resolveDirectory( shell.getHomeDir() & "/server/" );
		serverInfo.webConfigDir    = fileSystemUtil.resolveDirectory( shell.getHomeDir() & "/server/custom/" & serverInfo.name );

		var presideDir = fileSystemUtil.resolveDirectory( serverInfo.webConfigDir & "/preside" );
		var resourceDir = fileSystemUtil.resolveDirectory( GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/_resources" );

		if ( !DirectoryExists( serverInfo.webConfigDir ) ) {
			DirectoryCreate( serverInfo.webConfigDir );
		}
		if ( !DirectoryExists( presideDir ) ) {
			DirectoryCreate( presideDir );
			zip action="unzip" file="#resourceDir#/PresideServer.zip" destination="#presideDir#";
			var webxml = FileRead( presideDir   & "/web.xml" );
			webxml = ReplaceNoCase( webxml, "${webConfigDir}", serverInfo.webConfigDir, "all" );
			webxml = ReplaceNoCase( webxml, "${serverConfigDir}", serverInfo.serverConfigDir, "all" );
			FileWrite( presideDir & "/web.xml", webxml );
		}


		serverInfo.libDirs  = fileSystemUtil.resolveDirectory( presideDir  & "/lib" );
		serverInfo.webXml   = fileSystemUtil.resolveDirectory( presideDir  & "/web.xml" );
		serverInfo.trayIcon = fileSystemUtil.resolveDirectory( resourceDir & "/trayicon.png" );
	}

}