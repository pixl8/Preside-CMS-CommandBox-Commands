<?xml version="1.0" encoding="UTF-8"?>
<railo-configuration version="4.2">
	<setting/>

	<data-sources>
	</data-sources>
	
	<resources>
		<resource-provider arguments="case-sensitive:true;lock-timeout:1000;" class="railo.commons.io.res.type.ram.RamResourceProvider" scheme="ram"/>
		<resource-provider arguments="lock-timeout:10000;" class="railo.commons.io.res.type.s3.S3ResourceProvider" scheme="s3"/>
	</resources>
	
	<remote-clients directory="{railo-web}remote-client/"/>
	
	
	<file-system deploy-directory="{railo-web}/cfclasses/" fld-directory="{railo-web}/library/fld/" temp-directory="{railo-web}/temp/" tld-directory="{railo-web}/library/tld/">
	</file-system>

	<scope client-directory="{railo-web}/client-scope/" client-directory-max-size="100mb"/>
		
	<mail>
	</mail>
	
	<search directory="{railo-web}/search/" engine-class="railo.runtime.search.lucene.LuceneSearchEngine"/>
	

	<scheduler directory="{railo-web}/scheduler/"/>
	
	<mappings>
		<mapping archive="{railo-web}/context/railo-context.ra" physical="{railo-web}/context/" primary="physical" readonly="yes" toplevel="yes" trusted="true" virtual="/railo-context/"/>
		<mapping archive="" physical="{railo-web}/preside" primary="physical" readonly="yes" toplevel="yes" trusted="true" virtual="/preside" />
	</mappings>	
	
	<custom-tag>
		<mapping physical="{railo-web}/customtags/" trusted="yes"/>
	</custom-tag>
	
	<ext-tags>
		<ext-tag class="railo.cfx.example.HelloWorld" name="HelloWorld" type="java"/>
	</ext-tags>
	
	
	<component base="/railo-context/Component.cfc" data-member-default-access="public" use-shadow="yes"> 
	</component>
	
	<regional/>

	<debugging template="/railo-context/templates/debugging/debugging.cfm"/>
		
	<application cache-directory="{railo-web}/cache/" cache-directory-max-size="100mb"/>
		
	<logging>
		<logger appender="resource" appender-arguments="path:{railo-config}/logs/remoteclient.log" layout="classic" level="info" name="remoteclient"/>
		<logger appender="resource" appender-arguments="path:{railo-config}/logs/requesttimeout.log" layout="classic" name="requesttimeout"/>
		<logger appender="resource" appender-arguments="path:{railo-config}/logs/mail.log" layout="classic" name="mail"/>
		<logger appender="resource" appender-arguments="path:{railo-config}/logs/scheduler.log" layout="classic" name="scheduler"/>
		<logger appender="resource" appender-arguments="path:{railo-config}/logs/trace.log" layout="classic" name="trace"/>
		<logger appender="resource" appender-arguments="path:{railo-config}/logs/application.log" layout="classic" level="info" name="application"/>
		<logger appender="resource" appender-arguments="path:{railo-config}/logs/exception.log" layout="classic" level="info" name="exception"/>	
	</logging>		

	<rest/>

	<gateways/>

	<orm/>

</railo-configuration>