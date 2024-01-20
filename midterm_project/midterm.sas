/* import the oral health data set from the website */
filename oral "/home/u63620464/BIOSTAS203A/MidtermProject/OHXREF_I.XPT";

proc http url="https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/OHXREF_I.XPT" 
		out=oral;
run;

libname oral xport "/home/u63620464/BIOSTAS203A/MidtermProject/OHXREF_I.XPT";

/* import the dietary data sets from the website */
filename diet1 "/home/u63620464/BIOSTAS203A/MidtermProject/DR1TOT_I.XPT";

proc http url="https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DR1TOT_I.XPT" 
		out=diet1;
run;

libname diet1 xport "/home/u63620464/BIOSTAS203A/MidtermProject/DR1TOT_I.XPT";
filename diet2 "/home/u63620464/BIOSTAS203A/MidtermProject/DR2TOT_I.XPT";

proc http url="https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DR2TOT_I.XPT" 
		out=diet2;
run;

libname diet2 xport "/home/u63620464/BIOSTAS203A/MidtermProject/DR2TOT_I.XPT";

/*import the demographic data set from the website */
filename demo "/home/u63620464/BIOSTAS203A/MidtermProject/DEMO_I.XPT";

proc http url="https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/DEMO_I.XPT" out=demo;
run;

libname demo xport "/home/u63620464/BIOSTAS203A/MidtermProject/DEMO_I.XPT";

/*import the vitaminD data set from the website */
filename vd "/home/u63620464/BIOSTAS203A/MidtermProject/VID_I.XPT";

proc http url="https://wwwn.cdc.gov/Nchs/Nhanes/2015-2016/VID_I.XPT" out=vd;
run;

libname vd xport "/home/u63620464/BIOSTAS203A/MidtermProject/VID_I.XPT";

/* clean the oral health data set accoring to the meaning provided on the website*/
libname project "/home/u63620464/BIOSTAS203A/MidtermProject";

proc format;
	value oralformat 1="See a dentist immediately" 
		2="See a dentist within the next 2 weeks" 
		3="See a dentist at your earliest convenience" 
		4="Continue your regular routine care";
run;

data project.cleanedoral;
	set oral.OHXREF_I;
	keep seqn OHAREC;
	where OHAREC is not missing;
	format OHAREC oralformat.;
	label seqn="ID" OHAREC="Oral health condition";
run;

proc sort data=project.cleanedoral;
	by seqn;
run;

/* clean the diet data sets */
data project.cleandiet1;
	set diet1.DR1TOT_I;
	keep seqn DR1TSUGR;
	label seqn="ID" DR1TSUGR="Sugar intake on day 1";
run;

proc sort data=project.cleandiet1;
	by seqn;
run;

data project.cleandiet2;
	set diet2.DR2TOT_I;
	keep seqn DR2TSUGR;
	label seqn="ID" DR2TSUGR="Sugar intake on day 2";
run;

proc sort data=project.cleandiet2;
	by seqn;
run;

/*clean the demo data sets*/
data project.cleandemo;
	set demo.DEMO_I;
	keep seqn RIDAGEYR RIAGENDR RIDRETH3;
	label seqn="ID" RIDAGEYR="Age in years" RIAGENDR="Gender" RIDRETH3="Race";
run;

proc sort data=project.cleandemo;
	by seqn;
run;

/*clean the vitamin d data sets*/
data project.cleandvd;
	set vd.VID_I;
	keep seqn LBXVD2MS LBXVD3MS LBXVE3MS;
	label seqn="ID" LBXVD2MS="25-hydroxyvitamin D2" 
		LBXVD3MS="25-hydroxyvitamin D3" LBXVE3MS="epi-25-hydroxyvitamin D3";
run;

proc sort data=project.cleandvd;
	by seqn;
run;

/* merge 5 data sets into 1 and calculaate new columns*/
data project.mergeddata;
	merge project.cleanedoral project.cleandiet1 project.cleandiet2 
		project.cleandemo project.cleandvd;
	by seqn;
run;

proc format;
	value ohealthformat 0="Continueroutine care" 1="Need medical attetion";
run;

