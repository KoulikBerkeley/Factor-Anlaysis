%% grad_desc_noninv test

%This function minimizes the objective function 
% with out any restriction on S.
%This function calls subgrad_lin_calc_noninv for calcuating subgradient.
% This function calls fval for calculating the objective function.

%% Inputs

%   1. s--------------> The covarience matrix.
%   2. r--------------> The rank constraint on Lambda.
%   3. psi_init-------> Initial value of Psi.
%   4. threshold_l------> Required for stoping criteria on log likelihood.
%   5. threshold_p------> Required for stopping criterion on norm of psi.
%   5. upper_bound----> The upper limit of the diagonal elements of psi
%   6. MAX_ITERS------> Max no of iteration after which programme will
%                       terminate.

%% Stopping criteria

% Euclidean norm of (psi_new-psi_old)/psi_old  < threshold 
%                            OR
% The no of iterations > MAX_ITERS.

%% Output

% hist: 
      
%    1. Data type-----> 1*2 cell.
%    2. hist{1}-------> optimal value of psi.
%    3. hist{2}-------> value of objective function at each iteration.

%% CODE

function [hist] = factmleExp(data,rank,lb,diags,Psi_init,Threshold_l,Threshold_p,MAX_ITERS,svd_is_true) %send diagS

if nargin<5
    
    Psi_init=diags;
    Threshold_l=10^-8;
    Threshold_p=10^-5;
    MAX_ITERS=1000;
    
end
%%%diags=diag(S);
f= -1*ones(1,MAX_ITERS);
ftime = zeros(1,MAX_ITERS);
f(1)=inf;
Psi = Psi_init;
k=2;
dim=length(Psi);
check=1;

time_start =     tic;

while (check)
    

   Old_Psi=Psi; 
   
% calculating subgradient for mazorization.

x=1./Psi;   % x= Phi [in paper]
x_half=sqrt(x);
s1=bsxfun(@times,x_half',data); % data%Phi^{1/2}

if (svd_is_true==0)
[~,d,U]=svds(s1,rank); % change to ssvd and svds [like eigs]
else
    [~,d,U]=svd(s1,'econ'); d = d(1:rank,1:rank); U = U(:,1:rank);
end



diagd=((diag(d)).^2);

% updating optimal vaue of psi
diff_d= max(0,( 1-1./(diagd)));

%{
A = bsxfun(@times,1./x_half,U); % Phi^{-1/2}*U [p X n]
B = bsxfun(@times,diff_d,U'); % Diag(diff_d)*U' [n X p]
C = s1'; % Phi^{1/2}*data' [p X n]
D = data; % data [n X p]
%}

%%Q = A*(B*C); % This is dim*sample_size  
Q = bsxfun(@times,1./x_half,U)*(bsxfun(@times,diff_d,U')*(s1')); % This is dim*sample_size  

% diff_psi_0 = sum(Q.*D',2);
diff_psi_0 = sum(Q.*(data'),2); % diag(Q*D) 

Psi=max(diags-diff_psi_0,lb); 

f(k)= calc_fval(diags,x,diagd);

ftime(k) = toc(time_start);

% Convergence criterion
 
if ((f(k)~=inf) && (f(k-1)~=inf))
    
    check= ((  abs(  (  f(k)-f(k-1) )/f(k-1)  )  > Threshold_l)&&(k < MAX_ITERS)) ;
else
    check =((norm((Psi-Old_Psi)./(dim*(Old_Psi)),2) > Threshold_p) && (k < MAX_ITERS));
    
end

k = k+1;


end

hist.Psi = Psi;
hist.Nllopt=f(k-1);
hist.time = ftime(2:(k-1));
hist.Nll = f(2:(k-1));

end

%% fval
function[fval] = calc_fval(diags ,x,eig_val)
% calculates the objective function value.
    fval =  sum(-log(x)) +diags'*x +  sum(    log(max(1,eig_val)) -  max(1,eig_val) +1      );
end


