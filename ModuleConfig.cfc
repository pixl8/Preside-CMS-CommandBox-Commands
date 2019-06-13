component {
	public any function configure() {
		interceptors = [
			{ class="#moduleMapping#.interceptors.PresideCommandsPostInstallInterceptor" }
		];

		return;
	}


}
