/**
 * Scaffold a new PresideCMS site, e.g.
 * > preside new site "my-site"
 **/
component extends="commandbox.system.BaseCommand" excludeFromHelp=false {

	property name="packageService" inject="PackageService";
	property name="wirebox"        inject="wirebox";

	variables._skeletonMap = {
		  "basic" = "preside-skeleton-basic"
		, "nocms" = "preside-skeleton-webapp"
	};

	/**
	 * @siteid.hint         id of your site. Must contain alphanumerics, underscores and hyphens only
	 * @skeleton.hint       The name of the app skeleton to use. Options: basic, nocms
	 * @skeleton.optionsUDF skeletonComplete
	 **/
	function run(
		  required string siteid
		, required string skeleton
	) {
		var directory = shell.pwd();
		var adminPath = arguments.siteid & "_admin"

		if ( !_validSlug( arguments.siteId    ) ) {
			return _printError( "Invalid site id. Site id must contain alphanumerics, underscores and hyphens only." );
		}

		if( variables._skeletonMap.keyExists( arguments.skeleton ) ) {
			arguments.skeleton = variables._skeletonMap[ arguments.skeleton ];
		}

		packageService.installPackage(
			  id                      = arguments.skeleton
			, directory               = directory
			, save                    = false
			, saveDev                 = false
			, production              = true
			, currentWorkingDirectory = directory
		);

		_replacePlaceholdersWithArgs( argumentCollection=arguments, directory=directory, adminPath=adminPath );
		_runPostInstallScripts( argumentCollection=arguments, directory=directory, adminPath=adminPath );

		print.line();
		print.greenLine( "*****************************************************************************************" );
		print.greenLine( "Your site has been successfully initialised. Type 'preside start' to start a server here." );
		print.greenLine( "*****************************************************************************************" );
		print.line();

		return;
	}

// PRIVATE HELPERS
	private boolean function _validSlug( required string slug ) {
		return ReFindNoCase( "^[a-z0-9-_]+$", arguments.slug );
	}

	private void function _printError( errorMessage ) {
		print.line();
		print.redLine( arguments.errorMessage );
		print.line();
	}

	private void function _replacePlaceholdersWithArgs( required string siteId, required string adminPath, required string directory ) {
		var configCfcPath = arguments.directory & "/application/config/Config.cfc";
		var appCfcPath    = arguments.directory & "/Application.cfc";
		var config        = FileRead( configCfcPath );
		var appcfc        = FileRead( appCfcPath    );

		config = ReplaceNoCase( config, "${site_id}"   , arguments.siteId   , "all" );
		config = ReplaceNoCase( config, "${admin_path}", arguments.adminPath, "all" );
		appcfc = ReplaceNoCase( appcfc, "${site_id}"   , arguments.siteId   , "all" );

		FileWrite( configCfcPath, config );
		FileWrite( appCfcPath   , appcfc );
	}

	private void function _runPostInstallScripts( required string siteId, required string adminPath, required string directory ){
		var tmpDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/tmp";
		var currentDir = shell.pwd();
		var skeletonFile = currentDir & "/SkeletonInstall.cfc";

		if ( FileExists( skeletonFile ) ) {
			print.yellowLine( "");
			print.yellowLine( "Running post install scripts...");
			if ( DirectoryExists( tmpDir ) ) {
				DirectoryDelete( tmpDir, true );
			}
			DirectoryCreate( tmpDir );
			FileCopy( skeletonFile, tmpDir & "/SkeletonInstall.cfc" );

			var wireboxInstanceName = "command-" & CreateUUId();
			wirebox.registerNewInstance( name=wireboxInstanceName, instancePath="commandbox-home.commands.preside.new.tmp.SkeletonInstall" )
			       .setVirtualInheritance( "commandbox.system.BaseCommand" );

			var skeletonInstall = wireBox.getInstance( wireboxInstanceName );

			skeletonInstall.postInstall( directory=currentDir, siteId=arguments.siteId, adminPath=arguments.adminPath );
			DirectoryDelete( tmpDir, true );
			FileDelete( skeletonFile );

			print.yellowLine( "Done.");
			print.yellowLine( "");
		}
	}

	function skeletonComplete( ) {
		return variables._skeletonMap.keyArray();
	}
}