function [m1,Var2] = CombineVariants(m1,varObj)

[~,fh2,fh3]=simbiology_functions;

ParamVec=[];
ParamVal=[];
SpeciesVec=[];
SpeciesVal=[];

for i=1:length(varObj)
    
    q=varObj(i);
    [n,m]=size(q.Content);
    
    for ii=1:n
        
        curnt=q.Content{ii};
        typ=curnt(1);
        
        if strcmp(typ,'parameter')  % parameter
           x=strcmp(ParamVec,curnt(2));
           if ~any(x)
               ParamVec=[ParamVec; curnt(2)];
               ParamVal=[ParamVal; curnt(4)];
           else
               pos=find(x);
               ParamVal(pos)=curnt(4);
           end
      
        else                        % species
           x=strcmp(SpeciesVec,curnt(2));
           if ~any(x)
               SpeciesVec=[SpeciesVec; curnt(2)];
               SpeciesVal=[SpeciesVal; curnt(4)];
           else
               pos=find(x);
               SpeciesVal(pos)=curnt(4);
           end 
        end
 
    end   
   
end

if ~isempty(ParamVec)
    Var1=fh2(ParamVec,cell2mat(ParamVal),'ParamVar');
    addvariant(m1,Var1);      
    Var1 = getvariant(m1,'ParamVar');
    Var1.Active = true; % need fresh copy of variant

end

if ~isempty(SpeciesVec)
    Var2=fh3(SpeciesVec,cell2mat(SpeciesVal));
    addvariant(m1,Var2); 
    Var2 = getvariant(m1,'InitVar');
    Var2.Active = true;    

else
    Var2 = [];
end




