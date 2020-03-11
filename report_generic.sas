%macro report_generic(in_lib=work,in_table=,class_var_list=,wgt=,capt_pct_var_list=,
 pct_var_list=,min_var_list=,max_var_list=,sum_var_list=,mean_var_list=,std_var_list=,
 num_var_list=,denom_var_list=,exclusion=,out_table=tab_blah);

/****************************************************************************************************************/
/*CODE ORIGINATED FROM MACRO TABULATE_LIFT_CHART_WGT                                                            */
/*                                                                                                              */
/*WEIGHTED LIFT CHART MACRO (UNIT INCIDENCE AND BALANCE)                                                        */
/* I.Rischall ; A.Chin  29APR2003                                                                               */
/*                                                                                                              */
/*   Macro generates WEIGHTED one-way lift chart of UNIT INCIDENCE and associated BALANCE                       */
/*   If WGT option is left blank, a non-weighted lift table will be generated.                                  */
/*                                                                                                              */
/*      Macro Inputs:                                                                                           */
/*              in_lib          = Input Library                                                                 */
/*              in_table        = Input Table                                                                   */
/*                               */
/*              sort_order      = DESCENDING | <blank>  (blank implies ascending sort [risk score])             */
/*              exclusion       = <blank>; otherwise, macro will omit scores le 10 (assuming exclusions are     */
/*                                      coded with scores < 10                                                  */
/****************************************************************************************************************/

/****************************************************************************************************************/
/*UPDATED 26JAN2004 (VAR_LIST ADDITIONS)                                                                        */
/*S. Ringel                                                                                                     */
/*The macro generates the following columns automatically:                                                      */
/* Est. population                                                                                              */
/* Percent of Est Population                                                                                    */
/* Cumulative percent of Est population                                                                         */
/*The following var_list's have been added:                                                                     */
/* capt_pct_var_list                                                                                                 */
/* sum_var_list                                                                                                 */
/* mean_var_list                                                                                                */
/* min_var_list                                                                                                 */
/* max_var_list                                                                                                 */
/* std_var_list                                                                                                 */
/****************************************************************************************************************/

%if %EVAL(%LENGTH(&WGT)=0) %THEN %DO;
 %let col_title=;
%end;
%else %do;
 %let col_title=Weighted;
%end;
 

%local i;
%let j=0;
%let i=0;
        %DO %UNTIL (&word_length=0);
                %let i = %eval(&i+1);
                %let word&i = %scan(&num_var_list,&i,%str( ));
                %let word_length = %LENGTH(&&word&i);
                %IF &word_length ne 0 %THEN %DO;
                        %let j=&i;
                        %END;
        %END;

%let ratio_var_code_create=;
%let ratio_var_code_column=;
%let ratio_var_code_column2=;
%let ratio_var_code_define_npr=;
%let ratio_var_code_define=;
%do k=1 %to &j;
 %let ratio_var_code_column=&ratio_var_code_column ratio_&k;
 %let ratio_var_code_column2=&ratio_var_code_column2 %scan(&num_var_list,&k) %scan(&denom_var_list,&k);
 %let ratio_var_code_create=&ratio_var_code_create compute ratio_&k %str(;) 
    if %scan(&denom_var_list,&k).sum ne 0 then do %str(;)
    ratio_&k=%scan(&num_var_list,&k).sum / %scan(&denom_var_list,&k).sum %str(;) end %str(;) endcomp %str(;);
 %let ratio_var_code_define_npr=&ratio_var_code_define_npr define %scan(&num_var_list,&k)
   /analysis sum noprint%str(;) define %scan(&denom_var_list,&k)/analysis sum noprint %str(;);
 %let ratio_var_code_define=&ratio_var_code_define define ratio_&k
   /computed format=percent8.2 width=9 "Ratio of %scan(&num_var_list,&k) over %scan(&denom_var_list,&k)"%str(;);
%end;

