component {
	this.name = "presideExtensionCompiler";

	function onRequest() {
		try {
			var sourceDir = url.sourceDir ?: "";
			var targetDir = url.targetDir ?: sourceDir;

			_validateSourceAndTargetDirs( sourceDir, targetDir );
			_compile( sourceDir, targetDir );

			content reset=true type="text/plain";
			echo( "Compilation of source dir [#sourceDir#] has complete. Compiled files are to be found at target dir [#targetDir#]." );
		} catch( any e ) {
			content reset=true type="text/plain";
			header statuscode=500;
			echo( "There was an error compiling your extension. Message: [#e.message#]. Detail: [#e.detail#]" );

		}
	}

	function _validateSourceAndTargetDirs( sourceDir, targetDir ) {
		if ( !Len( Trim( sourceDir ) ) ) {
			throw( type="preside.compiler.bad.input", message="You must specify a valid sourceDir in the URL" );
		}
		if ( !Len( Trim( targetDir ) ) ) {
			throw( type="preside.compiler.bad.input", message="You must specify a valid targetDir in the URL (or pass nothing at all for the compiler to overwrite the source files)" );
		}
		if ( !DirectoryExists( sourceDir ) ) {
			throw( type="preside.compiler.bad.input", message="sourceDir not found, [#sourceDir#]" );
		}
	}

	function _compile( sourceDir, targetDir ) {
		var tmpdir = getTempDirectory() & "/" & CreateUUId();

		_copySrcToTmp( sourceDir, tmpDir );
		_createObjectPropFiles( tmpDir );
		_createViewParamFiles( tmpDir );
		_compileWithCfAdmin( tmpDir );
		_copyClassFilesOnTopOfSourceFiles( tmpdir );
		_moveFromTmpToTargetDir( tmpDir, targetDir );
	}

	function _copySrcToTmp( sourceDir, tmpDir ) {
		DirectoryCopy( sourceDir, tmpDir, true, "*", true );
	}

	function _compileWithCfAdmin( sourceDir ) {
		var tmpFile = getTempFile( getTempDirectory(), "compiled" ) & ".zip";

		admin action="updateMapping"
		      type="web"
		      password=""
		      virtual="/presideExtensionCompilerSource"
		      physical=sourceDir
		      archive=false
			  primary=false
			  inspect="never"
			  toplevel=false
			  remoteClients="";

		admin action="createArchive"
		      type="web"
		      password=""
		      file=tmpFile
		      virtual="/presideExtensionCompilerSource"
		      addCFMLFiles=true
		      addNonCFMLFiles=true;

		DirectoryDelete( sourceDir, true );

		zip action="unzip" file=tmpFile destination=sourceDir;
	}

	function _copyClassFilesOnTopOfSourceFiles( tmpdir ) {
		var classFiles = DirectoryList( tmpDir, true, "path", "*.class" )
		var cfFiles = DirectoryList( tmpDir, true, "path", "*.cfc" )

		cfFiles.append( DirectoryList( tmpDir, true, "path", "*.cfm" ), true )
		cfFiles.append( DirectoryList( tmpDir, true, "path", "*.cfml" ), true )

		for( var cfFile in cfFiles ) {
			var relativePath = Right( cffile, Len( cfFile ) - Len( tmpDir ) );
			var fileNameToMatch = LCase( relativePath ).replace( ".", "_", "all" ).replace( "-", "_", "all" ) & "$cf.class";
			var matchingClassFiles = classFiles.filter( function( classFile ) {
				var relativeClassFilePath = Right( classFile, Len( classFile ) - Len( tmpDir ) );
				var relativeClassFilePathNoGeneratedNumbers = relativeClassFilePath.reReplace( "[0-9]+/", "/", "all" );

				return relativeClassFilePath == filenameToMatch || relativeClassFilePathNoGeneratedNumbers == filenametoMatch;
			} );

			if ( matchingClassFiles.len() == 1 ) {
				FileMove( matchingClassFiles[ 1 ], cfFile );
				try {
					DirectoryDelete( getDirectoryFromPath( matchingClassFiles[ 1 ] ), false );
				} catch( any e ) {
					// won't delete if not empty, all good
				}
			} else if ( matchingClassFiles.len() > 1 ) {
				throw( type="presidecompiler.unexpected.compilation.error", "We found more than one class file as a possible match for the source file, [#cfFile#] and could not continue. Please contact the developer to help resolve. The matching class files were: #SerializeJson( matchingClassFiles )#" );
			}
		}

		try { FileDelete( tmpDir & "/META-INF/META-INF/MANIFEST.MF" ); } catch( any e ){}
		try { FileDelete( tmpDir & "/META-INF/MANIFEST.MF"          ); } catch( any e ){}
		try { FileDelete( tmpDir & "/META-INF/META-INF"             ); } catch( any e ){}
		try { FileDelete( tmpDir & "/META-INF"                      ); } catch( any e ){}
	}

	function _moveFromTmpToTargetDir( tmpdir, targetDir ) {
		if ( DirectoryExists( targetDir ) ) {
			DirectoryDelete( targetDir, true );
		}
		DirectoryCopy( tmpDir, targetDir, true, "*", true );
	}

	function _createObjectPropFiles( dir ) {
		var objectFiles = DirectoryList( dir & "/preside-objects", true, "path", "*.cfc" );
		for( var objFile in objectFiles ) {
			var props = _readPresideObjectProps( objFile );
			FileWrite( objFile.reReplace( "\.cfc$", "$props.json" ), SerializeJson( props ) );
		}
	}

	function _createViewParamFiles( dir ) {
		var viewFiles = DirectoryList( dir & "/views", true, "path", "*.cfm" );
		for( var viewFile in viewFiles ) {
			var viewParams = _readViewParams( viewFile );
			if ( viewParams.trim().len() ) {
				FileWrite( viewFile.reReplace( "\.cfm$", "$params.txt" ), viewParams );
			}
		}
	}

	function _readPresideObjectProps( filePath ) {
		var cfcContent      = FileRead( filePath );
		var propertyMatches = $reSearch( 'property\s+[^;/>]*name="([a-zA-Z_\$][a-zA-Z0-9_\$]*)"', cfcContent );

		if ( StructKeyExists( propertyMatches, "$1" ) ) {
			return propertyMatches.$1;
		}

		return [];
	}

	private string function _readViewParams( required string filePath ) {
		var fileContent     = FileExists( arguments.filePath ) ? FileRead( arguments.filePath ) : "";
		var regexes         = [ '<' & '(?:cfparam|cf_presideparam)\s[^>]*?name\s*=\s*"args\.(.*?)".*?>', '\bparam\s[^;]*?name\s*=\s*"args\.(.*?)"\s*;' ];
		var fieldRegex      = 'field\s*=\s*"(.*?)"';
		var rendererRegex   = 'renderer\s*=\s*"(.*?)"';
		var editableRegex   = 'editable\s*=\s*(true|"true")';
		var result          = "";
		var startPos        = 1;
		var match           = "";
		var alias           = "";
		var fieldName       = "";
		var selectDef       = "";
		var i               = 0;
		var idFieldIncluded = false;
		var params          = [];

		fileContent = _stripCfComments( fileContent );

		for( i=1; i lte regexes.len(); i++ ) {
			startPos = 1;
			while( startPos ){
				result = ReFindNoCase( regexes[i], fileContent, startPos, true );
				startPos = result.pos.len() eq 2 ? result.pos[2] : 0;
				if ( startPos ) {
					match = Mid( fileContent, result.pos[1], result.len[1] );
					alias = Mid( fileContent, result.pos[2], result.len[2] );
					result = ReFindNoCase( fieldRegex, match, 1, true );
					fieldName = result.pos.len() eq 2 and result.pos[2] ? Mid( match, result.pos[2], result.len[2] ) : alias;

					if ( fieldName != "false" ) {
						params.append( match );
					}

				}
			}
		}

		return params.toList( Chr( 10 ) & Chr( 13 ) );
	}

	private struct function $reSearch( required string regex, required string text ) {
		var final  = StructNew();
		var pos    = 1;
		var result = ReFindNoCase( arguments.regex, arguments.text, pos, true );
		var i      = 0;

		while( ArrayLen(result.pos) GT 1 ) {
			for(i=2; i LTE ArrayLen(result.pos); i++){
				if(not StructKeyExists(final, '$#i-1#')){
					final['$#i-1#'] = ArrayNew(1);
				}
				ArrayAppend(final['$#i-1#'], Mid(arguments.text, result.pos[i], result.len[i]));
			}
			pos = result.pos[2] + 1;
			result	= ReFindNoCase( arguments.regex, arguments.text, pos, true );
		} ;

		return final;
	}

	private string function _stripCfComments( content ) {
		return ReReplace( content, "<!---(.*?)--->", "\1", "all" );
	}
}

