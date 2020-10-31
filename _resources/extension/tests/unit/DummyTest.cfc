component extends="testbox.system.BaseSpec" {
	function run() {
		describe( "tests()", function() {
			it( "should all pass", function() {
				expect( true ).toBe( true );
			} );
		} );
	}
}