%local i;
%let j=0;
%let i=0;
        %DO %UNTIL (&word_length=0);
                %let i = %eval(&i+1);
                %let word&i = %scan(&pct_var_list,&i,%str( ));
                %let word_length = %LENGTH(&&word&i);
                %IF &word_length ne 0 %THEN %DO;
                        %let j=&i;
                        %END;
        %END;


%let pct_var_code_create=;
%let pct_var_code_column=;
%let pct_var_code_define_npr=;
%let pct_var_code_define=;
%let pct_var_code_column2=;
%let pct_var_code_column3=;
%do k=1 %to &j;
%let pct_var_code_column=&pct_var_code_column pct_&k;

%let pct_var_code_column2=&pct_var_code_column2 %scan(&pct_var_list,&k);
%let pct_var_code_column3=&pct_var_code_column3 %scan(&pct_var_list,&k)=%scan(&pct_var_list,&k);
%let pct_var_code_create=&pct_var_code_create compute pct_&k %str(;)
      pct_&k=%scan(&pct_var_list,&k).sum / dummy.sum %str(;) endcomp %str(;);
%let pct_var_code_define_npr=&pct_var_code_define_npr define %scan(&pct_var_list,&k) / analysis sum noprint %str(;)
      define dummy/analysis sum noprint %str(;);
%let pct_var_code_define=&pct_var_code_define define pct_&k /computed format=percent8.2 width=9
      "Percent of %scan(&pct_var_list,&k)" %str(;);
%end;

%if &j > 0 %then %do;
 %let pct_var_code_column2=&pct_var_code_column2 dummy;
 %let pct_var_code_column3=&pct_var_code_column3 dummy=dummy;
%end;

%put &pct_var_code_column2;

%let sort_code=;
%string_loop(var_list=&class_var_list,
             action_code = %NRSTR(%LET sort_code = &sort_code &&word&i);

                        )
;

%let format_code=;
%string_loop(var_list=&class_var_list,
             action_code = %NRSTR(%LET format_code = &format_code 
                           value $&&word&i low-high=[&&&&&&word&i...32.] %str(;));

                        )
;

proc format;
&format_code;
run;

%let bin_code=;
%string_loop(var_list=&class_var_list,
             action_code = %NRSTR(%LET bin_code = &bin_code length bin_&&word&i $32. %str(;)
               if &&word&i ne . then bin_&&word&i=put(&&word&i,&&&&&&word&i....) %str(;)
               else bin_&&word&i='Total' %str(;));

                        )
;

%let bin_column=;
%LET bin_column_rename=;
%string_loop(var_list=&class_var_list,
             action_code = %NRSTR(	%LET bin_column = &bin_column bin_&&word&i; 
									%LET bin_column_rename = &bin_column_rename bin_&&word&i=&&word&i;
								);

                        )


%let score_define=;
%string_loop(var_list=&class_var_list,
             action_code = %NRSTR(%LET score_define = &score_define define bin_&&word&i/group "&&word&i" width=32
             %str(;));

                        )
;

%let score_define_npr=;
%string_loop(var_list=&class_var_list,
             action_code = %NRSTR(%LET score_define_npr = &score_define_npr define &&word&i/group format=&&&&&&word&i....
             noprint %str(;));

                        )
;

%let class1=%scan(&class_var_list,1,' ');


proc sort data=&in_lib..&in_table out=step1;
by &sort_code;

data step2;
        set step1 end=last;
         %IF %EVAL(%LENGTH(&WGT)=0) %THEN %DO; unit_weight=1; %LET WGT=unit_weight; %END;
        retain cumulative 0;
        cumulative + &wgt;
        if last then do;
                call symput('totpop',left(cumulative));
        end;
run;


data step4;
        set step2;
        by &sort_code;
        dummy=1;
run;


%let capt_pct_var_CODE_column=;
%string_loop(var_list=&capt_pct_var_LIST,
             action_code = %NRSTR(%LET capt_pct_var_CODE_column = &capt_pct_var_code_column &&word&i=&&word&i.._pct);

                        )
