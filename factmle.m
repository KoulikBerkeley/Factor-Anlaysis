

% This function minimizes the objective function 
% with out any restriction on S.
% This function calls fval for calculating the objective function.
%
% --------------Inputs
%
%   1. S--------------> The covarience matrix.
%   2. rank--------------> The rank constraint on Lambda.
%   3. Psi_init-------> Initial value of Psi.
%   4. tol -----------> Tolerance level
%   6. MAX_ITERS------> Max no of iteration after which programme will
%                       terminate.
%   7. eig_is_true ----> If True uses matlab function eig() to obtain 
%                        eigrnvalues and eigenvectors. When False, it uses
%                        eigs(.) to obtain eigenvalues and eigenvectors. 
%                        Please refer to paper https://arxiv.org/abs/1801.05935
%                        for details.
%
%  8. lb ---------------> Lower bound for error variance estimate psi. 
%
% ---------Stopping criteria
%
% Euclidean norm of (psi_new-psi_old)/psi_old  < threshold 
%                            OR
% The no of iterations > MAX_ITERS.
%
% --------- Output
%
% hist: 
%     
%              Output Data type-----> 1*3 cell.
% 
%    1. hist{1}-------> optimal value of psi.
%    2. hist{2} ------> optimal objective value.
%    3. hist{3}-------> value of objective function at each iteration.

%% CODE

%function [ hist] = factmle(rank,lb,S,Psi_init,Threshold_l,Threshold_p,MAX_ITERS,eig_is_true)
function [ hist] = factmle(S,rank,tol,varargin)


% ---Preprocessing the input and assigning default values
[~,dim] = size(S);

p = inputParser;
p.addRequired('S',@(x) length(S(:,1) == length(S(:,1))))
p.addRequired('rank',@(x) (x >= 1)&&(x == floor(x) )&&( x <= dim ) )
p.addRequired('tol',@(x) x >= eps )

% Adding optional parameters and default values
p.addParameter('MAX_ITERS',1000,@(x) (x>=1)&&(x == floor(x)));
p.addParameter('lb',10^-3,@(x) (x>eps) );
p.addParameter('eig_is_true',(1>0),@(x) (x == (1>0) )||(x == (1<0)) );
p.addParameter('Psi_init',rand([dim,1]),@(x) iscolumn(x) == 1);

% Parsing the input
p.parse(S,rank,tol,varargin{:})

lb = p.Results.lb; MAX_ITERS = p.Results.MAX_ITERS ; eig_is_true = p.Results.eig_is_true ; Psi_init = p.Results.Psi_init ;


    
    Threshold_l = tol;
    Threshold_p = tol;
    
% --------------------------- end of pre processing --------------------


diags=diag(S); % Diagonal entries of S .

f= -1*ones(1,MAX_ITERS);
f(1)=inf;
Psi = Psi_init;
k=2;
dim=length(Psi);
check=1;

%A1=Psi;

while (check)
   Old_Psi=Psi; 
   
% calculating subgradient for mazorization.

x=1./Psi;
x_half=sqrt(x);


s1=bsxfun(@times,(bsxfun(@times,S,x_half')),x_half);
s1=(s1+s1')/2;

if (eig_is_true == (1>0))
[vv,dd] = eig(s1);  v = vv(:,(dim-rank+1):dim); d=diag(dd((dim-rank+1):dim,(dim-rank+1):dim)); 
else
[v, d]=eigs(s1,rank); d = diag(d);
end


if ( ~isreal(d) )
   d(find(~isreal(d))) = 0;
end

% collecting objective values

 f(k)= calc_fval(diags,x,d);
 


% Calculating subgradient.
    diff_d= max(0,1-1./d);
    A= bsxfun(@times,(bsxfun(@times,S,x_half)),1./(x_half'));
    A=v'*A;
    B = bsxfun(@times,v,diff_d');
    
    
diff_psi_0 = sum(B.*A',2);

%updating optimal vaue of psi
Psi=max(diags-diff_psi_0,lb); 



% Convergence criterion
 
if ((f(k)~=inf) && (f(k-1)~=inf))
    
    check= ((  abs(  (  f(k)-f(k-1) )/f(k-1)  )  > Threshold_l)&&(k < MAX_ITERS)) ;

else 
    
    check =((norm((Psi-Old_Psi)./(dim*(Old_Psi)),2) > Threshold_p) && (k < MAX_ITERS));
    
end

k=k+1;




end



hist.Psi = Psi;
hist.Nllopt=f(k-1);
hist.Nll = f(2:(k-1));



end




%% fval
function[fval] = calc_fval(diags ,x,eig_val)
% calculates the objective function value.

fval =  sum(-log(x)) +diags'*x +  sum(    log(max(1,eig_val)) -  max(1,eig_val) +1      );

end



 
