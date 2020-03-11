/******************************************************************************************;
****** MACRO NAME               :                                                   ****** ;
****** MODEL DEVELOPED BY       :                                                   ****** ;
****** PROGRAM WRITTEN BY       : Abhinav Sharma                                    ****** ;
****** PROGRAM MODIFIED BY      : Matthew DePoint                                   ****** ;
****** SAS VERSION              : 9.1                                               ****** ;
****** PURPOSE                  :                                                   ****** ;

****** PARAMETERS REQUIRED      :                                                   ****** ;
****** DATASETS REQUIRED        :  WealthScape Information , GMB DATAset            ****** ;
******                                                                              ****** ;
****** VARIABLES                :                                                   ****** ;
******                                                                              ****** ;
****** OUTPUT DATASET           : grwth_model_YYYYMM(MM=Month,YY=Year)              ****** ;
****** HISTORY                                                                      ****** :
****** VALIDATED BY             :                                                   ****** ;
*******************************************************************************************/
%MACRO format_from_rank_v2(in_table,ranked_var,format_label,in_lib=work, groups=10,wgt=);
/********************************************************************************/	
/*	THIS MACRO takes the IN_TABLE, ranks it by the RANKED_VAR into GROUPS	*/
/*	THEN, it creates a FORMAT from those rankings				*/
/*	DEPOINT CHIN, RISCHALL APR2003, DePoint oct2003				*/
/********************************************************************************/	
%IF (%LENGTH(&WGT)=0) %THEN %GOTO NON_WGT_METHOD; 
%ELSE %GOTO WGT_METHOD;

%NON_WGT_METHOD:
PROC RANK DATA=&in_lib..&in_table GROUPS=&groups out=RANK_OUT;
	VAR &ranked_var;
    RANKS RANK1; 
proc means data=RANK_OUT maxdec=0 NOPRINT;
	class RANK1;
	var &ranked_var;
	output out=to_ctrl(drop=_freq_)
			MIN(&ranked_VAR) 	= START
			MAX(&ranked_VAR) 	= END
			;
run;
data to_ctrl;
	set to_ctrl;
	where _type_=1;
	drop	 _type_;
	bin = rank1;
run;
%GOTO FINAL_FORMAT_OUTPUT;
/****************************************************************************/

%WGT_METHOD:
/****************************************************************************************************************/
/* This format creation macro is based upon the lift chart macro created by */
/* WEIGHTED LIFT CHART MACRO (UNIT INCIDENCE)									*/
/* I.Rischall ; A.Chin  29APR2003										*/
/*														*/
/* 	Macro Inputs:												*/
/*		in_lib 		= Input Library									*/
/*		in_table 	= Input Table									*/
/*		ranked_var 		= Ranking Score									*/
/*		wgt		= Weight Variable								*/
/* format_label = macro variable label for the format created*/
/* 		groups		= Number of Bins (e.g., 10 = deciles, 20 = twentiles, etc.)			*/
/****************************************************************************************************************/
data step_pre; set &in_lib..&in_table;
run;
proc sort data = step_pre (where = (&ranked_var ne .)) out = step1;
  by &ranked_var;
run;
data step2;
   set step1 end = last;
   retain cumulative 0;
   cumulative + &wgt;
   if last then do;
      call symput('totpop',left(cumulative));
   end;
run;
data step3 (keep = &ranked_var bin percentile);
	set step2;
	by  &ranked_var;
	percentile=((cumulative/&totpop)*100);

	do i = 1 to &groups;
	if percentile > (i-1)*100/&groups
	& percentile le i*100/&groups then bin=i;
	end;
	if percentile > 100 and bin = . then bin = &groups;
	if last.&ranked_var;
run;
data step4;
	merge step3 step2;
	by &ranked_var;
run;
proc report data = step4 nowindows headline headskip missing out = to_ctrl;
	column 	
  		bin
		&ranked_var = START
		&ranked_var = END
		;
	weight &wgt;
	define bin / group format=2. width=9 'Score Bin' noprint;
	define START / analysis min format=6.0  width = 9 'Minimum ' noprint;
	define END / analysis max format=6.0 width = 9 'Maximum ' noprint;
