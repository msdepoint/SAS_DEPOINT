%macro ks_wgt(in_lib=,in_table=,score=,the_var=,wgt=,ks_stat=ks_stat,print=Y);

/****************************************************************************************************************/
/* COMPUTE WEIGHTED KS-STATISTIC USING SCORE AS RANK INDEX                                                      */
/* I.Rischall ; A.Chin  29APR2003                                                                               */
/*     modified by DePoint Jun2003                                                                              */
/*   Macro generates WEIGHTED KS-Statistic                                                                      */
/*                                                                                                              */
/*      Macro Inputs:                                                                                           */
/*              in_lib          = Input Library                                                                 */
/*              in_table        = Input Table                                                                   */
/*              score           = Ranking Score (or independent/explanatory variable)                           */
/*              the_var         = The Dependent Variable (binary)                                               */
/*              wgt             = Weight Variable                                                               */
/*              print           = Y|<other value> ; print or suppress output                                    */
/*                                                                                                              */
/*      OUTPUT:  KS-STATISTIC                                                                                   */
/****************************************************************************************************************/
proc sort data=&in_lib..&in_table (where = (&score ne .)) out = sort_out(keep=&score &the_var &wgt);
   by &score;
run;

data ks_one;
   set sort_out end=last;
   retain cumgood 0 cumbad 0;
   %IF %LENGTH(&WGT) = 0 %THEN %DO; %let wgt = 1; %END;
   if &the_var = 0 then cumgood + &wgt;
   else if &the_var = 1 then cumbad + &wgt;
   if last then do;
      call symput('tgoods',left(cumgood));
      call symput('tbads',left(cumbad));
   end;
run;

data ks_two(keep=&score pctdiff);
   set ks_one;
   by &score;
   pctdiff=abs((cumgood/&tgoods-cumbad/&tbads)*100);
   if last.&score;
run;

proc univariate data = ks_two noprint;
   var pctdiff;
   output out = ksdata max = ks_value;
run;

data _null_;
   set ksdata;
   call symput("&ks_stat",trim(left(ks_value)));
run;

data ksdata; set ksdata;
	format variable $125.;
	VARIABLE = "&THE_VAR"; 
	LABEL KS_VALUE = "KS of &SCORE in predicting &THE_VAR";	
run;

%if %upcase(&print) = Y %then %do;
  title "Weighted KS-Statistic for %upcase(&the_var) Detection WEIGHT = &WGT";
  proc print data=ksdata NOOBS LABEL WIDTH=FULL;
    VAR VARIABLE KS_VALUE;
  run;
%end;

%mend ks_wgt;

