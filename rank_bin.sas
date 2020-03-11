/******************************************************************************/
/*  PROGRAM  : rank_bin.sas                                                   */
/*  HISTORY  : baseline_vars.sas                                              */
/*  PROJECT  : Monthly Model Diagnosis                                        */
/*  FUNCTION : Generate and store baseline distribution of given variables.   */
/*  OUTPUT   : A dataset containing bin cutoff values, baseline bin counts    */
/*             and baseline bin percentage distribution of given variables.   */
/*                                                                            */
/*  Xiaofeng Liu                                                              */
/*  November 16, 2009                                                         */
/*                                                                            */
/*  MODIFICATIONS:                                                            */
/*  Date     By  Description                                                  */
/*  -------  --  ------------------------------------------------------------ */
/*  10NOV09  XL  change name to RANK_BIN to cover a general function of       */
/*               ranking and binning customers by given variable(s)           */
/******************************************************************************/

%macro rank_bin(obsmth=, inputset=, outlib=, outset=, var=, custid=con_cst_id, numbin=5);
	%if %length(&obsmth)=0 or %length(&inputset)=0 or %length(&outset)=0 or %length(&var)=0 %then %do;
		%put >>>>> Error: one or more mandatory parameters are not provided ;
		%goto getout;
	%end;

	%if %length(&outlib)=0 %then %let baselib=work;
	%else %do; 
		libname baseout "&outlib.";
		%let baselib=baseout;
	%end;
	%put outlib=&outlib., outset=&outset.,;

  %*---- Get number of eligible (being-scored) customers ----;
	proc sql noprint;
		select count(distinct &custid) into :tot_cust
		  from &inputset ;
	quit;
	%let tot_cust=&tot_cust;
	%put tot_cust=&tot_cust; 

  %*---- Get number of variables and array of the variable names ----*;
	proc contents data=&inputset (keep=&var) out=work.varnames(keep=name) noprint;
	data _null_;
		set work.varnames end=fend;
		call symput('anavar'!!compress(_n_),compress(name));
		if fend then call symput('nvars',compress(put(_n_,4.)));
	run;
	proc delete data=work.varnames;run;

  %*---- Initialize the output dataset ----*;
  	data &baselib..&outset;
		length bin 4;
		baseline="&obsmth.";
		do bin=1 to &numbin.;output;end;
	run;

	proc sort data=&baselib..&outset;
		by bin;
	run;	

  %*---- Process given variables one by one ----*;
	%do i=1 %to &nvars.; 
		title "Process Variable &&anavar&i"; 
		proc sort data=&inputset (keep=&&anavar&i) out=work.anavar&i;
			by &&anavar&i ;
		run;

  	  %*---- Get type of the ith analytical variable ----;
		proc sql noprint;
			select substr(upcase(type),1,1) into :vartype
	  		  from dictionary.columns
	 		 where libname='WORK'     and
	       	       memname="ANAVAR&i" and
		   	       memtype='DATA'     and 
			       name="&&anavar&i." ;
		quit;
		%let vartype=&vartype;
		%put i=&i., anavar=&&anavar&i., vartype=&vartype.,;

  	  %*---- Count levels (distinct values) of the variable ----;
		proc sql noprint;
			select count(distinct &&anavar&i) into :num_val
	      	  from work.anavar&i
		 	 where %if &vartype=C %then %do; &&anavar&i ne ' ' %end;
			       %else %do; &&anavar&i ne . %end;;
			select count(*) into :missings
	      	  from work.anavar&i 	
		 	 where %if &vartype=C %then %do; &&anavar&i =' ' %end;
			       %else %do; &&anavar&i =. %end;;
		quit;
		%let num_val=&num_val;
		%let missings=&missings;

		%if &missings > 0 %then %let levels=%eval(1+&num_val);
		%else %let levels=&num_val;
		%put num_val=&num_val., missings=&missings., levels=&levels.,;

  	  %*---- Rank and bin customers by the variable ----;
		%if &levels <= &numbin %then %do;
			proc sql;
				create table work.&&anavar&i as
				select &&anavar&i         as bin_cap,
				       count(*)           as bin_cnt,
					   count(*)/&tot_cust as bin_pct
				  from work.anavar&i
				 group by &&anavar&i
				 order by &&anavar&i;
			quit;

			data work.&&anavar&i;
				length bin 4;
				set work.&&anavar&i;
				bin=_n_;

			proc sort data=work.&&anavar&i;
				by bin;
			run;

			proc print data=work.&&anavar&i;
				var bin bin_cap bin_cnt bin_pct;
				sum bin_cnt bin_pct;
			run;
		%end;

		%else %do;
			%if &levels > &num_val %then %let bin_cnt=%eval(&numbin.-1);
			%else %let bin_cnt=&numbin;

			%if &vartype=C %then %do;
				proc sort data=work.anavar&i out=work.uniqval nodupkey;
					by &&anavar&i;
				run;

				data _null_;
					set work.uniqval;
					by &&anavar&i;
					call symput('varval'!!compress(_n_),&&anavar&i);
				run;
				proc delete data=work.uniqval;run; 

				data work.anavar&i;
					set work.anavar&i;
					by &&anavar&i;
					%do j=1 %to &levels ;
						if &&anavar&i = "&&varval&j." then varlvl = &j;
						if &&anavar&i = ' ' then varlvl =.;
					%end;
				run;

				proc rank data=work.anavar&i out=work.anavar&i._rank group=&bin_cnt;
					var varlvl;
					ranks varrank;
				run; 

				proc sql;
					create table work.&&anavar&i as
					select varrank ,
			    		   max(&&anavar&i)	  as bin_cap,
			    		   count(*)           as bin_cnt,
						   count(*)/&tot_cust as bin_pct
			 	 	  from work.anavar&i._rank
					 group by varrank
					 order by varrank;
				quit;
			%end;

			%else %do;
			  %*---- Get rounding parameters ----*; 
			  	%let range=; %let rnd=;
				proc means data=work.anavar&i noprint;
					var &&anavar&i;
					output out=work.val_mean p5=p5 p95=p95 p25=p25 p50=p50;
				run;

				data _null_;
					set work.val_mean;
					range=sum(0,p95,-p5);
					if range >= 100000 then do;
						if p25 >= 10000 then rnd=1000;
						else if p25 >= 1000 then rnd=100;
						else if p25 >= 100 then rnd=10;
						else rnd=1;
					end; 
					else if range >= 10000 then do;
						if p25 >= 1000 then rnd=100;
						else if p25 >= 100 then rnd=10;
						else rnd=1;
					end; 
					else if range >= 1000 then do;
						if p25 >= 100 then rnd=10;
						else rnd=1;
					end; 
					call symput('p50',compress(p50));
					call symput('range',compress(put(range,9.)));
					if range >= 1000 then call symput('rnd',compress(put(rnd,4.)));
				run;
				proc delete data=work.val_mean;run;
				%put range=&range.,  rnd=&rnd., p50=&p50.,;

				%if &range < 1000 %then %do;
			  	  %*---- Rank and bin customers without rounding ----*; 
					proc rank data=work.anavar&i out=work.anavar&i._rank groups=&bin_cnt;
						var &&anavar&i;
						ranks varrank;
					run;

					proc sql;
						create table work.&&anavar&i as
						select varrank ,
			    		   	   max(&&anavar&i)	  as bin_cap,
			    			   count(*)           as bin_cnt,
							   count(*)/&tot_cust as bin_pct
			 	 	 	  from work.anavar&i._rank
					 	 group by varrank
						 order by varrank;
					quit;
				%end;

				%else %do;
			  	  %*---- Rank and bin customers with rounding ----*; 
					data work.rounded;
						set work.anavar&i;
						if &&anavar&i ne . then rounded = round(&&anavar&i,&rnd..);
						else rounded = &&anavar&i ;
					run;

					proc rank data=work.rounded out=work.anavar&i._rank groups=&bin_cnt;
						var rounded;
						ranks varrank;
					run;

					proc sql;
						create table work.&&anavar&i as
						select varrank ,
			    		   	   max(rounded)	  	  as bin_cap,
			    		   	   max(&&anavar&i)	  as bin_cap_orig,
			    			   count(*)           as bin_cnt,
							   count(*)/&tot_cust as bin_pct
			 	 	 	  from work.anavar&i._rank
					 	 group by varrank
						 order by varrank;
					quit;
					proc delete data=work.rounded; run;
				%end;
			%end;

		  %*---- Assign bin ID ----;
			data work.&&anavar&i;
				length bin 4;
				set work.&&anavar&i;
				by varrank;
				bin=_n_;
			run;

			proc sort data=work.&&anavar&i;
				by bin;
			run;

			proc print data=work.&&anavar&i;
				%if &vartype=N %then %do; format bin_cap 18.8; %end;
				var bin bin_cap bin_cnt bin_pct %if &range >= 1000 %then %do; bin_cap_orig %end;;
				sum bin_cnt bin_pct;
			run;
			proc delete data=work.anavar&i._rank;run;
		%end;

		data &baselib..&outset;
			merge &baselib..&outset
		      	  work.&&anavar&i (keep=bin bin_cap bin_cnt bin_pct 
			                       rename=(bin_cap=&&anavar&i.._bincap 
								           bin_cnt=&&anavar&i.._bincnt 
			                               bin_pct=&&anavar&i.._binpct));
			by bin;
		run;
		proc delete data=work.anavar&i work.&&anavar&i;run;
	%end;
	title; 
	proc print data=&baselib..&outset;run;

	%getout:
%mend rank_bin;