;


%let capt_pct_var_CODE_keep=;
%string_loop(var_list=&capt_pct_var_LIST,
             action_code = %NRSTR(%LET capt_pct_var_CODE_keep = &capt_pct_var_code_keep &&word&i.._pct);

                        )
;

%let capt_pct_var_CODE_define=;
%string_loop(var_list=&capt_pct_var_LIST,
             action_code = %NRSTR(%LET capt_pct_var_CODE_define = &capt_pct_var_code_define define &&word&i.._pct/
             analysis max format=percent8.2 width=9
             "Captured Percent of &&word&i" %str(;););

                        )
;

%let capt_pct_var_CODE_define_npr=;
%string_loop(var_list=&capt_pct_var_LIST,
             action_code = %NRSTR(%LET capt_pct_var_CODE_define_npr = &capt_pct_var_code_define_npr define &&word&i.._pct/
             analysis pctsum format=percent8.2
             "Captured Percent of &&word&i" noprint %str(;););

                        )
;



%let sum_VAR_CODE_column=;
%string_loop(var_list=&sum_var_LIST,
             action_code = %NRSTR(%LET sum_VAR_CODE_column = &sum_var_code_column &&word&i=&&word&i.._sum);

                        )
;



%let sum_VAR_CODE_keep=;
%string_loop(var_list=&sum_var_LIST,
             action_code = %NRSTR(%LET sum_VAR_CODE_keep = &sum_var_code_keep &&word&i.._sum);

                        )
;

%let sum_VAR_CODE_define=;
%string_loop(var_list=&sum_var_LIST,
             action_code = %NRSTR(%LET sum_VAR_CODE_define = &sum_var_code_define define &&word&i.._sum/analysis sum
                          format=comma14.2 width=9 "Sum of &&word&i" %str(;););

                        )
;

%let sum_VAR_CODE_define_npr=;
%string_loop(var_list=&sum_var_LIST,
             action_code = %NRSTR(%LET sum_VAR_CODE_define_npr = &sum_var_code_define_npr define &&word&i.._sum/analysis sum
                          "Sum of &&word&i" noprint %str(;););

                        )
;

%let min_VAR_CODE_column=;
%string_loop(var_list=&min_var_LIST,
             action_code = %NRSTR(%LET min_VAR_CODE_column = &min_var_code_column &&word&i=&&word&i.._min);

                        )
;

%let min_VAR_CODE_keep=;
%string_loop(var_list=&min_var_LIST,
             action_code = %NRSTR(%LET min_VAR_CODE_keep = &min_var_code_keep &&word&i.._min);

                        )
;

%let min_VAR_CODE_define=;
%string_loop(var_list=&min_var_LIST,
             action_code = %NRSTR(%LET min_VAR_CODE_define = &min_var_code_define define &&word&i.._min/analysis min
             format=comma14.2 width=9 "Min of &&word&i" %str(;););

                        )
;

%let min_VAR_CODE_define_npr=;
%string_loop(var_list=&min_var_LIST,
             action_code = %NRSTR(%LET min_VAR_CODE_define_npr = &min_var_code_define_npr define &&word&i.._min/analysis min
             "Min of &&word&i" noprint %str(;););

                        )
;

%let max_VAR_CODE_column=;
%string_loop(var_list=&max_var_LIST,
             action_code = %NRSTR(%LET max_VAR_CODE_column = &max_var_code_column &&word&i=&&word&i.._max);

                        )
;

%let max_VAR_CODE_keep=;
%string_loop(var_list=&max_var_LIST,
             action_code = %NRSTR(%LET max_VAR_CODE_keep = &max_var_code_keep &&word&i.._max);

                        )
;

