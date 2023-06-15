/**
 * Start a Preside Application server. This is proxy to server start
 * with some specific cfconfig configuration for Preside.
 **/
component {

	property name="interceptorService" inject="interceptorService";
	property name="moduleService"      inject="moduleService";

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
		, Boolean interactive  = true
		, String  serverConfigFile = "server.json"
		, String  trayIcon
	){
		if ( !moduleService.isModuleActive( "commandbox-cfconfig") ) {
			print.redLine( "=================================================================" );
			print.redLine( "CRITICAL ERROR: cfconfig not installed/enabled." );
			print.redLine( "The preside start command relies on cfconfig to persist settings." );
			print.line();
			print.redLine( "Either:"                                                         );
			print.redLine( "1. Ensure CommandBox is up to date (comes with cfconfig)"        );
			print.redLine( "2. Install cfconfig separately: box install commandbox-cfconfig" );
			print.redLine( "=================================================================" ).toConsole();
			return;
		}
		var serverProps = arguments;
		var osInfo      = CreateObject("java", "java.lang.System").getProperties();
		var resourceDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/../../_resources";

		serverProps.directory        = fileSystemUtil.resolvePath( arguments.directory );
		serverProps.saveSettings     = true;
		serverProps.rewritesEnable   = true;
		serverProps.rewritesConfig   = serverProps.rewritesConfig ?: ( serverProps.directory & "/urlrewrite.xml" );

		if ( !serverProps.keyExists( "trayIcon" ) ) {
			if ( osInfo['os.name'].findNoCase( "Mac OS" ) || osInfo['os.name'].findNoCase( "Linux" ) ) {
				serverProps.trayIcon = resourceDir & "/trayicon_hires.png";
			} else {
				serverProps.trayIcon = resourceDir & "/trayicon.png";
			}
		}

		_ensureCfConfigSetup( argumentCollection=serverProps );

		if ( serverProps.directory == fileSystemUtil.resolvePath( "" ) ) {
			StructDelete( serverProps, "directory" );
		}

		interceptorService.registerInterceptor( this );

		command( "server start" ).params( argumentCollection=serverProps ).run();
	}

	public void function onServerStart( interceptData ) {
		var path       = interceptData.serverInfo.webroot;
		var rootAppCfc = path.listAppend( "application/config/Config.cfc", "/" );

		if ( FileExists( rootAppCfc ) ) {
			var result = ReMatchNoCase('(?:settings.preside_admin_path[ ]*=[ ]*)[""'']{1}(\w+_?\w+)[""'']{1}', FileRead( rootAppCfc ) );
			var finalR = ReReplaceNoCase( result[1], 'settings.preside_admin_path[ ]*=[ ]*[""'']{1}(\w+_?\w+)[""'']{1}', "\1");

			interceptData.serverInfo.trayOptions = interceptData.serverInfo.trayOptions ?: [];
			ArrayInsertAt( interceptData.serverInfo.trayOptions, ArrayLen( interceptData.serverInfo.trayOptions ), {
				"label":"Preside",
				"items": [
					{ 'label':'Site Home', 'action':'openbrowser', 'url': interceptData.serverInfo.openbrowserURL },
					{ 'label':'Site Admin', 'action':'openbrowser', 'url': '#interceptData.serverInfo.openbrowserURL#/#finalR#/' }
				],
				"image" : ""
			} );
		}
	}

	private function _ensureCfConfigSetup() {
		var cfconfigFilePath = _getCfConfigFilePath( argumentCollection=arguments );

		print.line( "Checking/creating your cfconfig file at: [#cfconfigFilePath#]..."                    );
		print.line( "NOTE: this is used to set Preside specific configuration and save your datasource. You should almost certainly ensure that this file is NOT commited to version control." ).toConsole();
		print.line( "      You can also consult the CFConfig documentation to use this file to control other aspects of your Commandbox server." ).toConsole();

		if ( !FileExists( cfconfigFilePath ) ) {
			FileWrite( cfconfigFilePath, "{}" );
		}

		var cfconfig = DeserializeJson( FileRead( cfconfigFilePath ) );

		if ( !Len( Trim( cfconfig.datasources.preside.database ?: "" ) ) ) {
			cfconfig[ "datasources" ] = cfconfig.datasources ?: {};
			cfconfig.datasources[ "preside" ] = _setupDatasource( argumentCollection=arguments );

			print.linLine( " " );
			print.greenLine( "Thank you! If you have any issues with your datasource, you can configure in [#cfconfigFilePath#]" ).toConsole();
		}

		cfconfig[ "templateCharset"      ] = cfconfig.templateCharset ?: "UTF-8";
		cfconfig[ "webCharset"           ] = cfconfig.webCharset      ?: "UTF-8";
		cfconfig[ "resourceCharset"      ] = cfconfig.resourceCharset ?: "UTF-8";
		cfconfig[ "resourceCharset"      ] = cfconfig.resourceCharset ?: "UTF-8";
		cfconfig[ "dotNotationUpperCase" ] = false;

		FileWrite( cfconfigFilePath, formatterUtil.formatJson( cfconfig ) );

		print.line()
		print.line( "Checks complete. Starting your server now..." ).toConsole();
	}

	private string function _getCfConfigFilePath() {
		var serverConfPath = arguments.directory & arguments.serverConfigFile;
		if ( !FileExists( serverConfPath ) ) {
			FileWrite( serverConfPath, formatterUtil.formatJson( { "web"={ "webroot"=arguments.directory }} ) );
		}
		var serverConf = SerializeJson( FileRead( serverConfPath ) );
		var possibleKeys = [ "file", "server", "web" ];
		var relFilePath  = "";

		for( var key in possibleKeys ) {
			if ( Len( serverConfig.cfconfig[ key ] ?: "" ) ) {
				relFilePath = serverConfig.cfconfig[ key ];
			}
		}

		if ( !Len( relFilePath ) && Len( serverConfig.cfconfigFile ?: "" ) ) {
			relFilePath = serverConfig.cfconfigFile;
		}

		if ( !Len( relFilePath ) ) {
			relFilePath = ".cfconfig.json";
			serverConfig[ "cfconfig" ] = serverConfig[ "cfconfig" ] ?: {};
			serverConfig.cfconfig[ "file" ] = relFilePath;

			FileWrite( serverConfPath, formatterUtil.formatJson( serverConfig ) );
		}

		return arguments.directory & relFilePath;

	}

	private function _setupDatasource() {
		print.line();
		print.greenLine( "PRESIDE DATASOURCE SETUP" );
		print.greenLine( "========================" );
		print.greenLine( "No Preside Datasource found. Starting wizard to create one."   );
		print.greenLine( "NOTE: You can configure using your datasource independently in your .cfconfig file if you require a more complex datasource configuration." );
		print.line().toConsole();

		var config = {}

		config[ "dbdriver" ] =  multiselect( 'Select your database engine: ' ).options( [
			{ display='MySQL/MariaDB', value='mysql', selected=true },
			{ display='PostgreSQL', value='postgres' },
			{ display='Microsoft SQL Server', value='MSSQL' }
		] ).required().ask();

		config[ "database" ] = ask( message="Database name: ", required=true );
		config[ "username" ] = ask( message="Username: " );
		config[ "password" ] = ask( message="Password: ", mask='*' );
		config[ "host"     ] = ask( message="Host: ", defaultResponse="localhost" );
		config[ "port"     ] = ask( message="Port: ", defaultResponse=_getDefaultPortForDb( config.dbdriver ) );

		return config;
	}

	private function _getDefaultPortForDb( dbdriver ) {
		switch( arguments.dbdriver) {
			case "mssql": return 1433;
			case "postgres": return 5432;
			default: return 3306;
		}
	}
}
