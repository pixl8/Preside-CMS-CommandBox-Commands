component {
	public any function configure() {
		return;
	}

	public void function onInstall( interceptData ) {
		if ( IsEmpty( interceptData.installDirectory ?: "" ) && _isPresideApp( interceptData.packagePathRequestingInstallation ?: "" ) ) {
			switch( interceptData.artifactDescriptor.type ?: "" ) {
				case "modules":
					interceptData.installDirectory = interceptData.packagePathRequestingInstallation.listAppend( "application/modules", "/" );
				break;
			}
		}
	}

	private boolean function _isPresideApp( required string path ) {
		var rootAppCfc = arguments.path.listAppend( "Application.cfc", "/" );

		if ( FileExists( rootAppCfc ) ) {
			return FileRead( rootAppCfc ).findNoCase( "extends=""preside.system" );
		}

		return false;
	}
}
