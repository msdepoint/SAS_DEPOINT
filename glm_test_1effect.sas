%macro glm_test_1effect(in_table,lhs,class,in_lib=work,wgt=,sig_level=.05,NOPRINT=NOPRINT);
/**************************************************************************************************/
/* GLM ANOVA                                                                                      */ 
/* 13JAN04 / MD:ac                                                                                */
/* THIS MACRO PERFORMS A GENERALIZED F-TEST (EQUAL AND UNEQUAL SAMPLE SIZES) ON LHS               */
/*   VARIABLE LIST.                                                                               */
/* MACRO WILL OUTPUT ALL VARIABLES AND CLASSES, BUT WILL ONLY PRINT OBSERVATIONS		  */
/*   WITH SIGNIFICANT F-STATISTICS.  IF NON-SIGNIFICANT F-STAT, THEN F-STAT VALUE IS              */
/*   MISSING.                                                                                     */
/**************************************************************************************************/

data _null_;
	sig = &sig_level * 100000;  /* BY DEFAULT, SIG_LEVEL IS 0.05 ---> SIG = 5000 */
	call symput('sig',sig);
run;

%let the_string = &in_table&sysindex;

proc glm data=&in_lib..&in_table outstat=out1 &NOPRINT;
	class &class;
	model &lhs = &class;

	%IF %EVAL(%LENGTH(&WGT)>0) %THEN %DO;
		weight &wgt;
		title "GLM Analysis for &in_lib..&in_table with LHS=&LHS and class=&class using WEIGHT=&wgt";
	%END;

	/*means &class_id;*/

	%ELSE %DO;
		title "GLM Analysis for &in_lib..&in_table with LHS=&LHS and class=&class";
	%END;
run;
quit;


/* 	REST OF MACRO IS FOR PRESENTATION PURPOSES */
data out_fix;
	informat data_source $24.;
	length 	data_source $ 24
			LHS $ 24
			;
	data_source = "%UPCASE(&in_table)";	
	set out1(rename=(_name_=LHS _source_=class));
	LHS = UPCASE(LHS);
	if class = 'ERROR' then delete;
	format	prob 8.4
			f 8.4
			ss 8.4
			class $24.
			;

	prob2	= prob;

	if prob2 = . then prob2 = 999;

	prob2 = round(prob2,.00001)*100000;  /*do this because the %IF evaluation is only integer based*/

	call symput('prob2',prob2);   /*save p-value for future evaulation in the macro*/
	
	drop df ss prob2 _type_;
run;


/****************************************************************************************/
/*	this section compares the p=value saved above to the user-defined sig. level.		*/
/*	if the threshold is passed, then print out the mean of the LHS by the class		*/
/*	regardless, create an output table with a relatively unique name to be combined		*/
/*	later with other ANOVA tests.														*/
/****************************************************************************************/

%IF (&prob2 < &sig) %THEN %DO; /* IF SIGNIFICANT THEN PERFORM MEANS BELOW */

/*	proc sort data = &in_lib..&in_table;*/
/*		by &class;*/

%if %eval(%length(&wgt)>0) %then %goto wgt;
%else %goto non_wgt;


%WGT:
	proc means data = &in_lib..&in_table NOPRINT;
		var &wgt;
		class &class;
		output out 			= mean_pop
			SUM(&WGT)		= EST_POPULATION
		;
	run;
	proc means data = &in_lib..&in_table NOPRINT;
		var &LHS;
		class &class;
		output out 		= mean_wgt
			N(&LHS)		= SAMP_SIZE
			NMISS(&LHS)	= SAMP_MISS
			mean(&LHS)	= MEAN;
		weight &wgt;
	run;
	proc sort data=mean_pop;
		by &class _type_;
	proc sort data=mean_wgt;
		by &class _type_;
	data mean_out;
		merge mean_pop mean_wgt;
		by &class _type_;
		format est_population comma15.0;
	run;
	%goto continue;


%NON_WGT:
	proc means data = &in_lib..&in_table NOPRINT;
		var &LHS;
		class &class;
		output out 		= mean_out
			N(&LHS)		= SAMP_SIZE
			NMISS(&LHS)	= SAMP_MISS
			mean(&LHS)	= MEAN;
	run;
	%goto continue;

%CONTINUE:
	data means_fix;
		set mean_out(drop=_type_ _freq_);

		format 	samp_size comma12.0
				samp_miss comma12.0
				mean comma8.4
				;

		informat 	data_source $24.
				 	LHS $24.
					;
		length 	data_source $ 24
				LHS $ 24
				;
		data_source = "%UPCASE(&in_table)";
		LHS = "%UPCASE(&LHS)";

		LABEL MEAN='MEAN';

	data &the_string;
		merge out_fix means_fix;
		by data_source LHS;
		run;
	%GOTO OUT;
	%END;
%ELSE %DO; /*ELSE, just report F stats*/
		data &the_string;
			set out_fix;
				data_source = UPCASE(data_source);
				LHS = UPCASE(LHS);
			run;
		%END;
%OUT:
%let set_list = &set_list &the_string; 
/****************************************************************************************/
/*	END OF THE 1 EFFECT ANOVA MACRO														*/
/****************************************************************************************/
%mend glm_test_1effect;
