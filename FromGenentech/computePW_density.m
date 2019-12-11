function PW = computePW_density(m,dens)

M = [m; -m];

e = dens*0.05; % 5pct tolerance
d = [dens + e; -dens + e];

N = size(X,2);
LB = zeros(N,1);
UB = W_max*ones(N,1);
X0 = 1/N*ones(1,N);

Aeq=ones(1,N);
beq=1;

[PW, fval] = quadprog(H,f',M,d,Aeq,beq,LB,UB,X0);

%% reweight to increase diversity of the samples

% second step
Err=X*PW-Y;
Del=abs(Y*0.025);
D = Y;


if ~DIVERSIFY
    % don't perform the second step if this should not be performed
    return
end

A=[X; -X];
b=[Err+Del+D; -Err+Del-D];
H=eye(N);
f=[];
options = optimoptions('quadprog','Display','iter-detailed');
PW = quadprog(H,f,A,b,Aeq,beq,LB,UB,X0, options);


