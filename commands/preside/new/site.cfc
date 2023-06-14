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

		if ( !Len( arguments.skeleton ) ) {
			print.yellowLine( "Looking up available skeletons from forgebox.io... (hint: register a template by adding a forgebox package matching the pattern, 'preside-skeleton-*')" );
			print.line().toConsole();

			if ( templates.isEmpty() ) {
				print.line( "" );
				print.redLine( "No preside skeleton templates could be found! Ensure you are online and that https://www.forgebox.io is up and running." );
				print.line( "" );
			} else {
				var options = [];
				var i=0;
				for( var templateId in templates ) {
					var template = templates[ templateId ];

					ArrayAppend( options, {
						  value = templateId
						, display = template.name & ( template.official ? " (OFFICIAL)" : " (by #template.author#)" ) & ": " & template.description
						, accessKey = ++i
					} );
				}

				arguments.skeleton = multiselect( "Choose a skeleton template to use: " ).options( options ).required().ask();

				print.line( "" );

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
		var official        = [ "preside-skeleton-basic", "preside-skeleton-webapp" ];
		var ordered         = StructNew( "linked" );

		for( var entry in forgeboxEntries.results ) {
			templates[ entry.slug.replace( "preside-skeleton-", "" ) ] = {
				  name        = entry.title
				, description = entry.summary
				, package     = entry.slug
				, author      = entry.user.fullName ?: "unknown"
				, official    = ArrayFindNoCase( official, entry.slug )
			};
		}

		if ( StructKeyExists( templates, "basic" ) ) {
			ordered[ "basic" ] = templates.basic;
		}
		if ( StructKeyExists( templates, "basic" ) ) {
			ordered[ "webapp" ] = templates.webapp;
		}
		for( var key in templates ) {
			if ( !ArrayFind( [ "basic", "webapp" ], key ) ) {
				ordered[ key ] = templates[ key ];
			}
		}

		return ordered;
	}
}
