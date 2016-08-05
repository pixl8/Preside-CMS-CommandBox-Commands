/**
 * Scaffold a new PresideCMS site, e.g.
 * > preside new site "my-site"
 **/
component extends="commandbox.system.BaseCommand" excludeFromHelp=false {

	property name="packageService" inject="PackageService";

	variables._skeletonMap = {
		"basic" = "preside-skeleton-basic"
	};

	/**
	 * @siteid.hint         id of your site. Must contain alphanumerics, underscores and hyphens only
	 * @skeleton.hint       The name of the app skeleton to use. Options: basic
	 * @skeleton.optionsUDF skeletonComplete
	 **/
	function run(
		  required string siteid
		,          string skeleton = "basic"
		// , required string skeleton (when we have more than one skeleton, use this line + update docs for argument, above)
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

	function skeletonComplete( ) {
		return variables._skeletonMap.keyArray();
	}
}