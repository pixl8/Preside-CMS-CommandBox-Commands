component {

	property name="packageService"  inject="provider:packageService";
	property name="semanticVersion" inject="provider:semanticVersion@semver";

// INTERCEPTION LISTENERS
	public void function onInstall( interceptData ) {
		if ( _isPresideApp( interceptData.packagePathRequestingInstallation ?: "" ) ) {
			if ( IsEmpty( interceptData.installDirectory ?: "" ) ) {
				switch( interceptData.artifactDescriptor.type ?: "" ) {
					case "modules":
						interceptData.installDirectory = interceptData.packagePathRequestingInstallation.listAppend( "application/modules", "/" );
					break;
				}
			}
			var skipPackageChecks = IsBoolean( interceptData.installArgs.skipPresidePackageChecking ?: "" ) && interceptData.installArgs.skipPresidePackageChecking;
			if ( !skipPackageChecks ) {
				var artifactBoxJson = interceptData.artifactDescriptor;
				if ( _isExtension( artifactBoxJson ) ) {
					_compatibilityChecks( artifactBoxJson, interceptData.containerBoxJson ?: {} );
					_ensureDependenciesInstalled( artifactBoxJson, interceptData.installDirectory ?: "", interceptData.containerBoxJson ?: {} );
				}
			}
		}
	}

// PRIVATE HELPERS
	private boolean function _isPresideApp( required string path ) {
		var rootAppCfc = arguments.path.listAppend( "Application.cfc", "/" );

		if ( FileExists( rootAppCfc ) ) {
			return FileRead( rootAppCfc ).findNoCase( "extends=""preside.system" );
		}

		return false;
	}

	private boolean function _isExtension( required struct artifactDescriptor ) {
		var artifactType = artifactDescriptor.type ?: "";
		var artifactDir = artifactDescriptor.directory ?: "";

		return artifactType == "preside-extensions" || artifactDir == "application/extensions";
	}

	private void function _compatibilityChecks(
		  required struct artifactDescriptor
		, required struct containerBoxJson
	) {
		var compatibility = artifactDescriptor.preside.compatibility ?: {};
		var packageSlug   = artifactDescriptor.slug ?: "no-slug";

		for( var compatSlug in compatibility ) {
			var compat = compatibility[ compatSlug ];
			var compatible = !IsBoolean( compat.compatible ?: "" ) || compat.compatible;
			var minVersion = compat.minVersion ?: "";
			var maxVersion = compat.maxVersion ?: "";
			var targetPackage = containerBoxJson.dependencies[ compatSlug ] ?: "";

			if ( StructKeyExists( containerBoxJson.dependencies, compatSlug ) ) {
				if ( !compatible ) {
					throw(
						  type    = "preside.extension.dependency.compatibility.issue"
						, message = compat.message ?: "The extension [#packageSlug#] has a compatibility issue with the [#compatSlug#] package. To install [#packageSlug#], first uninstall [#compatSlug#]."
					);
				}

				var targetVersion = _getPackageVersion( containerBoxJson.dependencies[ compatSlug ] );
				if ( Len( minVersion ) && semanticVersion.compare( targetVersion, minVersion ) == -1 ) {
					throw(
						  type    = "preside.extension.dependency.compatibility.issue"
						, message = compat.message ?: "The extension [#packageSlug#] requires that the [#compatSlug#] package be at least version: [#minVersion#]. To install [#packageSlug#], first ensure that [#compatSlug#] is upgraded to at least [#minVersion#]."
					);
				}
				if ( Len( maxVersion ) && semanticVersion.compare( targetVersion, maxVersion ) == 1 ) {
					throw(
						  type    = "preside.extension.dependency.compatibility.issue"
						, message = compat.message ?: "The extension [#packageSlug#] requires that the [#compatSlug#] package be at or below version: [#minVersion#]. To install [#packageSlug#], first ensure that [#compatSlug#] is downgraded to version [#minVersion#] or before."
					);
				}
			}
		}
	}

	private void function _ensureDependenciesInstalled( required struct artifactDescriptor, required string installDirectory, required struct containerBoxJson ) {
		var dependencies = artifactDescriptor.preside.dependencies ?: {};
		var packageSlug = artifactDescriptor.slug ?: "no-slug";

		_checkPresideMinMaxVersion(
			  minVersion       = artifactDescriptor.preside.minVersion ?: ""
			, maxVersion       = artifactDescriptor.preside.maxVersion ?: ""
			, containerBoxJson = containerBoxJson
			, packageSlug      = packageSlug
		);

		for( var dependencySlug in dependencies ) {
			var dependency = dependencies[ dependencySlug ]
			if ( !_dependencyAlreadyInstalled( dependencySlug, dependency, containerBoxJson, packageSlug, arguments.installDirectory ) ) {
				var installVersion = dependency.installVersion ?: dependencySlug;
				if ( !installVersion contains dependencySlug && !installVersion contains "@" ) {
					installVersion = dependencySlug & "@" & installVersion;
				}
				packageService.installPackage( id=installVersion, save=true );
			}
		}
	}

	private boolean function _dependencyAlreadyInstalled( required string dependencySlug, required struct dependencyInfo, required struct containerBoxJson, required string packageSlug, required string installDirectory ) {
		var hasMinVer          = Len( Trim( dependencyInfo.minVersion ?: "" ) );
		var hasMaxVer          = Len( Trim( dependencyInfo.maxVersion ?: "" ) );
		var versionInstalled   = "";
		var depBoxJsonLocation = arguments.installDirectory & "/#dependencySlug#/box.json";

		if ( StructKeyExists( containerBoxJson.dependencies, dependencySlug ) ) {
			versionInstalled = containerBoxJson.dependencies[ dependencySlug ];
		} else if ( FileExists( depBoxJsonLocation ) ) {
			try {
				var depboxjson = DeserializeJson( FileRead( depBoxJsonLocation ) );
			} catch( any e ) {

				return false;
			}

			versionInstalled = depboxjson.version ?: "";
		}

		if ( Len( Trim( versionInstalled ) ) ) {
			if ( hasMinVer || hasMaxVer ) {
				if ( ListLen( versionInstalled, "##@" ) == 2 ) {
					versionInstalled = ListRest( versionInstalled, "##@" );
				}
				if ( ListLen( versionInstalled, "-" ) > 1 ) {
					versionInstalled = ListFirst( versionInstalled, "-" );
				}

				if ( hasMinVer && semanticVersion.compare( dependencyInfo.minVersion, versionInstalled ) == 1 ) {
					throw( type="preside.extension.dependency.version.mismatch", message="The already installed dependency [#dependencySlug#] of package [#packageSlug#] does not meet the minimum version requirement of [#dependencyInfo.minVersion#]. Please upgrade your [#dependencySlug#] extension to continue." );
				}

				if ( hasMaxVer && semanticVersion.compare( versionInstalled, dependencyInfo.maxVersion ) == 1 ) {
					throw( type="preside.extension.dependency.version.mismatch", message="The already installed dependency [#dependencySlug#] of package [#packageSlug#] exceeds the maximum version requirement of [#dependencyInfo.maxVersion#]. You will need to manually resolve this situation by either downgrading [#dependencySlug#], installing a later version of [#packageSlug#], or getting the package maintainers of [#packageSlug#] to update the package to be compatible with later versions of [#dependencySlug#]." );
				}
			}

			return true;
		}

		return false;
	}

	private void function _checkPresideMinMaxVersion(
		  required string minVersion
		, required string maxVersion
		, required struct containerBoxJson
		, required string packageSlug
	) {
		if ( Len( Trim( arguments.minVersion ) ) || Len( Trim( arguments.maxVersion ) ) ) {
			var installedPresideVersion = ListFirst( arguments.containerBoxJson.dependencies.presidecms ?: ( arguments.containerBoxJson.dependencies[ "preside-be" ] ?: "" ), "-" );

			if ( Len( Trim( installedPresideVersion ) ) && !ListFindNoCase( "be,stable", installedPresideVersion ) ) {
				if ( Len( Trim( arguments.minVersion ) ) && semanticVersion.compare( arguments.minVersion, installedPresideVersion ) == 1 ) {
					throw( type="preside.extension.dependency.version.mismatch", message="The Preside extension, [#packageSlug#], requires a minimum Preside version of [#arguments.minVersion#]. However, you currently have [#installedPresideVersion#], which does not meet the minimum requirement." );
				}

				if ( Len( Trim( arguments.maxVersion ) ) && semanticVersion.compare( arguments.maxVersion, installedPresideVersion ) == -1 ) {
					throw( type="preside.extension.dependency.version.mismatch", message="The Preside extension, [#packageSlug#], requires a maximum Preside version of [#arguments.maxVersion#]. However, you currently have [#installedPresideVersion#], which exceeds the maximum requirement." );
				}
			}
		}
	}

	private string function _getPackageVersion( packageId ) {
		if ( ReFindNoCase( "^s3://", packageId ) ) {
			return ReReplace( ListLast( packageId, "/" ), "\.zip$", "" );
		}

		return ListRest( packageId, "@##" )
	}
}