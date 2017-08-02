<cfcomponent implements="zcorerootmapping.interface.databaseVersion">
<cfoutput>
<cffunction name="getChangedTableArray" localmode="modern" access="public" returntype="array">
	<cfscript>
	arr1=[];
	return arr1;
	</cfscript>
</cffunction>

<cffunction name="executeUpgrade" localmode="modern" access="public" returntype="boolean">
	<cfargument name="dbUpgradeCom" type="component" required="yes">
	<cfscript>        
  
	if(!arguments.dbUpgradeCom.executeQuery(this.datasource, "ALTER TABLE `site_option`   
  ADD COLUMN `site_option_use_original_value` CHAR(1) DEFAULT '0' NOT NULL AFTER `site_option_character_width`")){		return false;	}
	 

	return true;
	</cfscript>
</cffunction>
</cfoutput>
</cfcomponent>