%let max_VAR_CODE_define=;
%string_loop(var_list=&max_var_LIST,
            action_code = %NRSTR(%LET max_VAR_CODE_define = &max_var_code_define define &&word&i.._max/analysis max
            format=comma14.2 "Max of &&word&i" width=9 %str(;););

                        )
;

%let max_VAR_CODE_define_npr=;
%string_loop(var_list=&max_var_LIST,
            action_code = %NRSTR(%LET max_VAR_CODE_define_npr = &max_var_code_define_npr define &&word&i.._max/analysis max
            "Max of &&word&i" noprint %str(;););

                        )
;

%let mean_VAR_CODE_column=;
%string_loop(var_list=&mean_var_LIST,
            action_code = %NRSTR(%LET mean_VAR_CODE_column = &mean_var_code_column &&word&i=&&word&i.._mean);

                        )
;

%let mean_VAR_CODE_keep=;
%string_loop(var_list=&mean_var_LIST,
            action_code = %NRSTR(%LET mean_VAR_CODE_keep = &mean_var_code_keep &&word&i.._mean);

                        )
;

%let mean_VAR_CODE_define=;
%string_loop(var_list=&mean_var_LIST,
             action_code = %NRSTR(%LET mean_VAR_CODE_define = &mean_var_code_define define &&word&i.._mean/analysis mean
             "Mean of &&word&i" format=comma14.2 width=9 %str(;););

                        )
;

%let mean_VAR_CODE_define_npr=;
%string_loop(var_list=&mean_var_LIST,
             action_code = %NRSTR(%LET mean_VAR_CODE_define_npr = &mean_var_code_define_npr define &&word&i.._mean/analysis mean
             "Mean of &&word&i" noprint %str(;););

                        )
;

%let std_VAR_CODE_column=;
%string_loop(var_list=&std_var_LIST,
            action_code = %NRSTR(%LET std_VAR_CODE_column = &std_var_code_column &&word&i=&&word&i.._std);

                        )
;

%let std_VAR_CODE_keep=;
%string_loop(var_list=&std_var_LIST,
            action_code = %NRSTR(%LET std_VAR_CODE_keep = &std_var_code_keep &&word&i.._std);

                        )
;

%let std_VAR_CODE_define=;
%string_loop(var_list=&std_var_LIST,
             action_code = %NRSTR(%LET std_VAR_CODE_define = &std_var_code_define define &&word&i.._std/analysis max
             format=8.2 width=9 "Standard Deviation of &&word&i" %str(;););

                        )
;

%let std_VAR_CODE_define_npr=;
%string_loop(var_list=&std_var_LIST,
             action_code = %NRSTR(%LET std_VAR_CODE_define_npr = &std_var_code_define_npr define &&word&i.._std/analysis std
             "Standard Deviation of &&word&i" noprint %str(;););

                        )
;



proc report data=step4 nowindows headline headskip missing out = unwgted;
        column  &sort_code
                n
                pctn
                &wgt
                &wgt = wgt_pct
        ;

        &score_define_npr;
        define n / format=comma9. width=9 'Number of Accounts' noprint;
        define pctn / format=percent6.2 width=9  ' Percent of Accounts' noprint;
        define &wgt / analysis sum format=comma9. 'Sum of Weights' noprint;
        define wgt_pct / analysis pctsum format = percent8.2 'Percent Sum of Weights' noprint;

        rbreak after / dol dul summarize;
        *title 'Lift Table';
run;

proc sort data=unwgted;
        by &sort_code;
run;

proc report data=step4 nowindows headline headskip missing out = wgted;
        column  &sort_code
                n
                pctn
                &wgt
                &wgt = wgt_pct

  &min_var_code_column
  &max_var_code_column
  &sum_var_code_column
  &mean_var_code_column
  &capt_pct_var_code_column
  &std_var_code_column
  &ratio_var_code_column2
  &pct_var_code_column3