run;
proc sort data=to_ctrl; by bin;
%GOTO FINAL_FORMAT_OUTPUT;
/****************************************************************************/

%FINAL_FORMAT_OUTPUT:
  %global &format_label;
  %let &FORMAT_LABEL=;
  %let &FORMAT_label = %SUBSTR(&ranked_var,1,7);

  data ctrl;
     set to_ctrl(keep = start end bin) end=last;
     retain fmtname "&&&FORMAT_label" type 'n';
     if last then hlo='h';
     else hlo =' ';
     format label $80.;
     /*if start >=10 then*/ label = compress(bin||'*'||START||' - '||END);
   run;

proc format library=work cntlin=ctrl;
/*proc format library=work fmtlib;*/
proc print data=ctrl noobs;
title "format for &in_table based upon &ranked_var with &groups breaks &WGT";
run;
%MEND format_from_rank_v2;

%MACRO get_most_recent_cust_table_info(in_lib=,table_type=ACCT,cust_table_date=);
ODS LISTING CLOSE;
ODS OUTPUT MEMBERS=mem;
PROC DATASETS LIBRARY=&in_lib ; RUN; QUIT;
ODS OUTPUT close;
DATA table_names;
	SET mem (KEEP=name rename=(name=memname));
%IF %UPCASE(&table_type) = ACCT %THEN %DO;
		IF INDEX(UPCASE(memname),'CUST_ACCT_') 
		AND NOT index(UPCASE(memname),'CUST_ACCT_200807B')
		AND NOT index(UPCASE(memname),'CUST_ACCT_200808B')
		AND NOT index(UPCASE(memname),'CUST_ACCT_200808_B')
		AND NOT index(UPCASE(memname),'CUST_ACCT_200809_21OCT2008') 
		AND NOT index(UPCASE(memname),'SUM_CUST_ACCT_200804') 
                AND NOT index(UPCASE(memname),'CUST_ACCT_200812_BKP')
                AND NOT index(UPCASE(memname),'CUST_ACCT_200810_BACKUP_28NOV08')
                AND NOT index(UPCASE(memname),'CUST_ACCT_200809_21OCT2008')        
              AND NOT index(UPCASE(memname),'CUST_ACCT_200903_OLD')  
 	;
%END;

	date_STRING 	= COMPRESS(SUBSTR(memname,11,6));
RUN;
ODS LISTING;

DATA updated_date_table; SET table_names;
FORMAT date_string_n 8.0;
	date_string_n = date_string;
RUN;
PROC SQL;
	SELECT MAX(date_string_n) INTO: max_dt_post 
	FROM updated_date_table
	;
%GLOBAL &cust_table_date;
%LET &cust_table_date = %CMPRES(&&max_dt_post);
%PUT &max_dt_post &&&cust_table_date;

%MEND get_most_recent_cust_table_info;

%MACRO pull_cust_data(cust_lib=,cust_table=,out_lib=work,out_table=,cust_var_list=);
/* attach to Wealthscape information using con_cst_id	*/

DATA &out_lib..&out_table; SET &cust_lib..&cust_table;
	WHERE class_tp NE 'N' AND client_in NE 'C' AND  private NE 1;
	KEEP con_cst_id &cust_var_list;
RUN;
%MEND pull_cust_data;

%MACRO pull_wsc_liquid(wsc_lib=,wsc_table=,wsc_liq_var_list=, out_lib=,out_table=,liq_med_table=);
/**********************/
/* we assume that the WC table was prepared at the con_cst_id level	*/
/**********************/

%LET wsc_liq_var_list_sql=con_cst_id;

%STRING_LOOP(var_list=%QUOTE(&wsc_liq_var_list),
				ACTION_CODE=%NRSTR(%LET wsc_liq_var_list_sql= &wsc_liq_var_list_sql, &&word&i; )
				);

PROC SQL;
CREATE TABLE &out_lib..&out_table AS 
    SELECT %UNQUOTE(&wsc_liq_var_list_sql)
	FROM &wsc_lib..&wsc_table 
	ORDER BY con_cst_id
	;
