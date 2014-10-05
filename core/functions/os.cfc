<cfcomponent>
<cfoutput>

<!--- application.zcore.functions.zSetPageHelpId("1.1"); --->
<cffunction name="zSetPageHelpId" access="public" localmode="modern" roles="member">
	<cfargument name="helpId" type="string" required="yes" hint="This is the numeric id for the help page resource.">
	<cfscript>
	if(not structkeyexists(request.zos, 'zPageHelpIdSet')){
		request.zos.zPageHelpIdSet=true;

		manualCom=createobject("component", "zcorerootmapping.mvc.z.admin.controller.manual");
		manualCom.init();
		cs=manualCom.getDocLink(arguments.helpid);
		if(cs.success){
			application.zcore.skin.addDeferredScript('zPageHelpId="'&jsStringFormat(cs.link)&'";');
		}
	}
	</cfscript>
</cffunction>

<cffunction name="getSystemIpStruct" localmode="modern" returntype="struct" access="public">

	<cfscript>
	d=application.zcore.functions.zSecureCommand("getSystemIpList", 10);
	
	arrD=listtoarray(d, chr(10));
	arrIp=arraynew(1);
	firstIp=false;
	defaultIpSet=false;
	defaultIp="";
	for(i=1;i LTE arraylen(arrD);i++){
		arrD[i]=trim(arrD[i]);
		if((arrD[i] CONTAINS "eth0:" or arrD[i] CONTAINS "p4p1:") and defaultIpSet EQ false){
			firstIp=true;
		}
		if(left(arrD[i], 4) EQ "inet"){
			arrS=listtoarray(arrD[i], " ",false);
			arrS2=listtoarray(arrS[2], "/", false);
			arrayappend(arrIp, arrS2[1]);
			if(firstIp){
				defaultIp=arrS2[1];
				firstIp=false;
				defaultIpSet=true;
			}
		}
	} 
	if(not defaultIpSet){
		defaultIp=arrIp[1];	
	}
	return {
		defaultIp: defaultIp,
		arrIp=arrIp
	};
	</cfscript>
</cffunction>

 <!--- application.zcore.functions.zSecureCommand(command, timeoutInSeconds); --->
<cffunction name="zSecureCommand" localmode="modern" access="public" returntype="string">
	<cfargument name="command" type="string" required="yes">
	<cfargument name="timeoutInSeconds" type="numeric" required="yes">
	<cfscript>
	secureHashDate=hash(randrange(10000000, 90000000))&"-"&dateformat(now(),"yyyymmdd")&"-"&timeformat(now(),"HHmmss");
	startPath=request.zos.installPath&"execute/start/"&secureHashDate&".txt";
	completePath=request.zos.installPath&"execute/complete/"&secureHashDate&".txt";
	application.zcore.functions.zwritefile(startPath, arguments.command);
	
	startTime=gettickcount();
	arguments.timeoutInSeconds*=1000;
	while(true){
		sleep(100);
		if(fileexists(completePath)){
			contents=application.zcore.functions.zreadfile(completePath);
			application.zcore.functions.zdeletefile(completePath);
			return contents;
		}else if(gettickcount()-startTime GTE arguments.timeoutInSeconds){
			application.zcore.functions.zdeletefile(startPath);
			application.zcore.functions.zdeletefile(completePath);
			throw("Timeout occurred while running zSecureCommand: #listGetAt(arguments.command, 1, chr(9))#.  The temporary files were automatically deleted. You may need to verify the PHP cron job is working correctly if this command continues to fail.");
		}
	}
	</cfscript>
</cffunction>

<cffunction name="getSiteDBObjects" localmode="modern" access="public">
	<cfargument name="globalStruct" type="struct" required="yes">
	<cfscript>
	ts={};
	c=application.zcore.db.getConfig();
	c.cacheDisabled=false;
	c.queryLogFunction=application.zcore.functions.zLogQuery;
	ts.cacheDisabledDB=duplicate(application.zcore.componentObjectCache.db);
	ts.cacheDisabledDB.init(c);
	
	c=application.zcore.db.getConfig();
	c.datasource=arguments.globalStruct.datasource;
	c.verifyQueriesEnabled=false;
	c.cacheDisabled=false;
	c.queryLogFunction=application.zcore.functions.zLogQuery;
	ts.cacheDisabledNoVerifyDB=duplicate(application.zcore.componentObjectCache.db);
	ts.cacheDisabledNoVerifyDB.init(c);
	
	c=application.zcore.db.getConfig();
	c.datasource=arguments.globalStruct.datasource;
	c.verifyQueriesEnabled=false;
	c.queryLogFunction=application.zcore.functions.zLogQuery;
	ts.cacheEnabledNoVerifyDB=duplicate(application.zcore.componentObjectCache.db);
	ts.cacheEnabledNoVerifyDB.init(c);
	
	c=application.zcore.db.getConfig();
	c.datasource=arguments.globalStruct.datasource;
	c.queryLogFunction=application.zcore.functions.zLogQuery;
	ts.cacheEnabledDB=duplicate(application.zcore.componentObjectCache.db);
	ts.cacheEnabledDB.init(c);
	return ts;
	</cfscript>
</cffunction>

<cffunction name="zReturnJson" localmode="modern" access="public" output="yes">
	<cfargument name="data" type="any" required="yes">
	<cfscript>
	writeoutput(serializeJson(arguments.data));
	header name="x_ajax_id" value="#application.zcore.functions.zso(form, 'x_ajax_id')#";
	application.zcore.functions.zabort();
	</cfscript>
</cffunction>

<cffunction name="zGenerateNginxMap" localmode="modern" access="public" output="no">
	<cfscript>
	var db=request.zos.queryObject;
	db.sql="select site_domain, site_short_domain, site_domainaliases, site_ssl_manager_domain from #db.table("site", request.zos.zcoreDatasource)# 
	where site_active=#db.param(1)# and 
	site_deleted = #db.param(0)# and 
	site_id <> #db.param(-1)# 
	GROUP BY site_short_domain 
	ORDER BY site_domain ";
	var qSite=db.execute("qSite");
	var arrTemp=[];
	for(var row in qSite){
		var arrTemp2=listToArray(row.site_domainaliases,",");
		var primaryPath=replace(application.zcore.functions.zGetDomainInstallPath(row.site_short_domain), request.zos.installPath&"sites/", "");
		primaryPath=left(primaryPath, len(primaryPath)-1);
		var primaryDomain=replace(replace(row.site_domain, 'http://', ''), 'https://', '');
		arrayAppend(arrTemp, primaryDomain&' "'&primaryPath&'"; ## primary'&chr(10));
		for(var i=1;i LTE arrayLen(arrTemp2);i++){
			arrayAppend(arrTemp, trim(arrTemp2[i])&' "'&primaryPath&'";'&chr(10));
		}
		if(row.site_ssl_manager_domain NEQ ""){
			arrayAppend(arrTemp, trim(row.site_ssl_manager_domain)&' "'&primaryPath&'";'&chr(10));
		}
		arrayAppend(arrTemp, chr(10));
	} 
	var output='map $http_host $zmaindomain {
	hostnames;
	default "No Host Matched";
	'&arrayToList(arrTemp, '')&'
	}';
	// let's make a backup only once.
	if(not fileexists(request.zos.sharedPath&'hostmap.conf.backup')){
		application.zcore.functions.zrenamefile(request.zos.sharedPath&'hostmap.conf', request.zos.sharedPath&'hostmap.conf.backup');
	}
	application.zcore.functions.zwritefile(request.zos.sharedPath&'hostmap.conf', output);
	
	db.sql="select * from #db.table("domain_redirect", request.zos.zcoreDatasource)# domain_redirect,
	#db.table("site", request.zos.zcoreDatasource)# site
	where site.site_active=#db.param(1)# and 
	site.site_id <> #db.param(-1)# and 
	site_deleted = #db.param(0)# and 
	domain_redirect_deleted = #db.param(0)# and 
	domain_redirect.site_id = site.site_id and 
	domain_redirect_deleted = #db.param(0)#  and 
	domain_redirect_type=#db.param(0)# and 
	domain_redirect_old_domain <> #db.param('')# and 
	domain_redirect_old_domain <> domain_redirect_new_domain
	GROUP BY domain_redirect_old_domain 
	ORDER BY domain_redirect_old_domain ";
	var qSite=db.execute("qSite");
	var arrTemp=[];
	for(var row in qSite){
		var primaryDomain=replace(replace(row.domain_redirect_old_domain, 'http://', ''), 'https://', '');
		var destinationDomain=replace(replace(row.domain_redirect_new_domain, 'http://', ''), 'https://', '');
		if(row.domain_redirect_secure EQ "1"){
			arrayAppend(arrTemp, primaryDomain&' "https://'&destinationDomain&'";'&chr(10));
		}else{
			arrayAppend(arrTemp, primaryDomain&' "http://'&destinationDomain&'";'&chr(10));
		}
	} 
	var output='map $http_host $zredirectdomain {
	hostnames;
	default "";
	'&arrayToList(arrTemp, '')&'
	}';
	application.zcore.functions.zwritefile(request.zos.sharedPath&'hostmap-redirect.conf', output);

	application.zcore.functions.zdeletefile(request.zos.sharedPath&'hostmap-execute-complete.txt');
	application.zcore.functions.zwritefile(request.zos.sharedPath&'hostmap-execute-reload.txt', "1");
	var start=gettickcount();
	while(true){
		if((gettickcount() - start)/1000 GT 10){
			return {success:false, message: "hostmap.conf published, but the 10 second timeout was reached while waiting for the web server to reload. Check that the cron job #request.zos.scriptsPath#newsite.php is still working." };
		}
		if(fileexists(request.zos.sharedPath&'/hostmap-execute-complete.txt')){
			var tempMessage=application.zcore.functions.zreadfile(request.zos.sharedPath&'/hostmap-execute-complete.txt');
			application.zcore.functions.zdeletefile(request.zos.sharedPath&'/hostmap-execute-complete.txt');
			return {success:true, message: tempMessage };
		}
		sleep(1);
	}
	</cfscript> 
</cffunction>

<cffunction name="zUpdateDomainRedirectCache" localmode="modern" access="public" output="no">
	<cfscript>
	var db=request.zos.queryObject;
	db.sql="SELECT domain_redirect.*, site.site_domain FROM 
	#db.table("domain_redirect", request.zos.zcoreDatasource)#, 
	#db.table("site", request.zos.zcoreDatasource)# 
	WHERE site.site_id = domain_redirect.site_id and 
	domain_redirect_deleted = #db.param(0)#  and 
	site_deleted = #db.param(0)# and 
	domain_redirect_deleted = #db.param(0)# and 
	site.site_id <> #db.param(-1)# ";
	var qDomain=db.execute("qDomain"); 
	var domainRedirectStruct={};
	for(var row in qDomain){
		domainRedirectStruct[row.domain_redirect_old_domain]=row;
	}
	application.zcore.domainRedirectStruct=domainRedirectStruct;

	</cfscript>
</cffunction>

