%macro Export_to_txt (in_lib, in_table,location=%QUOTE(./));
proc export data = &in_lib..&in_table
	   OUTFILE   = "&location&in_table" 
	   DBMS	  	 =  TAB REPLACE;
run;
%mend Export_to_txt;