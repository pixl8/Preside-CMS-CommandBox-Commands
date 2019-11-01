/**
 * Start a PresideCMS server
 **/
component {

	property name="serverService"           inject="ServerService";
	property name="interceptorService"      inject="interceptorService";
	property name="commandboxHomeDirectory" inject="HomeDir@constants";
	property name="interactive"             default=true;

	/**
	 * @port.hint port number
	 * @openbrowser.hint open a browser after starting
	 * @directory.hint web root for this server
	 * @name.hint short name for this server
	 * @interactive.hint whether or not to prompt for preside mapping and datasource
	 * @stopPort.hint stop socket listener port number
	 * @force.hint force start if status is not stopped
	 * @debug.hint sets debug log level
	 * @trayIcon.hint Full path to image file to use for tray icon (Preside Puffin will be used by default)
	 **/
	function run(
		  String  directory    = ""
		, Numeric heapSize     = 1024
		, Boolean saveSettings = false
		, Boolean interactive  = true
		, Numeric port
		, Boolean openbrowser
		, String  name
		, Numeric stopPort
		, Boolean force
		, Boolean debug
		, String  trayIcon
	){
		var serverProps = arguments;
		var resourceDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/../../_resources";
		var osInfo      = CreateObject("java", "java.lang.System").getProperties();

		serverProps.directory      = fileSystemUtil.resolvePath( arguments.directory );
		serverProps.name           = serverProps.name is "" ? listLast( serverProps.directory, "\/" ) : serverProps.name;
		serverProps.rewritesEnable = true;
		serverProps.rewritesConfig = serverProps.directory & "/urlrewrite.xml";
		this.interactive           = arguments.interactive;

		if ( !serverProps.keyExists( "trayIcon" ) ) {
			if ( osInfo['os.name'].findNoCase( "Mac OS" ) || osInfo['os.name'].findNoCase( "Linux" ) ) {
				serverProps.trayIcon = resourceDir & "/trayicon_hires.png";
			} else {
				serverProps.trayIcon = resourceDir & "/trayicon.png";
			}
		}

		interceptorService.registerInterceptor( this );
		serverService.start( serverProps=serverProps );
	}

	function onServerStart( event, interceptData ) {
		_prepareDirectories( interceptData.serverInfo ?: {} );
	}

	/**
	 * Private method to setup the web config directories with Preside specific configuration
	 *
	 */
	private void function _prepareDirectories( required struct serverInfo ) {
		var webConfigDir      = serverInfo.webConfigDir;

		if ( webConfigDir.startsWith( "/WEB-INF" ) ) {
			webConfigDir = ( serverInfo.serverHomeDirectory ?: "" ) & webConfigDir;
		}

		var presideServerDir  = webConfigDir & "/preside";
		var resourceDir       = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/../../_resources";
		var presideInitedFile = webConfigDir & "/.presideinitialized";

		if ( !FileExists( presideInitedFile ) ) {
			if ( !DirectoryExists( webConfigDir ) ) {
				DirectoryCreate( webConfigDir, false, true );

				var sourceWebConfigDirectory = commandBoxHomeDirectory & "/engine/cfml/cli/cfml-web";
				if ( !DirectoryExists( sourceWebConfigDirectory ) ) {
					print.line();
					print.redLine("*************************************************************************************************************************************************************************");
					print.redLine("Could not find server files. Please ensure you have the latest version of CommandBox. Expected to find files at [#sourceWebConfigDirectory#]");
					print.redLine("*************************************************************************************************************************************************************************");
					print.line();

					return {};
				}

				DirectoryCopy( sourceWebConfigDirectory, webConfigDir, true );
			}
			var presideLocation = _setupPresideLocation( webConfigDir, serverInfo.webroot );
			var datasource      = this.interactive ? _setupDatasource() : "";

			var luceeWebXml = FileRead( resourceDir & "/lucee-web.xml.cfm" );
			luceeWebXml = ReplaceNoCase( luceeWebXml, "${presideLocation}", presideLocation );
			luceeWebXml = ReplaceNoCase( luceeWebXml, "${datasource}", datasource );
			FileWrite( webConfigDir & "/lucee-web.xml.cfm", luceeWebXml );
			FileWrite( webConfigDir & "/lucee-web.xml.cfm", luceeWebXml );
			FileWrite( presideInitedFile, "" );
		}
	}

	private string function _setupPresideLocation( required string webConfigDir, required string webroot ) {
		var presideLocation = arguments.webroot.reReplace( "[\\/]$", "" ) & "/preside";

		if ( FileExists( presideLocation & "/system/Bootstrap.cfc" ) ) {
			print.line().toConsole();
			print.yellowLine( "Using Preside location [#presideLocation#]..." ).toConsole();
			print.line().toConsole();

			return presideLocation;
		}

		if ( !this.interactive ) {
			return "";
		}

		print.line().toConsole();
		print.yellowLine( "PresideCMS core installation" ).toConsole();
		print.yellowLine( "============================" ).toConsole();
		print.line().toConsole();

		print.line().toConsole();
		var useLocalVersion = shell.ask( "Install fresh version of Preside [Y/n]? " ) == "n";
		if ( useLocalVersion ) {
			print.line().toConsole();
			presideLocation = shell.ask( "Enter the path to Preside: " );
			while( !DirectoryExists( presideLocation ) || !FileExists( presideLocation & "/system/Bootstrap.cfc" ) ) {
				print.redLine( "The path you entered is not a valid Preside path!").toConsole();
				presideLocation = shell.ask( "Enter the path to Preside: " );
			}

		} else {
			var validVersion   = false;
			var presideVersion = "";

			while ( !validVersion ) {
				validVersion = true;

				print.line().toConsole();
				while( ![ "s", "b" ].findNoCase( presideVersion ) ) {
					presideVersion  = shell.ask( "Which version of preside do you wish to install, (S)table or (B)leeding edge? [(S)/b]:" );
					if ( !Len( Trim( presideVersion ) ) ) {
						presideVersion = "s";
					}
				}
				presideLocation = "http://downloads.presidecms.com/presidecms/" & ( presideVersion == "b" ? "bleeding-edge.zip" : "release.zip" );

				var presideZip = GetTempDirectory() & "/PresideCMS.zip";
				try {
					print.line()
					     .yellowLine( "Downloading Preside from [#presideLocation#]... please be patient" ).toConsole();
					http getasBinary=true file=presideZip url=presideLocation throwOnError=true;
				} catch ( any e ) {
					validVersion = false;
					print.redLine( "Invalid preside version [#presideVersion#]. No download found at [#presideLocation#]." ).toConsole();
				}
			}

			print.yellowLine( "Download complete. Installing to [#arguments.webConfigDir#/preside]..." ).toConsole();

			zip action="unzip" file="#presideZip#" destination=arguments.webConfigDir & "/preside";

			var subDirs = DirectoryList( arguments.webConfigDir & "/preside", false, "query" );
			var versionDir  = "";
			for( var subDir in subDirs ){
				if ( subDir.type == "Dir" && ReFindNoCase( "^presidecms-[0-9\.]+$", subDir.name ) ) {
					versionDir = "/#subDir.name#";
					break;
				}
			}

			presideLocation = "{lucee-web}/preside#versionDir#";
		}

		return presideLocation;
	}

	private string function _setupDatasource() {
		print.line().toConsole();
		print.yellowLine( "PresideCMS datasource setup (MySQL Only)" ).toConsole();
		print.yellowLine( "========================================" ).toConsole();
		print.line().toConsole();

		if ( shell.ask( "Setup MySQL datasource now [Y/n]? " ) == "n" ) {
			return "";
		}

		print.line().toConsole();
		print.yellowLine( "If you have not done so already, please create your database and have credentials ready." ).toConsole();
		print.line().toConsole();

		var db    = shell.ask( "Database name: " );
		var usr   = shell.ask( "Username: " );
		var pass  = shell.ask( "Password: " );
		var host  = shell.ask( "Host (localhost): " );
		var port  = shell.ask( "Port (3306): " );
		while( Len( Trim( port ) ) && !IsNumeric( port ) ) {
			print.redLine( "Invalid port number!" ).toConsole();
			port = shell.ask( "Port (3306): " );
		}

		if( !Len( Trim( host ) ) ) { host = "localhost"; }
		if( !Len( Trim( port ) ) ) { port = "3306"; }

		return '<data-source allow="511" blob="false" class="org.gjt.mm.mysql.Driver" clob="true" connectionLimit="-1" connectionTimeout="1" custom="useUnicode=true&amp;characterEncoding=UTF-8" database="#db#" dsn="jdbc:mysql://{host}:{port}/{database}" host="#host#" metaCacheTimeout="60000" name="preside" password="#pass#" port="#port#" storage="false" username="#usr#" validate="false"/>';
	}
}
