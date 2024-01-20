libname xptfile0 XPORT "~/Biostat203A/Homework/Homework4/XPT/TR.xpt";
libname ino "~/Biostat203A/Homework/Homework4/XPTread";
proc copy in=xptfile0 out=ino memtype=data;
run;

*1;
proc contents data=ino.IC order=varnum;
run;
proc print data=ino.IC (firstobs=1 obs=5);
run;

proc contents data=ino.RS order=varnum;
run;
proc print data=ino.RS (firstobs=1 obs=5);
run;

proc contents data=ino.TR order=varnum;
run;
proc print data=ino.TR (firstobs=1 obs=5);
run;

proc contents data=ino.TU order=varnum;
run;
proc print data=ino.TU (firstobs=1 obs=5);
run;

*2;
proc sort  data=ino.TR;
by  SUBJIDN TRDTC VISIT TRVALIDN;
run; 
proc sort  data=ino.RS ;
by  SUBJIDN RSDTC VISIT RSVALIDN;
run; 

proc print data=ino.RS(obs=10);
run;

data ino.TRRS;
merge ino.TR (rename = (TRDTC =date TRVALIDN=readerID))
ino.RS (rename = (RSDTC =date RSVALIDN=readerID));
by SUBJIDN date VISIT readerID;
run;

data TRRS2;
	set ino.TRRS;
	if TRSEQ~=. & RSSEQ~=. then  merge=3;
	if TRSEQ=. & RSSEQ~=. then  merge=2;
	if TRSEQ~=. & RSSEQ=. then  merge=1;
run;

proc freq data=TRRS2;
table merge*VISITNUM / nopercent norow nocum nocol;
run;

proc freq data=TRRS2;
where merge=1;
table VISITNUM / nopercent norow nocum nocol;
run;

proc freq data=TRRS2;
where merge=2;
table SUBJIDN RSSCAT / nopercent norow nocum nocol;
run;

*3;
Data TRRS3; 
	Set TRRS2; 
	by SUBJIDN VISITNUM; 
	if (first.SUBJIDN=1 or first.VISITNUM=1)  then output ;
run; 
proc freq data= TRRS3;
table merge*SUBJIDN /nopercent norow nocum nocol;
run;
proc freq data= TRRS3;
table merge*VISITNUM /nopercent norow nocum nocol;
run;
proc freq data= TRRS3;
where merge=1;
table merge*VISITNUM /nopercent norow nocum nocol;
run;

proc freq data= TRRS3;
where merge=2;
table merge*VISITNUM*RSORRES /nopercent norow nocum nocol;
run;

proc freq data= TRRS3;
where merge=3;
table merge*VISITNUM /nopercent norow nocum nocol;
run;

*4;
ods listing close;
ods rtf body="/home/u63620636/Biostat203A/Homework/Homework4/Baseline Target Disease Burden.rtf";
title1 "Baseline Target Disease Burden";
proc means mean std data=ino.TR ;
var TRSTRESN;
where TRTEST="Sum of Diameter" and TRACPTFL="Y" and VISIT="Screening";
run;
ods rtf close;
ods listing;

