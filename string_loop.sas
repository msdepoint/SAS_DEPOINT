%macro STRING_LOOP(var_list,ACTION_CODE);
/********************************************************/
/*	DEPOINT JULY 19, 2001					*/
/* modified by depoint apr2003*/
/*	This macro takes a list of variables passed in from	*/
/*	a macro, breaks apart the different variable names	*/
/*  to call action code, use the following syntax
ACTION_CODE=%NRSTR( blah blah blah )
*/
/*	the NRSTR is crucial to control for macro resolution */
/********************************************************/
%local i word_length;

%let i=0;
	%DO %UNTIL (&word_length=0);
		%let i = %eval(&i+1);
		%local word&i; 
		%let word&i = %scan(&var_list,&i,%str( ));
		%let word_length = %LENGTH(&&word&i);
		%IF &word_length ne 0 %THEN %DO;
			%UNQUOTE(&ACTION_CODE)
			%END;
	%END;
%mend STRING_loop;
