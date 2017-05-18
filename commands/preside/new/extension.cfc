/**
 * Scaffold a new PresideCMS extension, e.g.
 * > preside new extension "my-extension"
 **/
component {

	/**
	 * @extensionid.hint ID of your your extension. Must contain alphanumerics, underscores and hyphens only
	 * @title.hint       Human readable title of the extension
	 * @author.hint      Author of the extension (you)
	 * @version.hint     Initial version of the extension, e.g. 1.0.0
	 * @directory.hint   Directory in which to create the site (defaults to current directory)
	 **/
	function run(
		  required string  extensionid
		, required string  title
		, required string  author
		, required string  version
		,          string  directory = shell.pwd()
	) {
		if ( !_validSlug( arguments.extensionid ) ) {
			return _printError( "Invalid extension id. Extension id must contain alphanumerics, underscores and hyphens only." );
		}
		if ( !DirectoryExists( arguments.directory ) ) {
			return _printError( "Directory, [#arguments.directory#], does not exist" );
		}

		_unpackSkeleton( arguments.directory );
		_replacePlaceholdersWithArgs( argumentCollection=arguments );

		print.line();
		print.greenLine( "*****************************************************************************************" );
		print.greenLine( "Your extension has been successfully scaffolded. You can enable it in your application by" );
		print.greenLine( "entering the following code in the PresideCMS devoper console:" );
		print.greenLine( "" );
		print.greenLine( "extension enable " & arguments.extensionId );
		print.greenLine( "" );
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

	private void function _unpackSkeleton( required string directory ) {
		var resourceDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/../../../_resources";
		var zipFile     = resourceDir & "/preside-extension-skeleton.zip";

		zip action="unzip" file="#zipFile#" destination=directory;
	}

	private void function _replacePlaceholdersWithArgs(
		  required string  extensionid
		, required string  title
		, required string  author
		, required string  version
		, required string  directory
	) {
		var manifestPath = arguments.directory & "/manifest.json";
		var manifest     = FileRead( manifestPath );

		manifest = ReplaceNoCase( manifest, "${extensionid}", arguments.extensionid, "all" );
		manifest = ReplaceNoCase( manifest, "${title}"      , arguments.title      , "all" );
		manifest = ReplaceNoCase( manifest, "${author}"     , arguments.author     , "all" );
		manifest = ReplaceNoCase( manifest, "${version}"    , arguments.version    , "all" );

		FileWrite( manifestPath, manifest );
	}
}