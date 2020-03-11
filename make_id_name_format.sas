%MACRO make_id_name_format(in_lib=work,in_table=,format_label=);
/****************************************************************/
/* Cleans up the institution ID and name and creates			*/
/* a format for the institution ID								*/
/****************************************************************/

ODS LISTING CLOSE;
PROC FREQ DATA=&in_lib..&in_table;
	TABLES institution_id*institution_name /noprint out=freq1(KEEP=institution_id institution_name);
RUN;
ODS LISTING;

%MACRO check_length(var=);
%GLOBAL out_num;
%IF %LENGTH(&var)>31  %THEN %LET out_num=31;
%ELSE  %LET out_num = %LENGTH(&var);

%MEND check_length;
%CHECK_length(var=&format_label);

%GLOBAL &format_label;
%LET &FORMAT_LABEL=;
%LET &FORMAT_label = %SUBSTR(&format_label,1,&out_num);


DATA ctrl;
     set freq1(rename=(institution_id=start institution_name=label));
     retain fmtname "&&format_label" type 'c' ;
RUN;

proc print data=ctrl ;
run ;

proc format library=work cntlin=ctrl;
proc format library=work fmtlib;
RUN;

/********************/
/* CLEAN UP			*/
%SYMDEL out_num; /*remove out_num from the global table list*/
PROC DATASETS library=work NOLIST;
	DELETE ctrl;
QUIT;
/********************/
/********************/
%MEND make_id_name_format;
