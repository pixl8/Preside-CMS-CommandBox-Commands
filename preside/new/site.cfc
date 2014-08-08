/**
 * Scaffold a new PresideCMS site, e.g. 
 * > preside new site "my-site"
 **/
component extends="commandbox.system.BaseCommand" excludeFromHelp=false {

	/**
	 * @siteid.hint    id of your site. Must contain alphanumerics, underscores and hyphens only
	 * @adminPath.hint path to the admin, defaults to {siteid}_admin
	 * @directory.hint directory in which to create the site (defaults to current directory)
	 **/
	function run(
		  required string  siteid
		,          string  adminPath = siteid & "_admin"
		,          boolean useGit
		,          string  directory = shell.pwd()
	) output=false {
		if ( !_validSlug( arguments.siteId    ) ) {
			return _printError( "Invalid site id. Site id must contain alphanumerics, underscores and hyphens only." );
		}
		if ( !_validSlug( arguments.adminPath ) ) {
			return _printError( "Invalid admin path. Admin path must contain alphanumerics, underscores and hyphens only." );
		}
		if ( !DirectoryExists( arguments.directory ) ) {
			return _printError( "Directory, [#arguments.directory#], does not exist" );
		}
		if ( !StructKeyExists( arguments, "useGit" ) ) {
			arguments.useGit = shell.ask( "Add git ignore files [y/N]? " ) == "y";
		}

		_unpackSkeleton( arguments.directory );
		_replacePlaceholdersWithArgs( argumentCollection=arguments );
		if ( arguments.useGit ) {
			_addGitIgnoreFile( arguments.directory );
		}

		print.line();
		print.greenLine( "*****************************************************************************************" );
		print.greenLine( "Your site has been successfully initialised. Type 'preside start' to start a server here." );
		print.greenLine( "*****************************************************************************************" );
		print.line();

		return;
	}

// PRIVATE HELPERS
	private boolean function _validSlug( required string slug ) output=false {
		return ReFindNoCase( "^[a-z0-9-_]+$", arguments.slug );
	}

	private void function _printError( errorMessage ) output=false {
		print.line();
		print.redLine( arguments.errorMessage );
		print.line();
	}

	private void function _unpackSkeleton( required string directory ) output=false {
		var resourceDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/../_resources";
		var zipFile     = resourceDir & "/preside-site-skeleton.zip";

		zip action="unzip" file="#zipFile#" destination=directory;
	}

	private void function _replacePlaceholdersWithArgs( required string siteId, required string adminPath, required string directory ) output=false {
		var configCfcPath = arguments.directory & "/application/config/Config.cfc";
		var config        = FileRead( configCfcPath );

		config = ReplaceNoCase( config, "${site_id}"   , arguments.siteId );
		config = ReplaceNoCase( config, "${admin_path}", arguments.adminPath );

		FileWrite( configCfcPath, config );
	}

	private void function _addGitIgnoreFile( required string directory ) output=false {
		var nl            = Chr(13) & Chr(10);

		FileWrite( directory & "/.gitignore", 
			"/WEB-INF" & nl &
			"/_assets" & nl &
			"/uploads" & nl &
			"/application/config/LocalConfig.cfc"
		);
	}
}