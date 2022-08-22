/**
 * Scaffold a new PresideCMS site, e.g.
 * > preside new site "my-site"
 **/
component {

	property name="packageService" inject="PackageService";
	property name="wirebox"        inject="wirebox";
	property name="forgeBox"       inject="ForgeBox";

	/**
	 * @skeleton.hint The name of the app skeleton to use. Options: basic, nocms
	 **/
	function run( string skeleton = "" ) {
		var directory = shell.pwd();
		var templates = _getSkeletonTemplates();

		while( arguments.skeleton == "" ) {
			print.yellowLine( "Looking up available skeletons from forgebox.io... (hint: register a template by adding a forgebox package matching the pattern, 'preside-skeleton-*')" );
			print.line();
			
			if ( templates.isEmpty() ) {
				print.line( "" );
				print.redLine( "No preside skeleton templates could be found! Ensure you are online and that https://www.forgebox.io is up and running." );
				print.line( "" );
			}

			print.line( "" );
			print.line( "Available skeleton templates from which to build your new site/application:" );
			print.line( "" );
			for( var templateId in templates ) {
				print.text( " * " );
				print.yellowText( "#templateId#" );
				print.line( ": #templates[ templateId ].description#" );
			}
			print.line( "" );

			arguments.skeleton = ask( "Enter the skeleton template to use: " );
			if ( !templates.keyExists( arguments.skeleton ) ) {
				arguments.skeleton = "";
			}
		}

		if( templates.keyExists( arguments.skeleton ) ) {
			arguments.skeleton = templates[ arguments.skeleton ].package;
		}

		packageService.installPackage(
			  id                      = arguments.skeleton
			, save                    = false
			, saveDev                 = false
			, production              = true
		);

		_runPostInstallScripts();

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

	private void function _runPostInstallScripts(){
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
			wirebox.registerNewInstance( name=wireboxInstanceName, instancePath="commandbox-home.cfml.modules.preside-commands.commands.preside.new.tmp.SkeletonInstall" )
			       .setVirtualInheritance( "commandbox.system.BaseCommand" );

			var skeletonInstall = wireBox.getInstance( wireboxInstanceName );

			skeletonInstall.postInstall( directory=currentDir );
			DirectoryDelete( tmpDir, true );
			FileDelete( skeletonFile );

			print.yellowLine( "Done.");
			print.yellowLine( "");
		}
	}

	private struct function _getSkeletonTemplates() {
		var templates       = {};
		var forgeboxEntries = forgebox.getEntries( typeSlug = "preside-skeletons" );

		for( var entry in forgeboxEntries.results ) {
			templates[ entry.slug.replace( "preside-skeleton-", "" ) ] = {
				  name        = entry.title
				, description = entry.summary
				, package     = entry.slug
			};
		}

		return templates;
	}
}
