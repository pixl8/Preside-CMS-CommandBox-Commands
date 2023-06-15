component {
	this.name = "EXTENSIONNAME Test Suite";

	this.mappings[ '/tests'   ] = ExpandPath( "/" );
	this.mappings[ '/testbox' ] = ExpandPath( "/testbox" );
	this.mappings[ '/EXTENSIONSLUG'  ] = ExpandPath( "../" );

	setting requesttimeout=60000;
}
