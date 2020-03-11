%macro get_values(in_lib,in_table,var_list_name,var_name,delimiter=);
/************************************************************/
/*	DEPOINT DEC 6, 2001										*/
/*	This macro takes a table and outputs VALUES of a given	*/
/*	variable name to a GLOBAL macro variable				*/
/*	updated by depoint april 2003							*/
/*	when you call get_values, use a %QUOTE for delimiter if */
/*	you want to use, for example, a comma*/
/************************************************************/
	%GLOBAL &var_list_name;
	proc sql noprint;
		select &VAR_NAME
		INTO :&var_list_name SEPARATED BY "&DELIMITER " /*the space before the last quote is crucial*/
		from &in_lib..&in_table
		;
	quit;
%MEND get_values;
