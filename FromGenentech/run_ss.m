function [VpopParams,varargout] = run_ss(objective_handle,estParamData)
% run Scatter Search algorithm
% VpopParams is a matrix of patients and varying parameter values
% patients run along the rows, parameters along the columns
% VpopParams only contains the parameters that were varied for
% optimization

StatusOK = true;
Message = '';

% SS parameters
sim_no = 1;
rng(sim_no*5, 'twister');
MaxRgen = 3;  % maximum number of regenerations
freqn = 4;    % number of buckets for the distribution
nEval = 0;    % counter for evaluations
freq = ones(size(estParamData,1),freqn); % initialize freq matrix
m = 100;      % size generation set

% Random set generation
[Pset,freq] = rgen(estParamData,freq,m);
if size(estParamData,2)>=3
    Pset = [estParamData(:,3:end)'; Pset];
end
MaxRgen = MaxRgen - 1 ;

% Reference Set formation
b = 10;        % size of RefSet = 2b
%RefSet=zeros(2*b,param.n);
%RefObj=zeros(2*b,1);

% Calculate objective function value for Reference parameter sets
objvec = zeros(size(Pset, 1),1);
parStatusOK = true(1,length(objvec));
parMessage = cell(1,length(objvec));

% C = parallel.pool.Constant(@(p) objective_handle(p));

%parfor
gcp
parfevalOnAll(gcp(), @warning, 0, 'off')


parfor l = 1 : length(objvec)

    [objvec(l),parStatusOK(l),parMessage{l}] = objective_handle(Pset(l,:)');

    nEval = nEval + 1;
end


% fh = writeErrors(this_groupErrorCounts, this_groupErrorMessages, this_groupErrorMessageCounts);

    
                

sort_objvec = sort(objvec, 'ascend');
display(sprintf('MaxRgen = %d, nEval = %d, min(RefObj) = %f, %f, %f, %f, %f', MaxRgen, nEval, sort_objvec(1:5)));
tic;

StatusOK = all(parStatusOK);
Message = vertcat(parMessage);


% Sort, keep the sets with the b lowest objective function values in the
% Reference Set
[PsetObj,RefIndx]=sort(objvec);
RefSet=Pset(RefIndx(1:b),:);
RefObj=PsetObj(1:b);

% main MaxRgen loop
while (MaxRgen>=0)
    
    % Diversify parameter sets
    % Iraj :  the selected vectors should be removed from Pset
    % Iraj :  the nested loop can be changed to a vector equations
    
    for k=1:b
        Indx = diverse(Pset,RefSet);
        RefSet=[RefSet; Pset(Indx,:)];
        [objIndx,StatusOK,Message]=objective_handle(Pset(Indx,:)');
        RefObj=[RefObj; objIndx];
        % Iraj: updated nEval
        nEval=nEval+1;
    end % for
    sort_objvec = sort(RefObj, 'ascend');
    display(sprintf('MaxRgen = %d, nEval = %d, min(RefObj) = %f, %f, %f, %f, %f', MaxRgen, nEval, sort_objvec(1:5)));
    tic;

%     display(sprintf('RefObj = %f, %f, %f, %f, %f', RefObj(1:5)));
%     display(sprintf('RefObj = %f, %f, %f, %f, %f', RefObj(6:10)));
%     display(sprintf('RefObj = %f, %f, %f, %f, %f', RefObj(11:15)));
%     display(sprintf('RefObj = %f, %f, %f, %f, %f', RefObj(16:20)));
    
    % combination sets
    cbmflag=zeros(2*b,2*b);
    Csetflag=0;
    
    OldObj = 0;
    while (Csetflag==0)
        
        % Take combinations of the Reference Set to generate new candidate
        % parameter sets
        [Cset,cbmflag]=combination(RefSet,cbmflag,estParamData);
        if isempty(Cset) % Iraj: changed
            Csetflag=1;
        end % if
        
        % RefSet update
        if (Csetflag==0)
            Cdim=size(Cset);
            CsetObj=zeros(Cdim(1),1);
            
            % parfor
            parfor cs=1:Cdim(1)
                [CsetObj(cs),parStatusOK(cs),parMessage{cs}] = objective_handle(Cset(cs,:)');
                nEval=nEval+1;
            end 
            
            StatusOK = all(parStatusOK);
            Message = vertcat(parMessage{:});
            
            
            [Csrtval,Csrtidx]=sort(CsetObj);
            
            for k=1:(2*b)
                idxC=Csrtidx(k);
                d = mindist(Cset(idxC,:),RefSet,estParamData);
                [Rsrtval,Rsrtidx]=sort(RefObj,'descend');
                idxR=Rsrtidx(1);
                if (Rsrtval(1)>Csrtval(k) && d>0.01)
                    RefSet(idxR,:)=Cset(idxC,:);
                    RefObj(idxR)=Csrtval(k);
                    cbmflag(idxR,:)=0;
                    cbmflag(:,idxR)=0;
                end % if
            end % for
        end % if
        sort_objvec = sort(RefObj, 'ascend');
        display(sprintf('MaxRgen = %d, nEval = %d, min(RefObj) = %f, %f, %f, %f, %f', MaxRgen, nEval, sort_objvec(1:5)));
        tic;
            
        % end if (Csetflag==0)
        %          [NewObj, tmp_ind] = min(RefObj);
        %
        %          if abs(NewObj-OldObj) > 0.001
        %              OldObj = NewObj;
        %          else
        %              break;
        %          end
    end  % while (Csetflag==0)
    
    
    % RefSet Regeneration
    h=floor(b/2);
    [Rsrtval,Rsrtidx]=sort(RefObj);
    FRefSet=RefSet(Rsrtidx(1:b),:);
    FRefObj=Rsrtval(1:b);
    RefSet=RefSet(Rsrtidx(1:h),:);
    RefObj=Rsrtval(1:h);
    [Pset,freq]=rgen(estParamData,freq,m);
    MaxRgen = MaxRgen - 1;
    
    if MaxRgen>=0
        % Intensify
        objvec=zeros(m,1);
        % parfor
        parfor l=1:m
            [objvec(l),parStatusOK(l),parMessage{l}]=objective_handle(Pset(l,:)');
            nEval=nEval+1;
        end 

        
        StatusOK = all(parStatusOK);
        Message = vertcat(parMessage{:});
        
        [PsetObj,RefIndx]=sort(objvec);
        RefSet=[RefSet; Pset(RefIndx(1:(b-h)),:)];
        RefObj=[RefObj; PsetObj(1:(b-h))];
        
        sort_objvec = sort(RefObj, 'ascend');
        display(sprintf('MaxRgen = %d, nEval = %d, min(RefObj) = %f, %f, %f, %f, %f', MaxRgen, nEval, sort_objvec(1:5)));
        tic;        
    end
    
end % while

% Outputs
patient_cnt = 1;
VpopParams = FRefSet(1:patient_cnt,:);
Objvals = FRefObj(1:patient_cnt);

% Iraj added
StatusOK = true;
Message = '';

if nargout>1
    varargout{1} = StatusOK;
    varargout{2} = Message;
end

end




%% additional functions
function [Pset, freq] = rgen(paramData, freq, m)

nfreq=4;
n=size(paramData,1);
lb=paramData(:,1);
ub=paramData(:,2);
del=(ub-lb)/nfreq;
%lbj=zeros(n,nfreq);

% Iraj: can be generalized
% bounds of quadrants
lbj = [];
for i=1:nfreq
    lbj=[lbj, lb+(i-1)*del];
end
% [lb lb+del lb+2*del lb+3*del]; % NOTE hard coded for 4

%Pset matrix
Pset=zeros(m,n);

for l=1:m           % Pset index
    a=rand(n,1);
    b=rand(n,1);
    
    for j=1:n       % parameter index
        cflag=0;
        for i=1:nfreq
            if ( a(j) <= sum(1./freq(j,1:i))/sum(1./freq(j,:)) && cflag==0 )
                
                Pset(l,j)=lbj(j,i) + b(j)*del(j);
                cflag=1;
                freq(j,i)=freq(j,i) + 1;
                
            end % if
        end % for
    end % for
end % for

end % function

function [Cset, cbmflag] = combination(RefSet, cbmflag, paramData)
Cset=[];
Rdim=size(RefSet);
lb=paramData(:,1);
ub=paramData(:,2);

% combinations
for k1=1:(Rdim(1)-1)
    for k2=(k1+1):Rdim(1)
        if (cbmflag(k1,k2)==0)
            d=rand(Rdim(2),1)'.*(RefSet(k1,:)-RefSet(k2,:))/2;
            c1=max(min(RefSet(k1,:)-d,ub'),lb');
            c2=max(min(RefSet(k1,:)+d,ub'),lb');
            c3=max(min(RefSet(k2,:)-d,ub'),lb');
            c4=max(min(RefSet(k2,:)+d,ub'),lb');
            Cset=[Cset;c1;c2;c3;c4];
            cbmflag(k1,k2)=1;
        end % if
    end % for
end % for

if (isempty(Cset)==0)
    % random around each Refset entry (a la Sheela)
    for k=1:Rdim(1)
        c5=max(min(RefSet(k,:).* (1+0.1*rand(Rdim(2),1))',ub'),lb');
        c6=max(min(RefSet(k,:).* (1-0.1*rand(Rdim(2),1))',ub'),lb');
        Cset=[Cset;c5;c6];
    end % for
end % if
end % function

function indx = diverse(Pset, RefSet)

Sdim=size(Pset);
Rdim=size(RefSet);
mdist=1e12*ones(Sdim(1),1);

for l=1:Sdim(1)
    for k=1:Rdim(1)
        d=norm(Pset(l,:)-RefSet(k,:));
        mdist(l)=min(mdist(l),d);
    end % for
end % for
[~,indx]=max(mdist);

end % function

function dmin = mindist(Cset, RefSet, paramData)

dmin=Inf;
Rdim=size(RefSet);
lb=paramData(:,1);
ub=paramData(:,2);
nCset=(Cset-lb')./(ub'-lb');

for k=1:Rdim(1)
    nRefSet=(RefSet(k,:)-lb')./(ub'-lb');
    d=norm(nCset-nRefSet);
    dmin=min(dmin,d/Rdim(2)); % Iraj: why do we have Rdim(2) here?
end % for

end % function

