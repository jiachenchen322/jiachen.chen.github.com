/*==================================================================================
   Macro SWDPWR
  This macro can be used for power calculation of stepped wedge cluster randomized trials.
  Written by: Jiachen Chen (jiachen.chen@yale.edu)
===================================================================================*/
%macro swdpwr
(
 I=, /*number of clusters*/
 J=, /*number of time steps*/
 K=, /*number of participants at each time step from every cluster*/
 dataset=, /*name of the generated SAS data set*/
 response=2, /*choose continuous outcome(response=1) or binary outcome(response=2), with default value of 2*/
 model=2, /*choose conditional model (model=1) or marginal model(model=2),with default value of 2*/
 link=1, /*choose link function (identity 1, log 2, logit 3),with default value of 1*/
 mu=, /*baseline effect in control groups*/
 beta=, /*treatment effect (the parameter we would like to test)*/
 gammaJ=0, /*time effect at time period J, with default value of 0*/
 sigma2=0,/* Marginal variance of the outcome (only needed by continuous outcomes)*/
 alpha=0.05, /*type one error rate,with default value of 0.05*/
 ICC0=0.1, /*Within-period correlation,alpha0,with default value of 0.1*/
 ICC1=ICC0/2, /*Inter-period correlation,alpha1, with default value of ICC0/2*/
 ICC2=, /*Within-individual,alpha2*/
);


/*import study design matrix*/ 
data X_in;
set &dataset;
length count 8;
count=0;
do until (count ge numofclusters);
output;
count=count+1;
end;
drop count numofclusters;
run;


/*Initialize for combination
data XX;
set X_in(rename=(t1=name t2=para));
run;*/
data XX;
set X_in;
name=put(time1,4.);
para=put(time2,4.);
drop time1 time2;
run;

/*write the input txt for Fortran*/
data covpara;
I=&I;
J=&J;
K=&K;
res=&response;
opt=&model;
link=&link;
mu=&mu;
beta=&beta;
delta=&gammaJ;
sigma2=&sigma2;
typeone=&alpha;
ICC0=&ICC0;
ICC=&ICC1;
ICC2=&ICC2;
X_in="=";

run;

proc transpose data =covpara out = se1;
var I J K res opt link mu beta delta sigma2 typeone ICC0 ICC ICC2 X_in;
run;



data try;
I= scan('(I=)' ,1);
J= scan('(J=)' ,1);
K= scan('(K=)' ,1);
res= scan('(res=)' ,1);
opt= scan('(opt=)' ,1);
link= scan('(link=)' ,1);
mu= scan('(mu=)' ,1);
beta= scan('(beta=)' ,1);
delta= scan('(delta=)' ,1);
sigma2= scan('(sigma2=)' ,1);
typeone= scan('(typeone=)' ,1);
ICC0=  scan('(ICC0=)' ,1);
ICC=  scan('(ICC=)' ,1);
ICC2=  scan('(ICC2=)' ,1);
X_in =scan('(X_in)' ,1);
run;



proc transpose data = try out = temp3;
var I J K res opt link mu beta delta sigma2 typeone ICC0 ICC ICC2 X_in;
run;


data part1;
set temp3(rename=(COL1=name));
run;
data part2;
set se1(rename=(COL1=para));
run;



proc sort data=part1;
by _NAME_;
run;
proc sort data=part2;
by _NAME_;
run;

data mer;
merge part1 part2;
by _NAME_;
run;

proc sort data=mer out=sorted;
by  para;
run;

data fin;
set sorted;
keep name para;
run;

data new;
set fin XX;
run;

PROC EXPORT DATA= new
            OUTFILE= ".\in.txt"
            DBMS=DLM REPLACE;
     DELIMITER='20'x;
PUTNAMES=NO;
RUN;

/*Call Unix command to modify RRC Fortran program based on arguments from the users*/
%let mydir=C:\Users\xifan\;
%let outfile=.\out.txt ;

%let myprog=&mydir.swdnew.exe;
    x "&myprog .\in.txt &outfile";

/*Output the result*/
data output; 
    infile "&outfile"  dlm = '```'; 
    length Result $ 32767; 
    input Result; 
run; 

proc print;
data output;
run;

/*x "rm -f .\in.txt";
x "rm -f &outfile";*/

x "del .\in.txt";
x "del &outfile";

%mend swdpwr;



/*test examples*/
/*need to download swdnew.exe to your own computer*/
/*need to modify line %let mydir=C:\Users\xifan\; for proper directory to swdnew.exe on your own computer*/
/*an example for binary outcomes*/
data design2;
input numofclusters time1 time2 time3 time4;
cards;
4 0 1 1 1
4 0 0 1 1
4 0 0 0 1
;
run;
%swdpwr(I = 12, J = 4, K = 100, dataset = design2, response = 2, model = 2, link = 1, mu = 0.5, beta = 0.15, gammaJ = 0, alpha = 0.05, ICC0 = 0.1, ICC1 = 0.05, ICC2 = 0.2)

/*an example for continuous outcomes*/
data design3;
input numofclusters time1 time2 time3; 
cards;
4 0 1 1
4 0 0 1
;
run;
%swdpwr(I = 8, J = 3, K = 50, dataset = design3, response = 1, model = 2, link = 1, mu = 0.1, beta = 0.2, gammaJ = 0, sigma2 = 0.095, alpha = 0.05, ICC0 = 0.3, ICC1 = 0.2, ICC2 = 0.2)
