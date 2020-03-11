%MACRO CREATE_M(in_lib,in_table,out_table,FLAG=,varname=varname);
/************************************************/
/*	DePoint May 2003			*/
/*	updated April 2004			*/
/*	Create new modeling dataset		*/
/*	with new variables for data source 	*/
/*	specific sources like EXPERIAN or ACAPS	*/
/***********************************************/
	ods output directory=dir;
	proc datasets library=work; run; quit;
	ods output close;

	data _null_;
		set DIR; if UPCASE(LABEL1) = 'PHYSICAL NAME';
		call symput ('LOCATION',CVALUE1);
	run;

%IF &FLAG = FFGH %THEN %DO;
	%let calc_loc 	= ;
	%let calc_name 	= ;
%END;

%ELSE %DO;
	data nothing;
		ATTRIB &VARNAME FORMAT=$80. LABEL = 'INDEPENDENT VARIABLE';
		ATTRIB t FORMAT=$120. LABEL = 'transformation';		
		t=' ';
	%let calc_loc 	= &LOCATION;
	%let calc_name 	= nothing;	
%END;

%IF (%LENGTH(&FLAG) >0) %THEN %DO;
	/*GET LOCATION OF WORK TO PUT txt OUTPUT*/
	options nobyline nonumber nodate nodetails;
	title;
	libname GETEM "&calc_loc";
	data toprint;
		set getem.&calc_name(keep=t);
	run;
	FILENAME routed "&LOCATION/exp.txt";

	PROC PRINTTO PRINT=routed new;
		proc report data=toprint nowindows noalias nocenter noheader;
	RUN;
	PROC PRINTTO print=print;
	RUN;

	data &out_table;
		set &in_lib..&in_table;
		%INCLUDE "&LOCATION/exp.txt";
	run;
%END;
	%ELSE %DO;
		data &out_table;
			set &in_lib..&in_table;
		run;
	%END;
%MEND CREATE_M;