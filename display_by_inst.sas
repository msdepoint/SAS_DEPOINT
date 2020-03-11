%MACRO display_by_inst(in_lib=,in_table=,where_extra=,class_vars=,rate_var=,label=,out_lib=work,out_table=jimmyjim);
/*********************************************/
/*BE CAREFUL WITH THIS, it can spit out ALOT */
/*********************************************/
PROC FORMAT;
VALUE $prod
M	= 'Reg MM'
MY	= 'Prem MM'
K	= 'Reg Int DDA'
KY	= 'Prem DDA'
C	= 'CD'
S	= 'Reg Savings'
SP	= 'Passbook Savings'
MR = 'MR'
IF = 'IF'
HL = 'HL'
OS = 'OS'
;
*other 	= 'BAD code'
;
VALUE $P_or_B
P	= 'Personal'
B	= 'Business'
;
PICTURE pctfmt low-high='009.99 %';
QUIT;

proc tabulate data=&in_lib..&in_table missing order=INTERNAL OUT=&out_lib..&out_table;
    VAR &rate_var;
    CLASS &class_vars;
	FORMAT institution_id $&&institution_id..;
        TABLES (date=''), (institution_id='' * rate_class='') 
				* 	&rate_var=''*(mean*f=pctfmt. min*f=pctfmt. max*f=pctfmt.)
        /rts=30 row=float  BOX = "&rate_var &label" MISSTEXT='';
        TITLE ' ';
        ;
	%IF %LENGTH(%UNQUOTE(&where_extra)) > 0 %THEN %DO;
		WHERE %UNQUOTE(&where_extra)
		%END;
	;  
QUIT;
%MEND display_by_inst;