proc format;
	value ageformat 0-1="Infants" 1-12="Children" 13-17="Adolescent" 18-64="Adult" 
		65-high="Older Adult";
run;

proc format;
	value raceformat 1="Mexican American" 2="Other Hispanic" 
		3="Non-Hispanic White" 4="Non-Hispanic Black" 6="Non-Hispanic Asian" 
		7="Other Race - Including Multi-Racial";
run;

proc format;
	value genderformat 1="Male" 2="Female";
run;

data project.mergeddata;
	set project.mergeddata;
	AVGSUGAR=mean(DR1TSUGR, DR2TSUGR);
	length ORALHEALTH 3;

	if OHAREC=1 or OHAREC=2 or OHAREC=3 then
		ORALHEALTH=1;
	else if OHAREC=4 then
		ORALHEALTH=0;
	format ORALHEALTH ohealthformat. RIDAGEYR ageformat. RIDRETH3 
		raceformat. RIAGENDR genderformat.;
	label seqn="ID" AVGSUGAR="Sugar intake average on both days" 
		OHAREC="Oral health condition" 
		ORALHEALTH="Generalized oral health condition ";
run;

/*clean missing values, and add formats */
data project.cleanedData;
	set project.mergeddata(drop=DR1TSUGR DR2TSUGR OHAREC);
	where RIDAGEYR >=18 and RIDAGEYR <=64 and LBXVD2MS is not missing and LBXVD3MS 
		is not missing and LBXVE3MS is not missing and ORALHEALTH is not missing and 
		AVGSUGAR is not missing;
	format ORALHEALTH ohealthformat. RIDAGEYR ageformat. RIDRETH3 
		raceformat. RIAGENDR genderformat.;
run; 

proc print data=project.cleanedData(obs=10) label;
run;

proc contents data=project.cleanedData;
run;

/* Table 1: Descriptive statistics & data exploration */
proc sort data=project.cleanedData;
	by RIDRETH3;
run;

proc freq data = project.cleanedData;
  tables RIDRETH3*ORALHEALTH /norow nocol;
  by RIDRETH3;
run;

Proc sgplot data= project.cleanedData;
 histogram AVGSUGAR;
run;

Proc sgplot data= project.cleanedData;
 histogram LBXVD2MS;
 where ORALHEALTH=1;
run;
Proc sgplot data= project.cleanedData;
 histogram LBXVD2MS;
 where ORALHEALTH=0;
run;
Proc sgplot data= project.cleanedData;
 histogram LBXVD3MS;
run;
Proc sgplot data= project.cleanedData;
 histogram LBXVE3MS;
run;
Proc sgplot data= project.cleanedData;
 histogram ORALHEALTH;
run;

PROC MEANS DATA = project.cleanedData N MEDIAN P25 P75 MIN MAX maxdec=2;
	var RIDAGEYR RIAGENDR RIDRETH3;
	class ORALHEALTH;
RUN;

proc summary data=project.cleanedData min max PRINT NOLABELS;
  class ORALHEALTH; /* Binary variable with "yes" and "no" values */
  var AVGSUGAR LBXVD2MS LBXVD3MS LBXVE3MS; /* List of continuous variables */
run;


/*losgitical regression */
* check redundancy for logistic regression;
proc sort data=project.cleanedData out=project.cleanedData nodupkey 
		dupout=project.duplicated;
	by seqn;
run;

*check mulilinearity;
proc reg data=project.cleanedData;
  model ORALHEALTH = AVGSUGAR LBXVD2MS LBXVD3MS LBXVE3MS / vif tol;
run;

*check Linearity;
data CheckData;
  set project.cleanedData;
  ln_AVGSUGAR =log(AVGSUGAR);
  ln_LBXVD2MS =log(LBXVD2MS);
  ln_LBXVD3MS =log(LBXVD3MS);
  ln_LBXVE3MS =log(LBXVE3MS);
run;

proc logistic data=CheckData;
   model ORALHEALTH(event="Need medical attetion") = AVGSUGAR LBXVD2MS LBXVD3MS LBXVE3MS
   ln_AVGSUGAR ln_LBXVD2MS ln_LBXVD3MS ln_LBXVE3MS;
