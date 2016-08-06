/**
 * Scaffold a new PresideCMS site, e.g.
 * > preside new site "my-site"
 **/
component extends="commandbox.system.BaseCommand" excludeFromHelp=false {

	property name="packageService" inject="PackageService";
	property name="wirebox"        inject="wirebox";

	variables._skeletonMap = {
		  "basic" = { package="preside-skeleton-basic" , description="A basic website application with CMS features enabled using vanilla bootstrap css and js for the 'theme'" }
		, "nocms" = { package="preside-skeleton-webapp", description="A stripped down skeleton *admin application*. Has all CMS features disabled." }
	};

	/**
	 * @skeleton.hint       The name of the app skeleton to use. Options: basic, nocms
	 * @skeleton.optionsUDF skeletonComplete
	 **/
	function run( string skeleton = "" ) {
		var directory = shell.pwd();

		while( arguments.skeleton == "" ) {
			print.line( "" );
			print.line( "Available skeleton templates from which to build your new site/application:" );
			print.line( "" );
			for( var skeletonId in variables._skeletonMap ) {
				print.line( "   #skeletonId#: #variables._skeletonMap[ skeletonId ].description#" )
			}
			print.line( "" );

			arguments.skeleton = ask( "Enter the skeleton template to use: " );
			if ( !variables._skeletonMap.keyExists( arguments.skeleton ) ) {
				arguments.skeleton = "";
			}
		}

		if( variables._skeletonMap.keyExists( arguments.skeleton ) ) {
			arguments.skeleton = variables._skeletonMap[ arguments.skeleton ].package;
		}

		packageService.installPackage(
			  id                      = arguments.skeleton
			, directory               = directory
			, save                    = false
			, saveDev                 = false
			, production              = true
			, currentWorkingDirectory = directory
		);

		_runPostInstallScripts( directory=directory );

		print.line();
		print.greenLine( "*****************************************************************************************" );
		print.greenLine( "Your site has been successfully initialised. Type 'preside start' to start a server here." );
		print.greenLine( "*****************************************************************************************" );
		print.line();

		return;
	}

// PRIVATE HELPERS
	private void function _printError( errorMessage ) {
		print.line();
		print.redLine( arguments.errorMessage );
		print.line();
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