;
        weight &wgt;

        &score_define_npr;
        define n / format=comma9. width=9 'Number of Accounts' noprint;
        define pctn / format=percent6.2 width=9  ' Percent of Accounts' noprint;
        define &wgt / analysis sum format=comma9. 'Sum of Weights' noprint;
        define wgt_pct / analysis pctsum format = percent8.2 'Percent Sum of Weights' noprint;

 &min_var_code_define_npr;
 &max_var_code_define_npr;
 &sum_var_code_define_npr;
 &mean_var_code_define_npr;
 &capt_pct_var_code_define_npr;
 &std_var_code_define_npr;
 &ratio_var_code_define_npr;
 &pct_var_code_define_npr;
        rbreak after / dol dul summarize;
run;

proc sort data=wgted;
        by &sort_code;
run;

data wgted;
        set wgted (keep = &sort_code
           &capt_pct_var_code_keep &min_var_code_keep &max_var_code_keep &mean_var_code_keep
           &sum_var_code_keep &std_var_code_keep &ratio_var_code_column2 &pct_var_code_column2);
        length bin2 $16.;

        if &class1 ne . then bin2 = put(&class1, &&&class1...);
        else if &class1 = . then bin2 = "Total";
        if upcase(substr(bin2,1,7))= 'EXCLUDE' then bin2='.'||bin2;
run;

proc sort data=wgted;
        by bin2;
run;


data unwgted;
        set unwgted (keep = &sort_code n pctn &wgt wgt_pct);
       length bin2 $16.;
        rename n = num;
        rename pctn = pctnum;

       if &class1 ne . then bin2 = put(&class1, &&&class1...);
        else if &class1 = . then bin2 = "Total";
       if upcase(substr(bin2,1,7))= 'EXCLUDE' then bin2='.'||bin2;

run;

proc sort data=unwgted;
        by bin2;
run;

data unwgted;
        set unwgted;

        retain cum_wgt 0;
        cum_wgt + wgt_pct;
        if bin2 = "Total" then cum_wgt = 1;
run;

proc sort data = unwgted;
        by bin2;
run;

data wgt_lift;
        merge unwgted wgted;
        by bin2;
        &bin_code;
run;

proc report data=wgt_lift nowindows headline headskip missing out=&out_table(rename = (&bin_column_rename));
        column  bin2 
                &bin_column
                
                num
                pctnum

                &wgt
                wgt_pct

                &wgt    = est_pop
                wgt_pct = est_pop_pct
                cum_wgt
  &min_var_code_keep
  &max_var_code_keep
  &sum_var_code_keep
  &mean_var_code_keep
  &capt_pct_var_code_keep
  &std_var_code_keep
  &ratio_var_code_column2
  &ratio_var_code_column
  &pct_var_code_column3
  &pct_var_code_column
        ;
        
        define bin2 / order order=data format=$8. width=9 'Score Bin' noprint;
        &score_define;
       
        define num / analysis sum format=comma14. width=9 'Number in Sample' noprint;
        define pctnum /analysis sum format=percent6.2 width=9  ' Percent of Sample' noprint;

        define &wgt / analysis sum format=comma14. width=10 "&col_title Number in Sample" NOPRINT;
        define wgt_pct / analysis sum format = percent8.2 width=12 "&col_title Percent of Sample" NOPRINT;

        define est_pop / analysis sum format=comma14. width=10 "&col_title Number in Sample";
        define est_pop_pct / analysis sum format = percent8.2 width=12 "&col_title Percent of Sample";
        define cum_wgt / analysis max format = percent8.2 width=12 "&col_title Cumulative Percent of Sample" noprint;
 &min_var_code_define;
 &max_var_code_define;
 &sum_var_code_define;
 &mean_var_code_define;
 &capt_pct_var_code_define;
 &std_var_code_define;
 &ratio_var_code_define_npr;
 &ratio_var_code_define;
 &pct_var_code_define_npr;
 &pct_var_code_define;
 
  &ratio_var_code_create;
  &pct_var_code_create;
quit;

%mend report_generic;
