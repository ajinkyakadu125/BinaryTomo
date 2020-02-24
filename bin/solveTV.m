function [xTV,hist] = solveTV(A,b,D,lambda,options)
%solveTV A primal-dual algorithm to find a solution to
%
%   min_{x} 0.5*|A*x - b|_2^2 + lambda*|D*x|_1
%
% Input:
%   A : a (tomography) matrix of size m x n
%   b : (tomographic) projection data vector of size m x 1
%   D : a finite-difference matrix of size p x n
%   lambda : regularization parameter for TV
%   options:
%       maxIter : maximum number of iterations (default: 1e3)
%       optTol  : tolerance level for optimality (default: 1e-6)
%       progTol : tolerance level for progress (default: 1e-6)
%       saveHist: an indicator for saving history (default:0)
%
% Output:
%   xTV : solution (size n x 1)
%   hist - history containing values at each iteration
%       f    : function value 0.5|A*x-b|_2^2
%       g    : function value lambda*|D*x|_1
%       cost : sum of two functions f and g
%       er   : error value |[x;u]-[xprev;uprev]|_2
%       opt  : optimality value |A'*(A*x-b)+lambda*(D'*u)|_2
% 
%
% Created by:
%   - Ajinkya Kadu, Utrecht University
%   Feb 18, 2020

maxIter = getoptions(options,'maxIter',1e3);
optTol  = getoptions(options,'optTol',1e-6);
progTol = getoptions(options,'progTol',1e-6);
saveHist= getoptions(options,'saveHist',0);


[m,n] = size(A);
[p,n] = size(D);

x = zeros(n,1);
u = zeros(p,1);

gamma = 0.95/normest(D);
%%

for k=1:maxIter
    
    % update primal variable x
    xp = x;
    x  = proxf(xp-gamma*(D'*u),gamma,b,A);
    
    % update dual variable u
    up = u;
    dx = 2*x-xp;
    u  = proxgd(up+gamma*(D*dx),gamma,lambda);
   
        
    hist.er(k)   = norm([x;u]-[xp;up]);
    hist.opt(k)  = norm(A'*(A*x-b)+lambda*(D'*u));
    if saveHist
        Ax           = A*x;
        Dx           = D*x;
        hist.f(k)    = 0.5*norm(Ax-b)^2;
        hist.g(k)    = lambda*norm(Dx,1);
        hist.cost(k) = hist.f(k) + hist.g(k);
    end
    
    if (hist.opt(k) < optTol)
        fprintf('stopped at iteration %d \n',k);
        fprintf('Optimality: %d \n',hist.opt(k));
        fprintf('relative progress: %d \n',hist.er(k));
        break;
    end
    
    if (hist.er(k) < progTol)
        fprintf('stopped at iteration %d \n',k);
        fprintf('relative progress: %d \n',hist.er(k));
        fprintf('Optimality: %d \n',hist.opt(k));
        break;
    end
    
end

xTV = x;

end

function [y] = proxf(x,gamma,b,A)
% (inexact) proximal for f(x) = |A*x - b|^2

g = A'*(A*x-b);
y = x - gamma/(1+gamma)*g;

end

function [y] = proxgd(x,gamma,lambda)
% proximal for dual of function g(x) = |x|_1

y = x - gamma*proxg(x/gamma,1/gamma,lambda);

end

function [y] = proxg(x,gamma,lambda)
% proximal for function g(x) = lambda*|x|_1

t = gamma*lambda;
y = max(0, x - t) - max(0, -x - t);

end