run;

* Figure 2: logistic regression plots;
proc logistic data=project.cleanedData plots =all;
  model ORALHEALTH(event="Need medical attetion") = AVGSUGAR LBXVD2MS LBXVD3MS LBXVE3MS;
  output out=results_dataset predicted=PredictedProb;
run;

* Table 2: logistic regression Analysis;
proc logistic data=project.cleanedData;
  model ORALHEALTH = AVGSUGAR LBXVD2MS LBXVD3MS LBXVE3MS ;
run;



/* flow chart sas code*/

/* Figure 1: Enrollment and data collection */
data text;
 	length text $200;
	text="8858 Participants were assessed for eligibility";
	x_=25; y_=35;output;
	text="Excluded those who did not meet inclusion criteria*Not a US civilian 
	,Institutionalized,*Does not live in one of the 15 counties *researchers visited,
	Ages not 18-64,* and Nonresponsive";
	x_=46; y_=28;output;
	text="3721 Participants underwent* data collection";
	x_=25; y_=20;output;
	text="Venipuncture at *Mobile Examination Center";
	x_=25; y_=10;output;
	text="Telephone surveys";
	x_=6; y_=10;output;
	text="Oral examination at *Mobile Examination Center";
	x_=48; y_=10;output;
run;

data arrow;
	length name1 name2 $200;
	name1="8858 Participants were assessed for eligibility";
	name2="3721 Participants underwent* data collection";
	m1=25;n1=33.5;m2=25;n2=22;output;
	name1="8858 Participants were assessed for eligibility";
	name2="Excluded those who did not meet inclusion criteria*Not a US civilian,
	*Institutionalized*Does not live in one of the 15 counties* researchers visited,
	*Ages not 18-64,* and Nonresponsive";
	m1=25;n1=28;m2=28;n2=28;output;
	name1="3721 Participants underwent* data collection";
	name2="Telephone surveys";
	m1=6;n1=15;m2=6;n2=11;output;
	name1="3721 Participants underwent* data collection";
	name2="Venipuncture at *Mobile Examination Center";
	m1=25;n1=18;m2=25;n2=12;output;
	name1="3721 Participants underwent* data collection";
	name2="Oral examination at *Mobile Examination Center";
	m1=48;n1=15;m2=48;n2=12;output;
run;

data treat;
 set text arrow;
run;

proc template;
	define statgraph textplot;
 		begingraph;
 			layout overlay /yaxisopts=(linearopts=(viewmin=0 viewmax=45) display=none)
 							xaxisopts=(linearopts=(viewmin=0 viewmax=50) display=none)
 							walldisplay=none;
				textplot x=x_ y=y_ text=text / name="m"
					position=center
 					splitpolicy=split
 					splitchar="*"
 					splitchardrop=true
 					vcenter=bbox
 					position=center
 					display=(fill outline)
 					fillattrs=(color=blue transparency=1)
 					textattrs=(weight=bold color=black);
 				vectorplot xorigin=m1 yorigin=n1 x=m2 y=n2 / xaxis=x yaxis=y
 					arrowdirection=out arrowheadshape=open
 					lineattrs=(pattern=solid thickness=1px color=black);
				drawline x1=6 y1=15 x2=48 y2=15 / xaxis=x yaxis=y drawspace=datavalue
 				lineattrs=(pattern=solid thickness=1px color=black);
			endlayout;
		endgraph;
	end;
run;

ods listing close;
proc sgrender data=treat template=textplot;
run;
ods listing;

/* Validation: multiple logistic regression */
title "Oral Health Predictors - Multicollinearity Investigation of VIF
and Tolerance";
proc reg data=project.cleanedData;
	model ORALHEALTH= AVGSUGAR LBXVD2MS LBXVD3MS LBXVE3MS / vif tol collin;
run;

ods graphics on;
proc logistic plots=all;
   model y=x;
run;
proc logistic data=project.cleanedData outest=project.betas 
	covout alpha=0.05 plots=(oddsratio roc);
 	model ORALHEALTH(event="Need medical attention") = AVGSUGAR LBXVD2MS LBXVD3MS LBXVE3MS;
run;