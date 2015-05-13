<cfcomponent>
<cfoutput>


<cffunction name="delete" localmode="modern" access="remote" roles="member">
	<cfscript>
	var db=request.zos.queryObject; 
	application.zcore.adminSecurityFilter.requireFeatureAccess("Manage Events", true);	
	db.sql="SELECT * FROM #db.table("event", request.zos.zcoreDatasource)# event
	WHERE event_id= #db.param(application.zcore.functions.zso(form,'event_id'))# and 
	event_deleted = #db.param(0)# and
	site_id = #db.param(request.zos.globals.id)#";

	if(structkeyexists(form, 'return')){
		StructInsert(request.zsession, "event_return"&form.event_id, request.zos.CGI.HTTP_REFERER, true);		
	}
	form.returnJson=application.zcore.functions.zso(form, 'returnJson', true, 0);
	qCheck=db.execute("qCheck");
	
	if(qCheck.recordcount EQ 0){
		application.zcore.status.setStatus(Request.zsid, 'Event no longer exists', false,true);
		application.zcore.functions.zRedirect('/z/event/admin/manage-events/index?zsid=#request.zsid#');
	}
	</cfscript>
	<cfif structkeyexists(form,'confirm')>
		<cfscript> 
		application.zcore.imageLibraryCom.deleteImageLibraryId(qCheck.event_image_library_id);

		db.sql="DELETE FROM #db.table("event_x_category", request.zos.zcoreDatasource)#  
		WHERE event_id= #db.param(application.zcore.functions.zso(form, 'event_id'))# and 
		event_x_category_deleted = #db.param(0)# and 
		site_id = #db.param(request.zos.globals.id)# ";
		q=db.execute("q");

		application.zcore.functions.zDeleteUniqueRewriteRule(qCheck.event_unique_url);

		db.sql="DELETE FROM #db.table("event_recur", request.zos.zcoreDatasource)#  
		WHERE event_id= #db.param(application.zcore.functions.zso(form, 'event_id'))# and 
		event_recur_deleted = #db.param(0)# and 
		site_id = #db.param(request.zos.globals.id)# ";
		q=db.execute("q");

		db.sql="DELETE FROM #db.table("event", request.zos.zcoreDatasource)#  
		WHERE event_id= #db.param(application.zcore.functions.zso(form, 'event_id'))# and 
		event_deleted = #db.param(0)# and 
		site_id = #db.param(request.zos.globals.id)# ";
		q=db.execute("q");



		if(structkeyexists(request.zsession, 'event_return'&form.event_id)){
			a=request.zsession['event_return'&form.event_id];
			structdelete(request.zsession, 'event_return'&form.event_id);
			application.zcore.functions.zRedirect(a);
		}else{
			if(form.returnJson EQ 1){
				application.zcore.functions.zReturnJson({success:true});
			}else{
				application.zcore.status.setStatus(Request.zsid, 'Event deleted');
				application.zcore.functions.zRedirect('/z/event/admin/manage-events/index?zsid=#request.zsid#');
			}
		}
		</cfscript>
	<cfelse>
		<div style="font-size:14px; font-weight:bold; text-align:center; "> Are you sure you want to delete this Event?<br />
			<br />
			#qCheck.event_name#<br />
			<br />
			<a href="/z/event/admin/manage-events/delete?confirm=1&amp;event_id=#form.event_id#">Yes</a>&nbsp;&nbsp;&nbsp;
			<a href="/z/event/admin/manage-events/index">No</a> 
		</div>
	</cfif>
</cffunction>

<cffunction name="insert" localmode="modern" access="remote" roles="member">
	<cfscript>
	this.update();
	</cfscript>
</cffunction>