<cffunction name="zCheckDomainRedirect" localmode="modern" access="public" output="yes">
	<cfscript>
	var host=request.zos.cgi.http_host;
	var ds=0;  
	if(not structkeyexists(application.zcore.domainRedirectStruct, host)){
		application.zcore.functions.z404("checkDomainRedirect resulted in 404 because the host name is not mapped to a site on this installation. Please configure the server manager."); 
		application.zcore.functions.zabort();
	}
	ds=application.zcore.domainRedirectStruct[host];
	var protocol='http://';
	if(ds.domain_redirect_secure EQ 1){
		protocol = 'https://';
	}
	var theURL=replace(replace(request.zos.originalURL, "https:/" , ""), "http:/" , "");
	//writedump(ds, true, 'simple');	abort;
	if(ds.domain_redirect_type EQ '3'){
		application.zcore.functions.z404("checkDomainRedirect resulted in 404 by intentional configuration by site_id = #ds.site_id#, domain: #ds.site_domain#."); 
	}else if(ds.domain_redirect_type EQ '2'){ // force to exact url
		if(ds.domain_redirect_mask EQ '1'){
			writeoutput('#application.zcore.functions.zHTMLDoctype()#
			<head><meta charset="utf-8" /><title>#htmleditformat(ds.domain_redirect_title)#</title>
			<style type="text/css">html{height:100%;}</style>
			</head><body style="margin:0px; height:100%;">
			<iframe frameborder="0" scrolling="auto" height="100%" width="100%" src="#protocol&ds.domain_redirect_new_domain#" />
			</body></html>');
			application.zcore.functions.zabort();
		}else{
			//writeoutput("force to exact url: #protocol&ds.domain_redirect_new_domain#");			abort;
			application.zcore.functions.z301Redirect("#protocol&ds.domain_redirect_new_domain#");
		}
	}else if(ds.domain_redirect_type EQ '1'){ // all to root
		if(ds.domain_redirect_mask EQ '1'){
			writeoutput('#application.zcore.functions.zHTMLDoctype()#<head><meta charset="utf-8" /><title>#htmleditformat(ds.domain_redirect_title)#</title>
			<style type="text/css">html{height:100%;}</style>
			</head><body style="margin:0px; height:100%;">
			<iframe frameborder="0" scrolling="auto" height="100%" width="100%" src="#protocol&ds.domain_redirect_new_domain#"/>
			</body></html>');
			application.zcore.functions.zabort();
		}else{
			//writeoutput('all to root: '&"#protocol&ds.domain_redirect_new_domain#/");			abort;
			application.zcore.functions.z301Redirect("#protocol&ds.domain_redirect_new_domain#/");
		}
	}else if(ds.domain_redirect_type EQ '0'){ // preserve url
		if(ds.domain_redirect_mask EQ '1'){
			writeoutput('#application.zcore.functions.zHTMLDoctype()#<head><meta charset="utf-8" /><title>#htmleditformat(ds.domain_redirect_title)#</title>
			<style type="text/css">html{height:100%;}</style>
			</head><body style="margin:0px; height:100%;">
			<iframe frameborder="0" scrolling="auto" height="100%" width="100%" src="#protocol&ds.domain_redirect_new_domain&theURL#"/>
			</body></html>');
			application.zcore.functions.zabort();
		}else{ 
			var tempUrl=theURL; 
			var a=[];
			for(var i in form){
				if(i NEQ "fieldnames" and i NEQ request.zos.urlRoutingParameter and not isNull(form[i]) and isSimpleValue(form[i])){
					arrayAppend(a, i&"="&urlencodedformat(form[i]));	
				}
			}
			var q=arrayToList(a, "&");
			if(len(q) NEQ 0){
				q="?"&q;
			}
			//writeoutput("no mask: #protocol&ds.domain_redirect_new_domain&tempURL&q#");			abort;
			application.zcore.functions.z301Redirect("#protocol&ds.domain_redirect_new_domain&tempURL&q#"); 
		}
	} 
	</cfscript>
</cffunction>

<!--- 
var ts=application.zcore.functions.zGetEditableSiteOptionGroupSetById(groupStruct.__setId);
ts.name="New name";
var rs=application.zcore.functions.zUpdateSiteOptionGroupSet(ts);
if(not rs.success){
	application.zcore.status.setStatus(rs.zsid, false, form, true);
	application.zcore.functions.zRedirect("/?zsid=#rs.zsid#");
}else{
	writeoutput('Success !');
}
 --->
<cffunction name="zUpdateSiteOptionGroupSet" localmode="modern" access="public">
	<cfargument name="struct" type="struct" required="yes">
	<cfscript>
	var db=request.zos.queryObject;
	var siteOptionsCom=createobject("component", "zcorerootmapping.mvc.z.admin.controller.site-options"); 
	db.sql="SELECT * FROM #db.table("site_option", request.zos.zcoreDatasource)# site_option,
	 #db.table("site_option_group", request.zos.zcoreDatasource)# site_option_group 
	 WHERE 
	 site_option.site_id = site_option_group.site_id and 
	 site_option.site_option_group_id = site_option_group.site_option_group_id and 
	site_option_group.site_option_group_id = #db.param(arguments.struct.site_option_group_id)# and 
	site_option_deleted = #db.param(0)# and 
	site_option_group_deleted = #db.param(0)# and 
	site_option_group.site_id = #db.param(arguments.struct.site_id)#  ";
	var qD=db.execute("qD");
	structappend(form, arguments.struct, true);
	var arrSiteOption=[];
	for(var row in qD){
		arrayAppend(arrSiteOption, row.site_option_id);
		// doesn't work with time/date and other multi-field site option types probably...
		form['newvalue'&row.site_option_id]=arguments.struct[row.site_option_name];
	}
	form.site_option_id=arrayToList(arrSiteOption, ','); 
	var rs=siteOptionsCom.internalGroupUpdate(); 
	return rs;
	</cfscript>
</cffunction>


<cffunction name="zGetEditableSiteOptionGroupSetById" localmode="modern" access="public">
	<cfargument name="site_x_option_group_set_id" type="numeric" required="yes">
	<cfargument name="site_id" type="numeric" required="no" default="#request.zos.globals.id#"> 
	<cfscript>
	var s=application.zcore.functions.zGetSiteOptionGroupSetById(arguments.site_x_option_group_set_id);
	var db=request.zos.queryObject;
	if(arguments.site_id NEQ request.zos.globals.id){
		throw("zGetEditableSiteOptionGroupSetById() doesn't support other site ids yet.");
	}
	if(structcount(s) EQ 0){
		throw("site_x_option_group_set_id, #arguments.site_x_option_group_set_id#, doesn't exist, so it can't be edited.");
	}
	db.sql="select * from #db.table("site_x_option_group_set", request.zos.zcoreDatasource)# WHERE 
	site_x_option_group_set_id= #db.param(arguments.site_x_option_group_set_id)# and 
	site_x_option_group_set_deleted = #db.param(0)# and 
	site_id = #db.param(arguments.site_id)# ";
	var qS=db.execute("qS");
	if(qS.recordcount EQ 0){
		throw("site_x_option_group_set_id, #arguments.site_x_option_group_set_id#, doesn't exist, so it can't be edited.");
	}
	var n={};
	for(var i in s){
		if(s[i] EQ "/zupload/site-option/0"){
			n[i]="";
		}else if(left(i, 2) NEQ "__"){
			n[i]=s[i];
		}
	} 
	structappend(n, qS, false);
	return n;
	</cfscript>
</cffunction>

<cffunction name="zIsWidgetBuilderEnabled" localmode="modern" returntype="boolean" access="public">
	<cfscript>
	if(application.zcore.user.checkServerAccess()){
		return true;
	}else if(application.zcore.user.checkGroupAccess("member")){
		if(isdefined('request.zsession.user.enableWidgetBuilder') and request.zsession.user.enableWidgetBuilder EQ 1){
			return true;
		}else{
			return false;
		}
	}else if(application.zcore.functions.zso(request.zos.globals,'widgetBuilderEnabled',false,0) NEQ 1){
		 return false;
	}else{
		return true;
	}
	</cfscript>
</cffunction>

<cffunction name="zRequireTimePicker" localmode="modern" access="public">
	<cfscript>
	if(structkeyexists(request.zos, 'timePickerOutput')){
		return;
	}
	application.zcore.functions.zRequireJqueryUI();
	request.zos.timePickerOutput=true;
	application.zcore.template.prependTag("stylesheets", application.zcore.skin.includeCSS("/z/javascript/jquery/timePicker/timePicker.css"));
	application.zcore.template.appendTag("scripts", application.zcore.skin.includeJS("/z/javascript/jquery/timePicker/jquery.timePicker.js"));
	</cfscript>
</cffunction>

<cffunction name="zGetRootCFCPath" localmode="modern">
	<cfargument name="shortDomain" type="string" required="yes">
	<cfscript>
	var domain=replace(replace(arguments.shortDomain,'www.',''),"."&request.zos.testDomain,"");
	return replace(replace(domain,".","_","all"),"/",".","ALL")&".";
	</cfscript>
</cffunction>
<cffunction name="zRootSecureCfcPath" localmode="modern">
	<cfargument name="shortDomain" type="string" required="yes">
	<cfscript>
	var domain=replace(replace(arguments.shortDomain,'www.',''),"."&request.zos.testDomain,"");
	return "jetendo-sites-writable."&replace(replace(domain,".","_","all"),"/",".","ALL")&".";
	</cfscript>
</cffunction>

<cffunction name="zStatusHandler" localmode="modern" returntype="any" output="true">
	<cfargument name="id" type="string" required="yes">
	<cfargument name="getVars" type="boolean" required="no" default="#false#">
	<cfargument name="silent" type="boolean" required="no" default="#false#">
	<cfargument name="targetStruct" type="struct" required="no" default="#form#">
	<cfscript>
	var statusStruct = StructNew();
	var arrErrors = ArrayNew(1);
	statusStruct = application.zcore.status.getStruct(arguments.id);
	arrErrors = application.zcore.status.getErrors(arguments.id);
	if(isDefined('statusStruct.arrMessages')){
		if(arguments.getVars){
			StructAppend(arguments.targetStruct, statusStruct.varStruct, true);
		}
		if(arguments.silent EQ false){
			if(ArrayLen(statusStruct.arrMessages) GT 0 or ArrayLen(arrErrors) GT 0){
				writeoutput('<div style="float:left;width:100%;"><div style=" width:100%; overflow:hidden; display:block; clear:both; border-bottom:1px solid ##660000; margin-bottom:10px;">');
			}
			if(ArrayLen(statusStruct.arrMessages) GT 0){
				writeoutput('<div style="display:block; clear:both;float:left; color:##FFFFFF; width:98%; padding:1%; background-color:##990000; font-weight:bold;">Status:</div>');
				writeoutput('<div style="display:block; clear:both;float:left; color:##000000;width:98%; padding:1%; background-color:##FFFFFF;"><p style="padding-bottom:0px;">'&ArrayToList(statusStruct.arrMessages, '</p><hr /><p style="padding-bottom:0px;">')&'</p></div>');
				if(ArrayLen(arrErrors) GT 0){
					writeoutput('');
				}
			}
			if(ArrayLen(arrErrors) GT 0){
				writeoutput('<div style="display:block; clear:both;float:left; color:##FFFFFF; width:98%; padding:1%; font-weight:bold; background-color:##993333;">The following errors occurred:</div>');
				writeoutput('<div style="display:block; clear:both;float:left; color:##000000; width:98%; padding:1%; background-color:##FFFFFF;"><p style="padding-bottom:0px;">'&ArrayToList(arrErrors, '</p><hr /><p style="padding-bottom:0px;">')&'</p></div>');
			}
			if(ArrayLen(statusStruct.arrMessages) GT 0 or ArrayLen(arrErrors) GT 0){
				writeoutput('</div></div><br style="clear:both;" />');
			}
		}
	}
	</cfscript>
</cffunction>


<cffunction name="zIsDeveloper" localmode="modern" returntype="boolean" output="no">
	<cfscript>
	if(structkeyexists(request.zos.adminIpStruct,request.zos.cgi.remote_addr) and request.zos.adminIpStruct[request.zos.cgi.remote_addr] EQ false){
		request.zos.isDeveloper=true;
		return true;
	}else{
		request.zos.isDeveloper=false;
		return false;
	}
    </cfscript>
</cffunction>

<cffunction name="zUpdateCustomSiteFunctions" localmode="modern">
	<cfargument name="ss" type="struct" required="yes">
	<cfscript>
	if(arguments.ss.site_id EQ request.zos.globals.serverId){
		local.com=createobject("component", "zcorerootmapping.zCoreCustomFunctions");
		//structappend(ts.zcorecustomfunctions, local.com, true);
		arguments.ss.zcorecustomfunctions=local.com;
		if(structkeyexists(arguments.ss.zcorecustomfunctions, 'onSiteRequestStart')){
			arguments.ss.onSiteRequestStartEnabled=true;
		}
		if(structkeyexists(arguments.ss.zcorecustomfunctions, 'onSiteRequestEnd')){
			arguments.ss.onSiteRequestEndEnabled=true;
			
		}
	}else if(fileexists(arguments.ss.globals.homedir&'zCoreCustomFunctions.cfc')){
		local.com=createobject("component", request.zRootCfcPath&"zCoreCustomFunctions");
		//structappend(arguments.ss.zcorecustomfunctions, local.com, true);
		arguments.ss.zcorecustomfunctions=local.com;
		if(structkeyexists(arguments.ss.zcorecustomfunctions, 'onSiteRequestStart')){
			arguments.ss.onSiteRequestStartEnabled=true;
		}
		if(structkeyexists(arguments.ss.zcorecustomfunctions, 'onSiteRequestEnd')){
			arguments.ss.onSiteRequestEndEnabled=true;
			
		}
	}else if(fileexists(arguments.ss.globals.homedir&'zCoreCustomFunctions.cfm')){
		include template="#request.zRootPath#zCoreCustomFunctions.cfm";
		if(not structkeyexists(arguments.ss, 'zcorecustomfunctions')){
			arguments.ss.zcorecustomfunctions={};
		}
		structappend(arguments.ss.zcorecustomfunctions, variables.zcorecustomfunctions, true);
		if(structkeyexists(arguments.ss.zcorecustomfunctions, 'onSiteRequestStart')){
			arguments.ss.onSiteRequestStartEnabled=true;
		}
		if(structkeyexists(arguments.ss.zcorecustomfunctions, 'onSiteRequestEnd')){
			arguments.ss.onSiteRequestEndEnabled=true;
			
		}
		structdelete(variables, 'zcorecustomfunctions');
	}else{
		arguments.ss.zcoreCustomFunctions={};
		arguments.ss.onSiteRequestStartEnabled=false;
		arguments.ss.onSiteRequestEndEnabled=false;
	}
	</cfscript>
</cffunction>

<cffunction name="zGetSite" localmode="modern">
	<cfargument name="ss" type="struct" required="yes">
	<cfscript>
	var local=structnew();
	var db2=0;
	var template=0;
	var ts=structnew();
	application.zcore.functions.zClearCFMLTemplateCache();
	arrayappend(request.zos.arrRunTime, {time:gettickcount('nano'), name:'Application.cfc getSite begin'});
	request.zos.globals=arguments.ss.globals;
	request.zos.site_id=request.zos.globals["id"];
	ts.globals=arguments.ss.globals;
	ts.site_id=arguments.ss.globals.id;
	request.zRootDomain=replace(replace(request.zos.globals.shortDomain,'www.',''),"."&request.zos.testDomain,"");
	request.zRootPath="/"&replace(request.zRootDomain, ".","_","all")&"/";
	request.zRootSecureCfcPath="jetendo-sites-writable."&replace(replace(request.zRootDomain,".","_","all"),"/",".","ALL")&".";
	request.zRootCfcPath=replace(replace(request.zRootDomain,".","_","all"),"/",".","ALL")&".";
	local.tempInstallPath=application.zcore.functions.zGetDomainInstallPath(request.zRootDomain);
	request.zos.globals.homedir=application.zcore.functions.zGetDomainInstallPath(request.zos.globals.shortDomain); 
	request.zos.globals.privatehomedir=application.zcore.functions.zGetDomainWritableInstallPath(request.zos.globals.shortDomain); 
	request.zos.globals.securehomedir=local.tempInstallPath; 
	if(request.zos.globals.disableCFML EQ 1){
		return ts;
	}
	ts.hasTemplates=false;
	if(directoryexists(request.zos.globals.homedir&"templates/")){
		ts.hasTemplates=true;
	}
	ts.administratorTemplateMenuCache={};

	request.zos.db=application.zcore.componentObjectCache.db;
	ts.dbComponents=application.zcore.functions.getSiteDBObjects(ts.globals);
	
	request.zos.queryObject=ts.dbComponents.cacheEnabledDB.newQuery();
	request.zos.noVerifyQueryObject=ts.dbComponents.cacheEnabledNoVerifyDB.newQuery();
	
	ts.adminFeatureMapStruct=application.zcore.adminSecurityFilter.getFeatureMap();
	
	ts.comCache=structnew();
	ts.contentPageIDCache=structnew();
	ts.contentPageCache=structnew();
	ts.blogArticleIDCache=structnew();
	ts.blogArticleCache=structnew();
	ts.blogCategoryIDCache=structnew();
	ts.blogCategoryCache=structnew();
	ts.blogTagIDCache=structnew();
	ts.blogTagCache=structnew();
	ts.directoryExistsCache=structnew();
	ts.fileExistsCache=structnew();
	ts.onSiteRequestStartEnabled=false;
	ts.onSiteRequestEndEnabled=false;
	
	application.zcore.functions.zUpdateCustomSiteFunctions(ts);
	
	ts.menuIdCacheStruct=structnew();	
	ts.menuNameCacheStruct=structnew();	
	ts.slideshowIdCacheStruct=structnew();
	ts.slideshowNameCacheStruct=structnew();

	
	</cfscript>
	<cfsavecontent variable="request.zos.noVerifyQueryObject.sql">
	SHOW DATABASES like '#ts.globals.datasource#'
	</cfsavecontent><cfscript>local.qA=request.zos.noVerifyQueryObject.execute('qA');</cfscript>
	<cfif local.qA.recordcount EQ 0>
		<cfthrow type="exception" message="ERROR: The database and datasource name must be identical. #ts.globals.datasource# does not exist in database server. Please correct site globals.">
	</cfif>
	<cfscript>
	ts.cacheData={
		urlDatabaseCache={},
		databaseURLCache={}
	};
	if(not directoryexists(ts.globals.privatehomedir&"zupload")){
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload/user");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload/library");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload/slideshow");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload/video");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload/ssi");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload/site-options");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zupload/member");
	}
	if(not directoryexists(ts.globals.privatehomedir&"zuploadsecure")){
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure/user");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure/library");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure/slideshow");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure/video");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure/ssi");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure/site-options");
		application.zcore.functions.zcreatedirectory(ts.globals.privatehomedir&"zuploadsecure/member");
	}
	
	
	application.zcore.functions.zUpdateSiteMVCData(ts);

	
	ts.imageLibraryStruct=structnew();
	ts.imageLibraryStruct.sizeStruct=structnew();
	
	//structdelete(request,'app');
	if(request.zos.allowRequestCFC){
		request.zos.routing=application.zcore.componentObjectCache.routing;
	}
	local.routingCom= application.zcore.componentObjectCache.routing;
	local.routingCom.initRewriteRuleApplicationStruct(ts);
	
	local.appCom =application.zcore.app;
	local.appCom.onSiteStart(ts);
	local.skin=application.zcore.skin;
	local.skin.onSiteStart(ts);
	
	ts.leadRoutingStruct=application.zcore.functions.zGetLeadRoutesStruct();
	ts.getSiteRan=true;
	arrayappend(request.zos.arrRunTime, {time:gettickcount('nano'), name:'Application.cfc getSite end'});
	return ts;
	</cfscript>
</cffunction>

