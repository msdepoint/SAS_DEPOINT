/******************************************************************************************/
/******************************************************************************************/
/* 																						  */
/*       Macro Name:  TABULATE_WIZARD 													  */
/*           Author:  Nripendra Rai														  */
/*          Created:  July 12, 2006														  */
/*     Main Purpose:  TABULATE_WIZARD is a user friendly macro that lets user to produce  */
/*                    tabulate as desired by simply filling up the parameters. 			  */
/*       Parameters:																	  */
/* 																						  */
/*            in_lib    : name of the input library (assigned as work by default).		  */
/*           out_lib    : name of the output library (assigned as work by default).		  */
/*          in_table    : name of the input table or dataset.							  */
/*         out_table    : name of the output table, user can enter the output table name  */
/*                        otherwise it is named "ww" by default.						  */
/*    class_list_row    : A list of classification variables that goes on the row section */
/*                        of the produced tabulate.										  */
/*    class_list_col    : A list of classification variables that goes on the column 	  */
/*                        section of the produced tabulate.								  */
/*        n_var_list    : A list of analysis variables that is used to compute N.		  */
/*     mean_var_list    : A list of analysis variables that is used to compute MEAN.	  */
/*      min_var_list    : A list of analysis variables that is used to compute MINIMUM.   */
/*      max_var_list    : A list of analysis variables that is used to compute MAXIMUM.	  */
/*      sum_var_list    : A list of analysis variables that is used to compute SUM.		  */
/*      std_var_list    : A list of analysis variables that is used to compute 			  */
/*                        STANDARD DEVIATION.											  */
/*      row_pct_list    : A list of analysis variables that is used to compute ROW 		  */
/*                        PERCENT SUM.													  */
/*      col_pct_list    : A list of analysis variables that is used to compute COLUMN 	  */
/*                        PERCENT SUM.													  */
/*      pct_sum_list    : A list of analysis variables that is used to compute       	  */
/*                        PERCENT SUM.													  */
/*   median_var_list    : A list of analysis variables that is used to compute MEDIAN.    */
/*         in_weight    : An analysis variable to be weighted.							  */
/*       where_extra    : User can type in where-clause he/she wants, the where-clause 	  */
/*                        must be wrapped inside %NRSTR( ).								  */
/*            in_rts    : A number of vertical spaces used for the row titles, for 		  */
/*                        example 10, 20, 30 etc.										  */
/*           mylabel    : A specified text that goes into the big empty box in the 		  */
/*                        upper left of the table.										  */
/*         var_label    : A specified text that will be the heading of the table 		  */
/*                        i.e the first row in the upper right of the table.			  */
/*      display_stat    : An option for users if he/she wants keywords like N, 			  */
/*                        MEAN, SUM, MIN, MAX, etc. labeled on the top of the table 	  */
/*                        under heading, the user can type "yes" or any character or 	  */
/*                        text to turn it on. Otherwise, the above mentioned statistics   */
/*                        keywords would not be displayed. 								  */
/*   all_toggle_row     : A list of "ALL" toggles separated by delimeter '#' for row, the */
/*                        list has to be in order accordingly to the variables entered,   */
/*                        for example:  						                          */
/*                               for variables: Score Score_chall 			              */
/*                        Here, Score and Score_chall are row class variables       	  */			  
/*                        All_toggle_row = #  # ALL #  ( i.e. space ALL)                  */
/*                        If the user leaves this parameter blank then default will be 	  */
/*                        ALL on every variable. 										  */
/*   all_toggle_col     : Same as all_toggle_row (except that it is for column variables) */
/*       all_wrapper    : An option that gives a choice to user whether he/she wants to   */
/*                        wrap row or column classification variables with "ALL" or not,  */
/*                        user can simply type ALL to wrap and leave blank to do nothing. */ 
/* 																						  */
/*      Sample Code:  The following invocation of TABULATE_WIZARD will produce a tabulate */
/*                    containing two row and two column classification variables along 	  */
/*                    with SUM of an analysis variable: 								  */
/*                    %TABULTE_WIZARD (in_lib = work, out_lib = work, in_table= myFake,   */
/*                                     out_table= nipen, class_list_row= Score_chall 	  */
/*                                     response , class_list_col= ind1 Score,N_VAR_LIST=, */
/*                                     MEAN_VAR_LIST=, min_var_list=,max_var_list=,		  */
/*                                     sum_var_list= Dollar,std_var_list=, row_pct_list=, */
/*                                     col_pct_list=, pct_sum_list=, median_var_list=,    */
/*                                     in_weight=, 		                                  */
/*                                     where_extra=,in_rts= 20, mylabel= " Two Row 		  */
/*                                     Variables and Two Column Variables ", var_label=   */
/*                                     " Only On the TOP",display_stat=, all_toggle_row=  */
/*                                     # #ALL#, all_toggle_col= # #ALL# , 	              */
/*                                     all_wrapper= ALL );								  */
/* 																						  */
/*  Acknowledgement:  Matthew Somerset DePoint 											  */
/* 																						  */
/*             Note:  In case of class_list_row_class_list_col, n_var_list, 			  */
/*                    mean_var_list, min_var_list, and so on, user can simply type the 	  */
/*                    list of variables (default delimeter = space), no restrictions 	  */
/*                    such as %quote, %str, etc. Also, taking a look at ROW_COL_SEPARATOR */
/*                    macro is recommended. 											  */
/*                    Please be advised that there must be %LET <class-variable> 	      */
/*                    referring to some format otherwise format code wont work.           */
/*                    In case of numeric format then user has to put $ sign infront of    */
/*                    the format name.                                                    */
/*                    If any further suggestions, comments, advice or notice any glitches */
/*                    then please inform.			                         			  */                   
/* 																						  */
/******************************************************************************************/ 
/******************************************************************************************/

