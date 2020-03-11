%macro ks_rank(in_lib=,in_table=,out_lib=work,out_table=ks_keep,ind_var_list=,dep_var=,wgt=);
/************************************************************************************************/
/*  KS-STATISTIC RANK                                                                           */
/*  AC  09FEB2004                                                                               */
/*                                                                                              */
/*  Purpose:  This macro takes a list of independent variables and calculates KS-statistics     */
/*            against a specified dependent variable.  The macro outputs all KS-statistics      */
/*            using a descending rank into a .lst file, as well as specific table location      */
/*            permanent, if desired).                                                           */
/*                                                                                              */
/*            WORKS ONLY FOR NUMERIC, NON-DATE INDEPENDENT VARIABLES.  MACRO WILL               */
/*            REMOVE CHARACTER AND DATE VARIABLES IN INDEPENDENT VARIABLE LIST.                 */
/*                                                                                              */
/*  Inputs:   in_lib          = input library                                                   */
/*            in_table        = input table                                                     */
/*            out_lib         = output library                                                  */
/*            out_table       = output table                                                    */
/*            ind_var_list    = independent variable list; %bquote() is useful with this        */
/*            dep_var         = dependent variable                                              */
/************************************************************************************************/

/*********************************** BEGIN NUMERIC CHECK ****************************************/
    
data ksnumtest;
  set &in_lib..&in_table(obs=1);
  keep &ind_var_list;
run;

%get_var_names(in_lib=work,in_table=ksnumtest,out_table=list1,
  var_list_name=list1,
  out_lib=work, keep1=%QUOTE(name format), drop_list=%QUOTE());
 
data ksnumeric;
  set list1;
  if MISSING(format) then output ksnumeric;
run;

%get_values(in_lib=work,in_table=ksnumeric,var_list_name=varlist,
  var_name=name);
 
%put &varlist;

/************************************ END NUMERIC CHECK ****************************************/


%local i;
%let i = 0;

%do %until (&var_length = 0);
  %let i = %eval(&i + 1);
  %let var&i = %scan(&varlist, &i, %str( ));
  %let var_length = %length(&&var&i);

  %if &var_length > 0 %then %do;
     %ks_wgt(in_lib=&in_lib.,in_table=&in_table.,score=&&var&i,the_var=&dep_var,print=N,wgt=&wgt);

     data _null_;
       set ksdata;
       call symput('ks_value',ks_value);
     run;

     data stack;
       length ind_varname dep_varname $32.;
       ind_varname = "&&var&i";
       dep_varname = "&dep_var";
       ks_value = &ks_value;
     run;

     data &out_lib..&out_table;
       %if &i = 1 %then %do;
          set stack;
       %end;
       %else %do;
         set &out_lib..&out_table stack;
       %end;
     run;
  %end;
%end;

proc sort data=&out_lib..&out_table;
  by descending ks_value;
run;

proc print data=&out_lib..&out_table;
run;

/*********************************** KS RANK MACRO ENDS ****************************************/
%mend;