<cffunction name="update" localmode="modern" access="remote" roles="member">
	<cfscript>
	db=request.zos.queryObject;
	var ts={};
	var result=0;
	application.zcore.adminSecurityFilter.requireFeatureAccess("Manage Events", true);	
	form.site_id = request.zos.globals.id;
	ts.event_name.required = true;
	ts.event_calendar_id.required = true;
	ts.event_start_datetime_date.required = true;
	ts.event_end_datetime_date.required = true;
	result = application.zcore.functions.zValidateStruct(form, ts, Request.zsid,true);


	if(result){	
		application.zcore.status.setStatus(Request.zsid, false,form,true);
		if(form.method EQ 'insert'){
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/add?zsid=#request.zsid#');
		}else{
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/edit?event_id=#form.event_id#&zsid=#request.zsid#');
		}
	}

	if(form.event_uid EQ ""){
		form.event_uid=createuuid();
	}
	form.event_category_id=application.zcore.functions.zso(form, 'event_category_id');

	if(form.event_start_datetime_date NEQ "" and isdate(form.event_start_datetime_date)){
		form.event_start_datetime=dateformat(form.event_start_datetime_date, 'yyyy-mm-dd');
	}
	if(form.event_start_datetime_time NEQ "" and isdate(form.event_start_datetime_time)){
		form.event_start_datetime=form.event_start_datetime&" "&timeformat(form.event_start_datetime_time, 'HH:mm:ss');
	}
	if(form.event_end_datetime_date NEQ "" and isdate(form.event_end_datetime_date)){
		form.event_end_datetime=dateformat(form.event_end_datetime_date, 'yyyy-mm-dd');
	}
	if(form.event_end_datetime_time NEQ "" and isdate(form.event_end_datetime_time)){
		form.event_end_datetime=form.event_end_datetime&" "&timeformat(form.event_end_datetime_time, 'HH:mm:ss');
	} 

	if(datediff("d", form.event_start_datetime, form.event_end_datetime) LT 0){
		application.zcore.status.setStatus(request.zsid, "The end date must be after the start date", form, true);
		if(form.method EQ 'insert'){
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/add?zsid=#request.zsid#');
		}else{
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/edit?event_id=#form.event_id#&zsid=#request.zsid#');
		}
	}
	if(form.method EQ 'insert'){
		form.event_created_datetime=dateformat(now(), 'yyyy-mm-dd')&' '&timeformat(now(), 'HH:mm:ss');
	}

	if(form.event_recur_until_datetime NEQ ""){
		form.event_recur_until_datetime=dateformat(form.event_recur_until_datetime, 'yyyy-mm-dd')&' '&timeformat(form.event_recur_until_datetime, 'HH:mm:ss');
	}

	form.event_updated_datetime=dateformat(now(), 'yyyy-mm-dd')&' '&timeformat(now(), 'HH:mm:ss');
 
	application.zcore.functions.zcreatedirectory(request.zos.globals.privateHomedir&"zupload/event/");

	uniqueChanged=false;
	oldURL='';
	if(form.method EQ 'insert' and application.zcore.functions.zso(form, 'event_unique_url') NEQ ""){
		uniqueChanged=true;
	}
	if(form.method EQ 'update'){
		db.sql="SELECT * FROM #db.table("event", request.zos.zcoreDatasource)# 
		WHERE event_id = #db.param(form.event_id)# and 
		event_deleted = #db.param(0)# and 
		site_id = #db.param(request.zos.globals.id)#";
		qCheck=db.execute("qCheck");
		if(qCheck.recordcount EQ 0){
			application.zcore.status.setStatus(request.zsid, 'You don''t have permission to edit this event.',form,true);
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/index?zsid=#request.zsid#');
		}
		oldURL=qCheck.event_unique_url;
		if(structkeyexists(form, 'event_unique_url') and qcheck.event_unique_url NEQ form.event_unique_url){
			uniqueChanged=true;	
		}
	}

	ts=StructNew();
	ts.table='event';
	ts.datasource=request.zos.zcoreDatasource;
	ts.struct=form;
	if(form.method EQ 'insert'){
		form.event_id = application.zcore.functions.zInsert(ts);
		if(form.event_id EQ false){
			application.zcore.status.setStatus(request.zsid, 'Failed to save Event.',form,true);
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/add?zsid=#request.zsid#');
		}else{
			application.zcore.status.setStatus(request.zsid, 'Event saved.');
		}

	}else{
		if(application.zcore.functions.zUpdate(ts) EQ false){
			application.zcore.status.setStatus(request.zsid, 'Failed to save Event.',form,true);
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/edit?event_id=#form.event_id#&zsid=#request.zsid#');
		}else{
			application.zcore.status.setStatus(request.zsid, 'Event updated.');
		}
		
	} 
	application.zcore.functions.zUploadFileToDb("event_file1", request.zos.globals.privateHomedir&"zupload/event/", 'event', 'event_id', application.zcore.functions.zso(form, 'event_file1_deleted', true, 0), request.zos.zcoreDatasource); 
	application.zcore.functions.zUploadFileToDb("event_file2", request.zos.globals.privateHomedir&"zupload/event/", 'event', 'event_id', application.zcore.functions.zso(form, 'event_file2_deleted', true, 0), request.zos.zcoreDatasource); 

	db.sql="delete from #db.table("event_x_category", request.zos.zcoreDatasource)# WHERE 
	event_id = #db.param(form.event_id)# and 
	event_x_category_deleted=#db.param(0)# and 
	site_id = #db.param(request.zos.globals.id)# ";
	qDelete=db.execute("qDelete");

	if(form.event_category_id NEQ ""){
		arrCategory=listToArray(form.event_category_id, ',');
		for(i=1;i LTE arraylen(arrCategory);i++){
			ts={
				struct:{
					event_id:form.event_id,
					site_id:request.zos.globals.id,
					event_x_category_deleted:0,
					event_x_category_updated_datetime:dateformat(now(), 'yyyy-mm-dd')&' '&timeformat(now(), 'HH:mm:ss'),
					event_category_id:arrCategory[i]
				},
				table:"event_x_category",
				datasource:request.zos.zcoreDatasource
			}
			application.zcore.functions.zInsert(ts);
		}
	}

	application.zcore.siteOptionCom.activateOptionAppId(application.zcore.functions.zso(form, 'site_option_app_id'));
	application.zcore.imageLibraryCom.activateLibraryId(application.zcore.functions.zso(form, 'event_image_library_id'));

	updateRecurRecords=false;
	if(form.method EQ 'update'){
		if(dateformat(qCheck.event_start_datetime, "yyyy-mm-dd")&" "&timeformat(qCheck.event_start_datetime, "HH:mm:ss") NEQ form.event_start_datetime){
			updateRecurRecords=true;
		} 
		if(dateformat(qCheck.event_end_datetime, "yyyy-mm-dd")&" "&timeformat(qCheck.event_end_datetime, "HH:mm:ss") NEQ form.event_end_datetime){
			updateRecurRecords=true;
		}
		if(qCheck.event_recur_ical_rules NEQ form.event_recur_ical_rules){
			updateRecurRecords=true;
		}
		if(qCheck.event_excluded_date_list NEQ form.event_excluded_date_list){
			updateRecurRecords=true;
		}
	}else{
		updateRecurRecords=true;
	}

	if(updateRecurRecords){
		db.sql="delete from #db.table("event_recur", request.zos.zcoreDatasource)# WHERE 
		event_recur_deleted=#db.param(0)# and 
		site_id=#db.param(request.zos.globals.id)# and 
		event_id=#db.param(form.event_id)# ";
		qDelete=db.execute("qDelete");
		if(form.event_recur_ical_rules EQ ""){

			ts={
				table:"event_recur",
				datasource:request.zos.zcoreDatasource,
				struct:{
					event_id:form.event_id,
					site_id:request.zos.globals.id,
					event_recur_datetime:dateformat(form.event_start_datetime, "yyyy-mm-dd")&" "&timeformat(form.event_end_datetime, "HH:mm:ss"),
					event_recur_start_datetime:dateformat(form.event_start_datetime, "yyyy-mm-dd")&" "&timeformat(form.event_end_datetime, "HH:mm:ss"),
					event_recur_end_datetime:dateformat(form.event_end_datetime, "yyyy-mm-dd")&" "&timeformat(form.event_end_datetime, "HH:mm:ss"),
					event_recur_updated_datetime:dateformat(now(), 'yyyy-mm-dd')&' '&timeformat(now(), 'HH:mm:ss'),
					event_recur_deleted:0
				}
			}
			application.zcore.functions.zInsert(ts);
		}else{
			// project event 
			ical=application.zcore.app.getAppCFC("event").getIcalCFC();
			projectDays=application.zcore.app.getAppData("event").optionStruct.event_config_project_recurrence_days;
			arrDate=ical.getRecurringDates(form.event_start_datetime, form.event_recur_ical_rules, form.event_excluded_date_list, projectDays);
			minutes=datediff("n", form.event_start_datetime, form.event_end_datetime);
			for(i=1;i LTE arraylen(arrDate);i++){
				startDate=arrDate[i];
				endDate=dateadd("n", minutes, startDate);
				ts={
					table:"event_recur",
					datasource:request.zos.zcoreDatasource,
					struct:{
						event_id:form.event_id,
						site_id:request.zos.globals.id,
						event_recur_datetime:dateformat(startDate, "yyyy-mm-dd")&" "&timeformat(startDate, "HH:mm:ss"),
						event_recur_start_datetime:dateformat(startDate, "yyyy-mm-dd")&" "&timeformat(startDate, "HH:mm:ss"),
						event_recur_end_datetime:dateformat(endDate, "yyyy-mm-dd")&" "&timeformat(endDate, "HH:mm:ss"),
						event_recur_updated_datetime:dateformat(now(), 'yyyy-mm-dd')&' '&timeformat(now(), 'HH:mm:ss'),
						event_recur_deleted:0
					}
				}
				application.zcore.functions.zInsert(ts);
			}
		}
	}

	if(uniqueChanged){
		application.zcore.app.getAppCFC("event").updateRewriteRuleEvent(form.event_id, oldURL);	
	}
	application.zcore.app.getAppCFC("event").searchReindexEvent(form.event_id, false);

	if(structkeyexists(request.zsession, 'event_return'&form.event_id)){
		a=request.zsession['event_return'&form.event_id];
		structdelete(request.zsession, 'event_return'&form.event_id);
		application.zcore.functions.zRedirect(a);
	}else{
		if(form.modalpopforced EQ 1){
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/getReturnEventRowHTML?event_id=#form.event_id#');
		}else{
			application.zcore.functions.zRedirect('/z/event/admin/manage-events/index?zsid=#request.zsid#');
		}
	}
	</cfscript>