<cffunction name="zUpdateSiteMVCData" localmode="modern" output="no">
	<cfargument name="ss" type="struct" required="yes">
	<cfscript>
	ts={};
	ts.cfcMetaDataCache=structnew();
	 
	ts.controllerComponentCache=structnew();
	/*ts.modelDataCache=structnew();
	ts.modelDataCache.modelComponentCache=structnew();
	ts.modelDataCache.selectComponentCache=structnew();
	ts.modelDataCache.selectComponent=createobject("component","zcorerootmapping.com.model.select");
	ts.modelDataCache.tableCache=structnew();
	
	if(structkeyexists(form,  'zregeneratemodelcache')){
		local.tempCom=createobject("component","zcorerootmapping.com.model.base");
		local.tempCom._generateModels(ts);
	}*/
	ts.registeredControllerStruct=structnew();
	ts.registeredControllerPathStruct=structnew();
	local.arrNewComPath=arraynew(1);
	 
	if(structkeyexists(arguments.ss.globals,'mvcPaths') and arguments.ss.globals.mvcPaths NEQ ""){
		arrMvcPaths=listtoarray(arguments.ss.globals.mvcPaths,",");
	}else{
		arrMvcPaths=arraynew(1);	
	}
	for(local.i=1;local.i LTE arraylen(arrMvcPaths);local.i++){
		arrMvcPaths[local.i]=request.zRootCFCPath&arrMvcPaths[local.i];
	} 
	if(directoryexists(request.zos.installPath&"themes/"&arguments.ss.globals.themeName&"/mvc/")){
		arrayAppend(arrMvcPaths, "jetendo-themes."&arguments.ss.globals.themeName&".mvc");
	}
	</cfscript>
	<!--- get all models, controllers and views in the mvc path and precache or precompile them into the application scope --->
	<cfloop from="1" to="#arraylen(arrMvcPaths)#" index="local.i2">
		<cfscript>
		local.i=local.i2;
		if(left(arrMvcPaths[local.i], 15) EQ "jetendo-themes."){
			local.curPath=replace(expandpath(request.zos.installPath&"themes/"&replace(removechars(arrMvcPaths[local.i], 1, 15),'.','/','all')),"\","/","all");
		}else{
			local.curPath=replace(expandpath('/'&replace(arrMvcPaths[local.i],'.','/','all')),"\","/","all");
		}
		</cfscript>
		<cfdirectory action="list" recurse="yes" directory="#local.curPath#" name="local.qD" filter="*.cfc|*.html">
			<!--- <cfif qd.recordcount>
	<cfdump var="#qD#"><cfabort>
</cfif> --->
		<cfloop query="local.qD">
			<cfscript>
			if(local.qD.type EQ "file"){
				local.curPath2=removechars(replace(replace(local.qD.directory,"\","/","all"),local.curPath,""),1,1);
				local.arrPath2=listtoarray(local.curPath2,"/",false);
				local.fileType=listgetat(local.curPath2,1,"/");
				local.curPath3=replace(local.curPath2,"/",".","all");
				local.curPath4=listdeleteat(local.curPath3,1,".");
				local.curName=listgetat(local.qD.name,1,".");
				local.curExt=listgetat(local.qD.name,2,".");
				local.lastFolderName=listgetat(local.curPath2,listlen(local.curPath2, "/", true),"/");
				if(local.curName CONTAINS "."){
					application.zcore.functions.zerror(local.qD.directory&"/"&local.qD.name&" - A CFC file name can't have a period after the "".cfc"" is removed from the end.  Please remove the periods in the name, ""."", leave the "".cfc"" at the end and try again.");	
				}
				//writeoutput("lastfoldername:"&local.lastFolderName&"<br />curname:"&local.curName&"<br /> filetype:"&local.fileType&"<br />curpath3:"&local.curPath3&"<br />curPath4:"&local.curPath4&"<br />curPath2:"&local.curPath2&"<br />");
				
				// local.curPath3 is z.z2.controller  - which is perfect for mvcName lookup struct below: registeredControllerStruct
				if(local.lastFolderName EQ "controller"){
					if(local.curExt EQ "cfc"){
						local.comPath=arrMvcPaths[local.i]&"."&local.curPath3&"."&local.curName;
						local.tempCom=createobject("component", local.comPath);
						
						ts.controllerComponentCache[local.comPath]=local.tempCom;
						
						tempcommeta=GetMetaData(local.tempCom);
						ts.cfcMetaDataCache[local.comPath]=tempcommeta;
						if(structkeyexists(local.tempcommeta, 'functions')){
							for(local.i3=1;local.i3 LTE arraylen(local.tempcommeta.functions);local.i3++){
								if(structkeyexists(local.tempcommeta.functions[local.i3],"access") and local.tempcommeta.functions[local.i3].access EQ "remote"){
									ts.cfcMetaDataCache[local.comPath&":"&local.tempcommeta.functions[local.i3].name]=local.tempcommeta.functions[local.i3];
								}
							}
						}
						if(structkeyexists(local.tempCom,'mvcName')){
							local.curMvcName="/"&local.curpath2&"/"&local.tempCom.mvcName;
						}else{
							local.curMvcName="/"&local.curpath2&"/"&local.curName;
						}
						//writeoutput('<hr>'&local.curPath2&'<br />');
						//writeoutput("compath:"&local.comPath&"<br />curmvcname:"&local.curMvcName&"<br />");
						local.t42="";
						for(local.i4=1;local.i4 LTE arraylen(local.arrPath2);local.i4++){
							local.t42&="/"&local.arrPath2[local.i4];
							ts.registeredControllerPathStruct[local.t42]=true;
						}
						ts.registeredControllerStruct[local.curMvcName]="/"&replace(arrMvcPaths[local.i],'.','/','all')&"/"&local.curPath2&"/"&local.qD.name;
					}
				}else if(local.lastFolderName EQ "model"){
					if(local.curExt EQ "cfc"){
						local.comPath=arrMvcPaths[local.i]&"."&local.curPath3&"."&local.curName;
						if(structkeyexists(form,  'zregeneratemodelcache') EQ false and structkeyexists(application, 'zcore') and structkeyexists(application.sitestruct[request.zos.globals.id],'modelDataCache') and structkeyexists(application.sitestruct[request.zos.globals.id].modelDataCache.modelComponentCache, local.comPath)){
							ts.modelDataCache.modelComponentCache[local.comPath]=application.sitestruct[request.zos.globals.id].modelDataCache.modelComponentCache[local.comPath];
							//writeoutput('#local.curName#: use existing<br />');
						}else{
							arrayappend(local.arrNewComPath, local.comPath);
							//ts.modelDataCache.modelComponentCache[local.comPath]=createobject("component", local.comPath);
							//writeoutput('#local.curName#: use new<br />');
						}
					}
				}else if(local.lastFolderName EQ "view"){
					if(local.curExt EQ "html"){
						//writeoutput('application.zcore.skin.loadView("'&local.curPath3&"."&local.curName&'", "'&arrMvcPaths[local.i]&'");<br />');
						// application.zcore.skin.loadView("/"&curPath2&"/"&curName, arrMvcPaths[local.i]);
					}
				}
				//writeoutput("curdir:"&local.curPath2&"|"&local.fileType&"<br />");
				//writeoutput(directory&"\"&name&"<br />");
			}
			</cfscript>
		</cfloop>

	</cfloop>
	<!--- <cfscript>
	local.curPath=replace(request.zos.globals.privatehomedir&'_cache/model/',"\","/","all");
	if(directoryexists(local.curPath) EQ false){
		application.zcore.functions.zcreatedirectory(local.curPath);
	}
	//writeoutput(local.curPath&'<br />');
	
	</cfscript>
	<cfdirectory action="list" recurse="yes" directory="#local.curPath#" name="local.qD" filter="*.cfc">
	<cfloop query="local.qD">
		<cfscript>
		local.curPath2=replace(replace(local.qd.directory,"\","/","all"),local.curPath,"");
		local.fileType=listgetat(local.curPath2,1,"/");
		local.curName=listgetat(local.qd.name,1,".");
		if(local.fileType EQ "select"){
			// file is in /_cache/model/select/
		//	ts.modelDataCache.selectComponentCache[local.curName]=createobject("component",request.zRootSecureCFCPath&"_cache.model.select."&local.curName);
		
		/*}else if(local.fileType EQ "server cache path"){ 
			local.comPath="zcorecachemapping.model."&local.curName;
			if(structkeyexists(form,  'zregeneratemodelcache') EQ false and structkeyexists(application, 'zcore') and structkeyexists(application.sitestruct[request.zos.globals.id].modelDataCache.modelComponentCache, local.comPath)){
				ts.modelDataCache.modelComponentCache[local.comPath]=application.sitestruct[request.zos.globals.id].modelDataCache.modelComponentCache[local.comPath];
				//writeoutput('#local.curName#: use existing<br />');
			}else{
				//ts.modelDataCache.modelComponentCache[local.comPath]=createobject("component", local.comPath);
				arrayappend(local.arrNewComPath, local.comPath);
				//writeoutput('#local.curName#: use new<br />');
			}
			*/
		}else{
			local.comPath=request.zRootSecureCFCPath&"_cache.model."&local.curName;
			if(structkeyexists(form,  'zregeneratemodelcache') EQ false and structkeyexists(application, 'zcore') and structkeyexists(application.sitestruct[request.zos.globals.id].modelDataCache.modelComponentCache, local.comPath)){
				ts.modelDataCache.modelComponentCache[local.comPath]=application.sitestruct[request.zos.globals.id].modelDataCache.modelComponentCache[local.comPath];
				//writeoutput('#local.curName#: use existing<br />');
			}else{
				//ts.modelDataCache.modelComponentCache[local.comPath]=createobject("component", local.comPath);
				arrayappend(local.arrNewComPath, local.comPath);
				//writeoutput('#local.curName#: use new<br />');
			}
		}
		//writeoutput(name&'|'&local.fileType&'|'&local.curName&'<br />');
		</cfscript>
	</cfloop>
	<cfif arraylen(local.arrNewComPath) NEQ 0>
		<cfscript>
		local.threadOutputStruct=structnew();
		//writeoutput("building:"&arraylen(local.arrNewComPath));
		local.arrThread=arraynew(1);
		local.arrError=arraynew(1);
		local.iprocessed=1;
		/*
		m3=arraynew(1);
		for(i=1;i LTE arraylen(local.arrNewComPath);i++){
			arrayappend(m3, createobject("component",local.arrNewComPath[i]));
		}*/
		</cfscript>
		<cfloop from="1" to="#arraylen(local.arrNewComPath)#" index="local.i"><!---1 EQ 0 and arraylen(local.arrNewComPath) --->
			<cfscript>
			local.threadIndex=arraylen(local.arrThread)+1;
			arrayAppend(local.arrThread, "thread"&local.threadIndex);
			</cfscript>
			<cfthread name="thread#local.threadIndex#" arrCom="#local.arrNewComPath#" timeout="10" index="#local.i#" action="run">
				<cfscript>
				thread.myIndex=index;
				thread.errorMessage="";
				</cfscript>
				<cftry>
					<cfscript>
					thread.curCom=arrCom[index];
					thread.myObject=createobject("component",arrCom[index]);
					</cfscript>
					<cfcatch type="any">
						<cfscript>
						thread.errorMessage=cfcatch.message;
						thread.myObject=structnew();
						</cfscript>
					</cfcatch>
				</cftry>
			</cfthread>
			<cfif local.threadIndex EQ 7>
				<cfthread action="join" name="#arraytolist(local.arrThread,",")#" timeout="15000" />
				<cfscript>
				for(local.i2=local.iprocessed;local.i2 LTE arraylen(local.arrThread);local.i2++){
					local.ct=evaluate(local.arrThread[local.i2]);
					if(local.ct.status EQ "TERMINATED"){
						arrayAppend(local.arrError, "Failed to compile: "&local.arrNewComPath[local.ct.myIndex]&" | CFTHREAD ERROR: "&local.ct.error.message);
					}else{
						if(structkeyexists(local.ct,'myObject') EQ false){
							writeoutput('failed to compile component: '&local.ct.curCom&' with error message: '&local.ct.errorMessage&'<br />');
						}else{
							local.threadOutputStruct[local.ct.myIndex]=local.ct.myObject;
						}
					}
					local.iprocessed++;
				}
				</cfscript>
			</cfif>
		</cfloop>
		<cfthread action="join" name="#arraytolist(local.arrThread,",")#" timeout="15000" />
		
		<cfscript>
		for(local.i2=local.iprocessed;local.i2 LTE arraylen(local.arrThread);local.i2++){
			local.ct=evaluate(local.arrThread[local.i2]);
			if(local.ct.status EQ "terminated"){
				arrayAppend(local.arrError, "Failed to compile: "&local.arrNewComPath[local.ct.myIndex]&" | CFTHREAD ERROR: "&local.ct.error.message);
			}else{
				if(structkeyexists(local.ct,'myObject') EQ false){
					writeoutput('failed to compile component: '&local.ct.curCom&' with error message: '&local.ct.errorMessage&'<br />');
				}else{
					local.threadOutputStruct[local.ct.myIndex]=local.ct.myObject;
				}
			}
			local.iprocessed++;
		}
		local.arrThread=arraynew(1);
		
		for(local.i in local.threadOutputStruct){
			if(isSimpleValue(local.threadOutputStruct[local.i]) EQ false){
				ts.modelDataCache.modelComponentCache[local.arrNewComPath[local.i]]=local.threadOutputStruct[local.i];
			}else{
					
			}
		}
		</cfscript>
		<cfif arraylen(local.arrError) NEQ 0>
			<cfthrow type="exception" message="#arraytolist(local.arrError,'<br />')#">
		</cfif>
	</cfif>		 --->
	<cfscript> 
	structappend(arguments.ss, ts, true);
	structdelete(form, 'zregeneratemodelcache');
	
	</cfscript>
</cffunction>
<cffunction name="zCreateObject" localmode="modern" output="no" returntype="any">
    <cfargument name="c" type="string" required="yes">
    <cfargument name="cpath" type="string" required="yes">
    <cfargument name="forceNew" type="boolean" required="no" default="#false#">
    <cfscript>
    var c=0;
	var i=0;
	var t9=0;
	var t7=0;
	var e=0;
	var e2=0;
    if(structkeyexists(application.zcore,'allcomponentcache') EQ false){
        application.zcore.allcomponentcache=structnew();
    }
	t7=application.zcore.allcomponentcache;
    if(structkeyexists(t7,arguments.cpath) EQ false or arguments.forceNew){
		try{
			t9=createobject("component",arguments.cpath);
		}catch(Any e){
			savecontent variable="local.e2"{
				writedump(e, true, 'simple');	
			}
			if(not fileexists(expandpath(replace(arguments.cpath, ".","/","all")&".cfc"))){
				application.zcore.functions.z404("zCreateObject() c:"&arguments.c&"<br />cpath:"&arguments.cpath&"<br />forceNew:"&arguments.forceNew&"<br />request.zos.cgi.SCRIPT_NAME:"&request.zos.cgi.SCRIPT_NAME&"<br />catch error:"&local.e2);
			}else{
				rethrow;
			}
		}
        application.zcore.allcomponentcache[arguments.cpath]=t9;
    }
	t7=application.zcore.allcomponentcache[arguments.cpath];
    c=duplicate(t7);
    for(i in c){
        if(isstruct(c[i])){
            c[i]=structnew();
            structappend(c[i],duplicate(t7[i]),true);
        }
    }
    return c;
    </cfscript>
</cffunction>



<cffunction name="zImageOutput" localmode="modern" returntype="any" output="yes"><cfargument name="filePath" type="string" required="yes"><cfargument name="type" type="string" required="yes"><!--- image/jpeg or image/gif ---><cfif (arguments.type EQ 'image/jpeg' and right(arguments.filePath,4) EQ '.jpg') or (arguments.type EQ 'image/gif' and right(arguments.filePath,4) EQ '.gif')><cfheader name="Content-Disposition" value="inline; filename=#getfilefrompath(arguments.filePath)#"><cfcontent type="#arguments.type#" deletefile="no" file="#arguments.filePath#"><cfelse><cfscript>application.zcore.template.fail("zImageOutput(): arguments.filePath must be an absolute path to a jpeg or gif with arguments.type equal to image/jpeg or image/gif.");</cfscript></cfif><cfscript>application.zcore.functions.zabort();</cfscript></cffunction>
<!---  --->

<!--- application.zcore.functions.zModalCancel(); --->
<cffunction name="zModalCancel" localmode="modern" output="no" returntype="any">
	<cfscript>
    if(structkeyexists(request.zos,'modalWindowCancelled') EQ false){
		request.zos.modalWindowCancelled=true;
		application.zcore.template.prependTag("content",'<script type="text/javascript">/* <![CDATA[ */ var zModalCancelFirst=true; /* ]]> */</script>');
		application.zcore.template.appendTag("meta",'<script type="text/javascript">/* <![CDATA[ */ var zModalCancelFirst=true; /* ]]> */</script>');
	}
	</cfscript>
</cffunction>
<cffunction name="zErrorMetaData" localmode="modern" output="no" returntype="any">
    <cfargument name="errorMessage" type="string" required="yes">
    <cfscript>
    if(structkeyexists(request,'zArrErrorMessages') EQ false){
        request.zArrErrorMessages=arraynew(1);	
    }
    arrayappend(request.zArrErrorMessages, arguments.errorMessage);
    </cfscript>
    
</cffunction>


<cffunction name="zRequireContentFlowSlideshow" localmode="modern" output="yes" returntype="any">
    <cfargument name="package" type="string" required="no" default="">
    <cfscript>
	var theOutput="";
    if(structkeyexists(request.zos, 'zRequireContentFlowSlideshowIncluded')) return;
	request.zos.zRequireContentFlowSlideshowIncluded=true;
	</cfscript>
	<!--- <cfscript>
	var ts=structnew();
    if(structkeyexists(request.zos, 'zRequireContentFlowSlideshowIncluded')) return;
	application.zcore.functions.zRequireJquery();
	request.zos.zRequireContentFlowSlideshowIncluded=true;
	ts.type="zRequireContentFlowSlideshow";
	if(request.zos.istestserver){
		ts.url="/z/javascript/ContentFlow/contentflow_src.js";
	}else{
		ts.url="/z/javascript/ContentFlow/contentflow.js";
	}
	ts.package=arguments.package;
	ts.forcePosition="";
	arrayappend(request.zos.arrJSIncludes, ts);
	ts=structnew();
	ts.type="zRequireContentFlowSlideshow";
	if(request.zos.istestserver){
		ts.url="/z/javascript/ContentFlow/contentflow_src.css";
	}else{
		ts.url="/z/javascript/ContentFlow/contentflow.css";
	}
	ts.package=arguments.package;
	ts.forcePosition="";
	arrayappend(request.zos.arrCSSIncludes, ts);
    </cfscript> --->
    <cfsavecontent variable="theOutput">
    <cfif request.zos.istestserver>
    <link type="text/css" href="/z/javascript/ContentFlow/contentflow_src.css" rel="stylesheet" />
    <script type="text/javascript" src="/z/javascript/ContentFlow/contentflow_src.js"></script>
    <cfelse>
    <link type="text/css" href="/z/javascript/ContentFlow/contentflow.css" rel="stylesheet" />
    <script type="text/javascript" src="/z/javascript/ContentFlow/contentflow.js"></script>
    </cfif>
    </cfsavecontent>
    <cfscript>
	application.zcore.template.appendTag("meta",theOutput);
	</cfscript>
</cffunction>

<!--- application.zcore.functions.zRequireModernizr(); --->
<cffunction name="zRequireModernizr" localmode="modern" output="yes" returntype="any">
    <cfargument name="package" type="string" required="no" default="">
    <cfscript>
	var theMeta="";
	var ts=structnew();
    application.zcore.functions.zForceIncludePackage("zRequireModernizr", arguments.package);
	</cfscript>
    <cfif structkeyexists(request.zos,'JavascriptRequiredModernizr') EQ false>
	<!--- <cfsavecontent variable="theMeta"><cfif request.zos.istestserver><!--- <script src="/z/javascript/jquery/modernizr.2.6.1.min-small.js"></script> ---><!--- <script src="/z/javascript/jquery/modernizr.2.6.1.min.js"></script> ---><cfelse><!--- <script src="/z/javascript/jquery/modernizr.2.6.1.min-small.js"></script> ---></cfif></cfsavecontent> --->
    <cfscript>//application.zcore.template.appendTag("meta",theMeta);
    request.zos.JavascriptRequiredModernizr=true;</cfscript>
    </cfif>
</cffunction>


<!--- application.zcore.functions.zExecuteCSSJSIncludes(); --->
<cffunction name="zExecuteCSSJSIncludes" localmode="modern" output="yes" returntype="any">
	<cfscript>
	var local=structnew();
	local.tout="";
	
	
	local.jsLength=arraylen(request.zos.arrJSIncludes);
	local.cssLength=arraylen(request.zos.arrCSSIncludes);
	
	if(request.zos.globals.enableMinCat EQ 0 or structkeyexists(request.zos.tempObj,'disableMinCat')){
		if(structkeyexists(request.zos,'inMemberArea') and request.zos.inMemberArea EQ false){
			for(local.i=1;local.i LTE arraylen(application.sitestruct[request.zos.globals.id].globalHTMLHeadSourceArrCSS);local.i++){
				local.tout&=application.zcore.skin.includeCSS(application.sitestruct[request.zos.globals.id].globalHTMLHeadSourceArrCSS[local.i],'last');
			}
			for(local.i=1;local.i LTE arraylen(application.sitestruct[request.zos.globals.id].globalHTMLHeadSourceArrJS);local.i++){
				local.tout&=application.zcore.skin.includeJS(application.sitestruct[request.zos.globals.id].globalHTMLHeadSourceArrJS[local.i],'last');
			}
		}
	}
	// determine if files in package have changed
	if(structkeyexists(application.sitestruct[request.zos.globals.id],'packageJSCacheStruct') EQ false){
		application.sitestruct[request.zos.globals.id].packageJSCacheStruct=StructNew();
		application.sitestruct[request.zos.globals.id].packageCSSCacheStruct=StructNew();
		// rebuild from disk the packages.
		for(local.i in request.zos.includePackageStruct){
			if(local.jsLength NEQ 0){
				if(fileexists(request.zos.globals.homedir&"_z-"&local.i&".js")){
					local.f=application.zcore.skin.getFile("/_z-"&local.i&".js");
					application.sitestruct[request.zos.globals.id].packageJSCacheStruct[local.i]=local.f.file_modified_datetime;
				}else{
					application.sitestruct[request.zos.globals.id].packageJSCacheStruct[local.i]=false;
				}
			}
			if(local.cssLength NEQ 0){
				if(fileexists(request.zos.globals.homedir&"_z-"&local.i&".css")){
					local.f=application.zcore.skin.getFile("/_z-"&local.i&".css");
					application.sitestruct[request.zos.globals.id].packageCSSCacheStruct[local.i]=local.f.file_modified_datetime;
				}else{
					application.sitestruct[request.zos.globals.id].packageCSSCacheStruct[local.i]=false;
				}
			}
		}
	}
	// this code doesn't do anything!
	local.pStructCSSChanged=structnew();
	local.pStructCSS=structnew();
	local.pStructJSChanged=structnew();
	local.pStructJS=structnew();
	for(local.i=1;local.i LTE local.jsLength;local.i++){
		local.p=request.zos.arrJSIncludes[local.i].package;
		if(structkeyexists(local.pStructJSChanged, local.p) EQ false and request.zos.arrJSIncludes[local.i].package NEQ ""){
			local.pStructJSChanged[local.p]=false;
			local.pStructJS[local.p]=structnew();
			local.pStructJS[local.p].arr1=arraynew(1);
			local.pStructJS[local.p].arr2=arraynew(1);
			local.pStructJS[local.p].arr3=arraynew(1);
			if(local.jsLength NEQ 0 and structkeyexists(application.sitestruct[request.zos.globals.id].packageJSCacheStruct,local.p) EQ false){
				application.sitestruct[request.zos.globals.id].packageJSCacheStruct[local.p]=false;
			}
		}
	}
	for(local.i=1;local.i LTE local.cssLength;local.i++){
		local.p=request.zos.arrCSSIncludes[local.i].package;
		if(structkeyexists(local.pStructCSSChanged, local.p) EQ false and request.zos.arrCSSIncludes[local.i].package NEQ ""){
			local.pStructCSSChanged[local.p]=false;
			local.pStructCSS[local.p]=structnew();
			local.pStructCSS[local.p].arr1=arraynew(1);
			local.pStructCSS[local.p].arr2=arraynew(1);
			local.pStructCSS[local.p].arr3=arraynew(1);
			if(local.cssLength NEQ 0 and structkeyexists(application.sitestruct[request.zos.globals.id].packageCSSCacheStruct,local.p) EQ false){
				application.sitestruct[request.zos.globals.id].packageCSSCacheStruct[local.p]=false;
			}
		}
	} 
	request.zos.arrJSIncludes=arrayreverse(request.zos.arrJSIncludes);
	request.zos.arrCSSIncludes=arrayreverse(request.zos.arrCSSIncludes);
	for(local.i=1;local.i LTE local.jsLength;local.i++){
		if(request.zos.arrJSIncludes[local.i].package EQ ""){
			application.zcore.template.prependTag("scripts",application.zcore.skin.includeJS(request.zos.arrJSIncludes[local.i].url, 'first'));//request.zos.arrJSIncludes[local.i].forcePosition));
		}
	}
	for(local.i=1;local.i LTE local.cssLength;local.i++){
		if(request.zos.arrCSSIncludes[local.i].package EQ ""){
			application.zcore.template.prependTag("stylesheets",application.zcore.skin.includeCSS(request.zos.arrCSSIncludes[local.i].url, 'first'));//request.zos.arrCSSIncludes[local.i].forcePosition));
		}
	} 
	</cfscript>
</cffunction>

<cffunction name="zForceIncludePackage" localmode="modern" output="no" returntype="any">
    <cfargument name="type" type="string" required="yes">
    <cfargument name="package" type="string" required="no" default="">
	<cfscript>
	var i=1;
	if(arguments.package NEQ ""){
		request.zos.includePackageStruct[arguments.package]=true;
		for(i=1;i LTE arraylen(request.zos.arrJSIncludes);i++){
			if(request.zos.arrJSIncludes[i].type EQ arguments.type){
				request.zos.arrJSIncludes[i].package=arguments.package;	
			}
		}
		for(i=1;i LTE arraylen(request.zos.arrCSSIncludes);i++){
			if(request.zos.arrCSSIncludes[i].type EQ arguments.type){
				request.zos.arrCSSIncludes[i].package=arguments.package;	
			}
		}
	}
	</cfscript>
</cffunction>



<!--- application.zcore.functions.zRequireGoogleMaps(); --->
<cffunction name="zRequireGoogleMaps" localmode="modern" output="no" returntype="any"> 
	<cfscript>
	var theMeta="";
	var ts=structnew();
	if(structkeyexists(request.zos,'JavascriptRequiredGoogleMaps') EQ false){
		application.zcore.skin.includeJS("https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false&callback=zMapInit");
		request.zos.JavascriptRequiredGoogleMaps=true;
	}
	</cfscript>
</cffunction>

<!--- application.zcore.functions.zRequireJquery(); --->
<cffunction name="zRequireJquery" localmode="modern" output="no" returntype="any">
    <cfargument name="package" type="string" required="no" default="">
	<cfscript>
	var theMeta="";
	var ts=structnew();
	if(request.zos.globals.enableMinCat EQ 1 and request.zos.inMemberArea EQ false and structkeyexists(request.zos.tempObj,'disableMinCat') EQ false){
		return;
	}
    application.zcore.functions.zForceIncludePackage("zRequireJquery", arguments.package);
	</cfscript>
</cffunction>


<!--- application.zcore.functions.zRequireJqueryCookie(); --->
<cffunction name="zRequireJqueryCookie" localmode="modern" output="no" returntype="any">
    <cfargument name="package" type="string" required="no" default="">
	<cfscript>
	var theMeta="";
	var ts=structnew();
	if(request.zos.globals.enableMinCat EQ 1 and request.zos.inMemberArea EQ false and structkeyexists(request.zos.tempObj,'disableMinCat') EQ false){
		return;
	}
    application.zcore.functions.zForceIncludePackage("zRequireJqueryCookie", arguments.package);
	</cfscript>
    <cfif structkeyexists(request.zos,'JavascriptRequiredJqueryCookie') EQ false>
	<cfsavecontent variable="theMeta"><cfscript>
		ts.type="zRequireJqueryCookie";
		ts.url="/z/javascript/jquery/jquery.cookie.js";
		ts.package=arguments.package;
		ts.forcePosition="";
		arrayappend(request.zos.arrJSIncludes, ts);
	</cfscript></cfsavecontent>
    <cfscript>
    request.zos.JavascriptRequiredJqueryCookie=true;
    </cfscript>
    </cfif>
</cffunction>


<!--- application.zcore.functions.zRequireJqueryMobile(); --->
<cffunction name="zRequireJqueryMobile" localmode="modern" output="no" returntype="any">
	<cfargument name="package" type="string" required="no" default="">
	<cfscript>
	var theMeta="";
	var ts=structnew();
	if(request.zos.globals.enableMinCat EQ 1 and request.zos.inMemberArea EQ false and structkeyexists(request.zos.tempObj,'disableMinCat') EQ false){
		return;
	}
	application.zcore.functions.zForceIncludePackage("zRequireJqueryMobile", arguments.package);
	if(structkeyexists(request.zos,'JavascriptRequiredJqueryMobile') EQ false){
		savecontent variable="theMeta"{
			application.zcore.functions.zRequireJquery();
			ts={};
			ts.type="zRequireJqueryMobile";
			ts.url="/z/javascript/jquery/jquery.mobile-1.3.2/jquery.mobile-1.3.2.min.js";
			ts.package=arguments.package;
			ts.forcePosition="";
			arrayappend(request.zos.arrJSIncludes, ts);
			ts={};
			ts=structnew();
			ts.type="zRequireJqueryMobile";
			ts.url="/z/javascript/jquery/jquery.mobile-1.3.2/jquery.mobile-1.3.2.min.css";
			ts.package=arguments.package;
			ts.forcePosition="";
			arrayappend(request.zos.arrCSSIncludes, ts);
		}
		request.zos.JavascriptRequiredJqueryMobile=true;
	}
	</cfscript>
</cffunction>

<!--- application.zcore.functions.zRequireJqueryUI(); --->
<cffunction name="zRequireJqueryUI" localmode="modern" output="no" returntype="any">
    <cfargument name="package" type="string" required="no" default="">
	<cfscript>
	var theMeta="";
	var ts=structnew();
	if(request.zos.globals.enableMinCat EQ 1 and request.zos.inMemberArea EQ false and structkeyexists(request.zos.tempObj,'disableMinCat') EQ false){
		return;
	}
    application.zcore.functions.zForceIncludePackage("zRequireJqueryUI", arguments.package);
    </cfscript>
    <cfif structkeyexists(request.zos,'JavascriptRequiredJqueryUI') EQ false>
	<cfsavecontent variable="theMeta"><cfscript>
	application.zcore.functions.zRequireJquery();
    </cfscript><cfif request.zos.istestserver><cfscript>
		ts={};
		ts.type="zRequireJqueryUI";
		ts.url="/z/javascript/jquery/jquery-ui/jquery-ui-1.10.3.min.js";
		ts.package=arguments.package;
		ts.forcePosition="";
		arrayappend(request.zos.arrJSIncludes, ts);
		ts=structnew();
		ts.type="zRequireJqueryUI";
		ts.url="/z/javascript/jquery/jquery-ui/jquery-ui-1.10.3.min.css";
		ts.package=arguments.package;
		ts.forcePosition="";
		arrayappend(request.zos.arrCSSIncludes, ts);
		</cfscript>
	<cfelse>
	<cfscript>
		ts.type="zRequireJqueryUI";
		ts.url="/z/javascript/jquery/jquery-ui/jquery-ui-1.10.3.min.js";
		//ts.url="//ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/jquery-ui.min.js";
		ts.package=arguments.package;
		ts.forcePosition="";
		arrayappend(request.zos.arrJSIncludes, ts);
		ts=structnew();
		ts.type="zRequireJqueryUI";
		ts.url="/z/javascript/jquery/jquery-ui/jquery-ui-1.10.3.min.css";
		//ts.url="//ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/themes/base/jquery-ui.css";
		ts.package=arguments.package;
		ts.forcePosition="";
		arrayappend(request.zos.arrCSSIncludes, ts);
        </cfscript></cfif>
</cfsavecontent>
    <cfscript>//application.zcore.template.prependTag("meta",theMeta);
    request.zos.JavascriptRequiredJqueryUI=true;</cfscript>
    </cfif>
</cffunction>


<!--- 
ts={
	type:"Custom",
	errorHTML:'',
	scriptName:'',
	url:'',
	exceptionMessage:'',
	// optional
	lineNumber:''
}
application.zcore.functions.zLogError(ts);
 --->
<cffunction name="zLogError" access="public" localmode="modern">
	<cfargument name="ss" type="struct" required="yes">
	<cfscript>
	db=request.zos.queryObject; 
	log_id=0;
	
	currentMinute=timeformat(now(), "m");
	if(not structkeyexists(application, 'zErrorMinuteTime')){
		application.zErrorMinuteTime=currentMinute;
		application.zErrorMinuteCount=0;
	}
	if(currentMinute NEQ application.zErrorMinuteTime){
		application.zErrorMinuteCount=0;
		application.zErrorMinuteTime=currentMinute;
	}
	application.zErrorMinuteCount++;
	if(not structkeyexists(arguments.ss, 'errorHTML')){
		throw("arguments.ss.errorHTML is required.");
	}
	if(not structkeyexists(arguments.ss, 'type')){
		throw("arguments.ss.type is required.");
	}
	if(not structkeyexists(arguments.ss, 'scriptName')){
		throw("arguments.ss.scriptName is required.");
	}
	if(not structkeyexists(arguments.ss, 'url')){
		throw("arguments.ss.url is required.");
	}
	if(not structkeyexists(arguments.ss, 'lineNumber')){
		arguments.ss.lineNumber=0;
	}
	db.sql="INSERT INTO #db.table("log", request.zos.zcoreDatasource)# SET
        log_host = #db.param(request.zOS.CGI.http_host)#, 
        log_status = #db.param('New')#, 
        log_type = #db.param(arguments.ss.type)#, 
        log_datetime = #db.param(DateFormat(now(), "yyyy-mm-dd")&" "&TimeFormat(now(), "HH:mm:ss"))#,
        log_title = #db.param(arguments.ss.url)#,
        log_ip = #db.param(request.zos.cgi.remote_addr)#, 
        log_message = #db.param(arguments.ss.errorHTML)# , 
	log_user_agent=#db.param(request.zos.cgi.http_user_agent)# ,
	log_script_name=#db.param(arguments.ss.scriptName)#,
	log_line_number=#db.param(arguments.ss.lineNumber)#, 
	log_exception_message=#db.param(arguments.ss.exceptionMessage)#, 
	log_updated_datetime=#db.param(request.zos.mysqlnow)# ";
	rs=db.insert("qInsert");
	
	if(rs.success){
		log_id=rs.result;
	}else{
		throw("Failed to log error");	
	}
	// send email alert
	currentMinute=timeformat(now(), "m");
	if(not structkeyexists(application, 'zErrorMinuteCurrent')){
		application.zErrorMinuteTime=currentMinute;
	}
	if(application.zErrorMinuteTime NEQ currentMinute or not structkeyexists(application, 'zErrorMinuteCount')){
		application.zErrorMinuteCount=0;
		application.zErrorMinuteTime=currentMinute;
	}
	if(application.zErrorMinuteCount LTE request.zos.errorEmailAlertsPerMinute and arguments.ss.type NEQ "javascript-error"){
		ts=StructNew();
		
		ts.to=request.zos.developerEmailTo;
		ts.from=request.zos.developerEmailFrom;
		ts.subject=arguments.ss.type&" on "&request.zos.globals.shortDomain;
		savecontent variable="ts.html"{
			echo('#application.zcore.functions.zHTMLDoctype()#
			<head><title>Error</title>
			</head>
			<body>
			<span class="medium">#arguments.ss.type# on #request.zos.currentHostName#</span><br /><br />
		
			<a href="#request.zos.globals.serverDomain#/z/server-manager/admin/log/index?action=view&log_id=#log_id#">Click here</a> to view detailed information on this error.<br><br>
		
			You will have to login using an account with Server Administrator access.<br /><br />
			User''s IP: #request.zos.cgi.remote_addr# ');
			if(application.zErrorMinuteCount EQ request.zos.errorEmailAlertsPerMinute){
				echo('<br /><br />Error alert limit threshold of #request.zos.errorEmailAlertsPerMinute# alerts per minute was reached.  Further errors are only visible in server manager.');
			}
			echo('</body>
			</html>');
		}
		ts.site_id=request.zos.globals.id;
		rCom=application.zcore.email.send(ts);
		if(not rCom.isOK()){
			savecontent variable="errorHTML"{
				rCom.setStatusErrors(request.zsid);
			}
			throw("Failed to send log error email: "&errorHTML);
		}
	} 
	</cfscript>
</cffunction>


<cffunction name="zIncludeZOSFORMS" localmode="modern" output="yes" returntype="any">
	<!--- <cfargument name="output" type="boolean" required="no" default="#false#"> --->
    <cfargument name="package" type="string" required="no" default="">
	<cfscript>
	var ts=structnew();
	var rs=structnew();
	if(request.zos.globals.enableMinCat EQ 1 and request.zos.inMemberArea EQ false and structkeyexists(request.zos.tempObj,'disableMinCat') EQ false){
		return;
	}
	application.zcore.functions.zRequireJquery(arguments.package);
	
	allowJs=true;
	if(application.zcore.skin.checkCompiledJS()){
		allowJs=false;
	}
	/*var c3="";
	if(request.zos.istestserver){
		c3="-src";	
	}*/
	//c3="-src";	
    application.zcore.functions.zForceIncludePackage("zIncludeZOSFORMS", arguments.package);
    if(structkeyexists(request.zos,"zOSFORMSIncluded") EQ false){
		request.zos.zOSFORMSIncluded=true;
		if(allowJs){
			ts={
				type:"zIncludeZOSFORMS",
				url:"/z/javascript/jquery/balupton-history/scripts/uncompressed/json2.js",
				package:arguments.package,
				forcePosition:""
			}
			arrayappend(request.zos.arrJSIncludes, ts);
			c=arraylen(application.zcore.arrJsFiles);
			for(i=1;i LTE c;i++){
				ts={
					type:"zIncludeZOSFORMS",
					url:application.zcore.arrJsFiles[i],
					package:arguments.package,
					forcePosition:""
				};
				arrayappend(request.zos.arrJSIncludes, ts);
			}
		}
		ts={
			type:"zIncludeZOSFORMS",
			url:"/z/stylesheets/zOS.css",
			package:arguments.package,
			forcePosition:""
		};
		arrayappend(request.zos.arrCSSIncludes, ts);
		
		local.tempFile=request.zos.globals.privatehomedir&"zcache/zsystem.css";
		if(structkeyexists(application.sitestruct[request.zos.globals.id].fileExistsCache, local.tempFile) EQ false){
			application.sitestruct[request.zos.globals.id].fileExistsCache[local.tempFile]=fileexists(local.tempFile);
		}
		if(application.sitestruct[request.zos.globals.id].fileExistsCache[local.tempFile]){
			ts=structnew();
			ts.type="zIncludeZOSFORMS";
			ts.url="/zcache/zsystem.css";
			ts.package=arguments.package;
			ts.forcePosition="";
			arrayappend(request.zos.arrCSSIncludes, ts);
		}
	}
	</cfscript>
</cffunction>


<!--- application.zcore.functions.zRequireSWFObject(); --->
<cffunction name="zRequireSWFObject" localmode="modern" output="no" returntype="any">
    <cfargument name="package" type="string" required="no" default="">
	<cfscript>
	var theMeta="";
	var ts=structnew();
    application.zcore.functions.zForceIncludePackage("zRequireSWFObject", arguments.package);
    </cfscript>
    <cfif structkeyexists(request.zos,'JavascriptRequiredSWFObject') EQ false>
	<cfsavecontent variable="theMeta"><cfif request.zos.istestserver><cfscript>
	ts.type="zRequireSWFObject";
	ts.url="/z/javascript/swfobject.js";
	ts.package=arguments.package;
	ts.forcePosition="";
	arrayappend(request.zos.arrJSIncludes, ts);
    </cfscript>
	<cfelse><cfscript>
	ts.type="zRequireSWFObject";
	ts.url="/z/javascript/swfobject.js";
	ts.package=arguments.package;
	ts.forcePosition="";
	arrayappend(request.zos.arrJSIncludes, ts);
    </cfscript></cfif></cfsavecontent>
    <cfscript>request.zos.JavascriptRequiredSWFObject=true;</cfscript>
    </cfif>
</cffunction>




<cffunction name="zPublishCss" localmode="modern" returntype="any" output="no">
	<cfargument name="ss" type="struct" required="yes">
	<cfscript>
	var contentCount=0;
	var ts=structnew();
	var endTag="";
	var pos=0;
	var pos2=0;
	var newCode="";
	var contents="";
	var newcontents="";
	var rightCount=0;
	ts.uniquephrase="";
	ts.code="";
	ts.site_id=request.zos.globals.id;
	structappend(arguments.ss,ts,false);
	local.tempCSSPath=application.zcore.functions.zGetDomainWritableInstallPath(application.zcore.functions.zvar("shortDomain", arguments.ss.site_id))&"zcache/zsystem.css";
	if(arguments.ss.uniquephrase EQ ""){
		application.zcore.template.fail("arguments.ss.beginphrase and arguments.ss.endphrase are required.");
	}
	if(trim(arguments.ss.code) EQ ""){
		newCode="";
	}else{
		newCode="/* start #arguments.ss.uniquephrase# */"&chr(10)&arguments.ss.code&chr(10)&"/* end #arguments.ss.uniquephrase# */";
	}
	if(fileexists(local.tempCSSPath) EQ false){
		contents="/* THIS FILE IS AUTOMATICALLY GENERATED, DO NOT EDIT */"&chr(10);
	}else{
		contents=application.zcore.functions.zreadfile(local.tempCSSPath);
	} 
	endTag="/* end #arguments.ss.uniquephrase# */";
	pos=find("/* start #arguments.ss.uniquephrase# */", contents);
	pos2=find(endTag, contents);
	if(pos NEQ 0 and pos2 NEQ 0){
		contentCount=len(contents);
		if(pos NEQ 1){
			newcontents=left(contents, pos-1)&newCode;
		}else{
			newcontents=newCode;	
		}
		rightCount=len(contents)-(pos2+len(endTag)-1);
		if(rightCount GT 0){
			newcontents&=right(contents, rightCount);
		}
		contents=newcontents;
	}else{
		contents&=newCode;	
	} 
	local.tempFile=local.tempCSSPath;
	application.zcore.functions.zwritefile(local.tempFile,trim(contents));
	application.sitestruct[request.zos.globals.id].fileExistsCache[local.tempFile]=true;
	if(form[request.zos.urlRoutingParameter] NEQ "/z/server-manager/tasks/publish-system-css/index"){
		if(structkeyexists(application.zcore,'skin')) application.zcore.skin.verifyCache(application.sitestruct[request.zos.globals.id].skinObj);
		if(structkeyexists(application.zcore,'template')) application.zcore.template.findAndReplacePrependTag("meta", "/zcache/zsystem.css?zversion=", "/zcache/zsystem.css?zversion="&gettickcount());
	}
	</cfscript>
</cffunction>

<cffunction name="zIsTestServer" localmode="modern" returntype="boolean" output="no">
	<cfscript>if(request.zos.istestserver){return true;}else{return false;}</cfscript>
</cffunction>

<!--- application.zcore.functions.zEnableNewMetaTags(); --->
<cffunction name="zEnableNewMetaTags" localmode="modern" output="no" returntype="any" hint="Exists for legacy purposes only before stylesheets and scripts template tags were used."> 
</cffunction>





<cffunction name="zEscapeForRegEx" localmode="modern" output="no" returntype="string">
	<cfargument name="a" type="string" required="yes">
    <cfscript>
	var link=arguments.a;
	link=replace(link,"\","\\","ALL");
	link=replace(link,chr(9),"","ALL");
	link=replace(link,chr(10),"","ALL");;
	link=replace(link," ","","all");
	link=replace(link,"?","\?","ALL");
	link=replace(link,".","\.","ALL");
	
	link=replace(link,"(","\(","ALL");
	link=replace(link,")","\)","ALL");
	link=replace(link,"$","\$","ALL");
	link=replace(link,"[","\[","ALL");
	link=replace(link,"]","\]","ALL");
	link=replace(link,"{","\{","ALL");
	link=replace(link,"}","\}","ALL");
	link=replace(link,"*","\*","ALL");
	link=replace(link,"-","\-","ALL");
	link=replace(link,"|","\|","ALL");
	link=replace(link,"^","\^","ALL");
	link=replace(link,"+","\+","ALL");
	return link;
	</cfscript>
</cffunction>



<cffunction name="zReturnRedirect" localmode="modern" output="no" returntype="void" hint="Redirect to the return url in session memory or if it doesn't exist, redirect to the inputURL.">
	<cfargument name="inputURL" type="string" required="yes">
	<cfargument name="appendURL" type="string" required="no" default="">
    <cfscript>
	var zt="";
	if(structkeyexists(request.zsession,'___zr')){
		zt=request.zsession.___zr;
		structdelete(request.zsession,'___zr');
		application.zcore.functions.zRedirect(application.zcore.functions.zURLAppend(zt, arguments.appendURL));
	}else{
		application.zcore.functions.zRedirect(application.zcore.functions.zURLAppend(arguments.inputURL, arguments.appendURL));
	}
	</cfscript>
</cffunction>

<cffunction name="zGetStackTrace" localmode="modern" returntype="struct" output="no">
	<cftry><cfthrow message="fail" type="StackTrace">
    <cfcatch><cfscript>
	var rs=structnew();
	rs.StackTrace=cfcatch.stacktrace;
	rs.TagContext=cfcatch.tagcontext;
	return rs;
	</cfscript></cfcatch></cftry>
</cffunction>

<cffunction name="zVar" localmode="modern" output="false" returntype="string">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="site_id" type="string" required="no" default="#request.zos.globals.id#">
	<cfscript>
	if(structkeyexists(Request.zOS.globals,arguments.name)){
		if(arguments.site_id EQ request.zos.globals.id){
			return Request.zOS.globals[arguments.name];
		}else if(structkeyexists(application.zcore.siteGlobals, arguments.site_id)){
			return application.zcore.siteGlobals[arguments.site_id][arguments.name];
		}else{
			return "";
		}
	}else{
		application.zcore.template.fail("zVar(): variable name, `#arguments.name#`, is not a global variable");
		return "";		
	}
	</cfscript>
</cffunction>

<cffunction name="zGetUniqueNumber" localmode="modern" output="no" returntype="numeric">
	<cfscript>
	if(isDefined('request.zos.tempObj.uniquenumberindex') EQ false){
		request.zos.tempObj.uniquenumberindex=0;
	}
	request.zos.tempObj.uniquenumberindex++;
	return request.zos.tempObj.uniquenumberindex;
	</cfscript>
</cffunction>
 
     
<!--- application.zcore.functions.zGetSiteOptionGroupIdWithNameArray(["GroupName"]); --->
<cffunction name="zGetSiteOptionGroupIdWithNameArray" localmode="modern" output="no" returntype="numeric" hint="returns the group id for the last group in the array.">
	<cfargument name="arrGroupName" type="array" required="no" default="An array of site_option_group_name">
	<cfargument name="site_id" type="string" required="no" default="#request.zos.globals.id#">
	<cfscript>
	t9=application.zcore.siteGlobals[arguments.site_id].soGroupData;
	count=arrayLen(arguments.arrGroupName);
	if(count EQ 0){
		throw("You must specify one or more group names in arguments.arrGroupName");
	}
	curGroupId=0;
	siteOptionGroupId=0;
	for(i=1;i LTE count;i++){
		siteOptionGroupId=t9.siteOptionGroupIdLookup[curGroupId&chr(9)&arguments.arrGroupName[i]];
		curGroupId=siteOptionGroupId;
	}
	return siteOptionGroupId;
	</cfscript>
</cffunction>

<cffunction name="zGetSiteOptionGroupById" localmode="modern" output="yes" returntype="struct">
	<cfargument name="site_option_group_id" type="string" required="no" default="">
	<cfargument name="site_id" type="string" required="no" default="#request.zos.globals.id#">
	<cfscript>
	var t9=application.zcore.siteGlobals[arguments.site_id].soGroupData;
	if(structkeyexists(t9, "siteOptionGroupLookup") and structkeyexists(t9.siteOptionGroupLookup, arguments.site_option_group_id)){
		return t9.siteOptionGroupLookup[arguments.site_option_group_id];
	}
	return {};
	</cfscript>
</cffunction>
     
<cffunction name="zGetSiteOptionGroupSetById" localmode="modern" output="yes" returntype="struct">
	<cfargument name="site_option_group_set_id" type="string" required="yes">
	<cfargument name="site_id" type="string" required="no" default="#request.zos.globals.id#">
	<cfargument name="arrGroupName" type="array" required="no" default="#[]#">
	<cfargument name="showUnapproved" type="boolean" required="no" default="#false#">
	<cfscript> 
	var t9=application.zcore.siteGlobals[arguments.site_id].soGroupData;
	if(arraylen(arguments.arrGroupName)){
		var groupId=application.zcore.functions.zGetSiteOptionGroupIdWithNameArray(arguments.arrGroupName, arguments.site_id);
		var groupStruct=t9.siteOptionGroupLookup[groupId]; 
		if(not arguments.showUnapproved and groupStruct.site_option_group_enable_cache EQ 1 and structkeyexists(t9.siteOptionGroupSet, arguments.site_option_group_set_id)){
			groupStruct=t9.siteOptionGroupSet[arguments.site_option_group_set_id];
			application.zcore.functions.zAppendSiteOptionGroupDefaults(groupStruct, groupStruct.__groupId);
			return groupStruct;
		}else{ 
			return application.zcore.siteOptionCom.siteOptionGroupSetFromDatabaseBySetId(arguments.site_option_group_set_id, arguments.site_id, arguments.showUnapproved);
			//throw("zGetSiteOptionGroupSetById with cache disabled is not implemented");
		}
	}else{
		if(structkeyexists(t9, "siteOptionGroupSet") and structkeyexists(t9.siteOptionGroupSet, arguments.site_option_group_set_id)){
			var groupStruct=t9.siteOptionGroupSet[arguments.site_option_group_set_id];
			application.zcore.functions.zAppendSiteOptionGroupDefaults(groupStruct, groupStruct.__groupId);
			return groupStruct;
		}
	} 
	return {};
	</cfscript>
</cffunction>

<cffunction name="zSiteOptionGroupIdByName" localmode="modern" output="no" returntype="numeric">
	<cfargument name="groupName" type="string" required="yes">
	<cfargument name="site_option_group_parent_id" type="numeric" required="no" default="#0#">
	<cfargument name="site_id" type="numeric" required="no" default="#request.zos.globals.id#">
	<cfscript>
	var t9=application.zcore.siteGlobals[arguments.site_id].soGroupData;
	if(structkeyexists(t9, "siteOptionGroupIdLookup") and structkeyexists(t9.siteOptionGroupIdLookup, arguments.site_option_group_parent_id&chr(9)&arguments.groupName)){
		return t9.siteOptionGroupIdLookup[arguments.site_option_group_parent_id&chr(9)&arguments.groupName];
	}else{
		throw("arguments.groupName, ""#arguments.groupName#"", doesn't exist");
	}
	</cfscript>
</cffunction>

<cffunction name="zSiteOptionGroupStruct" localmode="modern" output="yes" returntype="array">
	<cfargument name="groupName" type="string" required="yes">
	<cfargument name="site_option_app_id" type="string" required="no" default="0">
	<cfargument name="site_id" type="string" required="no" default="#request.zos.globals.id#">
	<cfargument name="parentStruct" type="struct" required="no" default="#{__groupId=0,__setId=0}#">
	<cfscript> 
	var t9=application.zcore.siteGlobals[arguments.site_id].soGroupData;
	var siteOptionGroupId=0;
	var i=0;
	var arrGroup=0;
	if(structkeyexists(t9, "siteOptionGroupIdLookup") and structkeyexists(t9.siteOptionGroupIdLookup, arguments.parentStruct.__groupId&chr(9)&arguments.groupName)){
		siteOptionGroupId=t9.siteOptionGroupIdLookup[arguments.parentStruct.__groupId&chr(9)&arguments.groupName];
		
		var groupStruct=t9.siteOptionGroupLookup[siteOptionGroupId];
		if(groupStruct.site_option_group_enable_cache EQ 1){
			if(structkeyexists(t9.siteOptionGroupSetArrays, arguments.site_option_app_id&chr(9)&siteOptionGroupId&chr(9)&arguments.parentStruct.__setId)){
				arrGroup=t9.siteOptionGroupSetArrays[arguments.site_option_app_id&chr(9)&siteOptionGroupId&chr(9)&arguments.parentStruct.__setId];
				for(i=1;i LTE arraylen(arrGroup);i++){
					application.zcore.functions.zAppendSiteOptionGroupDefaults(arrGroup[i], siteOptionGroupId);
				}
				return arrGroup;
			}
		}else{
			return application.zcore.siteOptionCom.siteOptionGroupSetFromDatabaseByGroupId(siteOptionGroupId, arguments.site_option_app_id, arguments.site_id, arguments.parentStruct);
			//throw("zSiteOptionGroupStruct with cache disabled is not implemented");
		}
	} 
	return arraynew(1);
	</cfscript>
</cffunction> 


<cffunction name="zVarSO" localmode="modern" output="false" returntype="string">
	<cfargument name="name" type="string" required="yes">
	<cfargument name="site_id" type="string" required="no" default="">
	<cfargument name="disableEditing" type="boolean" required="no" default="#false#">
	<cfargument name="site_option_app_id" type="string" required="no" default="0">
     <cfscript>
	 var start="";
	 var end="";
	 if(arguments.site_id EQ "" and structkeyexists(request.zos, 'globals') and structkeyexists(request.zos.globals, 'id')){
	 	arguments.site_id=request.zos.globals.id;
	 }
	 var contentConfig=structnew();
	 if(application.zcore.app.siteHasApp("content")){
		 contentConfig=application.zcore.app.getAppCFC("content").getContentIncludeConfig();
	 }else{
		 contentConfig.contentEmailFormat=false;
	 }
	 if(arguments.name EQ 'Visitor Tracking Code' and (structkeyexists(request.zos.userSession.groupAccess, "member") or request.zos.istestserver)){
		 return '<script type="text/javascript">var zVisitorTrackingDisabled=true; </script>';
	 }
	 if(isDefined('request.zos.tempObj.zVarSOIndex') EQ false){
		request.zos.tempObj.zVarSOIndex=0;
		
	 }
	 request.zos.tempObj.zVarSOIndex++;
	if(arguments.disableEditing EQ false and structkeyexists(application.zcore,'user') and structkeyexists(request.zos.userSession, 'groupAccess') and (structkeyexists(request.zos.userSession.groupAccess, "administrator")) and contentConfig.contentEmailFormat EQ false){
		request.zos.tempObj.zVarSOIndex++;
		start='<div style="display:inline;" id="zcidspan#request.zos.tempObj.zVarSOIndex#" class="zOverEdit" data-editurl="/z/admin/site-options/index?return=1&amp;jumpto=soid_#application.zcore.functions.zURLEncode(arguments.name,"_")#">';
		end='</div>';
	}
	if(arguments.site_option_app_id EQ 0){
		if(structkeyexists(Request.zOS.globals,"site_options") and structkeyexists(Request.zOS.globals.site_options,arguments.name)){
			if(Request.zOS.globals.site_option_edit_enabled[arguments.name] EQ 0){
				start="";
				end="";
			}
			if(arguments.site_id EQ request.zos.globals.id){
				return start&Request.zOS.globals.site_options[arguments.name]&end;
			}else{
				return start&application.siteStruct[arguments.site_id].globals.site_options[arguments.name]&end;
			}
		}else{
			//application.zcore.template.fail("zVarSO: `#arguments.name#`, is not a site option.");
			return "";//Site Option Missing: #arguments.name#";		
		}
	}else{
		if(structkeyexists(Request.zOS.globals,"site_option_app") and structkeyexists(Request.zOS.globals.site_option_app, arguments.site_option_app_id) and structkeyexists(Request.zOS.globals.site_option_app[arguments.site_option_app_id],arguments.name)){
			if(Request.zOS.globals.site_option_edit_enabled[arguments.name] EQ 0){
				start="";
				end="";
			}
			if(arguments.site_id EQ request.zos.globals.id){
				return start&Request.zOS.globals.site_option_app[arguments.site_option_app_id][arguments.name]&end;
			}else{
				return start&application.siteStruct[arguments.site_id].globals.site_option_app[arguments.site_option_app_id][arguments.name]&end;
			}
		}else{
			//application.zcore.template.fail("zVarSO: `#arguments.name#`, is not a site option.");
			return "";//Site Option Missing: #arguments.name#";		
		}
	}
	</cfscript>
</cffunction>






<!--- zFilterURL(filterList); --->
<cffunction name="zFilterURL" localmode="modern" output="false" returntype="any">
	<cfargument name="filterList" type="string" required="yes">
	<cfscript>
	var i=0;
	var theURL = request.cgi_script_name;
	var arrTemp = ArrayNew(1);
	for(i in url){
		if(listFindNoCase(arguments.filterList, i) EQ false and isSimpleValue(url[i])){
			ArrayAppend(arrTemp, i&'='&URLEncodedFormat(url[i]));
		}
	}
	if(ArrayLen(arrTemp) NEQ 0){
		return theURL&"?"&ArrayToList(arrTemp, '&');
	}else{
		return theURL;
	}
	</cfscript>
</cffunction>
<cffunction name="zError" localmode="modern" output="false" returntype="any">
	<cfargument name="message" type="string" required="no">
	<cfargument name="silent" type="boolean" required="no" default="#false#">
	<cfscript>
	var ts=0;
	var log_id=0;
	var zErrorTempURL="";
	</cfscript>
	<cfif arguments.silent>
	<cfsavecontent variable="zErrorTempURL"><cfif request.zos.cgi.SERVER_PORT NEQ "443">http://<cfelse>https://</cfif>#request.zos.cgi.http_host##request.cgi_script_name#<cfif request.zos.CGI.QUERY_STRING NEQ "">?#request.zos.CGI.QUERY_STRING#</cfif></cfsavecontent>
	<cfscript>
	ts=StructNew();
	ts.table="log";
	ts.datasource="#request.zos.zcoreDatasource#";   
	ts.struct.log_host=request.zos.cgi.http_host;   
	ts.struct.log_title=zErrorTempURL;
	ts.struct.log_message=arguments.message;
	ts.struct.log_ip=request.zos.cgi.remote_addr;
	ts.struct.log_datetime=request.zos.mysqlnow;
	ts.struct.log_status='New';
	ts.struct.log_priority='0';
	if(isdefined('request.zsession.user.id')){
		ts.struct.user_id = request.zsession.user.id;
	}
	ts.struct.log_type='error';
	ts.struct.site_id=request.zos.globals.id;
	log_id=application.zcore.functions.zInsert(ts);
	</cfscript>
<cfmail  from="#request.zos.developerEmailFrom#" to="#request.zos.developerEmailTo#" type="html" subject="#request.zos.cgi.http_host# has an error">
#application.zcore.functions.zHTMLDoctype()#
<body>
Error on #request.zos.cgi.http_host#<br />
<br />
<a href="#request.zos.globals.serverdomain#/server-manager/admin/log/index?action=view&log_id=#log_id#">Click here to view detailed information on this error.</a>
<br />
<br />
You will have to login using your Server Administrator password.
<br />
<br />
User's IP: #request.zos.cgi.remote_addr#
</body></html>
</cfmail>
	<cfelse>
		<cfthrow type="exception" message="#arguments.message#">
	</cfif>
</cffunction>

<cffunction name="zCGI" localmode="modern" output="false" returntype="any">
	<cfargument name="name" type="string" required="no">
	<cfscript>
		return request.zOS.CGI[arguments.name];
	/*try{
	}catch(Any excpt){ }
	try{
	// replace with my own struct when ready.
		return CGI[arguments.name];
	}catch(Any excpt){
		application.zcore.functions.zError(arguments.name&' is not a valid CGI variable.');
	}*/
	</cfscript>
</cffunction>

<!--- FUNCTION: application.zcore.functions.zGetRepostStruct(); --->
<cffunction name="zGetRepostStruct" localmode="modern" returntype="struct" output="yes">	
	<cfscript>
	var arrURL = ArrayNew(1);
	var urlString = "";
	var formString = "";
	var arrForm = ArrayNew(1);
	var returnStruct = StructNew();
	var i = 0;
	var repostVarsIgnoreStruct=application.zcore.repostVarsIgnoreStruct;
	/*if(structkeyexists(form, 'method')){
		structdelete(form,'method');	
	}*/
	for(i in FORM){
		if(structkeyexists(repostVarsIgnoreStruct, i) EQ false and isSimpleValue(form[i])){
			formString = formString&'<input type="hidden" name="'&i&'" value="'&htmlEditFormat(FORM[i])&'" />'&chr(10);
			arrayappend(arrForm, i&"="&urlencodedformat(FORM[i]));
		}
	}
	for(i in URL){
		if(structkeyexists(form, i) EQ false and structkeyexists(repostVarsIgnoreStruct, i) EQ false and isSimpleValue(url[i])){
			ArrayAppend(arrURL,i&'='&URLEncodedFormat(URL[i]));
		}
	}
	urlString = ArrayToList(arrURL,"&");
	returnStruct.urlString = urlString;
	returnStruct.formString = formString;
	returnStruct.cgiFormString=arrayToList(arrForm, '&');
	return returnStruct;
	</cfscript>
</cffunction>

<cffunction name="zCheckDebugIP" localmode="modern" output="false" returntype="boolean">
	<cfscript>
	if(structkeyexists(request.zos.adminIpStruct,request.zos.cgi.remote_addr) and request.zos.adminIpStruct[request.zos.cgi.remote_addr] EQ false){
		return true;
	}else{
		return false;
	}
	</cfscript>
</cffunction>
<cffunction name="zIsServer" localmode="modern" output="false" returntype="boolean">
	<cfscript>
	if((request.zos.cgi.remote_addr EQ '127.0.0.1' and (cgi.HTTP_USER_AGENT contains 'railo' or cgi.HTTP_USER_AGENT EQ 'cfschedule' or cgi.HTTP_USER_AGENT EQ 'Coldfusion')) or
	 structkeyexists(request.zos.adminIpStruct,request.zos.cgi.remote_addr) and request.zos.adminIpStruct[request.zos.cgi.remote_addr]){
		return true;
	}else{
		return false;
	}
	</cfscript>
</cffunction>


<cffunction name="zDump" localmode="modern" output="true" returntype="any">
	<cfargument name="varName" type="any" required="yes">
	<cfargument name="label" type="string" required="no" default="">
	<cfargument name="nodumpcode" type="boolean" required="no" default="#false#">
	<cfdump var="#arguments.varName#" showudfs="no" format="html" label="#arguments.label#">
	<style type="text/css"> 
	div.-railo-dump  td span {font-weight:bold !important;}
	div.-railo-dump table{ background-color:##FFF !important;font-family:Arial, Helvetica, sans-serif  !important; font-size:12px !important; empty-cells:show !important; color:##000 !important;border-spacing:0px !important;color:##000 !important;  border:none !important;}
	div.-railo-dump td.r99f {background-color:##FFF !important; border-right:1px solid ##CCC !important; border-bottom:1px solid ##CCC !important; padding:3px !important;}
	div.-railo-dump td.rc9c {background-color:##FFF !important; border-right:1px solid ##CCC !important; border-bottom:1px solid ##CCC !important; padding:3px !important;} 
	div.-railo-dump td.r99f:nth-child(even) {background-color:##F2F2F2 !important;  }
	div.-railo-dump td.rc9c:nth-child(even) {background-color:##F2F2F2 !important;  }
	div.-railo-dump td {background-color:transparent !important; padding:3px !important; border:none !important; border-right:1px solid ##CCC !important;border-bottom:1px solid ##CCC !important;}
	div.-railo-dump tr:nth-child(even) {background: ##F2F2F2  !important;}
	div.-railo-dump tr tr:nth-child(even) {background: ##F2F2F2  !important;}
	div.-railo-dump tr:hover{ background-color:##e6faeb !important;} 
	</style>
</cffunction>



<cffunction name="zCheckAccess" localmode="modern" returntype="any" output="false">
	<cfargument name="struct" type="struct" required="yes">
	<cfargument name="permission" type="string" required="yes">
	<cfargument name="role" type="string" required="yes">
	<cfscript>
	try{
		if(arguments.permission EQ "read"){
			if(arguments.role EQ "owner"){
				if(arguments.struct.access_owner_read){
				return true;
				}else{
					return false;
				}
			}else if(arguments.role EQ "group"){
				if(arguments.struct.access_group_read){
				return true;
				}else{
					return false;
				}
			}else if(arguments.role EQ "public"){
				if(arguments.struct.access_public_read){
				return true;
				}else{
					return false;
				}
			}else{
				application.zcore.template.fail("The role you specified, `"&arguments.role&"`, must be owner, group or public.",true);
			}
		}else if(arguments.permission EQ "write"){
			if(arguments.role EQ "owner"){
				if(arguments.struct.access_owner_write){
				return true;
				}else{
					return false;
				}
			}else if(arguments.role EQ "group"){
				if(arguments.struct.access_group_write){
				return true;
				}else{
					return false;
				}
			}else if(arguments.role EQ "public"){
				if(arguments.struct.access_public_write){
				return true;
				}else{
					return false;
				}
			}else{
				application.zcore.template.fail("The role you specified, `"&arguments.role&"`, must be owner, group or public.",true);
			}
		
		}else if(arguments.permission EQ "delete"){
			if(arguments.role EQ "owner"){
				if(arguments.struct.access_owner_delete){
				return true;
				}else{
					return false;
				}
			}else if(arguments.role EQ "group"){
				if(arguments.struct.access_group_delete){
				return true;
				}else{
					return false;
				}
			}else if(arguments.role EQ "public"){
				if(arguments.struct.access_public_delete){
				return true;
				}else{
					return false;
				}
			}else{
				application.zcore.template.fail("The role you specified, `"&arguments.role&"`, must be owner, group or public.",true);
			}
		
		}else{
			application.zcore.template.fail("Error: FUNCTION: zCheckAccess: The permission you specified, `"&arguments.permission&"`, must be read, write or delete.",true);
		}
	}catch(Any excpt){
		//application.zcore.template.fail("Error: FUNCTION: zOS_accessToString: access must be a valid access struct containing access_owner/group/public_read/write/delete variables.",true);  
	}
	// don't care if its not defined anymore
		return false;
	</cfscript>
</cffunction>

<!--- FUNCTION: zOS_getAccessFromPost(struct, fieldName); --->
<cffunction name="zOS_getAccessFromPost" localmode="modern" returntype="any" output="true">
	<cfargument name="struct" type="struct" required="yes">
	<cfargument name="fieldName" type="string" required="yes">
	<cfscript>
	var tempStruct = StructNew();
	tempStruct.access_owner_read = false;
	tempStruct.access_owner_write = false;
	tempStruct.access_owner_delete = false;
	tempStruct.access_group_read = false;
	tempStruct.access_group_write = false;
	tempStruct.access_group_delete = false;
	tempStruct.access_public_read = false;
	tempStruct.access_public_write = false;
	tempStruct.access_public_delete = false;
	if(isDefined('arguments.struct.#arguments.fieldName#_owner_read')){
		tempStruct.access_owner_read = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_owner_write')){
		tempStruct.access_owner_write = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_owner_delete')){
		tempStruct.access_owner_delete = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_group_read')){
		tempStruct.access_group_read = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_group_write')){
		tempStruct.access_group_write = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_group_delete')){
		tempStruct.access_group_delete = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_public_read')){
		tempStruct.access_public_read = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_public_write')){
		tempStruct.access_public_write = true;
	}
	if(isDefined('arguments.struct.#arguments.fieldName#_public_delete')){
		tempStruct.access_public_delete = true;
	}
	return tempStruct;
	</cfscript>
</cffunction>

<!--- FUNCTION: zOS_accessToString(access); --->
<cffunction name="zOS_accessToString" localmode="modern" returntype="string" output="false">
	<cfargument name="struct" type="struct" required="yes">
	<cfscript>
	var chmod=0;
	try{
		if(arguments.struct.access_owner_read)chmod=chmod+400;
		if(arguments.struct.access_owner_write)chmod=chmod+200;
		if(arguments.struct.access_owner_delete)chmod=chmod+100;
		if(arguments.struct.access_group_read)chmod=chmod+40;
		if(arguments.struct.access_group_write)chmod=chmod+20;
		if(arguments.struct.access_group_delete)chmod=chmod+10;
		if(arguments.struct.access_public_read)chmod=chmod+4;
		if(arguments.struct.access_public_write)chmod=chmod+2;
		if(arguments.struct.access_public_delete)chmod=chmod+1;
	}catch(Any excpt){
		application.zcore.template.fail("Error: FUNCTION: zOS_accessToString: access must be a valid access struct containing access_owner/group/public_read/write/delete variables.",true);
	}
	return chmod;
	</cfscript>
</cffunction>







<cffunction name="zOS_recurseSiteDir" localmode="modern" output="true" returntype="any">
	<cfargument name="dirPath" type="string" required="yes">
	<cfargument name="dirPathRoot" type="string" required="yes">
	<cfargument name="siteRoot" type="string" required="no">
	<cfargument name="debug" type="boolean" required="no" default="#false#">
	<cfargument name="level" type="numeric" required="no" default="#1#">
	<cfargument name="cfonly" type="boolean" required="no" default="#true#">
	<cfargument name="sortString" type="string" required="no" default="">
	<cfargument name="noimages" type="boolean" required="no" default="#false#">
	<cfscript>
	var n=0;
	var qDir = "";
	var i = 0;
	var arrDir = ArrayNew(1);
	var addStruct = StructNew();
	var arrTemp = ArrayNew(1);
	var returnStruct = StructNew();
	if(isDefined('arguments.siteRoot') EQ false){
		arguments.siteRoot = arguments.dirPathRoot;
	}
	</cfscript>
	<cfif arguments.sortString NEQ ''>
	<cfdirectory action="list" directory="#arguments.dirPath#" name="qDir" sort="#arguments.sortString#">
	<cfelse>
	<cfdirectory action="list" directory="#arguments.dirPath#" name="qDir" sort="#arguments.sortString#">
	</cfif>
	<cfscript> 
	for(i=1;i LTE qDir.recordcount;i=i+1){
		if(qDir["type"][i] EQ "dir"){// and (arguments.cfonly EQ false or left(qDir["name"][i],1) NEQ '_')){
			if(qDir["name"][i] NEQ ".svn"){
				if(arguments.noimages EQ false or qDir["name"][i] NEQ 'images'){
					if(arguments.debug){
						writeoutput(replace(ljustify(" ", arguments.level*4), " ", "&nbsp;","ALL")&qDir["name"][i]);
						writeoutput("/<br />");
					}
					addStruct = StructNew();
					addStruct.name = qDir["name"][i];
					addStruct.parent = removeChars(arguments.dirPathRoot, 1, len(arguments.siteRoot)-1);
					addStruct.parent = removeChars(addStruct.parent, len(addStruct.parent), 1);
					addStruct.coldfusionRoot = arguments.dirPathRoot&qDir["name"][i]&"/";
					addStruct.siteRoot = addStruct.parent&"/"&qDir["name"][i];
					addStruct.dateLastModified=qDir.dateLastModified[i];
					addStruct.size=qDir.size[i];
					if(addStruct.parent EQ ""){
						addStruct.parent = "/";
					}
					addStruct.path = arguments.dirPath&qDir["name"][i]&"/";
					addStruct.dir = true;
					arrayAppend(arrDir, addStruct);
					// recurse dir
					arrTemp = application.zcore.functions.zOS_recurseSiteDir(addStruct.path, addStruct.coldfusionRoot, arguments.siteRoot, arguments.debug, arguments.level+1,arguments.cfonly, arguments.sortString, arguments.noimages);
					// copy recursed array to current array.
					for(n=1;n LTE arrayLen(arrTemp);n=n+1){
						arrayAppend(arrDir, arrTemp[n]);
					}
					if(arguments.debug){
						writeoutput("<br />");
					}
				}
			}
		}else if(qDir["type"][i] EQ "file"){
			if(arguments.cfonly EQ false or ((right(qDir["name"][i],3) EQ "cfm" or right(qDir["name"][i],3) EQ "cfc") and left(qDir["name"][i],1) NEQ '_' and qDir["name"][i] NEQ 'Application.cfm' and qDir["name"][i] NEQ 'onRequestEnd.cfm')){
				if(arguments.debug){
					writeoutput(replace(ljustify(" ", arguments.level*4), " ", "&nbsp;","ALL")&qDir["name"][i]);
					writeoutput("<br />");
				}
				// ignore the current script
				if(replace(CGI.PATH_TRANSLATED,"\","/","ALL") NEQ arguments.dirPath&qDir["name"][i]){
					addStruct = StructNew();
					addStruct.name = qDir["name"][i];
					addStruct.dateLastModified=qDir.dateLastModified[i];
					addStruct.size=qDir.size[i];
					addStruct.parent = removeChars(arguments.dirPathRoot, 1, len(arguments.siteRoot)-1);
					addStruct.parent = removeChars(addStruct.parent, len(addStruct.parent), 1);
					addStruct.coldfusionRoot = arguments.dirPathRoot&qDir["name"][i];
					addStruct.siteRoot = addStruct.parent&"/"&qDir["name"][i];					if(addStruct.parent EQ ""){
						addStruct.parent = "/";
					}

					addStruct.path = arguments.dirPath&qDir["name"][i];
					addStruct.dir = false;
					arrayAppend(arrDir, addStruct);
				}
			}
		}
	}
	return arrDir;
	</cfscript>
</cffunction>

<!---  application.zcore.functions.zAppendSiteOptionGroupDefaults(dataStruct, site_option_group_id); --->
<cffunction name="zAppendSiteOptionGroupDefaults" localmode="modern" output="false" returntype="any">
	<cfargument name="dataStruct" type="struct" required="yes">
	<cfargument name="site_option_group_id" type="string" required="yes">
	<cfscript> 
	if(structkeyexists(request.zos.globals.soGroupData, 'siteOptionGroupDefaults') and structkeyexists(request.zos.globals.soGroupData.siteOptionGroupDefaults, arguments.site_option_group_id)){
		structappend(arguments.dataStruct, request.zos.globals.soGroupData.siteOptionGroupDefaults[arguments.site_option_group_id], false);
	}
	return arguments.dataStruct;
	</cfscript>
</cffunction>

<!--- re-create the site globals and user group cache --->
<cffunction name="zOS_cacheSiteAndUserGroups" localmode="modern" output="false" returntype="any">
	<cfargument name="site_id" type="string" required="yes">
    <cfscript>
	var tempStruct='';
	var curSetNumber='';
	var curSetNumber1='';
	var local=structnew();
	var qSite=0;
	var qgroup=0;
	var qgroupx=0;
	var output="";
	var i=0;
	var qs=0;
	var result=0;
	var tempUniqueStruct=0;
	var id=0;
	var nk=0;
	var t9=0;
	var ts=0;
	var lastGroup="";
	var rgb=0;
	var qs2=0;
	var row=0;
	var firstTempStruct=structnew();
	var varName="";
	var pos="";
	var db=request.zos.queryObject;
	tempStruct=0;
	db.sql="SELECT * FROM #db.table("site", request.zos.zcoreDatasource)# site 
	WHERE site_id = #db.param(arguments.site_id)# and 
	site_deleted = #db.param(0)#";
	qSite=db.execute("qSite");
	local.tempPath=application.zcore.functions.zGetDomainInstallPath(qSite.site_short_domain);
	if(directoryExists(local.tempPath) EQ false){
		if(qSite.site_active EQ 1){
			application.zcore.template.fail("Site home directory is missing: "&local.tempPath);
		}else{
			return;
		}
	}
	// re-cache the site paths, this function is defined at top of page
	tempStruct = StructNew();
	application.zcore.functions.zQueryToStruct(qSite, tempStruct);
	if(tempStruct.site_siteroot NEQ ''){
		tempStruct.cfcSiteRoot = replace(removeChars(tempStruct.site_siteroot,1,1),'/','.','ALL')&'.';
	}else{
		tempStruct.cfcSiteRoot='';
	}
	//output = application.zcore.functions.zStructToString("Request.zOS.globals", tempStruct, true);
	for(i in tempStruct){
		if(left(i, 5) EQ "site_"){
			varName=mid(i, 5, len(i)-4);
		}else{
			varName=i;
		}
		varName = replace(varName, '_','','ALL');
		firstTempStruct[varName]=tempStruct[i];
	}
	tempStruct=firstTempStruct; 
	db.sql="SELECT * FROM #db.table("user_group", request.zos.zcoreDatasource)# user_group 
	WHERE site_id = #db.param(arguments.site_id)# and 
	user_group_deleted = #db.param(0)#";
	qGroup=db.execute("qGroup");
	db.sql="SELECT * FROM #db.table("user_group_x_group", request.zos.zcoreDatasource)# user_group_x_group, 
	#db.table("user_group", request.zos.zcoreDatasource)# user_group 
	WHERE 
	user_group_deleted = #db.param(0)# and 
	user_group_x_group_deleted = #db.param(0)# and 
	user_group_x_group.user_group_child_id = user_group.user_group_id and 
	user_group_x_group.site_id = #db.param(arguments.site_id)# and 
	user_group_x_group.site_id = user_group.site_id";
	qGroupX=db.execute("qGroupX");
	//tempStruct = StructNew();
	tempStruct.user_group.ids = StructNew();
	tempStruct.user_group.names = StructNew();
	tempStruct.user_group.access = StructNew();
	tempStruct.user_group.modify_user = StructNew();
	tempStruct.user_group.share_user = StructNew();
	for(i=1;i LTE qGroup.recordcount;i=i+1){
		if(qGroup["user_group_primary"][i] EQ 1){
			tempStruct.user_group.primary = qGroup["user_group_id"][i];
		}
		StructInsert(tempStruct.user_group.names, qGroup["user_group_name"][i], qGroup["user_group_id"][i],true);
		StructInsert(tempStruct.user_group.ids, qGroup["user_group_id"][i], qGroup["user_group_name"][i],true);
		// create the login access struct for each group
		StructInsert(tempStruct.user_group.access, qGroup["user_group_id"][i], StructNew(), false);
		StructInsert(tempStruct.user_group.modify_user, qGroup["user_group_id"][i], StructNew(), false);
		StructInsert(tempStruct.user_group.share_user, qGroup["user_group_id"][i], StructNew(), false);
		// force the parent group to have access to itself
		StructInsert(tempStruct.user_group.access[qGroup["user_group_id"][i]], qGroup["user_group_name"][i], qGroup["user_group_id"][i], true);
	}
	for(i=1;i LTE qGroupX.recordcount;i=i+1){
		// add the child user groups to each access struct
		if(qGroupX.user_group_modify_user[i] EQ 1){
			StructInsert(tempStruct.user_group.modify_user[qGroupX["user_group_id"][i]], qGroupX["user_group_name"][i], qGroupX["user_group_child_id"][i], true);		
		}
		if(qGroupX.user_group_login_access[i] EQ 1){
			StructInsert(tempStruct.user_group.access[qGroupX["user_group_id"][i]], qGroupX["user_group_name"][i], qGroupX["user_group_child_id"][i], true);
		}
		if(qGroupX.user_group_share_user[i] EQ 1){
			StructInsert(tempStruct.user_group.share_user[qGroupX["user_group_id"][i]], qGroupX["user_group_name"][i], qGroupX["user_group_child_id"][i], true);
		}
	}
	
	tempStruct.soGroupData={
		siteOptionLookup=structnew(),
		siteOptionIdLookup=structnew(),
		siteOptionGroupFieldLookup=structnew(),
		siteOptionGroupLookup=structnew(),
		siteOptionGroupIdLookup=structnew(),
		siteOptionGroupSetId=structnew(),
		siteOptionGroupSet=structnew(),
		siteOptionGroupSetArrays=structnew(),
		siteOptionGroupDefaults=structnew()
	};
	
	 db.sql="SELECT * FROM #db.table("site_option", request.zos.zcoreDatasource)# site_option 
	WHERE site_option_group_id<> #db.param(0)# and  
	site_option_deleted = #db.param(0)# and 
	site_id = #db.param(arguments.site_id)#";
	qS=db.execute("qS");
	for(row in qS){
		tempStruct.soGroupData.siteOptionLookup[row.site_option_id]=row;
		structappend(tempStruct.soGroupData.siteOptionLookup[row.site_option_id], {
			edit:row.site_option_edit_enabled,
			name:row.site_option_name,
			type:row.site_option_type_id,
			optionStruct:{}
		});
		tempStruct.soGroupData.siteOptionLookup[row.site_option_id].optionStruct=deserializeJson(row.site_option_type_json);
		if(not structkeyexists(tempStruct.soGroupData.siteOptionGroupDefaults, row.site_option_group_id)){
			tempStruct.soGroupData.siteOptionGroupDefaults[row.site_option_group_id]={};
		}
		tempStruct.soGroupData.siteOptionGroupDefaults[row.site_option_group_id][row.site_option_name]=row.site_option_default_value;
		tempStruct.soGroupData.siteOptionIdLookup[row.site_option_group_id&chr(9)&row.site_option_name]=row.site_option_id;
		if(row.site_option_group_id NEQ 0){
			if(structkeyexists(tempStruct.soGroupData.siteOptionGroupFieldLookup, row.site_option_group_id) EQ false){
				tempStruct.soGroupData.siteOptionGroupFieldLookup[row.site_option_group_id]=structnew();
			}
			tempStruct.soGroupData.siteOptionGroupFieldLookup[row.site_option_group_id][row.site_option_id]=true;
		}
	}
	db.sql="SELECT * FROM #db.table("site_option_group", request.zos.zcoreDatasource)# site_option_group 
	WHERE site_id =#db.param(arguments.site_id)# and 
	site_option_group_deleted = #db.param(0)# 
	ORDER BY site_option_group_parent_id asc";
	qS=db.execute("qS"); 
	
	var arrGroupCacheEnabled=[];
	for(row in qS){
		row.count=0;
		tempStruct.soGroupData.siteOptionGroupLookup[row.site_option_group_id]=row;
		if(row.site_option_group_enable_cache EQ 1){
			arrayAppend(arrGroupCacheEnabled, row.site_option_group_id); 
		}
		tempStruct.soGroupData.siteOptionGroupIdLookup[row.site_option_group_parent_id&chr(9)&row.site_option_group_name]=row.site_option_group_id;
	}
	var cacheEnableGroupIdList="'"&arrayToList(arrGroupCacheEnabled, "','")&"'";
	
	db.sql="SELECT s1.* 
	FROM #db.table("site_x_option_group_set", request.zos.zcoreDatasource)# s1   
	WHERE s1.site_id = #db.param(arguments.site_id)#  and 
	s1.site_x_option_group_set_deleted = #db.param(0)# and 
	s1.site_option_group_id IN (#db.trustedSQL(cacheEnableGroupIdList)#) 
	ORDER BY s1.site_x_option_group_set_parent_id ASC, s1.site_x_option_group_set_sort ASC "; 
	qS=db.execute("qS"); 
	tempUniqueStruct=structnew();
	
	tempStruct.soGroupData.siteOptionGroupSetId[0&"_groupId"]=0;
	tempStruct.soGroupData.siteOptionGroupSetId[0&"_parentId"]=0;
	tempStruct.soGroupData.siteOptionGroupSetId[0&"_appId"]=0;
	tempStruct.soGroupData.siteOptionGroupSetId[0&"_childGroup"]=structnew();
	for(row in qS){
		id=row.site_x_option_group_set_id;
		if(structkeyexists(tempStruct.soGroupData.siteOptionGroupSetId, id) EQ false){
			if(structkeyexists(tempStruct.soGroupData.siteOptionGroupSetId, id&"_appId") EQ false){
				tempStruct.soGroupData.siteOptionGroupLookup[row.site_option_group_id].count++;
				tempStruct.soGroupData.siteOptionGroupSetId[id&"_groupId"]=row.site_option_group_id;
				tempStruct.soGroupData.siteOptionGroupSetId[id&"_appId"]=row.site_option_app_id;
				tempStruct.soGroupData.siteOptionGroupSetId[id&"_parentId"]=row.site_x_option_group_set_parent_id;
				tempStruct.soGroupData.siteOptionGroupSetId[id&"_childGroup"]=structnew();
			}
			if(structkeyexists(tempStruct.soGroupData.siteOptionGroupSetId, row.site_x_option_group_set_parent_id&"_childGroup")){
				if(structkeyexists(tempStruct.soGroupData.siteOptionGroupSetId[row.site_x_option_group_set_parent_id&"_childGroup"], row.site_option_group_id) EQ false){
					tempStruct.soGroupData.siteOptionGroupSetId[row.site_x_option_group_set_parent_id&"_childGroup"][row.site_option_group_id]=arraynew(1);
				}
				// used for looping all sets in the group
				if(structkeyexists(tempUniqueStruct, row.site_x_option_group_set_parent_id&"_"&id) EQ false){ 
					arrayappend(tempStruct.soGroupData.siteOptionGroupSetId[row.site_x_option_group_set_parent_id&"_childGroup"][row.site_option_group_id], id);
					tempUniqueStruct[row.site_x_option_group_set_parent_id&"_"&id]=true;
				}
			}
		}
	}
	db.sql="SELECT s3.site_x_option_group_set_id, s3.site_option_id groupSetOptionId, 
	s3.site_x_option_group_value groupSetValue 
	FROM #db.table("site_x_option_group", request.zos.zcoreDatasource)# s3 
	WHERE s3.site_id = #db.param(arguments.site_id)#  and 
	s3.site_x_option_group_deleted = #db.param(0)# and 
	s3.site_option_group_id IN (#db.trustedSQL(cacheEnableGroupIdList)#) "; 
	qS=db.execute("qS"); 
	tempUniqueStruct=structnew();
	
	for(row in qS){
		id=row.site_x_option_group_set_id;
		if(structkeyexists(tempStruct.soGroupData.siteOptionLookup, row.groupSetOptionId)){
			var typeId=tempStruct.soGroupData.siteOptionLookup[row.groupSetOptionId].type;
			if(typeId EQ 3 or typeId EQ 9){
				if(row.groupSetValue NEQ "" and row.groupSetValue NEQ "0"){
					optionStruct=tempStruct.soGroupData.siteOptionLookup[row.groupSetOptionId].optionStruct;
					if(application.zcore.functions.zso(optionStruct, 'file_securepath') EQ "Yes"){
						tempValue="/zuploadsecure/site-options/"&row.groupSetValue;
					}else{
						tempValue="/zupload/site-options/"&row.groupSetValue;
					}
				}else{
					local.tempValue="";
				}
			}else{
				local.tempValue=row.groupSetValue;
			}
			tempStruct.soGroupData.siteOptionGroupSetId[id&"_f"&row.groupSetOptionId]=local.tempValue; 
		}
	}
	 db.sql="SELECT * FROM 
	 #db.table("site_x_option_group_set", request.zos.zcoreDatasource)# s1, 
	 #db.table("site_option_group", request.zos.zcoreDatasource)# s2
	WHERE s1.site_id = #db.param(arguments.site_id)# and 
	s1.site_id = s2.site_id and 
	s1.site_x_option_group_set_deleted = #db.param(0)# and 
	s2.site_option_group_deleted = #db.param(0)# and 
	s1.site_option_group_id = s2.site_option_group_id and 
	s2.site_option_group_enable_cache = #db.param(1)#
	ORDER BY s1.site_x_option_group_set_sort asc";
	//s1.site_x_option_group_set_approved=#db.param(1)# and 
	qS=db.execute("qS"); 
	for(row in qS){
		if(structkeyexists(tempStruct.soGroupData.siteOptionGroupSetArrays, row.site_option_app_id&chr(9)&row.site_option_group_id&chr(9)&row.site_x_option_group_set_parent_id) EQ false){
			tempStruct.soGroupData.siteOptionGroupSetArrays[row.site_option_app_id&chr(9)&row.site_option_group_id&chr(9)&row.site_x_option_group_set_parent_id]=arraynew(1);
		}
		ts=structnew();
		ts.__sort=row.site_x_option_group_set_sort;
		ts.__setId=row.site_x_option_group_set_id;
		ts.__dateModified=row.site_x_option_group_set_updated_datetime;
		ts.__groupId=row.site_option_group_id;
		ts.__approved=row.site_x_option_group_set_approved;
		ts.__title=row.site_x_option_group_set_title;
		ts.__parentID=row.site_x_option_group_set_parent_id;
		ts.__summary=row.site_x_option_group_set_summary;
		// build url
		if(row.site_x_option_group_set_image_library_id NEQ 0){
			ts.__image_library_id=row.site_x_option_group_set_image_library_id;
		}
		if(row.site_option_group_enable_unique_url EQ 1){
			if(row.site_x_option_group_set_override_url NEQ ""){
				ts.__url=row.site_x_option_group_set_override_url;
			}else{
				var urlId=qSite.site_option_group_url_id;
				if(urlId EQ "" or urlId EQ 0){
					throw("site_option_group_url_id is not set for site_id, #arguments.site_id#.");
				}
				ts.__url="/#application.zcore.functions.zURLEncode(row.site_x_option_group_set_title, '-')#-#urlId#-#row.site_x_option_group_set_id#.html";
			}
		}
		t9=tempStruct.soGroupData;
		if(structkeyexists(t9.siteOptionGroupDefaults, row.site_option_group_id)){
			local.defaultStruct=t9.siteOptionGroupDefaults[row.site_option_group_id];
		}else{
			local.defaultStruct={};
		}
		if(structkeyexists(t9.siteOptionGroupSetId, ts.__setId&"_groupId")){
			groupId=t9.siteOptionGroupSetId[ts.__setId&"_groupId"];
			if(structkeyexists(t9.siteOptionGroupFieldLookup, groupId)){
				local.fieldStruct=t9.siteOptionGroupFieldLookup[groupId];
			
				for(local.i2 in local.fieldStruct){
					local.cf=t9.siteOptionLookup[local.i2];
					if(structkeyexists(t9.siteOptionGroupSetId, ts.__setId&"_f"&local.i2)){
						ts[local.cf.name]=t9.siteOptionGroupSetId[ts.__setId&"_f"&local.i2];
					}else if(structkeyexists(local.defaultStruct, local.cf.name)){
						ts[local.cf.name]=local.defaultStruct[local.cf.name];
					}else{
						ts[local.cf.name]="";
					}
				}
			}
		}
		tempStruct.soGroupData.siteOptionGroupSet[row.site_x_option_group_set_id]= ts;
		arrayappend(tempStruct.soGroupData.siteOptionGroupSetArrays[row.site_option_app_id&chr(9)&ts.__groupId&chr(9)&row.site_x_option_group_set_parent_id], ts);
	} 
	
	db.sql="SELECT * FROM #db.table("site_option", request.zos.zcoreDatasource)# site_option 
	LEFT JOIN #db.table("site_x_option", request.zos.zcoreDatasource)# site_x_option ON 
	site_x_option.site_id =#db.param(arguments.site_id)# and 
	site_x_option.site_option_id = site_option.site_option_id and 
	site_option.site_id = if(site_x_option.site_option_id_siteIDType = #db.param(1)#, #db.param(qSite.site_id)#, if(site_x_option.site_option_id_siteIDType = #db.param(4)#, #db.param(0)#, #db.param(qSite.site_id)#)) and 
	site_x_option_deleted = #db.param(0)#
	WHERE site_option.site_id IN (#db.param('0')#,#db.param(arguments.site_id)#) and 
	site_option_deleted = #db.param(0)# and 
	site_option_group_id = #db.param(0)#";
	/*LEFT JOIN #db.table("site_option_group", request.zos.zcoreDatasource)# site_option_group ON 
	site_option_group.site_option_group_id = site_option.site_option_group_id and 
	site_option_group_type= #db.param(0)# and 
	site_option_group_deleted = #db.param(0)# and
	site_option_group.site_id = #db.param(arguments.site_id)# 
	site_option.site_option_group_id IN (#db.trustedSQL(cacheEnableGroupIdList)#) */
	qS=db.execute("qS"); 
	tempStruct.site_options=structnew();
	tempStruct.site_option_edit_enabled=structnew();
	tempStruct.site_option_app=structnew();
	for(row in qS){
		tempStruct.site_option_edit_enabled[row.site_option_name]=row.site_option_edit_enabled;
		if(row.site_option_type_id EQ 1 and row.site_option_line_breaks EQ 1){
			if(row.site_x_option_id EQ ""){
				local.c1=application.zcore.functions.zparagraphformat(row.site_option_default_value);
			}else{
				local.c1=application.zcore.functions.zparagraphformat(row.site_x_option_value);
			}
		}else{
			if(row.site_x_option_id EQ ""){
				local.c1=row.site_option_default_value;
			}else{
				local.c1=row.site_x_option_value;
			}
			if(local.c1 NEQ "" and local.c1 NEQ "0" and (row.site_option_type_id EQ 3 or row.site_option_type_id EQ 9)){
				local.c1="/zupload/site-options/"&local.c1;
			}
		}
		if(row.site_option_app_id NEQ 0){
			if(structkeyexists(tempStruct.site_option_app, row.site_option_app_id) EQ false){
				tempStruct.site_option_app[row.site_option_app_id]=structnew();
			}
			tempStruct.site_option_app[row.site_option_app_id][row.site_option_name]=local.c1;
		}else{
			tempStruct.site_options[row.site_option_name]=local.c1;
		}
	}
	/*
	*/
	tempStruct.lastModifiedDate=now();
	local.curPrivatePath=application.zcore.functions.zGetDomainWritableInstallPath(qsite.site_short_domain);
	if(qsite.site_short_domain_previous NEQ ""){
		local.sdomain=lcase(replacenocase(replacenocase(qsite.site_short_domain_previous,"www.",""),"."&request.zos.testDomain,""));
		local.tempPrivatePath=request.zos.sitesWritablePath&local.sdomain&"/";
		if(directoryexists(local.tempPrivatePath)){
			local.curPrivatePath=local.tempPrivatePath;
		}
	}
	application.zcore.functions.zWriteFile(local.curPrivatePath&'_cache/scripts/global.json', serializeJson(tempStruct));
	local.curSiteId=tempStruct.id;
	request.zos.globals=duplicate(application.zcore.serverglobals);
	structappend(Request.zos.globals, firstTempStruct, true);
	structappend(Request.zos.globals, tempStruct, true);
	
	local.tempStruct=structnew();
	local.tempStruct.site_id=arguments.site_id;
	local.tempStruct.globals=request.zos.globals;
	local.tempStruct=application.zcore.functions.zGetSite(tempStruct);
	application.sitestruct[arguments.site_id]=tempStruct;
	application.zcore.siteGlobals[arguments.site_id]=tempStruct.globals;
	if(arguments.site_id EQ local.curSiteId){
		application.sitestruct[request.zos.globals.id].globals=request.zos.globals; // used duplicate() previously and haven't needed to bring it back.
		application.sitestruct[request.zos.globals.id]=application.sitestruct[arguments.site_id];
	}
	structdelete(application.sitestruct[arguments.site_id],'administratorTemplateMenu');
	</cfscript>
</cffunction>

<cffunction name="zCacheJsonSiteAndUserGroup" localmode="modern">
	<cfargument name="site_id" type="numeric" required="yes">
	<cfargument name="tempStruct" type="struct" required="yes">
	<cfscript>
	var shortDomain=application.zcore.functions.zvar('shortDomain', arguments.site_id);
	if(shortDomain EQ ""){
		throw("site_id, #arguments.site_id#, doesn't exist.");
	}
	var curPrivatePath=application.zcore.functions.zGetDomainWritableInstallPath(shortDomain);
	application.zcore.functions.zWriteFile(curPrivatePath&'_cache/scripts/global.json', serializeJson(arguments.tempStruct));
	</cfscript>
</cffunction>

<cffunction name="zUpdateGlobalMVCData" localmode="modern" access="public" output="no">
	<cfargument name="ss" type="struct" required="yes">
	<cfargument name="forceUpdate" type="boolean" required="yes">
	<cfscript>
	ts={};
	ts.controllerComponentCache={};
	
	ts.cfcMetaDataCache=structnew();
	ts.modelDataCache={
		modelComponentCache={}
	};
	arrNewComPath=arraynew(1);
	ts.registeredControllerStruct=structnew();
	ts.registeredControllerPathStruct=structnew();
	ts.hookAppCom=structnew();
	
	mvcFilesChanged=false;
	arrLocalFile=[];
	
	if(request.zos.isExecuteEnabled){
		if(directoryexists(request.zos.installPath&"core/mvc/")){
			if(fileexists("#arguments.ss.serverglobals.serverprivatehomedir#_cache/mvc-cache.cfc")){
				output=application.zcore.functions.zSecureCommand("getNewerCoreMVCFiles", 50);
			}else{
				output=1;
			}
			arrayappend(request.zos.arrRunTime, {time:gettickcount('nano'), name:'Application.cfc onApplicationStart 3-4-2'});
			if(output NEQ ""){
				directory action="list" recurse="yes" directory="#request.zos.installPath#core/mvc" name="qD" filter="*.cfc";//,*.html";
				ts434=structnew();
				arrFunction=['arrFile=variables.get1(arrFile);'];
				ts434.arrFile=['
					<cffunction name="get#arrayLen(arrFunction)#" localmode="modern" access="private">
						<cfargument name="arrFile" type="array" required="yes">
						<cfscript>
						arrFile=arguments.arrFile;
				'];
				if(qD.recordcount GT 1){
					arrLocalFile=[];
					tempCount=1;
					loop query="qD"{
						//if(qD.directory DOES NOT CONTAIN "#arguments.ss.serverglobals.serverhomedir#mvc/z/test"){
							arrayAppend(ts434.arrFile, 'arrayAppend(arrFile, { type:"#qD.type#", directory:"#replace(qD.directory, "#request.zos.installPath#core/", "/")#", name:"#qD.name#", lastModified:"#qD.dateLastModified#"});');
							arrayappend(arrLocalFile, {"type":qD.type, "directory":replace(qD.directory, "#request.zos.installPath#core/", "/"), name:qD.name, lastModified:qD.dateLastModified});
							tempCount++;
							if(tempCount GTE 100){
								arrayAppend(arrFunction, 'arrFile=variables.get'&(arrayLen(arrFunction)+1)&'(arrFile);');
								arrayappend(ts434.arrFile, '
								return arrFile;
								</cfscript>
								</cffunction>
								<cffunction name="get#arrayLen(arrFunction)#" localmode="modern" access="private">
									<cfargument name="arrFile" type="array" required="yes">
									<cfscript>
									arrFile=arguments.arrFile;
								');	
								tempCount=1;
							}
						//}
					}
					arrayappend(ts434.arrFile, '
						return arrFile;
						</cfscript>
						</cffunction>');
					//tempStructString=application.zcore.functions.zStructToString("local", ts434);
					tempComponentString='<cfcomponent>
					<cffunction name="get" localmode="modern" access="public" hint="DO NOT EDIT THIS FILE. It is automatically regenerated when the /zcorerootmapping/mvc directory has new or removed CFC files.  This is done so that we can automatically cache CFC metadata when the application is deployed to the production server without the CFML source.  Railo supports sourceless deployment via the Secure Railo Archive (.ras) feature."  returntype="array">
					<cfscript>
					var local=structnew();
					arrFile=arraynew(1);
					'&arrayToList(arrFunction, '')&'
					return arrFile;
					</cfscript>
					</cffunction>
					'&arrayToList(ts434.arrFile, '')&'
					</cfcomponent>';  
					if(1 or request.zos.isExecuteEnabled){
						if(hash(tempComponentString) NEQ hash(application.zcore.functions.zreadfile("#arguments.ss.serverglobals.serverprivatehomedir#_cache/mvc-cache.cfc"))){
							application.zcore.functions.zwritefile(arguments.ss.serverglobals.serverprivatehomedir&"_cache/mvc-cache.cfc", tempComponentString);
							application.zcore.functions.zClearCFMLTemplateCache();
							mvcFilesChanged=true;
						}
					}
				}
				arrayappend(request.zos.arrRunTime, {time:gettickcount('nano'), name:'Application.cfc onApplicationStart 3-5'});
			}
		}
		if(arrayLen(arrLocalFile)){
			arrFile=arrLocalFile;
		}else if(1 or request.zos.isExecuteEnabled){
			mvcCacheCom=createobject("component","zcorecachemapping.mvc-cache");
			arrFile=mvcCacheCom.get();
		}else{
			throw("request.zos.isExecuteEnabled must be set to true in a sourceless deployment.");
		}
		if(not request.zos.isTestServer or structkeyexists(form, 'zforce')){
			mvcFilesChanged=true;
		}
	}else{
		// always true when execute is disabled
		directory action="list" recurse="yes" directory="#request.zos.installPath#core/mvc" name="qD" filter="*.cfc";
		arrFile=[];
		for(row in qD){
			arrayappend(arrFile, {"type":row.type, "directory":replace(row.directory, "#request.zos.installPath#core/", "/"), name:row.name, lastModified:row.dateLastModified});
		}
		mvcFilesChanged=true; 
	}
	if(mvcFilesChanged or (not structkeyexists(application, 'zcore') or not structkeyexists(application.zcore, 'controllerComponentCache') or structcount(application.zcore.hookAppCom) EQ 0)){
		for(i2=1;i2 LTE arraylen(arrFile);i2++){
			qD=arrFile[i2];
			if(left(qD.directory, 12) EQ '/mvc/z/test/'){// and request.zos.cgi.http_host NEQ request.zos.zcoreTestHost){ 
				continue;
			}
			
			/*if(not request.zos.isTestServer and left(qD.directory, 12) EQ '/mvc/z/test/'){
				continue;
			}*/
			i=i2;
			curPath=arguments.ss.serverglobals.serverhomedir&removechars(qD.directory,1,1)&"/"&qD.name;
			curPath2="/zcorerootmapping"&qD.directory&"/"&qD.name;
			curPath22="/zcorerootmapping"&qD.directory&"/"&qD.name;
			if(qD.name EQ "hook.cfc"){
				ts.hookAppCom[qD.name]=createObject("component","zcorerootmapping."&replace(replace(qD.directory, arguments.ss.serverglobals.serverhomedir, ""),"/",".","all")&"."&left(qD.name, len(qD.name)-4));
				ts.hookAppCom[qD.name].registerHooks(arguments.ss.componentObjectCache.hook);
				continue;
			}
			if(qD.type EQ "file"){ 
				curPath2=removechars(replace(replace(replace(arguments.ss.serverglobals.serverhomedir&removechars(qD.directory,1,1),"\","/","all"),curPath,""), arguments.ss.serverglobals.serverhomedir&"mvc/",""),1,0);
				arrPath2=listtoarray(curPath2,"/",false);
				fileType=listgetat(curPath2,1,"/");
				curPath3=replace(curPath2,"/",".","all");
				curPath4=listdeleteat(curPath3,1,".");
				curName=listgetat(qD.name,1,".");
				curExt=listgetat(qD.name,2,".");
				lastFolderName=listgetat(curPath2,listlen(curPath2, "/", true),"/");
				if(curName CONTAINS "."){
					application.zcore.functions.zerror(qD.directory&"/"&qD.name&" - A CFC file name can't have a period after the "".cfc"" is removed from the end.  Please remove the periods in the name, ""."", leave the "".cfc"" at the end and try again.");	
				}
				
				if(lastFolderName EQ "controller"){
					if(curExt EQ "cfc"){
						comPath=replace(mid(curPath22,2,len(curPath22)-5),"/",".","all");
						//try{
							tempCom=createobject("component", comPath);
						/*}catch(Any excpt){
							writeoutput(comPath);
							writedump(excpt);
							application.zcore.functions.zabort();
						}*/
						tempcommeta=GetMetaData(tempCom);
						ts.controllerComponentCache[comPath]=tempCom;
						ts.cfcMetaDataCache[comPath]=tempcommeta;
						if(structkeyexists(tempcommeta,'functions')){
							for(i3=1;i3 LTE arraylen(tempcommeta.functions);i3++){
								if(structkeyexists(tempcommeta.functions[i3],"access") and tempcommeta.functions[i3].access EQ "remote"){
									ts.cfcMetaDataCache[comPath&":"&tempcommeta.functions[i3].name]=tempcommeta.functions[i3];
								}
							}
						}
						if(structkeyexists(tempCom,'mvcName')){
							curMvcName="/"&curpath2&"/"&tempCom.mvcName;
						}else{
							curMvcName="/"&curpath2&"/"&curName;
						}
						curMvcName=replace(curMvcName, arguments.ss.serverglobals.serverhomedir&"mvc/", "");
						t42="";
						for(i4=1;i4 LTE arraylen(arrPath2);i4++){
							t42&="/"&arrPath2[i4];
							ts.registeredControllerPathStruct[t42]=true;
						}
						ts.registeredControllerStruct[curMvcName]=replace(curPath, arguments.ss.serverglobals.serverhomedir, "/zcorerootmapping/");
					}
					
				}else if(lastFolderName EQ "model"){
					if(curExt EQ "cfc"){
						comPath=replace(mid(curPath22,2,len(curPath22)-5),"/",".","all");
						ts.modelDataCache.modelComponentCache[comPath]=createobject("component", comPath);
						/*comPath="mvc"&"."&curPath3&"."&curName;
						if(structkeyexists(form,  'zregeneratemodelcache') EQ false and structkeyexists(applization, 'zcore') and structkeyexists(application.zcore,'modelDataCache') and structkeyexists(application.zcore.modelDataCache.modelComponentCache, comPath)){
							ts.modelDataCache.modelComponentCache[comPath]=application.zcore.modelDataCache.modelComponentCache[comPath];
						}else{
							arrayappend(arrNewComPath, comPath);
							ts.modelDataCache.modelComponentCache[comPath]=createobject("component", comPath);
						}*/
					}/*
				}else if(lastFolderName EQ "view"){
					if(curExt EQ "html"){
						//writeoutput('application.zcore.skin.loadView("'&curPath3&"."&curName&'", "'&arrMvcPaths[i]&'");<br />');
						// application.zcore.skin.loadView("/"&curPath2&"/"&curName, arrMvcPaths[i]);
					}*/
				}
				//writeoutput("curdir:"&curPath2&"|"&fileType&"<br />");
				//writeoutput(directory&"\"&name&"<br />");
			}
		}
		/*
		also need a component that wraps the global functions, global scopes and injects that to every controller by default.   maybe controllers should have a base component for this to be less code.
			getModelDependencies
			setRequestObject(requestObject);

			variables.ro.function
		*/
		//writedump(structkeyarray(ts.modelDataCache.modelComponentCache));
		//abort;
		structappend(arguments.ss, ts, true);
	}else{
		ts.hookAppCom=application.zcore.hookAppCom;
		ts.cfcMetaDataCache=application.zcore.functions.zso(application.zcore, 'cfcMetaDataCache', false, {});
		//ts.modelDataCache=application.zcore.modelDataCache;
		ts.controllerComponentCache=application.zcore.controllerComponentCache;
		ts.registeredControllerPathStruct=application.zcore.registeredControllerPathStruct;
		ts.registeredControllerStruct=application.zcore.registeredControllerStruct;
		structappend(arguments.ss, ts, true);
	}
	</cfscript>
</cffunction>

<cffunction name="zOS_rebuildCache" localmode="modern" output="no" returntype="any">
	<cfscript>
	var local=structnew();
	var db=request.zos.queryObject;
	var qSite=0;
	application.zcore.functions.zOS_cacheSitePaths();
	db.sql="SELECT site_id from #db.table("site", request.zos.zcoreDatasource)# site 
	WHERE site_id <> #db.param(-1)# and 
	site_deleted = #db.param(0)#";
	qSite=db.execute("qSite");
	for(local.row in qSite){
	        application.zcore.functions.zOS_cacheSiteAndUserGroups(local.row.site_id);
	}
        </cfscript>
</cffunction>

<!--- re-create the server wide caching of site paths. --->
<cffunction name="zOS_cacheSitePaths" localmode="modern" output="no" returntype="any">
	<cfscript>
	var local=structnew();
	var qSites = "";
	var output = "";
	var result = "";
	var i = 1;
	var row=0;
	var tempStruct = StructNew();
	var arrT=arraynew(1);
	var c="";
	var cs="";
	var ce="";
	var db=request.zos.queryObject;
	var endString="";
	var startString="";
	var theOut="";
	db.sql="SELECT * FROM #db.table("site", request.zos.zcoreDatasource)# site 
	WHERE site_id <> #db.param(-1)# and 
	site_deleted = #db.param(0)# and
	site_active=#db.param(1)#";
	qSites=db.execute("qSites");
	tempStruct = StructNew();
	for(row in qSites){
		if(trim(row.site_domain) NEQ ''){
			StructInsert(tempStruct, row.site_domain,row.site_id,true);
		}
		if(trim(row.site_securedomain) NEQ ''){
			StructInsert(tempStruct, row.site_securedomain,row.site_id,true);
		}
		local.tempPath=application.zcore.functions.zGetDomainInstallPath(local.row.site_short_domain);
		if(directoryexists(local.tempPath)){
			StructInsert(tempStruct, local.tempPath,row.site_id,true);
		}
		local.tempPath=application.zcore.functions.zGetDomainWritableInstallPath(local.row.site_short_domain);
		if(directoryexists(local.tempPath)){
			StructInsert(tempStruct, local.tempPath,row.site_id,true);
		}
	}
	for(row in qSites){
		var arrTemp=listToArray(row.site_domainaliases, ",", false);
		for(var i=1;i LTE arrayLen(arrTemp);i++){
			var p="http://";
			if(left(row.site_domain, 8) EQ "https://"){
				p="https://";
			}
			StructInsert(tempStruct, p&trim(arrTemp[i]), row.site_id, false);
		}
		if(row.site_ssl_manager_domain NEQ ""){
			StructInsert(tempStruct, 'https://'&trim(row.site_ssl_manager_domain), row.site_id, false);
		}
	}
	application.zcore.functions.zWriteFile(request.zos.globals.serverprivatehomedir&'_cache/scripts/sites.json', serializeJson(tempStruct));
	application.zcore.sitePaths=tempStruct;
	</cfscript>
</cffunction>

<cffunction name="zClearCFMLTemplateCache" localmode="modern">
	<cfscript>
	componentCacheClear();
	pagePoolClear();
	// ctCacheClear(); // custom tag cache
	</cfscript>
    <!--- query cache --->
    <!--- <cfobjectcache action="clear"> --->
</cffunction>

<cffunction name="zGetDomainInstallPath" localmode="modern" access="public" returntype="string">
	<cfargument name="domain" type="string" required="yes">
	<cfscript>
	if(request.zos.istestserver){
		return request.zos.sitesPath&replace(replace(replace(arguments.domain, "www.","","all"), "."&request.zos.testDomain, ""), ".", "_", "all")&"/";
	}else{
		return request.zos.sitesPath&replace(replace(arguments.domain, "www.","","all"), ".", "_", "all")&"/";
	}
	</cfscript>
</cffunction>

<cffunction name="zGetDomainWritableInstallPath" localmode="modern" access="public" returntype="string">
	<cfargument name="domain" type="string" required="yes">
	<cfscript>
	if(request.zos.istestserver){
		return request.zos.sitesWritablePath&replace(replace(replace(arguments.domain, "www.","","all"), "."&request.zos.testDomain, ""), ".", "_", "all")&"/";
	}else{
		return request.zos.sitesWritablePath&replace(replace(arguments.domain, "www.","","all"), ".", "_", "all")&"/";
	}
	</cfscript>
</cffunction>

<cffunction name="zOS_getSiteNav" localmode="modern" returntype="any" output="false" hint="displays server admin site navigation">
	<cfargument name="zid" type="string" required="yes">
	<cfscript>
	var local=structnew();
	var selectStruct='';
	var qSites='';
	var qSite='';
	var db=request.zos.queryObject;
	var content = "";
	var zsaHeader = "";

	if(not application.zcore.user.checkServerAccess()){
		application.zcore.status.setStatus(request.zsid, "You don't have access to the server manager.", form, true);
		application.zcore.functions.zRedirect("/z/admin/admin-home/index?zsid=#request.zsid#");
	}

	</cfscript>
	<cfif structkeyexists(form,'sid') EQ false>
    	<cfset form.sid=application.zcore.status.getField(arguments.zid, 'site_id')>
		<cfset form.sid = form.sid>
    <cfelse>
    	<cfset form.sid=form.sid>
	</cfif>
	<cfsavecontent variable="db.sql">
	SELECT * FROM #db.table("site", request.zos.zcoreDatasource)# site 
	WHERE site_id <> #db.param(-1)# and 
	site_deleted = #db.param(0)# and
	site_active= #db.param(1)# 
	ORDER BY site_domain
	</cfsavecontent><cfscript>qSites=db.execute("qSites");</cfscript>
	<cfsavecontent variable="db.sql">
	SELECT * FROM #db.table("site", request.zos.zcoreDatasource)# site 
	WHERE site_id = #db.param(form.sid)# and 
	site_deleted = #db.param(0)#
	</cfsavecontent><cfscript>qSite=db.execute("qSite");


	if(not application.zcore.user.checkAllCompanyAccess() and form.sid NEQ "" and form.sid NEQ "0"){
		if(request.zsession.user.company_id NEQ qSite.company_id){
			application.zcore.status.setStatus(request.zsid, "You don't have access to the server manager for this site_id: #form.sid#.", form, true);
			application.zcore.functions.zRedirect("/z/admin/admin-home/index?zsid=#request.zsid#");
		}
	}
	</cfscript>
	<cfsavecontent variable="zsaHeader">
	<script type="text/javascript">/* <![CDATA[ */
    function zOSGoToSite(id){
        if(id != ''){
            window.location.href='#request.cgi_script_name#?#replacenocase(cgi.QUERY_STRING,'sid=','zzzsid=','ALL')#&sid='+escape(id);
        }
    }
	/* ]]> */
    </script>
	<table style="width:100%; border-spacing:0px;margin-top:-10px; background-color:##DDD;" class="table-list">
		<tr><th style="background-color:##000 !important;color:##FFF; font-weight:bold; font-size:120%;padding:10px;">Server Manager</th></tr>
	<tr>
	<td style="padding:10px;"><a href="/z/server-manager/admin/server-home/index">Dashboard</a>
	<cfif structkeyexists(request.zos.userSession.groupAccess, "administrator")>
	 | <a href="/z/server-manager/admin/site-select/index?sid=">Sites</a> 
	 <cfif application.zcore.user.checkAllCompanyAccess()>
	
		| <a href="/z/server-manager/admin/dns-group/index">DNS</a> 
		| <a href="/z/_com/zos/app?method=appList&amp;zid=#arguments.zid#&amp;sid=#form.sid#">Apps</a>
		| <a href="/z/server-manager/admin/log?sid=">Logs</a> 
		| <a href="/z/server-manager/admin/deploy/index">Deploy</a>
	</cfif>
     
	 </cfif>
	 </td>
	</tr>
	</table>
	</cfsavecontent>
	<cfscript>
	if(len(form.sid) EQ 0){
		application.zcore.status.setField(arguments.zid, "site_id", "");
		return zsaHeader;
	}else{
		application.zcore.status.setField(arguments.zid, "site_id", form.sid);
	}
	form.sid = application.zcore.status.getField(arguments.zid, 'site_id');
	</cfscript>
	<cfsavecontent variable="content"><cfif structkeyexists(request.zos.userSession.groupAccess, "administrator")>
	<table style="width:100%; background-color:##EEE;  border-spacing:0px;margin-bottom:10px;" class="table-list">
	<tr>
	<th style="font-weight:bold; font-size:120%;"><a href="#qSite.site_domain#" target="_blank">#qSite.site_sitename#</a> | Server Manager</th>
	<th style="text-align:right;" class="tiny"><a href="/z/server-manager/admin/site/delete?zid=#arguments.zid#">Deactivate Site</a></th>
	</tr>
	<tr>
	<td colspan="2" class="tiny-bold">
	<a href="/z/server-manager/admin/site/edit?zid=#arguments.zid#&amp;sid=#form.sid#">Globals</a>
	| <a href="/z/server-manager/admin/domain-redirect/index?zid=#arguments.zid#&amp;sid=#form.sid#">Domain Redirects</a>
	<cfif application.zcore.user.checkAllCompanyAccess()>
		| <a href="/z/server-manager/admin/deploy/index?zid=#arguments.zid#&amp;sid=#form.sid#">Deploy</a>
	</cfif>
	| <a href="/z/server-manager/admin/white-label/index?zid=#arguments.zid#&amp;sid=#form.sid#">White-Label</a>
	
	| <a href="/z/server-manager/admin/site/downloadste?zid=#arguments.zid#&amp;sid=#form.sid#">Dreamweaver STE</a>
	<cfif qSite.site_theme_sync_site_id NEQ 0> | <a href="/z/server-manager/admin/site/manualSync?zid=#arguments.zid#&amp;sid=#form.sid#">Sync Source Code</a></cfif>
	| <a href="/z/server-manager/admin/download-site-backup/index?zid=#arguments.zid#&amp;sid=#form.sid#">Backup</a>
	| <a href="/z/server-manager/admin/user/index?zid=#arguments.zid#&sid=#form.sid#">Users</a> 
	| <a href="/z/_com/zos/app?method=instanceSiteList&amp;zid=#arguments.zid#&amp;sid=#form.sid#">Applications</a>
	| <a href="/z/server-manager/admin/rewrite-rules/edit?zid=#arguments.zid#&amp;sid=#form.sid#">Rewrite Rules</a>
	| <a href="/z/server-manager/admin/robots/edit?zid=#arguments.zid#&amp;sid=#form.sid#">Robots.txt</a>
	| <a href="/z/server-manager/admin/ssl/index?zid=#arguments.zid#&amp;sid=#form.sid#">SSL</a>
	| <a href="/z/server-manager/admin/hardcoded-urls/edit?zid=#arguments.zid#&amp;sid=#form.sid#">Hardcoded URLs</a>
	</td>
	</tr>
	</table></cfif>
	</cfsavecontent>
	<cfreturn zsaHeader&content>
</cffunction>


<cffunction name="zMenuClearCache" localmode="modern" returntype="any" output="no">
	<cfargument name="affectedStruct" type="struct" required="yes">
	<cfscript>
	var local=structnew();
	for(local.i IN application.sitestruct[request.zos.globals.id].menuIdCacheStruct){
		for(local.n IN arguments.affectedStruct){
			if(local.n EQ "all"){
				structdelete(application.sitestruct[request.zos.globals.id].menuIdCacheStruct, local.i);
				break;
			}else if(structkeyexists(application.sitestruct[request.zos.globals.id].menuIdCacheStruct[local.i].affectedStruct, local.n)){
				structdelete(application.sitestruct[request.zos.globals.id].menuIdCacheStruct, local.i);
				break;
			}
		}		
	}
	for(local.i IN application.sitestruct[request.zos.globals.id].menuNameCacheStruct){
		for(local.n IN arguments.affectedStruct){
			if(local.n EQ "all"){
				structdelete(application.sitestruct[request.zos.globals.id].menuNameCacheStruct, local.i);
				break;
			}else if(not structkeyexists(application.sitestruct[request.zos.globals.id].menuNameCacheStruct[local.i], 'affectedStruct') or structkeyexists(application.sitestruct[request.zos.globals.id].menuNameCacheStruct[local.i].affectedStruct, local.n)){
				structdelete(application.sitestruct[request.zos.globals.id].menuNameCacheStruct, local.i);
				break;
			}
		}		
	}
	</cfscript>
</cffunction>

<!--- 
ts=structnew();
ts.menu_id=5;
// or
ts.menu_name="";
rs=zMenuInclude(ts);
writeoutput(rs.output);
 --->
<cffunction name="zMenuInclude" localmode="modern" returntype="any" output="yes">
	<cfargument name="ss" type="struct" required="yes">
	<cfscript>
	menuCom=createobject("component", "zcorerootmapping.com.app.menuFunctions");
	menuCom.init(arguments.ss);
	arrLink=menuCom.getMenuLinkArray(); 
	rs={
		output:menuCom.getMenuHTML()
	};
	return rs;
	</cfscript>
</cffunction>



<!--- zGetSiteSelect(fieldName); --->
<cffunction name="zGetSiteSelect" localmode="modern" output="yes" returntype="any">
	<cfargument name="fieldName" type="string" required="yes">
	<cfscript>
	var local=structnew();
	var db=request.zos.queryObject;
	</cfscript>
	<cfsavecontent variable="db.sql">
	SELECT * FROM #db.table("site", request.zos.zcoreDatasource)# site 
	WHERE site_active= #db.param(1)# and 
	site_id <> #db.param(-1)# and 
	site_deleted = #db.param(0)#
	ORDER BY site_sitename ASC
	</cfsavecontent><cfscript>local.qSites=db.execute("qSites");
    local.selectStruct = StructNew();
    local.selectStruct.name = arguments.fieldName;
    local.selectStruct.query = local.qSites;
    local.selectStruct.queryLabelField = "site_sitename";
    local.selectStruct.queryValueField = "site_id";
    application.zcore.functions.zInputSelectBox(local.selectStruct);
    </cfscript>
</cffunction>
</cfoutput>
</cfcomponent>