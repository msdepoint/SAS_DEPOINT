
%MACRO format_with_exclusions(in_table,ranked_var,format_label,in_lib=work, groups=10,wgt=);
/********************************************************************************/	
/*	THIS MACRO takes the IN_TABLE, ranks it by the RANKED_VAR into GROUPS	*/
/*	THEN, it creates a FORMAT from those rankings				*/
/*	With default formats for exclusions					*/
/*	DEPOINT CHIN, RISCHALL APR2003
/********************************************************************************/	
%IF (%LENGTH(&WGT)=0) %THEN %GOTO NON_WGT_METHOD; 
%ELSE %GOTO WGT_METHOD;

%NON_WGT_METHOD:
PROC RANK DATA=&in_lib..&in_table GROUPS=&groups out=RANK_OUT;
	VAR &ranked_var;
	Where 9 < &ranked_var ; /*becuase exclusions are 001-009*/
    RANKS RANK1; 
proc means data=RANK_OUT maxdec=0 NOPRINT;
	class RANK1;
	var &ranked_var;
	output out=to_ctrl(drop=_freq_ rank1)
			MIN(&ranked_VAR) 	= START
			MAX(&ranked_VAR) 	= END
			;
run;
data to_ctrl;
	set to_ctrl;
	where _type_=1;
	drop	 _type_;
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
 where &ranked_var GE 10;
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
  proc format;
  	value LABELS
  	0	= 'EXCLUDE_ZERO_VALUE'
  	1	= 'EXCLUDE_DECEASED'
  	2	= 'EXCLUDE_NO_BUREAU-missing'
  	3	= 'EXCLUDE_NO_HIT-no_data'
  	4	= 'EXCLUDE_BNK_CO'
  	5	= 'NOT ASSIGNED-5'
  	6	= 'EXCLUDE_CLOSED'
  	7	= 'NOT ASSIGNED-7'
  	8	= 'NOT ASSIGNED-8'
  	9	= 'NOT ASSIGNED-9'
  	/*THESE ARE FICO SPECIFIC*/
/*  	9000	= 'EXCLUDE_TOO_MANY_TD' 
  	9001	= 'EXCLUDE_DECEASED'
  	9002	= 'EXCLUDE_NO_UPDATE_LST_6MO'
  	9003	= 'EXCLUDE_LACK_OF_HIST'
  	9996	= 'EXCLUDE_BLOCK_CONSUMER'
  	9997	= 'EXCLUDE_CRITERIA'
  	9998	= 'EXCLUDE_INSF_INFO'
  	9999	= 'EXCLUDE_NO_RECORD'
*/  	;
  QUIT;

  data exclusions;
  	FORMAT START END 4. LABEL $80.;
  	DO COUNT=1 TO 10;
  		NEW_COUNT= COUNT-1;
  		START	= new_COUNT;
  		END	= new_COUNT;
  		LABEL	= PUT(new_COUNT,LABELS.);
  		_TYPE_	= 1;
  		OUTPUT;
  	END;
  	DROP COUNT new_count;
  run;
  %global &format_label;
  %let &FORMAT_label = %SUBSTR(&ranked_var,1,7);

  data ctrl;
     set exclusions to_ctrl(keep = start end) end=last;
     retain fmtname "&&&FORMAT_label" type 'n';
     if last then hlo='h';
     else hlo =' ';
     format label $80.;
     /*if start >=10 then */label = compress(START||'-'||END);
   run;

proc format library=work cntlin=ctrl;
/*proc format library=work fmtlib;*/
proc print data=ctrl noobs;
title "format for &in_table based upon &ranked_var with &groups breaks &WGT";
run;
%MEND format_with_exclusions;

