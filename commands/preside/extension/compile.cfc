/**
 * Start a PresideCMS server
 **/
component {

	property name="serverService"           inject="ServerService";
	property name="interceptorService"      inject="interceptorService";
	property name="commandboxHomeDirectory" inject="HomeDir@constants";

	/**
	 * @sourceDir.hint    Source directory containing extension to compile
	 * @targetDir.hint    Target directory where compiled source will be placed (defaults to same location as source directory)
	 * @luceeVersion.hint Version of Lucee to compile against (defaults to 5.3.2)
	 * @force.hint        Whether or not to go ahead without prompting (default is false)
	 *
	 **/
	function run(
		  string  sourceDir    = "./"
		, string  targetDir    = arguments.sourceDir
		, numeric luceeVersion = "5.3.2"
		, boolean force        = false
	){
		var source  = fileSystemUtil.resolvePath( sourceDir );
		var target  = fileSystemUtil.resolvePath( targetDir );
		var confirm = arguments.force ? "Y" : "";


		while( confirm != "Y" && confirm != "N" ) {
			confirm = ask( "This command will compile all cfml files under [#source#] and deploy to [#target#]. Are you sure you wish to continue? [Y/N]" );
		}

		if ( confirm == "Y" ) {
			_stopServer();
			_startCompilerServer( arguments.luceeVersion );
			_doCompile( source, target );
			_stopServer();
		} else {
			print.line();
			print.yellowLine( "------------------------------------" );
			print.yellowLine( "Compile operation cancelled by user." );
			print.yellowLine( "------------------------------------" );
			print.line();
		}
	}

// private utility
	private void function _startCompilerServer( luceeVersion ) {
		var serverRoot  = fileSystemUtil.resolvePath( GetDirectoryFromPath( GetCurrentTemplatePath() ) & "../../../_resources/extensionCompiler" );
		var serverProps = {
			  cfEngine         = "lucee@#luceeVersion#"
			, serverConfigFile = serverRoot & "/server.json"
			, directory        = serverRoot
			, saveSettings     = false
		};

		print.printLine();
		print.yellowLine( "--------------------------------------------");
		print.yellowLine( "Starting up server to perform compilation...");
		print.yellowLine( "--------------------------------------------");
		serverService.start( serverProps=serverProps );
	}

	private void function _doCompile( sourceDir, targetDir ) {
		var result = "";
		var attempts = 0;

		while( !_serverIsRunning() && ++attempts <= 10 ) {
			wait( 1000 );
		}

		if ( !_serverIsRunning() ) {
			print.redLine( "Server startup timed out. Abandoning." );
		}

		http url="http://127.0.0.1:1337" method="get" result="result" {
			httpparam type="url" name="sourceDir" value=arguments.sourceDir;
			httpparam type="url" name="targetDir" value=arguments.targetDir;
		}

		if ( Val( result.status_code ?: "" ) == 200 ) {
			print.greenLine( result.fileContent ) ;
		} else {
			print.redLine( result.fileContent ) ;
		}
	}

	private void function _stopServer() {
		if ( _serverIsRunning() ) {
			serverService.stop( serverService.getServerInfoByName( "presideextensioncompiler" ) );
		}
	}

	private boolean function _serverIsRunning() {
		var serverInfo = serverService.getServerInfoByName( "presideextensioncompiler" );

		return !StructIsEmpty( serverInfo ) && serverService.isServerRunning( serverInfo );
	}
}
