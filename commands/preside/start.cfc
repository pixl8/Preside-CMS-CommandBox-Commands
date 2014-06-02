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
		serverInfo.serverConfigDir = shell.getHomeDir() & "/server";

		var webDir      = serverInfo.serverConfigDir & "/custom/" & serverInfo.name;
		var presideDir  = webDir & "/preside";
		var resourceDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/_resources";
		
		serverInfo.webConfigDir    = webDir & "/web";

		if ( !DirectoryExists( webDir ) ) {
			DirectoryCreate( webDir );
		}
		if ( !DirectoryExists( serverInfo.webConfigDir ) ) {
			DirectoryCopy( serverInfo.serverConfigDir & "/railo-web", serverInfo.webConfigDir );
			FileCopy( resourceDir & "/railo-web.xml.cfm", serverInfo.webConfigDir & "/railo-web.xml.cfm" );

			// TODO: something MUCH better here please!
			// i.e. allow user to select version of preside, etc.
			var presideZip = "#resourceDir#/PresideCMS-0.1.0.zip";			
			if ( !FileExists() ) {
				http getasBinary=true file=presideZip url="http://downloads.presidecms.com/stable/PresideCMS-0.1.0.zip";
			}
			zip action="unzip" file="#resourceDir#/PresideCMS-0.1.0.zip" destination=serverInfo.webConfigDir;

		}
		if ( !DirectoryExists( presideDir ) ) {
			DirectoryCreate( presideDir );
			zip action="unzip" file="#resourceDir#/PresideServer.zip" destination=presideDir;
			var webxml = FileRead( presideDir   & "/web.xml" );
			webxml = ReplaceNoCase( webxml, "${webConfigDir}"   , serverInfo.webConfigDir, "all" );
			webxml = ReplaceNoCase( webxml, "${serverConfigDir}", serverInfo.serverConfigDir, "all" );
			FileWrite( presideDir & "/web.xml", webxml );
		}


		serverInfo.libDirs  = presideDir  & "/lib";
		serverInfo.webXml   = presideDir  & "/web.xml";
		serverInfo.trayIcon = resourceDir & "/trayicon.png";
	}

}