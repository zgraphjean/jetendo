<?php
require("library.php");
set_time_limit(70);
/*
Command reference:
convertHTMLTOPDF#chr(9)#site_short_domain#chr(9)#htmlFile#chr(9)#pdfFile
getDiskUsage#chr(9)#absolutePath
getFileMD5Sum#chr(9)#absoluteFilePath
getImageMagickIdentify#chr(9)#absoluteFilePath
getImageMagickConvertResize#chr(9)&#resizeWidth#chr(9)#resizeHeight#chr(9)#cropWidth#chr(9)#cropHeight#chr(9)#cropXOffset#chr(9)#cropYOffset#chr(9)#absoluteSourceFilePath#chr(9)#absoluteDestinationFilePath
getImageMagickConvertApplyMask#chr(9)#absoluteImageInputPath#chr(9)#absoluteImageOutputPath
getUserList
getScryptCheck#chr(9)#password#chr(9)#hashedPassword
getScryptEncrypt#chr(9)#password
getSystemIpList
getNewerCoreMVCFiles
gzipFilePath#chr(9)#absoluteFilePath
importSite#chr(9)#siteDomain#chr(9)#importDirName#chr(9)#tarFileName#chr(9)#tarUploadFileName
installThemeToSite#chr(9)#themeName#chr(9)#absoluteSiteHomedir
mysqlDumpTable#chr(9)#schema#chr(9)#table
mysqlRestoreTable#chr(9)#schema#chr(9)#table
publishNginxSiteConfig#chr(9)#site_id
renameSite#chr(9)#oldSiteShortDomain#chr(9)#newSiteShortDomain
sslDeleteCertificate#chr(9)#ssl_hash
sslGenerateKeyAndCSR#chr(9)#serializedJson
sslInstallCertificate#chr(9)#serializedJson
sslSavePublicKeyCertificates#chr(9)#serializedJson
tarZipFilePath#chr(9)#tarAbsoluteFilePath#chr(9)#changeToAbsoluteDirectory#chr(9)#absolutePathToTar
tarZipSitePath#chr(9)#siteDomain#chr(9)#curDate
tarZipSiteUploadPath#chr(9)#siteDomain#chr(9)#curDate
verifySitePaths
*/

