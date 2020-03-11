%MACRO report_2way_ratio(in_lib=work,in_table=,class1=,class2=,numer=,denom=,out_lib=work,out_table=,class1_label=);
/*DePoint December 2005 */
/* assumes, like the report and tabulate generic */
/* each class has a format name referenced by the class name*/
/* assumes numeric class variables with max value less than 9999998*/

PROC REPORT DATA=&in_lib..&in_table nowindows headline headskip missing OUT=from_report(DROP=_break_);
	column &class1 &class2  &numer &denom ratio;
	DEFINE &class1 /group format =&&&class1... order=internal;
	DEFINE &class2 /group format =&&&class2... order=internal;
	DEFINE &numer/analysis sum noprint;
	DEFINE &denom/analysis sum noprint;
	break after &class1/summarize skip ol;
	rbreak after /summarize dol dul ;
	COMPUTE ratio;
		ratio = ROUND(&numer..sum/&denom..sum,0.001);
	ENDCOMP;
RUN;

DATA from1; SET from_report;
	*FORMAT new_c2 best8.;
	FORMAT ratio percent8.4;
	IF MISSING(&class1) THEN DELETE;
	IF MISSING(&class2) THEN new_c2 = 9999999; ELSE new_c2 = &class2;
	DROP &class2;
	RENAME 	new_c2 = &class2;
RUN;

PROC SORT DATA=from1; BY &class2;
DATA make_bottom_total(DROP=sum_numer sum_denom &numer &denom);
	SET from1; BY &class2;
	*FORMAT &class1 best8.;
	IF FIRST.&class2 THEN DO; sum_numer = 0; sum_denom=0;END;
	sum_numer = SUM(sum_numer,&numer); sum_denom = SUM(sum_denom,&denom);
	retain sum_numer sum_denom;
	IF LAST.&class2 THEN DO;
		ratio 	= ROUND(sum_numer/sum_denom,0.001);
		&class1	= 9999998;
		OUTPUT;
		END;
RUN;
DATA new_from1; SET from1 make_bottom_total;
	FORMAT c2_label $16.;
	IF &class2 = 9999999 THEN c2_label = 'TOTAL'; 
		ELSE c2_label = PUT(&class2,&&&class2...);

PROC SORT DATA=new_from1; BY &class1;
PROC TRANSPOSE DATA=new_from1 OUT=from_t(drop=_name_ _label_);
	by &class1;
	ID &class2;
	IDLABEL  c2_label;
	var  ratio;
run;
/*THIS SECTION CHANGES THE LOGICAL(physical?) order of the variables so that*/
/* That print correctly. It uses the format function in the from_t1 data step*/
%get_var_names(in_lib=work,in_table=from_t,out_table=cdvars,var_list_name=cdout,
	out_lib=work,keep1=name,drop_list=%QUOTE(c1_label PRODUCT),delimiter=);
 %PUT ***** &cdout;

DATA from_t1;
	FORMAT c1_label $16. &cdout percent8.4;
	SET from_t;
	IF &class1 = 9999998 THEN c1_label = 'TOTAL'; 
		ELSE c1_label = PUT(&class1,&&&class1...);
	LABEL 	_9999999		= 'TOTAL'
			c1_label	= "&class1_label"
			;
	c1_label	= COMPRESS(c1_label);
RUN;
PROC SORT DATA=from_t1 OUT=&out_lib..&out_table(drop=&class1); BY &class1;
/*
PROC TABULATE DATA=from_t1 missing format=percent8.4 ;
	CLASS &class1 /order=internal;
	FORMAT &class1 &&&class1...;
	VAR &cdout;    
	TABLES &class1='', (&cdout) *sum=' '
	/rts=20 BOX = "&class1_label" MISSTEXT=' ';      
    TITLE ' ';       
   RUN;

PROC TABULATE DATA=from_t1 missing format=percent8.4 ;
	CLASS c1_label /order=internal;
	FORMAT c1_label $16.;
	VAR &cdout;    
	TABLES c1_label='', (&cdout) *sum=' '
	/rts=20 BOX = "&class1_label" MISSTEXT=' ';      
    TITLE ' ';       
   RUN;
*/

PROC TABULATE DATA=&out_lib..&out_table missing format=percent8.4 ;
	CLASS c1_label /order=FORMATTED;
	VAR &cdout;    
	TABLES c1_label='', (&cdout) *sum=' '
	/rts=20 BOX = "&class1_label" MISSTEXT=' ';      
    TITLE ' ';       
   RUN;
/*
PROC PRINT DATA=&out_lib..&out_table NOOBS LABEL;RUN;
*/
%MEND report_2way_ratio;




