%macro get_var_names(in_lib,in_table,out_table,var_list_name,out_lib=work,keep1=name,drop_list=,delimiter=);
/************************************************************/
/*	DEPOINT DEC 6, 2001					*/
/*	modified OCT 2002	*/
/*	modified apr 2003*/
/*	This macro takes a table and outputs the variable names	*/
/*	to a output table and a GLOBAL marco variable			*/
/*	you can keep variables from the CONTENTS like name, format, label, type*/
/*	common drop list members unique identifiers date variables */
/************************************************************/
%let the_drops= "JUNK213";
%STRING_LOOP(var_list=%UNQUOTE(&drop_list),ACTION_CODE=%NRSTR(%let the_drops = &the_drops, "&&word&i";
								)
	);
	proc contents data=&IN_LIB..&in_table NOPRINT out=g_out(keep=&keep1);
	data &out_lib..&out_table;
		set g_out;
		IF UPCASE(name) NOT IN (%UPCASE(&the_drops));
					/*just list some common exclude variables*/
	run;
	
	%get_values(in_lib=&OUT_LIB,in_table=&out_table,var_list_name=&var_list_name,var_name=name,delimiter=%QUOTE(&delimiter));

%MEND get_var_names;