QUIT;

/**********************************/
/*	CALC liquid MEDIANS for miss replace	*/
/**********************************/
PROC Means DATA=&out_lib..&out_table Qmethod=P2 Qmarkers=7 Min Mean Median Max;
    Var &wsc_liq_var_list;
OUTPUT

	%STRING_LOOP( var_list=%QUOTE(&wsc_liq_var_list),
					ACTION_CODE=%NRSTR(Median(&&word&i)=med_&&word&i )
					)
    OUT=&out_lib..&liq_med_table;
RUN;
%MEND pull_wsc_liquid;

/*******************************************************/
/**********BEGIN MAIN PROGRAM					***********/
/*******************************************************/
LIBNAME glib "/camidata/SAS_DWH/GMB_output";
LIBNAME dwh "/camidata/SAS_DWH";
LIBNAME attr  '/camidata/SAS_DWH/cust_attr_score';
LIBNAME wsc '/camidata/common/data/';

LIBNAME loc './';

%LET wsc_table = liq_con_cst_id200911;
%LET wsc_lib = wsc;
%LET wsc_dep_var = liq_very_nonrrsp;
%LET wsc_inv_var = LIQ_INV_RRSP;
%LET wsc_liq_var = liq_with_rrsp;
/*******
	LIQ_perfect			= 'WSCHQSAVB /WSHHDTOT cashable within 24 hours'
	LIQ_very_nonrrsp		= 'SUM(WSCHQSAVB,WSGICTORB) /WSHHDTOT cashable within a week or so with limited penalty'
	LIQ_non_rrsp			= 'WSNRRSPB / WSHHDTOT cashable within a month or so with some penalty'
	LIQ_INV_nonrrsp		= 'SUM(WSSTOKORB,WSBONDORB,WSFUNDORB) /WSHHDTOT cashable within a month or so with some penalty'
	LIQ_INV_RRSP 			= 'WSINVESTB / WSHHDTOT cashable within a month or so with some penalty'
	LIQ_with_RRSP			= 'WSLIQASTV /  WSHHDTOT cashable within a month or so with some penalty'
*********/

%LET wsc_23liq_var_list	= &wsc_liq_var &wsc_dep_var &wsc_inv_var;

%LET cust_dep_var = DEP_bal_avg3;
%LET cust_inv_var = INVST_bal_avg3;
%LET cust_tot_var = tot_cr_bal_avg3;
%LET cust_table_var_list = 	&cust_dep_var &cust_inv_var &cust_tot_var
								INVST_cnt1 DEP_cnt1  tot_cr_cnt1 TENURE;

%LET final_lib 	= work;
%LET final_table	= growth_pfs_hbca;


/****************************************************/
/*	PULL CUSTOMER DATA									*/
/****************************************************/
%get_most_recent_cust_table_info(in_lib=dwh,cust_table_date=curr_cust_tbl_dt);
%pull_cust_data(cust_lib=glib,cust_table=gmb_production_&curr_cust_tbl_dt,out_table=cust_23table,cust_var_list=&cust_table_var_list);

/****************************************************/
/*	PULL WSC Liquid asset DATA							*/
/****************************************************/
%pull_wsc_liquid(wsc_lib=wsc,wsc_table=liq_con_cst_id&curr_cust_tbl_dt,
						wsc_liq_var_list=%QUOTE(&wsc_23liq_var_list),out_lib=work,out_table=from_liq,liq_med_table=from_liq_med);

PROC CONTENTS;RUN;
/****************************************************/
/*	COMBINE cust and Wealthscape						*/
/*	CALCULATE SOW											*/
/***************************************************/
PROC SQL;
	CREATE TABLE cust_liquid AS
	SELECT 
	a.*, b.*
	FROM cust_23table a LEFT JOIN from_liq b 
	ON a.con_cst_id = b.con_cst_id 
	ORDER BY a.con_cst_id
	;
QUIT;

