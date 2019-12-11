function [SSVariant, ParameterVariant, InitVariant]=simbiology_functions
SSVariant=@getSS;
ParameterVariant=@CreateParamVar;
InitVariant=@SetInit;

function SSVar=getSS(m1,cs,SteadyStateTime,SpeciesNameVec,VarName,varargin)
SimTime=SteadyStateTime;  
cs.StopTime=SimTime;
set(cs.SolverOptions, 'OutputTimes',0:SimTime)

nVarargs = length(varargin);
vobj=[];
if (nVarargs==1) 
    vobj=varargin{1};    
end

simData = sbiosimulate(m1, cs, vobj);
[~,X] = selectbyname(simData, SpeciesNameVec) ;
Xss=X(end,:);
Xss=max(0,Xss);

%SSVar  = sbiovariant('SSVar') ;
SSVar  = sbiovariant(VarName) ;

texth =  'SSVar.Content = {';
text1 = ['''' 'species' ''''];
text2 = ['''' 'InitialAmount' ''''];
text3 = '''';
textb =  '}; ';

textm='';
for  i = 1:length(SpeciesNameVec) 
    textm=strcat(textm, ...
        '{',text1,',',text3,SpeciesNameVec(i),text3,',',text2,',',num2str(Xss(i)),'},');    
end
textm=textm{1}(1:end-1);
textf = strcat(texth,textm,textb);
eval(textf);

function ParamVar=CreateParamVar(NameVec,ValueVec,VarName)

ParamVar  = sbiovariant(VarName) ;

texth =  'ParamVar.Content = {';
text1 = ['''' 'parameter' ''''];
text2 = ['''' 'Value' ''''];
text3 = '''';
textb =  '}; ';

textm='';
for  i = 1:length(ValueVec) 
    textm=strcat(textm, ...
        '{',text1,',',text3,char(NameVec(i)),text3,',',text2,',',num2str(ValueVec(i)),'},');    
end
textm=textm(1:end-1);
textf = strcat(texth,textm,textb);
eval(textf);

function InitVar=SetInit(SpeciesNameVec,Vec)

Xss=Vec;
Xss=max(0,Xss);

InitVar  = sbiovariant('InitVar') ;

texth =  'InitVar.Content = {';
text1 = ['''' 'species' ''''];
text2 = ['''' 'InitialAmount' ''''];
text3 = '''';
textb =  '}; ';

textm='';
for  i = 1:length(SpeciesNameVec) 
    textm=strcat(textm, ...
        '{',text1,',',text3,SpeciesNameVec(i),text3,',',text2,',',num2str(Xss(i)),'},');    
end
textm=textm{1}(1:end-1);
textf = strcat(texth,textm,textb);
eval(textf);
