
(function($, window, document, undefined){
	"use strict";
	var zModalObjectHidden=new Array();
	var zModalScrollPosition=new Array();
	var zArrModal=[];
	var zModalPosIntervalId=false;
	var zModalIndex=0;
	var zModalKeepOpen=false;
	function zModalLockPosition(e){
		var el = document.getElementById("zModalOverlayDiv"); 
		if(el && el.style.display==="block"){
			var yPos=$(window).scrollTop();
			el.style.top=yPos+"px";
			return false;
		}else{
			return true;
		}
	}
	function zShowModalStandard(url, maxWidth, maxHeight){
		var windowSize=zGetClientWindowSize();
		if(url.indexOf("?") === -1){
			url+="?";
		}else{
			url+="&";
		}
		if(typeof maxWidth === "undefined"){
			maxWidth=3000;	
		}
		if(typeof maxHeight === "undefined"){
			maxHeight=3000;	
		}
		var modalContent1='<iframe src="'+url+'ztv='+Math.random()+'" frameborder="0"  style=" margin:0px; border:none; overflow:auto;" seamless="seamless" width="100%" height="98%" />';		
		zShowModal(modalContent1,{'width':Math.min(maxWidth, windowSize.width-50),'height':Math.min(maxHeight, windowSize.height-50),"maxWidth":maxWidth, "maxHeight":maxHeight});
	}
	function zFixModalPos(){
		zGetClientWindowSize();
		var windowSize=zWindowSize;
		for(var i=1;i<=zModalIndex;i++){
			var el = document.getElementById("zModalOverlayDivContainer"+i);
			var el2 = document.getElementById("zModalOverlayDivInner"+i);
			zArrModal[i].scrollPosition=[
			self.pageXOffset ||
			document.documentElement.scrollLeft ||
			document.body.scrollLeft
			,
			self.pageYOffset ||
			document.documentElement.scrollTop ||
			document.body.scrollTop
			];
			if(isNaN(zArrModal[i].modalWidth)){
				zArrModal[i].modalWidth=10000;
			}
			if(isNaN(zArrModal[i].modalHeight)){
				zArrModal[i].modalHeight=10000;
			}
			el.style.top=zArrModal[i].scrollPosition[1]+"px";
			el.style.left=zArrModal[i].scrollPosition[0]+"px";
			var newWidth=Math.min(zArrModal[i].modalWidth, Math.min(windowSize.width-100,((zArrModal[i].modalMaxWidth))));
			var newHeight=Math.min(zArrModal[i].modalHeight, Math.min(windowSize.height-100,((zArrModal[i].modalMaxHeight))));
			var left=Math.round(Math.max(0, windowSize.width-newWidth)/2);
			var top=Math.round(Math.max(0, windowSize.height-newHeight)/2);
			el2.style.left=left+'px';
			el2.style.top=top+'px';
			el2.style.width=newWidth+"px";
			el2.style.height=newHeight+"px";
		}
	}
	function zShowModal(content, obj){
		var d=document.body || document.documentElement;
		zModalIndex++;
		zArrModal[zModalIndex]={

			"disableResize":false,
			"modalMaxWidth":10000,
			"modalMaxHeight":10000,
			"modalWidth":10000,
			"modalHeight":10000
		};
		var h='<div id="zModalOverlayDivContainer'+zModalIndex+'" class="zModalOverlayDiv"><div id="zModalOverlayDivInner'+zModalIndex+'" class="zModalOverlayDiv2"></div></div>';
		$(d).append(h);
		d.style.overflow="hidden";
		zGetClientWindowSize();
		if(typeof obj.disableResize !== "undefined" && obj.disableResize){
			zArrModal[zModalIndex].disableResize=obj.disableResize;	
		}
		var disableClose=false;
		if(typeof obj.disableClose !== "undefined" && obj.disableClose){
			disableClose=obj.disableClose;	
		}
		var windowSize=zWindowSize;
		zArrModal[zModalIndex].modalWidth=obj.width;
		zArrModal[zModalIndex].modalHeight=obj.height;
		obj.width=Math.min(zArrModal[zModalIndex].modalMaxWidth, Math.min(obj.width, windowSize.width));
		obj.height=Math.min(zArrModal[zModalIndex].modalMaxHeight, Math.min(obj.height, windowSize.height));
		if(typeof obj.maxWidth !== "undefined"){
			zArrModal[zModalIndex].modalMaxWidth=obj.maxWidth;
		}
		if(typeof obj.maxHeight !== "undefined"){
			zArrModal[zModalIndex].modalMaxHeight=obj.maxHeight;
		}
	    zArrModal[zModalIndex].scrollPosition = [
	        self.pageXOffset ||
	        document.documentElement.scrollLeft ||
	        document.body.scrollLeft
	        ,
	        self.pageYOffset ||
	        document.documentElement.scrollTop ||
	        document.body.scrollTop
	    ];
	    if(zModalIndex==1){

			var arr=document.getElementsByTagName("iframe");
			for(var i=0;i<arr.length;i++){
				if(arr[i].style.visibility==="" || arr[i].style.visibility === "visible"){
					arr[i].style.visibility="hidden";
					zModalObjectHidden.push(arr[i]);
				}
			}
			if(navigator.userAgent.indexOf("MSIE 6.0") !== -1){
				var arr=document.getElementsByTagName("select");
				for(var i=0;i<arr.length;i++){
					if(arr[i].style.visibility==="" || arr[i].style.visibility === "visible"){
						arr[i].style.visibility="hidden";
						zModalObjectHidden.push(arr[i]);
					}
				}
				arr=document.getElementsByTagName("object");
				for(var i=0;i<arr.length;i++){
					if(arr[i].style.visibility==="" || arr[i].style.visibility === "visible"){
						arr[i].style.visibility="hidden";
						zModalObjectHidden.push(arr[i]);
					}
				}
				// don't use the png here...
				var dover1=document.getElementById("zModalOverlayDiv");
				dover1.style.backgroundImage="url(/z/a/images/bg-checker.gif)";
			}
		}
		var el = document.getElementById("zModalOverlayDivContainer"+zModalIndex);
		var el2 = document.getElementById("zModalOverlayDivInner"+zModalIndex);
		el.style.display = "block";
		el2.style.display = "block";
		el2.onclick=function(){
			zModalKeepOpen=true;
			setTimeout(function(){zModalKeepOpen=false;},100); 
			return false;
		};
		if(disableClose){
			el2.innerHTML=content;  	
			el.onclick=function(){};
		}else{
			el.onclick=function(){
				if(zModalKeepOpen) return;
				zCloseModal();
			};
			el2.innerHTML='<div style="width:80px; text-align:right; font-weight:bold; float:right;"><a href="javascript:void(0);" onclick="zCloseModal();">X Close</a></div><br style="clear:both;" /> '+content+'<div>';  
		}
		el.style.top=zArrModal[zModalIndex].scrollPosition[1]+"px";
		el.style.left=zArrModal[zModalIndex].scrollPosition[0]+"px";
		el.style.height="100%";
		el.style.width="100%";
		var left=Math.round(Math.max(0,((windowSize.width)-obj.width))/2);
		var top=Math.round(Math.max(0, (windowSize.height-obj.height))/2);
		el2.style.left=left+'px';
		el2.style.top=top+'px';
		el2.style.width=(obj.width)+"px";
		el2.style.height=(obj.height)+"px";
		zModalPosIntervalId=setInterval(zFixModalPos,500);
	}
	function zCloseModal(){
		clearInterval(zModalPosIntervalId);
		for(var i=0;i <zArrModalCloseFunctions.length;i++){
			zArrModalCloseFunctions[i]();
		}
		zArrModalCloseFunctions=[];
		zModalPosIntervalId=false;
		var d=document.body || document.documentElement;
		d.style.overflow="auto";
		var el = document.getElementById("zModalOverlayDivContainer"+zModalIndex);
		el.parentNode.removeChild(el);
	    if(zModalIndex==1){
			for(var i=0;i<zModalObjectHidden.length;i++){
				zModalObjectHidden[i].style.visibility="visible";
			}
		}
		zModalIndex--;
		if(zModalIndex<0){
			zModalIndex=0;
		}
	}
	function zShowImageUploadWindow(imageLibraryId, imageLibraryFieldId){
		var windowSize=zGetClientWindowSize();
		var modalContent1='<iframe src="/z/_com/app/image-library?method=imageform&image_library_id='+imageLibraryId+'&fieldId='+encodeURIComponent(imageLibraryFieldId)+'&ztv='+Math.random()+'"  style="margin:0px;border:none; overflow:auto;" seamless="seamless" width="100%" height="95%"><\/iframe>';		
		zShowModal(modalContent1,{'width':windowSize.width-100,'height':windowSize.height-100});
	}

	function zCloseThisWindow(reload){
		if(typeof reload === 'undefined'){
			reload=false;
		}
		if(window.parent.zCloseModal){
			if(reload){
				var curURL=window.parent.location.href;
				window.parent.location.href = curURL;
			}else{
				window.parent.zCloseModal();
			}
		}else{
			if(reload){
				var curURL=window.parent.location.href;
				window.parent.location.href = curURL;
			}else{
				window.close();
			}
		}
	}
	window.zArrModalCloseFunctions=[];
	if(typeof window.zModalCancelFirst == "undefined"){
		window.zModalCancelFirst=false;
	}
	window.zModalLockPosition=zModalLockPosition;
	window.zShowModalStandard=zShowModalStandard;
	window.zFixModalPos=zFixModalPos;
	window.zShowModal=zShowModal;
	window.zCloseModal=zCloseModal;
	window.zShowImageUploadWindow=zShowImageUploadWindow;
	window.zCloseThisWindow=zCloseThisWindow;
})(jQuery, window, document, "undefined"); 