</cffunction>


	

<cffunction name="add" localmode="modern" access="remote" roles="member">
	<cfscript>
	this.edit();
	</cfscript>
</cffunction>

<cffunction name="edit" localmode="modern" access="remote" roles="member">
	<cfscript> 
	var db=request.zos.queryObject; 
	var currentMethod=form.method;
	var htmlEditor=0;
	application.zcore.functions.zSetPageHelpId("10.2");
	application.zcore.adminSecurityFilter.requireFeatureAccess("Events");	
	if(application.zcore.functions.zso(form,'event_id') EQ ''){
		form.event_id = -1;
	}
	if(structkeyexists(form, 'return')){
		StructInsert(request.zsession, "event_return"&form.event_id, request.zos.CGI.HTTP_REFERER, true);		
	}

	db.sql="SELECT * FROM #db.table("event_calendar", request.zos.zcoreDatasource)#  
	WHERE site_id =#db.param(request.zos.globals.id)# and 
	event_calendar_deleted = #db.param(0)# 
	LIMIT #db.param(0)#, #db.param(1)#";
	qCalendar=db.execute("qCalendar");
	if(qCalendar.recordcount EQ 0){
		application.zcore.status.setStatus(request.zsid, "You must add a calendar first.", form, true);
		application.zcore.functions.zRedirect("/z/event/admin/manage-event-calendar/add?zsid=#request.zsid#");
	}

	db.sql="SELECT * FROM #db.table("event", request.zos.zcoreDatasource)# event 
	WHERE site_id =#db.param(request.zos.globals.id)# and 
	event_deleted = #db.param(0)# and 
	event_id=#db.param(form.event_id)#";
	qEvent=db.execute("qEvent"); 
	application.zcore.functions.zQueryToStruct(qEvent, form, 'event_calendar_id,event_category_id'); 
	application.zcore.functions.zStatusHandler(request.zsid,true);
	application.zcore.functions.zRequireJqueryUI();
	form.modalpopforced=application.zcore.functions.zso(form, 'modalpopforced',true, 0);
	if(form.modalpopforced EQ 1){
		application.zcore.skin.includeCSS("/z/a/stylesheets/style.css");
		application.zcore.functions.zSetModalWindow();
	}
	if(currentMethod EQ "add"){
		form.event_uid='';
		form.event_id="";
		form.event_file1="";
		form.event_file2="";
		form.event_image_library_id="";
		form.event_unique_url="";
	}
	</cfscript>
	<h2>
		<cfif currentMethod EQ "add">
			Add
			<cfscript>
			application.zcore.functions.zCheckIfPageAlreadyLoadedOnce();
			</cfscript>
		<cfelse>
			Edit
		</cfif> Event</h2>
		<p>* denotes required field.</p>
	<form action="/z/event/admin/manage-events/<cfif currentMethod EQ 'add'>insert<cfelse>update</cfif>?event_id=#form.event_id#" method="post">
		<input name="event_uid" type="hidden" value="#htmleditformat(application.zcore.functions.zso(form, 'event_uid'))#" />
		<input type="hidden" name="modalpopforced" value="#form.modalpopforced#" />
		<table style="width:100%;" class="table-list">  
			<tr>
				<th style="width:1%;">&nbsp;</th>
				<td><button type="submit" name="submitForm">Save</button>

					<cfif form.modalpopforced EQ 1>
						<button type="button" name="cancel" onclick="window.parent.zCloseModal();">Cancel</button>
					<cfelse>
						<cfscript>
						cancelLink="/z/event/admin/manage-events/index";
						</cfscript>
						<button type="button" name="cancel" onclick="window.location.href='#cancelLink#';">Cancel</button>
					</cfif>
				</td>
			</tr>
			<tr>
				<th>Calendar</th>
				<td>
					<cfscript>
					db.sql="select * from #db.table("event_calendar", request.zos.zcoreDatasource)# WHERE 
					site_id = #db.param(request.zos.globals.id)# and 
					event_calendar_deleted=#db.param(0)# 
					ORDER BY event_calendar_name ASC";
					qCalendar=db.execute("qCalendar"); 
					ts = StructNew();
					ts.name = "event_calendar_id"; 
					ts.size = 1; 
					ts.multiple = true; 
					ts.query = qCalendar;
					ts.queryLabelField = "event_calendar_name";
					ts.queryParseLabelVars = false; // set to true if you want to have a custom formated label
					ts.queryParseValueVars = false; // set to true if you want to have a custom formated value
					ts.queryValueField = "event_calendar_id"; 
					application.zcore.functions.zSetupMultipleSelect(ts.name, application.zcore.functions.zso(form, 'event_calendar_id', true, 0));
					application.zcore.functions.zInputSelectBox(ts);
					</cfscript> *
				</td>
			</tr>  
			<tr>
				<th>Name</th>
				<td><input type="text" name="event_name" style="width:500px;" value="#htmleditformat(form.event_name)#" /> *</td>
			</tr>  
			<tr>
				<th>Category</th>
				<td>
					<cfscript>
					db.sql="select * from #db.table("event_category", request.zos.zcoreDatasource)# WHERE 
					site_id = #db.param(request.zos.globals.id)# and 
					event_category_deleted=#db.param(0)# 
					ORDER BY event_category_name ASC";
					qCategory=db.execute("qCategory");

					ts = StructNew();
					ts.name = "event_category_id"; 
					ts.size = 1; 
					ts.multiple = true; 
					ts.query = qCategory;
					ts.queryLabelField = "event_category_name";
					ts.queryParseLabelVars = false; // set to true if you want to have a custom formated label
					ts.queryParseValueVars = false; // set to true if you want to have a custom formated value
					ts.queryValueField = "event_category_id"; 
					application.zcore.functions.zSetupMultipleSelect(ts.name, application.zcore.functions.zso(form, 'event_category_id', true, 0));
					application.zcore.functions.zInputSelectBox(ts);
					</cfscript> 
				</td>
			</tr>    
			<tr>
				<th>Summary</th>
				<td>
					<cfscript>
					htmlEditor = application.zcore.functions.zcreateobject("component", "/zcorerootmapping/com/app/html-editor");
					htmlEditor.instanceName	= "event_summary";
					htmlEditor.value			= form.event_summary;
					htmlEditor.width			= "#request.zos.globals.maximagewidth#px";
					htmlEditor.height		= 150;
					htmlEditor.create();
					</cfscript>   
				</td>
			</tr> 
			<tr>
				<th>Body Text</th>
				<td>
					<cfscript>
					htmlEditor = application.zcore.functions.zcreateobject("component", "/zcorerootmapping/com/app/html-editor");
					htmlEditor.instanceName	= "event_description";
					htmlEditor.value			= form.event_description;
					htmlEditor.width			= "#request.zos.globals.maximagewidth#px";
					htmlEditor.height		= 350;
					htmlEditor.create();
					</cfscript>   
				</td>
			</tr> 
			<cfscript>

			onChangeJavascript='';
			application.zcore.functions.zRequireTimePicker();  
			application.zcore.skin.addDeferredScript('  
				$("##event_start_datetime_time").timePicker({
					show24Hours: false,
					step: 15
				});
				$("##event_end_datetime_time").timePicker({
					show24Hours: false,
					step: 15
				});
				$( "##event_start_datetime_date" ).datepicker();
				$( "##event_end_datetime_date" ).datepicker();
			'); 
			</cfscript>
			<tr>
				<th>Start Date</th>
				<td>
					<input type="text" name="event_start_datetime_date" onchange="#onChangeJavascript#" onkeyup="#onChangeJavascript#" onpaste="#onChangeJavascript#" id="event_start_datetime_date" value="#htmleditformat(dateformat(form.event_start_datetime, 'mm/dd/yyyy'))#" size="9" />
					<input type="text" name="event_start_datetime_time" id="event_start_datetime_time" value="#htmleditformat(timeformat(form.event_start_datetime, 'HH:mm:ss'))#" size="9" />
					 * </td>
			</tr> 

			<tr>
				<th>End Date</th>
				<td><input type="text" name="event_end_datetime_date" onchange="#onChangeJavascript#" onkeyup="#onChangeJavascript#" onpaste="#onChangeJavascript#" id="event_end_datetime_date" value="#htmleditformat(dateformat(form.event_end_datetime, 'mm/dd/yyyy'))#" size="9" />
					<input type="text" name="event_end_datetime_time" id="event_end_datetime_time" value="#htmleditformat(timeformat(form.event_end_datetime, 'HH:mm:ss'))#" size="9" /> *
				</td>
			</tr>  
			<tr>
				<th>All Day Event?</th>
				<td>#application.zcore.functions.zInput_Boolean("event_allday")# (Yes, will hide the start/end times)</td>
			</tr> 

			<tr>
				<th>Timezone</th>
				<td><input type="text" name="event_timezone" value="#htmleditformat(form.event_timezone)#" /></td>
			</tr> 
			<tr>
				<th>Location Name</th>
				<td><input type="text" name="event_location" style="width:500px;" value="#htmleditformat(form.event_location)#" /></td>
			</tr> 
			<tr>
				<th>Address</th>
				<td><input type="text" name="event_address" style="width:500px;" value="#htmleditformat(form.event_address)#" /></td>
			</tr> 
			<tr>
				<th>Address 2</th>
				<td><input type="text" name="event_address2" style="width:500px;" value="#htmleditformat(form.event_address2)#" /></td>
			</tr> 
			<tr>
				<th>City</th>
				<td><input type="text" name="event_city" style="width:500px;" value="#htmleditformat(form.event_city)#" /></td>
			</tr> 
			<tr>
				<th>State</th>
				<td>#application.zcore.functions.zStateSelect("event_state", application.zcore.functions.zso(form, 'event_state'))#</td>
			</tr> 
			<tr>
				<th>Country</th>
				<td>#application.zcore.functions.zCountrySelect("event_country", application.zcore.functions.zso(form, 'event_country'))#</td>
			</tr> 
			<tr>
				<th>Zip/Postal Code</th>
				<td><input type="text" name="event_zip" value="#htmleditformat(form.event_zip)#" /></td>
			</tr> 
			<tr>
				<th>Web Site URL</th>
				<td><input type="text" name="event_website" style="width:500px;" value="#htmleditformat(form.event_website)#" /></td>
			</tr> 
			<tr>
				<th>File 1</th>
				<td><cfscript>
					ts={
						name:"event_file1"
					};
					application.zcore.functions.zInput_File(ts);
					</cfscript></td>
			</tr> 
			<tr>
				<th>File 1 Label</th>
				<td><input type="text" name="event_file1label" style="width:500px;" value="#htmleditformat(form.event_file1label)#" /></td>
			</tr> 
			<tr>
				<th>File 2</th>
				<td><cfscript>
					ts={
						name:"event_file2"
					};
					application.zcore.functions.zInput_File(ts);
					</cfscript></td>
			</tr> 
			<tr>
				<th>File 2 Label</th>
				<td><input type="text" name="event_file2label" style="width:500px;" value="#htmleditformat(form.event_file2label)#" /></td>
			</tr> 
			<tr>
				<th>Featured Event</th>
				<td>#application.zcore.functions.zInput_Boolean("event_featured", application.zcore.functions.zso(form, 'event_featured'))#</td>
			</tr>  
			<tr>
				<th>Recurring Event</th>
				<td><strong style="font-size:120%;"><span><a href="##" onclick="openRecurringEventOptions(); return false;">Edit</a> | Recurrence: <span id="recurringConfig1">
					<cfif form.event_recur_ical_rules NEQ "">Yes | 
						<cfscript>
						ical=application.zcore.app.getAppCFC("event").getIcalCFC();
						echo(ical.getIcalRuleAsPlainEnglish(form.event_recur_ical_rules));
						</cfscript>
					<cfelse>
						No
					</cfif>
				</span></strong>
				 </span>
				<input type="hidden" name="event_recur_ical_rules" id="event_recur_ical_rules" value="#htmleditformat(form.event_recur_ical_rules)#" />
				<input type="hidden" name="event_excluded_date_list" id="event_excluded_date_list" value="#htmleditformat(form.event_excluded_date_list)#" />
				<input type="hidden" name="event_recur_until_datetime" id="event_recur_until_datetime" value="#htmleditformat(form.event_recur_until_datetime)#" />
				<input type="hidden" name="event_recur_count" id="event_recur_count" value="#htmleditformat(form.event_recur_count)#" />
				<input type="hidden" name="event_recur_interval" id="event_recur_interval" value="#htmleditformat(form.event_recur_interval)#" />
				<input type="hidden" name="event_recur_frequency" id="event_recur_frequency" value="#htmleditformat(form.event_recur_frequency)#" />

				</td>
			</tr>  
			<!--- 
			http://www.farbeyondcode.com.127.0.0.2.xip.io/z/event/admin/recurring-event/index?event_start_datetime=04/30/2015%20&event_end_datetime=06/17/2015%20&event_recur_ical_rules=&ztv=0.33506121183745563
			 --->
			<script type="text/javascript">
			function openRecurringEventOptions(){
				var startDate=$("##event_start_datetime_date").val();
				var startTime=$("##event_start_datetime_time").val();
				var endDate=$("##event_end_datetime_date").val();
				var endTime=$("##event_end_datetime_time").val();
				var rules=$("##event_recur_ical_rules").val();
				var exclude=$("##event_excluded_date_list").val();
				var d={
					"event_start_datetime": escape(startDate+" "+startTime),
					"event_end_datetime": escape(endDate+" "+endTime), 
					"event_recur_ical_rules": escape(rules),
					"event_excluded_date_list": escape(exclude)
				};
				var a=[];
				for(var i in d){
					a.push(i+"="+d[i]);
				}
				zShowModalStandard('/z/event/admin/recurring-event/index?'+a.join("&"), zWindowSize.width-100, zWindowSize.height-100);

			}
			</script>
			<tr>
				<th style="width:1%; white-space:nowrap;">#application.zcore.functions.zOutputHelpToolTip("Photos","member.event.edit event_image_library_id")#</th>
				<td>
					<cfscript>
					ts=structnew();
					ts.name="event_image_library_id";
					ts.value=form.event_image_library_id;
					application.zcore.imageLibraryCom.getLibraryForm(ts);
					</cfscript>
				</td>
			</tr>

			<tr>
				<th style="width:1%; white-space:nowrap;">#application.zcore.functions.zOutputHelpToolTip("Photo Layout","member.event.edit event_image_library_layout")#</th>
				<td>
					<cfscript>
					ts=structnew();
					ts.name="event_image_library_layout";
					ts.value=form.event_image_library_layout;
					application.zcore.imageLibraryCom.getLayoutTypeForm(ts);
					</cfscript>
				</td>
			</tr>
			<tr>
				<th>Unique URL</th>
				<td><input type="text" name="event_unique_url" value="#htmleditformat(form.event_unique_url)#" /></td>
			</tr> 

			<!---          
          
event_generated - what is this?
event_reservation_enabled - not needed yet.
event_status - what is this?
 
Map Coordinates	Map Location Picker  
			 --->
			<tr>
				<th style="width:1%;">&nbsp;</th>
				<td><button type="submit" name="submitForm">Save</button>
					
					<cfif form.modalpopforced EQ 1>
						<button type="button" name="cancel" onclick="window.parent.zCloseModal();">Cancel</button>
					<cfelse>
						<cfscript>
						cancelLink="/z/event/admin/manage-events/index";
						</cfscript>
						<button type="button" name="cancel" onclick="window.location.href='#cancelLink#';">Cancel</button>
					</cfif>
				</td></td>
			</tr>
		</table>
	</form>
</cffunction>


<cffunction name="index" localmode="modern" access="remote" roles="member">
	<cfscript>
	db=request.zos.queryObject;

	application.zcore.functions.zRequireJqueryUI();
 	form.event_recur=application.zcore.functions.zso(form, 'event_recur');
 	form.event_start_date=application.zcore.functions.zso(form, 'event_start_date');
 	form.event_end_date=application.zcore.functions.zso(form, 'event_end_date');
 	form.event_searchtext=application.zcore.functions.zso(form, 'event_searchtext');
 	form.event_category_id=application.zcore.functions.zso(form, 'event_category_id');
 	form.event_calendar_id=application.zcore.functions.zso(form, 'event_calendar_id');
	form.showRecurring=application.zcore.functions.zso(form, 'showRecurring', true, 0);
	application.zcore.adminSecurityFilter.requireFeatureAccess("Manage Events");


	request.ical=application.zcore.app.getAppCFC("event").getIcalCFC();
	perpage=10;
	form.zIndex=application.zcore.functions.zso(form, 'zIndex', true, 1);
	if(form.zIndex LT 1){
		form.zIndex=1;
	}

	searchOn=false;
	application.zcore.functions.zSetPageHelpId("10.1");
	
	db.sql="select * from 
	#db.table("event", request.zos.zcoreDatasource)#";
	if(form.showRecurring EQ 1){
		db.sql&=" , 
		#db.table("event_recur", request.zos.zcoreDatasource)# WHERE 
		event.site_id = event_recur.site_id and 
		event.event_id = event_recur.event_id and 
		event_recur_deleted=#db.param(0)# and ";
	}else{
		db.sql&=" WHERE ";
	}
	db.sql&=" event.site_id = #db.param(request.zos.globals.id)# and 
	event_deleted=#db.param(0)# ";
	if(form.showRecurring EQ 1){
		if(form.event_start_date NEQ "" and isdate(form.event_start_date)){
			db.sql&=" and event_recur_end_datetime >= #db.param(dateformat(form.event_start_date, 'yyyy-mm-dd'))# ";
		}
		if(form.event_end_date NEQ "" and isdate(form.event_end_date)){
			db.sql&=" and event_recur_start_datetime <= #db.param(dateformat(form.event_end_date, 'yyyy-mm-dd'))# ";
		}
	}else{
		if(form.event_start_date NEQ "" and isdate(form.event_start_date)){
			db.sql&=" and event_end_datetime >= #db.param(dateformat(form.event_start_date, 'yyyy-mm-dd'))# ";
		}
		if(form.event_end_date NEQ "" and isdate(form.event_end_date)){
			db.sql&=" and event_start_datetime <= #db.param(dateformat(form.event_end_date, 'yyyy-mm-dd'))# ";
		}
	}
	if(form.event_recur EQ "1"){
		searchOn=true;
		db.sql&=" and event_recur_ical_rules <> #db.param('')# ";
	}
	if(form.event_searchtext NEQ ""){
		searchOn=true;
		db.sql&=" and concat(event.event_id, #db.param(' ')#, event_name, #db.param(' ')#, event_description)  like #db.param('%#form.event_searchtext#%')# ";
	}
	if(form.event_category_id NEQ ""){
		searchOn=true;
		db.sql&=" and CONCAT(#db.param(',')#,event_category_id, #db.param(',')#) LIKE #db.param('%,'&form.event_category_id&',%')# ";
	}
	if(form.event_calendar_id NEQ ""){
		searchOn=true;
		db.sql&=" and CONCAT(#db.param(',')#,event_calendar_id, #db.param(',')#) LIKE #db.param('%,'&form.event_calendar_id&',%')# ";
	}
	if(form.showRecurring EQ 1){
		db.sql&=" ORDER BY event_recur_start_datetime ASC, event_recur_end_datetime ASC";
	}else{
		db.sql&=" ORDER BY event_start_datetime ASC, event_end_datetime ASC";
	}
	db.sql&=" LIMIT #db.param((form.zIndex-1)*perpage)#, #db.param(perpage)# ";
	qList=db.execute("qList");

	db.sql="select count(event.event_id) count from 
	#db.table("event", request.zos.zcoreDatasource)#";
	if(form.showRecurring EQ 1){
		db.sql&=" , 
		#db.table("event_recur", request.zos.zcoreDatasource)# WHERE 
		event.site_id = event_recur.site_id and 
		event.event_id = event_recur.event_id and 
		event_recur_deleted=#db.param(0)# and ";
	}else{
		db.sql&=" WHERE ";
	}
	db.sql&=" event.site_id = #db.param(request.zos.globals.id)# and 
	event_deleted=#db.param(0)# ";
	if(form.showRecurring EQ 1){
		if(form.event_start_date NEQ "" and isdate(form.event_start_date)){
			db.sql&=" and event_recur_end_datetime >= #db.param(dateformat(form.event_start_date, 'yyyy-mm-dd'))# ";
		}
		if(form.event_end_date NEQ "" and isdate(form.event_end_date)){
			db.sql&=" and event_recur_start_datetime <= #db.param(dateformat(form.event_end_date, 'yyyy-mm-dd'))# ";
		}
	}else{
		if(form.event_start_date NEQ "" and isdate(form.event_start_date)){
			db.sql&=" and event_end_datetime >= #db.param(dateformat(form.event_start_date, 'yyyy-mm-dd'))# ";
		}
		if(form.event_end_date NEQ "" and isdate(form.event_end_date)){
			db.sql&=" and event_start_datetime <= #db.param(dateformat(form.event_end_date, 'yyyy-mm-dd'))# ";
		}
	}
	if(form.event_recur EQ "1"){
		db.sql&=" and event_recur_ical_rules <> #db.param('')# ";
	}
	if(form.event_searchtext NEQ ""){
		db.sql&=" and concat(event.event_id, #db.param(' ')#, event_name, #db.param(' ')#, event_description) like #db.param('%#form.event_searchtext#%')# ";
	}
	if(form.event_category_id NEQ ""){ 
		db.sql&=" and CONCAT(#db.param(',')#,event_category_id, #db.param(',')#) LIKE #db.param('%,'&form.event_category_id&',%')# ";
	}
	if(form.event_calendar_id NEQ ""){ 
		db.sql&=" and CONCAT(#db.param(',')#,event_calendar_id, #db.param(',')#) LIKE #db.param('%,'&form.event_calendar_id&',%')# ";
	}
	qCount=db.execute("qCount");
	
	request.eventCom=application.zcore.app.getAppCFC("event");
	request.eventCom.getAdminNavMenu();
	if(searchOn){
		echo('<h2>Manage Events | Search Results</h2>');
	}else{
		echo('<h2>Manage Events</h2>');
	}


	application.zcore.skin.addDeferredScript('   
		$( "##event_start_date" ).datepicker();
		$( "##event_end_date" ).datepicker();
	'); 
	</cfscript>

	<p><a href="/z/event/admin/manage-events/add">Add Event</a></p>
	<hr />
	<div style="width:100%; float:left;">
		<form action="/z/event/admin/manage-events/index" method="get">
		<div style="width:150px;margin-bottom:10px; float:left; "><h2>Search Events</h2>
		</div>
		<div style="width:170px; margin-bottom:10px;float:left;">
			Keyword:<br /> 
			<input type="text" name="event_searchtext" value="#form.event_searchtext#" style="width:150px; " />
		</div>
		<div style="width:90px;margin-bottom:10px;float:left;">
			Start: <br />
			<input type="text" name="event_start_date" id="event_start_date" value="#form.event_start_date#" style="width:70px; " />
		</div>
		<div style="width:90px;margin-bottom:10px;float:left;">
			End: <br />
			<input type="text" name="event_end_date" id="event_end_date" value="#form.event_end_date#" style="width:70px; " />
		</div>
		<div style="width:145px;margin-bottom:10px;float:left;">
			Only Recurring Events: <br />
			#application.zcore.functions.zInput_Boolean("event_recur")#
		</div>
		<div style="width:145px;margin-bottom:10px;float:left;">
			Show Recurring Dates: <br />
			#application.zcore.functions.zInput_Boolean("showRecurring")#
		</div>
		
		<div style="width:120px;margin-bottom:10px;float:left;">
			Calendar: <br />
			<cfscript>
			db.sql="select * from #db.table("event_calendar", request.zos.zcoreDatasource)# WHERE 
			site_id = #db.param(request.zos.globals.id)# and 
			event_calendar_deleted=#db.param(0)# 
			ORDER BY event_calendar_name ASC";
			qCalendar=db.execute("qCalendar"); 
			ts = StructNew();
			ts.name = "event_calendar_id"; 
			ts.size = 1; 
			ts.inlineStyle="width:100px;";
			ts.multiple = false; 
			ts.query = qCalendar;
			ts.queryLabelField = "event_calendar_name";
			ts.queryParseLabelVars = false; // set to true if you want to have a custom formated label
			ts.queryParseValueVars = false; // set to true if you want to have a custom formated value
			ts.queryValueField = "event_calendar_id"; 
			//application.zcore.functions.zSetupMultipleSelect(ts.name, application.zcore.functions.zso(form, 'event_calendar_id', true, 0));
			application.zcore.functions.zInputSelectBox(ts);
			</cfscript>
		</div>
		<div style="width:120px;margin-bottom:10px;float:left;">
			Category: <br />
			<cfscript>
			db.sql="select * from #db.table("event_category", request.zos.zcoreDatasource)# WHERE 
			site_id = #db.param(request.zos.globals.id)# and 
			event_category_deleted=#db.param(0)# 
			ORDER BY event_category_name ASC";
			qCategory=db.execute("qCategory");

			ts = StructNew();
			ts.name = "event_category_id"; 
			ts.size = 1; 
			ts.multiple = false; 
			ts.inlineStyle="width:100px;";
			ts.query = qCategory;
			ts.queryLabelField = "event_category_name";
			ts.queryParseLabelVars = false; // set to true if you want to have a custom formated label
			ts.queryParseValueVars = false; // set to true if you want to have a custom formated value
			ts.queryValueField = "event_category_id"; 
			//application.zcore.functions.zSetupMultipleSelect(ts.name, application.zcore.functions.zso(form, 'event_category_id', true, 0));
			application.zcore.functions.zInputSelectBox(ts);
			</cfscript> 


		</div>
		<div style="width:150px;margin-bottom:10px;float:left;">&nbsp;<br />
			<input type="submit" name="search1" value="Search" />
			<cfif searchOn>
				<input type="button" name="search2" value="Show All" onclick="window.location.href='/z/event/admin/manage-events/index';">
			</cfif>
		</div>
		</form>
	</div>
	<hr />
	<cfscript>
	searchStruct = StructNew(); 
	searchStruct.showString = "Results ";
	searchStruct.url = "/z/event/admin/manage-events/index?event_searchtext=#form.event_searchtext#&event_calendar_id=#form.event_calendar_id#&event_category_id=#form.event_category_id#&event_start_date=#form.event_start_date#&event_end_date=#form.event_end_date#&event_recur=#form.event_recur#&showRecurring=#form.showRecurring#";
	searchStruct.indexName = "zIndex";
	searchStruct.buttons = 5;
	searchStruct.count = qCount.count;
	searchStruct.index = form.zIndex;
	searchStruct.perpage = perpage; 
	
	searchNav = application.zcore.functions.zSearchResultsNav(searchStruct);
	if(qCount.count GT perpage){
		echo(searchNav);
	}

	request.uniqueEvent={};
	</cfscript>
	<table class="table-list">
		<tr>
			<th>ID</th>
			<th>Name</th>
			<th>Start Date</th>
			<th>End Date</th>
			<th>Recurring</th>
			<th>Last Updated</th>
			<th>Admin</th>
		</tr>
		<cfscript>
		for(row in qList){
			echo('<tr>');
			getEventRowHTML(row);
			echo('</tr>');
			request.uniqueEvent[row.event_id]=true;
		}
		</cfscript>  
	</table>
	<cfscript>
	
	if(qList.recordcount EQ 0){
		echo('<p>No events found</p>');
	}
	if(qCount.count GT perpage){
		echo(searchNav);
	}
	</cfscript>
</cffunction>

<cffunction name="getReturnEventRowHTML" localmode="modern" access="remote" roles="member">
	<cfscript>
	var db=request.zos.queryObject; 
	db.sql="SELECT * FROM #db.table("event", request.zos.zcoreDatasource)# event 
	WHERE site_id =#db.param(request.zos.globals.id)# and 
	event_deleted = #db.param(0)# and 
	event_id=#db.param(form.event_id)#";
	qEvent=db.execute("qEvent"); 
	
	request.ical=application.zcore.app.getAppCFC("event").getIcalCFC();
	request.eventCom=application.zcore.app.getAppCFC("event");
	request.uniqueEvent={};
	savecontent variable="rowOut"{
		for(row in qEvent){
			getEventRowHTML(row);
			request.uniqueEvent[row.event_id]=true;
		}
	}

	echo('done.<script type="text/javascript">
	window.parent.zReplaceTableRecordRow("#jsstringformat(rowOut)#");
	window.parent.zCloseModal();
	</script>');
	abort;
	</cfscript>
</cffunction>
	
<cffunction name="getEventRowHTML" localmode="modern" access="public" roles="member">
	<cfargument name="row" type="struct" required="yes">
	<cfscript>
	row=arguments.row;
	echo('
		<td>#row.event_id#</td>
		<td>#row.event_name#</td>');
	if(structkeyexists(row, 'event_recur_start_datetime')){
		echo('<td>#dateformat(row.event_recur_start_datetime, 'm/d/yyyy')#</td>
		<td>#dateformat(row.event_recur_end_datetime, 'm/d/yyyy')#</td>');
	}else{
		echo('<td>#dateformat(row.event_start_datetime, 'm/d/yyyy')#</td>
		<td>#dateformat(row.event_end_datetime, 'm/d/yyyy')#</td>');
	}
		echo('<td>');
	if(row.event_recur_ical_rules NEQ ""){
		echo(request.ical.getIcalRuleAsPlainEnglish(row.event_recur_ical_rules));
	}else{
		echo('No');
	}
	echo('</td>
		<td>#application.zcore.functions.zGetLastUpdatedDescription(row.event_updated_datetime)#</td>
		<td>');
		if(not structkeyexists(request.uniqueEvent, row.event_id)){
			echo('<a href="#request.eventCom.getEventURL(row)#" target="_blank">View</a> | 
			<a href="/z/event/admin/manage-events/add?event_id=#row.event_id#">Copy</a> | ');

			if(row.event_recur_ical_rules NEQ ""){
				echo('<a href="/z/event/admin/manage-events/edit?event_id=#row.event_id#&return=1">Edit</a>');
				echo(' | <a href="/z/event/admin/manage-events/delete?event_id=#row.event_id#&amp;return=1">Delete</a>');
			}else{
				echo('<a href="/z/event/admin/manage-events/edit?event_id=#row.event_id#&amp;modalpopforced=1" onclick="zTableRecordEdit(this);  return false;">Edit</a>');
			echo(' | 
			<a href="##" onclick="zDeleteTableRecordRow(this, ''/z/event/admin/manage-events/delete?event_id=#row.event_id#&amp;returnJson=1&amp;confirm=1''); return false;">Delete</a>');
			}
		}else{
			echo('Duplicate of Event #row.event_id# ');
		}
	echo('</td>');

	</cfscript>
</cffunction>
</cfoutput>
</cfcomponent>