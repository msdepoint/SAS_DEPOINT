%MACRO report_response_dollar(in_tablE=,in_lib=,class1=,class2=,num_var=,denom_var=,out_table=WOUT,wgt=);
/* two way response($) cross-tabulate. class variables have to be numeric*/
/* DePoint Jan 2003*/
proc sql;
    create table look2 as
    select distinct PUT(&class2, &&&class2...) as look2
    from &IN_LIB..&IN_TABLE
    order by look2
    ;
    select count(*) INTO :count2 from look2 ;
    %LET count2 = &COUNT2; /*gets rid of spaces as explained by SAS instructors*/
quit;

proc report data=&in_LIB..&in_TABLE nowindows out=&OUT_TABLE list COLWIDTH=8 spacing=1 missing;
%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO; weight &wgt;%END;
title1 "2-way RESPONSE ($) for &in_table";
    column &class1 &class2, ( &num_var &denom_var doll_resp) &num_var=a1
&denom_var=a2 tot;  /*don't count the class2 as a column*/

define &class1./group format=&&&class1... ;
define &class2./across format=&&&class2... ;
define &NUM_VAR/SUM format=dollar11. NOPRINT;
define &DENOM_VAR/SUM format=dollar11. NOPRINT;
define a1 / noprint;
define a2 / noprint;
define tot / format=percent8.2 'Total';
define doll_resp/computed format=percent8.2 width=12 ' ';
compute tot;
    %LET J = 4; /*this is all VERY specific to the column statement above*/
    %DO K = 1 %TO &COUNT2; /*these refer to doll_resp*/
        _c%EVAL(&J)_ = _c%EVAL(&J-2)_ / _c%EVAL(&J-1)_;
        %LET J = %EVAL(&J + 3);
    %END;
    tot=a1/a2;
    endcomp;
rbreak after /summarize;
run;
%MEND report_response_dollar;
