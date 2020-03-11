/**************************************************************************************************************/
/****THIS MACRO CREATES A MACRO VARIABLE &LIBRARYEXISTS WHICH WILL TELL YOU IF THE SPECIFIED LIBRARY EXISTS****/
/**************************************************************************************************************/

%macro lib_exists (lib=,status_name=libraryexists) ;
 %GLOBAL &status_name;
    %if %sysfunc(libref(&lib)) = 0 %then %do;
     %put "&lib exists" ;
	 %LET &status_name = Y;
    %end ;
    %else
      %put The libname &lib does not exist ;
 run ;
 %mend lib_exists;

