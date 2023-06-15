/**
 * Scaffolds a Preside Extension
 *
 **/
component {


	/**
	 * @name.hint      Extension name, e.g. My cool extension
	 * @slug.hint      Extension slug, without preside-ext-
	 * @author.hint    Author, e.g. you!
	 * @repoUrl.hint   Home URL, e.g. github repo
	 * @directory.hint Directory in which extension will be scaffolded
	 *
	 **/
	function run(
		  required string name
		, required string slug
		, required string author
		, required string repoUrl
		,          string directory = shell.pwd()
	) {
		var args = StructCopy( arguments );

		if ( !_validSlug( arguments.slug ) ) {
			return _printError( "Invalid slug. Extension slug must contain alphanumerics, underscores and hyphens only." );
		}
		if ( !DirectoryExists( arguments.directory ) ) {
			return _printError( "Directory, [#arguments.directory#], does not exist" );
		}

		args.isOpenSource = "";
		do {
			args.isOpenSource = shell.ask( "Is this a public (open source) extension? (Y/N): " );
		} while( args.isOpenSource != "Y" && args.isOpenSource != "N" );

		args.requireStatic = "";
		do {
			args.requireStatic = shell.ask( "Will your extension require CSS/JS? (Y/N): " );
		} while( args.requireStatic != "Y" && args.requireStatic != "N" );

		args.requireTests = "";
		do {
			args.requireTests = shell.ask( "Will you be writing tests?! (Y/N): " );
		} while( args.requireTests != "Y" && args.requireTests != "N" );

		args.gitIgnoreRules = "";
		do {
			args.gitIgnoreRules = shell.ask( "Install git ignore rules (Y/N): " );
		} while( args.gitIgnoreRules != "Y" && args.gitIgnoreRules != "N" );

		if ( args.isOpenSource == "Y" ) {
			args.githubActions = "";
			do {
				args.githubActions = shell.ask( "Install GitHub actions to run tests, build and publish to Forgebox? (Y/N): " );
			} while( args.githubActions != "Y" && args.githubActions != "N" );
		} else {
			args.githubActions = "N";
		}

		arguments.slug = arguments.slug.reReplace( "^preside\-ext\-", "" );

		_unpackSkeleton( arguments.directory );

		if ( !args.requireStatic == "Y" ) {
			DirectoryDelete( arguments.directory & "/assets", true );
		}
		if ( !args.requireTests == "Y" ) {
			DirectoryDelete( arguments.directory & "/tests", true );
			FileDelete( arguments.directory & "/server-tests.json" );
			FileDelete( arguments.directory & "/box.json" );
			FileDelete( arguments.directory & "/test.sh" );
			FileMove( arguments.directory & "/box.json.no.tests", arguments.directory & "/box.json" );
		} else {
			FileDelete( arguments.directory & "/box.json.no.tests" );
		}

		if ( !args.githubActions == "Y" ) {
			DirectoryDelete( arguments.directory & "/.github", true );
		}

		if ( !args.gitIgnoreRules == "Y" ) {
			if ( args.requireStatic == "Y" ) {
				FileDelete( arguments.directory & "/assets/.gitignore" );
			}
			if ( args.requireTests == "Y" ) {
				FileDelete( arguments.directory & "/tests/.gitignore" );
			}
		}

		_replacePlaceholdersWithArgs( argumentCollection=args );

		print.line();
		print.greenLine( "************************************************" );
		print.greenLine( "Your extension has been successfully scaffolded!" );
		print.greenLine( "************************************************" );
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

	private void function _unpackSkeleton( required string directory ) {
		var source = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/../../../_resources/extension";

		DirectoryCopy( source, arguments.directory, true );

		FileSetAccessMode( arguments.directory & "/test.sh", "755" );
	}

	private void function _replacePlaceholdersWithArgs(
		  required string name
		, required string slug
		, required string repoUrl
		, required string directory
		, required string author
		, required string isOpenSource
	) {
		var filePaths = [
			  arguments.directory & "/manifest.json"
			, arguments.directory & "/box.json"
			, arguments.directory & "/README.md"
			, arguments.directory & "/assets/package.json"
			, arguments.directory & "/tests/Application.cfc"
			, arguments.directory & "/test.sh"
			, arguments.directory & "/server-tests.json"
			, arguments.directory & "/.github/workflows/ci.yml"
		];

		for( var filePath in filePaths ) {
			if ( FileExists( filePath ) ) {
				var fileContent = FileRead( filePath );
				var private = arguments.isOpenSource == "Y" ? "false" : "true";

				fileContent = Replace( fileContent, "EXTENSIONSLUG", arguments.slug   , "all" );
				fileContent = Replace( fileContent, "EXTENSIONNAME", arguments.name   , "all" );
				fileContent = Replace( fileContent, "EXTENSIONURL" , arguments.repoUrl, "all" );
				fileContent = Replace( fileContent, "AUTHOR"       , arguments.author , "all" );
				fileContent = Replace( fileContent, "PRIVATE"      , private          , "all" );

				FileWrite( filePath, fileContent );
			}

		}
	}

}