DATA SOWa; 
    IF _N_ = 1 THEN DO;		SET from_liq_med( Keep=med_&wsc_dep_var med_&wsc_inv_var med_&wsc_liq_var); 	END;
    Set cust_liquid;
	
    IF NOT MISSING(&wsc_liq_var)  THEN Wsc_Total_Assets = &wsc_liq_var;	ELSE Wsc_Total_Assets  = med_&wsc_liq_var;
    IF NOT MISSING(&wsc_dep_var)	THEN Wsc_Deposit_Assets = &wsc_dep_var;	ELSE Wsc_Deposit_Assets = med_&wsc_dep_var;
    IF NOT MISSING(&wsc_inv_var)	THEN Wsc_Invest_Assets = &wsc_inv_var;	ELSE Wsc_Invest_Assets = med_&wsc_inv_var;

    /*Share Of Wallet */
    IF wsc_Total_Assets   NE 0		THEN Sow_Tot = &cust_tot_var / wsc_Total_Assets;       /*Deposit&Investment Only*******/
    IF wsc_Deposit_Assets NE 0		THEN Sow_Dep = &cust_dep_var / wsc_Deposit_Assets;        /*Deposit*******/
    IF wsc_Invest_Assets  NE 0		THEN Sow_Inv = &cust_INV_var / wsc_Invest_Assets;       /*Investment *******/

  ************  for tagging credit only customers**********;
    IF DEP_cnt1 = 0            AND
       INVST_cnt1 =0           AND 
       &cust_inv_var = 0       AND
       &cust_tot_var = 0     	THEN Group='C';
    								ELSE Group='O';
    IF tenure > 3;
RUN;

/****************************************************/
/*	CALCULATE Attrition Median						*/
/***************************************************/
		/*omit for now because we do not have a score that rank orders depletetion probabilities	*/



/****************************************************/
/*	CALCULATE SOW Median	for miss replace				*/
/***************************************************/
PROC MEANS DATA=SOWa(Keep=Sow_Tot Sow_Dep Sow_Inv Group) Qmethod=P2 Qmarkers=7 Min Mean Median Max;
	VAR Sow_Tot Sow_Dep Sow_Inv;
OUTPUT Median(Sow_Tot)=Med_Sow_Tot Median(Sow_Dep)=Med_Sow_Dep Median(Sow_Inv)=Med_Sow_Inv
		Out=SOW_median;
		Where Group='O';
RUN;
/****************************************************/
/*	CALCULATE Growth Opportunity						*/
/***************************************************/
DATA pfs_growth;
    IF _N_ = 1 THEN Set Sow_median(Keep=Med_Sow_Tot Med_Sow_Dep Med_Sow_Inv);
    Set SOWa;
		*(Keep= con_cst_id Group Sow_: wsc_total_Assets wsc_Deposit_Assets wsc_Invest_Assets);
        IF Group='C' THEN Do;
            Sow_Tot_M =Med_Sow_Tot ;
            Sow_Dep_M=Med_Sow_Dep;
            Sow_Inv_M = Med_Sow_Inv;
        End;
        ELSE IF Group='O' THEN Do;
            Sow_Tot_M = Sow_Tot ;
            Sow_Dep_M=  Sow_Dep;
            Sow_Inv_M = Sow_Inv;
        End;
    IF Sow_Tot_M <0 THEN Sow_Tot_M=0;
    ELSE IF Sow_Tot_M >1 THEN Sow_Tot_M=1;
    IF Sow_Dep_M <0 THEN Sow_Dep_M=0;
    ELSE IF Sow_Dep_M >1 THEN Sow_Dep_M=1;
    IF Sow_Inv_M <0 THEN Sow_Inv_M=0;
    ELSE IF Sow_Inv_M >1 THEN Sow_Inv_M=1;
    Overall_Opportunity         =   (1- Sow_Tot_M)*wsc_Total_Assets;
    Deposit_Opportunity         =   (1-Sow_Dep_M)*wsc_Deposit_Assets;
    Invest_Opportunity          =   (1-Sow_Inv_M)*wsc_Invest_Assets;

	med_attr=0; /*SKIP THIS PART (see above)*/
    Overall_Growth_Opportunity  =   Overall_Opportunity *(1-Med_attr);
    Deposit_Growth_Opportunity  =   Deposit_Opportunity*(1-Med_attr);
    Invest_Growth_Opportunity   =   Invest_Opportunity*(1-Med_attr);