%macro tabulate_wizard(in_lib = work, out_lib = work, in_table=, out_table=, class_list_row=, class_list_col=,N_VAR_LIST=, MEAN_VAR_LIST=,
			min_var_list=,max_var_list=,sum_var_list=,std_var_list=, row_pct_list=, col_pct_list=,pct_sum_list=,MEDIAN_VAR_LIST=, in_weight=, where_extra=, in_rts=, 
            mylabel=, var_label=, display_stat=, all_toggle_row=,all_toggle_col=, all_wrapper=,var_format=);

		/************************************************/
		/* Creating a user defined format for percentage*/
		/************************************************/
        proc format; 
        picture pctpic low-high='009.99 %';
        quit;
        title;

		/**********************************************************************************/
		/* Display the keywords N or Mean or Min or Max etc. if display_stat has any value*/
		/**********************************************************************************/
        %IF %EVAL(%LENGTH(&display_stat)>0) %THEN %DO;

			 /***************************/
             /* Displaying N statistics */
		     /***************************/
             %let N_VAR_CODE=;
             %string_loop(	var_list=&N_var_LIST,
				action_code = %NRSTR(%LET N_VAR_CODE = &N_VAR_CODE (&&word&i*N*f=comma14.);
									)
			                 )
             ;

			 /*******************/
			 /* Displaying MEAN */
			 /*******************/
             %let MEAN_VAR_CODE=;
             %string_loop(	var_list=&MEAN_var_LIST,
				action_code = %NRSTR(%LET MEAN_VAR_CODE = &MEAN_VAR_CODE (&&word&i*mean*f= &var_format);
									)
			                  )
             ;

			 /******************/
			 /* Displaying MIN */
			 /******************/
             %let MIN_VAR_CODE=;
             %string_loop(	var_list=&MIN_var_LIST,
				action_code = %NRSTR(%LET MIN_VAR_CODE = &MIN_VAR_CODE (&&word&i*min*f= &var_format);
									)
			                 )
             ;

			 /******************/
             /* Displaying MAX */
			 /******************/
             %let MAX_VAR_CODE=;
             %string_loop(	var_list=&MAX_var_LIST,
				action_code = %NRSTR(%LET MAX_VAR_CODE = &MAX_VAR_CODE (&&word&i*max*f=&var_format);
									)
			                )
              ;

			  /******************/
			  /* Displaying SUM */
			  /******************/
              %let SUM_VAR_CODE=;
              %string_loop(	var_list=&SUM_var_LIST,
				action_code = %NRSTR(%LET SUM_VAR_CODE = &SUM_VAR_CODE (&&word&i*SUM*f=&var_format);
									)
			                )
               ;

			   /*********************************/
			   /* Displaying Standard Deviation */
			   /*********************************/
               %let STD_VAR_CODE=;
               %string_loop(	var_list=&STD_var_LIST,
				action_code = %NRSTR(%LET STD_VAR_CODE = &STD_VAR_CODE (&&word&i*STD*f=comma14.);
									)
			                 )
               ;

			   /******************************/
			   /* Displaying Row Percent Sum */
			   /******************************/
               %let ROW_PCT_CODE=;
               %string_loop(	var_list=&row_pct_LIST,
				action_code = %NRSTR(%LET row_pct_CODE = &row_pct_CODE (&&word&i*rowpctsum*f=pctpic9.);
									)
		                 	)
                ;

				/*********************************/
				/* Displaying Column Percent Sum */
				/*********************************/
                %let COL_PCT_CODE=;
                %string_loop(	var_list=&col_pct_LIST,
				   action_code = %NRSTR(%LET col_pct_CODE = &col_pct_CODE (&&word&i*colpctsum*f=pctpic9.);
									)
			                )
                ;
				/*********************************/
				/* Displaying Percent Sum        */
				/*********************************/
                %let PCT_SUM_CODE=;
                %string_loop(	var_list=&pct_sum_LIST,
				   action_code = %NRSTR(%LET pct_sum_CODE = &pct_sum_CODE (&&word&i*pctsum*f=pctpic9.);
									)
			                )
                ;
				/*********************************/
				/* Displaying MEDIAN             */
				/*********************************/
                %let MEDIAN_VAR_CODE=;
                %string_loop(	var_list=&MEDIAN_VAR_LIST,
				   action_code = %NRSTR(%LET MEDIAN_VAR_CODE = &MEDIAN_VAR_CODE (&&word&i*median*f=&var_format);
									)
			                )
                ;
            %END;

			/*********************************************/
			/* Else Display without any keywords heading */
			/*********************************************/
            %else
            %do;
				 /***************************/
			     /* Displaying N statistics */
			     /***************************/
                 %let N_VAR_CODE=;
                 %string_loop(	var_list=&N_var_LIST,
				 action_code = %NRSTR(%LET N_VAR_CODE = &N_VAR_CODE (&&word&i*N=' '*f=comma14.);
									)
			                 )
                 ;
				 %PUT &N_VAR_CODE;

				 /*******************/
				 /* Displaying MEAN */
				 /*******************/
                 %let MEAN_VAR_CODE=;
                 %string_loop(	var_list=&MEAN_var_LIST,
				  action_code = %NRSTR(%LET MEAN_VAR_CODE = &MEAN_VAR_CODE (&&word&i*mean= ' '*f= &var_format);
									)
			              )
                  ;

				  /******************/
				  /* Displaying MIN */
				  /******************/
                  %let MIN_VAR_CODE=;
                  %string_loop(	var_list=&MIN_var_LIST,
				   action_code = %NRSTR(%LET MIN_VAR_CODE = &MIN_VAR_CODE (&&word&i*min= ' '*f= &var_format);
									)
			               )
                   ;

				   /******************/
				   /* Displaying MAX */
				   /******************/
                   %let MAX_VAR_CODE=;
                   %string_loop(	var_list=&MAX_var_LIST,
				    action_code = %NRSTR(%LET MAX_VAR_CODE = &MAX_VAR_CODE (&&word&i*max= ' '*f= &var_format);
									)
			                )
                    ;

					/******************/
					/* Displaying SUM */
					/******************/
                    %let SUM_VAR_CODE=;
                    %string_loop(	var_list=&SUM_var_LIST,
				     action_code = %NRSTR(%LET SUM_VAR_CODE = &SUM_VAR_CODE (&&word&i*SUM= ' '*f=&var_format);
									)
			               )
                    ;

					/*********************************/
					/* Displaying Standard Variation */
					/*********************************/
                    %let STD_VAR_CODE=;
                    %string_loop(	var_list=&STD_var_LIST,
				     action_code = %NRSTR(%LET STD_VAR_CODE = &STD_VAR_CODE (&&word&i*STD= ' '*f=comma14.);
									)
			                )
                    ;

					/******************************/
					/* Displaying Row Percent SUM */
					/******************************/
                    %let ROW_PCT_CODE=;
                    %string_loop(	var_list=&row_pct_LIST,
				     action_code = %NRSTR(%LET row_pct_CODE = &row_pct_CODE (&&word&i*rowpctsum= ' '*f=pctpic9.);
									)
			                )
                    ;

					/*********************************/
					/* Displaying Column Percent SUM */
					/*********************************/
                    %let COL_PCT_CODE=;
                    %string_loop(	var_list=&col_pct_LIST,
				     action_code = %NRSTR(%LET col_pct_CODE = &col_pct_CODE (&&word&i*colpctsum= ' '*f=pctpic9.);
									)
			                  )
                    ;
					/*********************************/
				    /* Displaying Percent Sum        */
				    /*********************************/
                    %let PCT_SUM_CODE=;
                    %string_loop(	var_list=&pct_sum_LIST,
				    action_code = %NRSTR(%LET pct_sum_CODE = &pct_sum_CODE (&&word&i*pctsum= ' '*f=pctpic9.);
									)
			                )
                    ;
					/*********************************/
				    /* Displaying MEDIAN             */
				    /*********************************/
                    %let MEDIAN_VAR_CODE=;
                    %string_loop(	var_list=&MEDIAN_VAR_LIST,
				     action_code = %NRSTR(%LET MEDIAN_VAR_CODE = &MEDIAN_VAR_CODE (&&word&i*median=' '*f=&var_format);
									)
			                 )
                     ;
              %end;

		 /************************************/
		 /* Creating a name for an out table */
		 /************************************/
		 %if %EVAL(%LENGTH(&out_table)>0) %THEN %DO;
		 %Let out_option = &out_table;
		 %END;
		 %Else
		 %do;
		   %let out_option= ww ; 
		 %END;
		
		/***************************************************************************************/
        /*************    This macro separates the class variables    *************************/ 
        /**************   which are used in either row or column      ************************/
        /***************  of the Proc Tabulate                        ***********************/
        /***********************************************************************************/

        %macro row_col_separator(in_lib = work, out_lib = work, in_table=, in_class_list=, in_label=, in_toggle_list =, in_all_wrapper=);
    
		/***********************************************************************************/
        /*  Creating the class code which will be used in tables section of proc tabulate  */
		/***********************************************************************************/
	    %GLOBAL CLASS_CODE;
        %let CLASS_CODE=;
        %MACRO do_class(class,index, all_string = );

		/********************************************/
	    /* Put all only if the user provides a list */
		/********************************************/
	    %IF %EVAL(%LENGTH(&all_string)>0) %THEN 
        %DO;
	        %let is_all&index = %scan(&all_string, &index, %str(#)); 
            %IF &INDEX=1 %THEN 
            %DO;	
                %LET CLASS_CODE = (&class= &in_label &&is_all&index); 
            %END;
            %ELSE	
            %DO; 	
               %LET CLASS_CODE = &CLASS_CODE * (&class =' ' &&is_all&index);
            %END;
	    %END;

		/***************************/
		/* Else put all by default */
		/***************************/
	    %ELSE
	    %DO;
		    %IF &INDEX=1 %THEN 
            %DO;	
               %LET CLASS_CODE = (&class= &in_label ALL); 
            %END;
            %ELSE	
            %DO; 	
               %LET CLASS_CODE = &CLASS_CODE * (&class =' ' ALL);
            %END;

	    %END;
        %MEND do_class;

		/******************************************************************/
	    /* Getting the required class code from the list provided by user */ 
		/******************************************************************/
        %string_loop(	var_list= &in_class_list ,									
				action_code = %NRSTR(%DO_class(class=&&word&i,index=&i, all_string = &in_toggle_list)
									)
			            )
        ;

		/**********************************/
	    /* Formatting the class variables */
		/**********************************/
	    %GLOBAL FORMAT_CODE;
        %let FORMAT_CODE =;
        %string_loop(	var_list=&in_class_list,	
				action_code = %NRSTR(%LET FORMAT_CODE = &FORMAT_CODE &&word&i &&&&&&word&i....;
									)
			             )
         ;
	

         %mend row_col_separator;
         /************************************/
         /******Ends row_col_separator*******/
         /**********************************/


		/******************************************************************/
		/* Invoking row_col_separator macro to get the class_code for row */
		/******************************************************************/
        %row_col_separator(in_lib = &in_lib, out_lib = work, in_table= &in_table, in_class_list= &class_list_row, in_label = %quote (' '), in_toggle_list= &all_toggle_row, in_all_wrapper = &all_wrapper);
        %Let class_code_row = &class_code;
		%Let format_code_row = &format_code;

		/************************************************************************************************************/
		/* If class_list for column has any variable then produce Tabulate with both row and column class variables */
		/************************************************************************************************************/
        %IF %EVAL(%LENGTH(&class_list_col)>0) %THEN %DO;

		     /*********************************************************************/
		     /* Invoking row_col_separator macro to get the class_code for column */
		     /*********************************************************************/
             %row_col_separator(in_lib = &in_lib, out_lib = work, in_table= &in_table, in_class_list= &class_list_col, in_label = &var_label, in_toggle_list= &all_toggle_col, in_all_wrapper = &all_wrapper);
             %Let class_code_col = &class_code;
			 %Let format_code_col = &format_code;

             /****************************************/
             /********* THE MAIN TABULATE ***********/
             /**************************************/
             proc tabulate data = &in_lib..&in_table missing out = &out_option;
             class &class_list_row &class_list_col;
             var &N_VAR_LIST &MEAN_var_LIST &MIN_VAR_LIST &MAX_VAR_LIST &SUM_VAR_LIST &STD_VAR_LIST &row_pct_list &col_pct_list &pct_sum_list &median_var_list;
             %IF %EVAL(%LENGTH(&in_weight)>0) %THEN %DO; weight &in_weight; %END;
             FORMAT  &format_code_row  &format_code_col ;
             tables (&class_code_row) &all_wrapper, ((&class_code_col) &all_wrapper) * (&N_VAR_CODE &SUM_VAR_CODE &MIN_VAR_CODE &MAX_VAR_CODE &MEAN_VAR_CODE
		            &STD_VAR_CODE &row_pct_code &col_pct_code &pct_sum_code &median_var_code)
                    /rts=&in_rts BOX=&mylabel MISSTEXT= ' ';

             %IF %LENGTH(%UNQUOTE(&where_extra)) > 0 %THEN %DO;
		         WHERE %UNQUOTE(&where_extra);
		     %END;
             title ;
             ;
             run;
        %END;

		/*******************************************************/
		/* Else produce Tabulate with only row class variables */
		/*******************************************************/
        %else 
        %do;
           /****************************************/
           /********* THE MAIN TABULATE ***********/
           /**************************************/
           proc tabulate data = &in_lib..&in_table missing out = &out_option;
           class &class_list_row ;
           var &N_VAR_LIST &MEAN_var_LIST &MIN_VAR_LIST &MAX_VAR_LIST &SUM_VAR_LIST &STD_VAR_LIST &row_pct_list &col_pct_list &pct_sum_list &median_var_list;
           %IF %EVAL(%LENGTH(&in_weight)>0) %THEN %DO; weight &in_weight; %END;
           FORMAT  &format_code_row;
           tables (&class_code_row) &all_wrapper , &N_VAR_CODE &SUM_VAR_CODE &MIN_VAR_CODE &MAX_VAR_CODE &MEAN_VAR_CODE
		          &STD_VAR_CODE &row_pct_code &col_pct_code	&pct_sum_code &median_var_code
                  /rts=&in_rts BOX=&mylabel MISSTEXT= ' ';

           %IF %LENGTH(%UNQUOTE(&where_extra)) > 0 %THEN %DO;
		       WHERE %UNQUOTE(&where_extra);
		   %END;
           title;
           ;
           run;
           %END;

%MEND tabulate_wizard;

/*****************************************************************/
/*****************************************************************/
/**********   This is the end of tabulate_wizard   ***************/
/*****************************************************************/
/*****************************************************************/
