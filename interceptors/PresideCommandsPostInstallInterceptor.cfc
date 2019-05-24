component {

	property name="packageService" inject="packageService";

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

			var artifactBoxJson = interceptData.artifactDescriptor;
			if ( _isExtension( artifactBoxJson ) ) {
				_ensureDependenciesInstalled( artifactBoxJson, interceptData.installDirectory ?: "", interceptData.containerBoxJson ?: {} );
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

	private void function _ensureDependenciesInstalled( required struct artifactDescriptor, required string installDirectory, required struct containerBoxJson ) {
		var dependencies = _getExtensionDependencies( argumentCollection=arguments )

		for( var dependency in dependencies ) {
			if ( !_dependencyAlreadyInstalled( dependency, containerBoxJson ) ) {
				packageService.installPackage( id=dependency, save=true );
			}
		}
	}

	private array function _getExtensionDependencies( required struct artifactDescriptor, required string installDirectory ) {
		var manifestPath = arguments.installDirectory & "/#( artifactDescriptor.slug ?: "" )#/manifest.json";

		try {
			var manifest = DeserializeJson( FileRead( manifestPath ) );
			var autoInstall = manifest.autoInstall ?: [];

			return IsArray( autoInstall ) ? autoInstall : [ autoInstall ];
		} catch( any e ) {}

		return [];
	}

	private boolean function _dependencyAlreadyInstalled( required string dependency, required struct containerBoxJson ) {
		if ( StructKeyExists( containerBoxJson.dependencies, ListFirst( dependency, "@")  ) ) {
			return true;
		}

		var dependencyWithoutVersion = ListFirst( dependency, "##@" );

		for( var installedDepSlug in containerBoxJson.dependencies ) {
			var installedDep = ListFirst( containerBoxJson.dependencies[ installedDepSlug ], "##@" );

			if ( installedDep == dependencyWithoutVersion ) {
				return true;
			}
		}

		return false;
	}
}