RUN;

/****************************************************/
/*	CALCULATE Growth Opportunity BUCKETS				*/
/***************************************************/

PROC FORMAT;
	VALUE g_rank
	1	= 'VL'
	2	= 'L'
	3	= 'M'
	4 	= 'H'
	5	= 'VH'
	OTHER = 'BAD CODE'
	;

/* THESE are dynamic now, but need to be hard coded at some point	*/
/* one could modify this macro a bit to create the g_rank values above	*/
%format_from_rank_v2(in_table=pfs_growth,ranked_var=overall_growth_opportunity,format_label=overall_growth,in_lib=work, groups=5,wgt=);
%format_from_rank_v2(in_table=pfs_growth,ranked_var=deposit_growth_opportunity,format_label=dep_growth,in_lib=work, groups=5,wgt=);
%format_from_rank_V2(in_table=pfs_growth,ranked_var=invest_growth_opportunity,format_label=inv_growth,in_lib=work, groups=5,wgt=);

/*PROC PRINT DATA=to_ctrl;*/

DATA &final_lib..&final_table;SET pfs_growth ;

	FORMAT Growth_Rtl_Grp Growth_Rtl_Dep_Grp Growth_Rtl_INV_Grp $32.;
	Growth_Rtl_Grp = PUT(overall_growth_opportunity, &overall_growth..);
	Growth_Rtl_dep_Grp = PUT(deposit_growth_opportunity, &dep_growth..);
	Growth_Rtl_inv_Grp = PUT(invest_growth_opportunity, &inv_growth..);

	RENAME 
    Overall_Growth_Opportunity	= Growth_Rtl_Scr
    Deposit_Growth_Opportunity = Growth_Rtl_Dep 
    Invest_Growth_Opportunity	= Growth_Rtl_Inv
	;
	DROP Med_Sow_Tot Med_Sow_Dep Med_Sow_Inv Sow_Tot Sow_Dep Sow_Inv 
         wsc_total_Assets wsc_Deposit_Assets wsc_Invest_Assets Group;

	*KEEP 	con_cst_id Growth_Rtl_Grp Growth_Rtl_Dep_Grp Growth_Rtl_INV_Grp
			Overall_Growth_Opportunity Deposit_Growth_Opportunity Invest_Growth_Opportunity
	;
RUN;
PROC CONTENTS;RUN;

PROC FREQ DATA=&syslast;
	TABLES Growth_Rtl_Grp Growth_Rtl_Dep_Grp Growth_Rtl_INV_Grp;
RUN;

DATA analysis; SET &final_lib..&final_table;
COUNT=1;
RUN;


%LET m_list = &cust_table_var_list Growth_Rtl_Scr Growth_Rtl_dep Growth_Rtl_inv;
%LET p_list = ;
%LET s_list = ;

%LET growth_loop_list = Growth_Rtl_Grp Growth_Rtl_Dep_Grp Growth_Rtl_INV_Grp;

ODS HTML FILE='examine_growth_measures_raw_v1.xls' STYLE=minimal;
%STRING_LOOP(var_list=%QUOTE(&growth_loop_list),
ACTION_CODE=%NRSTR(
%LET &&word&i = $32;
%tabulate_wizard(in_lib = work, out_lib = work, in_table=analysis, out_table=testa, 
		class_list_row=&&word&i, 
		class_list_col=, 
		N_VAR_LIST=count, MEAN_VAR_LIST=&m_list &p_list, MEDIAN_VAR_LIST=,
		min_var_list=,max_var_list=,sum_var_list=&s_list,std_var_list=, 
		row_pct_list=, col_pct_list=, pct_sum_list=, in_weight=, 
		where_extra=, 
		in_rts=30, mylabel="&&word&i", var_label='', 
		display_stat=YES, all_toggle_row=ALL # #, all_toggle_col= ALL # #, 
	all_wrapper=,var_format=comma20.4);
)
);
ODS HTML CLOSE;
ENDSAS;
**********************************************************************************;
**********************************************************************************;
**********************************************************************************;


