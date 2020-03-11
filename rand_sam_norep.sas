%macro rand_sam_norep(in_lib,in_table,out_lib,out_table,sampsize,seed);
/************************************************************************/
/* A.Chin 23SEP2002                                                     */
/* Modified DePoint April 2004 */
/* This MACRO allows for random sampling without replacement            */
/* must specify sample size less than size population                   */
/************************************************************************/
data &out_lib..&out_table(drop=obsleft sampsize);
	sampsize = &sampsize;
	obsleft = totobs;
		do while(sampsize > 0 and sampsize not >= totobs);
			pickit + 1;
			if ranuni(&seed) < sampsize/obsleft then do;
				set &in_lib..&in_table point=pickit nobs=totobs;
					output;
				sampsize = sampsize - 1;
			end;
		obsleft = obsleft - 1;
	end;
	stop;
run;
%mend rand_sam_norep;
