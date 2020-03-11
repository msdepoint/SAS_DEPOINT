%MACRO CHECK_dups(in_lib=,in_table=);
PROC FREQ DATA=&in_lib..&in_table;
	TABLES institution_id*institution_name /noprint out=CHECKIT(KEEP=institution_id institution_name);
RUN;
PROC SORT DATA=checkit; BY institution_id institution_name;RUN;

DATA dups; SET checkit; BY institution_id institution_name;
IF first.institution_id THEN count=0;
count+1;
IF count>1 THEN OUTPUT;
RUN;

PROC SQL;CREATE TABLE names AS
SELECT UNIQUE m.institution_id, m.institution_name
from &in_lib..&in_table m,
	(SELECT institution_id FROM dups) d
WHERE 	m.institution_id = d.institution_id
ORDER BY m.institution_id, m.institution_name
;
CREATE TABLE ids AS 
SELECT UNIQUE m.institution_id, m.institution_name
from &in_lib..&in_table m,
	(SELECT institution_name FROM dups) d
WHERE 	m.institution_name = d.institution_name
ORDER BY m.institution_id, m.institution_name
;

DATA all123we;
	SET names
		ids
		;
RUN;
PROC SORT DATA=all123we OUT=all_ids(KEEP=institution_id) NODUPKEY; BY institution_id;RUN;
PROC SORT DATA=all123we OUT=all_names(KEEP=institution_name) NODUPKEY; BY institution_name;RUN;

PROC PRINT DATA=all_names;
	FORMAT institution_name $24.;
RUN;
PROC PRINT DATA=all_ids;
	FORMAT institution_id $12.;
RUN;
%MEND check_dups;