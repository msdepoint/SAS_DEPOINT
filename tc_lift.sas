%MACRO tc_lift (in_table=,in_lib=work,offer_var=,compare_var=,out_table=tc_lift_out, wgt=);
/***********************************************/
/*DEPOINT Feb/DEC 2004 */
/*assumes numeric for offer variable value*/
/* so this macro does not do multiple "t-test" */
/* e.g offer_var = test_control		*/
/* compare_var = revenue			*/
/***********************************************/
ODS LISTING CLOSE;
ODS OUTPUT means=means1(KEEP=&offer_var n mean_&compare_var RENAME=(mean_&compare_var = MEAN));
ODS OUTPUT modelanova=pval1(KEEP=dependent probf RENAME=(probf = p_value));
proc glm data=&in_lib..&in_table;
	class &offer_var;
	model &compare_var = &offer_var;
	MEANS &offer_var;
	%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO;weight &wgt;%END;
quit;
ODS OUTPUT CLOSE;
ODS LISTING;

PROC SQL;
	CREATE TABLE almost_out AS
	SELECT *
	FROM pval1(firstobs=1 obs=1), means1
	;
QUIT;
DATA &out_table;
	FORMAT data_source compare_var $36. &offer_var $12. n best8.0 mean comma14.2;
	SET almost_out;
	data_source = "%UPCASE(&in_table)";
	compare_var = "%UPCASE(&compare_var)";
	LABEL &offer_var = "&offer_var";
	KEEP data_source compare_var &offer_var n mean p_value;
RUN;

PROC DATASETS library=work NOLIST;
	DELETE pval1 means1 almost_out;
QUIT;
%MEND tc_lift;