function processContents($contents){
	$a=explode("\t", $contents);
	$contents=array_shift($a);
	if($contents == "getUserList"){
		return getUserList();
	}else if($contents =="getNewerCoreMVCFiles"){
		return getNewerCoreMVCFiles();
	}else if($contents =="getSystemIpList"){
		return getSystemIpList();
	}else if($contents =="getFileMD5Sum"){
		return getFileMD5Sum($a);
	}else if($contents =="getDiskUsage"){
		return getDiskUsage($a);
	}else if($contents =="tarZipFilePath"){
		return tarZipFilePath($a);
	}else if($contents =="tarZipSitePath"){
		return tarZipSitePath($a);
	}else if($contents =="tarZipSiteUploadPath"){
		return tarZipSiteUploadPath($a);
	}else if($contents =="untarZipSiteImportPath"){
		return untarZipSiteImportPath($a);
	}else if($contents =="importSite"){
		return importSite($a);
	}else if($contents =="tarZipGlobalDatabase"){
		return tarZipGlobalDatabase($a);
	}else if($contents =="gzipFilePath"){
		return gzipFilePath($a);
	}else if($contents =="getImageMagickIdentify"){
		return getImageMagickIdentify($a);
	}else if($contents =="getImageMagickConvertResize"){
		return getImageMagickConvertResize($a);
	}else if($contents =="getImageMagickConvertApplyMask"){
		return getImageMagickConvertApplyMask($a);
	}else if($contents =="getScryptCheck"){
		return getScryptCheck($a);
	}else if($contents =="getScryptEncrypt"){
		return getScryptEncrypt($a);
	}else if($contents =="renameSite"){
		return renameSite($a);
	}else if($contents =="verifySitePaths"){
		return verifySitePaths();
	}else if($contents =="installThemeToSite"){
		return installThemeToSite($a);
	}else if($contents =="mysqlDumpTable"){
		return mysqlDumpTable($a);
	}else if($contents =="mysqlRestoreTable"){
		return mysqlRestoreTable($a);
	}else if($contents =="convertHTMLTOPDF"){
		return convertHTMLTOPDF($a);
	}else if($contents =="reloadBindZone"){
		return reloadBindZone($a);
	}else if($contents =="reloadBind"){
		return reloadBind($a);
	}else if($contents =="notifyBindZone"){
		return notifyBindZone($a);
	}else if($contents =="publishNginxSiteConfig"){
		return publishNginxSiteConfig($a);
	}else if($contents =="sslInstallCertificate"){
		return sslInstallCertificate($a);
	}else if($contents =="sslGenerateKeyAndCSR"){
		return sslGenerateKeyAndCSR($a);
	}else if($contents =="sslSavePublicKeyCertificates"){
		return sslSavePublicKeyCertificates($a);
	}else if($contents =="sslDeleteCertificate"){
		return sslDeleteCertificate($a);
	}
	return "";
}
function sslDeleteCertificate($a){
	$rs=new stdClass();
	$rs->success=true;
	if(count($a) != 1){
		$rs->success=false;
		$rs->errorMessage="1 argument is required: ssl_hash.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$ssl_hash=$a[0];
	if(strpos($ssl_hash, "/") !== FALSE || strpos($ssl_hash, "\\") !== FALSE){
		$rs->success=false;
		$rs->errorMessage="ssl_hash can't contain slashes.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$nginxSSLPath=get_cfg_var("jetendo_nginx_ssl_path");
	if($nginxSSLPath == ""){
		$rs->success=false;
		$rs->errorMessage="jetendo_nginx_ssl_path is not defined.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$currentPath=$nginxSSLPath.$ssl_hash."/";
	if(is_dir($currentPath)){
		$cmd="/bin/rm -rf ".escapeshellarg($currentPath);
		`$cmd`;
	}
	return json_encode($rs);
}

function sslInstallCertificate($a){
	$rs=new stdClass();
	$rs->success=true;
	if(count($a) != 1){
		$rs->success=false;
		$rs->errorMessage="1 argument is required: serializedJson.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$js=json_decode($a[0]);
	if(strpos($js->ssl_hash, "/") !== FALSE || strpos($js->ssl_hash, "\\") !== FALSE){
		$rs->success=false;
		$rs->errorMessage="ssl_hash can't contain slashes.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$nginxSSLPath=get_cfg_var("jetendo_nginx_ssl_path");
	if($nginxSSLPath == ""){
		$rs->success=false;
		$rs->errorMessage="jetendo_nginx_ssl_path is not defined.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$currentPath=$nginxSSLPath.$js->ssl_hash."/";
	if(!is_dir($currentPath)){
		mkdir($currentPath, 0400, true);
	}
	$currentPath.=$js->site_id;

	file_put_contents($currentPath.".key", $js->ssl_private_key);
	$cmd="/usr/bin/openssl rsa -in ".escapeshellarg($currentPath.".key")." -text -noout | /bin/grep 'Private-Key:' ";
	$ssl_key_size=trim(str_replace(" bit)", "", str_replace("Private-Key: (", "",`$cmd`)));
	if($ssl_key_size != "" && $ssl_key_size <2048){
		$rs->success=false;
		$rs->errorMessage="The Key Size must be 2048 or higher. It was ".$ssl_key_size;
		echo($rs->errorMessage."\n");
		sslDeleteCertificate(array($js->ssl_hash));
		return json_encode($rs);
	}
	file_put_contents($currentPath.".crt", $js->ssl_public_key);
	$cmd="/usr/bin/openssl x509 -in ".escapeshellarg($currentPath.".crt")." -noout -enddate";
	$r2=trim(str_replace("notAfter=", "",`$cmd`));
	if($r2 == ""){
		$rs->success=false;
		$rs->errorMessage="Public key is not valid. Unable to parse expiration date.";
		echo($rs->errorMessage."\n");
		sslDeleteCertificate(array($js->ssl_hash));
		return json_encode($rs);
	}

	$cmd="/usr/bin/openssl x509 -noout -subject -in ".escapeshellarg($currentPath.".crt");
	$crtResult=str_replace("\t", "", `$cmd`)."/";
	$cnPos2=strpos($crtResult, "/CN=");
	$cnPosEnd2=strpos($crtResult, "/", $cnPos2+1);
	if($cnPos2 !== FALSE && $cnPosEnd2 !== FALSE){
	}else{
		$rs->success=false;
		$rs->errorMessage="Unable to parse the common name from the public certificate. It may be invalid.".$cnPos2."|".$cnPosEnd2;
		echo($rs->errorMessage."\n");
		sslDeleteCertificate(array($js->ssl_hash));
		return json_encode($rs);
	}
	file_put_contents($currentPath.".crt", $js->ssl_public_key."\n".$js->ssl_intermediate_certificate."\n".$js->ssl_ca_certificate);
	$arrCSR=explode("/", $crtResult);
	$arrCSR2=array();
	for($i=0;$i<count($arrCSR);$i++){
		$arr1=explode("=", $arrCSR[$i]);
		$arrCSR2[$arr1[0]]=$arr1[1];
	}
	$rs->success=true;
	$rs->ssl_key_size=$ssl_key_size;
	$rs->csrData=$arrCSR2;
	$rs->ssl_expiration_datetime=date_parse($r2);
	return json_encode($rs);
}

function sslGenerateKeyAndCSR($a){
	$rs=new stdClass();
	$rs->success=true;
	if(count($a) != 1){
		$rs->success=false;
		$rs->errorMessage="1 argument is required: serializedJson.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$js=json_decode($a[0]);
	if(strpos($js->ssl_hash, "/") !== FALSE || strpos($js->ssl_hash, "\\") !== FALSE){
		$rs->success=false;
		$rs->errorMessage="ssl_hash can't contain slashes.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}

	$nginxSSLPath=get_cfg_var("jetendo_nginx_ssl_path");
	if($nginxSSLPath == ""){
		$rs->success=false;
		$rs->errorMessage="jetendo_nginx_ssl_path is not defined.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$currentPath=$nginxSSLPath.$js->ssl_hash."/";
	if(!is_dir($currentPath)){
		mkdir($currentPath, 0400, true);
	}
	if($js->ssl_key_size != "" && $js->ssl_key_size <2048){
		$rs->success=false;
		$rs->errorMessage="The Key Size must be 2048 or higher. It was ".$js->ssl_key_size;
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$currentPath.=$js->site_id;
	if($js->ssl_selfsign == "1"){
		$cmd="/usr/bin/openssl req -x509 -nodes -days ".escapeshellarg($js->ssl_selfsign_days)." -newkey ".escapeshellarg("rsa:".$js->ssl_key_size)." -keyout ".escapeshellarg($currentPath.".key")." -out ".escapeshellarg($currentPath.".crt")." -subj ".escapeshellarg("/C=$js->ssl_country/ST=$js->ssl_state/L=$js->ssl_city/O=$js->ssl_organization/OU=$js->ssl_organization_unit/CN=$js->ssl_common_name/E=$js->ssl_email");
		$r2=`$cmd`;
		if(!file_exists($currentPath.".key")){
			$rs->success=false;
			$rs->errorMessage="Failed to generate private key: ".$r;
			echo($rs->errorMessage."\n");
			sslDeleteCertificate(array($js->ssl_hash));
			return json_encode($rs);
		}
		if(!file_exists($currentPath.".crt")){
			$rs->success=false;
			$rs->errorMessage="Failed to generate public key: ".$r;
			echo($rs->errorMessage."\n");
			sslDeleteCertificate(array($js->ssl_hash));
			return json_encode($rs);
		}
		$rs->ssl_public_key=file_get_contents($currentPath.".crt");
		$cmd="/usr/bin/openssl x509 -in ".escapeshellarg($currentPath.".crt")." -noout -enddate";
		$r2=trim(str_replace("notAfter=", "",`$cmd`));
		if($r2 == ""){
			$rs->success=false;
			$rs->errorMessage="Public key is not valid. Unable to parse expiration date.";
			echo($rs->errorMessage."\n");
			sslDeleteCertificate(array($js->ssl_hash));
			return json_encode($rs);
		}
		$rs->ssl_expiration_datetime=date_parse($r2);
	}else{
		$cmd="/usr/bin/openssl genrsa -out ".escapeshellarg($currentPath.".key")." ".escapeshellarg($js->ssl_key_size);
		$r=`$cmd`;
		if(!file_exists($currentPath.".key")){
			$rs->success=false;
			$rs->errorMessage="Failed to generate private key: ".$r;
			echo($rs->errorMessage."\n");
			sslDeleteCertificate(array($js->ssl_hash));
			return json_encode($rs);
		}
		$cmd="/usr/bin/openssl req -new -key ".escapeshellarg($currentPath.".key")." -out ".escapeshellarg($currentPath.".csr")." -subj ".escapeshellarg("/C=$js->ssl_country/ST=$js->ssl_state/L=$js->ssl_city/O=$js->ssl_organization/OU=$js->ssl_organization_unit/CN=$js->ssl_common_name/E=$js->ssl_email");
		$r2=`$cmd`;
		if(!file_exists($currentPath.".csr")){
			$rs->success=false;
			$rs->errorMessage="Failed to generate CSR file: ".$r2;
			echo($rs->errorMessage."\n");
			sslDeleteCertificate(array($js->ssl_hash));
			return json_encode($rs);
		}
	}
	if(file_exists($currentPath.".csr")){
		$rs->ssl_csr=file_get_contents($currentPath.".csr");
	}else{
		$rs->ssl_csr="";
	}
	return json_encode($rs);
}

function sslSavePublicKeyCertificates($a){
	$rs=new stdClass();
	$rs->success=true;

	if(count($a) != 1){
		$rs->success=true;
		$rs->errorMessage="1 argument is required: serializedJson.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$js=json_decode($a[0]);
	if(strpos($js->ssl_hash, "/") !== FALSE || strpos($js->ssl_hash, "\\") !== FALSE){
		$rs->success=false;
		$rs->errorMessage="ssl_hash can't contain slashes.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$nginxSSLPath=get_cfg_var("jetendo_nginx_ssl_path");
	if($nginxSSLPath == ""){
		$rs->success=false;
		$rs->errorMessage="jetendo_nginx_ssl_path is not defined.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$currentPath=$nginxSSLPath.$js->ssl_hash."/";
	if(!is_dir($currentPath)){
		mkdir($currentPath, 0400, true);
	}
	$currentPath.=$js->site_id;

	file_put_contents($currentPath.".crt", $js->ssl_public_key);
	$cmd="/usr/bin/openssl x509 -in ".escapeshellarg($currentPath.".crt")." -noout -enddate";
	$r2=trim(str_replace("notAfter=", "",`$cmd`));
	if($r2 == ""){
		$rs->success=false;
		$rs->errorMessage="Public key is not valid. Unable to parse expiration date.";
		echo($rs->errorMessage."\n");
		sslDeleteCertificate(array($js->ssl_hash));
		return json_encode($rs);
	}


	$cmd="/usr/bin/openssl req -noout -subject -in ".escapeshellarg($currentPath.".csr");
	$csrResult=str_replace("\t", "", `$cmd`)."/";
	$cmd="/usr/bin/openssl x509 -noout -subject -in ".escapeshellarg($currentPath.".crt");
	$crtResult=str_replace("\t", "", `$cmd`)."/";
	file_put_contents($currentPath.".crt", $js->ssl_public_key."\n".$js->ssl_intermediate_certificate."\n".$js->ssl_ca_certificate);

	$cnPos=strpos($csrResult, "/CN=");
	$cnPosEnd=strpos($csrResult, "/", $cnPos+1);
	if($cnPos !== FALSE && $cnPosEnd !== FALSE){
		$cnPos2=strpos($crtResult, "/CN=");
		$cnPosEnd2=strpos($crtResult, "/", $cnPos2+1);
		if($cnPos2 !== FALSE && $cnPosEnd2 !== FALSE){
			$cn1=substr($csrResult, $cnPos+4, $cnPosEnd-($cnPos+4));
			$cn2=substr($crtResult, $cnPos2+4, $cnPosEnd2-($cnPos2+4));
			if($cn1 != $cn2){
				$rs->success=false;
				$rs->errorMessage="The public certificate's common name: ".$cn2." doesn't match CSR's common name: ".$cn1;
				echo($rs->errorMessage."\n");
				sslDeleteCertificate(array($js->ssl_hash));
				return json_encode($rs);
			}
		}else{
			$rs->success=false;
			$rs->errorMessage="Unable to parse the common name from the public certificate. It may be invalid.";
			sslDeleteCertificate(array($js->ssl_hash));
			echo($rs->errorMessage."\n");
			return json_encode($rs);
		}
	}else{
		$rs->success=false;
		$rs->errorMessage="Unable to parse the common name from the CSR certificate. It may be invalid.";
		echo($rs->errorMessage."\n");
		sslDeleteCertificate(array($js->ssl_hash));
		return json_encode($rs);
	}
	$rs->success=true;
	$rs->ssl_expiration_datetime=date_parse($r2);
	return json_encode($rs);
}

function reloadBindZone($a){
	set_time_limit(30);
	if(count($a) != 1){
		echo "1 argument is required: zoneName.\n";
		return "0";
	}
	$zoneName=$a[0];
	$cmd="/usr/sbin/rndc reload ".escapeshellarg($zoneName);
	`$cmd`;

	// TODO: this might be optional - need to test it
	//$cmd="/usr/sbin/rndc notify ".escapeshellarg($zoneName);
	//`$cmd`;
	return "1";
}

function notifyBindZone($a){
	set_time_limit(30);
	if(count($a) != 1){
		echo "1 argument is required: zoneName.\n";
		return "0";
	}
	$zoneName=$a[0];
	$cmd="/usr/sbin/rndc notify zone ".escapeshellarg($zoneName);
	`$cmd`;
	return "1";
}

function reloadBind($a){
	set_time_limit(30);
	$cmd="/usr/sbin/rndc reload";
	`$cmd`;

	// TODO: It's possible this didn't send the notify messages. Will have to test.
	return "1";
}

function convertHTMLTOPDF($a){
	set_time_limit(30);
	if(count($a) != 3){
		echo "3 arguments are required: site_short_domain, absoluteFilePath and htmlWithoutBreaksOrTabs.\n";
		return "0";
	}
	$site_short_domain=$a[0];
	$htmlFile=$a[1];
	$pdfFile=$a[2];
	$sitePath=zGetDomainWritableInstallPath($site_short_domain);
	if(!is_dir($sitePath)){
		echo "sitePath doesn't exist: ".$sitePath."\n";
		return "0";
	}
	if($htmlFile == ""){
		echo "htmlFile is a required argument.\n";
		return "0";
	}
	if($pdfFile == ""){
		echo "pdfFile is a required argument.\n";
		return "0";
	}
	$pdfFile=getAbsolutePath($pdfFile);
	if(substr($pdfFile, 0, strlen($sitePath)) != $sitePath){
		echo "pdfFile, ".$pdfFile.", must be in the sites-writable directory of the current domain, ".$sitePath.".\n";
		return "0";
	}
	$parentDir=dirname($pdfFile);
	if(!is_dir($parentDir)){
		echo "parent directory, ".$dirname($pdfFile).", doesn't exist.\n";
		return "0";
	}
	if(substr($htmlFile, 0, 5) == "http:" || substr($htmlFile, 0, 6) == "https:"){
		echo "htmlFile can't be a URL for security reasons";
		return "0";
		/*
		Maybe allow urls with more validation later.
			Must prevent other ports
			Prevent connections to IPs
			Prevent localhost and other local host names.
			More?
		if(strpos(substr($htmlFile, 6), ":") !== FALSE){
			echo "htmlFile must be port 80 or 443.  No custom ports allowed for security.";
			return "0";
		}
		$cmd="/usr/local/bin/wkhtmltopdf ".escapeshellarg($htmlFile)." ".escapeshellarg($pdfFile);
		*/
	}else{
		$htmlFile=getAbsolutePath($htmlFile);
		if(substr($htmlFile, 0, strlen($sitePath)) != $sitePath){
			echo "htmlFile, ".$htmlFile.", must be in the sites-writable directory of the current domain, ".$sitePath.".\n";
			return "0";
		}
		// if we ever allow use to edit the html, we should parse the html for links that don't match site_short_domain.
		$cmd="/usr/local/bin/wkhtmltopdf --disable-javascript --disable-local-file-access ".escapeshellarg($htmlFile)." ".escapeshellarg($pdfFile);
	}
	if(file_exists($pdfFile)){
		unlink($pdfFile);
	}
	`$cmd`;
	if(file_exists($pdfFile)){
		chown($pdfFile, get_cfg_var("jetendo_www_user"));
		chgrp($pdfFile, get_cfg_var("jetendo_www_user"));
		chmod($pdfFile, 0660);
		return "1";
	}else{
		return "0";
	}
}

function mysqlDumpTable($a){
	set_time_limit(1000);
	if(count($a) != 2){
		echo "2 arguments are required: schema and table.\n";
		return "0";
	}
	if($a[0] == ""){
		echo "schema is a required argument.\n";
		return "0";
	}
	if($a[1] == ""){
		echo "table is a required argument.\n";
		return "0";
	}
	$schema=$a[0];
	$table=$a[1];
	
	if(!checkMySQLPrivileges()){
		return "0";
	}
	$path=get_cfg_var("jetendo_share_path")."database/backup/".$schema.".".$table.".sql";
	@unlink($path);
	$cmd="/usr/bin/mysqldump -h ".escapeshellarg(get_cfg_var("jetendo_mysql_default_host"))." -u ".
	escapeshellarg(get_cfg_var("jetendo_mysql_default_user"))." --password=".escapeshellarg(get_cfg_var("jetendo_mysql_default_password")).
	" --quick --single-transaction --opt ".escapeshellarg($schema)." ".escapeshellarg($table)." 2>&1 > $path";
	echo $cmd."\n";
	$r=`$cmd`;
	echo $r."\n";
	if(file_exists($path)){
		chown($path, get_cfg_var("jetendo_www_user"));
		chgrp($path, get_cfg_var("jetendo_www_user"));
		chmod($path, 0660);
		if(filesize($path)){
			return "1";
		}else{
			echo "Filesize was zero: ".$path." | There may be a permissions problem.\n";
			return "0";
		}
	}else{
		return "0";
	}
}
function mysqlRestoreTable($a){
	set_time_limit(1000);
	if(count($a) != 2){
		echo "2 arguments are required: schema and table.\n";
		return "0";
	}
	if($a[0] == ""){
		echo "schema is a required argument.\n";
		return "0";
	}
	if($a[1] == ""){
		echo "table is a required argument.\n";
		return "0";
	}
	if(!checkMySQLPrivileges()){
		return "0";
	}

	$schema=$a[0];
	$table=$a[1];
	$path=get_cfg_var("jetendo_share_path")."database/backup/".$schema.".".$table.".sql";
	$cmd="/usr/bin/mysql -h ".escapeshellarg(get_cfg_var("jetendo_mysql_default_host"))." -u ".
	escapeshellarg(get_cfg_var("jetendo_mysql_default_user"))." --password=".escapeshellarg(get_cfg_var("jetendo_mysql_default_password")).
	" -D ".escapeshellarg($schema)." < ".escapeshellarg($path);
	$r=`$cmd`;
	echo $r."\n";
	echo $cmd;
	return "1";
}

function renameSite($a){
	if(count($a) != 2){
		echo "2 arguments are required: siteShortDomainSource and siteShortDomainDestination.\n";
		return "0";
	}
	if($a[0] == ""){
		echo "The siteShortDomainSource is a required argument.\n";
		return "0";
	}
	if($a[1] == ""){
		echo "The siteShortDomainDestination is a required argument.\n";
		return "0";
	}
	$siteShortDomainSource=zGetDomainInstallPath($a[0]);
	$siteShortDomainDestination=zGetDomainInstallPath($a[1]);

	if($siteShortDomainSource == "" || !is_dir($siteShortDomainSource)){
		echo "The site absolute directory doesn't exist: ".$siteShortDomainSource."\n";
		return "0";
	}
	$found=false;
	if(substr($siteShortDomainSource, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "An attempt to break out of the sites directory was detected: ".$siteShortDomainSource."\n";
		return "0";
	}


	$siteWritableShortDomainSource=zGetDomainWritableInstallPath($a[0]);
	$siteWritableShortDomainDestination=zGetDomainWritableInstallPath($a[1]);
	if($siteShortDomainSource == "" || !is_dir($siteWritableShortDomainSource)){
		echo "The sites-writable absolute directory doesn't exist: ".$siteWritableShortDomainSource."\n";
		return "0";
	}
	$found=false;
	if(substr($siteWritableShortDomainSource, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "An attempt to break out of the sites directory was detected: ".$siteWritableShortDomainSource."\n";
		return "0";
	}
	system("/bin/mv -f ".escapeshellarg($siteShortDomainSource)." ".escapeshellarg($siteShortDomainDestination));
	system("/bin/mv -f ".escapeshellarg($siteWritableShortDomainSource)." ".escapeshellarg($siteWritableShortDomainDestination));
	return "1";
}

function verifySitePaths(){
	set_time_limit(300);
	// forces site root directories to exist with correct permissions
	$fail=false;
	$cmysql2=new mysqli(get_cfg_var("jetendo_mysql_default_host"),get_cfg_var("jetendo_mysql_default_user"), get_cfg_var("jetendo_mysql_default_password"), zGetDatasource());
	if($cmysql2->error != ""){ 
		$fail=true;
		array_push($arrError, "db connect error:".$cmysql2->error);	
	}
	if(!$fail){
		$r=$cmysql2->query("select * from site where site_active='1' and site_short_domain <> '' ");
		if($cmysql2->error != ""){ 
			$fail=true;
			array_push($arrError, "db error:".$cmysql2->error);	
		}
		if(!$fail){

			while($row=$r->fetch_array(MYSQLI_ASSOC)){
				$sitePath=zGetDomainInstallPath($row["site_short_domain"]);
				if($sitePath != "" && !is_dir($sitePath)){
					mkdir($sitePath, 0550);
				}
				if(zIsTestServer()){
					chmod($sitePath, 0777);
				}else{
					chmod($sitePath, 0550);
				}
				chown($sitePath, get_cfg_var("jetendo_www_user"));
				chgrp($sitePath, get_cfg_var("jetendo_www_user"));
				$sitePath=zGetDomainWritableInstallPath($row["site_short_domain"]);
				if($sitePath != "" && !is_dir($sitePath)){
					mkdir($sitePath, 0770);
				}
				if(zIsTestServer()){
					chmod($sitePath, 0777);
				}else{
					chmod($sitePath, 0770);
				}
				chown($sitePath, get_cfg_var("jetendo_www_user"));
				chgrp($sitePath, get_cfg_var("jetendo_www_user"));
			}
		}
	}
}
function installThemeToSite($a){
	set_time_limit(100);
	if(count($a) != 2){
		echo "2 arguments are required: themeName and siteAbsolutePath.\n";
		return "0";
	}
	$themeName=$a[0];
	$siteAbsolutePath=$a[1];
	$sp=get_cfg_var("jetendo_sites_path");
	if($siteAbsolutePath == ""){
		echo "The siteAbsolutePath is a required argument.\n";
		return "0";
	}

	$siteAbsolutePath=getAbsolutePath($siteAbsolutePath);
	if($siteAbsolutePath == "" || !is_dir($siteAbsolutePath)){
		echo "The site absolute directory doesn't exist: ".$siteAbsolutePath."\n";
		return "0";
	}
	$found=false;
	if(substr($siteAbsolutePath, 0, strlen($sp)) == $sp){
		$found=true;
	}
	if(!$found){
		echo "An attempt to break out of the sites directory was detected: ".$siteAbsolutePath."\n";
		return "0";
	}

	$p=get_cfg_var("jetendo_root_path")."themes/";
	if($themeName == ""){
		echo "The themeName is a required argument.\n";
		return "0";
	}

	$themePath=getAbsolutePath($p.$themeName."/");
	if($themePath == "" || !is_dir($themePath)){
		echo "The theme directory doesn't exist: ".$themePath."\n";
		return "0";
	}
	$found=false;
	if(substr($themePath, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "An attempt to break out of the theme directory was detected: ".$themePath."\n";
		return "0";
	}
	if(substr($themePath, strlen($themePath)-1, 1) != "/"){
		$themePath.="/";
	}
	if(substr($siteAbsolutePath, strlen($siteAbsolutePath)-1, 1) != "/"){
		$siteAbsolutePath.="/";
	}
	$cmd='/usr/bin/rsync -av --exclude=".git/" --exclude=".gitignore" --exclude="README.txt" '.escapeshellarg($themePath)." ".escapeshellarg($siteAbsolutePath);
	$r=`$cmd`;
	$cmd='/bin/chown '.get_cfg_var("jetendo_www_user").':'.get_cfg_var("jetendo_www_user").' '.escapeshellarg($siteAbsolutePath);
	$r=`$cmd`;
	$isTestServer=zIsTestServer();
	$preview=false;
	$arrError=array();
	$result=zCheckDirectoryPermissions($siteAbsolutePath, get_cfg_var("jetendo_www_user"), get_cfg_var("jetendo_www_user"), "440", "550", true, $preview, $arrError, $isTestServer);
	return "1";
}
function getNewerCoreMVCFiles(){
	$p=get_cfg_var("jetendo_root_path");
	$cmd="/usr/bin/find ".$p."core/mvc -type f -newer ".$p."core/mvc-cache.cfc";
	return `$cmd`;
}
function getScryptEncrypt($a){
	set_time_limit(100);
	$pw=implode("", $a);
	$p=get_cfg_var("jetendo_root_path");
	$cmd='/usr/bin/java -jar '.$p.'scripts/jetendo-scrypt.jar "encrypt" '.escapeshellarg($pw);
	$r=`$cmd`;
	return $r;
}
function publishNginxSiteConfig($a){

	$rs=new stdClass();
	$rs->success=true;
	if(count($a) != 1){
		$rs->success=false;
		$rs->errorMessage="1 argument is required: site_id.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}

	$nginxSitesPath=get_cfg_var("jetendo_nginx_sites_config_path");
	$nginxSSLPath=get_cfg_var("jetendo_nginx_ssl_path");
	if($nginxSitesPath == ""){
		$rs->success=false;
		$rs->errorMessage="jetendo_nginx_sites_config_path is not defined.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	if($nginxSSLPath == ""){
		$rs->success=false;
		$rs->errorMessage="jetendo_nginx_ssl_path is not defined.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	if(!is_dir($nginxSitesPath)){
		mkdir($nginxSitesPath, 0640, true);
	}
	$site_id=$a[0];
	$cmysql2=new mysqli(get_cfg_var("jetendo_mysql_default_host"),get_cfg_var("jetendo_mysql_default_user"), get_cfg_var("jetendo_mysql_default_password"), zGetDatasource());
	if($cmysql2->error != ""){ 
		$rs->success=false;
		$rs->errorMessage="db connect error:".$cmysql2->error;
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$r=$cmysql2->query("select * from site where 
	site_active='1' and 
	site_short_domain <> '' and 
	site_deleted='0' and 
	site_id = '".$cmysql2->real_escape_string($site_id)."' ");
	if($cmysql2->error != ""){ 
		$rs->success=false;
		$rs->errorMessage="db error:".$cmysql2->error;
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	if($r->num_rows==0){
		$rs->success=false;
		$rs->errorMessage="site_id doesn't exist.";
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$r2=$cmysql2->query("select * from `ssl` where 
	ssl_active='1' and 
	ssl_deleted='0' and 
	site_id = '".$cmysql2->real_escape_string($site_id)."' 
	ORDER BY ssl_created_datetime DESC 
	LIMIT 0,1");
	if($cmysql2->error != ""){ 
		$rs->success=false;
		$rs->errorMessage="DB error: ".$cmysql2->error;
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	$hasSSL=false;
	if($r2->num_rows){
		$hasSSL=true;
		$sslRow=$r2->fetch_array(MYSQLI_ASSOC);
	}
	$arrConfig=array();
	$row=$r->fetch_array(MYSQLI_ASSOC);
	
	$outPath=$nginxSitesPath.$site_id.".conf";
	if($row["site_nginx_disable_jetendo"]=="0" && !$hasSSL && trim($row["site_nginx_config"]) == ""){
		if(file_exists($outPath)){
			unlink($outPath);
			`/usr/sbin/service nginx reload 2>&1`;
			$result=`/usr/sbin/service nginx status 2>&1`;
			if(strpos($result, "nginx found running") !== FALSE){ 
				// success
				return json_encode($rs);
			}else{
				$rs->success=false;
				$rs->errorMessage="Failed to reload Nginx: ".$result;
				echo($rs->errorMessage."\n");
				return json_encode($rs);
			}
		}
	}
	$arrSite=explode(",", $row["site_domainaliases"]);
	if($hasSSL){
		$arrSSLSite=array();
		$host=str_replace("www.", "", $sslRow["ssl_common_name"]);
		array_push($arrSSLSite, $host);
		array_push($arrSite, $host);
		if($sslRow["ssl_wildcard"] == "1"){
			array_push($arrSSLSite, "*.".$host);
			array_push($arrSite, "*.".$host);
		}else{
			array_push($arrSSLSite, "www.".$host);
			array_push($arrSite, "www.".$host);
		}

		array_push($arrConfig, "server { 
			listen ".$row["site_ip_address"].":80;\n". 
			"server_name  ".implode(" ", $arrSite).";\n".
			"rewrite ^/(.*)$ https://$host/$1 permanent;\n".
		"}\n".
		"server {".
			"listen ".$row["site_ip_address"].":443 ssl spdy;\n".
			"server_name ".implode(" ", $arrSSLSite).";\n".
			$row["site_nginx_config"]."\n".
			"ssl_certificate ".$nginxSSLPath.$sslRow["ssl_hash"]."/".$row["site_id"].".crt;\n".
			"ssl_certificate_key ".$nginxSSLPath.$sslRow["ssl_hash"]."/".$row["site_id"].".key;\n");
			if($row["site_nginx_disable_jetendo"] == "0"){
				array_push($arrConfig, "include jetendo-ssl-vhost.conf;\n". 
				"include jetendo-vhost.conf;\n");
			}
		array_push($arrConfig, "}\n");
	}else{
		$host=str_replace("www.", "", $row["site_short_domain"]);
		array_push($arrSite, $host);
		array_push($arrSite, "www.".$host);
		array_push($arrConfig, "server {\n".
		"listen ".$row["site_ip_address"].":80; \n".
		"server_name  ".implode(" ", $arrSite).";\n".
		$row["site_nginx_config"]."\n");
			if($row["site_nginx_disable_jetendo"] == "0"){
				array_push($arrConfig, "include jetendo-vhost.conf;\n");
			}
		array_push($arrConfig, "}\n");
	}
	$out=str_replace("\r", "", implode("\n", $arrConfig));
	$backupMade=false;
	if(file_exists($outPath)){
		$backupMade=true;
		$backupContents=file_get_contents($outPath);
	}
	file_put_contents($outPath, $out);

	$result=`/usr/sbin/service nginx configtest 2>&1`;
	if(strpos($result, "successful") !== FALSE){
		`/usr/sbin/service nginx reload 2>&1`;
		$result=`/usr/sbin/service nginx status 2>&1`;
		//echo "result:".$result.":endresult\n";
		if(strpos($result, "nginx found running") !== FALSE){ 
			// success
		}else{
			echo "Nginx failed to reload..\n";
			$nginxOK=false;
			if($backupMade){
				file_put_contents($outPath, $backupContents);
				echo "restored ".$outPath." from backup";
			}else{
				unlink($outPath);
			}
			$result=`/usr/sbin/service nginx reload 2>&1`;
			echo "Reloaded nginx: ".$result."\n";
			$rs->success=false;
			$rs->errorMessage="Nginx failed to reload with Error: ".$result;
			echo($rs->errorMessage."\n");
			return json_encode($rs);
		}
	}else{
		$nginxOK=false;	
		if($backupMade){
			echo "restored ".$outPath." backup.";
			file_put_contents($outPath, $backupContents);
		}else{
			unlink($outPath);
		}
		$rs->success=false;
		$rs->errorMessage="Error: ".$result;
		echo($rs->errorMessage."\n");
		return json_encode($rs);
	}
	return json_encode($rs);
}

function getScryptCheck($a){
	set_time_limit(100);
	if(count($a) != 2){
		return "0";
	}
	$pw=$a[0];
	$hash=$a[1];
	$p=get_cfg_var("jetendo_root_path");
	$cmd='/usr/bin/java -jar '.$p.'scripts/jetendo-scrypt.jar "check" '.escapeshellarg($pw).' '.escapeshellarg($hash);
	$r=`$cmd`;
	return $r;
}

function getSystemIpList(){
	$cmd="ip addr show";
	return `$cmd`;
}
function gzipFilePath($a){
	set_time_limit(1000);
	$path=implode("", $a);
	if(file_exists($path)){
		$path=getAbsolutePath($path);
		$p=get_cfg_var("jetendo_root_path");
		$found=false;
		if(substr($path, 0, strlen($p)) == $p){
			$found=true;
		}
		$p=get_cfg_var("jetendo_backup_path");
		if(substr($path, 0, strlen($p)) == $p){
			$found=true;
		}
		if($found){
			$cmd="/bin/gzip -S .gz -f -9 ".escapeshellarg($path);
			`$cmd`;
			if(file_exists($path.".gz")){
				return "1";
			}
		}
	}
	return "0";
}
function getImageMagickConvertApplyMask($a){
	set_time_limit(100);
	if(count($a) != 3){
		echo "Incorrect number of arguments to getImageMagickConvertApplyMask.\n";
		return "0";
	}
	$absImageInputPath=trim($a[0]);
	$absImageOutputPath=trim($a[1]);
	$absImageMaskPath=trim($a[2]);
	if($absImageInputPath == ""){
		echo "absImageInputPath was an empty string\n";
		return "0";
	}
	if($absImageOutputPath == ""){
		echo "absImageOutputPath was an empty string\n";
		return "0";
	}
	if($absImageMaskPath == ""){
		echo "absImageMaskPath was an empty string\n";
		return "0";
	}
	$absImageInputPath=getAbsolutePath($absImageInputPath);
	$absImageOutputPath=getAbsolutePath($absImageOutputPath);
	$outputDir=getAbsolutePath(dirname($absImageOutputPath));
	$$absImageMaskPath=getAbsolutePath($absImageMaskPath);
	if($absImageInputPath == "" || !file_exists($absImageInputPath)){
		echo "The file for absImageInputPath doesn't exist: ".$absImageInputPath."\n";
		return "0";
	}
	if($outputDir == "" || !is_dir($outputDir)){
		echo "The parent directory for absImageOutputPath doesn't exist: ".$absImageOutputPath."\n";
		return "0";
	}
	if($absImageMaskPath == "" || !file_exists($absImageMaskPath)){
		echo "The file for absImageMaskPath doesn't exist: ".$absImageMaskPath."\n";
		return "0";
	}
	$absImageInputPathInfo=pathinfo($absImageInputPath);
	
	$outputExtension=getFileExt($absImageOutputPath);
	
	$absImageMaskPathInfo=pathinfo($absImageMaskPath);
	$validTypes=array();
	$validTypes["png"]=true;
	$validTypes["jpg"]=true;
	$validTypes["jpeg"]=true;
	$validTypes["gif"]=true;
	if(!isset($validTypes[strToLower($absImageInputPathInfo["extension"])])){
		echo "absImageInputPath must end with .jpg, .jpeg, .png or .gif.  It ended with: ".$absImageInputPathInfo["extension"]."\n";
		return "0";
	}
	if(!isset($validTypes[strToLower($outputExtension)])){
		echo "absImageOutputPath must end with .jpg, .jpeg, .png or .gif.  It ended with: ".$outputExtension."\n";
		return "0";
	}
	if(!isset($validTypes[strToLower($absImageMaskPathInfo["extension"])])){
		echo "absImageMaskPath must end with .jpg, .jpeg, .png or .gif.  It ended with: ".$absImageMaskPathInfo["extension"]."\n";
		return "0";
	}
	$path=$absImageInputPath;
	$p=get_cfg_var("jetendo_root_path");
	$found=false;
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	$p=get_cfg_var("jetendo_backup_path");
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "absImageInputPath must be in the jetendo install or backup paths. Path:".$absImageInputPath."\n";
		return "0";
	}
	$path=$absImageOutputPath;
	$p=get_cfg_var("jetendo_root_path");
	$found=false;
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	$p=get_cfg_var("jetendo_backup_path");
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "absImageOutputPath must be in the jetendo install or backup paths. Path:".$absImageOutputPath."\n";
		return "0";
	}
	$path=$absImageMaskPath;
	$p=get_cfg_var("jetendo_root_path");
	$found=false;
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	$p=get_cfg_var("jetendo_backup_path");
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "absImageMaskPath must be in the jetendo install or backup paths. Path:".$absImageMaskPath."\n";
		return "0";
	}
	$cmd="/usr/bin/convert ".escapeshellarg($absImageInputPath)." ".escapeshellarg($absImageMaskPath)." -alpha Off -compose CopyOpacity -composite ".escapeshellarg($absImageOutputPath);
	$r=`$cmd`;
	echo $cmd."\n".$r."\n";
	if(file_exists($absImageOutputPath)){
		return "1";
	}
	echo "Failed to apply image to image\n";
	return "0";
}

function getImageMagickConvertResize($a){
	set_time_limit(100);
	if(count($a) != 8){
		echo "Incorrect number of arguments to getImageMagickConvertResize.\n";
		return "0";
	}
	$resizeWidth=intval($a[0]);
	$resizeHeight=intval($a[1]);
	$cropWidth=intval($a[2]);
	$cropHeight=intval($a[3]);
	$cropXOffset=intval($a[4]);
	$cropYOffset=intval($a[5]);
	$sourceFilePath=trim($a[6]);
	$destinationFilePath=trim($a[7]);
	
	if($resizeWidth < 10 || $resizeHeight < 10){
		echo "resizeWidth and resizeHeight must be an integer greater then or equal 10.  Values: ".$resizeWidth."x".$resizeHeight."\n";
		return "0";
	}
	if($sourceFilePath == ""){
		echo "sourceFilePath was an empty string\n";
		return "0";
	}
	if($destinationFilePath == ""){
		echo "destinationFilePath was an empty string\n";
		return "0";
	}
	$sourceFilePath=getAbsolutePath($sourceFilePath);
	$destinationFilePath=getAbsolutePath($destinationFilePath);
	$outputDir=getAbsolutePath(dirname($destinationFilePath));
	if($sourceFilePath == "" || !file_exists($sourceFilePath)){
		echo "The file for sourceFilePath doesn't exist: ".$sourceFilePath."\n";
		return "0";
	}
	if($outputDir == "" || !is_dir($outputDir)){
		echo "The parent directory for destinationFilePath doesn't exist: ".$destinationFilePath."\n";
		return "0";
	}
	$sourceFilePathInfo=pathinfo($sourceFilePath);
	
	$outputExtension=getFileExt($destinationFilePath);
	
	$validTypes=array();
	$validTypes["png"]=true;
	$validTypes["jpg"]=true;
	$validTypes["jpeg"]=true;
	$validTypes["gif"]=true;
	if(!isset($validTypes[strToLower($sourceFilePathInfo["extension"])])){
		echo "sourceFilePath must end with .jpg, .jpeg, .png or .gif.  It ended with: ".$sourceFilePathInfo["extension"]."\n";
		return "0";
	}
	if(!isset($validTypes[strToLower($outputExtension)])){
		echo "destinationFilePath must end with .jpg, .jpeg, .png or .gif.  It ended with: ".$outputExtension."\n";
		return "0";
	}
	$path=$sourceFilePath;
	$p=get_cfg_var("jetendo_root_path");
	$found=false;
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	$p=get_cfg_var("jetendo_backup_path");
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "sourceFilePath must be in the jetendo install or backup paths. Path:".$sourceFilePath."\n";
		return "0";
	}
	$path=$destinationFilePath;
	$p=get_cfg_var("jetendo_root_path");
	$found=false;
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	$p=get_cfg_var("jetendo_backup_path");
	if(substr($path, 0, strlen($p)) == $p){
		$found=true;
	}
	if(!$found){
		echo "destinationFilePath must be in the jetendo install or backup paths. Path:".$destinationFilePath."\n";
		return "0";
	}
	$cmd='/usr/bin/convert -resize "'.$resizeWidth.'x'.$resizeHeight.'>" ';
	if($cropWidth != 0){
		$cmd.=' -crop '.$cropWidth.'x'.$cropHeight.'+'.$cropXOffset.'+'.$cropYOffset;
	}
	$cmd.=' '.escapeshellarg($sourceFilePath).' '.escapeshellarg($destinationFilePath);
	$r=`$cmd`;
	echo $cmd."\n".$r."\n";
	if(file_exists($destinationFilePath)){
		return "1";
	}
	return "0";
}

function getImageMagickIdentify($a){
	set_time_limit(100);
	$path=implode("", $a);
	if(file_exists($path)){
		$path=getAbsolutePath($path);
		$p=get_cfg_var("jetendo_root_path");
		$found=false;
		if(substr($path, 0, strlen($p)) == $p){
			$found=true;
		}
		$p=get_cfg_var("jetendo_backup_path");
		if(substr($path, 0, strlen($p)) == $p){
			$found=true;
		}
		if($found){
			$cmd="/usr/bin/identify -format %wx%h ".escapeshellarg($path)." 2>&1";
			$r=`$cmd`;
			echo $cmd."\n".$r."\n";
			return $r;
		}
	}
	return "";
}


function untarZipSiteImportPath($a){
	if(count($a) != 2){
		echo "incorrect number of arguments: ".implode(", ", $a)."\n";
		return "0";
	}
	$tarFileName=$a[0];
	$importDirName=$a[1];
	if(strpos($importDirName, ".") !== FALSE){
		echo "Import directory name must be a date as a number: ".$importDirName."\n";
		return "0";
	}
	if(!is_dir(get_cfg_var("jetendo_backup_path")."backup/import/".$importDirName)){
		echo "Import directory doesn't exist: ".get_cfg_var("jetendo_backup_path")."backup/import/".$importDirName."\n";
		return "0";
	}
	$tarPath=get_cfg_var("jetendo_backup_path")."backup/import/".$importDirName."/upload/".$tarFileName;
	if(!file_exists($tarPath)){
		echo "Tar file name doesn't exist: ".$tarPath."\n";
		return "0";
	}
	$untarPath=get_cfg_var("jetendo_backup_path")."backup/import/".$importDirName."/temp/";
	$cmd='/bin/tar -xvzf '.escapeshellarg($tarPath).' --exclude=sites --exclude=sites-writable -C '.escapeshellarg($untarPath);
	echo $cmd."\n";
	`$cmd`;

	return "1";
}


function tarZipSiteUploadPath($a){
	if(count($a) != 2){
		echo "incorrect number of arguments: ".implode(", ", $a)."\n";
		return "0";
	}
	$siteDomain=$a[0];
	if(!is_dir(get_cfg_var("jetendo_sites_writable_path").$siteDomain)){
		echo "Site path doesn't exist: ".get_cfg_var("jetendo_sites_writable_path").$siteDomain."\n";
		return "0";
	}
	$tarPath=get_cfg_var("jetendo_backup_path")."backup/site-archives/".$siteDomain."-zupload-".$a[1].".tar.gz";
	if(file_exists($tarPath)){
		@unlink($tarPath);
	}
	$cmd='/bin/tar -cvzf '.escapeshellarg($tarPath).' -C '.escapeshellarg(get_cfg_var("jetendo_sites_writable_path").$siteDomain).' zupload zuploadsecure';
	echo $cmd."\n";
	`$cmd`;

	if(!zIsTestServer()){

		$cmd='/bin/chown '.get_cfg_var("jetendo_www_user").":".get_cfg_var("jetendo_www_user")." ".escapeshellarg($tarPath);
		echo $cmd."\n";
		`$cmd`;
		$cmd='/bin/chmod 440 '.escapeshellarg($tarPath);
		echo $cmd."\n";
		`$cmd`;
	}
	if(file_exists($tarPath)){
		return "1";
	}else{
		return "0";
	}
}

function importSite($a){
	if(count($a) != 4){
		echo "incorrect number of arguments: ".implode(", ", $a)."\n";
		return "0";
	}

	$siteDomain=$a[0];
	$importDirName=$a[1];
	$tarFileName=$a[2];
	$tarUploadFileName=$a[3];
	if($siteDomain == ""){
		echo "Site domain must be defined.\n";
		return "0";
	}
	$tarPath=get_cfg_var("jetendo_backup_path")."backup/import/".$importDirName."/upload/".$tarFileName;
	$tarUploadPath=get_cfg_var("jetendo_backup_path")."backup/import/".$importDirName."/upload/".$tarUploadFileName;
	if($tarPath == "" || !file_exists($tarPath)){
		echo "Tar path doesn't exist: ".$tarPath."\n";
		return "0";
	}
	if($tarUploadFileName != "" && !file_exists($tarUploadPath)){
		echo "Tar upload path doesn't exist: ".$tarUploadPath."\n";
		return "0";
	}
	@mkdir(get_cfg_var("jetendo_sites_path").$siteDomain, 0400);
	@mkdir(get_cfg_var("jetendo_sites_writable_path").$siteDomain, 0400);

	if($tarUploadFileName != ""){
		$cmd='/bin/tar -xvzf '.escapeshellarg($tarUploadPath).' -C '.escapeshellarg(get_cfg_var("jetendo_sites_writable_path").$siteDomain).' zupload zuploadsecure';
		echo $cmd."\n";
		`$cmd`;
	}
	$cmd='/bin/tar -xvzf '.escapeshellarg($tarPath).' -C '.escapeshellarg(get_cfg_var("jetendo_sites_writable_path").$siteDomain).' --transform="s,^sites-writable,," sites-writable';
	echo $cmd."\n";
	`$cmd`;

	$cmd='/bin/tar -xvzf '.escapeshellarg($tarPath).' -C '.escapeshellarg(get_cfg_var("jetendo_sites_path").$siteDomain).' --transform="s,^sites,," sites';
	echo $cmd."\n";
	`$cmd`;

	verifySitePaths();

	if(file_exists($tarPath)){
		return "1";
	}else{
		return "0";
	}
}

function tarZipSitePath($a){
	if(count($a) != 2){
		echo "incorrect number of arguments: ".implode(", ", $a)."\n";
		return "0";
	}
	$siteDomain=$a[0];
	if(!is_dir(get_cfg_var("jetendo_sites_path").$siteDomain)){
		echo "Site path doesn't exist: ".get_cfg_var("jetendo_sites_path").$siteDomain."\n";
		return "0";
	}
	$backupPath=get_cfg_var("jetendo_backup_path")."backup/";
	$tarPath=get_cfg_var("jetendo_backup_path")."backup/site-archives/".$siteDomain."-".$a[1].".tar.gz";

	if(file_exists($tarPath)){
		@unlink($tarPath);
	}
	// figure out which database files to include based on the cfml code.
	$arr7z=array();
	array_push($arr7z, "database-schema/");
	$tempPathName='';
	$siteBackupPath=$backupPath."site-archives".$tempPathName."/".$siteDomain."/";
	$transformPath=substr(get_cfg_var("jetendo_sites_writable_path").$siteDomain, 1); 
	$cmd='/bin/tar -cvzf '.escapeshellarg($tarPath).' -C '.escapeshellarg($backupPath).' '.implode(' ', $arr7z).' -C '.escapeshellarg($siteBackupPath).'  restore-site-database.sql database globals.json -C '.escapeshellarg(get_cfg_var("jetendo_sites_path")).' --exclude=.git --transform "s,^'.$siteDomain.',sites," '.$siteDomain.' -C '.escapeshellarg(get_cfg_var("jetendo_sites_writable_path").$siteDomain."/").' --exclude=zupload --exclude=__zdeploy-changes.txt --transform "s,^'.$transformPath.',sites-writable," '.get_cfg_var("jetendo_sites_writable_path").$siteDomain."/";
	echo $cmd."\n";
	`$cmd`;
	if(!zIsTestServer()){
		$cmd='/bin/chown '.get_cfg_var("jetendo_www_user").":".get_cfg_var("jetendo_www_user")." ".escapeshellarg($tarPath);
		echo $cmd."\n";
		`$cmd`;
		$cmd='/bin/chmod 440 '.escapeshellarg($tarPath);
		echo $cmd."\n";
		`$cmd`;
	}
	if(file_exists($tarPath)){
		return "1";
	}else{
		return "0";
	}
}

function tarZipGlobalDatabase($a){
	$backupPath=get_cfg_var("jetendo_backup_path")."backup/";
	$tarPath=get_cfg_var("jetendo_backup_path")."backup/global-database.tar.gz";
	@unlink($tarPath);
	$cmd='/bin/tar -cvzf '.escapeshellarg($tarPath).' -C '.escapeshellarg($backupPath).'  restore-global-database.sql database-global-backup/ database-schema/';
	echo $cmd."\n";
	`$cmd`;

	$cmd='/bin/chown '.get_cfg_var("jetendo_www_user").":".get_cfg_var("jetendo_www_user")." ".escapeshellarg($tarPath);
	echo $cmd."\n";
	`$cmd`;
	$cmd='/bin/chmod 440 '.escapeshellarg($tarPath);
	echo $cmd."\n";
	`$cmd`;

	if(file_exists($tarPath)){
		return "1";
	}else{
		return "0";
	}
}

function tarZipFilePath($a){
	set_time_limit(1000);
	if(count($a) != 3){
		echo "incorrect number of arguments: ".implode(", ", $a)."\n";
		return "0";
	}
	$tarFilename=trim($a[0]);
	if($tarFilename==""){
		echo "tarFilename is invalid: ".$tarFilename."\n";
		return "0";
	}
	$tarDirectory=trim($a[1]);
	$pathToTar=trim($a[2]);
	$tarDirectory=getAbsolutePath($tarDirectory);
	$pathToTar=getAbsolutePath($pathToTar);
	if($pathToTar=="" || (!is_dir($pathToTar) && !file_exists($pathToTar))){
		echo "pathToTar is invalid: ".$pathToTar."\n";
		return "0";
	}
	if($tarDirectory=="" || !is_dir($tarDirectory)){
		echo "tarDirectory is invalid: ".$tarDirectory."\n";
		return "0";
	}
	$p=get_cfg_var("jetendo_root_path");
	$p2=get_cfg_var("jetendo_backup_path");
	$found=false;
	if(substr($tarDirectory, 0, strlen($p)) == $p || substr($tarDirectory, 0, strlen($p2)) == $p2){
		if(substr($pathToTar, 0, strlen($p)) == $p || substr($pathToTar, 0, strlen($p2)) == $p2){
			$found=true;
		}else{
			echo "pathToTar is not in jetendo install or backup paths.\n";
		}
	}else{
		echo "tarDirectory is not in jetendo install or backup paths.\n";
	}
	if($found){
		chdir($pathToTar);
		$cmd="/bin/tar -cvzf ".escapeshellarg($tarDirectory."/".$tarFilename)." *";
		`$cmd`;
		if(file_exists($tarDirectory."/".$tarFilename)){
			$tarPath=$tarDirectory."/".$tarFilename;
			$cmd='/bin/chown '.get_cfg_var("jetendo_www_user").":".get_cfg_var("jetendo_www_user")." ".escapeshellarg($tarPath);
			echo $cmd."\n";
			`$cmd`;
			$cmd='/bin/chmod 440 '.escapeshellarg($tarPath);
			echo $cmd."\n";
			`$cmd`;
			echo "Created tar/gzip successfully\n";
			return "1";
		}
	}
	echo "Failed to create tar/gzip\n";
	return "0";
}

function getDiskUsage($a){
	set_time_limit(500);
	$path=implode("", $a);
	if(is_dir($path) || file_exists($path)){
		$path=getAbsolutePath($path);
		$p=get_cfg_var("jetendo_root_path");
		$found=false;
		if(substr($path, 0, strlen($p)) == $p){
			$found=true;
		}
		$p=get_cfg_var("jetendo_backup_path");
		if(substr($path, 0, strlen($p)) == $p){
			$found=true;
		}
		if($found){
			$cmd="/usr/bin/du -sh ".escapeshellarg($path);
			return `$cmd`;
		}
	}
	return "";
}
function getFileMD5Sum($a){
	$path=implode("", $a);
	if(file_exists($path)){
		$path=getAbsolutePath($path);
		$p=get_cfg_var("jetendo_root_path");
		if(substr($path, 0, strlen($p)) != $p){
			return "";
		}
		$cmd="/usr/bin/md5sum ".escapeshellarg($path);
		return `$cmd`;
	}else{
		return "";
	}
}
function getUserList(){
	$cmd="/bin/cat /etc/passwd";
	$result=trim(`$cmd`);
	$arrPasswd=explode("\n", $result);
	$arrUser=array();
	for($i=0;$i<count($arrPasswd);$i++){
		$arrTemp=explode(":", $arrPasswd[$i]);
		array_push($arrUser, $arrTemp[0]);
		
	}
	return implode(",", $arrUser);
}
function microtimeFloat()
{
    list($usec, $sec) = explode(" ", microtime());
    return ((float)$usec + (float)$sec);
}
function runCommand($argv){
	if(count($argv) != 2){
		echo "Invalid argument count.";
		exit;
	}	
	$debug=false;
	$timeout=60; // seconds
	$timeStart=microtimeFloat();
	$completePath=get_cfg_var("jetendo_root_path")."execute/complete/";
	$startPath=get_cfg_var("jetendo_root_path")."execute/start/";

	$startFile=$startPath.$argv[1];
	$completeFile=$completePath.$argv[1];
	if(!file_exists($startFile)){
		echo "Start file was missing: ".$startFile."\n";
		exit;
	}

	$contents=file_get_contents($startFile);
	unlink($startFile);
	$results=processContents($contents);
	$fp=fopen($completeFile, "w");
	echo "Completed: ".$argv[1]."\n";
	fwrite($fp, $results);
	fclose($fp);
			
}
runCommand($argv);

?>